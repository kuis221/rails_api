class Filter

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :roles

  def initialize(attributes = {})
    if attributes
      attributes.each do |name, value|
        send("#{name}=", value)
      end
    end
  end

  def persisted?
    false
  end
end