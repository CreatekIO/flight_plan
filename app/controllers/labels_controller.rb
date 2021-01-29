class LabelsController < AuthenticatedController
  load_and_authorize_resource :repo

  def index
    render json: labels_for_repo
  end

  private

  def labels_for_repo
    @repo.display_labels.map do |label|
      label.slice(:id, :remote_id, :name, :colour).merge(repo: @repo.id)
    end
  end
end
