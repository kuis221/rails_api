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

    private
      def model_report_fields(klass)
        klass.report_fields.map{|k,info| ["#{klass.name.underscore}:#{k}", info[:title]]}
      end
  end
end