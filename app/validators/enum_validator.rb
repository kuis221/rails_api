# Validates the values of an Enumerable with other validators.
# Generates error messages that include the index and value of
# invalid elements.
#
# Example:
#
#   validates :values, enum: { presence: true, inclusion: { in: %w{ big small } } }
#
# See: http://stackoverflow.com/questions/5669496/how-do-i-validate-members-of-an-array-field
class EnumValidator < ActiveModel::EachValidator

  def initialize(options)
    super
    @validators = options.map do |(key, args)|
      create_validator(key, args)
    end
  end

  def validate_each(record, attribute, values)
    helper = Helper.new(@validators, record, attribute)
    Array.wrap(values).each do |value|
      helper.validate(value)
    end
  end

  private

  class Helper

    def initialize(validators, record, attribute)
      @validators = validators
      @record = record
      @attribute = attribute
      @count = -1
    end

    def validate(value)
      @count += 1
      @validators.each do |validator|
        next if value.nil? && validator.options[:allow_nil]
        next if value.blank? && validator.options[:allow_blank]
        validate_with(validator, value)
      end
    end

    def validate_with(validator, value)
      before_errors = error_count
      run_validator(validator, value)
      if error_count > before_errors
        prefix = "element #{@count} (#{value}) "
        (before_errors...error_count).each do |pos|
          error_messages[pos] = prefix + error_messages[pos]
        end
      end
    end

    def run_validator(validator, value)
      validator.validate_each(@record, @attribute, value)
    rescue NotImplementedError
      validator.validate(@record)
    end

    def error_messages
      @record.errors.messages[@attribute]
    end

    def error_count
      error_messages ? error_messages.length : 0
    end
  end

  def create_validator(key, args)
    opts = {attributes: attributes}
    opts.merge!(args) if args.kind_of?(Hash)
    validator_class(key).new(opts).tap do |validator|
      validator.check_validity!
    end
  end

  def validator_class(key)
    validator_class_name = "#{key.to_s.camelize}Validator"
    validator_class_name.constantize
  rescue NameError
    "ActiveModel::Validations::#{validator_class_name}".constantize
  end
end