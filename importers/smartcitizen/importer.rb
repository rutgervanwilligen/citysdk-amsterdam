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
devices = JSON.parse(File.read('devices.json'))

api = CitySDK::API.new("api.citysdk.waag.org")
api.authenticate(email, passw)
api.set_layer layer

begin
  devices.each do |device|
    response = Faraday.get SCK_URL + SCK_PATH + "#{device["id"]}/posts.json"
    
    api_device = JSON.parse(response.body)["device"]

    node = {}
    if device.has_key? "cdk_id"
      node = {
        cdk_id: device["cdk_id"],        
        data: {
          sensorid: api_device["id"].to_i
        }
      }
    else    
      node = {
        id: api_device["id"],
        name: api_device["title"],
        geom: {
          type: "Point",
          coordinates: [
            api_device["geo_long"].to_f,
            api_device["geo_lat"].to_f
          ]
        },
        data: {
          sensorid: api_device["id"].to_i
        }
      }
    end
    puts "creating node for sensor #{device["id"]}: \"#{device["title"]}\""
    api.delete "/#{layer}.#{device["id"]}/#{layer}"    
    api.create_node node
  end
ensure
	api.release
end

puts "done..."