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

class String
  def round_coordinates(precision)
    self.gsub(/(\d+)\.(\d{#{precision}})\d+/, '\1.\2')
  end
end

SQL = <<-SQL
  SELECT
    wvk_id, mst.mst_id, mst.name, mst.location::int, carriageway,    
    method, equipment, lanes, characteristics,
    direction, distance::float, ST_AsGeoJSON(geom) AS geojson
  FROM 
    mst_wvk 
  JOIN 
    mst
  ON 
    mst_wvk.mst_id = mst.mst_id;
SQL
  
MST_WVK = {}
DB[SQL].each do |row|
  row[:characteristics] = JSON.parse(row[:characteristics], {:symbolize_names => true})
  MST_WVK[row[:mst_id]] = row
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
        mst_wvk = MST_WVK[@data[:id]]
        wvk_id = mst_wvk[:wvk_id]
        
        values = @data[:values].zip(mst_wvk[:characteristics]).map do |value, characteristic|          
          h = {
            type: value[:type],
            value: value[:value],
            accuracy: characteristic[:accuracy],
            period: characteristic[:period],
            lane: characteristic[:lane],
          }
          
          h[:vehicleLengths] = characteristic[:lengthCharacteristics] if characteristic.has_key? :lengthCharacteristics
          h[:vehicleType] = characteristic[:vehicleType] if characteristic.has_key? :vehicleType
          
          h
        end
        
        # Remove entries with invalid values
        values.delete_if do |value|
          value[:value] <= 0
        end        
        
        data = {
          mst_id: mst_wvk[:mst_id],
          name: mst_wvk[:name],
          vild_location: mst_wvk[:location],
          carriageway: mst_wvk[:carriageway],
          direction: mst_wvk[:direction],
          distance: mst_wvk[:distance],
          method: mst_wvk[:method],
          equipment: mst_wvk[:equipment],
          lanes: mst_wvk[:lanes],
          geometry: JSON.parse(mst_wvk[:geojson].round_coordinates(6)),
          measurement: {
            time: @data[:time],
            values: values
          }
        }
                
        # TODO: naming convention!
        key = "ndw!!!#{wvk_id}"
        memdata = DC.get(key)
        if memdata
          memdata[@data[:id]] = data
          DC.set(key, memdata)
        else
          DC.set(key, {@data[:id] => data})
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
        @data[:values] << {}
      end  
    when :basicData
      case value
      when "TrafficFlow"
        @data[:values][-1][:type] = :flow
      when "TrafficSpeed"
        @data[:values][-1][:type] = :speed
      end
    end
  end
  
  def text(value)
    case @elements[-1]
    when :measurementTimeDefault
      @data[:time] = value
    when :vehicleFlowRate
      @data[:values][-1][:value] = value.to_i
    when :speed
      @data[:values][-1][:value] = value.to_i
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


