class Labelling < ApplicationRecord
  belongs_to :label, inverse_of: :labellings
  belongs_to :ticket, inverse_of: :labellings
end
