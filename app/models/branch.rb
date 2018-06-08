class Branch < ApplicationRecord
  belongs_to :repo
  belongs_to :ticket, optional: true
end
