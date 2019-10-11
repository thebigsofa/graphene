class RemoveParamsIndex < ActiveRecord::Migration[6.0]
  def change
    remove_index :pipelines, name: "index_pipelines_on_params"
  end
end
