class DeleteFormFieldClientele < ActiveRecord::Migration
  def change
    ff = FormField.find_by({name: 'Clientele', fieldable_type: 'EntityForm'})
    FormField.destroy(ff) if ff.present?
  end
end
