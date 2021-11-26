class TicketAssigneeChangeset
  include OctokitClient

  octokit_methods :add_assignees, :remove_assignees, prefix_with: %w[ticket.repo.slug ticket.number]

  attr_reader :errors

  def initialize(ticket:, changes:, token:)
    @octokit_token = token
    @ticket = ticket
    @additions = changes[:add].presence || []
    @deletions = changes[:remove].presence || []
    @remote_issue = nil
    @errors = Hash.new { |errors, key| errors[key] = [] }
  end

  def save
    add_assignees
    remove_assignees
    import_latest

    errors.each_value.all?(&:empty?)
  end

  def error_messages
    message = errors.map do |(type, names)|
      formatted_names = names.map { |name| "@#{name}" }.join(', ')
      "#{type} #{formatted_names}"
    end.join(' or ')

    ["Unable to #{message}"]
  end

  private

  attr_reader :ticket, :additions, :deletions, :remote_issue

  def octokit_client_options
    { access_token: @octokit_token }
  end

  def add_assignees
    return unless additions.any?

    @remote_issue = octokit_add_assignees(additions)
  rescue Octokit::Error
    errors[:assign] += additions
  end

  def remove_assignees
    return unless deletions.any?

    @remote_issue = octokit_remove_assignees(deletions)
  rescue Octokit::Error
    errors[:unassign] += deletions
  end

  def import_latest
    return if remote_issue.blank?

    @ticket = Ticket.import(remote_issue.to_hash, ticket.repo)
  end
end
