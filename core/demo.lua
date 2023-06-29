local ffi = require('ffi')

local header_file = io.open('./headers/ipf.h')

if header_file == nil then
	print 'Cannot find header file.'
	os.exit(1)
end

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
---@param remote_port number
---@param local_port number
---@param allow_lan boolean
---@return number forward_rule_id
local function forward(ip, remote_port, local_port, allow_lan)
	return ipf.ipf_forward(ffi.new('char [?]', #ip + 1, ip), remote_port, local_port, allow_lan)
end

---Forward ip and a range of ports
---@param ip string
---@param remote_port_start number
---@param remote_port_end number
---@param local_port_start number
---@param allow_lan boolean
---@return number forward_rule_id
local function forward_range(ip, remote_port_start, remote_port_end, local_port_start, allow_lan)
	return ipf.ipf_forward_range(ffi.new('char [?]', #ip + 1, ip), remote_port_start, remote_port_end, local_port_start, allow_lan)
end

---Cancel forward
---@param forward_rule_id number
---@return number forward_rule_id
local function cancel_forward(forward_rule_id)
	return ipf.ipf_cancel_forward(forward_rule_id)
end

---Convert error code to error message
---@param error number error code
---@return string #error message
local function error_message(error)
	local message_table = {
		[-1] = 'Unknown error',
		[-10] = 'Invalid string',
		[-11] = 'Invalid IP address',
		[-12] = 'Too many rules',
		[-13] = 'Invalid rule ID',
		[-14] = 'Invalid local start port',
		[-15] = 'Invalid remote end port',
		[-16] = 'Error handler is already registered',
		[-51] = 'Permission denied',
		[-52] = 'Address in use',
		[-53] = 'Already exists',
		[-54] = 'Out of memory',
		[-55] = 'Too many open files',
	}

	return message_table[error]
end

---Error handler for libipf
---@param forward_rule_id number forward rule id
---@param error number
---@diagnostic disable-next-line: unused-local
local function ipf_error_handler(forward_rule_id, error)
	print('Error: ' .. error_message(error))
	os.exit(1)
end

---Sleep for n seconds
---@param n number
local function sleep(n)
	os.execute('sleep ' .. tonumber(n))
end

---Start a single port forwarding
---@param ip string
---@return number forward_rule_id
local function forward_single_port(ip)
	print 'Please input the port you want to forward:'
	local port = tonumber(io.read())
	if port == nil or port <= 0 or port > 65535 then
		print 'Port is invalid.'
		os.exit(1)
	end
	return forward(ip, port, port, true)
end

---Start a range of ports forwarding
---@param ip string
---@return number forward_rule_id
local function forward_a_range_of_ports(ip)
	print 'Please input the start port you want to forward:'
	local start_port = tonumber(io.read())
	print 'Please input the end port you want to forward:'
	local end_port = tonumber(io.read())
	if start_port == nil or start_port <= 0 or start_port > 65535 then
		print 'Start port is invalid.'
		os.exit(1)
	end
	if end_port == nil or end_port <= 0 or end_port > 65535 or end_port <= start_port then
		print 'End port is invalid.'
		os.exit(1)
	end
	return forward_range(ip, start_port, end_port, start_port, true)
end

ipf.ipf_register_error_handler(ipf_error_handler)

print 'Please input IP address you want to forward:'

local ip = io.read()

if check_ip_is_valid(ip) == false then
	print("IP address " .. ip .. " is invalid.")
	os.exit(1)
end

print 'Please input how long (in seconds, empty means forever) you want to forward:'
local time = tonumber(io.read())

---@type number
local forward_rule_id

print 'Do you want to forward a single port or a range of ports? (single/range)'
local forward_type = io.read()

if forward_type == 'single' then
	forward_rule_id = forward_single_port(ip)
elseif forward_type == 'range' then
	forward_rule_id = forward_a_range_of_ports(ip)
else
	print('Unknown forward type (`' .. forward_type .. '`), must be `single` or `range`.')
	os.exit(1)
end

print 'Forwarding started.'

if time ~= nil then
	sleep(time)
	cancel_forward(forward_rule_id)
	print 'Forwarding stopped.'
end

sleep(1000000)
