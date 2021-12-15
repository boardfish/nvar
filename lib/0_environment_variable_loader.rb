# frozen_string_literal: true

require_relative '../../lib/environment_variable'

# Load environment variables from `config/environment_variables.yml`, and assign
# them to constants in the app. The EnvironmentVariable class will raise an
# error if it can't source a required env var from the environment, and set
# values for use during tests.
begin
  EnvironmentVariable.load_all
rescue EnvironmentVariableNotPresentError => e
  raise e unless Rails.env.test?

  e.vars.each do |var|
    Object.const_set(var.name, var.name)
  end
end
