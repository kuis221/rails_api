object @campaign

attributes :id, :name, :modules, :survey_brand_ids

child :form_fields => :form_fields do
  attributes :id, :name, :type, :required, :settings, :ordering, :kpi_id, :min_options_allowed, :min_statements_allowed
  node :options, if: ->(field){ field.respond_to?(:options) } do |field|
    field.options_for_input(true).each_with_index.map{|option, index| {id: option[1], name: option[0], ordering: index } }
  end
  node :statements, if: ->(field){ field.respond_to?(:statements) } do |field|
    field.statements.map{|statement| {id: statement.id, name: statement.name, ordering: statement.ordering } }
  end
end