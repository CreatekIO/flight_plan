class TicketAssignmentBroadcast < ApplicationBroadcast
  delegate :ticket, to: :ticket_assignment
  delegate :board, :board_ticket, to: :ticket

  def created
    broadcast_to_board(
      'ticket/assigned',
      ticket_assignment.slice(:ticket_id).merge(
        board_ticket_id: board_ticket.id,
        assignee: blueprint(ticket_assignment)
      ),
      board: board
    )
  end

  def destroyed
    broadcast_to_board(
      'ticket/unassigned',
      ticket_assignment.slice(:ticket_id).merge(
        board_ticket_id: board_ticket.id,
        assignee: blueprint(ticket_assignment)
      ),
      board: board
    )
  end
end
