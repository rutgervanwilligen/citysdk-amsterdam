# Administrative regions importer

require 'citysdk'
include CitySDK

credentials = '/var/www/citysdk/shared/config/cdkpw.json'
pw = File.exists?(credentials) ? JSON.parse(File.read(credentials)) : nil

email = ARGV[0] || (pw ? pw['email'] : nil) || 'citysdk@waag.org'
passw = ARGV[1] || (pw ? pw[email]  : nil) || ''
host  = ARGV[2] || (pw ? pw['host']  : nil) || 'api.dev'

layer = 'admr'

# National border
imp = Importer.new({
  :file_path => 'landsgrens.zip', 
  :name => 'landsnaam',
  :layername => layer, 
  :create_type => 'create', 
  :srid => "28992",  # Dutch RD system
  :host => host,
  :email => email, 
  :passw => passw
})
          
imp.doImport() do |d|
  d[:id] = 'nederland'
  d[:data][:admn_level] = 0
end


# Provinces
imp = Importer.new({
      :file_path=> 'provincies.zip', 
      :name =>'provincien',
      :host => host, 
      :layername => layer, 
      :create_type => 'create', 
      :srid => '28992', 
      :email => email, 
      :passw =>passw
})
      
imp.doImport() do |d|
  d[:id] = 'nl.prov.' + d[:data][:provincien].downcase
  d[:data][:admn_level] = 1
end


# Municipalities
imp = Importer.new({
  :file_path => 'gemeenten.zip', 
  :name => 'gemeentena',
  :host => host, 
  :layername => layer, 
  :create_type => 'create', 
  :srid => '28992', 
  :email => email, 
  :passw => passw
})
      
imp.doImport() do |d|
  d[:id] = 'nl.' + d[:data][:gemeentena].downcase
  d[:data][:admn_level] = 3
end
