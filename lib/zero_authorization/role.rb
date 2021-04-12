module ZeroAuthorization

  class Role
    # thread-local, requires Rails 5
    thread_mattr_accessor :private_role, instance_accessor: false

    # Initializing role
    def initialize(role_name)
      @role_name = role_name
    end

    def to_s
      @role_name.to_s
    end

    # Getting rule_set(s) for the role
    def rule_set
      self.class.roles_n_privileges_hash["role_#{@role_name}".to_sym]
    end

    # Sets a valid role if available defined from config/roles_n_privileges.yml else a nil
    def self.role=(role_as_string)
      self.private_role = roles_n_privileges_hash.keys.collect { |key| key.to_s.gsub(/^role_/, '') }.include?(role_as_string) ? new(role_as_string) : nil
    end

    def can_do_rights(for_classname)
      self.class.methods_marked_for(for_classname, :can_do, rule_set)
    end

    def cant_do_rights(for_classname)
      self.class.methods_marked_for(for_classname, :cant_do, rule_set)
    end

    def self.methods_marked_for(for_classname, specific_can_or_cant = nil, source_class_rule_sets = nil)
      method_collection = {}
      if source_class_rule_sets.nil?
        validate_roles_n_privileges_hash.each do |role, class_rule_sets|
          method_collection.merge!(extract_rule_hash(class_rule_sets, for_classname, specific_can_or_cant))
        end
      else
        method_collection.merge!(extract_rule_hash(source_class_rule_sets, for_classname, specific_can_or_cant))
      end
      method_collection
    end

    def self.extract_rule_hash(class_rule_sets, for_classname, specific_can_or_cant)
      method_collection = {}
      basic_rule = class_rule_sets[for_classname.to_sym]
      basic_rule.each do |can_or_cant, rule_hash|
        (method_collection.merge!(rule_hash)) if (specific_can_or_cant.nil? ? true : (can_or_cant == specific_can_or_cant)) and rule_hash.is_a?(Hash)
      end if basic_rule.is_a?(Hash)
      method_collection
    end

    # Cache read of config/roles_n_privileges.yml for role_privileges_hash
    def self.roles_n_privileges_hash
      @roles_n_privileges_hash ||= validate_roles_n_privileges_hash
      @roles_n_privileges_hash
    end

    # Hard read of config/roles_n_privileges.yml for role_privileges_hash
    def self.roles_n_privileges_hash_reload
      @roles_n_privileges_hash = validate_roles_n_privileges_hash
    end

    def self.validate_roles_n_privileges_hash
      _result_hash = {}
      YAML::load_file(File.join(Rails.root, 'config', 'roles_n_privileges.yml')).each do |role_name, role_permissions|
        _result_hash[role_name.to_sym] ||= {}
        _rh_with_role = _result_hash[role_name.to_sym]

        role_permissions.symbolize_keys!
        [:can_do, :cant_do].each do |_can|

          if role_permissions[_can].is_a?(Array)

            role_permissions[_can].each do |class_name|
              if [Symbol, String].include?(class_name.class)
                _class_name = class_name.to_s.classify.to_sym
                ((_rh_with_role[_class_name] ||= {})[_can] ||={}).merge!({:anything => nil})
              else
                raise ZeroAuthorization::Exceptions::InvalidRolesNPrivilegesHash.new(class_name), 'It should only be a Symbol or String'
              end
            end

          elsif role_permissions[_can].is_a?(Hash)

            role_permissions[_can].each do |class_name, permission_set|
              _class_name = class_name.to_s.classify.to_sym

              if [Symbol, String].include?(class_name.class)
                if [Symbol, String].include?(permission_set.class)
                  if [:anything, :nothing].include?(permission_set.to_sym)
                    ((_rh_with_role[_class_name] ||= {})[_can] ||={}).merge!({permission_set.to_sym => nil})
                  else
                    raise ZeroAuthorization::Exceptions::InvalidRolesNPrivilegesHash.new(permission_set.to_sym), 'It should only have :anything or :nothing'
                  end
                elsif permission_set.is_a?(Array)
                  permission_set.each do |i_permission_set|
                    if [Symbol, String].include?(i_permission_set.class)
                      ((_rh_with_role[_class_name] ||= {})[_can] ||={}).merge!({i_permission_set.to_sym => nil})
                    elsif i_permission_set.is_a?(Hash)
                      i_permission_set.each do |_key, _value|
                        if [Symbol, String].include?(_key.class) and [Symbol, String].include?(_value.class)
                          ((_rh_with_role[_class_name] ||= {})[_can] ||={}).merge!({_key.to_sym => _value.to_sym})
                        else
                          raise ZeroAuthorization::Exceptions::InvalidRolesNPrivilegesHash.new({_key => _value}), 'Hash should only have key and value of type Symbol or String'
                        end
                      end
                    else
                      raise ZeroAuthorization::Exceptions::InvalidRolesNPrivilegesHash.new(i_permission_set), 'It should only be a Symbol, String or Hash'
                    end
                  end
                elsif permission_set.is_a?(Hash)
                  permission_set.each do |i_permission_key, i_permission_value|
                    if [Symbol, String].include?(i_permission_key.class) and [Symbol, String].include?(i_permission_value.class)
                      ((_rh_with_role[_class_name] ||= {})[_can] ||={}).merge!({i_permission_key.to_sym => i_permission_value.to_sym})
                    else
                      raise ZeroAuthorization::Exceptions::InvalidRolesNPrivilegesHash.new({i_permission_key => i_permission_value}), 'Hash should only have key and value of type Symbol or String'
                    end
                  end
                else
                  raise ZeroAuthorization::Exceptions::InvalidRolesNPrivilegesHash.new(permission_set), 'It should only be a Symbol, String, Hash or Array'
                end
              else
                raise ZeroAuthorization::Exceptions::InvalidRolesNPrivilegesHash.new(class_name), 'It should only be a Symbol or String'
              end
            end

          end
        end
      end
      _result_hash
    end

    # Do any activity with any specific temporary role and then revert back to normal situation.
    # Example:
    # ZeroAuthorization::Role.temp_role('default') do
    #  Patron.all.each do |patron|
    #    patron.some_restricted_method_call!
    #  end
    #end
    def self.temp_role(temp_role_as_string, &block)
      _current_role = self.private_role
      self.role = temp_role_as_string
      yield
      self.private_role = _current_role
    end
  end
end
