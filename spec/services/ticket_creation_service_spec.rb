require 'rails_helper'

RSpec.describe TicketCreationService do
  describe '.create_ticket' do
    let!(:repo) { create(:repo) }
    let(:attributes) do
      {
        title: 'A new ticket',
        description: 'This is a new ticket',
        repo_id: repo.id
      }
    end
    it 'creates a new github ticket' do
      expect { described_class.new(attributes).create_ticket }.to change { repo.tickets.count }.by(1)
    end
  end
end
