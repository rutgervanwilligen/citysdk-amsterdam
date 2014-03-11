#import garages
require 'citysdk'

layer = 'divv.parking.tarieven'

#2. put stuff in citysdk
begin
	#authenticate with test API
	api = CitySDK::API.new('api.citysdk.waag.org')
	exit if not api.authenticate('user@waag.org','PASSWORD')

	#create test layer
	begin
		api.delete("/layers/#{layer}")
	rescue CitySDK::HostException => e
		#import parsed data
		puts e.message
	end

ensure
	#always release api, no matter what happens
	api.release
end
