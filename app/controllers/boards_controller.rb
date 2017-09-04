class BoardsController < ApplicationController
  def show
    @swimlanes = WORKFLOW[:swimlanes].map do |swimlane|
      OpenStruct.new(
        name: swimlane['name'],
        tickets: Ticket.where(state: swimlane['name']),
        transition_to: swimlane['transition_to']
      )
    end
  end
end
