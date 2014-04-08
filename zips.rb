
 # This wraps the ZIP code database downloaded from http://zips.sourceforge.net/

require 'csv'

class Zips
  def initialize
    unless File.exists? 'zips.csv'
      raise "No zips.csv file found; please download it from http://zips.sourceforge.net/"
    end
    @zips = {}
     # Ruby's CSV module can't handle spaces after commas.
    str = File.read 'zips.csv'
    str.gsub!(/, "/, ',"')
    CSV.parse str do |line|
      zip, st, lat, lon, city, state = *line
      next if zip == 'zip code'  # header
      @zips[zip] = [lat.to_f, lon.to_f]
    end
  end

  # Indicates whether there are coordinates stored for the zip code.
  def data_for?(zip)
    !! @zips[zip]
  end

   # Just get the coordinates of a zip code.
  def coordinates (zip)
    @zips[zip]
  end

  DEG = Math::PI / 180

   # Algorithm taken from http://zips.sourceforge.net/
   # Returns distance in miles.
  def coord_dist (lat_a, lon_a, lat_b, lon_b)
    dist = Math.sin(lat_a * DEG) * Math.sin(lat_b * DEG) +
           Math.cos(lat_a * DEG) * Math.cos(lat_b * DEG) *
           Math.cos((lon_a - lon_b) * DEG)
    return Math.acos(dist) / DEG * 69.09
  end

   # Returns distance in miles between the two zip codes.
   # This is an approximate, of course.
  def distance (zip_a, zip_b)
    lat_a, lon_a = *coordinates(zip_a)
    lat_b, lon_b = *coordinates(zip_b)
    return coord_dist lat_a, lon_a, lat_b, lon_b
  end
end

if __FILE__ == $0
   # Self-testing routine, should be around 300
  puts Zips.new.distance "93108", "94043"
end

