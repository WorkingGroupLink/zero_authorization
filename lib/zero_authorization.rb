require 'rails'
require 'active_record'
require 'active_support/core_ext'
require "zero_authorization/version"
require 'zero_authorization/exceptions'
require 'zero_authorization/role'
require 'zero_authorization/engine'

#Add these lines in initializer of rails application.
#Rails.application.eager_load!
#ActiveRecord::Base.descendants.each do |descendant|
#  descendant.send(:include, ZeroAuthorization::Engine)
#end
