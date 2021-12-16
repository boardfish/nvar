# frozen_string_literal: true

require "rails"
require_relative './environment_variable'

module Nvar
  class Engine < Rails::Engine # :nodoc:
    # Load environment variables from `config/environment_variables.yml`, and assign
    # them to constants in the app. The EnvironmentVariable class will raise an
    # error if it can't source a required env var from the environment, and set
    # values for use during tests.
    initializer 'nvar.load_all' do
      begin
        Nvar::EnvironmentVariable.load_all
      rescue Nvar::EnvironmentVariableNotPresentError => e
        raise e unless Rails.env.test?

        e.vars.each do |var|
          Object.const_set(var.name, var.name)
        end
      end
    end
  end
end
