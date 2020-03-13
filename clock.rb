require 'clockwork'
require './config/boot'
require './config/environment'

module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  every 1.day, 'auto_deploy', at: '10:15', if: -> (time) { time.on_weekday? } do
    Board.with_auto_deploy_repos.each do |board|
      next if board.deploy_swimlane.tickets.none?

      DeployWorker.perform_async(board.id)
    end
  end

  every 1.day, 'auto_merge', at: '10:30', if: -> (time) { time.on_weekday? } do
    Board.with_auto_deploy_repos.each do |board|
      next if board.deploy_swimlane.tickets.none?

      MergeWorker.perform_async(board.id)
    end
  end
end
