require 'spec_helper'
require "active_support/core_ext/hash/except"

RSpec.describe Nvar::EnvironmentVariableNotPresentError do
  subject(:error) { described_class.new(Struct.new(:name).new('TEST_ENVIRONMENT_VARIABLE'))}

  describe "#message" do
    subject { error.message }

    it { is_expected.to eq("The following variables are unset or blank: TEST_ENVIRONMENT_VARIABLE")}
  end
end

RSpec.describe Nvar::EnvironmentVariable do
  before do
    stub_const("Nvar::EnvironmentVariable::CONFIG_FILE", 'spec/fixtures/files/nvar_config.yml')
  end

  base_args = {
    name: 'TEST_ENVIRONMENT_VARIABLE',
    type: 'String',
    filter_from_requests: nil,
    required: true,
    passthrough: false,
    default_value: 'default_value'
  }

  let(:args) { base_args }

  let(:environment_variable) { described_class.new(**args) }

  base_env = {
    REQUIRED_ENV_VAR: 'value',
    REQUIRED_FILTERED_ENV_VAR: 'secret_value',
    OPTIONAL_FILTERED_ENV_VAR: nil,
    REQUIRED_ENV_VAR_WITH_TYPED_DEFAULT: '42',
    OPTIONAL_ENV_VAR: nil,
    REQUIRED_ENV_VAR_WITH_DEFAULT: 'redis://127.0.0.1:6380',
    REQUIRED_BASIC_AUTH_FILTERED_ENV_VAR: 'secret_value'
  }

  around { |example|
    ClimateControl.modify(**env) { example.run }
    env.keys.each do
      Object.send(:remove_const, _1)
    rescue NameError
    end
  }

  let(:env) { base_env }

  describe "::load_all" do
    subject(:load_all) { described_class.load_all }

    it { is_expected.to be_an Array }
    it { is_expected.to have_attributes(size: 2) }
    it { is_expected.to contain_exactly(
      contain_exactly(*env.map { have_attributes(name: _1[0], value: _1[1]) }),
      []
    ) }

    context 'when a required env var is missing' do
      let(:env) { base_env.except(:REQUIRED_ENV_VAR) }

      it 'raises an error' do
        expect { load_all }.to raise_error Nvar::EnvironmentVariableNotPresentError, "The following variables are unset or blank: REQUIRED_ENV_VAR"
      end
    end
  end

  describe "::verify_env" do
    before { stub_const("Nvar::EnvironmentVariable::ENV_FILE", env_file.path) }
    after { env_file.unlink }

    subject {
      described_class.verify_env
      File.read(env_file)
    }

    let(:env_file) { Tempfile.new }

    context 'when the env file exists and a required environment variable is unset' do
      let!(:env) { base_env.except(:REQUIRED_ENV_VAR) }

      it { is_expected.to match /REQUIRED_ENV_VAR=\n/ }
    end

    context 'when the env file exists and an optional environment variable is unset' do
      let!(:env) { base_env.except(:OPTIONAL_ENV_VAR) }
    end

    context 'when the env file exists and an environment variable with a default value is unset' do
      let!(:env) { base_env.except(:REQUIRED_ENV_VAR_WITH_TYPED_DEFAULT) }

      it { is_expected.to match /REQUIRED_ENV_VAR_WITH_TYPED_DEFAULT=8\n/ }
    end

    context 'when the env file does not exist and environment variables are unset' do
      let!(:env) { base_env.except(:REQUIRED_ENV_VAR) }
      before { allow(File).to receive(:exist?).with(env_file.path).and_return(false) }

      it { is_expected.to match /REQUIRED_ENV_VAR=\n/ }
    end

    context 'when the env file does not exist and environment variables are unset' do
      let!(:env) { base_env.except(:REQUIRED_ENV_VAR) }
      before { allow(File).to receive(:exist?).with(env_file.path).and_return(false) }

      it { is_expected.to start_with Nvar::EnvironmentVariable::ENV_COMMENT }
    end

    context 'when the env file does not exist and all environment variables are set' do
      before { allow(File).to receive(:exist?).with(env_file.path).and_return(false) }

      it { is_expected.to be_empty }
    end
  end

  describe '#initialize' do
    subject(:initializer) { environment_variable }

    context 'when name is absent' do
      let(:args) { base_args.except(:name) }

      it { expect { initializer }.to raise_error ArgumentError }
    end
  end

  describe '#filter_from_vcr_cassettes' do
    let(:config) { VCR.configuration.dup }
    subject(:configure) { environment_variable.filter_from_vcr_cassettes(config) }

    context 'when filter_from_requests is nil' do
      let(:args) { base_args.merge(filter_from_requests: nil) }

      it { is_expected.to be_nil }
    end

    context 'when filter_from_requests is false' do
      let(:args) { base_args.merge(filter_from_requests: false) }

      it { is_expected.to be_nil }
    end

    context 'when filter_from_requests is true' do
      let(:args) { base_args.merge(filter_from_requests: true) }
      before { allow(config).to receive(:filter_sensitive_data) }

      it { is_expected.to be_a VCR::Configuration }
      it { configure; expect(config).to have_received(:filter_sensitive_data).with("<#{environment_variable.name}>") }
    end

    context 'when filter_from_requests is :alone_as_basic_auth_password' do
      let(:args) { base_args.merge(filter_from_requests: :alone_as_basic_auth_password) }
      before { allow(config).to receive(:filter_sensitive_data) }

      it { is_expected.to be_a VCR::Configuration }
      it { configure; expect(config).to have_received(:filter_sensitive_data).with("<#{environment_variable.name}>") }
    end
  end

  describe '#type' do
    subject { environment_variable.type }

    context 'when type is absent' do
      let(:args) { base_args.except(:type) }

      it { is_expected.to eq('String') }
    end
  end

  describe '#required' do
    subject { environment_variable.required }

    context 'when required is absent' do
      let(:args) { base_args.except(:required) }

      it { is_expected.to eq(true) }
    end

    context 'when required is present' do
      it { is_expected.to eq(args[:required]) }
    end
  end

  describe '#value' do
    subject { environment_variable.value }

    around { |example| ClimateControl.modify(args[:name] => 'passthrough_value', 'RAILS_ENV' => 'test') { example.run } }

    context 'when passthrough is false and a default value is provided' do
      let(:args) { base_args.merge(passthrough: false, default_value: 'default_value') }

      it { is_expected.to eq('default_value') }
    end

    context 'when passthrough is true and a default value is provided' do
      let(:args) { base_args.merge(passthrough: true, default_value: 'default_value') }

      it { is_expected.to eq('passthrough_value') }
    end

    context 'when passthrough is false and a default value is not provided' do
      let(:args) { base_args.merge(passthrough: false, default_value: nil) }

      it { is_expected.to eq(environment_variable.name) }
    end

    context 'when passthrough is true and a default value is not provided' do
      let(:args) { base_args.merge(passthrough: true, default_value: nil) }

      it { is_expected.to eq('passthrough_value') }
    end
  end
end
