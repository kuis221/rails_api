# == Schema Information
#
# Table name: neighborhoods
#
#  gid      :integer          not null, primary key
#  state    :string(2)
#  county   :string(43)
#  city     :string(64)
#  name     :string(64)
#  regionid :decimal(, )
#  geog     :spatial          multipolygon, 4326
#

class Neighborhood < ActiveRecord::Base
  # This is how shp2pgsql generates the table
  self.primary_key = 'gid'

  # # By default, use the GEOS implementation for spatial columns.
  # self.rgeo_factory_generator = RGeo::Geos.factory_generator

  # # But use a geographic implementation for the :lonlat column.
  # set_rgeo_factory_for_column(:geog, RGeo::Geographic.spherical_factory(:srid => 4326))
end
