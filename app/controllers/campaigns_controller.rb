class CampaignsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  include DeactivableHelper

  # This helper provide the methods to add/remove campaigns members to the event
  extend TeamMembersHelper

  layout false, only: :kpis

  def update_post_event_form
    fields = params[:fields].dup
    fields.each do |id, field|
      field['kpi_id'] = Kpi.find(field['kpi_id']).id if field['kpi_id'] =~ /[a-z]/i
    end
    ActiveRecord::Base.transaction do
      resource.form_fields_attributes = params[:fields]
      resource.save
    end
    render text: resource.errors.inspect
  end

  def autocomplete
    buckets = autocomplete_buckets({
      campaigns: [Campaign],
      brands: [Brand, BrandPortfolio],
      places: [Place],
      people: [CompanyUser, Team]
    })
    render :json => buckets.flatten
  end

  protected
    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)

        f.push(label: "Brands", items: facet_search.facet(:brands).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :brand}) } )
        f.push(label: "Brand Portfolios", items: facet_search.facet(:brand_portfolios).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :brand_portfolio}) } )
        users = facet_search.facet(:users).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :user}) }
        teams = facet_search.facet(:teams).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :team}) }
        people = (users + teams).sort { |a, b| b[:count] <=> a[:count] }
        f.push(label: "People", items: people )
        f.push(label: "Status", items: facet_search.facet(:status).rows.map{|x| build_facet_item({label: x.value, id: x.value, name: :status, count: x.count}) })
      end
    end
end
