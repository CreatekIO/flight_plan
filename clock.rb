require 'clockwork'
require './config/boot'
require './config/environment'

module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  every 1.day, 'Auto Deployment', at: ['10:30', '14:30'] do
    Board.where(auto_deploy: true).each do |board|
      if board.deploy_swimlane.tickets.any?
        DeployWorker.perform_async(board.id)
      end
    end
  end
end
