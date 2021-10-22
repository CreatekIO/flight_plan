class InDevelopmentRule < ApplicationRule
  alias_record_as :head

  trigger 'BranchHead', :created do
    pushed_to_feature_branch? && board_ticket.in_swimlane?(/planning - done/i)
  end

  delegate :board_ticket, to: :linked_ticket

  def call
    ApplicationRecord.transaction do
      move(board_ticket, to: 'Development')
      assign_pusher
    end
  end

  private

  def pushed_to_feature_branch?
    linked_ticket.present?
  end

  def linked_ticket
    @linked_ticket ||= head.branch.ticket
  end

  def assign_pusher
    linked_ticket.assignments
      .create_with(assignee_username: head.pusher_username)
      .find_or_create_by!(assignee_remote_id: head.pusher_remote_id)
  end
end
