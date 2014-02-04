module ZeroAuthorization

  class Role
    cattr_writer :role

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

    #Returns a valid role if available defined from config/roles_n_privileges.yml else a nil
    def self.role
      roles_n_privileges_hash.keys.collect { |key| key.to_s.gsub(/^role_/, '') }.include?(@@role) ? new(@@role) : nil
    end

    # Cache read of config/roles_n_privileges.yml for role_privileges_hash
    def self.roles_n_privileges_hash
      @roles_n_privileges_hash ||= YAML::load_file(File.join(Rails.root, 'config', 'roles_n_privileges.yml'))
      @roles_n_privileges_hash
    end

    # Hard read of config/roles_n_privileges.yml for role_privileges_hash
    def self.roles_n_privileges_hash_reload
      @roles_n_privileges_hash = YAML::load_file(File.join(Rails.root, 'config', 'roles_n_privileges.yml'))
    end

    # Do any activity with any specific temporary role and then revert back to normal situation.
    # Example:
    # ZeroAuthorization::Role.temp_role('default') do
    #  Patron.all.each do |patron|
    #    patron.some_restricted_method_call!
    #  end
    #end
    def self.temp_role(temp_role, &block)
      _current_role = self.role.nil? ? self.role : self.role.to_s
      self.role=temp_role
      yield
      self.role=_current_role
    end

  end
end