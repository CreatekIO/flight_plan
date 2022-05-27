require 'rails_helper'

RSpec.describe JobMonitor do
  let(:api_key) { 'test-api-key' }

  before do
    stub_const("#{described_class}::PING_KEY", api_key)
    stub_request(:any, %r{^https://hc-ping.com/})
  end

  describe '.measure' do
    let(:name) { 'test-task' }

    it 'sends requests for start and end' do
      result = described_class.measure(name) { :result }

      aggregate_failures do
        expect(WebMock).to have_requested(:get, "https://hc-ping.com/#{api_key}/#{name}/start")
        expect(WebMock).to have_requested(:get, "https://hc-ping.com/#{api_key}/#{name}")
        expect(result).to eq(:result)
      end
    end

    context 'no API key set' do
      before do
        stub_const("#{described_class}::PING_KEY", '')
      end

      it 'does not send any requests' do
        result = described_class.measure(name) { :result }

        aggregate_failures do
          expect(WebMock).not_to have_requested(:get, %r{^https://hc-ping.com/})
          expect(result).to eq(:result)
        end
      end
    end

    context 'error raised by API' do
      before do
        stub_request(:any, %r{^https://hc-ping.com/.+/start}).to_timeout
        allow(Bugsnag).to receive(:notify)
      end

      it 'does not raise an error' do
        result = nil

        aggregate_failures do
          expect {
            result = described_class.measure(name) { :result }
          }.not_to raise_error

          expect(result).to eq(:result)
          expect(Bugsnag).to have_received(:notify).with a_kind_of(Exception)
        end
      end
    end

    context 'error raised by block' do
      class CustomTestError < Exception; end

      it 'propagates error, but sends requests for start and fail' do
        aggregate_failures do
          expect {
            described_class.measure(name) { raise CustomTestError, 'block failed' }
          }.to raise_error(CustomTestError)

          expect(WebMock).to have_requested(:get, "https://hc-ping.com/#{api_key}/#{name}/start")
          expect(WebMock).to have_requested(:get, "https://hc-ping.com/#{api_key}/#{name}/fail")
        end
      end
    end
  end
end
