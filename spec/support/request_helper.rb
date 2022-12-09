module RequestHelper
  module ClassMethods
    def with_forgery_protection!
      around do |example|
        previous_value = ActionController::Base.allow_forgery_protection
        ActionController::Base.allow_forgery_protection = true

        example.run
      ensure
        ActionController::Base.allow_forgery_protection = previous_value
      end
    end
  end

  def json
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include RequestHelper, type: :request
  config.extend RequestHelper::ClassMethods, type: :request
end
