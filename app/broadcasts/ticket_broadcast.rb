class TicketBroadcast < ApplicationBroadcast
  delegate :board_ticket, :milestone, to: :ticket

  changed :title do
    broadcast_change(ticket, :title, to: ticket.board)
  end

  changed :milestone_id do
    if milestone
      broadcast_to_board(
        'ticket/milestoned',
        ticket_id: ticket.id,
        board_ticket_id: board_ticket.id,
        milestone: blueprint(milestone)
      )
    else
      broadcast_to_board(
        'ticket/demilestoned',
        ticket_id: ticket.id,
        board_ticket_id: board_ticket.id
      )
    end
  end
end
