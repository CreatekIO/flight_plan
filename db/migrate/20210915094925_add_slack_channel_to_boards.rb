class AddSlackChannelToBoards < ActiveRecord::Migration[5.2]
  class Board < ActiveRecord::Base; end

  def up
    add_column :boards, :slack_channel, :string

    default_channel = ENV['SLACK_CHANNEL'].presence || '#cr-dev'

    say_with_time("Setting boards.slack_channel = \"#{default_channel}\"") do
      Board.update_all(slack_channel: default_channel)
    end
  end

  def down
    remove_column :boards, :slack_channel
  end
end
