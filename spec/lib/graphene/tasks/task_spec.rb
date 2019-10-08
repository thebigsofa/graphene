# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Tasks::Task do
  let(:klass) do
    Class.new do
      include Graphene::Tasks::Task

      def initialize(foo:, bar:, baz: 3)
        super
      end
    end
  end

  subject { klass.new(foo: 1, bar: 2) }

  describe ".new" do
    subject { klass.new("foo" => 42, "bar" => 6) }

    it "accepts string keys" do
      expect(subject.foo).to eq(42)
      expect(subject.bar).to eq(6)
      expect(subject.baz).to eq(3)
    end
  end

  describe "#params" do
    it "returns a list of accepted parameters" do
      expect(klass.params).to eq(%i[foo bar baz])
    end

    it "excludes the keyword splat parameter" do
      expect(Class.new { include Graphene::Tasks::Task }.params).to be_empty
    end
  end

  describe "#required_params" do
    it "returns a list of required parameters" do
      expect(klass.required_params).to eq(%i[foo bar])
    end
  end

  describe "method_missing" do
    it "allows direct access to params members" do
      expect(subject.foo).to eq(1)
      expect(subject.bar).to eq(2)
      expect(subject.baz).to eq(3)
    end
  end

  describe "#params" do
    it "returns a HashWithIndifferentAccess containing all params" do
      expect(subject.params).to be_kind_of(HashWithIndifferentAccess)
      expect(subject.params).to eq("foo" => 1, "bar" => 2, "baz" => 3)
    end
  end

  describe "#halt!" do
    let(:klass) do
      Class.new do
        include Graphene::Tasks::Task

        def initialize
          halt!(StandardError, "foobar")
        end
      end
    end

    subject { klass.new }

    it "raises a Task::Halt" do
      expect { subject.call }.to raise_error(Graphene::Tasks::Task::HaltError).with_message("foobar")
    end

    it "passes the correct error to wrap" do
      subject.call
    rescue Graphene::Tasks::Task::HaltError => e
      expect(e.error.class).to eq(StandardError)
      expect(e.error.message).to eq("foobar")
    end
  end

  describe "param validation" do
    let(:klass) do
      Class.new do
        include Graphene::Tasks::Task

        def json_schema_properties
          {
            foo: {
              type: :string
            }
          }
        end

        def initialize(foo:)
          super
        end
      end
    end

    context "valid param" do
      it "raises no error" do
        expect { klass.new(foo: "bar") }.not_to raise_error
      end
    end

    context "invalid param" do
      it "raises no error" do
        expect { klass.new(foo: 12) }.to raise_error(JSON::Schema::ValidationError)
      end
    end
  end

  describe "json schema property validation" do
    context "missing properties, initialize defined first" do
      it "raises a schema error" do
        expect do
          Class.new do
            include Graphene::Tasks::Task

            def initialize(foo:)
              super
            end

            def json_schema_properties
              {}
            end
          end
        end.to raise_error(Graphene::Tasks::Task::SchemaError)
      end
    end

    context "missing properties, initialize defined last" do
      it "raises a schema error" do
        expect do
          Class.new do
            include Graphene::Tasks::Task

            def json_schema_properties
              {}
            end

            def initialize(foo:)
              super
            end
          end
        end.to raise_error(Graphene::Tasks::Task::SchemaError)
      end
    end

    context "invalid json schema" do
      it "raises an error" do
        expect do
          Class.new do
            include Graphene::Tasks::Task

            def json_schema_properties
              {
                foo: {
                  type: :foobar
                }
              }
            end

            def initialize(foo:)
              super
            end
          end
        end.to raise_error(Graphene::Tasks::Task::SchemaError)
      end
    end

    context "valid properties" do
      it "raises no error" do
        expect do
          Class.new do
            include Graphene::Tasks::Task

            def json_schema_properties
              {
                foo: {
                  type: :string
                }
              }
            end

            def initialize(foo:)
              super
            end
          end
        end.not_to raise_error
      end
    end

    context "subsequent invalid method definition" do
      it "raises an error" do
        expect do
          Class.new do
            include Graphene::Tasks::Task

            def initialize(foo:)
              super
            end

            def json_schema_properties
              {
                foo: {
                  type: :string
                }
              }
            end

            def initialize(foo:, bar:)
              super
            end
          end
        end.to raise_error(Graphene::Tasks::Task::SchemaError)
      end
    end
  end
end
