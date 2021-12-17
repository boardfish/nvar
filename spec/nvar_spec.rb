# frozen_string_literal: true

RSpec.describe Nvar do
  before { described_class.config_file_path = 'spec/fixtures/files/nvar_config.yml' }

  it 'has a version number' do
    expect(described_class::VERSION).not_to be nil
  end

  base_env = {
    REQUIRED_ENV_VAR: 'value',
    REQUIRED_FILTERED_ENV_VAR: 'secret_value',
    OPTIONAL_FILTERED_ENV_VAR: nil,
    REQUIRED_ENV_VAR_WITH_TYPED_DEFAULT: '42',
    OPTIONAL_ENV_VAR: nil,
    REQUIRED_ENV_VAR_WITH_DEFAULT: 'redis://127.0.0.1:6380',
    REQUIRED_BASIC_AUTH_FILTERED_ENV_VAR: 'secret_value'
  }

  around do |example|
    ClimateControl.modify(**env) { example.run }
    env.keys.each do
      Object.send(:remove_const, _1)
  rescue NameError # rubocop:disable Lint/SuppressedException
    end
  end

  let(:env) { base_env }

  describe '::filter_from_vcr_cassettes' do
    let(:config) { VCR.configuration.dup }
    subject(:configure) { described_class.filter_from_vcr_cassettes(config) }

    it { is_expected.to be_a VCR::Configuration }
  end

  describe '::load_all' do
    subject(:load_all) { described_class.load_all }

    it { is_expected.to be_an Array }
    it { is_expected.to have_attributes(size: 2) }
    it {
      is_expected.to contain_exactly(
        contain_exactly(*env.map { have_attributes(name: _1[0], value: _1[1]) }),
        []
      )
    }

    context 'when a required env var is missing' do
      let(:env) { base_env.except(:REQUIRED_ENV_VAR) }

      it 'raises an error' do
        expect do
          load_all
        end.to raise_error Nvar::EnvironmentVariableNotPresentError,
                           'The following variables are unset or blank: REQUIRED_ENV_VAR'
      end
    end
  end

  describe '::verify_env' do
    before { described_class.env_file_path = env_file.path }
    after { env_file.unlink }

    subject do
      described_class.verify_env
      File.read(env_file)
    end

    let(:env_file) { Tempfile.new }

    context 'when the env file exists and a required environment variable is unset' do
      let!(:env) { base_env.except(:REQUIRED_ENV_VAR) }

      it { is_expected.to match(/REQUIRED_ENV_VAR=\n/) }
    end

    context 'when the env file exists and an optional environment variable is unset' do
      let!(:env) { base_env.except(:OPTIONAL_ENV_VAR) }
    end

    context 'when the env file exists and an environment variable with a default value is unset' do
      let!(:env) { base_env.except(:REQUIRED_ENV_VAR_WITH_TYPED_DEFAULT) }

      it { is_expected.to match(/REQUIRED_ENV_VAR_WITH_TYPED_DEFAULT=8\n/) }
    end

    context 'when the env file does not exist and environment variables are unset' do
      let!(:env) { base_env.except(:REQUIRED_ENV_VAR) }
      before { allow(File).to receive(:exist?).with(env_file.path).and_return(false) }

      it { is_expected.to match(/REQUIRED_ENV_VAR=\n/) }
    end

    context 'when the env file does not exist and environment variables are unset' do
      let!(:env) { base_env.except(:REQUIRED_ENV_VAR) }
      before { allow(File).to receive(:exist?).with(env_file.path).and_return(false) }

      it { is_expected.to start_with Nvar::ENV_COMMENT }
    end

    context 'when the env file does not exist and all environment variables are set' do
      before { allow(File).to receive(:exist?).with(env_file.path).and_return(false) }

      it { is_expected.to be_empty }
    end
  end
end
