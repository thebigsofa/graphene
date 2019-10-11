class AddAuditTrailToJobs < ActiveRecord::Migration[6.0]
  def change
    add_column :jobs, :audits, :jsonb, default: [], null: false
  end
end
