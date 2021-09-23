class BoardsController < AuthenticatedController
  def show
    respond_to do |format|
      format.html
      format.json do
        loader.merge!(Board.where.not(id: params[:id]))

        render json: loader
      end
    end
  end

  def index
    redirect_to Board.first
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
    end
  end
end
