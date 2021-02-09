class LabelsController < AuthenticatedController
  load_and_authorize_resource :repo

  def index
    render json: json_array_from(@repo.display_labels)
  end
end
