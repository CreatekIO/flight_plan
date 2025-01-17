class PushImporter
  def self.import(payload, repo)
    new(payload, repo).import
  end

  def initialize(payload, repo)
    @payload = payload
    @repo = repo
  end

  def import
    unless BranchNameType.valid_ref?(payload[:ref])
      Rails.logger.info("Not importing ref: #{payload[:ref].inspect}")
      return
    end

    repo.transaction do
      branch = Branch.import(payload, repo)
      return if branch.blank? || branch.destroyed?

      if deployment_branch?
        repo.update_merged_tickets
      elsif ticket_for_issue_number.present?
        branch.update!(ticket: ticket_for_issue_number)
        ticket_for_issue_number.update!(merged: false)
      end
    end
  end

  private

  attr_reader :payload, :repo

  def deployment_branch?
    payload[:ref] == "refs/heads/#{repo.deployment_branch}"
  end

  def issue_number
    @issue_number ||= IssueNumberExtractor.from_branch(payload[:ref])
  end

  def ticket_for_issue_number
    return if issue_number.blank?

    @ticket_for_issue_number ||= repo.tickets.find_by(number: issue_number)
  end
end
