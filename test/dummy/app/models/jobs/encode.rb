# frozen_string_literal: true

module Jobs
  module Tasks
    class Encode
      include Graphene::Tasks::Task

      def initialize(media_uid:, callbacks:, source:, type:, project_uid:)
        super
      end

      def call
        yield("Encoding #{media_uid} complete.")
      end
    end
  end

  class Encode < Graphene::Jobs::Base
    STACK = Graphene::Stack[
      Jobs::Tasks::Encode
    ]
  end
end
