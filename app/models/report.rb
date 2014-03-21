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
#  sharing       :string(255)      default("owner")
#

class Report < ActiveRecord::Base
  # Created_by_id and updated_by_id fields
  track_who_does_it

  scoped_to_company

  validates :name, presence: true
  validates :company_id, presence: true, numericality: true
  validates :sharing, inclusion: { in: %w(owner everyone custom) }

  attr_accessor :filter_params, :page

  scope :active, -> { where(active: true) }

  scope :accessible_by_user, ->(user) {
    joins('LEFT JOIN report_sharings ON report_sharings.report_id=reports.id').
    where(company_id: user.company_id).
    where('reports.sharing=? OR
       reports.created_by_id=? OR
       (reports.sharing=? AND (
            (report_sharings.shared_with_type=? AND report_sharings.shared_with_id=?) OR
            (report_sharings.shared_with_type=? AND report_sharings.shared_with_id in (?)) OR
            (report_sharings.shared_with_type=? AND report_sharings.shared_with_id=?))
        )',
       'everyone',
       user.user_id,
       'custom',
          'CompanyUser', user.id,
          'Team', user.team_ids+[0],
          'Role', user.role_id
       ).
    group('reports.id')
  }

  serialize :rows
  serialize :columns
  serialize :values
  serialize :filters

  has_many :sharings, class_name: 'ReportSharing', inverse_of: :report, autosave: true

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
    rows.try(:any?) && values.try(:any?) && columns.try(:any?)
  end

  def fetch_page(params={})
    fetch_results_for((rows+columns).compact, params)
  end

  def sharing_selections
    self.sharings.map{|s| "#{s.shared_with_type.underscore}:#{s.shared_with_id}" }
  end

  def sharing_selections=(selections)
    self.sharings.each{|s| s.mark_for_destruction unless selections.include?("#{s.shared_with_type.underscore}:#{s.shared_with_id}") }
    selections.reject(&:empty?).map do |selection|
      type, id = selection.split(':')
      case type
      when 'company_user', 'role', 'team'
        self.sharings.find_or_initialize_by_shared_with_id_and_shared_with_type(shared_with_type: type.classify, shared_with_id: id)
      end
    end
  end

  def to_csv(&block)
    CSV.generate do |csv|
      csv << rows.map(&:label) +  report_columns.map{|c| c.gsub('||', '/')}
      row_fields = rows.map(&:to_sql_name)
      results = fetch_page
      total = results.count
      fetch_page.each_with_index do |row, i|
        csv << row_fields.map{|n| row[n] } + row['values']
        yield total, i if block_given? && i%50 == 0
      end
    end
  end

  def offset
    ((page || 1)-1) * 50
  end

  def fetch_results_for(fields, params={})
    rows_columns = Hash[fields.map do |f|
      f.table_column
    end.compact]

    rows_columns = {'1' => 'col_name'} if rows_columns.empty?

    params.reverse_merge! apply_values_formatting: true

    if can_be_generated?
      select_cols = (fields.reject{|f| f['field'] == 'values'}).each_with_index.map{|f,i| "row_labels[#{i+1}] as #{f.to_sql_name}"}
      value_fields = {}
      values_columns = values.map do |f|
        if f.kpi.present? && (f.kpi.is_segmented? || f.kpi.kpi_type == 'count')
          f.kpi.kpis_segments.map do |s|
            name = "kpi_#{s.kpi_id}_#{s.id}"
            select_cols.push name
            value_fields[name] = "#{f.label}: #{s.text}"
            "#{name} numeric"
          end
        else
          name = f.to_sql_name
          select_cols.push name
          value_fields[name] = "#{f.label}"
          "#{name} numeric"
        end
      end.flatten

      results = ActiveRecord::Base.connection.select_all("
        SELECT #{select_cols.join(', ')}
        FROM crosstab('\n\t#{values_sql(rows_columns).compact.join("\nUNION ALL\n\t").gsub(/'/, "''")}\n\tORDER BY 1',
          'select m from generate_series(1,#{values_columns.count}) m')
        AS ct(row_labels varchar[], #{values_columns.join(', ')}) ORDER BY 1 ASC
      ")

      empty_values = Hash[report_columns.map{|k| [k, nil]}]

      key_fields = rows.compact.map{|f| f.to_sql_name } - ['values']
      column_fields = columns.map{|f| f.to_sql_name }
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
    @columns_totals ||= begin
      results = fetch_results_for(columns, apply_values_formatting: false)
      if results.any?
        results.first['values']
      else
        []
      end
    end
  end

  def first_row_values_for_page
    @first_row_values_for_page ||= add_joins_scopes(base_events_scope, values).order('1 ASC').
    limit(50).offset(offset).
    pluck('DISTINCT ' + rows.first.table_column[0])
  end

  def base_events_scope
    company.events.active
  end

  protected
    def format_field(value)
      v = value
      v = [] if v.nil? || v == ''
      v = v.map{|k, v| v.to_h } if v.is_a?(ActionController::Parameters)
      v
    end

    def add_page_conditions_to_scope(s)
      if first_row_values_for_page.include?(nil)
        s.where("#{rows.first.table_column[0]} in (?) OR #{rows.first.table_column[0]} IS NULL", first_row_values_for_page)
      else
        s.where("#{rows.first.table_column[0]} in (?)", first_row_values_for_page)
      end
    end

    def values_sql(rc)
      unless values.nil? || rows.nil? || rows.empty?
        i = 0
        rows_field = "ARRAY[#{rc.keys.map{|k| k+'::text'}.join(', ')}]"
        values.map do |value|
          value_field = value['field']
          s = add_filters_conditions(add_joins_scopes(base_events_scope, value).group('1'))
          s = add_page_conditions_to_scope(s) if rc.has_key?(rows.first.table_column[0]) && page.present?
          if value.kpi.present?
            if value.kpi.is_segmented?
              value_field = value_aggregate_sql(value['aggregate'], 'event_results.scalar_value')
              value.kpi.kpis_segments.map{|segment| s.where('event_results.kpi_id=? and event_results.kpis_segment_id=?', value.kpi.id, segment.id).select("#{rows_field}, #{i+=1}, #{value_field}").to_sql }
            elsif value.kpi.kpi_type == 'count'
              if value['aggregate'] == 'count'
                value_field = value_aggregate_sql(value['aggregate'], 'event_results.scalar_value')
              else
                value_field = '0'
              end
              value.kpi.kpis_segments.map{|segment| s.where('event_results.kpi_id=? and event_results.value=?', value.kpi.id, segment.id.to_s).select("#{rows_field}, #{i+=1}, #{value_field}").to_sql }
            else
              if Kpi.promo_hours.id == value.kpi.id
                value_field = value_aggregate_sql(value['aggregate'], 'events.promo_hours')
              elsif Kpi.events.id == value.kpi.id
                value_field = value_aggregate_sql(value['aggregate'], '1')
              else
                value_field = value_aggregate_sql(value['aggregate'], 'event_results.scalar_value')
                s = s.where('event_results.kpi_id=?', value.kpi.id)
              end
              s.select("#{rows_field}, #{i+=1}, #{value_field}").to_sql
            end
          elsif m = /\A(.*):([a-z_]+)\z/.match(value['field'])
            if value['aggregate'] == 'count'
              value_field = value_aggregate_sql(value['aggregate'], value.table_column[0])
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

    def add_filters_conditions(s)
      if filter_params.present? && filter_params.any?
        filters.each do |filter|
          if filter_params.has_key?(filter.field)
            if filter_params[filter.field].is_a?(Hash)
              if filter_params[filter.field]['start'] && filter_params[filter.field]['end']
                start_date = Timeliness.parse(filter_params[filter.field]['start']).strftime('%Y-%m-%d 00:00:00')
                end_date = Timeliness.parse(filter_params[filter.field]['end']).strftime('%Y-%m-%d 23:59:59')
                s = s.where("#{filter.filter_column} BETWEEN ? AND ?", start_date, end_date )
              elsif filter_params[filter.field]['min'] && filter_params[filter.field]['max']
                if filter_params[filter.field]['min'].to_i == 0
                  s = s.where("(#{filter.filter_column} BETWEEN ? AND ? OR #{filter.filter_column} IS NULL)", filter_params[filter.field]['min'], filter_params[filter.field]['max'] )
                else
                  s = s.where("#{filter.filter_column} BETWEEN ? AND ?", filter_params[filter.field]['min'], filter_params[filter.field]['max'] )
                end
              end
            elsif filter_params[filter.field].is_a?(Array)
              s = s.where("#{filter.filter_column} IN (?)", filter_params[filter.field])
            end
          else
            nil
          end
        end
      end
      s
    end

    def add_joins_scopes(s, field_list)
      field_list = [field_list] unless field_list.is_a?(Array)
      fields = [field_list, rows, columns, filters].compact.inject{|sum,x| sum + x }
      if fields.any?{|v| v.kpi.present? && ![Kpi.events, Kpi.promo_hours].include?(v.kpi)}
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

      [rows, columns].compact.inject{|sum,x| sum + x }.each do |f|
        if f.kpi.present?
          s = s.joins("INNER JOIN event_results er_kpi_#{f.kpi.id} ON er_kpi_#{f.kpi.id}.event_id = events.id AND er_kpi_#{f.kpi.id}.kpi_id=#{f.kpi.id}")
        end
      end

      filters.each do |filter|
        if filter.kpi.present? && filter_params && filter_params.has_key?(filter.field) && !filter_params[filter.field].empty?
          s = s.joins("LEFT JOIN event_results er_kpi_#{filter.kpi.id} ON er_kpi_#{filter.kpi.id}.event_id = events.id AND er_kpi_#{filter.kpi.id}.kpi_id=#{filter.kpi.id}")
        end
      end

      fields = [rows, columns].compact.inject{|sum,x| sum + x }
      s
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
              if v.kpi.present? && (v.kpi.is_segmented? || v.kpi.kpi_type == 'count')
                v.kpi.kpis_segments.map{|segment| scoped_columns(s, c.slice(1, c.count), "#{prefix}#{v['label']}: #{segment.text}||") }
              else
                scoped_columns(s, c.slice(1, c.count), "#{prefix}#{v['label']}||")
              end
            end
          else
            values = ActiveRecord::Base.connection.select_values(s.select("DISTINCT(#{column.table_column[0]}) as value").order('1'))
            values.map do |v|
              scoped_columns(s.where(column.table_column[0] => v), c.slice(1, c.count), "#{prefix}#{v}||", index+1)
            end
          end
        else
          [prefix.gsub(/\|\|\z/,'')]
        end
      end.flatten
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
      if column_total.nil?  || column_total == 0
        ''
      else
        value*100/column_total
      end
    else
      value
    end
  end

  def table_column
    @table_column ||= if m = /\Akpi:([0-9]+)\z/.match(field)
      ["er_kpi_#{m[1]}.value", "kpi_#{m[1]}"]
    elsif m = /\A(.*):([a-z_]+)\z/.match(field)
      definition = field_class.report_fields[m[2].to_sym]
      definition[:column].nil? ? ["#{field_class.table_name}.#{m[2]}", m[2]] : ( definition[:column].respond_to?(:call) ? [definition[:column].call, m[2]] :  [definition[:column], m[2]])
    end
  end

  def filter_column
    @table_column ||= if m = /\Akpi:([0-9]+)\z/.match(field)
      "er_kpi_#{m[1]}.value"
    elsif m = /\A(.*):([a-z_]+)\z/.match(field)
      definition = field_class.report_fields[m[2].to_sym]
      column = definition[:filter_column] || definition[:column]
      column.nil? ? "#{field_class.table_name}.#{m[2]}" : ( column.respond_to?(:call) ? column.call :  column )
    end
  end

  def to_sql_name
    field.gsub(/:/,'_')
  end

  def display
    @data['display']
  end

  def field
    @data['field']
  end

  def label
    @data['label']
  end

  def aggregate
    @data['aggregate']
  end

  def to_hash
    @data
  end

  def kpi
    @kpi ||= if m = /\Akpi:([0-9]+)\z/.match(field)
      Kpi.where('company_id is null OR company_id = ?', @report.company_id).find(m[1])
    end
  end

  # Returns the expect param format (for strong_parameters) for the filters
  def allowed_filter_params
    if kpi.present? && kpi.kpi_type == 'number'
      {field => [:max, :min]}
    elsif column_info
      type = column_info.has_key?(:filter) ? column_info[:filter].call(self)[:type] : nil
      if type == 'calendar'
        {field => [:start, :end]}
      else
        {field => []}
      end
    end
  end

  def as_filter
    if kpi.present?
      if ['percentage', 'count'].include?(kpi.kpi_type)
        options = kpi.kpis_segments.map do |segment|
          { label: segment.text, id: segment.id, name: field }
        end
        { label: label, items: options }
      else
        result = @report.base_events_scope.joins(:results).where(event_results: {kpi_id: kpi.id}).select('MAX(event_results.scalar_value) as max_value, MIN(event_results.scalar_value) as min_value').first
        min = result.min_value.to_f.truncate
        max = result.max_value.to_f.ceil
        { label: label, name: field, min: min, max: max, selected_min: min, selected_max: max }
      end
    elsif column_info
      if column_info.has_key?(:filter)
        column_info[:filter].call(self)
      else
        options = field_class.in_company(@report.company_id).order("#{table_column[0]} ASC").pluck("DISTINCT #{table_column[0]}").map do |option|
          { label: option, id: option, name: field }
        end
        { label: label, items: options }
      end
    end
  end

  def column_info
    @column_info ||= if field_class.present?
      field_class.report_fields[field_attribute.to_sym]
    end
  end

  def field_class
    @klass ||= if m = /\A(.*):([a-z_]+)\z/.match(field)
      m[1].classify.constantize
    end
  end

  def field_attribute
    @field_attribute ||= if m = /\A.*:([a-z_]+)\z/.match(field)
      m[1]
    end
  end
end
