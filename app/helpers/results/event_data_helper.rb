module Results
  module EventDataHelper
    def custom_fields_to_export_headers
      @_headers ||= custom_columns.values.map(&:upcase)
    end

    def custom_fields_to_export_values(event)
      # We are reusing the same object for each result to reduce memory usage
      @result ||= FormFieldResult.new
      event_values = empty_values_hash
      ActiveRecord::Base.connection.select_all(
        event.results.where(form_field_id: active_fields_for_campaign(event.campaign_id)).
                  select('form_field_results.form_field_id, form_field_results.value, form_field_results.hash_value').to_sql
      ).each do |row|
        @result.form_field = custom_fields_to_export[row['form_field_id'].to_i]
        if @result.form_field.is_hashed_value?
          @result.hash_value = ActiveRecord::Coders::Hstore.load(row['hash_value'])
        else
          @result.value = row['value']
        end
        id = @result.form_field.kpi_id.nil? ? "field_#{@result.form_field_id}" : "kpi_#{@result.form_field.kpi_id}"
        if @result.form_field.type == 'FormField::Percentage'
          #values = ActiveRecord::Coders::Hstore.load(row['hash_value'])
          # TODO: we have to correctly map values for hash_value here
          @result.form_field.options_for_input.each do |option|
            value = @result.value[option[1].to_s]
            event_values["#{id}-#{option[1]}"] = ['Number', 'percentage', (value.present? && value != '' ? value.to_f : 0.0)/100]
          end
        else
          event_values[id] = if @result.form_field.is_numeric?
            ['Number', 'normal', (Float(@result.to_html) rescue nil)]
          else
            ['String', 'normal', @result.to_html]
          end
        end
      end
      event_values.values
    end

    def area_for_event(event)
      campaign_from_cache(event.campaign_id).areas.select{|a| a.place_in_scope?(event.place) }.map(&:name).join(', ') unless event.place.nil?
    end

    def team_member_for_event(event)
      ActiveRecord::Base.connection.select_values("
        #{event.users.joins(:user).select('users.first_name || \' \' || users.last_name AS name' ).reorder(nil).to_sql}
        UNION ALL
        #{event.teams.select('teams.name').reorder(nil).to_sql}
        ORDER BY name
      ").join(', ')
    end

    def url_for_event(event)
      Rails.application.routes.url_helpers.event_url(event)
    end

    private
      # Returns an array of nils that need to be populated by the event
      # where the key is the id of the field + the id of the segment id if the field is segmentable
      def empty_values_hash
        @empty_values_hash ||= custom_columns.dup
        @empty_values_hash.each{|k,v| @empty_values_hash[k] = nil }
        @empty_values_hash
      end

      # Returns and array of Form Field IDs that are assigned to a campaign
      def active_fields_for_campaign(campaign_id)
        @campaign_fields ||= {}
        @campaign_fields[campaign_id] ||= campaign_from_cache(campaign_id).form_fields.where(id: custom_fields_to_export.keys).pluck(:id)
        @campaign_fields[campaign_id]
      end

      def custom_fields_to_export
        @kpis_to_export ||= begin
          exclude_kpis = [Kpi.impressions.id, Kpi.interactions.id, Kpi.samples.id, Kpi.gender.id, Kpi.ethnicity.id]
          campaign_ids = []
          campaign_ids = params[:campaign] if params[:campaign] && params[:campaign].any?
          if params[:q].present? && match = /\Acampaign,([0-9]+)/.match(params[:q])
            campaign_ids+= [match[1]]
          end
          campaign_ids = campaign_ids.uniq.compact
          unless current_company_user.is_admin?
            if campaign_ids.any?
              campaign_ids = campaign_ids.map(&:to_i) & current_company_user.accessible_campaign_ids
            else
              campaign_ids = current_company_user.accessible_campaign_ids
            end
          end
          if campaign_ids.any?
            fields_scope = FormField.for_events_in_company(current_company_user.company_id).where('form_fields.kpi_id not in (?)', exclude_kpis).order('form_fields.name ASC')
            fields_scope = fields_scope.where(campaigns: {id: campaign_ids}) unless current_company_user.is_admin? and campaign_ids.empty?
            Hash[fields_scope.map{|field| [field.id, field]}]
          else
            {}
          end
        end
        @kpis_to_export
      end

      def custom_columns
        @custom_columns ||= Hash[*custom_fields_to_export.map do |id, field|
          if field.type == 'FormField::Percentage'
            if field.kpi_id.nil?
              field.options_for_input.map{|s| ["field_#{field.id}-#{s[1]}", "#{field.name}: #{s[0]}"]}
            else
              field.options_for_input.map{|s| ["kpi_#{field.kpi_id}-#{s[1]}", "#{field.kpi.name}: #{s[0]}"]}
            end
          else
            field.kpi_id.nil? ? ["field_#{id}", field.name] : ["kpi_#{field.kpi_id}", field.kpi.name]
          end
        end.flatten]
        @custom_columns
      end

      def campaign_from_cache(id)
        @_campaign_cache ||= {}
        @_campaign_cache[id] ||= Campaign.find(id)
        @_campaign_cache[id]
      end
  end
end