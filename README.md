# ZeroAuthorization

Functionality to add authorization on Rails model's write operations plus any other set of defined methods.

## Installation

Add this line to your application's Gemfile:

    gem 'zero_authorization'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install zero_authorization

## Usage

1. Specify what any specific role of current root entity(logged_user) can do/can't do in roles_n_privileges.yml

        :role_role_name_one:
          :can_do:
            :Account:
            - :create
            - :save
            - :update
            :User:
            - :create
            - :save
            - :update
            :ModelCrudHistory: :anything
            :Permission: :anything
          :cant_do:
            :Project:
            - :destroy
        :role_role_name_two:
          :can_do:
            :Project:
            - :create
            - :save:
                :if:
                  :authorize?
            - :update:
                :if:
                  :authorize?
            - :destroy:
                :if:
                  :authorize?
        :role_role_name_three:
          :can_do:
            :Plant:
            - :create
            - :save
            - :update
            - :destroy
          :cant_do: :anything

2. Restrict models for activity and let rule-set(s) via zero-authorization take control of activity

    1 Add initializer file with content (if all existing models needs to have restrictions. Easy way out).

        # Make a file restrict_models.rb in Rails.root/config/initializers
        Rails.application.eager_load!
        ActiveRecord::Base.descendants.each do |descendant|
          descendant.send(:include, ZeroAuthorization::Engine)
        end

    2 To hand pick some models for restriction

        class ModelName < ActiveRecord::Base
          include ZeroAuthorization::Engine
        end

4. (Re-)boot application.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
