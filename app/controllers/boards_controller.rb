class BoardsController < AuthenticatedController
  helper_method :use_v2_ui?

  layout :determine_layout

  def show
    @hide_container = true
    # TODO: this needs to come from the logged in user
    @boards = Board.all
    @board = Board.find(params[:id])

    respond_to :html, :json
  end

  def index
    redirect_to Board.first
  end

  private

  def determine_layout
    use_v2_ui? ? 'application_v2' : 'application'
  end

  def use_v2_ui?
    params[:v2].present? || Flipper.enabled?(:v2_ui, current_user)
  end
end
