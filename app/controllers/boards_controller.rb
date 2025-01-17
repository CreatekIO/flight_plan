class BoardsController < AuthenticatedController
  def show
    respond_to do |format|
      format.html do
        @board = Board.find(params[:id])
        self.last_board_id = @board.id
        @boards = Board.all
      end

      format.json do
        if feature?(:normalised_responses)
          loader.merge!(Board.where.not(id: params[:id]))

          render json: loader
        else
          @board = Board.find(params[:id])
        end
      end
    end
  end

  def index
    redirect_to action: :show, id: last_board_id.presence || Board.first
  end

  private

  def loader
    @loader ||= ReduxLoader.from(Board, params[:id]) do
      fetch(Board, :repos, :swimlanes)
      fetch(Swimlane, board_tickets: -> { limit(10) })
      fetch(
        BoardTicket,
        :ticket,
        timesheets: -> { where(ended_at: nil).reorder(started_at: :desc).limit(1) }
      )
      fetch(
        Ticket.except_columns(:body),
        :pull_requests,
        :milestone,
        :display_labels,
        :assignments
      )
      fetch(
        Timesheet.joins(:swimlane).select(
          Timesheet.arel_table[Arel.star],
          Swimlane.arel_table[:display_duration].as('swimlane_displays_duration')
        )
      )
    end
  end
end
