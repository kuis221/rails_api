class Legacy::DataMigration < ActiveRecord::Base
  belongs_to :company

  belongs_to :local, polymorphic: true, autosave: true
  belongs_to :remote, polymorphic: true, autosave: true

  accepts_nested_attributes_for :local

  validates :company_id, presence: true, numericality: true

  validates :remote_id, presence: true, numericality: true
  validates :remote_type, presence: true

  #validates :local_id, presence: true, numericality: true
  validates :local_type, presence: true

  scope :for_metric, lambda{|metric| where(remote_type: 'Metric', remote_id: metric.id)}

  delegate :campaign_name, :start_at, :end_at, :place_name, :place_id, to: :local
  delegate :account_name, :account_id, to: :remote

  scope :different_zipcode, lambda{ |value|
    joins('INNER JOIN legacy_accounts la1 ON la1.id=remote_id AND remote_type=\'Legacy::Account\'
           INNER JOIN places p1 ON p1.id=local_id AND local_type=\'Place\'
           LEFT JOIN legacy_addresses ld1 ON la1.id=ld1.addressable_id AND ld1.addressable_type=\'Account\'').
    where('ld1.postal_code::varchar(255) <> p1.zipcode')
  }

  search_methods :different_zipcode if respond_to?(:search_methods)
end