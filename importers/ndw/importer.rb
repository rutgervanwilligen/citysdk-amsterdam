# NDW importer

require 'sequel'
require 'json'
require 'citysdk'

credentials = '/var/www/citysdk/shared/config/cdkpw.json'
pw = File.exists?(credentials) ? JSON.parse(File.read(credentials)) : nil

email = ARGV[0] || (pw ? pw['email'] : nil) || 'citysdk@waag.org'
passw = ARGV[1] || (pw ? pw[email]  : nil) || ''
host  = ARGV[2] || (pw ? pw['host']  : nil) || 'api.dev'

layer = "ndw"

api = CitySDK::API.new("api.citysdk.waag.org")
api.authenticate(email, passw)
api.set_layer layer

DB = Sequel.connect("postgres://postgres:postgres@localhost/ndw")

i = 0

query = <<-SQL
  SELECT DISTINCT
    wvk_id
  FROM 
    mst_wvk;
SQL

begin
  DB[query].each do |row|
    # Convert BigDecimal to int
    wvk_id = row[:wvk_id].to_i
    
    node = {
      cdk_id: "nwb.#{wvk_id}",
      data: {
        wvk_id: wvk_id
      }
    }
    api.create_node node
    
    i += 1
    puts "Imported #{i} rows" if i % 1000 == 0     
  end
ensure
	api.release
end

puts "done..."