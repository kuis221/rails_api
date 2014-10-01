class AddUserDateFieldToActivityTypes < ActiveRecord::Migration
  def change
    ActivityType.find_each do |activity_type|
      unless activity_type.form_fields.pluck(:type).include?('FormField::UserDate')
        activity_type.form_fields << FormField::UserDate.new(name: 'User/Date', ordering: (activity_type.form_fields.maximum(:ordering) || 0) + 1)
      end
    end
  end
end
