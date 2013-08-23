# == Schema Information
#
# Table name: metrics
#
#  id          :integer          not null, primary key
#  type        :string(32)
#  brand_id    :integer
#  program_id  :integer
#  name        :string(255)
#  style       :string(255)
#  optional_id :integer
#  active      :boolean          default(TRUE)
#  creator_id  :integer
#  updater_id  :integer
#  created_at  :datetime
#  updated_at  :datetime
#


class Metric < Legacy::Record
  belongs_to    :program

  has_many :metric_results

  scope :system, lambda {where(:program_id => nil, :brand_id => nil)}

  def result_hash(result)
    {name => cast_value(result.value)}
  end

  # convert keys in hash to int to keep things matching up - but preserve values
  # TODO dry vs metrics_helper.rb
  def self.scrub_hash_keys(hash)
    (hash || {}).inject({}) { |h, (k, v)| h[k.to_i] = v; h}
  end
end