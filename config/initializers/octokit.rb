Octokit.configure do |c|
  c.access_token = ENV['GITHUB_API_TOKEN']
  c.auto_paginate = true
end

