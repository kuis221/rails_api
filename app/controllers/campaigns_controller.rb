class CampaignsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  include DeactivableHelper

  # This helper provide the methods to add/remove campaigns members to the event
  extend TeamMembersHelper

  layout false, only: :kpis

  def update_post_event_form
    attrs = params[:fields].dup
    attrs.each{|index, field| normalize_brands(field[:options][:brands]) if field[:options].present? && field[:options][:brands].present? }
    # Mark for destruction the fields that are not on the params
    field_ids = extract_fields_ids(attrs)
    mark_fields_for_destruction(resource.form_fields, field_ids)
    resource.form_fields_attributes = attrs
    resource.save
    render text: 'OK'
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

  def find_similar_kpi
    search = Sunspot.search(Kpi) do
      keywords(params[:name]) do
        fields(:name)
      end
      with(:company_id, [-1, current_company.id])
    end
    render json: search.results
  end

  def campaign_has_kpi?(kpi)
    resource.kpis.include?(kpi)
  end

  def remove_kpi
    @field = resource.form_fields.where(kpi_id: params[:kpi_id]).find(:first)
    @field.destroy
  end

  def add_kpi
    if resource.form_fields.where(kpi_id: params[:kpi_id]).count == 0
      kpi = Kpi.global_and_custom(current_company).find(params[:kpi_id])
      ordering = resource.form_fields.select('max(ordering) as ordering').reorder(nil).first.ordering || 0
      @field = resource.form_fields.create({kpi: kpi, field_type: kpi.kpi_type, name: kpi.name, ordering: ordering + 1, options: {capture_mechanism: kpi.capture_mechanism}}, without_protection: true)

      # Update any preview results captured for this kpi using the new
      # created field
      if @field.persisted?
        EventResult.joins(:event).where(events: {campaign_id: resource}, kpi_id: kpi).update_all(form_field_id: @field.id)
      end
    else
      render text: ''
    end
  end

  protected
    def normalize_brands(brands)
      unless brands.empty?
        brands.each_with_index do |b, index|
          b = Brand.find_or_create_by_name(b).id unless b =~ /^[0-9]$/
          brands[index] = b.to_i
        end
      end
    end

    def mark_fields_for_destruction(fields, field_ids)
      fields.each do |f|
        f.mark_for_destruction unless field_ids.include?(f.id)
        mark_fields_for_destruction f.fields, field_ids if f.field_type == 'section'
      end
    end

    def extract_fields_ids(fields)
      fields.map{|index, f| [f['id'].try(:to_i)] + extract_fields_ids(f['fields_attributes'] || []) }.flatten.compact
    end
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
