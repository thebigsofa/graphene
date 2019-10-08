# frozen_string_literal: true

class CreateJobs < ActiveRecord::Migration[5.2]
  def change
    create_table :jobs, id: :uuid do |t|
      t.string(:type, null: false, index: true, default: "Graphene::Jobs::Base")

      t.string(:state, null: false, default: "pending", index: true)
      t.string(:error)
      t.string(:error_message)
      t.uuid(:pipeline_id, null: false, index: true)

      t.index(%i[type id], unique: true)
    end
  end
end
