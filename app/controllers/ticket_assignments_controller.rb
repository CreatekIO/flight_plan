class TicketAssignmentsController < AuthenticatedController
  load_and_authorize_resource :board
  load_and_authorize_resource :board_ticket, through: :board, id_param: :ticket_id
  load_and_authorize_resource :ticket, through: :board_ticket, singleton: true

  def update
    changeset = TicketAssigneeChangeset.new(
      ticket: @ticket,
      changes: assignment_params,
      token: current_user_github_token.for(@ticket.repo)
    )

    if changeset.save
      render json: TicketAssignmentBlueprint.render(@ticket.assignments.reload), status: :ok
    else
      render json: { errors: changeset.error_messages }, status: :unprocessable_entity
    end
  end

  private

  def assignment_params
    params.require(:assignment).permit(add: [], remove: [])
  end
end
