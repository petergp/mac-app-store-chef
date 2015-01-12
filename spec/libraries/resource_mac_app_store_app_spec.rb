# Encoding: UTF-8

require_relative '../spec_helper'
require_relative '../../libraries/resource_mac_app_store_app'

describe Chef::Resource::MacAppStoreApp do
  let(:platform) { { platform: 'mac_os_x', version: '10.9.2' } }
  let(:node) { Fauxhai.mock(platform).data }
  let(:app_name) { 'Some App' }
  let(:app_id) { 'com.example.someapp' }
  let(:package_url) { nil }
  let(:resource) do
    r = described_class.new(app_name, nil)
    r.app_id(app_id)
    r
  end

  before(:each) do
    allow_any_instance_of(described_class).to receive(:node).and_return(node)
  end

  shared_examples_for 'an invalid configuration' do
    it 'raises an exception' do
      expect { resource }.to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe '#initialize' do
    it 'sets the correct resource name' do
      exp = :mac_app_store_app
      expect(resource.instance_variable_get(:@resource_name)).to eq(exp)
    end

    it 'sets the correct provider' do
      exp = Chef::Provider::MacAppStoreApp
      expect(resource.instance_variable_get(:@provider)).to eq(exp)
    end

    it 'sets the correct supported actions' do
      expected = [:install]
      expect(resource.instance_variable_get(:@allowed_actions)).to eq(expected)
    end

    it 'defaults the state to uninstalled' do
      expect(resource.instance_variable_get(:@installed)).to eq(false)
    end
  end

  [:installed, :installed?].each do |m|
    describe "##{m}" do
      context 'app installed' do
        it 'returns true' do
          r = resource
          r.instance_variable_set(:@installed, true)
          expect(r.send(m)).to eq(true)
        end
      end

      context 'app not installed' do
        it 'returns false' do
          expect(resource.send(m)).to eq(false)
        end
      end
    end
  end

  describe '#app_id' do
    context 'no override' do
      let(:app_id) { nil }

      it_behaves_like 'an invalid configuration'
    end

    context 'a valid override' do
      let(:app_id) { 'com.example.someapp' }

      it 'returns the override' do
        expect(resource.app_id).to eq(app_id)
      end
    end

    context 'an invalid override' do
      let(:app_id) { :something }

      it_behaves_like 'an invalid configuration'
    end
  end
end