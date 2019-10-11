class IndexJobArtifacts < ActiveRecord::Migration[6.0]
  def change
    add_index :jobs, :artifacts
  end
end
