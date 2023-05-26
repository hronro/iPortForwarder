local ffi = require('ffi')

local header_file = io.open('./headers/ipf.h')
local header = header_file:read('*a')
header_file:close()

ffi.cdef(header)

local ipf = ffi.load('./target/release/' ..
(jit.os == 'Linux' and 'libipf.so' or jit.os == 'OSX' and 'libipf.dylib' or jit.os == 'Windows' and 'ipf.dll' or 'unknown'))

---Check if ip is valid
---@param ip string
---@return boolean
local function check_ip_is_valid(ip)
	return ipf.ipf_check_ip_is_valid(ffi.new('char [?]', #ip + 1, ip))
end

---Forward ip and port
---@param ip string
---@param port number
---@param allow_lan boolean
---@return number forward_rule_id
local function forward(ip, port, allow_lan)
	return ipf.ipf_forward(ffi.new('char [?]', #ip + 1, ip), port, allow_lan)
end

---Cancel forward
---@param forward_rule_id number
---@return number forward_rule_id
local function cancel_forward(forward_rule_id)
	return ipf.ipf_cancel_forward(forward_rule_id)
end

---Sleep for n seconds
---@param n number
local function sleep(n)
	os.execute('sleep ' .. tonumber(n))
end

print 'Please input IP address you want to forward:'

local ip = io.read()

if check_ip_is_valid(ip) then
	print('IP address ' .. ip .. ' is valid.')

	print 'Please input the port you want to forward:'
	local port = tonumber(io.read())

	print 'Please input how long (in seconds, empty means forever) you want to forward:'
	local time = tonumber(io.read())

	if port ~= nil and port > 0 and port <= 65535 then
		local forward_rule_id = forward(ip, port, false)

		print 'Start forwarding...'

		if time ~= nil then
			sleep(time)
			cancel_forward(forward_rule_id)
			print 'Forwarding stopped.'
		end

		sleep(1000000)
	else
		print "Port is invalid."
	end
else
	print("IP address " .. ip .. " is invalid.")
end
