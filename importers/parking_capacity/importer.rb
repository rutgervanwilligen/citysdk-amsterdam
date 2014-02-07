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
api.set_createTemplate({
  create: {
    params: {
      srid: 28992,
      create_type: "create"
    }
  } 
})

begin
  response = Faraday.get PARKING_HOST + PARKING_PATH
  # Current version of parking JSON is invalid:
  # "key"="value" instead of "key": "value"
  garages = JSON.parse response.body #.gsub(/\"=\"/, '": "')
  garages["features"].each do |garage|

    puts garage.inspect
    # node = {
    #   id: device["id"],
    #   name: device["title"],
    #   geom: {
    #     type: "Point",
    #     coordinates: [
    #       device["geo_long"].to_f,
    #       device["geo_lat"].to_f
    #     ]
    #   },
    #   data: {
    #     sensorid: device["id"].to_i
    #   }
    # }
    puts "creating node for sensor #{device["id"]}: \"#{device["title"]}\""
    #api.create_node node
  end
ensure
	api.release
end

puts "done..."