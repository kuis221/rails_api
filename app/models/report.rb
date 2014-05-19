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
    @rows ||= load_fields(:rows)
  end

  def columns
    @columns ||= load_fields(:columns)
  end

  def values
    @values ||= load_fields(:values)
  end

  def filters
    @filters ||= load_fields(:filters)
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
        csv << row_fields.map{|n| row[n] } + format_values(row['values'])
        yield total, i if block_given? && i%50 == 0
      end
    end
  end

  def format_values(result_values, options={})
    values_position = columns.map(&:field).index('values')
    values_map = report_columns.map{|c| c.split('||')[values_position] }
    values_label_map = {}
    values.each do |v|
      if v.kpi.present? && (v.kpi.is_segmented? || v.kpi.kpi_type == 'count')
        v.kpi.kpis_segments.each{ |s| values_label_map["#{v.label}: #{s.text}"] =  v }
      elsif v.form_field.present? && v.form_field.is_optionable?
        v.form_field.options.each{ |o| p "#{v.label}: #{o.name}"; values_label_map["#{v.label}: #{o.name}"] =  v }
      else
        values_label_map[v.label] = v
      end
    end
    result_values.each_with_index.map do |value, index|
      values_label_map[values_map[index]].format_value result_values, index, options
    end
  end

  def offset
    ((page || 1)-1) * 30
  end

  def fetch_results_for(fields, params={})
    rows_columns = Hash[fields.map do |f|
      f.table_column
    end.compact]

    rows_columns = {'1' => 'col_name'} if rows_columns.empty?

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
        elsif f.form_field.present? && f.form_field.is_optionable?
          f.form_field.options.map do |o|
            name = "form_field_#{o.form_field_id}_#{o.id}"
            select_cols.push name
            value_fields[name] = "#{f.label}: #{o.name}"
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
        rows.push row
      end
      rows
    end
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
      results = fetch_results_for(columns)
      if results.any?
        results.first['values']
      else
        []
      end
    end
  end

  def first_row_values_for_page
    @first_row_values_for_page ||= add_filters_conditions(add_joins_scopes(base_events_scope, values)).order('1 ASC').
    limit(30).offset(offset).group('1').
    pluck(rows.first.table_column[0])
  end

  def base_events_scope
    company.events.active
  end

  def reload(options = nil)
    super
    @rows = @columns = @values = @filter = nil
    self
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
              elsif Kpi.photos.id == value.kpi.id
                value_field = value_aggregate_sql('COUNT', 'photos.id')
              elsif Kpi.comments.id == value.kpi.id
                value_field = value_aggregate_sql('COUNT', 'comments.id')
              elsif Kpi.expenses.id == value.kpi.id
                value_field = value_aggregate_sql(value['aggregate'], 'event_expenses.amount')
              else
                value_field = value_aggregate_sql(value['aggregate'], 'event_results.scalar_value')
                s = s.where('event_results.kpi_id=?', value.kpi.id)
              end
              s.select("#{rows_field}, #{i+=1}, #{value_field}").to_sql
            end
          elsif value.form_field.present?
            if value.form_field.is_optionable? && value.form_field.is_hashed_value?
              value.form_field.options.map do |option|
                value_field = value_aggregate_sql(value['aggregate'], '(activity_results.hash_value->\''+option.id.to_s+'\')::numeric')
                s.where("activity_results.form_field_id=#{value.form_field.id} and activity_results.hash_value ? '#{option.id}'").
                  select("#{rows_field}, #{i+=1}, #{value_field}").to_sql
              end
            elsif value.form_field.is_optionable?
              value_field = value['aggregate'] == 'count' ? value_aggregate_sql(value['aggregate'], 'activity_results.id') : 0
              value.form_field.options.map do |option|
                s.where('activity_results.form_field_id=? and activity_results.value=?', value.form_field.id, option.id.to_s).
                  select("#{rows_field}, #{i+=1}, #{value_field}").to_sql
              end
            else
              if value.form_field.is_numeric?
                value_field = value_aggregate_sql(value.aggregate, 'activity_results.scalar_value')
              elsif value.aggregate.downcase == 'count'
                value_field = value_aggregate_sql('count', 'activity_results.value')
              else
                value_field = '0'
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
          unless ['brand_portfolio', 'brand'].include?(filter.model_name)  # BrandPortfolios/Brands filters are handled directly in #add_joins_scopes
            if is_filtered_by?(filter.field)
              condition = filter_info = nil
              filter_info = filter.column_info[:filter].call(filter) if filter.column_info.present? && filter.column_info.has_key?(:filter)
              if filter_params[filter.field].is_a?(Hash)
                if filter_info && filter_info[:type] == 'calendar' && filter_params[filter.field]['start'] && filter_params[filter.field]['end']
                  start_date = Timeliness.parse(filter_params[filter.field]['start']).strftime('%Y-%m-%d 00:00:00')
                  end_date = Timeliness.parse(filter_params[filter.field]['end']).strftime('%Y-%m-%d 23:59:59')
                  condition = "#{filter.filter_column} BETWEEN ? AND ?", start_date, end_date
                elsif filter_info && filter_info[:type] == 'time' && (filter_params[filter.field]['start'] || filter_params[filter.field]['end'])
                  start_time = (Timeliness.parse('2014-01-01 ' + filter_params[filter.field]['start'].to_s) || Timeliness.parse('2014-01-01 00:00:00')).strftime('%H:%M:%S')
                  end_time   = (Timeliness.parse('2014-01-01 ' + filter_params[filter.field]['end'].to_s) || Timeliness.parse('2014-01-01 23:59:59')).strftime('%H:%M:%S')
                  condition = "#{filter.filter_column} BETWEEN ? AND ?", start_time, end_time
                elsif filter_params[filter.field]['min'] && filter_params[filter.field]['max']
                  if filter_params[filter.field]['min'].to_i == 0
                    condition = "(#{filter.filter_column} BETWEEN ? AND ? OR #{filter.filter_column} IS NULL)", filter_params[filter.field]['min'].to_i, filter_params[filter.field]['max'].to_i
                  else
                    condition = "#{filter.filter_column} BETWEEN ? AND ?", filter_params[filter.field]['min'].to_i, filter_params[filter.field]['max'].to_i
                  end
                end
              elsif filter_params[filter.field].is_a?(Array)
                condition = "#{filter.filter_column} IN (?)", filter_params[filter.field]
              end
              s = if condition[0] =~ /COUNT|SUM|AVG|MIN|MAX/
                s.having(condition)
              elsif condition
                s.where(condition)
              else
                s
              end unless condition.nil?
            else
              nil
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
      #fields = [field_list, rows, columns, filters].compact.inject{|sum,x| sum + x }
      fields = [field_list, rows, columns, filters].flatten.compact
      fields_without_filters = [field_list, rows, columns].flatten.compact
      if fields_without_filters.any?{|v| v.kpi.present? && is_a_result_kpi?(v.kpi)} ||
         filters.any?{|filter| filter.kpi.present? && is_filtered_by?(filter.field) && is_a_result_kpi?(filter.kpi)}
        # Include the form_fields table in the join making sure that only active kpis are counted
        s = s.joins(:results, {campaign: :form_fields}).where('campaign_form_fields.kpi_id=event_results.kpi_id AND event_results.kpi_id in (?)', field_list.select{|f| f.kpi.present? && is_a_result_kpi?(f.kpi) }.map{|f| f.kpi.id})
      end

      joined_with_activities = false
      if fields_without_filters.any?{|v| v.form_field.present?} ||
         filters.any?{|filter| filter.form_field.present? && is_filtered_by?(filter.field) }
        # Include the form_fields table in the join making sure that only active form fields results are counted
        s = s.joins(activities: :results, campaign: {activity_types: :form_fields}).where('activity_results.form_field_id=form_fields.id AND activity_type_campaigns.activity_type_id=activities.activity_type_id AND form_fields.id in (?)', field_list.map{|f| f.form_field.try(:id) }.compact)
        joined_with_activities = true
      end

      if fields_without_filters.any?{|v| v.kpi.present? && v.kpi.id == Kpi.photos.id}
        s = s.joins("LEFT JOIN attached_assets photos ON photos.attachable_type='Event' AND photos.asset_type='photo' AND photos.attachable_id = events.id AND photos.active='t'")
      end

      if fields_without_filters.any?{|v| v.kpi.present? && v.kpi.id == Kpi.comments.id}
        s = s.joins("LEFT JOIN comments ON comments.commentable_type='Event' AND comments.commentable_id = events.id")
      end

      if fields_without_filters.any?{|v| v.kpi.present? && v.kpi.id == Kpi.expenses.id}
        s = s.joins("LEFT JOIN event_expenses ON event_expenses.event_id = events.id")
      end

      s = s.joins(:place) if fields_without_filters.any?{|v| v.model_name == 'place' } || filters.any?{|v| v.model_name == 'place' && is_filtered_by?(v.field)}
      s = s.joins(:campaign) if fields_without_filters.any?{|v| v.model_name == 'campaign'} || filters.any?{|v| v.model_name == 'campaign' && is_filtered_by?(v.field)}

      # Join with users/teams table
      include_roles = fields_without_filters.any?{|v| v.model_name == 'role' } || filters.any?{|v| v.model_name == 'role' && is_filtered_by?(v.field)}
      if fields.any?{|v| v.model_name == 'user'} || filters.any?{|v| v.model_name == 'user' && is_filtered_by?(v.field)}  || include_roles
        s = s.joins_for_user_teams
        s = s.joins('INNER JOIN roles ON roles.id=company_users.role_id') if include_roles
      elsif fields.any?{|v| v.model_name == 'team'} || filters.any?{|v| v.model_name == 'team' && is_filtered_by?(v.field)}
        s = s.joins(:teams)
      end
      #s = s.joins(:campaign) if fields.any?{|v| Campaign.report_fields.keys.include?(v['field']) }

      # Join with areas table
      if fields.any?{|v| v.model_name == 'area'} || filters.any?{|v| v.model_name == 'area' && is_filtered_by?(v.field)}
        s = s.joins('LEFT JOIN "places" ON "places"."id" = "events"."place_id"
            LEFT JOIN (
                SELECT place_id, placeable_id area_id FROM "placeables"
                WHERE "placeables"."placeable_type" = \'Area\'
              UNION
                SELECT place_id, locations.area_id FROM locations_places
                INNER JOIN (
                  SELECT DISTINCT places.location_id, placeables.placeable_id area_id
                  FROM "places"
                  INNER JOIN "placeables" ON "placeables"."place_id" = "places"."id"
                  WHERE "placeables"."placeable_type" = \'Area\' AND "places"."is_location" = \'t\'
                ) locations on locations.location_id=locations_places.location_id
            ) areas_places ON events.place_id=areas_places.place_id
            LEFT JOIN areas ON areas.id=areas_places.area_id')
      end

      # Join with brand_portfolios table
      portfolio_filters = filters.select{|filter| filter.model_name == 'brand_portfolio' && is_filtered_by?(filter.field) }
      if [field_list, rows, columns].flatten.compact.any?{|v| v.model_name == 'brand_portfolio' }
        # This case is for when we are NOT filtering the list by brand portfolio but we DO have to fetch a portfolio field from the
        # database (eg Portofio Name as a row/column)
        s = s.joins(:campaign).joins("LEFT JOIN (
                SELECT brand_portfolios_campaigns.campaign_id, brand_portfolios_campaigns.brand_portfolio_id
                FROM brand_portfolios_campaigns
              UNION
                SELECT brands_campaigns.campaign_id, brand_portfolios_brands.brand_portfolio_id
                FROM brand_portfolios_brands
                INNER JOIN brands_campaigns ON brands_campaigns.brand_id = brand_portfolios_brands.brand_id
              ) bpj ON bpj.campaign_id = campaigns.id
              LEFT JOIN brand_portfolios ON brand_portfolios.id=bpj.brand_portfolio_id")

        portfolio_filters.each{|filter| s = s.where("#{filter.filter_column} IN (?)", filter_params[filter.field])}
      elsif portfolio_filters.any?
        # This case is for when we should filter the list by brand portfolio but doesn't have to fetch any portfolio field from the
        # database (eg Portofio Name as a row/column)
        conditions = "WHERE (#{portfolio_filters.map{|filter| filter.filter_column + ' IN ('+ filter_params[filter.field].map{|p| Event.sanitize(p) }.join(',')+')'}.join(' AND ')})"
        s = s.joins(:campaign).joins("INNER JOIN (
                SELECT brand_portfolios_campaigns.campaign_id
                FROM brand_portfolios_campaigns
                INNER JOIN brand_portfolios ON brand_portfolios.id = brand_portfolios_campaigns.brand_portfolio_id
                #{conditions}
              UNION
                SELECT brands_campaigns.campaign_id
                FROM brand_portfolios_brands
                INNER JOIN brands_campaigns ON brands_campaigns.brand_id = brand_portfolios_brands.brand_id
                INNER JOIN brand_portfolios ON brand_portfolios.id = brand_portfolios_brands.brand_portfolio_id
                #{conditions}
              ) bpj ON bpj.campaign_id = campaigns.id")
      end

      # Join with brands table
      brand_filters = filters.select{|filter| filter.model_name == 'brand' && is_filtered_by?(filter.field) }
      if [field_list, rows, columns].flatten.compact.any?{|v| v.model_name == 'brand' }
        # This case is for when we are NOT filtering the list by brands but we DO have to fetch a brand field from the
        # database (eg Brand Name as a row/column)
        s = s.joins(:campaign).joins("LEFT JOIN (
                SELECT brands_campaigns.campaign_id, brands_campaigns.brand_id
                FROM brands_campaigns
              UNION
                SELECT brand_portfolios_campaigns.campaign_id, brand_portfolios_brands.brand_id
                FROM brand_portfolios_campaigns
                INNER JOIN brand_portfolios_brands ON brand_portfolios_brands.brand_portfolio_id = brand_portfolios_campaigns.brand_portfolio_id
              ) bj ON bj.campaign_id = campaigns.id
              LEFT JOIN brands ON brands.id=bj.brand_id")

        brand_filters.each{|filter| s = s.where("#{filter.filter_column} IN (?)", filter_params[filter.field])}
      elsif brand_filters.any?
        # This case is for when we should filter the list by brand portfolio but doesn't have to fetch any portfolio field from the
        # database (eg Portofio Name as a row/column)
        conditions = "WHERE (#{brand_filters.map{|filter| filter.filter_column + ' IN ('+ filter_params[filter.field].map{|p| Event.sanitize(p) }.join(',')+')'}.join(' AND ')})"
        s = s.joins(:campaign).joins("INNER JOIN (
                SELECT brands_campaigns.campaign_id
                FROM brands_campaigns
                INNER JOIN brands ON brands.id = brands_campaigns.brand_id
                #{conditions}
              UNION
                SELECT brand_portfolios_campaigns.campaign_id
                FROM brand_portfolios_campaigns
                INNER JOIN brand_portfolios_brands ON brand_portfolios_brands.brand_portfolio_id = brand_portfolios_campaigns.brand_portfolio_id
                INNER JOIN brands ON brands.id = brand_portfolios_brands.brand_id
                #{conditions}
              ) bj ON bj.campaign_id = campaigns.id")
      end

      # Joins with activities table
      activity_type_fields = [field_list, rows, columns].flatten.compact.select{|f| f.activity_type.present? }
      if activity_type_fields.any?
        ids = activity_type_fields.map{|at| at.activity_type.id }
        #s = s.joins("INNER JOIN activities activities on activities.activity_type_id in (#{ids.join(',')})")
        s = s.where(activities: {activity_type_id: ids})
        activity_type_fields.select{|f| f.activity_field == 'user' }.each do |f|
          s = s.joins("LEFT JOIN company_users cu_activities_#{f.activity_type.id} on cu_activities_#{f.activity_type.id}.id=activities.company_user_id " +
                      "LEFT JOIN users users_activities_#{f.activity_type.id} on users_activities_#{f.activity_type.id}.id=cu_activities_#{f.activity_type.id}.user_id " )
        end
      end

      [rows, columns].compact.inject{|sum,x| sum + x }.each do |f|
        if f.kpi.present?
          s = s.joins("INNER JOIN event_results er_kpi_#{f.kpi.id} ON er_kpi_#{f.kpi.id}.event_id = events.id AND er_kpi_#{f.kpi.id}.kpi_id=#{f.kpi.id}")
        elsif f.form_field.present?
          s = s.joins(
            "INNER JOIN activities a_field_#{f.form_field.id} ON a_field_#{f.form_field.id}.activitable_type='Event' and a_field_#{f.form_field.id}.activitable_id=events.id " + ( joined_with_activities ? "AND activities.id=a_field_#{f.form_field.id}.id " : '' ) +
            "INNER JOIN activity_results ar_field_#{f.form_field.id} ON ar_field_#{f.form_field.id}.activity_id = a_field_#{f.form_field.id}.id AND ar_field_#{f.form_field.id}.form_field_id=#{f.form_field.id}"
          )
          if f.form_field.is_optionable? && f.form_field.is_hashed_value?
            s = s.joins("
              LEFT JOIN form_field_options field_options_#{f.form_field.id}
              ON ar_field_#{f.form_field.id}.form_field_id=field_options_#{f.form_field.id}.form_field_id AND
                 ar_field_#{f.form_field.id}.hash_value ? field_options_#{f.form_field.id}.id::varchar")
          elsif f.form_field.is_optionable?
            s = s.joins("
                LEFT JOIN form_field_options field_options_#{f.form_field.id}
                ON ar_field_#{f.form_field.id}.form_field_id=field_options_#{f.form_field.id}.form_field_id AND
                ar_field_#{f.form_field.id}.value::numeric=field_options_#{f.form_field.id}.id")
          end
        end
      end

      # For each filter, we need to create a special join with the event results table
      filters.each do |filter|
        if filter.kpi.present? && is_filtered_by?(filter.field)
          if is_a_result_kpi?(filter.kpi)
            s = s.joins("LEFT JOIN event_results er_kpi_#{filter.kpi.id} ON er_kpi_#{filter.kpi.id}.event_id = events.id AND er_kpi_#{filter.kpi.id}.kpi_id=#{filter.kpi.id}")
          elsif filter.kpi.id == Kpi.comments.id
            s = s.joins("LEFT JOIN (SELECT count(comments.id) quantity, commentable_id FROM comments WHERE commentable_type='Event' GROUP BY commentable_id) filter_comments_join ON filter_comments_join.commentable_id = events.id")
          elsif filter.kpi.id == Kpi.photos.id
            s = s.joins("LEFT JOIN (SELECT count(attached_assets.id) quantity, attachable_id FROM attached_assets WHERE attachable_type='Event' AND asset_type='photo' GROUP BY attachable_id) filter_photos_join ON filter_photos_join.attachable_id = events.id")
          elsif filter.kpi.id == Kpi.expenses.id
            s = s.joins("LEFT JOIN (SELECT SUM(event_expenses.amount) amount, event_id FROM event_expenses GROUP BY event_id) filter_expenses_join ON filter_expenses_join.event_id = events.id")
          end
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

    # Returns true if the KPI is a KPI which results are stored on the event_results table or
    # false if it's a special kpi which result is obtained in a different way (like number of events, photos, etc)
    def is_a_result_kpi?(kpi)
      ![Kpi.events.id, Kpi.photos.id, Kpi.comments.id, Kpi.expenses.id, Kpi.promo_hours.id].include?(kpi.id)
    end

    def scoped_columns(s, c, prefix='', index=0)
      begin
        if c.any? && column = c.first
          if column['field'] == 'values'
            values.map do |v|
              if v.kpi.present? && (v.kpi.is_segmented? || v.kpi.kpi_type == 'count')
                v.kpi.kpis_segments.map{|segment| scoped_columns(s, c.slice(1, c.count), "#{prefix}#{v['label']}: #{segment.text}||") }
              elsif v.form_field.present? && v.form_field.is_optionable?
                v.form_field.options.map{|option| scoped_columns(s, c.slice(1, c.count), "#{prefix}#{v['label']}: #{option.name}||") }
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

    def is_filtered_by?(field_name)
      filter_params.present? && filter_params.has_key?(field_name) && filter_params[field_name].any?
    end
end


class Report::Field
  attr_accessor :type, :data, :report

  include ActionView::Helpers::NumberHelper

  def initialize(report, type, data)
    @report = report
    @type = type
    @data = data
  end

  def [](key)
    @data[key]
  end

  def apply_display_method(row_values, column_index)
    total = case display
    when 'perc_of_column'
      @report.columns_totals[column_index]
    when 'perc_of_row'
      _sum_total_for_value row_values, column_index
    when 'perc_of_total'
      _sum_total_for_value @report.columns_totals, column_index
    else
      -1
    end
    if total == -1
      row_values[column_index]
    elsif total.nil?  || total == 0
      ''
    else
      row_values[column_index]*100/total
    end
  end

  def format_value(row_values, column_index, options={})
    if row_values[column_index].present? && row_values[column_index] != ''
      if display.present? && display != '' && (options[:ignore_display].nil? || !options[:ignore_display])
        number_to_percentage(apply_display_method(row_values, column_index), precision: precision)
      else
        number_with_precision(row_values[column_index], precision: precision, delimiter: ',')
      end
    end
  end

  def table_column
    @table_column ||= if kpi.present?
      ["er_kpi_#{kpi.id}.value", "kpi_#{kpi.id}"]
    elsif form_field.present?
      if form_field.is_optionable?
        ["field_options_#{form_field.id}.name", "form_field_#{form_field.id}"]
      else
        ["ar_field_#{form_field.id}.value", "form_field_#{form_field.id}"]
      end
    elsif activity_type.present?
      if activity_field == 'user'
        ["users_activities_#{activity_type.id}.first_name || ' ' || users_activities_#{activity_type.id}.last_name", "activity_user_#{activity_type.id}"]
      elsif activity_field == 'activity_date'
        ["to_char(activities.#{activity_field}, 'YYYY/MM/DD')", "activity_#{activity_field}_#{activity_type.id}"]
      else
        ["activities.#{activity_field}", "activity_#{activity_field}_#{activity_type.id}"]
      end
    elsif m = /\A(.*):([a-z_]+)\z/.match(field)
      definition = field_class.report_fields[m[2].to_sym]
      definition[:column].nil? ? ["#{field_class.table_name}.#{m[2]}", m[2]] : ( definition[:column].respond_to?(:call) ? [definition[:column].call, m[2]] :  [definition[:column], m[2]] )
    end
  end

  def filter_column
    @table_column ||= if kpi.present?
      if kpi.id == Kpi.events.id
        "COUNT(events.id)"
      elsif kpi.id == Kpi.promo_hours.id
        "SUM(events.promo_hours)"
      elsif kpi.id == Kpi.comments.id
        "filter_comments_join.quantity"
      elsif kpi.id == Kpi.photos.id
        "filter_photos_join.quantity"
      elsif kpi.id == Kpi.expenses.id
        "filter_expenses_join.amount"
      elsif kpi.kpi_type == 'number'
        "er_kpi_#{kpi.id}.scalar_value"
      else
        "er_kpi_#{kpi.id}.value"
      end
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

  def precision
    @data.has_key?('precision') && @data['precision'] != '' ? @data['precision'].to_i :  2
  end

  def to_hash
    @data
  end

  def kpi
    @kpi ||= if m = /\Akpi:([0-9]+)\z/.match(field)
      Kpi.where('company_id is null OR company_id = ?', @report.company_id).find(m[1])
    end
  end

  def form_field
    @form_field ||= if m = /\Aform_field:([0-9]+)\z/.match(field)
      FormField.find(m[1])
    end
  end

  def activity_type
    @activity_type ||= if m = /\Aactivity_type_([0-9]+):(.*)\z/.match(field)
      @activity_field = m[2]
      ActivityType.find(m[1])
    end
  end

  def activity_field
    @activity_field
  end

  def model_name
    @model_name ||= if m = /\A([a-z_]+):.*\z/.match(field)
      m[1]
    end
  end

  # Returns the expect param format (for strong_parameters) for the filters
  def allowed_filter_params
    if kpi.present? && (kpi.kpi_type == 'number' || [Kpi.photos.id, Kpi.expenses.id, Kpi.comments.id, Kpi.events.id, Kpi.promo_hours.id].include?(kpi.id) )
      {field => [:max, :min]}
    elsif column_info
      type = column_info.has_key?(:filter) ? column_info[:filter].call(self)[:type] : nil
      if ['calendar', 'time'].include?(type)
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
        if kpi.id == Kpi.photos.id
          result = @report.base_events_scope.joins("LEFT JOIN (SELECT count(attached_assets.id) quantity, attachable_id FROM attached_assets WHERE attachable_type='Event' AND asset_type='photo' GROUP BY attachable_id) photos ON photos.attachable_id = events.id").select('MAX(photos.quantity) as max_value, 0 as min_value').first
        elsif kpi.id == Kpi.comments.id
          result = @report.base_events_scope.joins("LEFT JOIN (SELECT count(comments.id) quantity, commentable_id FROM comments WHERE commentable_type='Event' GROUP BY commentable_id) comments ON comments.commentable_id = events.id").select('MAX(comments.quantity) as max_value, 0 as min_value').first
        elsif kpi.id == Kpi.expenses.id
          result = @report.base_events_scope.joins("LEFT JOIN (SELECT sum(event_expenses.amount) quantity, event_id FROM event_expenses GROUP BY event_id) expenses ON expenses.event_id = events.id").select('MAX(expenses.quantity) as max_value, 0 as min_value').first
        elsif kpi.id == Kpi.events.id
          result = @report.base_events_scope.select('count(events.id) as max_value, 0 as min_value').first
        elsif kpi.id == Kpi.promo_hours.id
          result = @report.base_events_scope.select('MAX(events.promo_hours) as max_value, 0 as min_value').first
        else
          result = @report.base_events_scope.joins(:results).where(event_results: {kpi_id: kpi.id}).select('MAX(event_results.scalar_value) as max_value, MIN(event_results.scalar_value) as min_value').first
        end
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

  def _sum_total_for_value(row_values, column_index)
    _field_positions_in_value.map{|position| row_values[position] }.compact.reduce(:+)
  end

  def _field_positions_in_value
    @field_positions_in_value ||= begin
      values_position = @report.columns.map(&:field).index('values')
      values_map = @report.report_columns.map{|c| c.split('||')[values_position] }
      values_map.each_with_index.map{|l, index| index if l == label }.compact
    end
  end
end
