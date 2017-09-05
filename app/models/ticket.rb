class Ticket < ApplicationRecord

  after_commit :update_remote

  private

  def update_remote
    # TODO: need to be able to recover if github does not respond, 
    # possibly moving to a background job
    if state_previously_changed?
      if state == 'Closed'
        Octokit.close_issue('createkio/flight_plan', remote_number)
      elsif state_previous_change.first == 'Closed'
        Octokit.reopen_issue('createkio/flight_plan', remote_number)
      end
    end
  end

end
