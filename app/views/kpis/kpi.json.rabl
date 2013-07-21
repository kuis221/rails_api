object nil


attributes id: :id, module: :module, name: :name, kpi_type: :type

node(:segments) do |kpi|
  kpi.kpis_segments.map(&:text)
end

node(:module_name) do |kpi|
  if kpi.module.present?
    I18n.translate("form_builder.modules.#{kpi.module}")
  else
    'Custom'
  end
end