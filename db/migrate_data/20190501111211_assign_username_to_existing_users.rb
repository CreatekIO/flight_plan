class AssignUsernameToExistingUsers < ActiveRecord::Migration["4.2"]
  def up
    client = Octokit::Client.new

    User.where(username: nil).each do |user|
      begin
        github_user = client.user(user.uid.to_i)

        user.update_attributes!(username: github_user.login)
      rescue => error
        p error
        puts error.bactrace
        next
      end
    end
  end
end
