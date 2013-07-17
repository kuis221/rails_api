object false

node :fields do
	@campaign.form_fields.includes(:kpi).map{|f| {id: f.id, kpi_id: f.kpi_id, kpi_slug: f.kpi_slug, module: f.kpi_module, ordering: f.ordering, name: f.name, type: f.field_type, options: f.options, section_id: f.section_id}}
end

node :modules do
	Hash[Kpi.global_and_custom(current_company).in_module.group_by(&:module).map do |mod, kpis|
		["#{mod}", kpis.map{|kpi| {id: kpi.id, name: kpi.name, slug: kpi.slug, type: kpi.kpi_type, capture_mechanism: kpi.capture_mechanism}}]
	end]
end