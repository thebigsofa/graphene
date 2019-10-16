class AddGroupToJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :jobs, :group, :string, null: false
  end
end
