class LabelsController < AuthenticatedController
  load_and_authorize_resource :repo

  def index
    render json: LabelBlueprint.render(@repo.display_labels)
  end
end
