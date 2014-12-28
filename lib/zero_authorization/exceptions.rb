module ZeroAuthorization
  module Exceptions
    class ExecutingUnreachableCode < StandardError
      def initialize(msg = 'It may be a bug. Please report to ZeroAuthorization\'s authors!')
        super(msg)
      end
    end

    class RoleNotAvailable < StandardError
    end

    class NotAuthorized < StandardError
      attr_reader :role

      def initialize(role)
        @role = role
      end
    end

    class InvalidAuthorizationMode < StandardError
      def initialize(msg = 'Invalid authorization mode in use it should be from :strict, :warning or :superficial')
        super(msg)
      end
    end

    class InvalidRolesNPrivilegesHash < StandardError
      attr_reader :hash_in_use

      def initialize(hash_in_use)
        @hash_in_use = hash_in_use
      end
    end

  end
end