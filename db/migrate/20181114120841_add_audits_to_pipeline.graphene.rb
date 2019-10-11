class AddAuditsToPipeline < ActiveRecord::Migration[6.0]
  def change
    add_column :pipelines, :audits, :jsonb, default: [], null: false
  end
end
