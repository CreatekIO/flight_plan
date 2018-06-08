class BranchHead < ApplicationRecord
  belongs_to :repo
  belongs_to :branch
end
