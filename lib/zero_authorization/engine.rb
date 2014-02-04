module ZeroAuthorization
  module Engine
    def self.included(base)
      puts "Initializing ZeroAuthorization for #{base.name}"

      base.extend(ClassMethods)

      # Initializing authentication mode. Options are
      # :strict =>'raise exception and deny operation if not authorized' ,
      # :warning => 'display only warning without exception' [DEFAULT],
      # :superficial =>'allow operation without authorization'
      base.send(:initialize_authorization_mode)

      # Applying restriction on methods
      base.send(:initialize_methods_restriction)

      # Applying restriction on crud write operations
      base.send(:before_save, :is_zero_authorized_4_save)
      base.send(:before_create, :is_zero_authorized_4_create)
      base.send(:before_update, :is_zero_authorized_4_update)
      base.send(:before_destroy, :is_zero_authorized_4_destroy)


      private

      # Authorization for authorization mode :strict
      def authorize_strictly(action)
        role = ZeroAuthorization::Role.role
        raise 'ZeroAuthorizationRoleNotAvailable' if role.nil?

        if zero_authorized_core(role, action)
          return true
        else
          logger.debug 'ZeroAuthorization: Not authorized to perform activity.'
          raise 'NotAuthorized'
        end

        false
      end

      # Authorization for authorization mode :warning
      def authorize_with_warning(action)
        role = ZeroAuthorization::Role.role
        raise 'ZeroAuthorizationRoleNotAvailable' if role.nil?

        if zero_authorized_core(role, action)
          return true
        else
          logger.debug 'ERROR: ZeroAuthorization: Not authorized to perform activity.'
          self.errors.add(:authorization_error, 'occurred, Unauthorized to perform this activity')
        end

        false
      end

      # Authorization for authorization mode :superficial
      def authorize_superficially(action)
        logger.debug 'ZeroAuthorizationMode: superficial. By passing authorization.'
        return true
      end

      # Return authorization mode
      def zero_authorized_checker(action)
        if self.class.authorization_mode == :strict
          return authorize_strictly(action)
        elsif self.class.authorization_mode == :warning
          return authorize_with_warning(action)
        elsif self.class.authorization_mode == :superficial
          return authorize_superficially(action)
        else
          raise 'InvalidAuthorizationMode'
        end
      end

      # Core of authorization after reading/parsing rule set for current role
      def zero_authorized_core(role, action)
        _auth_flag = false
        unless role.rule_set[:can_do].nil?
          if role.rule_set[:can_do] == :anything
            _auth_flag = true

          elsif role.rule_set[:can_do].is_a?(Hash)

            if role.rule_set[:can_do][self.class.name.to_sym] == :anything
              _auth_flag = true
            else
              logger.debug "----------- self.class.name.to_sym: #{self.class.name.to_sym}"
              symbolized_actions = role.rule_set[:can_do][self.class.name.to_sym].collect { |x| x if x.is_a?(Symbol) }.compact
              _auth_flag = if symbolized_actions.include?(action)
                             true
                           else
                             conditional_check =nil
                             (role.rule_set[:can_do][self.class.name.to_sym]- symbolized_actions).each do |action_rule_hash|
                               conditional_check = action_rule_hash[action] if action_rule_hash.keys.include? action
                             end
                             conditional_check ||= {}
                             conditional_check= conditional_check[:if]
                             return self.send(conditional_check) unless conditional_check.nil?
                             false
                           end
              #_auth_flag = true if (role.rule_set[:can_do][self.class.name.to_sym] || []).include?(action)
            end
          end
        end
        unless role.rule_set[:cant_do].nil?
          if role.rule_set[:cant_do] == :anything
            _auth_flag = false
          elsif role.rule_set[:cant_do].is_a?(Hash)
            _auth_flag = false if (role.rule_set[:cant_do][self.class.name.to_sym] || []).include?(action)
          end
        end
        _auth_flag
      end

      def is_zero_authorized_4_save
        zero_authorized_checker(:save)
      end

      def is_zero_authorized_4_create
        zero_authorized_checker(:create)
      end

      def is_zero_authorized_4_update
        zero_authorized_checker(:update)
      end

      def is_zero_authorized_4_destroy
        zero_authorized_checker(:destroy)
      end
    end

    module ClassMethods
      attr_accessor :authorization_mode

      def list_of_methods_to_guard
        _model_methods_set = {}
        Role.roles_n_privileges_hash.each do |role_key, permission_value|
          unless permission_value[:can_do].nil?
            _model_methods_set = _model_methods_set.merge(permission_value[:can_do]) { |key, oval, nval| ([oval] << [nval]).flatten.compact.uniq } if permission_value[:can_do].is_a?(Hash)
          end
          unless permission_value[:cant_do].nil?
            _model_methods_set = _model_methods_set.merge(permission_value[:cant_do]) { |key, oval, nval| ([oval] << [nval]).flatten.compact.uniq } if permission_value[:cant_do].is_a?(Hash)
          end
        end
        if _model_methods_set[self.name.to_sym] == :anything
          _model_methods_set.delete(self.name.to_sym)
        end
        (_model_methods_set[self.name.to_sym] || []).clone.delete_if do |x|
          if x.is_a? Hash
            x= x.keys.first
          end
          [:create, :save, :update, :destroy, :anything].include?(x)
        end
      end

      private
      def initialize_authorization_mode
        @authorization_mode = :warning # :strict, :warning and :superficial
      end

      # applying restriction on methods
      def initialize_methods_restriction
        list_of_methods_to_guard.each do |method_name|
          if method_name.is_a? Hash
            method_name = method_name.keys.first
          end
          send(:alias_method, "za_#{method_name}", method_name)
          define_method "#{method_name}" do |*args|
            puts 'Restricted method call..'
            send("za_#{method_name}", *args) if zero_authorized_checker(method_name)
          end
        end
      end
    end
  end

end