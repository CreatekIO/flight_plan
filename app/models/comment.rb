class Comment < ApplicationRecord
  belongs_to :ticket

  def self.import(remote_comment, remote_issue, remote_repo)
    comment = find_by_remote(remote_comment)
    if comment.ticket_id.blank?
      comment.ticket = Ticket.find_by_remote(remote_issue, remote_repo)
    end

    comment.update_attributes(
      remote_body: remote_comment[:body],
      remote_author_id: remote_comment[:user][:id],
      remote_author: remote_comment[:user][:login]
    )
    comment
  end

  def self.find_by_remote(remote_comment)
    Comment.find_or_initialize_by(remote_id: remote_comment[:id])
  end
end
