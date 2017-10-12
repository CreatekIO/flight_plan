class Ticket < ApplicationRecord
  has_many :timesheets, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :board_tickets, dependent: :destroy

  belongs_to :repo
end
