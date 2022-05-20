class CodeReviewCompleteRule < ApplicationRule
  alias_record_as :pull_request

  trigger 'PullRequest', :changed, :merged do
    pull_request.merged? && connected_tickets.any? { |ticket| in_code_review?(ticket) }
  end

  def call
    pull_request.tickets.includes(:pull_requests).each do |ticket|
      next unless in_code_review?(ticket)
      next unless ticket.pull_requests.all?(&:merged?)

      move(ticket.board_ticket, to: 'Code Review - DONE')
    end
  end

  private

  def connected_tickets
    @connected_tickets ||= pull_request.tickets.includes(board_ticket: :swimlane)
  end

  def in_code_review?(ticket)
    ticket.board_ticket.in_swimlane?(/^code review$/i)
  end
end
