# CitySDK Amsterdam webservices

## Boilerplate code

    class CitySDK_Services < Sinatra::Base
     
      KEY = File.open(File.dirname(__FILE__) + '/key.txt','r').read
      
      post '/service' do
      
        # Read data from request 
        json = self.parse_request_json
        
        # json is data from CitySDK node
        id = json["id"]
    
        connection = Faraday.new "http://service.org"
        response = self.httpget(connection, "/api/#{id}")
        
        if response.status == 200
          
          return { 
            :status => 'success', 
            :url => request.url, 
            :data => JSON.parse(response)
          }.to_json 
        else
          self.do_abort(response.status, {result: "fail", error: "Error requesting resource", message: exception.message})
        end

      end
    end  
      
