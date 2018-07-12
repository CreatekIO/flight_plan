FactoryBot.definition_file_paths = %w( spec/support/factories )
FactoryBot.find_definitions

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

