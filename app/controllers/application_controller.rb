class ApplicationController < ActionController::Base
  private

  def json_array_from(records)
    Jbuilder.encode do |json|
      json.array! records do |record|
        json.merge! record.to_builder.attributes!
      end
    end
  end
end
