Octokit.configure do |c|
  c.access_token = ENV['FLIGHT_PLAN_TOKEN']
  c.auto_paginate = true
end

