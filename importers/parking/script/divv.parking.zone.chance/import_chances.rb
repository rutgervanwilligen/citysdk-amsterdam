require 'citysdk'
require 'csv'

#import zone chances from csv file
#mapping was manually done as follows:
#centrum: T13C, T13B, T13B, T13B
#woongebieden: T11A, T12A, T12B, T12B

layer = 'divv.parking.zone.chance'

#1. parse zones from file
data_centrum = File.open './data/centrum.geojson', 'r:UTF-8'
zones_centrum_raw = JSON.parse data_centrum.read

data_woon = File.open './data/woon.geojson', 'r:UTF-8'
zones_woon_raw = JSON.parse data_woon.read

#2. parse chance data for centrum and woon
csv_text = File.read('./data/bez.csv')
csv = CSV.parse csv_text, :headers => true, :col_sep => ";"

centrum_data = {}
woon_data = {}

csv.each do | row |
	day = row["dag"]
	hour = row["uur van de dag"]
	grade = row["bezettingsgraad"]

	if(row["gebied"] == "woongebieden")
		if (! woon_data.has_key? day) 
			woon_data[day] = "" 
		end
		woon_data[day] = "#{woon_data[day]}#{hour}:#{grade};"

	elsif(row["gebied"] == "centrumgebied")
		if (! centrum_data.has_key? day) 
			centrum_data[day] = ""
		end
		centrum_data[day] = "#{centrum_data[day]}#{hour}:#{grade};"
	end	
end

#get existing zones from citysdk
begin
	api = CitySDK::API.new('api.citysdk.waag.org')
	exit if not api.authenticate('user@waag.org','PASSWORD')
	
	#create test layer
	begin
		api.put('/layers',{:data => {
		:name => layer,
		:description => 'Historical capacity information for street parking zones',
		:organization => 'DIVV Amsterdam',
		:category => 'mobility.parking'
		}})
	rescue CitySDK::HostException => e
		#import parsed data
		puts e.message
	end
	
	response = api.get('/nodes?layer=test.divv.parking.zone&geom&per_page=100')
	zones = response[:results]

	zones.each do |zone|
		code = zone[:layers][:"test.divv.parking.zone"][:data][:code]
		cdk_id = zone[:cdk_id]
		n = cdk_id[23..-1].to_i
		
		case n
			when 2, 3, 4, 15
				data = {
					:data => centrum_data
				}
				#puts data.inspect
				api.put("#{zone[:cdk_id]}/#{layer}", data)
			when 6, 18, 7, 5, 10
				data = 
				{
					:data => woon_data
				}
				#puts data.inspect
				api.put("#{zone[:cdk_id]}/#{layer}", data)
		end
	end	
ensure
	#always release api, no matter what happens
	api.release
end

