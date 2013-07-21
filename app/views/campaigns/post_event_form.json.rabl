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

child Kpi.global_and_custom(current_company).includes(:kpis_segments).all => :kpis do
  extends 'kpis/kpi'
end