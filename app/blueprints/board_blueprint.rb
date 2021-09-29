class BoardBlueprint < ApplicationBlueprint
  fields :name

  association_ids :repos, :swimlanes
end
