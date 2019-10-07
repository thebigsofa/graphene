# frozen_string_literal: true

require "spec_helper"

RSpec.describe Concerns::Loggable do
  subject do
    Class.new do
      include Concerns::Loggable

      on_log do |message|
        "baz #{message}"
      end

      def log_prefix_elements
        {
          foo: "bar"
        }
      end
    end.new
  end

  it "logs the correct string" do
    expect(subject.logger).to receive(:info).with("foo bar baz qux").once
    subject.info("qux")
  end
end
