class Comment < ApplicationRecord
  belongs_to :ticket

  def self.import(comment_json, issue_json, repo_json)
    comment = find_by_remote(comment_json)
    if comment.ticket_id.blank?
      comment.ticket = Ticket.find_by_remote(issue_json, repo_json)
    end

    comment.update_attributes(
      remote_body: comment_json[:body],
      remote_author_id: comment_json[:user][:id],
      remote_author: comment_json[:user][:login]
    )
    comment.save!
  end

  def self.find_by_remote(comment_json)
    Comment.find_or_initialize_by(remote_id: comment_json[:id])
  end
end
