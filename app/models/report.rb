# == Schema Information
#
# Table name: reports
#
#  id            :integer          not null, primary key
#  company_id    :integer
#  name          :string(255)
#  description   :text
#  active        :boolean          default(TRUE)
#  created_by_id :integer
#  updated_by_id :integer
#  rows          :text
#  columns       :text
#  values        :text
#  filters       :text
#

class Report < ActiveRecord::Base
  # Created_by_id and updated_by_id fields
  track_who_does_it

  scoped_to_company

  validates :name, presence: true, uniqueness: {scope: :company_id}
  validates :company_id, presence: true, numericality: true

  scope :active, -> { where(active: true) }

  serialize :rows
  serialize :columns
  serialize :values
  serialize :filters


  # Override setter methods to format/clean the values
  def rows=(value)
    write_attribute :rows, format_field(value)
  end

  def columns=(value)
    write_attribute :columns, format_field(value)
  end

  def values=(value)
    write_attribute :values, format_field(value)
  end

  def filters=(value)
    write_attribute :filters, format_field(value)
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def can_be_generated?
    rows.try(:any?) && (values.try(:any?) || columns.try(:any?))
  end

  def fetch_page(page=1)
    values_columns = values.map{|f| field_to_sql_name(f['field']) + ' numeric' }.join(', ')
    ActiveRecord::Base.connection.select_all("
      SELECT *
      FROM crosstab('\n\t#{values_sql.compact.join("\nUNION ALL\n\t")}\n\tORDER BY 1
      ', 'select m from generate_series(1,#{values.count}) m')
      AS ct(row_labels varchar, #{values_columns}) ORDER BY 1 ASC LIMIT 30"
    )
  end

  def field_to_sql_name(field_name)
    field_name.gsub(/:/,'_')
  end

  protected
    def format_field(value)
      value.map{|k, v| v.to_h } if value.is_a?(ActionController::Parameters)
    end

    def values_sql
      unless values.nil? || rows.nil? || rows.empty?
        group_by = rows.each_with_index.map{|r, i| i+1 }.join(', ')
        values.each_with_index.map do |value, i|
          value_field = value['field']
          s = add_joins_scopes(company.events, value)
          if m = /\Akpi:([0-9]+)\z/.match(value['field'])
            if Kpi.promo_hours.id == m[1].to_i
              value_field = value_aggregate_sql(value['aggregate'], 'promo_hours')
            elsif Kpi.events.id == m[1].to_i
              value_field = value_aggregate_sql(value['aggregate'], '1')
            else
              value_field = value_aggregate_sql(value['aggregate'], 'scalar_value')
              s = s.where('kpi_id=?', m[1].to_i)
            end
          end
          s = s.select("#{rows_columns}, #{i+1}, #{value_field}").group('1')
          s.to_sql
        end
      end
    end

    def values_conditions
      "company_id=#{self.company.id}"
    end

    def add_joins_scopes(s, value)
      fields = [[value], rows, columns, filters].compact.inject{|sum,x| sum + x }
      s = s.joins(:results)  if fields.any?{|v| (m = /\Akpi:([0-9]+)\z/.match(v['field'])) && ![Kpi.events.id, Kpi.promo_hours.id].include?(m[1].to_i)}
      if fields.any?{|v| Place.report_fields.map{|k,v| "place:#{k}" }.include?(v['field'])}
        s = s.joins(:place)
      end
      s = s.joins(:campaign) if fields.any?{|v| Campaign.report_fields.keys.include?(v['field']) }

      fields = [rows, columns].compact.inject{|sum,x| sum + x }
      s
    end

    def rows_columns
      @rows_columns ||= rows.map do |f|
        if m = /\A(.*):(.*)\z/.match(f['field'])
          "#{m[1].pluralize}.#{m[2]} as #{m[1]}_#{m[2]}"
        end
      end.compact.join(', ')
    end

    def value_aggregate_sql(aggregate, field)
      case aggregate.try(:downcase)
      when 'sum', 'count', 'min', 'max', 'avg'
        "#{aggregate.upcase}(#{field})"
      else
        "SUM(#{field})"
      end
    end

end
