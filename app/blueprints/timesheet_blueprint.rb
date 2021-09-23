class TimesheetBlueprint < ApplicationBlueprint
  field(
    :duration,
    # Only calculate duration if we need to
    if: -> (_, timesheet, _) { timesheet[:swimlane_displays_duration] }
  ) do |timesheet|
    Timesheet.format_duration(timesheet.duration)
  end
end
