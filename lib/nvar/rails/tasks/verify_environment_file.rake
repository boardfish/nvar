# frozen_string_literal: true

namespace :nvar do
  task :verify_environment_file do
    Nvar::EnvironmentVariable.configure_for_rails(Rails)
    Nvar::EnvironmentVariable.verify_env ? exit : exit(1)
  end
end
