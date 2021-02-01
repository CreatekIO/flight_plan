class LabellingsController < AuthenticatedController
  load_and_authorize_resource :board
  load_and_authorize_resource :board_ticket, through: :board, id_param: :ticket_id
  load_and_authorize_resource :ticket, through: :board_ticket, singleton: true

  def update
    changeset = TicketLabelChangeset.new(
      ticket: @ticket,
      changes: labelling_params,
      token: current_user_github_token
    )

    if changeset.save
      render json: json_array_from(@ticket.display_labels.reload), status: :ok
    else
      render json: { errors: changeset.errors }, status: :unprocessable_entity
    end
  end

  private

  def labelling_params
    params.require(:labelling).permit(add: [], remove: [])
  end
end
