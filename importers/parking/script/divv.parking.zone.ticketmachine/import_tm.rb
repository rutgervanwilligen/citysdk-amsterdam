#import ticket machines from geojson
require 'citysdk'

layer = 'divv.parking.zone.ticketmachine'

#1. parse the input zones from file using json
data = File.open './data/automaten.geojson', 'r:UTF-8'
tm_raw = JSON.parse data.read

#process raw data make it useful for citysdk
tms = tm_raw["features"].map do | tm |
	{
		:id => "#{tm["properties"]["VERKOOP_PU"]}",
		:name => "ticketmachine #{tm["properties"]["VERKOOP_PU"]}",
		:geom => tm["geometry"],
		:modalities => ["car"],
		:data =>
		{
			:description => tm["properties"]["OMS"],
			:rotation => tm["properties"]["GMRotation"],
			:date => tm["properties"]["B_DAT_VERK"]
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
		:description => 'street parking ticketmachine locations and details',
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
	tms.each do |tm|
		#puts zone
		api.create_node tm
	end

ensure
	#always release api, no matter what happens
	api.release
end

#to get ticket machines for zone use for example:
#http://test-api.citysdk.waag.org/test.divv.parking.zone.17/nodes?layer=test.divv.parking.zone.ticketmachine
