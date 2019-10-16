# frozen_string_literal: true

module Graphene
  module Audits
    class StateChange < Base
      attr_reader :from, :to

      def initialize(job, from, to)
        super(job)
        @from = from
        @to = to
      end

      def to_h
        super.merge(from: from, to: to)
      end
    end
  end
end
