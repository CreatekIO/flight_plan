class Labelling < ApplicationRecord
  belongs_to :label, inverse_of: :labellings
  belongs_to :ticket, inverse_of: :labellings
  has_one :board_ticket, through: :ticket
end
