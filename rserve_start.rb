=begin
look into r_test2.rb and r_wrapper for further functionality
this will initialize the rserve. If rserve started, then no initialization will occur
=end
require 'rserve'
require 'socket'

def is_port_open?(ip, port)
  begin
    TCPSocket.new(ip, port)
  rescue Errno::ECONNREFUSED
    return false
  end
  return true
end

def check_ports
	addr_infos = Socket.ip_address_list
	no_port=false
	addr_infos.each { |addr_info| no_port= is_port_open?(addr_info.ip_address, 6311) || no_port } #if at least one port is open, no Rserve should be performed. Rserve is usually port 6311
		unless no_port
			`/usr/lib/R/bin/R CMD /home/jwong/R/x86_64-pc-linux-gnu-library/3.2/Rserve/libs/Rserve --no-save`  #using the long form because randomforest stored in gnu-library
		end
	#Socket.ip_address_list[0].ip_address -> 127.0.0.1
end
check_ports