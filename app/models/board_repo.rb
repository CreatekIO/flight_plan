class BoardRepo < ApplicationRecord
  belongs_to :repo
  belongs_to :board
end
