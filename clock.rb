require 'clockwork'
require './config/boot'
require './config/environment'

module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  every 1.day, 'auto_deploy', at: '10:15', if: ->(time) { time.on_weekday? } do
    Board.where(auto_deploy: true).each do |board|
      DeployWorker.perform_async(board.id) if board.deploy_swimlane.tickets.any?
    end
  end

  every 1.day, 'auto_merge', at: '10:30', if: ->(time) { time.on_weekday? } do
    Board.where(auto_deploy: true).each do |board|
      MergeWorker.perform_async(board.id) if board.deploy_swimlane.tickets.any?
    end
  end
end
