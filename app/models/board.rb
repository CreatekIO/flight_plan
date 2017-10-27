class Board < ApplicationRecord
  has_many :board_repos, dependent: :destroy
  has_many :repos, through: :board_repos
  has_many :swimlanes, dependent: :destroy
  has_many :board_tickets, dependent: :destroy
  belongs_to :deploy_swimlane, class_name: 'Swimlane', optional: true

  def open_swimlane
    swimlanes.order(:position).first
  end

  def closed_swimlane
    swimlanes.order(:position).last
  end
end
