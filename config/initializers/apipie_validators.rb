class EventResultsValidator < Apipie::Validator::BaseValidator
  def initialize(param_description, argument)
    super(param_description)
    @type = argument
  end

  def validate(value)
    return false if value.nil?
    if value.is_a?(Hash) && value.all? { |_k, v| v.keys.sort == %w(id value) && (v['id'].is_a?(Integer) || v['id'] =~ /\A[0-9]+\z/) }
      true
    elsif value.is_a?(Array) && value.all? { |v| v.keys.sort == %w(id value) && (v['id'].is_a?(Integer) || v['id'] =~ /\A[0-9]+\z/) }
      true
    end
    true
  end

  def self.build(param_description, argument, _options, _block)
    if argument == :event_result
      new(param_description, argument)
    end
  end

  def description
    'Must be a list of results [id, value].'
  end
end

class SurveyResultsValidator < Apipie::Validator::BaseValidator
  def initialize(param_description, argument)
    super(param_description)
    @type = argument
  end

  def validate(value)
    return false if value.nil?
    if value.is_a?(Hash) && value.all? { |_k, v| !v['answer'].nil? && v['answer'] != '' }
      true
    elsif value.is_a?(Array) && value.all? { |v| !v['answer'].nil? && v['answer'] != '' }
      true
    end
    true
  end

  def self.build(param_description, argument, _options, _block)
    if argument == :survey_result
      new(param_description, argument)
    end
  end

  def description
    'Must be a list of answers [id, answer].'
  end
end
