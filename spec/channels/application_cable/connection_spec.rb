require 'rails_helper'

RSpec.describe ApplicationCable::Connection do
  # Based on code from Devise::Test::ControllerHelpers
  let!(:warden) do
    manager = Warden::Manager.new(nil) do |config|
      config.merge! Devise.warden_config
    end

    Warden::Proxy.new({}, manager)
  end

  around do |example|
    Warden.test_mode!
    example.run
    Warden.test_reset!
  end

  def sign_in(user)
    warden.set_user(user)
  end

  subject do
    connect env: { 'warden' => warden }
  end

  context 'with user in session' do
    let(:user) { build_stubbed(:user) }

    it 'successfully connects' do
      sign_in user

      subject

      expect(connection.current_user).to eq(user)
    end
  end

  context 'without user in session' do
    it 'rejects connection' do
      expect { subject }.to have_rejected_connection
    end
  end
end
