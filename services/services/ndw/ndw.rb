##############################################################################################################
## Nationale Databank Wegverkeer #############################################################################
##############################################################################################################  

class CitySDK_Services < Sinatra::Base

  post '/ndw' do    
    json = self.parse_request_json    
    wvk_id = json["wvk_id"]
    
    # TODO: naming convention!
    key = "ndw!!!#{id}"
    data = CitySDK_Services.memcache_get(key)
    
    if data
      json = json.merge(data) 
    end    
        
    return { 
      :status => 'success', 
      :url => request.url, 
      :data => json
    }.to_json 
  end
    
end