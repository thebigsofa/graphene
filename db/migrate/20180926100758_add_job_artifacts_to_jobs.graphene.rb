class AddJobArtifactsToJobs < ActiveRecord::Migration[6.0]
  def change
    add_column :jobs, :artifacts, :jsonb, default: {}, null: false
  end
end
