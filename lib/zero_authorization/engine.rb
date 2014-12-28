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
        raise ZeroAuthorization::Exceptions::RoleNotAvailable, 'Executing authorize_strictly but role not available' if role.nil?

        if zero_authorized_core(role, action)
          return true
        else
          raise ZeroAuthorization::Exceptions::NotAuthorized.new(role), "Not authorized to execute #{action} on #{self.class.name}."
        end

        false
      end

      # Authorization for authorization mode :warning
      def authorize_with_warning(action)
        role = ZeroAuthorization::Role.role
        raise ZeroAuthorization::Exceptions::RoleNotAvailable, 'Executing authorize_with_warning but role not available' if role.nil?

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
          raise ZeroAuthorization::Exceptions::InvalidAuthorizationMode
        end
      end

      # Core of authorization after reading/parsing rule set for current role
      # Rules for rule-sets execution (Precedence: from top to bottom)
      # Rule 00: If no rule-sets are available for 'can do' and 'cant do' then is authorized true '(with warning message)'.
      # Rule 01: If role can't do 'anything' or can do 'nothing' then is authorized false.
      # Rule 02: If role can't do 'nothing' or can do 'anything' then is authorized true.
      # Rule 03: If role can't do 'specified' method and given 'evaluate' method returns true then is authorized false.
      # Rule 04: If role can't do 'specified' method and given 'evaluate' method returns false then is authorized true.
      # Rule 05: If role can   do 'specified' method and given 'evaluate' method returns true then is authorized true.
      # Rule 06: If role can   do 'specified' method and given 'evaluate' method returns false then is authorized false.
      # Rule 07: If role can't do 'specified' method then is authorized false.
      # Rule 08: If role can   do 'specified' method then is authorized true.
      def zero_authorized_core(role, action)
        can_rights = role.can_do_rights(self.class.name)
        can_rights_names = can_rights.keys
        cant_rights = role.cant_do_rights(self.class.name)
        cant_rights_names = cant_rights.keys

        if can_rights.empty? and cant_rights.empty? #Rule 00
          _temp_i = "#{self.class.name} is exempted from ZeroAuthorization. To enable back, try adding rule-set(s) in role_n_privileges.yml"
          puts _temp_i
          Rails.logger.info _temp_i
          return true
        end
        return false if cant_rights_names.include?(:anything) or can_rights_names.include?(:nothing) #Rule 01
        return true if cant_rights_names.include?(:nothing) or can_rights_names.include?(:anything) #Rule 02
        return (self.send(cant_rights[action.to_sym]) ? false : true) unless cant_rights[action.to_sym].nil? # Rule 03 and Rule 04
        return (self.send(can_rights[action.to_sym]) ? true : false) unless can_rights[action.to_sym].nil? # Rule 05 and Rule 06
        return false if cant_rights_names.include?(action.to_sym) # Rule 07
        return true if can_rights_names.include?(action.to_sym) # Rule 08

        raise ZeroAuthorization::Exceptions::ExecutingUnreachableCode
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

      def declared_methods_to_restrict
        Role.methods_marked_for(self.name).keys
      end

      def list_of_methods_to_guard
        declared_methods_to_restrict - [:create, :save, :update, :destroy, :anything, :nothing]
      end

      private
      def initialize_authorization_mode
        @authorization_mode = :warning # :strict, :warning and :superficial
      end

      # applying restriction on methods
      def initialize_methods_restriction
        list_of_methods_to_guard.each do |method_name|
          if self.instance_methods.include?(method_name)
            send(:alias_method, "za_#{method_name}", method_name)
            define_method "#{method_name}" do |*args|
              _temp_i = "Restricted method call to #{self.class.name}#{method_name}.."
              puts _temp_i
              Rails.logger.debug(_temp_i)
              send("za_#{method_name}", *args) if zero_authorized_checker(method_name)
            end
          else
            _temp_i = "[WARNING] ZeroAuthorization: Method '#{method_name}' unavailable in #{self.name} for restriction application."
            puts _temp_i
            Rails.logger.debug(_temp_i)
          end
        end
      end
    end
  end

end