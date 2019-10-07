# frozen_string_literal: true

# https://github.com/colszowka/simplecov/issues/559
require "simplecov"
require "simplecov-console"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter
    # SimpleCov::Formatter::Console
  ]
)

SimpleCov.minimum_coverage(60)

SimpleCov.start do
  add_filter "spec"
  add_filter "lib/babel_fish.rb"
end
