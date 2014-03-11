#import parking garage and P+R prices
require 'citysdk'
require 'csv'

#helper function for parsing and formatting opening_times
def get_time row 
	times = JSON.parse "{ #{row["opening_times"]} }"
	default = times["opening_times"]["default"] rescue nil
	if default 
		time_string = ""
		default.each do |tt|
			time_string += "#{tt["days"]} #{tt["open_in"]} #{tt["open_out"]} #{tt["close_in"]} #{tt["close_out"]}|"	
		end
		return time_string.chop!
	end
	return nil
end

layer = 'divv.parking.car.price'

#Naam,Type,URL,Beheerder,Adres,Postcode,Plaats,Aantal plaatsen,Latitude,Longitude,Bijzondere openingstijden,Opening Inrijden,Sluiting Inrijden,Opening Uitrijden,Sluiting Uitrijden,Dagprijs,Inclusief OV,PrijsPerTijdseenheid,Tijdeenheid (min),Gratis minuten,Opmerkingen
csv_text = File.read('./data/price3.csv')
csv = CSV.parse csv_text, :headers => true, :col_sep => ';', :quote_char => '"'

#get existing garages from citysdk
#get existing zones from citysdk
begin
	api = CitySDK::API.new('api.citysdk.waag.org')
	exit if not api.authenticate('user@waag.org','PASSWORD')
	
	#create test layer
	begin
		api.put('/layers',{:data => {
		:name => layer,
		:description => 'Prices for parking garages and P+R',
		:organization => 'DIVV Amsterdam',
		:category => 'mobility.parking'
		}})
	rescue CitySDK::HostException => e
		#import parsed data
		puts e.message
	end
	
	response = api.get('/nodes?layer=divv.parking.car&per_page=100')
	locations = response[:results]
	
	#match on name and address
	locations.each do |location|
		cdk_id = location[:cdk_id]
		address = location[:layers][:"divv.parking.car"][:data][:address]
		title = location[:name].gsub('&#039;','\'')
	
		match = false	
		csv.each do |row|
			if(row["Naam"] == title && (address == '' || row["Adres"] == address ))
				#create and put data
				time_string =  get_time row

				data = {
					:data => 
					{
						:owner => row["Beheerder"],
						:capacity => row["Aantal plaatsen"],
						:opening_times => time_string,
						:price_day => row["Dagprijs"],
						:includes_public_transport => row["Inclusief OV"],
						:price_per_time_unit => row["PrijsPerTijdseenheid"],
						:time_unit_minutes => row["Tijdeenheid (min)"],
						:free_minutes => row["Gratis minuten"],
						:remarks => row["Opmerkingen"]
					}.delete_if {|k,v| v.nil? }
				}

				#puts data.inspect
				api.delete("#{cdk_id}/#{layer}")
				api.put("#{cdk_id}/#{layer}", data)

			end
		end
	end	
ensure
	#always release api, no matter what happens
	api.release
end

