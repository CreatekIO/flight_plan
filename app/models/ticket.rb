class Ticket < ApplicationRecord
  belongs_to :repo

  has_many :comments, dependent: :destroy
  has_many :board_tickets, dependent: :destroy
end
