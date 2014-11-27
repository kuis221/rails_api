module Results
  module EventDataHelper
    SEGMENTED_FIELD_TYPES = ['FormField::Percentage', 'FormField::Summation', 'FormField::LikertScale']
    PERCENTAGE_TYPE = 'FormField::Percentage'.freeze
    SUMMATION_TYPE = 'FormField::Summation'.freeze
    NUMBER = 'Number'.freeze
    STRING = 'String'.freeze
    def custom_fields_to_export_headers
      @_headers ||= custom_columns.values.map(&:upcase)
    end

    def custom_fields_to_export_values(resource)
      # We are reusing the same object for each result to reduce memory usage
      @result ||= FormFieldResult.new
      resource_values = empty_values_hash
      ActiveRecord::Base.connection.select_all(ActiveRecord::Base.connection.unprepared_statement do
        resource.results.where(form_field_id: active_fields_for_resource(resource))
                  .select('form_field_results.form_field_id, form_field_results.value, form_field_results.hash_value').to_sql
      end).each do |row|
        @result.form_field = custom_fields_to_export[row['form_field_id'].to_i]
        if @result.form_field.is_hashed_value?
          @result.hash_value = row['hash_value']
        else
          @result.value = row['value']
        end
        if SEGMENTED_FIELD_TYPES.include?(@result.form_field.type)
          # values = ActiveRecord::Coders::Hstore.load(row['hash_value'])
          # TODO: we have to correctly map values for hash_value here
          if @result.form_field.type == PERCENTAGE_TYPE
            @result.form_field.options_for_input.each do |option|
              value = @result.value[option[1].to_s]
              key = @fields_mapping["#{@result.form_field.id}_#{option[1]}"]
              resource_values[key] = [NUMBER, 'percentage', (value.present? && value != '' ? value.to_f : 0.0) / 100]
            end
          else
            sum = 0
            @result.form_field.options_for_input.each do |option|
              value = @result.value[option[1].to_s]
              sum += value.to_f if value
              key = @fields_mapping["#{@result.form_field.id}_#{option[1]}"]
              resource_values[key] = [NUMBER, 'normal', value]
            end
            if @result.form_field.type == SUMMATION_TYPE
              resource_values[@fields_mapping["#{@result.form_field.id}__TOTAL"]] = [NUMBER, 'normal', sum]
            end
          end
        else
          resource_values[@fields_mapping[@result.form_field.id]] =
            if @result.form_field.is_numeric?
              [NUMBER, 'normal', (Float(@result.to_csv) rescue nil)]
            else
              [STRING, 'normal', @result.to_csv]
            end
        end
      end
      resource_values.values
    end

    def area_for_event(event)
      campaign_from_cache(event.campaign_id).areas_campaigns.select do |ac|
        ac.place_in_scope?(event.place)
      end.map { |ac| ac.area.name }.join(', ') unless event.place.nil?
    end

    def area_for_activity(activity)
      return unless activity.campaign_id.present?
      campaign_from_cache(activity.campaign_id).areas_campaigns.select do|ac|
        ac.place_in_scope?(activity.place)
      end.map { |ac| ac.area.name }.join(', ') unless activity.place.nil?
    end

    def team_member_for_event(event)
      ActiveRecord::Base.connection.unprepared_statement do
        ActiveRecord::Base.connection.select_values("
          #{event.users.joins(:user).select('users.first_name || \' \' || users.last_name AS name').reorder(nil).to_sql}
          UNION ALL
          #{event.teams.select('teams.name').reorder(nil).to_sql}
          ORDER BY name
        ").join(', ')
      end
    end

    def url_for_event(event)
      Rails.application.routes.url_helpers.event_url(event)
    end

    private

    # Returns an array of nils that need to be populated by the event
    # where the key is the id of the field + the id of the segment id if the field is segmentable
    def empty_values_hash
      @empty_values_hash ||= custom_columns.dup
      @empty_values_hash.each { |k, _v| @empty_values_hash[k] = nil }
      @empty_values_hash
    end

    # Returns and array of Form Field IDs that are assigned to a campaign
    def active_fields_for_resource(resource)
      if resource.is_a?(Event)
        @campaign_fields ||= {}
        @campaign_fields[resource.campaign_id] ||= campaign_from_cache(resource.campaign_id).form_fields.where(
          id: custom_fields_to_export.keys
        ).pluck(:id)
        @campaign_fields[resource.campaign_id]
      else
        @activity_type_fields ||= {}
        @activity_type_fields[resource.activity_type_id] ||= FormField.for_activities.where(
          fieldable_id: resource.activity_type_id,
          id: custom_fields_to_export.keys
        ).pluck(:id)
        @activity_type_fields[resource.activity_type_id]
      end
    end

    def custom_fields_to_export
      @custom_fields_to_export ||= begin
        campaign_ids = []
        campaign_ids = params[:campaign] if params[:campaign] && params[:campaign].any?
        if params[:q].present? && match = /\Acampaign,([0-9]+)/.match(params[:q])
          campaign_ids += [match[1]]
        end
        campaign_ids = campaign_ids.uniq.compact
        unless current_company_user.is_admin?
          if campaign_ids.any?
            campaign_ids = campaign_ids.map(&:to_i) & current_company_user.accessible_campaign_ids
          else
            campaign_ids = current_company_user.accessible_campaign_ids
          end
        end
        Hash[form_fields_for_resource(campaign_ids)]
      end
      @custom_fields_to_export
    end

    def form_fields_for_resource(campaign_ids)
      if resource_class == Event
        form_fields_for_events(campaign_ids)
      else
        form_fields_for_activities(campaign_ids)
      end
    end

    def form_fields_for_events(campaign_ids)
      if campaign_ids.any?
        fields_scope = FormField.for_events_in_company(current_company_user.company)
                        .where('form_fields.kpi_id not in (?) OR kpi_id is NULL', exclude_kpis)
                        .where.not(type: exclude_field_types)
                        .order('lower(form_fields.name) ASC, form_fields.type ASC')
        fields_scope = fields_scope.where(campaigns: { id: campaign_ids }) unless current_company_user.is_admin? && campaign_ids.empty?
        fields_scope.map { |field| [field.id, field] }
      else
        []
      end
    end

    def form_fields_for_activities(campaign_ids)
      s =
        if campaign_ids.empty? && current_company_user.is_admin?
          FormField.for_activity_types_in_company(current_company_user.company)
        else
          FormField.for_activity_types_in_campaigns(campaign_ids)
        end.where.not(type: exclude_field_types).order('lower(form_fields.name) ASC, form_fields.type ASC')
      s = s.where(fieldable_id: params[:activity_type]) if params[:activity_type] && params[:activity_type].any?
      s.map { |field| [field.id, field] }
    end

    def exclude_field_types
      ['FormField::Attachment', 'FormField::Photo', 'FormField::Section', 'FormField::UserDate']
    end

    def exclude_kpis
      [Kpi.impressions.id, Kpi.interactions.id, Kpi.samples.id, Kpi.gender.id, Kpi.ethnicity.id]
    end

    def custom_columns
      return @custom_columns unless @custom_columns.nil?
      @fields_mapping = {}
      @custom_columns = {}
      custom_fields_to_export.each do |_, field|
        segments =
          if SEGMENTED_FIELD_TYPES.include?(field.type)
            s = field.options_for_input.map{ |option| ["#{field.id}_#{option[1]}", "#{field.name}: #{option[0]}"] }
            s.push(["#{field.id}__TOTAL", "#{field.name}: TOTAL"]) if field.type == SUMMATION_TYPE
            s
          else
            [[field.id, field.name]]
          end
        segments.each do |s|
          id = unique_field_id(field, s[1])
          @fields_mapping[s[0]] = id
          @custom_columns[id] = s[1]
        end
      end
      @custom_columns
    end

    def unique_field_id(field, name)
      @fieldable_fields_mapping ||= {}
      @fieldable_fields_mapping[field.fieldable_id] ||= []
      i = 0
      id = nil
      loop do
        id = [field.type, name.gsub(/[^\w:]/, '_').downcase, i += 1].join('/')
        break unless @fieldable_fields_mapping[field.fieldable_id].include?(id)
      end
      @fieldable_fields_mapping[field.fieldable_id].push id
      id
    end

    def campaign_from_cache(id)
      @_campaign_cache ||= {}
      @_campaign_cache[id] ||= Campaign.find(id)
      @_campaign_cache[id]
    end
  end
end
