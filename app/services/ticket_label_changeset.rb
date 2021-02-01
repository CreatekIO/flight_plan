class TicketLabelChangeset
  include OctokitClient

  octokit_methods :add_labels_to_an_issue, :remove_label, prefix_with: %w[ticket.repo.slug ticket.number]

  attr_reader :errors

  def initialize(ticket:, changes:, token:)
    self.octokit_token = token
    @ticket = ticket
    @additions = changes[:add].presence || []
    @deletions = changes[:remove].presence || []
    @latest_labels_from_github = nil
    @errors = Hash.new { |errors, key| errors[key] = [] }
  end

  def save
    add_labels
    remove_labels
    import_latest

    errors.each_value.all?(&:empty?)
  end

  private

  attr_reader :ticket, :additions, :deletions, :latest_labels_from_github

  def add_labels
    return unless additions.any?

    @latest_labels_from_github = octokit_add_labels_to_an_issue(additions)
  rescue Octokit::Error
    errors[:add] += additions
  end

  def remove_labels
    return unless deletions.any?

    deletions.each do |label_name|
      begin
        @latest_labels_from_github = octokit_remove_label(label_name)
      rescue Octokit::Error
        errors[:remove] << label_name
      end
    end
  end

  def import_latest
    return if latest_labels_from_github.blank?

    ticket.update_labels_from_remote(
      labels: latest_labels_from_github.map(&:to_hash)
    )
  end
end
