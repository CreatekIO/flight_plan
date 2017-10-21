class Board < ApplicationRecord
  has_many :board_repos, dependent: :destroy
  has_many :repos, through: :board_repos
  has_many :swimlanes, dependent: :destroy
  has_many :board_tickets, dependent: :destroy
  belongs_to :deploy_swimlane, class_name: 'Swimlane'  

  DEPLOY_DELAY = 10.minutes

  def open_swimlane
    swimlanes.order(:position).first
  end

  def closed_swimlane
    swimlanes.order(:position).last
  end

  def schedule_next_deployment
    if pending_auto_deployment?
      self.next_deployment = calculate_next_deployment
    end
  end

  private

  def pending_auto_deployment?
    auto_deploy? && deploy_swimlane.board_tickets.any? 
  end

  def calculate_next_deployment
    last_ticket = deploy_swimlane.board_tickets.order(:updated_at).last

    deploy_at = last_ticket.updated_at + DEPLOY_DELAY

    if deploy_at < '9am'
      deploy_at = deploy_at.change(hour: 9, minute: 0, second: 0)
    elsif deploy_at > '5pm'
      deploy_at = deploy_at.change(hour: 9, minute: 0, second: 0)
      deploy_at += 1.day
    end

    loop do
      break if (1..5).include? deploy_at.wday
      deploy_at += 1.day
    end

    deploy_at
  end
end
