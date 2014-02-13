require 'citysdk'

credentials = '/var/www/citysdk/shared/config/cdkpw.json'
pw = File.exists?(credentials) ? JSON.parse(File.read(credentials)) : nil

email = ARGV[0] || (pw ? pw['email'] : nil) || 'citysdk@waag.org'
passw = ARGV[1] || (pw ? pw[email]  : nil) || ''
host  = ARGV[2] || (pw ? pw['host']  : nil) || 'api.dev'

PARKING_HOST = "http://www.trafficlink-online.nl"
PARKING_PATH = "/trafficlinkdata/wegdata/IDPA_ParkingLocation.GeoJSON"

layer = "divv.parking.capacity"

api = CitySDK::API.new("api.citysdk.waag.org")
api.authenticate(email, passw)
api.set_layer layer

begin
  response = Faraday.get PARKING_HOST + PARKING_PATH
  garages = JSON.parse response.body
  garages["features"].each do |garage|
    id = garage["Id"]
    geom = garage["geometry"]    
    name = garage["properties"]["Name"]

    node = {
      id: id,
      name: name,
      geom: geom,
      data: {
        id: id
      }
    }    

    puts "Creating node for parking garage \"#{name}\""
    api.create_node node
  end
ensure
	api.release
end

puts "done..."