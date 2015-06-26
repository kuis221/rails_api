class PaginatedResultSerializer < ActiveModel::Serializer
  attributes :page, :total

  has_many :results
end
