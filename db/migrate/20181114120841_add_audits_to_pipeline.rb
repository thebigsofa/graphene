class AddAuditsToPipeline < ActiveRecord::Migration[5.2]
  def change
    add_column :pipelines, :audits, :jsonb, default: [], null: false
  end
end
