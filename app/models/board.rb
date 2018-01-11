class Board < ApplicationRecord
  has_many :board_repos, dependent: :destroy
  has_many :repos, through: :board_repos
  has_many :swimlanes, dependent: :destroy
  has_many :board_tickets, dependent: :destroy
  belongs_to :deploy_swimlane, class_name: 'Swimlane', optional: true
  validate :check_additional_branches_regex

  def open_swimlane
    swimlanes.order(:position).first
  end

  def closed_swimlane
    swimlanes.order(:position).last
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
