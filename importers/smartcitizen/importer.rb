require 'citysdk'

credentials = '/var/www/citysdk/shared/config/cdkpw.json'
pw = File.exists?(credentials) ? JSON.parse(File.read(credentials)) : nil

SCK_KEY = JSON.parse(File.read('/var/www/citysdk/shared/config/sck.json').force_encoding('utf-8'))['key'] 
SCK_URL = "http://api.smartcitizen.me"
SCK_PATH = "/v0.0.1/#{SCK_KEY}/"

email = ARGV[0] || (pw ? pw['email'] : nil) || 'citysdk@waag.org'
passw = ARGV[1] || (pw ? pw[email]  : nil) || ''
host  = ARGV[2] || (pw ? pw['host']  : nil) || 'api.dev'

layer = "sck"
sensors = JSON.parse(File.read('sensors.json'))

api = CitySDK::API.new("api.citysdk.waag.org")
api.authenticate(email, passw)
api.set_layer layer

begin
  sensors.each do |sensor_id|
    response = Faraday.get SCK_URL + SCK_PATH + "#{sensor_id}/posts.json"
    device = JSON.parse(response.body)["device"]  
    node = {
      id: device["id"],
      name: device["title"],
      geom: {
        type: "Point",
        coordinates: [
          device["geo_long"].to_f,
          device["geo_lat"].to_f
        ]
      },
      data: {
        sensorid: device["id"].to_i
      }
    }
    puts "creating node for sensor #{device["id"]}: \"#{device["title"]}\""
    puts api.delete "/#{layer}.#{device["id"]}/#{layer}"    
    api.create_node node
  end
ensure
	api.release
end

puts "done..."