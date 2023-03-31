class RepoBlueprint < ApplicationBlueprint
  fields :name, :slug
  field :uses_app?, name: :uses_app
end
