# frozen_string_literal: true

# Wrapper for retrieval of environment variables. See
# config/initializers/environment_variable_loader.rb to check out how it's used.
require 'active_support/core_ext/hash/keys'
require 'yaml'

module Nvar
  # Error that is raised when an environment variable is blank or unset when it is
  # required
  class EnvironmentVariableNotPresentError < StandardError
    attr_reader :vars

    def initialize(vars)
      @vars = vars
      super
    end

    def message
      "The following variables are unset or blank: #{vars.map(&:name).join(', ')} "
    end
  end

  # Wrapper for loading environment variables, used across relevant Rake tasks
  class EnvironmentVariable
    attr_reader :name, :type, :value, :required, :defined

    ENV_FILE = '.env'

    CONFIG_FILE = File.expand_path('../config/environment_variables.yml', __dir__)

    # Comments in .env files must have a leading '#' symbol. This cannot be
    # followed by a space.
    ENV_COMMENT = <<~'COMMENT'
      #Environment variables are managed through this file (.env). The Scripts to
      #Rule Them All (in script/) load the environment from here, and the app warns
      #on startup if any required environment variables are missing. You can see the
      #list of environment variables that can be set for the app in
      #config/environment_variables.yml.
    COMMENT

    class << self
      def load_all
        set, unset = all
        set.map(&:to_const)
        raise EnvironmentVariableNotPresentError, unset if unset.any?
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
        File.write(ENV_FILE, ENV_COMMENT, mode: 'w') unless File.exist?(ENV_FILE)
      end

      def verify_env(write_to_file: true)
        _set, unset = all
        return true unless unset.any? && !Rails.env.test?

        puts 'Please update .env with values for each environment variable:'
        unset.each do |variable|
          variable.add_to_env_file if write_to_file
          puts "- #{variable.name}"
        end
        puts "#{CONFIG_FILE} contains information on required environment variables across the app."
        # Don't exit if all unset variables had defaults that were written to .env
        write_to_file && unset.all? { |variable| variable.value.present? }
      end

      private

      def variables
        YAML.safe_load(File.read(CONFIG_FILE)).deep_symbolize_keys
      end
    end

    def initialize(name:, type: 'String', filter_from_requests: nil, **args)
      @name = name
      @type = type
      @required = args[:required].nil? ? true : args[:required]
      @filter_from_requests = filter_from_requests.yield_self { |f| f.in?([true, false]) ? f : f&.to_sym }
      @value = fetch_value(args.slice(:passthrough, :default_value))
      @defined = true
    rescue KeyError
      @value = args[:default_value]
      @defined = false
    end

    def to_const
      raise EnvironmentVariableNotPresentError, [self] unless defined

      Object.const_set(name, typecast_value)
    end

    def set?
      return false unless defined

      return value.present? if required

      true
    end

    def add_to_env_file
      return if present_in_env_file?

      File.write(ENV_FILE, "#{name}=#{value}\n", mode: 'a')
    end

    def filter_from_vcr_cassettes(config)
      return if @filter_from_requests.blank?

      config.filter_sensitive_data('<PASSWORD>') do
        case @filter_from_requests
        when :alone_as_basic_auth_password
          Base64.encode64(['', @value].join(':')).delete("\n")
        when true
          @value
        end
      end
      config
    end

    private

    def present_in_env_file?
      File.open(ENV_FILE) { |f| f.each_line.find { |line| line.start_with?("#{name}=") } }
    end

    def to_env_assign
      "#{name}=#{value}\n"
    end

    def typecast_value
      return value if value.nil?

      Kernel.public_send(type.to_sym, value)
    end

    def fetch_value(passthrough: false, default_value: nil)
      return (default_value || name) if ENV['RAILS_ENV'] == 'test' && !passthrough

      required ? ENV.fetch(name.to_s) : ENV[name.to_s]
    end
  end
end
