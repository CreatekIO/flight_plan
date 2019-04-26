module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_user_from_session
    end

    private

    def find_user_from_session
      env['warden'].user.tap do |user|
        reject_unauthorized_connection if user.blank?
      end
    end
  end
end
