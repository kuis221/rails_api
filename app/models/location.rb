# == Schema Information
#
# Table name: locations
#
#  id   :integer          not null, primary key
#  path :string(500)
#

class Location < ActiveRecord::Base
  has_and_belongs_to_many :places

  def self.load_by_paths(paths)
    paths.map { |path| Location.find_or_create_by(path: path) }
  rescue PG::UniqueViolation
    sleep 1
    retry
  end
end
