# frozen_string_literal: true

# Wrapper for retrieval of environment variables. See
# config/initializers/environment_variable_loader.rb to check out how it's used.
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/object/blank"
require "yaml"

module Nvar
  # Wrapper for loading environment variables, used across relevant Rake tasks
  class EnvironmentVariable
    attr_reader :name, :type, :value, :required, :defined

    def initialize(name:, type: "String", filter_from_requests: nil, **args)
      @name = name
      @type = type
      @required = args[:required].nil? ? true : args[:required]
      @filter_from_requests = filter_from_requests.yield_self { |f| [true, false].include?(f) ? f : f&.to_sym }
      @value = fetch_value(**args.slice(:passthrough, :default_value).with_defaults(passthrough: ENV.fetch("NVAR_PASSTHROUGH", "").split(",").include?(name)))
      @defined = true
    rescue KeyError
      @value = args[:default_value]
      @defined = false
    end

    def to_const
      raise Nvar::EnvironmentVariableNotPresentError, self unless defined

      Object.const_set(name, typecast_value)
    end

    def set?
      return false unless defined

      return value.present? if required

      true
    end

    def add_to_env_file
      return if present_in_env_file?

      File.write(Nvar.env_file_path, to_env_assign, mode: "a")
    end

    def filter_from_vcr_cassettes(config)
      return if @filter_from_requests.nil? || !@filter_from_requests

      config.filter_sensitive_data("<#{name}>") do
        # :nocov:
        case @filter_from_requests
        when :alone_as_basic_auth_password
          Base64.encode64(["", @value].join(":")).delete("\n")
        when true
          @value
        end
        # :nocov:
      end
      config
    end

    private

    def present_in_env_file?
      File.open(Nvar.env_file_path) { |f| f.each_line.find { |line| line.start_with?("#{name}=") } }
    end

    def to_env_assign
      "#{name}=#{value}\n"
    end

    def typecast_value
      return value if value.nil?

      Kernel.public_send(type.to_sym, value)
    end

    def fetch_value(passthrough: false, default_value: nil)
      return default_value || name if ENV["RAILS_ENV"] == "test" && !passthrough

      required ? ENV.fetch(name.to_s) : ENV[name.to_s]
    end
  end
end
