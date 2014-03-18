object @activity_type

attributes :id, :name

child :form_fields => :form_fields do
  attributes :id, :name, :type, :required, :settings, :ordering
  node :options, if: lambda { |field| field.respond_to?(:options) } do |field|
    field.options.map{|option| {id: option.id, name: option.name} }
  end
end