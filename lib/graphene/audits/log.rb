# frozen_string_literal: true

module Audits
  class Log < Base
    attr_reader :level, :message

    def initialize(job, level, message)
      super(job)
      @level = level
      @message = message
    end

    def to_h
      super.merge(level: level, message: message)
    end
  end
end
