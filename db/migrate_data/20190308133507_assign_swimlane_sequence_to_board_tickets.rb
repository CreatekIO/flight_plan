class AssignSwimlaneSequenceToBoardTickets < ActiveRecord::Migration["4.2"]
  def up
    Swimlane.all.each do |swimlane|
      say_with_time "Assigning positions for swimlane ##{swimlane.id}..." do
        board_tickets = swimlane.board_tickets.order(:updated_at).load

        board_tickets.zip(positions[board_tickets.length]).each do |(board_ticket, position)|
          next if board_ticket.swimlane_sequence.present?

          board_ticket.update_column(:swimlane_sequence, position)
        end
      end
    end
  end

  private

  def positions
    @positions ||= Hash.new do |cache, key|
      low = RankedModel::MIN_RANK_VALUE
      high = RankedModel::MAX_RANK_VALUE

      if key > 1
        cache[key] = Array.new(key) { |n| (low + n.to_f * (high-low)/(key-1)).ceil }
      else
        cache[key] = [0]
      end
    end
  end
end
