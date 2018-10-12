class BoardRepo < ApplicationRecord
  belongs_to :repo, touch: true
  belongs_to :board, touch: true
end
