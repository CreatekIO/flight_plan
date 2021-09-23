class LabelBlueprint < ApplicationBlueprint
  fields :name, :colour
  field :repo_id, name: :repo
end
