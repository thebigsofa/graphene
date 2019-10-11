class AddGroupToJobs < ActiveRecord::Migration[6.0]
  def change
    add_column :jobs, :group, :string, null: false
  end
end
