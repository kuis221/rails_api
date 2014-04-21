object @activity_type

attributes :id, :name

child :form_fields => :form_fields do
  attributes :id, :name, :type, :required, :settings, :ordering
  node (:min_fields_allowed), if: lambda { |field| field.min_fields_allowed } do |field|
    field.min_fields_allowed
  end
  node (:current_visible), if: lambda { |field| field.respond_to?(:options) } do |field|
    field.options.length
  end
  node :options, if: lambda { |field| field.respond_to?(:options) } do |field|
    field.options.map{|option| {id: option.id, name: option.name, ordering: option.ordering } }
  end
  node :statements, if: lambda { |field| field.respond_to?(:statements) } do |field|
    field.statements.map{|statement| {id: statement.id, name: statement.name, ordering: statement.ordering } }
  end
end