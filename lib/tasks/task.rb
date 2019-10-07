# frozen_string_literal: true

module Task
  class Error < StandardError; end

  class SchemaError < Error; end

  class HaltError < Error
    attr_reader :error

    def initialize(error_type, *args)
      @error = error_type.new(*args)
      super(*args)
    end
  end

  extend ActiveSupport::Concern
  include Concerns::Loggable

  # rubocop:disable Metrics/BlockLength
  class_methods do
    def params
      instance_method(:initialize)
        .parameters
        .reject { |(type, _)| type == :keyrest }
        .flat_map(&:second)
    end

    def required_params
      instance_method(:initialize)
        .parameters
        .select { |(type, _)| type == :keyreq }
        .flat_map(&:second)
    end

    def new(hash = {}, **kwargs)
      return super() if instance_method(:initialize).parameters.empty?

      super(**kwargs.merge(hash.symbolize_keys).slice(*params))
    end

    def method_added(name)
      validate_json_schema_properties!
      super
    end

    def json_schema_properties
      instance_method(:json_schema_properties).bind(allocate).call
    end

    def json_schema
      instance_method(:json_schema).bind(allocate).call
    end

    private

    def validate_json_schema_properties!
      return unless instance_methods.include?(:json_schema_properties) &&
                    private_instance_methods.include?(:initialize)

      if (params - json_schema_properties.keys).any?
        raise SchemaError, "missing properties in json schema"
      end

      validate_json_schema!(json_schema)
    end

    def validate_json_schema!(schema)
      metaschema = JSON::Validator.validator_for_name("draft4").metaschema
      raise SchemaError, "invalid json schema" unless JSON::Validator
                                                      .validate(metaschema, schema)
    end
  end
  # rubocop:enable Metrics/BlockLength

  included do
    attr_reader :params

    on_log do |message|
      "#{self.class.name} #{message}"
    end
  end

  def initialize(**kwargs)
    JSON::Validator.validate!(json_schema, kwargs)
    @params = HashWithIndifferentAccess.new(kwargs)
  end

  def json_schema
    {
      type: :object,
      properties: json_schema_properties
    }
  end

  def json_schema_properties
    self.class.params.each_with_object({}) do |param, properties|
      properties[param] = {
        not: {
          type: :null
        }
      }
    end
  end

  def method_missing(meth, *args, **kwargs, &block)
    return params[meth] if params.key?(meth) && args.empty?

    super
  end

  def respond_to_missing?(meth, include_private = false)
    params.key?(meth) || super
  end

  def with(klasses, *args, &block)
    Sheaf::Stack[*[klasses].flatten].fmap do |klass|
      klass.new(params)
    end.call(*args, &block)
  end

  def halt!(*args)
    raise HaltError.new(*args)
  end
end
