RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
  # By default, use the GEOS implementation for spatial columns.
  config.default = RGeo::Geographic.spherical_factory(srid: 4326)

  # # But use a geographic implementation for point columns.
  # config.register(RGeo::Geographic.spherical_factory(srid: 4326), geo_type: 'point')
  # config.register(RGeo::Geographic.spherical_factory(srid: 4326), geo_type: 'multi_polygon')
end
