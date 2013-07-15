object false


node :modules do
	Hash[Kpi.global_and_custom(current_company).in_module.group_by(&:module).map do |mod, kpis|
		["#{mod}", kpis.map{|kpi| {id: kpi.id, name: kpi.name, type: kpi.kpi_type, capture_mechanism: kpi.capture_mechanism}}]
	end]
end