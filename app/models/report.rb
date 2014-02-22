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

  def rows
    read_attribute(:rows) || []
  end

  def columns
    read_attribute(:columns) || []
  end

  def values
    read_attribute(:values) || []
  end

  def filters
    read_attribute(:filters) || []
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

  def fetch_page(params={})
    if can_be_generated?
      params[:offset] ||= 0
      values_columns = values.map{|f| field_to_sql_name(f['field']) + ' numeric' }.join(', ')
      select_cols = (rows+columns).each_with_index.map{|f,i| "row_labels[#{i+1}] as #{field_to_sql_name(f['field'])}"}
      select_cols += values.map{|f| field_to_sql_name(f['field']) }

      ActiveRecord::Base.connection.select_all("
        SELECT #{select_cols.join(', ')}
        FROM crosstab('\n\t#{values_sql.compact.join("\nUNION ALL\n\t")}\n\tORDER BY 1
        ', 'select m from generate_series(1,#{values.count}) m')
        AS ct(row_labels varchar[], #{values_columns}) ORDER BY 1 ASC LIMIT 30 OFFSET #{params[:offset]}"
      )
    end
  end

  def field_to_sql_name(field_name)
    field_name.gsub(/:/,'_')
  end

  protected
    def format_field(value)
      v = value
      v = v.map{|k, v| v.to_h } if value.is_a?(ActionController::Parameters)
      v
    end

    def values_sql
      unless values.nil? || rows.nil? || rows.empty?
        group_by = rows.each_with_index.map{|r, i| i+1 }.join(', ')
        values.each_with_index.map do |value, i|
          value_field = value['field']
          s = add_joins_scopes(company.events.active, value)
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
          s = s.select("ARRAY[#{rows_columns.keys.map{|k| k+'::text'}.join(', ')}], #{i+1}, #{value_field}").group('1')
          s.to_sql.gsub(/'/, "''")
        end
      end
    end

    def values_conditions
      "company_id=#{self.company.id}"
    end

    def add_joins_scopes(s, value)
      fields = [[value], rows, columns, filters].compact.inject{|sum,x| sum + x }
      s = s.joins(:results)  if fields.any?{|v| (m = /\Akpi:([0-9]+)\z/.match(v['field'])) && ![Kpi.events.id, Kpi.promo_hours.id].include?(m[1].to_i)}

      s = s.joins(:place) if fields.any?{|v| Place.report_fields.map{|k,v| "place:#{k}" }.include?(v['field'])}

      # Join with users/teams table
      if fields.any?{|v| User.report_fields.map{|k,v| "user:#{k}" }.include?(v['field'])}
        s = s.joins_for_user_teams
      elsif fields.any?{|v| Team.report_fields.map{|k,v| "team:#{k}" }.include?(v['field'])}
        s = s.joins(:teams)
      end
      s = s.joins(:campaign) if fields.any?{|v| Campaign.report_fields.keys.include?(v['field']) }

      fields = [rows, columns].compact.inject{|sum,x| sum + x }
      s
    end

    def rows_columns
      @rows_columns ||= Hash[(rows+columns).map do |f|
        if m = /\A(.*):(.*)\z/.match(f['field'])
          klass = m[1].classify.constantize
          definition = klass.report_fields[m[2].to_sym]
          definition[:column].nil? ? ["#{klass.table_name}.#{m[2]}", m[2]] : ( definition[:column].respond_to?(:call) ? [definition[:column].call, m[2]] :  [definition[:column], m[2]])
        end
      end.compact]
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
