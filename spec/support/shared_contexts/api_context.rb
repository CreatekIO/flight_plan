RSpec.shared_context 'api' do
  let(:params) { nil }
  let(:api_headers) {
    {
      'Authorization' => 'Token token=key:secret',
      'ACCEPT' => 'application/json'
    }
  }
end
