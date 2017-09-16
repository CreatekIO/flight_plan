class Repo < ApplicationRecord
  has_many :board_repos, dependent: :destroy
  has_many :boards, through: :board_repos
  has_many :tickets, dependent: :destroy

end
