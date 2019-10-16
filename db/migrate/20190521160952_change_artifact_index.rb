class ChangeArtifactIndex < ActiveRecord::Migration[5.2]
  def change
    remove_index :jobs, :artifacts
    add_index :jobs, "(artifacts->'behavioural_recognition_video_id')", :name => 'index_job_on_field_br'
    add_index :jobs, "(artifacts->'people_detection_job_id')", :name => 'index_job_on_field_pd'
    add_index :jobs, "(artifacts->'zencoder_job_id')", :name => 'index_job_on_field_zencoder'
  end
end
