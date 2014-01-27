class EventResultsValidator < Apipie::Validator::BaseValidator

  def initialize(param_description, argument)
    super(param_description)
    @type = argument
  end

  def validate(value)
    return false if value.nil?
    return false if !value.is_a?(Array)
    value.all?{|r| r.keys.sort == ['id', 'value'] && (r['id'].is_a?(Integer) || r['id'] =~ /\A[0-9]+\z/)}
  end

  def self.build(param_description, argument, options, block)
    if argument == :event_result
      self.new(param_description, argument)
    end
  end

  def description
    "Must be a list of results [id, value]."
  end
end