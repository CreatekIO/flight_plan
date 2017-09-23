class SwimlaneTransition < ApplicationRecord
  belongs_to :swimlane
  belongs_to :transition, class_name: Swimlane
end
