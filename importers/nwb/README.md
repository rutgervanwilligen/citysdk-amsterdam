# NWB importer

Imports all road segments from [Nationaal Wegenbestand](https://data.overheid.nl/data/dataset/nationaal-wegen-bestand-wegen-wms) into existing CitySDK instance. Expects local PostgreSQL database `citysdk-ndw`, containing table `wegvakken`. NWB roads are used to link with traffic data from [NDW](http://ndw.nu/).

Importer expects existing CitySDK layer `nwb`.

See `citysdk-ndw` repository for information about obtaining data, creating NDW database, and details about linking NDW DATEX II real-time traffic flow data to NWB road segments.

