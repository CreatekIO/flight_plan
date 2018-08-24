FactoryBot.definition_file_paths = %w( spec/support/factories )
FactoryBot.find_definitions

FactoryBot.define do
  def fp_number_generator(start, step: 2)
    start.step(Float::INFINITY, step).lazy
  end

  sequence(:sha) { SecureRandom.hex(20) }

  sequence(:user_id, 10_000)

  # Generates odd numbers
  sequence(:issue_number, fp_number_generator(1))
  sequence(:issue_remote_id, fp_number_generator(200_000_001))

  # Generates even numbers
  sequence(:pr_number, fp_number_generator(2))
  sequence(:pr_remote_id, fp_number_generator(200_000_002))
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

