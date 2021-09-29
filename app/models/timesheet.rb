class Timesheet < ApplicationRecord
  belongs_to :board_ticket
  belongs_to :swimlane
  belongs_to :before_swimlane, class_name: 'Swimlane', optional: true
  belongs_to :after_swimlane, class_name: 'Swimlane', optional: true
  has_one :ticket, through: :board_ticket
  has_one :board, through: :board_ticket

  def self.format_duration(seconds)
    if seconds < 1.hour
      '< 1h'
    elsif seconds < 8.hours
      "#{(seconds / 1.hour).floor}h"
    else
      "#{(seconds / 8.hours).floor}d"
    end
  end

  def duration
    started_at.business_time_until(ended_at || Time.now)
  end
end
