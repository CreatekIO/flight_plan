class Timesheet < ApplicationRecord
  belongs_to :board_ticket
  belongs_to :swimlane
  belongs_to :before_swimlane, class_name: 'Swimlane', optional: true
  belongs_to :after_swimlane, class_name: 'Swimlane', optional: true
  has_one :ticket, through: :board_ticket
  has_one :board, through: :board_ticket
end
