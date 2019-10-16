class IndexJobArtifacts < ActiveRecord::Migration[5.2]
  def change
    add_index :jobs, :artifacts
  end
end
