require 'citysdk'
include CitySDK

# national border
imp = Importer.new({
      :file_path=>"/Users/tom/Downloads/landsgrens.zip", 
      :name=>'landsnaam',
      :layername=>"admr", 
      :create_type=>"create", 
      :srid=>"28992",  # dutch RD system
      :host=>"api.dev",
      :email=>'citysdk@waag.org', 
      :passw=>'nix'
      })
      
      
imp.doImport() do |d|
  d[:id] = 'nederland'
  d[:data][:admn_level] = 0
end


# provinces
imp = Importer.new({
      :file_path=>"/Users/tom/Downloads/provincies.zip", 
      :name=>'provincien',
      :host=>"api.dev", 
      :layername=>"admr", 
      :create_type=>"create", 
      :srid=>"28992", 
      :email=>'citysdk@waag.org', 
      :passw=>'nix'
      })
      
      
imp.doImport() do |d|
  d[:id] = 'nl.prov.' + d[:data][:provincien].downcase
  d[:data][:admn_level] = 1
end


# municipalities
imp = Importer.new({
      :file_path=>"/Users/tom/Downloads/gemeenten.zip", 
      :name=>"gemeentena",
      :host=>"api.dev", 
      :layername=>"admr", 
      :create_type=>"create", 
      :srid=>"28992", 
      :email=>'citysdk@waag.org', 
      :passw=>'nix'
      })
      
      
imp.doImport() do |d|
  d[:id] = 'nl.' + d[:data][:gemeentena].downcase
  d[:data][:admn_level] = 3
end

