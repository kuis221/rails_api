# == Schema Information
#
# Table name: campaigns
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  description      :text
#  aasm_state       :string(255)
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  company_id       :integer
#  first_event_id   :integer
#  last_event_id    :integer
#  first_event_at   :datetime
#  last_event_at    :datetime
#  start_date       :date
#  end_date         :date
#  survey_brand_ids :integer          default([]), is an Array
#  modules          :text
#  color            :string(10)
#

class Campaign < ActiveRecord::Base
  include AASM
  include GoalableModel

  # Created_by_id and updated_by_id fields
  track_who_does_it

  scoped_to_company

  serialize :modules

  # Required fields
  validates :name, presence: true
  validates :company_id, presence: true, numericality: true

  AVAILABLE_COLORS =
      %w(#d3c941 #606060 #a18740 #d93f99 #a766cf #7e42a4
         #d7a23c #6c5f3c #bfbfbf #909090 #606060 #0033a0
         #01afc7 #0a1e2c #1d5632 #de4d43 #5a1e1e)

  DATE_FORMAT = %r{\A[0-1]?[0-9]/[0-3]?[0-9]/[0-2]0[0-9][0-9]\z}

  validates :start_date, format: { with: DATE_FORMAT, message: 'MM/DD/YYYY' }, allow_nil: true
  validates :end_date, format: { with: DATE_FORMAT, message: 'MM/DD/YYYY' }, allow_nil: true
  validates :end_date, presence: true, date: { on_or_after: :start_date, message: 'must be after' }, if: :start_date
  validates :start_date, presence: true, if: :end_date
  validates :color, inclusion: {in: AVAILABLE_COLORS }, allow_nil: true, allow_blank: true

  validate :valid_modules?

  # validates_date :start_date, before: :end_date,  allow_nil: true, allow_blank: true, before_message: 'must be before'
  # validates_date :end_date, on_or_after: :start_date, allow_nil: true, allow_blank: true, on_or_after_message: ''

  # Campaigns-Brands relationship
  has_and_belongs_to_many :brands, -> { order('brands.name ASC').where(brands: { active: true }) }, autosave: true

  # Campaigns-Brand Portfolios relationship
  has_and_belongs_to_many :brand_portfolios, -> { order('brand_portfolios.name ASC').where(brand_portfolios: { active: true }) },
                          autosave: true, after_remove: :remove_child_goals_for
  has_many :brand_portfolio_brands, through: :brand_portfolios, class_name: 'Brand', source: :brands

  # Campaigns-Areas relationship
  has_many :areas_campaigns, inverse_of: :campaign
  has_many :areas, -> { order('areas.name ASC').where(active: true) }, through: :areas_campaigns,
        autosave: true, after_remove: :clear_locations_cache, after_add: :clear_locations_cache

  # Campaigns-Areas relationship
  has_and_belongs_to_many :date_ranges, -> { order('date_ranges.name ASC').where(active: true) },
                          autosave: true, after_remove: :remove_child_goals_for

  # Campaigns-Areas relationship
  has_and_belongs_to_many :day_parts, -> { order('day_parts.name ASC').where(active: true) },
                          autosave: true, after_remove: :remove_child_goals_for

  belongs_to :first_event, class_name: 'Event'
  belongs_to :last_event, class_name: 'Event'

  # Campaigns-Users relationship
  has_many :memberships, as: :memberable, inverse_of: :memberable
  has_many :users, class_name: 'CompanyUser', source: :company_user, through: :memberships,
                   after_add: :reindex_associated_resource,
                   after_remove: :reindex_associated_resource

  # Campaigns-Events relationship
  has_many :events, -> { order 'start_at ASC' }, inverse_of: :campaign

  # Campaigns-Teams relationship
  has_many :teamings, as: :teamable, inverse_of: :teamable
  has_many :teams, through: :teamings,
                   after_add: :reindex_associated_resource,
                   after_remove: :reindex_associated_resource

  has_many :user_teams, class_name: 'CompanyUser', source: :users, through: :teams

  has_many :form_fields, -> { order('form_fields.ordering ASC') }, as: :fieldable

  has_many :kpis, through: :form_fields

  # Activity-Type relationships
  has_many :activity_type_campaigns
  has_many :activity_types, through: :activity_type_campaigns

  scope :with_goals_for, ->(kpi) { joins(:goals).where(goals: { kpi_id: kpi }).where('goals.value is not NULL AND goals.value > 0') }
  scope :accessible_by_user, ->(company_user) {
    if company_user.is_admin?
      where(company_id: company_user.company_id)
    else
      where(company_id: company_user.company_id, id: company_user.accessible_campaign_ids)
    end
  }
  scope :active, -> { where(aasm_state: 'active') }

  # Campaigns-Places relationship
  has_many :placeables, as: :placeable
  has_many :places, through: :placeables, after_remove: :clear_locations_cache, after_add: :clear_locations_cache

  # Attached Documents
  has_many :documents, -> { order('created_at DESC').where(asset_type: :document) }, class_name: 'AttachedAsset', as: :attachable, inverse_of: :attachable

  accepts_nested_attributes_for :form_fields, allow_destroy: true

  aasm do
    state :active, initial: true
    state :inactive
    state :closed

    event :activate do
      transitions from: [:inactive, :closed], to: :active
    end

    event :deactivate do
      transitions from: :active, to: :inactive
    end
  end

  searchable do
    text :name, stored: true

    string :name
    string :status

    integer :company_id
    integer :id

    integer :place_ids, multiple: true

    string :aasm_state

    integer :user_ids, multiple: true

    integer :team_ids, multiple: true

    integer :brand_ids, multiple: true

    integer :brand_portfolio_ids, multiple: true

    integer :company_user_ids, multiple: true do
      user_ids
    end
  end

  def has_date_range?
    start_date.present? && end_date.present?
  end

  def in_date_range?(s, e)
    has_date_range? && (e >= start_date && s < end_date)
  end

  def staff
    (staff_users + teams).sort_by(&:name)
  end

  def staff_users
    @staff_users ||= Campaign.connection.unprepared_statement do
      CompanyUser.find_by_sql("
        #{users.active.to_sql} UNION
        #{CompanyUser.active.where(company_id: company_id).joins(:brands).where(brands: { id: brand_ids }).to_sql} UNION
        #{CompanyUser.active.where(company_id: company_id).joins(:brand_portfolios).where(brand_portfolios: { id: brand_portfolio_ids }).to_sql}
      ")
    end
  end

  # This is similar to #staff_users except that it also include users from the
  # teams associated
  def all_users_with_access
    @staff_users ||= Campaign.connection.unprepared_statement do
      CompanyUser.find_by_sql("
        #{users.active.to_sql} UNION
        #{user_teams.active.to_sql} UNION
        #{company.company_users.active.admin.to_sql} UNION
        #{CompanyUser.active.where(company_id: company_id).joins(:brands).where(brands: { id: brand_ids }).to_sql} UNION
        #{CompanyUser.active.where(company_id: company_id).joins(:brand_portfolios).where(brand_portfolios: { id: brand_portfolio_ids }).to_sql}
      ")
    end
  end

  def areas_and_places
    (areas + places).sort_by(&:name)
  end

  def place_allowed_for_event?(place)
    !geographically_restricted? ||
    place.location_ids.any? { |location| accessible_locations.include?(location) } ||
    place.persisted? && (Place.linked_to_campaign(self).where(id: place.id).count('DISTINCT places.id') > 0)
  end

  def accessible_locations
    Rails.cache.fetch("campaign_locations_#{id}") do
      (
        areas.reorder(nil).joins(:places).where(places: { is_location: true }).pluck('places.location_id') +
        places.where(is_location: true).reorder(nil).pluck('places.location_id')
      ).map(&:to_i)
    end
  end

  def brands_list
    brands.map(&:name).join ','
  end

  def brands_list=(list)
    brands_names = list.split(',')
    existing_ids = brands.map(&:id)
    brands_names.each do |brand_name|
      brand = Company.current.brands.find_or_initialize_by(name: brand_name)
      brands << brand unless existing_ids.include?(brand.id)
    end
    brands.each { |brand| brand.mark_for_destruction unless brands_names.include?(brand.name) }
  end

  def event_status_data_by_areas(user)
    user_allowed_areas = areas.accessible_by_user(user).pluck('areas.id')
    event_status_graph_data children_goals.for_areas(user_allowed_areas), ->(goalable) {
      events.active.in_campaign_area(areas_campaigns.find_by(area_id: goalable))
    }
  end

  def event_status_data_by_staff
    event_status_graph_data children_goals.for_staff(user_ids, team_ids), ->(goalable) {
      if goalable.is_a?(CompanyUser)
        events.active.with_user_in_team(goalable)
      else
        events.active.with_team(goalable)
      end
    }
  end

  def event_status_graph_data(children_goals_scope, events_scope)
    stats = {}
    queries = Campaign.connection.unprepared_statement do
      children_goals_scope.with_value.includes(:goalable).where(kpi_id: [Kpi.events.id, Kpi.promo_hours.id]).map do |goal|
        name, group = if goal.kpi_id == Kpi.events.id then ['EVENTS', 'COUNT(events.id)'] else ['PROMO HOURS', 'SUM(events.promo_hours)'] end
        stats["#{goal.goalable.id}-#{name}"] = { 'id' => goal.goalable.id, 'name' => goal.goalable.name, 'goal' => goal.value, 'kpi' => name, 'executed' => 0.0, 'scheduled' => 0.0 }
        events_scope.call(goal.goalable)
          .select("ARRAY['#{goal.goalable.id}', '#{name}'], '#{name}' as kpi, CASE WHEN events.end_at < '#{Time.now.to_s(:db)}' THEN 'executed' ELSE 'scheduled' END as status, #{group}")
          .reorder(nil).group('1, 2, 3').to_sql
      end
    end

    ActiveRecord::Base.connection.select_all("
      SELECT keys[1] as id, kpi, executed, scheduled FROM crosstab('#{queries.join(' UNION ALL ').gsub('\'', '\'\'')} ORDER by 2 ASC, 1 ASC',
        'SELECT unnest(ARRAY[''executed'', ''scheduled''])') AS ct(keys varchar[], kpi varchar, executed numeric, scheduled numeric)").each do |result|
      r = stats["#{result['id']}-#{result['kpi']}"]
      r['executed'] = result['executed'].to_f if result['executed']
      r['scheduled'] = result['scheduled'].to_f if result['scheduled']
    end if queries.any?

    stats.each do |_k, r|
      r['remaining'] = r['goal'] - (r['scheduled'] + r['executed'])
      r['executed_percentage'] = (r['executed'] * 100 / r['goal']).to_i rescue 100
      r['executed_percentage'] = [100, r['executed_percentage']].min
      r['scheduled_percentage'] = (r['scheduled'] * 100 / r['goal']).to_i rescue 0
      r['scheduled_percentage'] = [r['scheduled_percentage'], (100 - r['executed_percentage'])].min
      r['remaining_percentage'] = 100 - r['executed_percentage'] - r['scheduled_percentage']
      if start_date && end_date && r['goal'] > 0
        s = start_date.to_date
        e = end_date.to_date
        days = (e - s).to_i
        if Date.today > s && Date.today < e && days > 0
          r['today'] = ((Date.today - s).to_i + 1) * r['goal'] / days
        elsif Date.today > e
          r['today'] = r['goal']
        else
          r['today'] = 0
        end
        r['today_percentage'] = [(r['today'] * 100 / r['goal']).to_i, 100].min
      end
    end

    stats.values.sort { |a, b| a['name'] + a['kpi'] <=> b['name'] + b['kpi'] }
  end

  def associated_brands
    brands + brand_portfolios.includes(:brands).map(&:brands).flatten
  end

  def associated_brand_ids
    (brands.pluck(:id) + brand_portfolio_brands.pluck(:id)).uniq
  end

  def status
    aasm_state.capitalize
  end

  def reindex_associated_resource(resource)
    Sunspot.index(resource)
  end

  def enabled_modules
    if modules
      modules.keys
    else
      []
    end
  end

  def enabled_modules_kpis
    enabled_modules.map { |m| Kpi.send(m) }
  end

  def active_global_kpis
    @active_global_kpis ||= [Kpi.events, Kpi.promo_hours] + (kpis.select { |k| k.module != 'custom' } + enabled_modules_kpis).sort_by(&:ordering)
  end

  def active_kpis
    @active_kpis ||= kpis + enabled_modules_kpis + [Kpi.events, Kpi.promo_hours]
  end

  def custom_kpis
    @custom_kpis ||= kpis.select { |k| k.module == 'custom' }
  end

  # Returns true if there is any area or place associated to the campaign
  def geographically_restricted?
    (areas.loaded? ? areas.any? : areas.count > 0) ||
    (places.loaded? ? places.any? : places.count > 0)
  end

  def add_kpi(kpi)
    field = form_fields.where(kpi_id: kpi).first

    # Make sure the kpi is not already assigned to the campaign
    if field.nil?
      ordering = form_fields.select('max(ordering) as ordering').reorder(nil).first.ordering || 0
      field = form_fields.create(
        kpi: kpi,
        field_type: kpi.form_field_type,
        name: kpi.name,
        ordering: ordering + 1
      )
    end

    field
  end

  def form_field_for_kpi(kpi)
    form_fields.find { |field| field.kpi_id == kpi.id }.tap { |f| f.kpi = kpi unless f.nil? }
  end

  def survey_statistics
    answers_scope = SurveysAnswer.joins(survey: :event).where(events: { campaign_id: id }, brand_id: survey_brands.map(&:id), question_id: [1, 3, 4])
    total_surveys = answers_scope.select('distinct(surveys.id)').count
    answers_scope = answers_scope.select('count(surveys_answers.id) as counter,surveys_answers.answer, surveys_answers.question_id, surveys_answers.brand_id').group('surveys_answers.answer, surveys_answers.question_id, surveys_answers.brand_id')
    brands_map = Hash[survey_brands.map { |b| [b.id, b.name] }]
    stats = {}
    answers_scope.each do |answer|
      stats["question_#{answer.question_id}"] ||= {}
      stats["question_#{answer.question_id}"][answer.answer] ||= {}
      stats["question_#{answer.question_id}"][answer.answer][brands_map[answer.brand_id]] ||= { count: 0, avg: 0.0 }
      stats["question_#{answer.question_id}"][answer.answer][brands_map[answer.brand_id]][:count] = answer.counter.to_i
      stats["question_#{answer.question_id}"].each { |_a, brands| brands.each { |_b, s| s[:avg] = s[:count] * 100.0 / total_surveys } }
    end

    stats
  end

  def survey_brands
    @survey_brands ||= Brand.where(id: survey_brand_ids)
  end

  def first_event=(event)
    unless event.nil?
      self.first_event_id = event.id
      self.first_event_at = event.start_at
    end
  end

  def last_event=(event)
    unless event.nil?
      self.last_event_id = event.id
      self.last_event_at = event.start_at
    end
  end

  def assign_all_global_kpis(autosave = true)
    assign_attributes(form_fields_attributes: {
                        '0' => { 'ordering' => '0', 'name' => 'Gender', 'field_type' => 'FormField::Percentage', 'kpi_id' => Kpi.gender.id },
                        '1' => { 'ordering' => '1', 'name' => 'Age', 'field_type' => 'FormField::Percentage', 'kpi_id' => Kpi.age.id },
                        '2' => { 'ordering' => '2', 'name' => 'Ethnicity/Race', 'field_type' => 'FormField::Percentage', 'kpi_id' => Kpi.ethnicity.id },
                        '7' => { 'ordering' => '7', 'name' => 'Impressions', 'field_type' => 'FormField::Number', 'kpi_id' => Kpi.impressions.id },
                        '8' => { 'ordering' => '8', 'name' => 'Interactions', 'field_type' => 'FormField::Number', 'kpi_id' => Kpi.interactions.id },
                        '9' => { 'ordering' => '9', 'name' => 'Samples', 'field_type' => 'FormField::Number', 'kpi_id' => Kpi.samples.id }
                      }, modules: { 'expenses' => {}, 'photos' => {}, 'surveys' => {}, 'videos' => {}, 'comments' => {} })
    save if autosave
  end

  def clear_locations_cache(area)
    remove_child_goals_for(area)
    Rails.cache.delete("campaign_locations_#{id}")
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets = false)
      solr_search do
        with(:company_id, params[:company_id])
        with(:user_ids, params[:user]) if params.key?(:user) && params[:user].present?
        with(:team_ids, params[:team]) if params.key?(:team) && params[:team].present?
        with(:brand_ids, params[:brand]) if params.key?(:brand) && params[:brand].present?
        with(:brand_portfolio_ids, params[:brand_portfolio]) if params.key?(:brand_portfolio) && params[:brand_portfolio].present?
        with(:status, params[:status]) if params.key?(:status) && params[:status].present?
        with(:id, params[:id]) if params.key?(:id) && params[:id].present?

        if params.key?(:q) && params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'campaign'
            with :id, value
          when 'venue'
            with :place_ids, Venue.find(value).place_id
          else
            with "#{attribute}_ids", value
          end
        end

        if include_facets
          facet :user_ids
          facet :team_ids
          facet :brand_ids
          facet :brand_portfolio_ids
          facet :status
        end

        order_by(params[:sorting] || :name, params[:sorting_dir] || :desc)
        paginate page: (params[:page] || 1), per_page: (params[:per_page] || 30)
      end
    end

    def report_fields
      {
        name:   { title: 'Name' }
      }
    end

    # Returns an array of data indication the progress of the campaigns based on the events/promo hours goals
    def promo_hours_graph_data
      Campaign.connection.unprepared_statement do
        q = with_goals_for(Kpi.promo_hours).joins(:events).where(events: { active: true })
           .select("campaigns.id, campaigns.name, campaigns.start_date, campaigns.end_date, goals.value as goal, 'PROMO HOURS' as kpi, CASE WHEN events.end_at < '#{Time.now.to_s(:db)}' THEN 'executed' ELSE 'scheduled' END as status, SUM(events.promo_hours)")
           .order('2, 1').group('1, 2, 3, 4, 5, 6, 7').to_sql.gsub(/'/, "''")
        data = ActiveRecord::Base.connection.select_all("SELECT * FROM crosstab('#{q}', 'SELECT unnest(ARRAY[''executed'', ''scheduled''])') AS ct(id int, name varchar, start_date date, end_date date, goal numeric, kpi varchar, executed numeric, scheduled numeric)").to_a

        q = with_goals_for(Kpi.events).joins(:events).where(events: { active: true })
           .select("campaigns.id, campaigns.name, campaigns.start_date, campaigns.end_date, goals.value as goal, 'EVENTS' as kpi, CASE WHEN events.end_at < '#{Time.now.to_s(:db)}' THEN 'executed' ELSE 'scheduled' END as status, COUNT(events.id)")
           .order('2, 1').group('1, 2, 3, 4, 5, 6, 7').to_sql.gsub(/'/, "''")
        data += ActiveRecord::Base.connection.select_all("SELECT * FROM crosstab('#{q}', 'SELECT unnest(ARRAY[''executed'', ''scheduled''])') AS ct(id int, name varchar, start_date date, end_date date, goal numeric, kpi varchar, executed numeric, scheduled numeric)").to_a
        data.sort! { |a, b| a['name'] <=> b['name'] }

        data.each do |r|
          r['id'] = r['id'].to_i
          r['goal'] = r['goal'].to_f
          r['executed'] = r['executed'].to_f
          r['scheduled'] = r['scheduled'].to_f
          r['remaining'] = r['goal'] - (r['scheduled'] + r['executed'])
          r['executed_percentage'] = (r['executed'] * 100 / r['goal']).to_i rescue 100
          r['executed_percentage'] = [100, r['executed_percentage']].min
          r['scheduled_percentage'] = (r['scheduled'] * 100 / r['goal']).to_i rescue 0
          r['scheduled_percentage'] = [r['scheduled_percentage'], (100 - r['executed_percentage'])].min
          r['remaining_percentage'] = 100 - r['executed_percentage'] - r['scheduled_percentage']
          if r['start_date'] && r['end_date'] && r['goal'] > 0
            r['start_date'] = Timeliness.parse(r['start_date']).to_date
            r['end_date'] = Timeliness.parse(r['end_date']).to_date
            days = (r['end_date'] - r['start_date']).to_i
            if Date.today > r['start_date'] && Date.today < r['end_date'] && days > 0
              r['today'] = ((Date.today - r['start_date']).to_i + 1) * r['goal'] / days
            elsif Date.today > r['end_date']
              r['today'] = r['goal']
            else
              r['today'] = 0
            end
            r['today_percentage'] = [(r['today'] * 100 / r['goal']).to_i, 100].min
          end
        end
        data
      end
    end

    # Returns an Array of campaigns ready to be used for a dropdown. Use this
    # to reduce the amount of memory by avoiding the load bunch of activerecord objects.
    def for_dropdown
      order('campaigns.name').pluck('campaigns.name, campaigns.id')
    end
  end

  def valid_modules?
    modules = %w(surveys photos expenses comments videos)
    if (enabled_modules - modules).any?
      errors.add :modules, :invalid
    end
  end
end
