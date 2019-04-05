class TicketAssignment < ApplicationRecord
  belongs_to :ticket, inverse_of: :assignments
  belongs_to :assignee, class_name: 'User', foreign_key: :assignee_remote_id, primary_key: :uid, optional: true
end
