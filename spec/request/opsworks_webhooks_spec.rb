require 'rails_helper'

RSpec.describe 'OpsWorks webhooks', type: :request do
  describe 'POST #create' do
    let(:webhook_secret) { SecureRandom.hex }
    let(:bugsnag_reporter) { spy('Bugsnag reporter') }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('OPSWORKS_WEBHOOK_SECRET').and_return(webhook_secret)

      allow(Bugsnag).to receive(:notify).and_yield(bugsnag_reporter)
      allow(Rails.logger).to receive(:warn).and_call_original
    end

    let(:payload) { build(:opsworks_deployment_webhook).to_json }

    subject { post webhook_opsworks_path, params: payload, headers: headers }

    context 'with valid signature' do
      let(:digest) { OpenSSL::HMAC.hexdigest('sha256', webhook_secret, payload) }
      let(:headers) { { 'X-Signature' => "sha256=#{digest}" } }

      it 'returns 201' do
        subject

        expect(response).to have_http_status(:created)
        expect(Bugsnag).not_to have_received(:notify)
        expect(Rails.logger).not_to have_received(:warn)
      end
    end

    context 'with invalid signature' do
      let(:headers) do
        { 'X-Signature' => 'sha256=wrong' }
      end

      it 'returns 201 and logs error' do
        subject

        aggregate_failures do
          expect(response).to have_http_status(:created)

          expect(Bugsnag).to have_received(:notify).with(/signature mismatch/i)
          expect(bugsnag_reporter).to have_received(:add_tab)
          expect(Rails.logger).to have_received(:warn).with(/signature mismatch/i)
        end
      end
    end

    context 'with missing signature' do
      let(:headers) { {} }

      it 'returns 201 and logs error' do
        subject

        aggregate_failures do
          expect(response).to have_http_status(:created)

          expect(Bugsnag).to have_received(:notify).with(/signature mismatch/i)
          expect(bugsnag_reporter).to have_received(:add_tab)
          expect(Rails.logger).to have_received(:warn).with(/signature mismatch/i)
        end
      end
    end
  end
end
