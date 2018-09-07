require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  describe '.permissive_enum' do
    let(:table_name) { 'permissive_enum_tests' }

    before do
      allow(Bugsnag).to receive(:notify)
    end

    around do |example|
      described_class.connection.create_table(table_name, force: true) do |t|
        t.string :state
      end

      # Define class after its table has been created
      class PermissiveEnumTest < described_class
        permissive_enum state: { opened: 'opened', closed: 'closed' } unless defined_enums.any?
      end

      example.run

      described_class.connection.drop_table(table_name)
    end

    it 'allows values not in enum' do
      record = PermissiveEnumTest.new(state: 'not_allowed')

      aggregate_failures do
        expect(Bugsnag).to have_received(:notify).with(an_instance_of(ArgumentError))

        expect(record.state).to eq('not_allowed')

        expect { record.save! }.not_to raise_error

        expect(record.reload.state).to eq('not_allowed')
      end
    end

    it 'still allows values in enum' do
      record = PermissiveEnumTest.new(state: 'opened')

      aggregate_failures do
        expect(record.state).to eq('opened')
        expect(record.opened?).to eq(true)

        expect { record.save! }.not_to raise_error

        expect(record.reload.state).to eq('opened')
        expect(record.class.opened).to include(record)
      end
    end
  end
end
