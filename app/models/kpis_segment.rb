# == Schema Information
#
# Table name: kpis_segments
#
#  id         :integer          not null, primary key
#  kpi_id     :integer
#  text       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class KpisSegment < ActiveRecord::Base
  belongs_to :kpi
  attr_accessible :text
end
