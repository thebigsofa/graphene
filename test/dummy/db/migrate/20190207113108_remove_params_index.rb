class RemoveParamsIndex < ActiveRecord::Migration[5.2]
  def change
    remove_index :pipelines, name: "index_pipelines_on_params"
  end
end
