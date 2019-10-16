# frozen_string_literal: true

class CreatePipelines < ActiveRecord::Migration[5.2]
  def change
    create_table :pipelines, id: :uuid do |t|
      t.jsonb(:params, index: true, default: {})
    end

    add_foreign_key(:jobs, :pipelines)
  end
end
