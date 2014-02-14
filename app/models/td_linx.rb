# == Schema Information
#
# Table name: td_linxes
#
#  id                     :integer          not null, primary key
#  store_code             :string(255)
#  retailer_dba_name      :string(255)
#  retailer_address       :string(255)
#  retailer_city          :string(255)
#  retailer_state         :string(255)
#  retailer_trade_channel :string(255)
#  license_type           :string(255)
#  fixed_address          :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class TdLinx < ActiveRecord::Base
  attr_accessible :license_type, :retailer_address, :retailer_city, :retailer_dba_name, :retailer_state, :retailer_trade_channel, :store_code, :fixed_address
end
