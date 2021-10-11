class LabellingBroadcast < ApplicationBroadcast
  delegate :board_ticket, to: :labelling

  def created
    return if labelling.label.for_swimlane_status?

    broadcast_to_board(
      'ticket/labelled',
      labelling.slice(:ticket_id).merge(
        board_ticket_id: board_ticket.id,
        label: blueprint(labelling.label)
      ),
      board: board_ticket.board
    )
  end

  def destroyed
    return if labelling.label.for_swimlane_status?

    broadcast_to_board(
      'ticket/unlabelled',
      labelling.slice(:ticket_id, :label_id).merge(
        board_ticket_id: board_ticket.id
      ),
      board: board_ticket.board
    )
  end
end
