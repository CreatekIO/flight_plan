class TicketRefreshWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5

  def perform(ticket_id)
    ticket = Ticket.find(ticket_id)
  rescue ActiveRecord::RecordNotFound => error
    Bugnsag.notify(error)
  else
    TicketRefresher.new(ticket).run
  end
end
