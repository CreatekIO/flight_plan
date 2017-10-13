class Webhook::GithubController < Webhook::BaseController
  include GithubWebhook::Processor

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def github_ping(paylog)
    p paylog
  end

  def github_issues(_payload)
    case json_body[:action] 
    when 'labeled'
      new_swimlane = board_ticket.board.swimlanes.find_by_label!(json_body[:label][:name])
      board_ticket.update(swimlane: new_swimlane)
    when 'unlabeled'
      if no_status_labels? && json_body[:issue][:state] == 'open'
        new_swimlane = board_ticket.board.swimlanes.order(:position).first
        board_ticket.update(swimlane: new_swimlane)
      end
    when 'closed'
      board_ticket.close(update_remote: false)
    end
  end

  def board_ticket
    ticket = Ticket.find_by!(remote_id: json_body[:issue][:id])
    ticket.board_tickets.first!
  end

  def no_status_labels?
    json_body[:issue][:labels].none? do |label|
      label[:name].start_with? 'status:'
    end
  end

  def not_found
    head :not_found
  end

  def webhook_secret(_payload)
    ENV['GITHUB_WEBHOOK_SECRET']
  end

end
