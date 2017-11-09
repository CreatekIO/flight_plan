class AddAdditionalBranchesRegexToBoard < ActiveRecord::Migration[5.1]
  def change
    add_column :boards, :additional_branches_regex, :string
  end
end
