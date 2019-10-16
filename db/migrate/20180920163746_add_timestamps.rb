class AddTimestamps < ActiveRecord::Migration[5.2]
  def change
    add_column :pipelines, :created_at, :datetime, null: false
    add_column :pipelines, :updated_at, :datetime, null: false
    add_column :jobs, :created_at, :datetime, null: false
    add_column :jobs, :updated_at, :datetime, null: false
    add_column :edges, :created_at, :datetime, null: false
    add_column :edges, :updated_at, :datetime, null: false

    add_index :pipelines, :created_at
    add_index :pipelines, :updated_at
    add_index :jobs, :created_at
    add_index :jobs, :updated_at
    add_index :edges, :created_at
    add_index :edges, :updated_at
  end
end
