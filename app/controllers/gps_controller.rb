class GpsController < ApplicationController
  # Queclink GV55 TCP server endpoint for real-time GPS data
  # Protocol: IMEI(15 bytes)+comma+data packet
  
  def receive
    req_body = request.body.read
    imei = req_body[0..14]
    packet = req_body[16..-1]
    
    # Parse Queclink GV55 packet (basic location + status)
    # Format after IMEI: +GTFIL or other report types
    if packet.start_with?('+GTFIL')
      # Extract GPS data (simplified parser for prod)
      lat = parse_coordinate(packet[20..30])
      lon = parse_coordinate(packet[32..42])
      speed = packet[44..47].to_f
      ignition = (packet[60] == '1')
      
      # Store GPS location (use your existing model)
      GpsLocation.create!(
        device_imei: imei,
        latitude: lat,
        longitude: lon,
        speed: speed,
        ignition_status: ignition,
        received_at: Time.current
      )
    end
    
    head :ok
  end
  
  private
  
  def parse_coordinate(raw)
    # Queclink coordinate format: DDMM.MMMM,a (a= N/S/E/W)
    degrees = raw[0..1].to_f
    minutes = raw[2..-3].to_f / 60.0
    direction = raw[-1]
    (degrees + minutes) * (direction.in?(['S', 'W']) ? -1 : 1)
  end
end
