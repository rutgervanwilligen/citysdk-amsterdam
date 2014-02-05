# NWB importer

require 'sequel'
require 'json'
require 'citysdk'

credentials = '/var/www/citysdk/shared/config/cdkpw.json'
pw = File.exists?(credentials) ? JSON.parse(File.read(credentials)) : nil

email = ARGV[0] || (pw ? pw['email'] : nil) || 'citysdk@waag.org'
passw = ARGV[1] || (pw ? pw[email]  : nil) || ''
host  = ARGV[2] || (pw ? pw['host']  : nil) || 'api.dev'

layer = "nwb"

api = CitySDK::API.new("api.citysdk.waag.org")
api.authenticate(email, passw)
api.set_layer layer

DB = Sequel.connect("postgres://postgres:postgres@localhost/citysdk-ndw")

# TODO: add more columns - house letters, etc.
columns = [
  :wvk_id,
  :stt_naam,
  :gme_id,
  :beginkm,
  :eindkm,
  :rijrichtng,
  :wegnummer,
  :wegdeelltr,
  :hecto_lttr,
  :baansubsrt
]

i = 0

query = <<SQL
  SELECT
    #{columns.map{ |c| c.to_s }.join(",")},
    -- Convert MultiLineStrings to LineStrings
    ST_AsGeoJSON(ST_CollectionHomogenize(geom)) AS geom
  FROM 
    wegvakken;
SQL

begin
  DB[query].each do |row|
    # Convert BigDecimal to int
    row[:wvk_id] = row[:wvk_id].to_i
    
    node = {
      id: row[:wvk_id].to_i,
      name: row[:stt_naam],
      geom: JSON.parse(row[:geom]),
      data: Hash[columns.map{|c| [c, row[c]] if row[c] }]
    }
    api.create_node node
    
    i += 1
    puts "Imported #{i} rows" if i % 1000 == 0     
  end
ensure
	api.release
end

puts "done..."