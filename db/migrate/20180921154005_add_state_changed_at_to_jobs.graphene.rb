class AddStateChangedAtToJobs < ActiveRecord::Migration[6.0]
  def change
    add_column :jobs, :state_changed_at, :datetime, default: -> { 'CURRENT_TIMESTAMP' }, null: false, index: true
  end
end
