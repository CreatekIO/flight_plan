class TicketBroadcast < ApplicationBroadcast
  delegate :milestone, to: :ticket

  changed :title do
    broadcast_change(ticket, :title, to: ticket.board)
  end
end
