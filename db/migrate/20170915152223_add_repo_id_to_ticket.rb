class AddRepoIdToTicket < ActiveRecord::Migration[5.1]
  def change
    add_reference :tickets, :repo, foreign_key: true
  end
end
