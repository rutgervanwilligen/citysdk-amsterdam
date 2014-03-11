#import zones from geojson
require 'citysdk'

layer = 'divv.parking.zone'

#1. parse the input zones from file using json
data = File.open './data/parkeerzones.geojson', 'r:UTF-8'
zones_raw = JSON.parse data.read

#process raw data make it useful for citysdk
zones = zones_raw["features"].map do | zone_raw |
	{
		:id => "#{zone_raw["id"]}",
		:name => "zone #{zone_raw["id"]}",
		:geom => zone_raw["geometry"],
		:modalities => ["car"],
		:data =>
		{
			:code => zone_raw["properties"]["GEBIED_COD"],
			:date => zone_raw["properties"]["B_DAT_GEBI"]
		}
	}
end

#2. put stuff in citysdk
begin
	#authenticate with test API
	api = CitySDK::API.new('api.citysdk.waag.org')
	exit if not api.authenticate('user@waag.org','PASSWORD')

	#create test layer
	begin
		api.put('/layers',{:data => {
		:name => layer,
		:description => 'Street parking zone locations',
		:organization => 'DIVV Amsterdam',
		:category => 'mobility.parking'
		}})
	rescue CitySDK::HostException => e
		#import parsed data
		puts e.message
	end

	#add parsed data to layer
	#dit is dus belangrijk!
	api.set_layer layer
	zones.each do |zone|
		#puts zone
		api.create_node zone
	end

ensure
	#always release api, no matter what happens
	api.release
end
