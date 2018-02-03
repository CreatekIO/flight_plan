require 'clockwork'
require './config/boot'
require './config/environment'

module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  every 1.day, 'auto_deploy', at: '10:15', if: ->(t) { (1..5).cover? t.wday } do
    Board.where(auto_deploy: true).each do |board|
      if board.deploy_swimlane.tickets.any?
        DeployWorker.perform_async(board.id)
      end
    end
  end

  every 1.day, 'auto_merge', at: '10:30', if: ->(t) { (1..5).cover? t.wday } do
    Board.where(auto_deploy: true).each do |board|
      if board.deploy_swimlane.tickets.any?
        MergeWorker.perform_async(board.id)
      end
    end
  end
end
