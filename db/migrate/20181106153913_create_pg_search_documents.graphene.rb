class CreatePgSearchDocuments < ActiveRecord::Migration[6.0]
  def self.up
    say_with_time("Creating table for pg_search multisearch") do
      create_table :pg_search_documents do |t|
        t.text :content
        t.uuid :searchable_id
        t.string :searchable_type
        t.timestamps null: false
      end

      add_index :pg_search_documents, :searchable_id
      add_index :pg_search_documents, [:searchable_id, :searchable_type]
    end
  end

  def self.down
    say_with_time("Dropping table for pg_search multisearch") do
      remove_index :pg_search_documents, [:searchable_id, :searchable_type]
      remove_index :pg_search_documents, :searchable_id

      drop_table :pg_search_documents
    end
  end
end
