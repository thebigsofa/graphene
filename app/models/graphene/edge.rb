# frozen_string_literal: true

module Graphene
  class Edge < ApplicationRecord
    belongs_to :origin, class_name: "Graphene::Jobs::Base"
    belongs_to :destination, class_name: "Graphene::Jobs::Base"
  end
end
