class Board < ApplicationRecord
  has_many :board_repos, dependent: :destroy
  has_many :repos, through: :board_repos
  has_many :swimlanes
end
