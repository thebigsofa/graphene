class AddJobArtifactsToJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :jobs, :artifacts, :jsonb, default: {}, null: false
  end
end
