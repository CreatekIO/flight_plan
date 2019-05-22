class CorrectSwimlaneForClosedTickets < ActiveRecord::Migration["4.2"]
  def up
    return say 'Skipping as not on Heroku' unless ENV['DYNO'].present?

    Board.all.each do |board|
      open_swimlane_id = board.open_swimlane.id
      closed_swimlane_id = board.closed_swimlane.id

      board_tickets = board.board_tickets
        .joins(:ticket)
        .where(tickets: { remote_state: 'closed' })
        .where(swimlane_id: open_swimlane_id)

      say "Found #{board_tickets.count} closed board tickets in open swimlane on board ##{board.id}"

      board_tickets.includes(:timesheets).each do |board_ticket|
        timesheets = board_ticket.timesheets.sort_by(&:started_at)

        penultimate_timesheet = timesheets[-2]

        # Board ticket was in the right swimlane, but then we moved it
        # for some reason...
        if penultimate_timesheet.swimlane_id = closed_swimlane_id
          say "Fixing board ticket ##{board_ticket.id}"

          # Skip callbacks
          board_ticket.update_columns(swimlane_id: closed_swimlane_id, updated_at: Time.current)

          # Fix timesheets
          timesheets.last.destroy!
          penultimate_timesheet.update_attributes!(ended_at: nil)
        else
          say "Board ticket ##{board_ticket.id} wasn't in closed swimlane beforehand. History: #{timesheets.map(&:attributes).inspect}"
        end
      end

      board_tickets = board.board_tickets
        .joins(:ticket)
        .where(tickets: { remote_state: 'closed' })
        .where.not(swimlane_id: closed_swimlane_id)

      say "Found #{board_tickets.count} closed board tickets in wrong swimlane on board ##{board.id}"

      board_tickets.each do |board_ticket|
        say "Fixing board ticket ##{board_ticket.id}"

        board_ticket.update_attributes!(update_remote: false, swimlane_id: closed_swimlane_id)
      end

      say_with_time "Reordering and rebalancing closed swimlane" do
        board.closed_swimlane.board_tickets
          .joins(:ticket)
          .reorder('COALESCE(tickets.remote_updated_at, tickets.updated_at) DESC')
          .rebalance!
      end
    end
  end
end
