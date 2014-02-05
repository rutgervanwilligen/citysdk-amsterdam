##############################################################################################################
## Oplaadpalen.nl ############################################################################################
##############################################################################################################  

class CitySDK_Services < Sinatra::Base
    
  OPLAADPALEN_KEY = JSON.parse(File.read('/var/www/citysdk/shared/config/oplaadpalen_key.json'))["key"]
  OPLAADPALEN_HOST = "http://oplaadpalen.nl"
  OPLAADPALEN_PATH = "/api/availability/#{OPLAADPALEN_KEY}/json"
  
  post '/oplaadpalen' do
    json = self.parse_request_json
          
    if json["realtimestatus"] == "true"
      id = json["id"]
            
      # TODO: naming convention!
      key = "oplaadpalen!!!#{id}"      
      data = CitySDK_Services.memcache_get(key)
      if data
        json["availability"] = data
      else
        # Download availability data from oplaadpunten.nl
        connection = Faraday.new OPLAADPALEN_HOST    
        response = httpget(connection, OPLAADPALEN_PATH)
        if response.status == 200
          availability = JSON.parse response.body          
          availability.each { |data|
            _id = data["id"]
            data.delete("id")
            
            # Convert strings to integers:
            data = Hash[data.map{|k,str| [k, str.to_i] } ]
            
            if _id == id
              json["availability"] = data
            end          
            key = "oplaadpalen!!!#{_id}" 
            # TODO: get timeout from layer data
            CitySDK_Services.memcache_set(key, data, 5 * 60 )
          }        
        end
      end      
    end
    
    json["cards"] = JSON.parse json["cards"]
    json["facilities"] = JSON.parse json["facilities"]
    
    json["price"] = json["price"].to_f
    json["nroutlets"] = json["nroutlets"].to_i
    json["realtimestatus"] = (json["realtimestatus"] == "true")
    json["id"] = json["id"].to_i
        
    json.select! { |k,v| v != '' } 
      
    return { :status => 'success', 
      :url => request.url, 
      :data => json
    }.to_json 
  end  
    
end