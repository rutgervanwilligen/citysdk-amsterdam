require 'stringio'
require 'zlib'
require 'json'
require 'ox'
require 'open-uri'
require 'sequel'
require 'dalli'

DB = Sequel.connect('postgres://localhost/ndw?user=postgres&password=postgres')
DC = Dalli::Client.new('localhost:11211')

NDW_PATH = "ftp://83.247.110.3/trafficspeed.gz"

WAIT = 60 * 2

MST_WVK = {}
DB[:mst_wvk].each do |row|
  MST_WVK[row[:mst_id]] = row[:wvk_id]
end  

class TrafficSpeed < ::Ox::Sax
  
  def initialize
    @data = {}    
    @elements = []    
  end
    
  def start_element(name)
    @elements << name
  end
  
  def end_element(name)
    @elements.pop
    if name == :siteMeasurements      
      if MST_WVK.has_key? @data[:id]
        wvk_id = MST_WVK[@data[:id]]
        
        # TODO: naming convention!
        key = "ndw!!!#{wvk_id}"
        memdata = DC.get(key)
        if memdata
          memdata[@data[:id]] = @data
          DC.set(key, memdata)
        else
          DC.set(key, {@data[:id] => @data})
        end        
      end    
      
      @data = {}
    end        
  end
  
  def attr(name, value)
    case @elements[-1]
    when :measurementSiteReference
      if name == :id
        @data[:id] = value
      end
    when :measuredValue
      if name == :index
        if not @data.has_key? :values
          @data[:values] = []
        end        
        @data[:values] << {
          index: value.to_i
        }
      end  
    when :basicData      
      @data[:values][-1][:type] = value
    end
  end
  
  def text(value)
    case @elements[-1]
    when :measurementTimeDefault
      @data[:time] = value
    when :vehicleFlowRate
      @data[:values][-1][:flow] = value.to_i
    when :speed
      @data[:values][-1][:speed] = value.to_i
    end
  end
  
end

# Data sample:
# <siteMeasurements>
#   <measuredValue index="6" xsi:type="_SiteMeasurementsIndexMeasuredValue">
#     <measuredValue xsi:type="MeasuredValue">
#       <basicData xsi:type="TrafficFlow">
#         <vehicleFlow numberOfInputValuesUsed="12">
#           <vehicleFlowRate>720</vehicleFlowRate>
#         </vehicleFlow>
#       </basicData>
#     </measuredValue>
#   </measuredValue>
#   <measuredValue index="7" xsi:type="_SiteMeasurementsIndexMeasuredValue">
#     <measuredValue xsi:type="MeasuredValue">
#       <basicData xsi:type="TrafficSpeed">
#         <averageVehicleSpeed numberOfIncompleteInputs="0" numberOfInputValuesUsed="0" supplierCalculatedDataQuality="100.0">
#           <speed>0</speed>
#         </averageVehicleSpeed>
#       </basicData>
#     </measuredValue>
#   </measuredValue>
# </siteMeasurements>

handler = TrafficSpeed.new

loop do 
  puts "Reading zipped NDW data into memcached..."
  begin
    open(NDW_PATH) do |f|
      file = Zlib::GzipReader.open(f)
      Ox.sax_parse(handler, file)
    end  
    puts "Done... time for sleep (#{WAIT} seconds)!"
  rescue Exception => e
    puts e
  end
  sleep(WAIT)
end


