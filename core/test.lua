local ffi = require('ffi')

local header_file = io.open('./headers/ipf.h')
local header = header_file:read('*a')
header_file:close()

ffi.cdef(header)

local ipf = ffi.load('./target/release/' .. (jit.os == 'Linux' and 'libipf.so' or jit.os == 'OSX' and 'libipf.dylib' or jit.os == 'Windows' and 'ipf.dll' or 'unknown'))

local function check_ip_is_valid(ip)
	return ipf.ipf_check_ip_is_valid(ffi.new('char [?]', #ip + 1, ip))
end

local function forward (ip, port, allow_lan)
	ipf.ipf_forward(ffi.new('char [?]', #ip + 1, ip), port, allow_lan)
end


local function sleep(n)
  os.execute("sleep " .. tonumber(n))
end

print "Please input IP address you want to forward:"

local ip = io.read()

if check_ip_is_valid(ip) then
	print("IP address " .. ip .. " is valid.")

	print "Please input the port you want to forward:"
	local port = tonumber(io.read())

		if port ~= nil and port > 0 and port <= 65535 then
			forward(ip, port, false)

			print "Start forwarding..."

			sleep(1000000)
		else
				print "Port is invalid."
		end
else
	print("IP address " .. ip .. " is invalid.")
end
