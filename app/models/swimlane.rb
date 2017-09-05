class Swimlane
  def self.all
    WORKFLOW[:swimlanes].map do |swimlane|
      OpenStruct.new(
        name: swimlane['name'],
        tickets: Ticket.where(state: swimlane['name']),
        transition_to: swimlane['transition_to'],
        display_duration?: swimlane['display_duration']
      )
    end
  end

  def self.duration_displayable
    all.select(&:display_duration?)
  end
end
