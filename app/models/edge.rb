# frozen_string_literal: true

class Edge < ApplicationRecord
  belongs_to :origin, class_name: "Jobs::Base"
  belongs_to :destination, class_name: "Jobs::Base"
end
