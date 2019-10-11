class AddVersionToPipelines < ActiveRecord::Migration[6.0]
  def change
    add_column :pipelines, :version, :integer, default: 1, null: false
    add_index :pipelines, :version
  end
end
