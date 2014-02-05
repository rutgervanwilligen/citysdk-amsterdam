##############################################################################################################
## Arts Holland ##############################################################################################
############################################################################################################## 

class CitySDK_Services < Sinatra::Base

  AH_QUERY = File.open(File.dirname(__FILE__) + '/artsholland.sparql','r').read
  AH_URL = "http://api.artsholland.com" 
  
  # curl --data '{"uri":"http://data.artsholland.com/venue/1998-l-001-0000187"}' http://localhost:9292/artsholland  
  post '/artsholland' do
    
    json = self.parse_request_json
    
    if json['uri'] and json['uri'] != ''
      
      start_date = DateTime.now.strftime()
      end_date = DateTime.strptime((DateTime.now.to_time.to_i + 2 * 7 * 24 * 60 * 60).to_s, '%s').strftime()
      
      ahPostData = {
        :output => :json,
        :query => AH_QUERY % [json['uri'], start_date, end_date]
      }
  
      connection = Faraday.new :url => AH_URL
      response = connection.post do |req|
        req.url '/sparql'
        req.headers = {
         'Content-Type' => 'application/x-www-form-urlencoded',
         'Accept' => 'application/sparql-results+json'
        }        
        req.body = ahPostData
      end
  
      events = []
      if response.status == 200 
         results = JSON.parse(response.body)
         
         results["results"]["bindings"].each { |event|
           events << {
             :title => event["title"]["value"],
             :time => event["time"]["value"],
             :event_uri => event["e"]["value"],
             :production_uri => event["p"]["value"],
           }
         }
                  
         return { :status => 'success', 
           :url => request.url, 
           :data => json.merge({
             :events => events
           })           
         }.to_json         
  
      else
        self.do_abort(response.status, {result: "fail", error: "Error requesting resource", message: response.body})
      end
  
    else
      return { :status => 'success', 
        :url => request.url, 
        :data => json
      }.to_json 
    end
    
  end
    
end