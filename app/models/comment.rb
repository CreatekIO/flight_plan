class Comment < ApplicationRecord
  belongs_to :ticket

  DELETED_ACTION = 'deleted'.freeze

  def self.import(payload, repo)
    remote_comment = payload[:comment]
    remote_issue = payload[:issue]
    return if remote_issue[:pull_request].present? # actually a comment on a PR, ignore

    comment = Comment.find_or_initialize_by(remote_id: remote_comment[:id])

    return comment.destroy if payload[:action] == DELETED_ACTION

    if comment.new_record?
      comment.ticket = if remote_issue.present?
        repo.tickets.find_or_initialize_by(remote_id: remote_issue[:id])
      else
        Ticket.find_by_html_url(remote_comment[:html_url])
      end
    end

    comment.update(
      body: remote_comment[:body],
      author_remote_id: remote_comment.dig(:user, :id),
      author_username: remote_comment.dig(:user, :login),
      remote_created_at: remote_comment[:created_at],
      remote_updated_at: remote_comment[:updated_at]
    )

    comment
  end
end
