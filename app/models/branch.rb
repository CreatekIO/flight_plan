class Branch < ApplicationRecord
  belongs_to :repo
  belongs_to :ticket, optional: true

  attribute :name, BranchNameType.new
  attribute :base_ref, BranchNameType.new
end
