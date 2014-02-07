#############################################################################################################
## Parking garage capacity ##################################################################################
#############################################################################################################

class CitySDK_Services < Sinatra::Base
 
  PARKING_HOST = "http://www.trafficlink-online.nl"
  PARKING_PATH = "/trafficlinkdata/wegdata/IDPA_ParkingLocation.GeoJSON"
  PARKING_TIMEOUT = 5 * 60
  
  PARKING_MAPPING = JSON.parse(File.open(File.dirname(__FILE__) + '/mapping.json','r').read)
  
  # curl --data '{"postcode":"1103DS"}' http://localhost:9292/parking  
  post '/parking' do
  
    # Read data from request 
    json = self.parse_request_json
    postcode = json["postcode"]
    
    # TODO: naming convention!
    key = "parking!!!#{postcode}"
    data = CitySDK_Services.memcache_get(key)
    if not data
    
      connection = Faraday.new PARKING_HOST    
      response = httpget(connection, PARKING_PATH)
      if response.status == 200
        # Current version of parking JSON is invalid:
        # "key"="value" instead of "key": "value"
        garages = JSON.parse response.body.gsub(/\"=\"/, '": "')
                
        garages["features"].each do |garage|
          name = garage["properties"]["Name"]
          
          data = {}
          if PARKING_MAPPING.has_key? name
            garage_postcode = PARKING_MAPPING[name]
            garage_key = "parking!!!#{garage_postcode}"
            
            # TODO: get timeout from layer data
            CitySDK_Services.memcache_set(garage_key, garage["properties"], PARKING_TIMEOUT)
          end          
        end
      end
      
      # If requested CitySDK node does not exist in parking API/mapping
      # Set key to empty hash, to prevent fetching URL next time again
      data = CitySDK_Services.memcache_get(key)
      if not data
        CitySDK_Services.memcache_set(key, {}, PARKING_TIMEOUT)
        data = {}
      end      
    
    end
    
    json["capacity"] = data
    
    return { 
      :status => 'success', 
      :url => request.url, 
      :data => json
    }.to_json 

  end
end 