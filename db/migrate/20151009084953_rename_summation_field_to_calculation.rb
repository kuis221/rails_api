class RenameSummationFieldToCalculation < ActiveRecord::Migration
  def change
    FormField.where(type: 'FormField::Summation').update_all(type: 'FormField::Calculation')
    FormField::Calculation.all.each do |f|
      f.settings ||= {}
      f.settings['operation'] = '+'
      f.settings['calculation_label'] = 'TOTAL'
      f.save
    end
  end
end
