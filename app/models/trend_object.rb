require 'sunspot/trend_object_adapter'

class TrendObject
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include Sunspot::TrendObjectAdapter
  extend ActiveModel::Naming

  attr_reader :id, :resource, :result

  delegate :form_field_id, to: :result, allow_nil: true

  searchable do
    string :id

    integer :company_id
    integer :campaign_id

    integer :place_id
    integer :form_field_id

    integer :location, multiple: true do
      locations_for_index
    end

    string :country

    string :state

    string :city

    time :start_at, stored: true, trie: true
    time :end_at, stored: true, trie: true

    string :description, as: :terms_suggestions

    string :source
  end

  def initialize(resource, result=nil)
    @id = TrendObject.object_to_id(result || resource)
    @resource = resource
    @result = result
  end

  def description
    if resource.is_a?(Comment)
      resource.content
    else
      result.value
    end
  end

  def source
    if @resource.is_a?(Activity)
      "ActivityType:#{@resource.activity_type_id}"
    else
      @resource.class.name
    end
  end

  def company_id
    @resource.company_id
  end

  def campaign_id
    @resource.campaign_id
  end

  def place_id
    place.try(:id)
  end

  def country
    place.try(:country)
  end

  def city
    place.city if place.present?
  end

  def state
    place.try(:state_code)
  end

  def locations_for_index
    place.locations.pluck('locations.id') if place.present?
  end

  def place
    if @resource.is_a?(Comment)
      @resource.commentable.place
    elsif @resource.is_a?(Event)
      @resource.place
    elsif @resource.activitable.present?
      @resource.activitable.place
    end
  end

  def start_at
    if @resource.is_a?(Comment)
      @resource.commentable.start_at
    elsif @resource.is_a?(Event)
      @resource.start_at
    else
      @resource.activity_date.beginning_of_day
    end
  end

  def end_at
    if @resource.is_a?(Comment)
      @resource.commentable.end_at
    elsif @resource.is_a?(Event)
      @resource.start_at
    else
      @resource.activity_date.end_of_day
    end
  end

  def persisted?
    true
  end

  def self.inspect
    "#<#{self.to_s} id: #{ @id }, object: #{ @resource.inspect }>"
  end

  def self.logger
    Rails.logger
  end

  def self.load_objects(ids)
    ids_by_class = {}
    ids.each do|id|
      clazz_name, object_id = id.split(':')
      ids_by_class[clazz_name] ||= []
      ids_by_class[clazz_name].push object_id
    end

    ids_by_class.map do |clazz_name, ids|
      if clazz_name == 'comment'
        Comment.preload(commentable: :campaign).where(id: ids).map{ |o| TrendObject.new(o) }
      elsif clazz_name == 'form_field_result'
        FormFieldResult.includes(:resultable).where(id: ids).map{ |o| TrendObject.new(o.resultable, o) }
      end
    end.flatten
  end

  def self.object_to_id(resource)
    resource.class.name.underscore + ':' + resource.id.to_s
  end

  def self.find(id)
    if id
      clazz_name, object_id = id.split(':')
      obj = clazz_name.camelize.constantize.find(object_id)
      if obj.is_a?(Comment)
        TrendObject.new(obj)
      else
        TrendObject.new(obj.resultable, obj)
      end
    end
  end

  def self.do_search(params, include_facets=true)
    ss = solr_search do
      with :company_id, params[:company_id]

      with :source, params[:source] unless params[:source].nil?

      with :form_field_id, params[:question] unless params[:question].nil?

      with :campaign_id, params[:campaign] if params.has_key?(:campaign) and params[:campaign].present?

      if params[:area].present?
        any_of do
          with :place_id, Area.where(id: params[:area]).joins(:places).where(places: {is_location: false}).pluck('places.id').uniq + [0]
          with :location, Area.where(id: params[:area]).map{|a| a.locations.map(&:id) }.flatten + [0]
        end
      end

      if params.has_key?(:brand) and params[:brand].present?
        campaign_ids = Campaign.joins(:brands).where(brands: {id: params[:brand]}, company_id: params[:company_id]).pluck('DISTINCT(campaigns.id)')
        with "campaign_id", campaign_ids + [0]
      end

      if params[:start_date].present? and params[:end_date].present?
        d1 = Timeliness.parse(params[:start_date], zone: :current).beginning_of_day
        d2 = Timeliness.parse(params[:end_date], zone: :current).end_of_day
        any_of do
          with :start_at, d1..d2
          with :end_at, d1..d2
        end
      elsif params[:start_date].present?
        d = Timeliness.parse(params[:start_date], zone: :current)
        all_of do
          with(:start_at).less_than(d.end_of_day)
          with(:end_at).greater_than(d.beginning_of_day)
        end
      end

      if include_facets
        if term = params[:term]
          with(:description, term)
          facet :start_at, :time_range => (Time.parse('2009-06-01 00:00:00 -0400')..
                       Date.today.end_of_day), :time_interval => 86400
        elsif words = params[:words]
          facet :description, sort: :count, limit: (params[:limit] || 50), only: words
        else
          facet :description, sort: :count, limit: (params[:limit] || 50), prefix: params[:prefix]
        end
      end

      order_by(params[:sorting] || :start_at, params[:sorting_dir] || :desc)
      paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
    end
  end

  def self.solr_index(opts={})
    options = {
      :batch_size => Sunspot.config.indexing.default_batch_size,
      :batch_commit => true,
      :start => opts.delete(:first_id)
    }.merge(opts)

    if options[:batch_size].to_i > 0

      # Index events comments
      batch_counter = 0
      Comment.for_trends.preload(commentable: :place).find_in_batches(options.slice(:batch_size, :start)) do |records|
        solr_benchmark(options[:batch_size], batch_counter += 1) do
          Sunspot.index(records.map{|comment| TrendObject.new(comment) }.select { |model| model.indexable? })
          Sunspot.commit if options[:batch_commit]
        end
        options[:progress_bar].increment!(records.length) if options[:progress_bar]
      end

      # Index form field results
      batch_counter = 0
      FormField.where(type: FormField::TRENDING_FIELDS_TYPES).each do |form_field|
        form_field.form_field_results
          .order('resultable_type, resultable_id')
          .preload(:resultable)
          .find_in_batches(options.slice(:batch_size, :start)) do |records|

          solr_benchmark(options[:batch_size], batch_counter += 1) do
            Sunspot.index(records.map{|result| TrendObject.new(result.resultable, result) }.select { |model| model.indexable? })
            Sunspot.commit if options[:batch_commit]
          end
          options[:progress_bar].increment!(records.length) if options[:progress_bar]
        end
      end
    else
      Sunspot.index! Comment.for_trends.select(&:indexable?)
    end

    # perform a final commit if not committing in batches
    Sunspot.commit unless options[:batch_commit]
  end

  def self.count
    Comment.for_trends.count +
    Activity.active.with_results_for(
      FormField.where(type: ActivityType::TRENDING_FIELDS_TYPES)
        .joins('INNER JOIN activity_types ON activity_types.id=fieldable_id and fieldable_type=\'ActivityType\'')
        .group('form_fields.id')
        .pluck('form_fields.id')
    ).count
  end
end