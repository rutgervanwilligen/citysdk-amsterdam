##############################################################################################################
## DIVV Traffic Flow (dummy)##################################################################################
##############################################################################################################

class CitySDK_Services < Sinatra::Base
 
  post '/divv_tf' do
    # dummy; added for consistent implemtation of rt services.
    # values are always retrieved from memcache, so this 
    # webservice endpoint should never be called.
    json = self.parse_request_json
    return { :status => 'success', 
      :url => request.url, 
      :data => json
    }.to_json 
  end

end