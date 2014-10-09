class SolrSearcher
  class << self
    def search(clazz, params, include_facets)
      clazz.solr_search do
        with :company_id, params[:company_id]
        with_campaign params[:campaign] if params[:campaign]
        with_area params[:area] if params[:area]
        with_place params[:place] if params[:place]
        with_location params[:location] if params[:location]
        with_status params[:status] if params[:status]
        with_id params[:id] if params[:id]
        with_event_status params[:with_custom_search] if params[:with_custom_search]

        with_user_teams params

        restrict_search_to_user_permissions params[:current_company_user] if params[:current_company_user]

        with_custom_search params[:q] if params[:q]

        # clazz.search_facets.call if include_facets
        Util.instance_eval_or_call(self, clazz.search_facets)

        yield if block_given?
      end
    end
  end
end

module Sunspot
  module DSL
    class Search
      def with_campaign(campaigns)
        if field?(:campaign_id)
          with :campaign_id, campaigns
        elsif field?(:campaing_ids)
          with :campaign_id, campaigns
        end
      end

      def with_area(areas)
        if field?(:area_id)
          with :area_id, areas
        elsif field?(:area_ids)
          with :area_ids, areas
        elsif field?(:place_id) && field?(:location)
          any_of do
            with :place_id, Area.where(id: params[:area]).joins(:places).where(places: { is_location: false }).pluck('places.id').uniq + [0]
            with :location, Area.where(id: params[:area]).map { |a| a.locations.map(&:id) }.flatten + [0]
          end
        end
      end

      def with_brand(brands)
        if field?(:brand_id)
          with :brand_id, brands
        elsif field?(:brand_ids)
          with :brand_ids, brands
        elsif field?(:campaign_ids) || field?(:campaign_id)
          campaigns = Campaign.with_brands(value).pluck('campaigns.id')
          campaigns = '-1' if campaigns.empty?
          with_campaign campaigns
        end
      end

      def with_place(places)
        if field?(:place_id)
          with :place_id, places
        elsif field?(:place_ids)
          with :place_ids, places
        end
      end

      def with_venue(venues)
        if field?(:venue_id)
          with :venue_id, venues
        elsif field?(:venue_ids)
          with :venue_ids, venues
        else
          with_place Venue.where(id: value).pluck(:place_id)
        end
      end

      def with_location(locations)
        with :locations, locations if field?(:locations)
      end

      def with_status(statuses)
        with :status, statuses if field?(:status)
      end

      def with_id(ids)
        with :id, ids if field?(:id)
      end

      def with_user_teams(params)
        return unless (params.key?(:user) && params[:user].present?) ||
                      (params.key?(:team) && params[:team].present?)
        team_ids = []
        team_ids += params[:team] if params.key?(:team) && params[:team].any?
        team_ids += Team.with_user(params[:user]).map(&:id) if params.key?(:user) && params[:user].any?

        any_of do
          with(:user_ids, params[:user]) if params.key?(:user) && params[:user].present?
          with(:team_ids, team_ids) if team_ids.any?
        end
      end

      # Used for searching events by status
      def with_event_status(statuses)
        event_status = statuses.dup
        late = event_status.delete('Late')
        due = event_status.delete('Due')
        executed = event_status.delete('Executed')
        scheduled = event_status.delete('Scheduled')

        end_at_field = :end_at
        if Company.current && Company.current.timezone_support?
          end_at_field = :local_end_at
        end

        any_of do
          with :status, event_status unless event_status.empty?
          unless late.nil?
            all_of do
              with(:status, 'Unsent')
              with(end_at_field).less_than(current_company.late_event_end_date)
            end
          end

          unless due.nil?
            all_of do
              with(:status, 'Unsent')
              with(end_at_field, current_company.due_event_start_date..current_company.due_event_end_date)
            end
          end

          with(end_at_field).less_than(Time.zone.now) unless executed.nil?

          with(end_at_field).greater_than(Time.zone.now.beginning_of_day) unless scheduled.nil?
        end
      end

      def with_custom_search(search)
        (attribute, value) = search.split(',')
        case attribute
        when 'brand'    then with_brand value
        when 'campaign' then with_campaign value
        when 'place'    then with_place value
        when 'company_user' then with_user value
        when 'venue'    then with_venue value
        when 'area'     then with_area value
        when 'team'     then with_user_teams(team: [value])
        end
      end

      def restrict_search_to_user_permissions(company_user)
        return if company_user.role.is_admin?
        with_campaign company_user.accessible_campaign_ids + [0]
        within_user_locations(company_user)
      end

      def within_user_locations(company_user)
        any_of do
          with(:place_id, company_user.accessible_places + [0])
          with(:location, company_user.accessible_locations + [0])
        end
      end

      protected

      def field?(name)
        @field_names = @setup.fields.map(&:name)
      end
    end
  end
end