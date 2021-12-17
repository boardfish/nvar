# frozen_string_literal: true

namespace :nvar do
  task :verify_environment_file do
    Nvar.configure_for_rails(Rails)
    Nvar.verify_env ? exit : exit(1)
  end
end
