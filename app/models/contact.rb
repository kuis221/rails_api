# == Schema Information
#
# Table name: contacts
#
#  id           :integer          not null, primary key
#  company_id   :integer
#  first_name   :string(255)
#  last_name    :string(255)
#  title        :string(255)
#  email        :string(255)
#  phone_number :string(255)
#  street1      :string(255)
#  street2      :string(255)
#  country      :string(255)
#  state        :string(255)
#  city         :string(255)
#  zip_code     :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Contact < ActiveRecord::Base

  scoped_to_company

  has_many :contact_events, dependent: :destroy, as: :contactable

  validates :first_name, presence: true
  validates :last_name, presence: true

  def full_name
    [first_name, last_name].join ' '
  end

  def country_name
    Country.new(country).name rescue nil unless country.nil?
  end
end
