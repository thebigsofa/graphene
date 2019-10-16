# frozen_string_literal: true

class CreateEdges < ActiveRecord::Migration[5.2]
  def change
    create_table :edges, id: :uuid do |t|
      t.uuid(:origin_id, null: false, index: true)
      t.uuid(:destination_id, null: false, index: true)

      t.index(%i[origin_id destination_id], unique: true)
    end

    add_foreign_key(:edges, :jobs, column: :origin_id)
    add_foreign_key(:edges, :jobs, column: :destination_id)
  end
end
