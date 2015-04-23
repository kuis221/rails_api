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
#  params           :text
#

class DataExtract::EventExpense < DataExtract
  define_columns name: 'event_expenses.name',
                 amount: 'event_expenses.amount',
                 campaign_name: 'campaigns.name',
                 end_date: proc { "to_char(events.#{date_field_prefix}end_at, 'MM/DD/YYYY')" },
                 end_time: proc { "to_char(events.#{date_field_prefix}end_at, 'HH12:MI AM')" },
                 start_date: proc { "to_char(events.#{date_field_prefix}start_at, 'MM/DD/YYYY')" },
                 start_time: proc { "to_char(events.#{date_field_prefix}start_at, 'HH12:MI AM')" },
                 event_status: 'initcap(events.aasm_state)',
                 place_street: 'trim(places.street_number || \' \' || places.route)',
                 place_city: 'places.city',
                 place_name: 'places.name',
                 place_state: 'places.state',
                 place_zipcode: 'places.zipcode',
                 created_by: 'trim(users.first_name || \' \' || users.last_name)',
                 created_at: proc { "to_char(event_expenses.created_at, 'MM/DD/YYYY')" }

  def add_joins_to_scope(s)
    s = s.joins('LEFT JOIN events ON events.id=event_expenses.event_id')
    s = s.joins('LEFT JOIN places ON places.id=events.place_id')
    if columns.include?('created_by') || filters.present? && filters['user'].present?
      s = s.joins('LEFT JOIN users ON event_expenses.created_by_id=users.id')
    end
    if columns.include?('campaign_name')
      s = s.joins('LEFT JOIN campaigns ON events.campaign_id=campaigns.id')
    end
    s
  end

  def total_results
    EventExpense.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
  end

  def base_scope
    add_filter_conditions_to_scope add_joins_to_scope(model.for_user_accessible_events(current_user))
  end

  def date_field_prefix
    @date_field_prefix ||= current_user.company.timezone_support? ? 'local_' : ''
  end

  def filters_scope
    'events'
  end

  def sort_by_column(col)
    case col
    when 'start_date'
      "events.#{date_field_prefix}start_at"
    when 'end_date'
      "events.#{date_field_prefix}end_at"
    when 'created_at'
      'event_expenses.created_at'
    else
      super
    end
  end
  
  def filters_include_calendar
    true
  end
end
