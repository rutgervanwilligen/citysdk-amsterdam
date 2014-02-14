#import zone prices from xml file
require 'citysdk'
require 'xmlsimple'

#get area from area table
def getArea id
	$areas.each do |area|
		aid = area["AreaId"][0]
		if(aid == id)
			return area
		end

	end
	return nil
end

#get regulation from regulation table
def getRegulation id 
	$regulation_data.each do |regulation|
		rid = regulation["RegulationId"]
		if(rid == id)
			return regulation
		end
	end
	return nil

end

#get fare from fare table
def getFare id
	$fare_data.each do |fare|
		fid = fare["FareCalculationCode"]
		if(fid == id)
			return fare
		end
	end
	return nil
end

def dow_to_int string

	dow = ['ZONDAG','MAANDAG','DINSDAG','WOENSDAG','DONDERDAG','VRIJDAG','ZATERDAG']
	hash = Hash[dow.map.with_index.to_a]
	return hash[string]

end

#process a list of zones
def process_price_for_zones zones, zone_layer_name

	zones.each do | zone |
		match_id = zone[:layers][zone_layer_name][:data][:code]
		area = getArea match_id
		next if not area

		price_per_hour = area["PriceOneHourParking"][0] rescue "0"
		data = {
			:data => 
			{
					"description" => area["AreaDesc"][0],
					"price_per_hour" => price_per_hour,
					"grace_period_before" => area["GracePeriodBefore"][0],
					"grace_period_after" => area["GracePeriodAfter"][0]
			}	
		}

		#generate regulation id for this zone
		regNr = 0
		fare_string = ""
		
		area["AreaRegulationTable"][0]["AreaRegulationData"].each do | reg |
			regId = reg["RegulationIdArea"]
			regulation = getRegulation regId
				
			time_frames = regulation["TimeFrameTable"][0]["TimeFrameData"]
			time_frames.each do | timeframe |
				fid = timeframe["FareTimeFrame"]
				if(fid)
					tf_day = dow_to_int timeframe["DayTimeFrame"][0]
					tf_start = timeframe["StartTimeTimeFrame"][0]
					tf_end = timeframe["EndTimeTimeFrame"][0]

					fare = getFare fid
					fare_data = fare["FarePartTable"][0]["FarePartData"]
					fare_data.each do |part|
						f_start = part["StartDurationFarePart"][0]
						f_end = part["EndDurationFarePart"][0]
						f_step = part["StepSizeFarePart"][0]
						f_amount = part["AmountFarePart"][0]

						fare_string += "#{tf_day} #{tf_start} #{tf_end} #{f_start} #{f_end} #{f_step} #{f_amount}|"
					end

				end
			end
 
		end
		data[:data]["fare"] = fare_string.chop!
		#puts "#{zone[:cdk_id]}/#{$layer}"
		#puts data
		
		$api.delete("#{zone[:cdk_id]}/#{$layer}")
		$api.put("#{zone[:cdk_id]}/#{$layer}", data)
	end
end
				
$layer = 'divv.parking.zone.price'

#1. parse the input prices from file using xml
data_raw = XmlSimple.xml_in './data/20120611_363_RetrieveAreaRegulationFareInfo.xml'

$areas = data_raw["Body"][0]["RetrieveAreaRegulationFareInfoResponse"][0]["AreaRegulationFareInfoResponseData"][0]["AreaTable"][0]["AreaData"]
$regulation_data = data_raw["Body"][0]["RetrieveAreaRegulationFareInfoResponse"][0]["AreaRegulationFareInfoResponseData"][0]["RegulationTable"][0]["RegulationData"]
$fare_data = data_raw["Body"][0]["RetrieveAreaRegulationFareInfoResponse"][0]["AreaRegulationFareInfoResponseData"][0]["FareTable"][0]["FareData"]


#get existing zones from citysdk
begin
	$api = CitySDK::API.new('api.citysdk.waag.org')
	exit if not $api.authenticate('user@waag.org','PASSWORD')
	
	#create test layer
	begin
		$api.put('/layers',{:data => {
		:name => $layer,
		:description => 'Price information for street parking.',
		:organization => 'DIVV Amsterdam',
		:category => 'mobility.parking'
		}})
	rescue CitySDK::HostException => e
		#import parsed data
		puts e.message
	end
	
	response = $api.get('/nodes?layer=divv.parking.zone&per_page=100')
	zones = response[:results]
	
	response = $api.get('/nodes?layer=divv.parking.zone.exception&per_page=100')
	exceptions = response[:results]
	
	process_price_for_zones zones, :"divv.parking.zone"
	process_price_for_zones exceptions, :"divv.parking.zone.exception"

ensure
	#always release api, no matter what happens
	$api.release
end
