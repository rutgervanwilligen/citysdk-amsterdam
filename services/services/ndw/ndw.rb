##############################################################################################################
## Nationale Databank Wegverkeer #############################################################################
##############################################################################################################  

class CitySDK_Services < Sinatra::Base

  post '/ndw' do    
    json = self.parse_request_json
        
    return { 
      :status => 'success', 
      :url => request.url, 
      :data => {
        test: true
      }
    }.to_json 
  end
    
end