class Ticket < ApplicationRecord
  has_many :timesheets
  has_one :open_timesheet, -> { where(ended_at: nil) }, class_name: "Timesheet"

  after_save :update_timesheet, if: :saved_change_to_state?
  after_commit :update_remote, on: :update, if: :saved_change_to_state?

  private

  def update_timesheet
    time_now = Time.now

    if open_timesheet
      open_timesheet.update_attributes(
        ended_at: time_now,
        after_state: state
      )
    end

    timesheets.create!(
      started_at: time_now,
      state: state,
      before_state: attribute_before_last_save(:state)
    )
  end

  def update_remote
    # TODO: need to be able to recover if github does not respond,
    # possibly moving to a background job
    if state == 'Closed'
      Octokit.close_issue('createkio/flight_plan', remote_number)
    elsif attribute_before_last_save(:state) == 'Closed'
      Octokit.reopen_issue('createkio/flight_plan', remote_number)
    end
  end
end
