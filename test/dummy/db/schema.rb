# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_10_11_111729) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "edges", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "origin_id", null: false
    t.uuid "destination_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_edges_on_created_at"
    t.index ["destination_id"], name: "index_edges_on_destination_id"
    t.index ["origin_id", "destination_id"], name: "index_edges_on_origin_id_and_destination_id", unique: true
    t.index ["origin_id"], name: "index_edges_on_origin_id"
    t.index ["updated_at"], name: "index_edges_on_updated_at"
  end

  create_table "jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "type", default: "Graphene::Jobs::Base", null: false
    t.string "state", default: "pending", null: false
    t.string "error"
    t.string "error_message"
    t.uuid "pipeline_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "state_changed_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "artifacts", default: {}, null: false
    t.integer "version", default: 1, null: false
    t.jsonb "audits", default: [], null: false
    t.string "group", null: false
    t.jsonb "identifier", default: {}, null: false
    t.index ["created_at"], name: "index_jobs_on_created_at"
    t.index ["identifier"], name: "index_jobs_on_identifier"
    t.index ["pipeline_id"], name: "index_jobs_on_pipeline_id"
    t.index ["state"], name: "index_jobs_on_state"
    t.index ["type", "id", "version"], name: "index_jobs_on_type_and_id_and_version"
    t.index ["type", "id"], name: "index_jobs_on_type_and_id", unique: true
    t.index ["type"], name: "index_jobs_on_type"
    t.index ["updated_at"], name: "index_jobs_on_updated_at"
    t.index ["version", "pipeline_id"], name: "index_jobs_on_version_and_pipeline_id"
    t.index ["version"], name: "index_jobs_on_version"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.uuid "searchable_id"
    t.string "searchable_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["searchable_id", "searchable_type"], name: "index_pg_search_documents_on_searchable_id_and_searchable_type"
    t.index ["searchable_id"], name: "index_pg_search_documents_on_searchable_id"
  end

  create_table "pipelines", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "params", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "version", default: 1, null: false
    t.jsonb "audits", default: [], null: false
    t.index ["created_at"], name: "index_pipelines_on_created_at"
    t.index ["updated_at"], name: "index_pipelines_on_updated_at"
    t.index ["version"], name: "index_pipelines_on_version"
  end

  add_foreign_key "edges", "jobs", column: "destination_id"
  add_foreign_key "edges", "jobs", column: "origin_id"
  add_foreign_key "jobs", "pipelines"
end
