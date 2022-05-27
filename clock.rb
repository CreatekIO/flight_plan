require 'clockwork'
require './config/boot'
require './config/environment'

silence_warnings do
  EARLY_DEPLOY_BOARD_IDS = ENV["EARLY_DEPLOY_BOARD_IDS"].to_s.split(",").map(&:strip)
end

module Clockwork
  error_handler { |error| Bugsnag.notify(error) }

  every 1.day, 'auto_deploy_early', at: '09:00', if: -> (time) { time.on_weekday? } do
    JobMonitor.measure('clock-auto_deploy_early') do
      ReleaseManager.enqueue_deploy_workers do |boards|
        boards.where(id: EARLY_DEPLOY_BOARD_IDS)
      end
    end
  end

  every 1.day, 'auto_deploy', at: '10:15', if: -> (time) { time.on_weekday? } do
    JobMonitor.measure('clock-auto_deploy') do
      ReleaseManager.enqueue_deploy_workers do |boards|
        boards.where.not(id: EARLY_DEPLOY_BOARD_IDS)
      end
    end
  end

  every 1.day, 'auto_merge', at: '10:30', if: -> (time) { time.on_weekday? } do
    JobMonitor.measure('clock-auto_merge') do
      Board.with_auto_deploy_repos.each do |board|
        Rails.logger.info("Enqueuing merge check for Board##{board.id} '#{board.name}'")

        MergeWorker.perform_async(board.id)
      end
    end
  end
end
