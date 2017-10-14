class Webhook::GithubController < Webhook::BaseController
  include GithubWebhook::Processor

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def github_ping(paylog)
    p paylog
  end

  def github_issues(_payload)
    Ticket.import_from_remote(json_body[:issue], json_body[:repository])
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
