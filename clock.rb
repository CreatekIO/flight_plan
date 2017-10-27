require 'clockwork'
require './config/boot'
require './config/environment'

module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  every 10.seconds, 'Auto Deployment' do
    AutoDeploy.deploy_all
  end
end
