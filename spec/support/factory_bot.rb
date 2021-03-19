FactoryBot.definition_file_paths = %w[spec/support/factories]

FactoryBot.define do
  def fp_number_generator(start, step: 2)
    start.step(Float::INFINITY, step).lazy.map(&:to_i)
  end

  sequence(:sha) { SecureRandom.hex(20) }
  sequence(:hex_colour) { format('%06x', (rand * 0xffffff)) }

  sequence(:user_id, 10_000)
  sequence(:label_id, 2_000_000_000)

  # Generates odd numbers
  sequence(:issue_number, fp_number_generator(1))
  sequence(:issue_remote_id, fp_number_generator(200_000_001))

  # Generates even numbers
  sequence(:pr_number, fp_number_generator(2))
  sequence(:pr_remote_id, fp_number_generator(200_000_002))
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end
end
