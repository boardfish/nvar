require 'spec_helper'
require "active_support/core_ext/hash/except"

RSpec.describe Nvar::EnvironmentVariable do
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

  describe '#filter_from_vcr_cassettes' do
    subject { environment_variable.filter_from_vcr_cassettes }

    context 'when filter_from_requests is nil'
    context 'when filter_from_requests is false'
    context 'when filter_from_requests is not an accepted value'
    context 'when filter_from_requests is :alone_as_basic_auth_password'
    context 'when filter_from_requests is true'
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