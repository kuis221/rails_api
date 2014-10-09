class Remote::EventResult < Remote::Record
  belongs_to :event, class_name: 'Remote::Event'

  def value_is_empty?
    value.nil? || value == '' || value == 0 || value == '0' || value == '0.0'
  end
end
