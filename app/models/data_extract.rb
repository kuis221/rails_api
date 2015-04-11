# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  filters          :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#

class DataExtract < ActiveRecord::Base
  belongs_to :company
  track_who_does_it

  serialize :columns
  serialize :filters
  serialize :params

  DEFAULT_LIMIT = 30

  attr_accessor :current_user

  class << self
    def define_columns(columns)
      @export_columns_definitions = columns
    end

    def exportable_columns
      columns_definitions.keys
    end

    def columns_definitions
      @export_columns_definitions || {}
    end
  end

  DATA_SOURCES = [
    ['Events', :event], ['Post Event Data (PERs)', :event_data], ['Activities', :activity],
    ['Attendance', :invite], ['Comments', :comment], ['Contacts', :contact], ['Expenses', :event_expense],
    ['Tasks', :task], ['Venues', :venue], ['Users', :user], ['Teams', :team],
    ['Roles', :role], ['Campaign', :campaign], ['Brands', :brand], ['Activity Types', :activity_type],
    ['Areas', :area], ['Brand Portfolios', :brand_portfolio], ['Data Ranges', :date_range], ['Day Parts', :day_part]
  ]

  after_initialize  do
    self.columns ||= self.class.exportable_columns.map(&:to_s) if new_record?
    self.filters ||= HashWithIndifferentAccess.new
  end

  def columns=(cols)
    valid_cols = exportable_columns.map(&:to_s)
    self['columns'] = cols.select { |c| valid_cols.include?(c)  }.uniq
  end

  def rows(page = 1)
    offset = (page - 1) * DEFAULT_LIMIT
    base_scope.order(sort_by).limit(DEFAULT_LIMIT).offset(offset)
              .pluck(*selected_columns_to_sql)
  end

  def source
    self.class.name.split('::').last.underscore
  end

  def model
    @model ||= "::#{self.class.name.split('::')[1]}".constantize
  end

  def add_joins_to_scope(s)
    s
  end

  def add_filter_conditions_to_scope(s)
    s
  end

  def exportable_columns
    self.class.exportable_columns
  end

  def columns_definitions
    self.class.columns_definitions
  end

  def total_pages
    total_results / DEFAULT_LIMIT
  end

  def total_results
    base_scope.count
  end

  def to_hash
    { data_extract: attributes }
  end

  def base_scope
    add_filter_conditions_to_scope add_joins_to_scope(model.accessible_by_user(current_user))
  end

  def selected_columns_to_sql
    columns_definitions.select { |k, v| columns.include?(k.to_s) }.values.map do |column|
      # Check if the column is a proc that we should call
      column_definition column
    end
  end

  def sort_by
    col = default_sort_by
    col = columns.first if col.blank? || !columns.include?(col)
    return if col.blank? || !columns_definitions.key?(col.to_sym)
    "#{columns.index(col) + 1} #{default_sort_dir || 'ASC'}"
  end

  def column_definition(column)
    column.respond_to?(:call) ? instance_eval(&column) : column
  end

  def filters_scope
    model.name.underscore.pluralize
  end
end
