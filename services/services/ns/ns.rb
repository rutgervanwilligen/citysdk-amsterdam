##############################################################################################################
## Nederlandse Spoorwegen ####################################################################################
##############################################################################################################

class CitySDK_Services < Sinatra::Base 
  
  NS_KEY = JSON.parse(File.read('/var/www/citysdk/shared/config/nskey.json')) 
  NS_URL = "https://webservices.ns.nl" 
  NS_AVT = "/ns-api-avt?station="
  NS_PRIJZEN = "/ns-api-prijzen-v2?"
  NS_STATIONS = "/ns-api-stations"
  NS_STORINGEN = "/ns-api-storingen?"
  NS_PLANNER = "/ns-api-treinplanner?"
  
  NS_CDK_IDS = JSON.parse(File.read(File.dirname(__FILE__) + '/cdk_ids.json').force_encoding('utf-8')) 
  NS_STATION_CODES = JSON.parse(File.read(File.dirname(__FILE__) + '/station_codes.json').force_encoding('utf-8')) 
  NS_LINES = JSON.parse(File.read(File.dirname(__FILE__) + '/lines.json').force_encoding('utf-8')) 
    
  # curl --data '{"code":"HT", "land":"NL", "type":"knooppuntIntercitystation", "uiccode":"8400319"}' http://services.citysdk.waag.org/ns_avt
  post '/ns_avt' do
    
    json = self.parse_request_json
    
    if json['code'] and json['code'] != ''
      connection = Faraday.new :url => NS_URL, :ssl => {:verify => false}
      connection.basic_auth(NS_KEY["usr"], NS_KEY["key"])
  
      data = json
      response = httpget(connection, NS_AVT + json['code'])
      if response.status == 200
        h = Hash.from_xml(response.body)
        
        data["VertrekkendeTreinen"] = []
        
        if h['ActueleVertrekTijden'] and h['ActueleVertrekTijden']['VertrekkendeTrein']
        
          h['ActueleVertrekTijden']['VertrekkendeTrein'].each { |vt|
          
            vertrekkende_trein = {
              :type => vt["TreinSoort"].downcase.gsub(/\W+/, '_'),
              :vervoerder => vt["Vervoerder"],
              :ritnummer => vt["RitNummer"].to_i,
              :vertrektijd => vt["VertrekTijd"],
              :route => {},
              :eindbestemming => {
                :naam => vt["EindBestemming"]              
              },
              :spoor => vt["VertrekSpoor"]
            }
          
            vertrekkende_trein[:reistip] = vt["ReisTip"].strip if vt["ReisTip"]
            if vt["Opmerkingen"]
              vertrekkende_trein[:opmerkingen] = vt["Opmerkingen"].values.map { |opmerking| opmerking.strip }
            end
            vertrekkende_trein[:route][:tekst] = vt["RouteTekst"] if vt["RouteTekst"]
                
            # Vertrekvertraging
            if vt["VertrekVertraging"]
              vertrekkende_trein[:vertraging] = {
                :minuten => vt["VertrekVertraging"] =~ /(\d+)/ ? $1.to_i : 0,
                :tekst => vt["VertrekVertragingTekst"]
              }           
            end
                                    
            # Eindbestemming, code & cdk_id:
            code = NS_STATION_CODES[vt['EindBestemming']]
            cdk_id = NS_CDK_IDS[code]
            type = vt["TreinSoort"].downcase.gsub(/\W+/, '_')
          
            vertrekkende_trein[:eindbestemming][:code] = code if code
            vertrekkende_trein[:eindbestemming][:cdk_id] = cdk_id if cdk_id   
  
            # Route
            line = nil
            if NS_LINES.has_key? type
              NS_LINES[type].each { |l|
                # Two options to check whether l is the correct line
                # 1. l must contain code and json['code'] with index of code > index json['code']
                # 2. code must be terminus of l and l must contain json['code']
              
                if i1 = l.index(json['code']) and i2 = l.index(code) and i1 < i2 # Option 1
                #if l[-1] == code and l.include? json['code'] # Option 2
                  line = l
                  break
                end
              }
            end
          
            if line
              vertrekkende_trein[:route][:cdk_id] = "ns.#{type}.#{line[0]}.#{line[-1]}".downcase
              vertrekkende_trein[:route][:stations] = line.map { |code|  NS_CDK_IDS[code]}
            end
          
            data["VertrekkendeTreinen"] << vertrekkende_trein   
          }        
        
        end
        
        return { :status => 'success', 
          :url => request.url, 
          :data => data
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