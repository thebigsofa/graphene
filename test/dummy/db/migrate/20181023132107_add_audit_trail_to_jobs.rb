class AddAuditTrailToJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :jobs, :audits, :jsonb, default: [], null: false
  end
end
