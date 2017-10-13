class BoardTicket < ApplicationRecord
  belongs_to :board
  belongs_to :ticket
  belongs_to :swimlane
  has_many :timesheets, dependent: :destroy
  has_one :open_timesheet, -> { where(ended_at: nil) }, class_name: "Timesheet"
   
  after_save :update_timesheet, if: :saved_change_to_swimlane_id?
  after_commit :update_remote, on: :update, if: :saved_change_to_swimlane_id?

  attr_writer :should_update_remote

  def state_durations
    timesheets.each_with_object(Hash.new 0) do |timesheet, durations|
      durations[timesheet.swimlane.name] += (timesheet.ended_at || Time.now) - timesheet.started_at
    end
  end

  def current_state_duration
    format_duration(state_durations[swimlane.name])
  end

  def displayable_durations(board)
    durations = state_durations

    board.swimlanes.where(display_duration: true).map do |swimlane|
      next if durations[swimlane.name].zero?
      {
        name: swimlane.name,
        duration: format_duration(durations[swimlane.name])
      }
    end.compact
  end

  def close(update_remote: true)
    update(swimlane: closed_swimlane, should_update_remote: update_remote)
  end

  private

  def should_update_remote?
    unless defined? @should_update_remote
      @should_update_remote = true
    end
    @should_update_remote 
  end

  def format_duration(seconds)
    if seconds < 1.hour
      "< 1h"
    elsif seconds < 24.hours
      "#{(seconds / 1.hour).floor}h"
    else
      "#{(seconds / 24.hours).floor}d"
    end
  end

  def update_timesheet
    time_now = Time.now

    if open_timesheet
      open_timesheet.update_attributes(
        ended_at: time_now,
        after_swimlane: swimlane
      )
    end

    what = timesheets.create!(
      started_at: time_now,
      swimlane: swimlane,
      before_swimlane_id: attribute_before_last_save(:swimlane_id)
    )
  end

  def update_remote
    return unless should_update_remote?

    # TODO: need to be able to recover if github does not respond,
    # possibly moving to a background job
    
    if swimlane_id == closed_swimlane.id
      Octokit.close_issue('createkio/flight_plan', ticket.remote_number)
    elsif attribute_before_last_save(:swimlane_id) == closed_swimlane.id
      Octokit.reopen_issue('createkio/flight_plan', ticket.remote_number)
    end
  end

  def closed_swimlane
    # TODO: need to signify which column is the closed column on a board via config (not hard coded)
    board.swimlanes.order(:position).last
  end

end
