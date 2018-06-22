class PushImporter
  MASTER_REF = 'refs/heads/master'.freeze

  def self.import(payload, repo)
    new(payload, repo).import
  end

  def initialize(payload, repo)
    @payload = payload
    @repo = repo
  end

  def import
    repo.transaction do
      if master_branch?
        repo.update_merged_tickets
      elsif ticket_for_issue_number.present?
        branch.update_attributes!(ticket: ticket_for_issue_number)
        ticket_for_issue_number.update_attributes!(merged: false)
      end
    end
  end

  private

  attr_reader :payload, :repo

  def master_branch?
    payload[:ref] == MASTER_REF
  end

  def issue_number
    @issue_number ||= IssueNumberExtractor.from_branch(payload[:ref])
  end

  def ticket_for_issue_number
    return if issue_number.blank?

    @ticket_for_issue_number ||= repo.tickets.find_by(remote_number: issue_number)
  end
end
