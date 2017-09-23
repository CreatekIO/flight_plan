class BoardTicket < ApplicationRecord
  belongs_to :board
  belongs_to :ticket
  belongs_to :swimlane
end
