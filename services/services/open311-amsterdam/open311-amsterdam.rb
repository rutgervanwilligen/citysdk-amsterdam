##############################################################################################################
## Amsterdam Open311 #########################################################################################
##############################################################################################################  

class CitySDK_Services < Sinatra::Base
     
  Amsterdam311_URL = "http://open311.dataplatform.nl"
  Amsterdam311_PATH = "/opentunnel/open311/v21/requests.xml?jurisdiction_id=0363&api_key=" + JSON.parse(File.read('/var/www/citysdk/shared/config/adam311.json'))['key'] + "&service_request_id="
  post '/311.amsterdam' do
    json = self.parse_request_json
    
    connection = Faraday.new(:url => Amsterdam311_URL) do |c|
      c.use Faraday::Request::UrlEncoded
      c.use Faraday::Adapter::NetHttp
    end
  
    resp = httpget(connection, Amsterdam311_PATH + json['service_request_id'])
    if resp.status == 200
      json = Hash.from_xml(resp.body)['service_requests']['request']
    end
    
    return { 
      :status => 'success', 
      :url => request.url, 
      :data => json
    }.to_json 
  end
    
end