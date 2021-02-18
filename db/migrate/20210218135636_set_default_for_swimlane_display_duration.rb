class SetDefaultForSwimlaneDisplayDuration < ActiveRecord::Migration[5.1]
  class Swimlane < ActiveRecord::Base; end

  def change
    change_column_default :swimlanes, :display_duration, from: nil, to: false
    Swimlane.where(display_duration: nil).update_all(display_duration: false)
  end
end
