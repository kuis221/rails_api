node :field do
  {
    id: @field.id,
    kpi_id: @field.kpi_id,
    module: @field.kpi_module,
    segments: (@field.kpi.present? ? @field.kpi.kpis_segments.map(&:text): []),
    ordering: @field.ordering,
    name: @field.name,
    type: @field.field_type,
    options: @field.options,
    section_id: @field.section_id,
    fields: @field.field_type == 'section' ? @field.fields.map{|sf| build_field_response(sf) } : [],
  }
end