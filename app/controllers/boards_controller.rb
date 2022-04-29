class BoardsController < AuthenticatedController
  before_action :check_for_apps, only: :show

  def show
    respond_to do |format|
      format.html do
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
    redirect_to Board.first
  end

  private

  def check_for_apps
    return unless request.format.html?

    @board = Board.find(params[:id])
    using_app_count = @board.repos.using_app.count
    return if using_app_count.zero? || current_user_github_token.app?

    @use_app_creds = true
    flash.alert = I18n.t('boards.require_gh_app', count: using_app_count)
    store_location_for(:user, board_path(@board))
    render template: 'pages/index' and return
  end

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
