class Comment < ApplicationRecord
  belongs_to :ticket

  DELETED_ACTION = 'deleted'.freeze

  def self.import(payload, repo)
    remote_comment = payload[:comment]
    remote_issue = payload[:issue]

    comment = Comment.find_or_initialize_by(remote_id: remote_comment[:id])

    return comment.destroy if payload[:action] == DELETED_ACTION

    if comment.new_record?
      comment.ticket = if remote_issue.present?
        Ticket.find_by_remote(remote_issue, full_name: repo.remote_url)
      else
        Ticket.find_by_html_url(remote_comment[:html_url])
      end
    end

    comment.update_attributes(
      remote_body: remote_comment[:body],
      remote_author_id: remote_comment.dig(:user, :id),
      remote_author: remote_comment.dig(:user, :login),
      remote_created_at: remote_comment[:created_at],
      remote_updated_at: remote_comment[:updated_at]
    )

    comment
  end
end
