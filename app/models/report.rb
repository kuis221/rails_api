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

  attr_accessor :columns_values


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
    load_fields(:rows)
  end

  def columns
    load_fields(:columns)
  end

  def values
    load_fields(:values)
  end

  def filters
    load_fields(:filters)
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
    fetch_results_for((rows+columns).compact, params)
  end

  def fetch_results_for(fields, params={})
    rows_columns = Hash[fields.map do |f|
      table_column_for_field(f)
    end.compact]

    rows_columns = {'1' => 'col_name'} if rows_columns.empty?

    params.reverse_merge! offset: 0, apply_values_formatting: true

    if can_be_generated?
      select_cols = (fields.reject{|f| f['field'] == 'values'}).each_with_index.map{|f,i| "row_labels[#{i+1}] as #{field_to_sql_name(f['field'])}"}
      value_fields = {}
      values_columns = values.map do |f|
        if (m = /\Akpi:([0-9]+)\z/.match(f['field'])) && (kpi = load_kpi(m[1])) && (kpi.is_segmented? || kpi.kpi_type == 'count')
          kpi.kpis_segments.map do |s|
            name = "kpi_#{kpi.id}_#{s.id}"
            select_cols.push name
            value_fields[name] = "#{f['label']}: #{s.text}"
            "#{name} numeric"
          end
        else
          name = field_to_sql_name(f['field'])
          select_cols.push name
          value_fields[name] = "#{f['label']}"
          "#{name} numeric"
        end
      end.flatten

      results = ActiveRecord::Base.connection.select_all("
        SELECT #{select_cols.join(', ')}
        FROM crosstab('\n\t#{values_sql(rows_columns).compact.join("\nUNION ALL\n\t").gsub(/'/, "''")}\n\tORDER BY 1',
          'select m from generate_series(1,#{values_columns.count}) m')
        AS ct(row_labels varchar[], #{values_columns.join(', ')}) ORDER BY 1 ASC LIMIT 30 OFFSET #{params[:offset]}
      ")

      empty_values = Hash[report_columns.map{|k| [k, nil]}]

      key_fields = rows.compact.map{|f| field_to_sql_name(f['field']) } - ['values']
      column_fields = columns.map{|f| field_to_sql_name(f['field']) }
      rows = []
      row = values = previous_key =nil
      results.each do |result|
        key = key_fields.map{|f| result[f] }
        if key != previous_key
          unless row.nil?
            row['values'] = values.values
            row['values'] = apply_values_formatting(row['values']) if params[:apply_values_formatting]
            rows.push row
          end
          row = result.select{|k,v| key_fields.include?(k) }
          values = empty_values.dup
        end
        value_fields.each do |name, label|
          k = column_fields.map{|c| if c == 'values' then label else result[c] end }.join('||')
          values[k] = result[name].to_f if values.has_key?(k)
        end
        previous_key = key
      end
      unless row.nil?
        row['values'] = values.values
        row['values'] = apply_values_formatting(row['values']) if params[:apply_values_formatting]
        rows.push row
      end
      rows
    end
  end

  def apply_values_formatting(result_values)
    step = values.count
    values.each_with_index do |field, index|
      (index..(result_values.count-1)).step(step).each do |i|
        result_values[i] = field.apply_display_method(result_values[i], columns_totals[i])
      end
    end
    result_values
  end

  def field_to_sql_name(field_name)
    field_name.gsub(/:/,'_')
  end

  def report_columns
     @report_columns ||= scoped_columns(add_joins_scopes(base_events_scope, values), columns)
  end

  def report_columns_hash
    @report_columns_hash ||= Hash.new.tap do |hash|
      report_columns.each do |parts|
        h = hash
        parts.split('||').each_with_index do |part, index|
          h[part] ||= {}
          h=h[part]
        end
      end
    end
  end

  def columns_totals
    results = fetch_results_for(columns, apply_values_formatting: false)
    if results.any?
      results.first['values']
    else
      []
    end
  end

  protected
    def format_field(value)
      v = value
      v = v.map{|k, v| v.to_h } if value.is_a?(ActionController::Parameters)
      v
    end

    def values_sql(rc)
      unless values.nil? || rows.nil? || rows.empty?
        i = 0
        rows_field = "ARRAY[#{rc.keys.map{|k| k+'::text'}.join(', ')}]"
        values.map do |value|
          value_field = value['field']
          s = add_joins_scopes(base_events_scope, value).group('1')
          if m = /\Akpi:([0-9]+)\z/.match(value['field'])
            kpi = load_kpi(m[1])
            if kpi.is_segmented?
              value_field = value_aggregate_sql(value['aggregate'], 'event_results.scalar_value')
              kpi.kpis_segments.map{|segment| s.where('event_results.kpi_id=? and event_results.kpis_segment_id=?', kpi.id, segment.id).select("#{rows_field}, #{i+=1}, #{value_field}").to_sql }
            elsif kpi.kpi_type == 'count'
              if value['aggregate'] == 'count'
                value_field = value_aggregate_sql(value['aggregate'], 'event_results.scalar_value')
              else
                value_field = '0'
              end
              kpi.kpis_segments.map{|segment| s.where('event_results.kpi_id=? and event_results.value=?', kpi.id, segment.id.to_s).select("#{rows_field}, #{i+=1}, #{value_field}").to_sql }
            else
              if Kpi.promo_hours.id == m[1].to_i
                value_field = value_aggregate_sql(value['aggregate'], 'events.promo_hours')
              elsif Kpi.events.id == m[1].to_i
                value_field = value_aggregate_sql(value['aggregate'], '1')
              else
                value_field = value_aggregate_sql(value['aggregate'], 'event_results.scalar_value')
                s = s.where('event_results.kpi_id=?', m[1].to_i)
              end
              s.select("#{rows_field}, #{i+=1}, #{value_field}").to_sql
            end
          elsif m = /\A(.*):([a-z_]+)\z/.match(value['field'])
            if value['aggregate'] == 'count'
              value_field = value_aggregate_sql(value['aggregate'], get_column_name_from(value)[0])
            else
              value_field = '0'
            end
            s.select("#{rows_field}, #{i+=1}, #{value_field}").to_sql
          else
            nil
          end
        end.flatten
      end
    end

    def values_conditions
      "company_id=#{self.company.id}"
    end

    def add_joins_scopes(s, field_list)
      field_list = [field_list] unless field_list.is_a?(Array)
      fields = [field_list, rows, columns, filters].compact.inject{|sum,x| sum + x }
      if fields.any?{|v| (m = /\Akpi:([0-9]+)\z/.match(v['field'])) && ![Kpi.events.id, Kpi.promo_hours.id].include?(m[1].to_i)}
        # Include the event_results table in the join making sure that only
        s = s.joins(:results, {campaign: :form_fields}).where('campaign_form_fields.kpi_id=event_results.kpi_id')
      end

      s = s.joins(:place) if fields.any?{|v| Place.report_fields.map{|k,v| "place:#{k}" }.include?(v['field'])}
      s = s.joins(:campaign) if fields.any?{|v| Campaign.report_fields.map{|k,v| "campaign:#{k}" }.include?(v['field'])}

      # Join with users/teams table
      include_roles = fields.any?{|v| Role.report_fields.map{|k,v| "role:#{k}" }.include?(v['field'])}
      if fields.any?{|v| User.report_fields.map{|k,v| "user:#{k}" }.include?(v['field'])} || include_roles
        s = s.joins_for_user_teams
        s = s.joins('INNER JOIN roles ON roles.id=company_users.role_id') if include_roles
      elsif fields.any?{|v| Team.report_fields.map{|k,v| "team:#{k}" }.include?(v['field'])}
        s = s.joins(:teams)
      end
      s = s.joins(:campaign) if fields.any?{|v| Campaign.report_fields.keys.include?(v['field']) }

      [rows,columns].compact.inject{|sum,x| sum + x }.compact.each do |f|
        if m = /\Akpi:([0-9]+)\z/.match(f['field'])
          s = s.joins("INNER JOIN event_results er_kpi_#{m[1]} ON er_kpi_#{m[1]}.event_id = events.id AND er_kpi_#{m[1]}.kpi_id=#{m[1]}")
        end
      end

      fields = [rows, columns].compact.inject{|sum,x| sum + x }
      s
    end

    def table_column_for_field(f)
      if m = /\Akpi:([0-9]+)\z/.match(f['field'])
        ["er_kpi_#{m[1]}.value", "kpi_#{m[1]}"]
      elsif m = /\A(.*):([a-z_]+)\z/.match(f['field'])
        get_column_name_from f
      end
    end

    def get_column_name_from(f)
      if m = /\A(.*):([a-z_]+)\z/.match(f['field'])
        klass = m[1].classify.constantize
        definition = klass.report_fields[m[2].to_sym]
        definition[:column].nil? ? ["#{klass.table_name}.#{m[2]}", m[2]] : ( definition[:column].respond_to?(:call) ? [definition[:column].call, m[2]] :  [definition[:column], m[2]])
      end
    end

    def value_aggregate_sql(aggregate, field)
      case aggregate.try(:downcase)
      when 'sum', 'count', 'min', 'max', 'avg'
        "#{aggregate.upcase}(#{field})"
      else
        "SUM(#{field})"
      end
    end

    def scoped_columns(s, c, prefix='', index=0)
      begin
        if c.any? && column = c.first
          if column['field'] == 'values'
            values.map do |v|
              if (m = /\Akpi:([0-9]+)\z/.match(v['field'])) && (kpi = load_kpi(m[1])) && (kpi.is_segmented? || kpi.kpi_type == 'count')
                kpi.kpis_segments.map{|segment| scoped_columns(s, c.slice(1, c.count), "#{prefix}#{v['label']}: #{segment.text}||") }
              else
                scoped_columns(s, c.slice(1, c.count), "#{prefix}#{v['label']}||")
              end
            end
          else
            values = ActiveRecord::Base.connection.select_values(s.select("DISTINCT(#{table_column_for_field(column)[0]}) as value").order('1'))
            values.map do |v|
              scoped_columns(s.where(table_column_for_field(column)[0] => v), c.slice(1, c.count), "#{prefix}#{v}||", index+1)
            end
          end
        else
          [prefix.gsub(/\|\|\z/,'')]
        end
      end.flatten
    end

    def base_events_scope
      company.events.active
    end

    def load_kpi(id)
      @_kpis ||= {}
      @_kpis[id.to_i] ||= Kpi.find(id)
    end

    def load_fields(name)
      fields = read_attribute(name)
      if fields.nil?
        []
      else
        fields.map{|r| Report::Field.new(self, name, r) }
      end
    end
end


class Report::Field
  attr_accessor :type, :data, :report

  def initialize(report, type, data)
    @report = report
    @type = type
    @data = data
  end

  def [](key)
    @data[key]
  end

  def apply_display_method(value, column_total)
    case display
    when 'perc_of_column'
      value*100/column_total
    else
      value
    end
  end

  def display
    @data['display']
  end

  def field
    @data['display']
  end

  def label
    @data['label']
  end

  def aggregate
    @data['label']
  end

  def to_hash
    @data
  end
end