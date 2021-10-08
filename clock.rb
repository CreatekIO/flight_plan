require 'clockwork'
require './config/boot'
require './config/environment'

module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  every 1.day, 'auto_deploy', at: '10:15', if: -> (time) { time.on_weekday? } do
    JobMonitor.measure('clock-auto_deploy') do
      Board.with_auto_deploy_repos.each do |board|
        if board.deploy_swimlane.tickets.none?
          Rails.logger.info("Nothing to deploy for Board##{id} '#{board.name}'")
          next
        end

        Rails.logger.info("Enqueuing release for Board##{id} '#{board.name}'")
        DeployWorker.perform_async(board.id)
      end
    end
  end

  every 1.day, 'auto_merge', at: '10:30', if: -> (time) { time.on_weekday? } do
    JobMonitor.measure('clock-auto_merge') do
      Board.with_auto_deploy_repos.each do |board|
        Rails.logger.info("Enqueuing merge check for Board##{id} '#{board.name}'")

        MergeWorker.perform_async(board.id)
      end
    end
  end
end
