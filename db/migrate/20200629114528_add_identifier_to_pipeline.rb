class AddIdentifierToPipeline < ActiveRecord::Migration[6.0]
  def change
    add_column :pipelines, :identifier, :string, default: ""
    add_column :pipelines, :identifier_type, :string, default: ""
    add_index :pipelines, :identifier
  end
end
