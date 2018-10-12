class Timesheet < ApplicationRecord
  belongs_to :board_ticket, touch: true
  belongs_to :swimlane, touch: true
  belongs_to :before_swimlane, class_name: 'Swimlane', optional: true
  belongs_to :after_swimlane, class_name: 'Swimlane', optional: true
  has_one :ticket, through: :board_ticket
  has_one :board, through: :board_ticket
end
