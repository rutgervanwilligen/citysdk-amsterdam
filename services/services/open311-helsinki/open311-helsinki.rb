##############################################################################################################
## Helsinki Open311 ##########################################################################################
##############################################################################################################

class CitySDK_Services < Sinatra::Base

  Helsinki311_URL = "https://asiointi.hel.fi"
  Helsinki311_PATH = "/palautews/rest/v1/requests.json?service_request_id="
  
  post '/311.helsinki' do
    json = self.parse_request_json
    
    connection = Faraday.new(:url => Helsinki311_URL, :ssl => {:verify => false, :version => 'SSLv3'}) do |c|
      c.use Faraday::Request::UrlEncoded
      c.use Faraday::Adapter::NetHttp
    end
  
    resp = httpget(connection, Helsinki311_PATH + json['service_request_id'])
    data = JSON.parse(resp.body)
    
    @json = data[0] if resp.status == 200
    return { :status => 'success', 
      :url => request.url, 
      :data => json
    }.to_json 
  end
    
end