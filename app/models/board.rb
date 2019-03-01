class Board < ApplicationRecord
  has_many :board_repos, dependent: :destroy
  has_many :repos, through: :board_repos
  has_many :open_pull_requests, through: :repos
  has_many :swimlanes, dependent: :destroy
  has_many :board_tickets, -> { extending(BoardTicketExtensions) }, dependent: :destroy
  has_many :releases, dependent: :destroy
  belongs_to :deploy_swimlane, class_name: 'Swimlane', optional: true
  validate :check_additional_branches_regex

  def open_swimlane
    swimlanes.order(:position).first
  end

  def closed_swimlane
    swimlanes.order(:position).last
  end

  def preloaded_board_tickets(page: 1)
    board_tickets.by_swimlane(per: 10, page: page).preload(
      :open_timesheet,
      ticket: [
        :repo,
        pull_requests: %i[repo]
      ]
    )
  end

  def to_builder
    Jbuilder.new do |board|
      board.id id
      board.name name
      board.auto_deploy auto_deploy
      board.additional_branches_regex additional_branches_regex
      board.deploy_swimlane deploy_swimlane.to_builder if deploy_swimlane
    end
  end

  private

  def check_additional_branches_regex
    Regexp.new(additional_branches_regex.to_s)
  rescue RegexpError => e
    errors.add(:additional_branches_regex, e.message)
  end
end
