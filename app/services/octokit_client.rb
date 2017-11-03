module OctokitClient
  def client
    @client ||= Octokit::Client.new
  end
end
