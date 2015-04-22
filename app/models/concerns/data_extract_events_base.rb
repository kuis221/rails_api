module DataExtractEventsBase
  extend ActiveSupport::Concern

  included do
    define_columns campaign_name: 'campaigns.name',
                   end_date: proc { "to_char(#{date_field_prefix}end_at, 'MM/DD/YYYY')" },
                   end_time: proc { "to_char(#{date_field_prefix}end_at, 'HH12:MI AM')" },
                   start_date: proc { "to_char(#{date_field_prefix}start_at, 'MM/DD/YYYY')" },
                   start_time: proc { "to_char(#{date_field_prefix}start_at, 'HH12:MI AM')" },
                   place_street: 'trim(both \' \' from places.street_number || \' \' || places.route)',
                   place_city: 'places.city',
                   place_name: 'places.name',
                   place_state: 'places.state',
                   place_zipcode: 'places.zipcode',
                   event_team_members: 'array_to_string(event_team_members.names, \', \')',
                   event_status: 'initcap(events.aasm_state)',
                   status: 'CASE WHEN events.active=\'t\' THEN \'Active\' ELSE \'Inactive\' END'
  end

  def add_joins_to_scope(s)
    s = s.joins(:campaign) if columns.include?('campaign_name')
    s = s.joins('LEFT JOIN places ON places.id=events.place_id') if columns.any? { |c| c.match(/^place_/)  }
    if columns.include?('event_team_members') || filters.present? && filters['user'].present?
      s = s.joins('LEFT JOIN event_team_members ON events.id=event_team_members.event_id')
    end
    s
  end

  def total_results
    Event.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
  end

  def model
    @model ||= Event
  end

  def add_filter_conditions_to_scope(s)
    return s if filters.nil? || filters.empty?
    s = s.where(campaign_id: filters['campaign']) if filters['campaign'].present?
    s = s.in_areas(params['area']) if filters['area'].present?
    s = s.where('ARRAY[?] && event_team_members.ids', filters['user']) if filters['user'].present?
    s = s.where(aasm_state: filters['event_status']) if filters['status'].present?
    s = s.where(active: filters['active_state'].map { |f| f == 'active' ? true : false }) if filters['active_state'].present?
    s = s.filters_between_dates(filters['start_date'].to_s, filters['end_date'].to_s) if filters['start_date'].present? && filters['end_date'].present?
    s
  end

  def sort_by_column(col)
    case col
    when 'start_date'
      :start_at
    when 'end_date'
      :end_at
    else
      super
    end
  end

  def date_field_prefix
    @date_field_prefix ||= current_user.company.timezone_support? ? 'local_' : ''
  end
end