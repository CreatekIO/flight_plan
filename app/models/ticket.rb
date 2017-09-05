class Ticket < ApplicationRecord 
  has_many :timesheets
  after_commit :update_remote, on: :update, if: :state_previously_changed?

  def update_timesheet
    timesheets.create!(
      started_at: Time.now,
      state: state,
      before_state: state_previous_change.first
    )
  end

  def update_remote
    # TODO: need to be able to recover if github does not respond, 
    # possibly moving to a background job
    if state == 'Closed'
      Octokit.close_issue('createkio/flight_plan', remote_number)
    elsif state_previous_change.first == 'Closed'
      Octokit.reopen_issue('createkio/flight_plan', remote_number)
    end
  end
end
