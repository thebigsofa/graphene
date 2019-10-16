# frozen_string_literal: true

module Graphene
  module Concerns
    module Loggable
      extend ActiveSupport::Concern

      LOG_METHODS = %i[debug error fatal info log warn].freeze

      included do
        attr_writer :logger
      end

      class_methods do
        def on_log(&block)
          LOG_METHODS.each do |method|
            define_method method do |message|
              super(instance_exec(message, method, &block))
            end
          end
        end
      end

      LOG_METHODS.each do |method|
        define_method method do |message|
          logger.__send__(method, "#{format_log_prefix_elements} #{message}".strip)
        end
      end

      def logger
        @logger ||= Logger.new(nil)
      end

      def log_prefix_elements
        {}
      end

      private

      def format_log_prefix_elements
        log_prefix_elements.to_a.flatten.join(" ")
      end
    end
  end
end
