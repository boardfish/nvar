# frozen_string_literal: true

require_relative '../environment_variable'

task :verify_environment_file do
  EnvironmentVariable.touch_env
  EnvironmentVariable.verify_env ? exit : exit(1)
end
