class EventsController < FilteredController

  # This helper provide the methods to add/remove team members to the event
  extend TeamMembersHelper

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper
  include EventsHelper
  include ApplicationHelper

  helper_method :describe_filters

  respond_to :js, only: [:new, :create, :edit, :update, :edit_results, :save_results]

  custom_actions member: [:tasks, :edit_results]
  layout false, only: :tasks

  def autocomplete
    buckets = autocomplete_buckets({
      campaigns: [Campaign],
      brands: [Brand, BrandPortfolio],
      places: [Place],
      people: [CompanyUser, Team]
    })
    render :json => buckets.flatten
  end

  def save_results
    update! do |success, failure|
      success.js { render 'edit_results' }
    end
  end

  protected

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :start_date, :end_date, :company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)

        # Date Ranges
        ranges = [
            build_facet_item({label: 'Today', id: 'today', name: :predefined_date, count: 1, ordering: 1}),
            build_facet_item({label: 'This Week', id: 'week', name: :predefined_date, count: 1, ordering: 2}),
            build_facet_item({label: 'This Month', id: 'month', name: :predefined_date, count: 1, ordering: 3})
        ]
        ranges += DateRange.active.map{|r| {label: r.name, id: r.id, name: :date_range, count: 5}}
        f.push(label: "Date Ranges", items: ranges )

        f.push(label: "Campaigns", items: facet_search.facet(:campaign).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, name: :campaign, count: x.count}) })
        f.push build_brands_bucket(facet_search.facet(:campaign).rows)
        f.push build_locations_bucket(facet_search.facet(:place).rows)
        #f.push(label: "Brands", items: facet_search.facet(:brands).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, name: :brand, count: x.count}) })
        users = facet_search.facet(:users).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :user}) }
        teams = facet_search.facet(:teams).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :team}) }
        people = (users + teams).sort { |a, b| b[:count] <=> a[:count] }
        f.push(label: "People", items: people )
        f.push(label: "Status", items: ['Active', 'Inactive'].map{|x| build_facet_item({label: x, id: x, name: :status, count: 1}) })
      end
    end

    def build_locations_bucket(facets)
      first_five = facets.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :place}) }.first(5)
      first_five_ids = first_five.map{|x| x[:id] }
      locations = {}
      locations = Place.where(id: facets.map{|x| x.value.split('||')[0]}.uniq.reject{|id| first_five_ids.include?(id) }).load_organized(current_company.id)

      {label: 'Locations', top_items: first_five, items: locations}
    end

    def build_brands_bucket(campaings)
      campaigns_counts = Hash[campaings.map{|x| id, name = x.value.split('||'); [id.to_i, x.count] }]
      brands = {}
      Campaign.includes(:brands).where(id: campaigns_counts.keys).each do |campaign|
        campaing_brands = Hash[campaign.brands.map{|b| [b.id, {label: b.name, id: b.id, name: :brand, count: campaigns_counts[campaign.id]}] }]
        brands.merge!(campaing_brands){|k,a1,a2|  a1.merge({count: (a1[:count] + a2[:count])}) }
      end
      brands = brands.values.sort{|a, b| b[:count] <=> a[:count] }
      {label: 'Brands', items: brands}
    end

    def begin_of_association_chain
      current_company
    end

    def controller_filters(c)
      c.includes([:campaign, :place])
    end
end
