##############################################################################################################
## Nationale Databank Wegverkeer #############################################################################
##############################################################################################################  

class CitySDK_Services < Sinatra::Base

  post '/ndw' do    
    json = self.parse_request_json    
    wvk_id = json["wvk_id"]
    
    # TODO: naming convention!
    key = "ndw!!!#{wvk_id}"
    data = CitySDK_Services.memcache_get(key)
    
    if data
      json[:msts] = data.values
    end    
        
    return { 
      :status => 'success', 
      :url => request.url, 
      :data => json
    }.to_json 
  end
    
end