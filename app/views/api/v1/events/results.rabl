collection @results

attributes :id, :value

node :name do |r|
  r.kpis_segment_id.nil? ? r.form_field.name : r.kpis_segment.text
end

node :group do |r|
  r.kpis_segment_id.nil? ? nil : r.form_field.name
end

glue :form_field do
  attributes :ordering, :field_type, :options
end

node :segments, if: lambda{|r| r.form_field.field_type == 'count'} do |r|
  r.form_field.kpi.kpis_segments.map{|s| {id: s.id, text: s.text}}
end