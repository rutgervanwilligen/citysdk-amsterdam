##############################################################################################################
## Buienradar ################################################################################################
##############################################################################################################

class CitySDK_Services < Sinatra::Base
    
  # http://gps.buienradar.nl/getrr.php?lat=52.3715975723131&lon=4.89971325769402
  BR_URL = "http://gps.buienradar.nl" 
  BR_PATH = "/getrr.php?"
  
  # curl --data '{"centroid:lat":"52.3715975723131", "centroid:lon":"4.89971325769402"}' http://localhost:3000/rain  
  post '/rain' do  
    json = self.parse_request_json
  
    lat = json["centroid:lat"]
    lon = json["centroid:lon"]
  
    connection = Faraday.new :url => BR_URL
    response = self.httpget(connection, BR_PATH + "lat=#{lat}&lon=#{lon}")
    data = {:centroid => {:lat => lat, :lon => lon}, :rain => {}}
  
    if response.status == 200
      response.body.split(' ').each do |d|
        value, time = d.split('|')
        value = value.to_i
        data[:rain][time] = value
      end
      return { 
        :status => 'success', 
        :url => request.url, 
        :data => data
      }.to_json 
    else
      self.do_abort(response.status, {result: "fail", error: "Error requesting resource", message: exception.message})
    end
  end

end