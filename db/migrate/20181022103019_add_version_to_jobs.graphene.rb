class AddVersionToJobs < ActiveRecord::Migration[6.0]
  def change
    add_column :jobs, :version, :integer, default: 1, null: false, index: true
    add_index :jobs, :version
    add_index :jobs, %i[type id version]
    add_index :jobs, %i[version pipeline_id]
  end
end
