module OctokitClient
  def client
    @client ||= Octokit::Client.new(netrc: true)
  end
end
