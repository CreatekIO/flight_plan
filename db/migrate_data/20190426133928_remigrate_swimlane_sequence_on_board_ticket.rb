class RemigrateSwimlaneSequenceOnBoardTicket < ActiveRecord::Migration["4.2"]
  class BoardTicket < ActiveRecord::Base
  end

  def up
    all_board_tickets.each do |swimlane_id, board_tickets|
      say_with_time "Processing Swimlane ##{swimlane_id}" do
        board_tickets.each_with_index do |board_ticket, index|
          board_ticket.update_columns(
            swimlane_sequence: index * 1024
          )
        end
      end
    end
  end

  private

  def all_board_tickets
    @all_board_tickets ||= BoardTicket
      .reorder(swimlane_id: :asc, swimlane_sequence: :asc, updated_at: :desc)
      .group_by(&:swimlane_id)
  end
end
