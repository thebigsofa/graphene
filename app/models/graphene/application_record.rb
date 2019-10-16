# frozen_string_literal: true

module Graphene
  class ApplicationRecord < ActiveRecord::Base
    include GlobalID::Identification

    self.abstract_class = true
  end
end
