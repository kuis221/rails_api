class PaginatedResult
  include ActiveModel::Serialization
  attr_accessor :page, :total, :results

  def initialize(attrs = {})
    attrs.each { |k, v| send("#{k}=", v) }
  end

  def attributes
    { page: nil, total: nil, results: nil }
  end
end
