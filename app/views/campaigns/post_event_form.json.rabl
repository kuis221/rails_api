object false

def build_field_response(f)
	{
		id: f.id,
		kpi_id: f.kpi_id,
		module: f.kpi_module,
		segments: (f.kpi.present? ? f.kpi.kpis_segments.map(&:text): []),
		ordering: f.ordering,
		name: f.name,
		type: f.field_type,
		options: f.options,
		section_id: f.section_id,
		fields: f.field_type == 'section' ? f.fields.map{|sf| build_field_response(sf) } : [],
	}
end

node :fields do
	@campaign.form_fields.where(section_id: nil).includes({kpi: :kpis_segments}).map do |f|
		build_field_response(f)
	end
end

node :kpis do
	Kpi.global_and_custom(current_company).includes(:kpis_segments).map{|k| {id: k.id, module: k.module, module_name: t("form_builder.modules.#{k.module || 'custom'}"), segments: k.kpis_segments.map(&:text), name: k.name, type: k.kpi_type}}
end