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
  validates :country, presence: true,
                      inclusion: { in: proc { Country.all.map { |c| c[1] } }, message: 'is not valid' }
  validates :state,   presence: true,
                      inclusion: { in: proc { |event| Country[event.country].states.keys rescue [] }, message: 'is not valid' }
  validates :city,    presence: true

  validates_format_of :email, with: /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, allow_blank: true, if: :email_changed?

  before_validation do
    self.country ||= 'US'
  end

  searchable do
    integer :id
    integer :company_id
    text :name, stored: true do
      full_name
    end
    string :name do
      full_name
    end
    string :status do
      'Active'
    end
  end

  def full_name
    [first_name, last_name].join(' ').strip
  end

  def country_name
    Country.new(country).name rescue nil unless country.nil?
  end

  def street_address
    [street1, street2].reject { |v| v.nil? || v == '' }.join(', ')
  end
end
