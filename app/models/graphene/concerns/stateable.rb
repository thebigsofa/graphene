# frozen_string_literal: true

module Concerns
  module Stateable
    extend ActiveSupport::Concern

    class_methods do
      def define_state(state, trigger_name: nil, &block)
        define_method trigger_name || :"#{state}!" do |*args|
          attrs = {
            state: state,
            state_changed_at: Time.now
          }.merge(block ? instance_exec(*args, &block) : {})

          update!(attrs)
        end

        define_method :"#{state}?" do
          self.state == state
        end
      end
    end

    included do
      before_validation :check_state_changed_at_timestamp
    end

    def state
      attributes["state"]&.to_sym
    end

    def check_state_changed_at_timestamp
      self.state_changed_at ||= Time.now
    end
  end
end
