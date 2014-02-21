module Results
  module ReportsHelper
    def available_field_list
      kpis = Kpi.where("company_id=? OR company_id is null", current_company.id).order('company_id DESC, name ASC')
      {
        'KPIs' => kpis.map{|kpi| ["kpi:#{kpi.id}", kpi.name]},
        'Event' => model_report_fields(Event),
        'Task' => model_report_fields(Task),
        'Venue' => model_report_fields(Place),
        'User' => model_report_fields(User),
        'Team' => model_report_fields(Team),
        'Role' => model_report_fields(Role),
        'Campaign' => model_report_fields(Campaign),
        'Brand Portfolios' => model_report_fields(BrandPortfolio),
        'Date Range' => model_report_fields(DateRange),
        'Day Part' => model_report_fields(DayPart)
      }
    end

    def report_column_label(column)
      column['label']
    end

    def each_grouped_report_row(results=nil, row_number=0, &block)
      results ||= @report.fetch_page
      row_field = @report.field_to_sql_name(@report.rows[row_number]['field'])
      previous_label = nil
      results.each do |row|
        if row_number < @report.rows.count-1
          row_label = row[row_field]
          if row_label != previous_label
            group = results.select{|r|r[row_field] == row_label}
            values = get_row_values(group, row_field, row_label)
            yield row_label, row_number, values
            each_grouped_report_row(group, row_number+1, &block)
          end
          previous_label = row_label
        else
          values = row.reject{|k,v| !report_columns_names.include?(k) }
          p values
          yield row[row_field], row_number, values
        end
      end
    end

    private
      def model_report_fields(klass)
        klass.report_fields.map{|k,info| ["#{klass.name.underscore}:#{k}", info[:title]]}
      end

      def get_row_values(group, row_field, row_label)
        values = Hash[report_columns_names.map{|name| [name, 0]}]
        group.each do |row|
          report_columns_names.map{|name| values[name] += row[name].to_f unless row[name].nil? }
        end
        values
      end

      # Return the names of the expected names from the SQL query for the report values and columns
      def report_columns_names
        @report_values_names ||= @report.values.map{|v| @report.field_to_sql_name(v['field']) }
      end
  end
end