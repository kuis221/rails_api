node :field do
  {
    id: @field.id,
    kpi_id: @field.kpi_id,
    segments: (@field.kpi.present? ? @field.kpi.kpis_segments.map(&:text): []),
    ordering: @field.ordering,
    name: @field.name,
    type: @field.type,
    settings: @field.settings
  }
end