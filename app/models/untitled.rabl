ActiveRecord::Base.logger = nil
FormField::Calculation.all.each do |field|
  valid_options = field.options.map(&:id).map(&:to_s)
  FormFieldResult.where(form_field_id: field.id).where.not(hash_value: nil).find_each do |result|
    next if result.value.nil? || result.value.empty?
    keys = result.value.keys
    if (keys - valid_options).count == keys.count
      result.value.transform_keys! do |k|
        correct_option = field.options.detect(-> { nil }) { |o| o.name == FormFieldOption.where(id: k).pluck(:name).first }
        correct_option.nil? ? k : correct_option.id.to_s
      end
      result.save
    end
  end
end
