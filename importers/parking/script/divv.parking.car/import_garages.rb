#import garages
require 'citysdk'

layer = 'divv.parking.car'

#1. parse the input garage locations from file using json
data = File.open './data/locaties3juni2013.json', 'r:UTF-8'
locations_raw = JSON.parse data.read

#process raw data make it useful for citysdk
cdk_id = 0 #generate ID, postcode is not precise enough

locations = Array.new
locations_raw["parkeerlocaties"].each do | location_raw |
	
	cdk_id += 1	
	ltype = location_raw["parkeerlocatie"]["type"]
	
	if(ltype == "Parkeergarage" || ltype == "P+R")
		title = location_raw["parkeerlocatie"]["title"]
		url = location_raw["parkeerlocatie"]["url"]
		url_title = location_raw["parkeerlocatie"]["urltitle"]
		address = location_raw["parkeerlocatie"]["adres"]
		pc = location_raw["parkeerlocatie"]["postcode"]
		city = location_raw["parkeerlocatie"]["woonplaats"]
		geometry = JSON.parse location_raw["parkeerlocatie"]["Locatie"]

		locations << {
			:id => "#{cdk_id}",
			:name => title,
			:geom => geometry,
			:modalities => ["car"],
			:data =>
			{
				:type => ltype,
				:address => address,
				:postcode => pc,
				:info_url => url,
				:info_title =>url_title,
			}
		}.delete_if {|k,v| v.nil? }

	end	      
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
		:description => 'Car parking garages and P+R locations',
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
	locations.each do |location|
		begin
			api.create_node location
		rescue Exception => e
			puts e
			puts location
		end
	end

ensure
	#always release api, no matter what happens
	api.release
end
