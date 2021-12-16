# frozen_string_literal: true

task :verify_environment_file do
  Nvar::EnvironmentVariable.verify_env ? exit : exit(1)
end
