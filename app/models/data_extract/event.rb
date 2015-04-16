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

class DataExtract::Event < DataExtract
  define_columns campaign_name: 'campaigns.name',
                 end_date: proc { "to_char(#{date_field_prefix}end_at, 'MM/DD/YYYY')" },
                 end_time: proc { "to_char(#{date_field_prefix}end_at, 'HH12:MI AM')" },
                 start_date: proc { "to_char(#{date_field_prefix}start_at, 'MM/DD/YYYY')" },
                 start_time: proc { "to_char(#{date_field_prefix}start_at, 'HH12:MI AM')" },
                 place_address1: 'places.street_number',
                 place_address2: 'places.route',
                 place_city: 'places.city',
                 place_name: 'places.name',
                 place_state: 'places.state',
                 place_zipcode: 'places.zipcode',
                 event_team_members: 'array_to_string(array_agg(team_users.first_name || \' \' || team_users.last_name), \', \')',
                 event_status: 'initcap(events.aasm_state)',
                 created_by: '(SELECT trim(us.first_name || \' \' || us.last_name) FROM users as us WHERE events.created_by_id=us.id)',
                 created_at: proc { "to_char(events.created_at, 'MM/DD/YYYY')" },
                 status: 'CASE WHEN events.active=\'t\' THEN \'Active\' ELSE \'Inactive\' END'

  def add_joins_to_scope(s)
    s = s.joins(:campaign) if columns.include?('campaign_name')
    s = s.joins('LEFT JOIN places ON places.id=events.place_id') if columns.any? { |c| c.match(/^place_/)  }
    if columns.include?('event_team_members') || filters.present? && filters['user'].present?
      s = s.joins('LEFT JOIN event_team_members ON events.id=event_team_members.event_id')
           .joins('LEFT JOIN users team_users ON team_users.id=event_team_members.user_id')
           .group(group_by_columns)
    end
    s
  end

  def total_results
    Event.connection.select_value("SELECT COUNT(*) FROM (#{base_scope.select(*selected_columns_to_sql).to_sql}) sq").to_i
  end

  def group_by_columns
    (
      ['events.id'] + columns.each_with_index.map { |c, i| i + 1 } -
      [columns.index('event_team_members') + 1]     # Do not group by event_team_members
    ).join(',')
  end

  def add_filter_conditions_to_scope(s)
    return s if filters.nil? || filters.empty?
    s = s.where(campaign_id: filters['campaign']) if filters['campaign'].present?
    s = s.in_areas(params['area']) if filters['area'].present?
    s = s.where(team_users: { company_user_id: filters['user'] }) if filters['user'].present?
    s = s.where(aasm_state: filters['event_status']) if filters['status'].present?
    s = s.where(active: filters['active_state'].map { |f| f == 'active' ? true : false }) if filters['active_state'].present?
    s
  end

  def date_field_prefix
    @date_field_prefix ||= current_user.company.timezone_support? ? 'local_' : ''
  end
end
