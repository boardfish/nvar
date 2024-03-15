# frozen_string_literal: true

require "nvar/version"
require "nvar/environment_variable"
require "nvar/engine" if defined?(Rails)
require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/hash/reverse_merge"
require "active_support/string_inquirer"

# Centralized configuration for required environment variables in your Ruby app.
module Nvar
  mattr_accessor :config_file_path, default: File.expand_path("config/environment_variables.yml")
  mattr_accessor :env_file_path, default: File.expand_path(".env")
  mattr_accessor :env, default: :development

  # Comments in .env files must have a leading '#' symbol. This cannot be
  # followed by a space.
  ENV_COMMENT = <<~COMMENT
    #Environment variables are managed through this file (.env). The Scripts to
    #Rule Them All (in script/) load the environment from here, and the app warns
    #on startup if any required environment variables are missing. You can see the
    #list of environment variables that can be set for the app in
    #config/environment_variables.yml.
  COMMENT

  class Error < StandardError; end

  # Error that is raised when an environment variable is blank or unset when it is
  # required
  class EnvironmentVariableNotPresentError < Error
    attr_reader :vars

    def initialize(*vars)
      @vars = vars
      super()
    end

    def message
      "The following variables are unset or blank: #{vars.map(&:name).join(", ")}"
    end
  end

  class << self
    def env
      ActiveSupport::StringInquirer.new(@@env.to_s)
    end

    def configure_for_rails(app)
      self.config_file_path = app.root.join("config/environment_variables.yml")
      self.env_file_path = app.root.join(".env")
      [config_file_path, env_file_path].each do |path|
        File.open(path, "w") {} unless path.exist? # rubocop:disable Lint/EmptyBlock
      end
    end

    def load_all
      all.tap do |set, unset|
        set.map(&:to_const)
        raise EnvironmentVariableNotPresentError.new(*unset) if unset.any?
      end
    end

    def filter_from_vcr_cassettes(config)
      set, = all
      set.reduce(config) do |c, env_var|
        c.tap { env_var.filter_from_vcr_cassettes(c) }
      end
    end

    def all
      variables.map do |variable_name, config|
        EnvironmentVariable.new(**(config || {}).merge(name: variable_name))
      end.partition(&:set?)
    end

    def touch_env
      File.write(env_file_path, ENV_COMMENT, mode: "w") unless File.exist?(env_file_path)
    end

    def verify_env(write_to_file: true)
      _set, unset = all
      return true if all_required_env_variables_set?

      puts "Please update .env with values for each environment variable:"
      touch_env if write_to_file
      unset.each do |variable|
        variable.add_to_env_file if write_to_file
        puts "- #{variable.name}"
      end
      puts "#{config_file_path} contains information on required environment variables across the app."
      # Don't exit if all unset variables had defaults that were written to .env
      write_to_file && unset.all? { |variable| variable.value.present? }
    end

    private

    def all_required_env_variables_set?
      all[1].none? || ENV["RAILS_ENV"] == "test"
    end

    def variables
      (YAML.safe_load_file(config_file_path) || {}).deep_symbolize_keys
    end
  end
end
