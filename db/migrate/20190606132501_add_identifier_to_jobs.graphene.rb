class AddIdentifierToJobs < ActiveRecord::Migration[6.0]
  def change
    remove_index :jobs, name: :index_job_on_field_br
    remove_index :jobs, name: :index_job_on_field_pd
    remove_index :jobs, name: :index_job_on_field_zencoder
    add_column :jobs, :identifier, :jsonb, null: false, default: {}
    add_index :jobs, :identifier
  end
end
