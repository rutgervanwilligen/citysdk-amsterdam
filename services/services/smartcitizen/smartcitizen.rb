#############################################################################################################
## SmartCitizen sensors #####################################################################################
#############################################################################################################

class CitySDK_Services < Sinatra::Base

  SCK_KEY = JSON.parse(File.read('/var/www/citysdk/shared/config/sck.json').force_encoding('utf-8'))['key'] 
  SCK_URL = "http://api.smartcitizen.me"
  SCK_PATH = "/v0.0.1/#{SCK_KEY}/"
  
  # curl --data '{"sensorid":"567"}' http://services.citysdk.waag.org/sck  
  post '/sck' do
    json = self.parse_request_json
    
    connection = Faraday.new(:url => SCK_URL) do |c|
      c.use Faraday::Request::UrlEncoded
      c.use Faraday::Adapter::NetHttp
    end
    
    resp = httpget(connection, SCK_PATH + "#{json['sensorid']}/posts.json")
    if resp.status == 200
      h = JSON.parse(resp.body)
      json['update'] = h['device']['posts'][0]['insert_datetime']
      json['battery'] = h['device']['posts'][0]['bat'].to_s # + "%"
      json['light'] = h['device']['posts'][0]['light'].to_s # + "%"
      json['temperature'] = h['device']['posts'][0]['temp'].to_s # + "℃"
      json['humidity'] = h['device']['posts'][0]['hum'].to_s # + "%"
      json['noise'] = h['device']['posts'][0]['noise'].to_s # + "dB"
      json['co'] = h['device']['posts'][0]['co'].to_s # + "㏀"
      json['no2'] = h['device']['posts'][0]['no2'].to_s # + "㏀"
    end
    
    return { 
      :status => 'success', 
      :url => request.url, 
      :data => json
    }.to_json 
  end
    
end