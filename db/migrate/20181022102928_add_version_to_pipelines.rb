class AddVersionToPipelines < ActiveRecord::Migration[5.2]
  def change
    add_column :pipelines, :version, :integer, default: 1, null: false
    add_index :pipelines, :version
  end
end
