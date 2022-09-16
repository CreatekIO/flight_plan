class ReadyForCodeReviewRule < ApplicationRule
  alias_record_as :pr_connection

  setting :destination_swimlane_name, default: 'Code Review'

  trigger 'PullRequestConnection', :created do
    board_ticket.in_swimlane?(/development|demo - done/i)
  end

  delegate :board_ticket, to: 'pr_connection.ticket'

  def call
    move(board_ticket, to: destination_swimlane_name)
  end
end
