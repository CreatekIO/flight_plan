class BoardRepo < ApplicationRecord
  belongs_to :repo
  belongs_to :board

  delegate :name, to: :repo
end
