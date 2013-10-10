# == Schema Information
#
# Table name: form_templates
#
#  id         :integer          not null, primary key
#  program_id :integer          not null
#  creator_id :integer
#  updater_id :integer
#  created_at :datetime
#  updated_at :datetime
#

class Legacy::FormTemplate < Legacy::Record
  belongs_to    :program

  has_many      :form_fields

end