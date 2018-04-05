-- compatibility
if	require
then
	component = require("component")
	table = require("table")
	computer = require("computer")
	event = require("event")
end
function com(s)
	local	taddr = component.list(s)()
	return	taddr and component.proxy(taddr)
end
function pop(t)
	return table.remove(t,1)
end

local port = 1

tunnel = com("tunnel") 
local	sendraw = function(addr, ...)
	return tunnel.send(...)
end
if	not tunnel
then	tunnel = com("modem")
	sendraw = function(addr, ...)
		return tunnel.send(addr, port, ...)
	end
end


function table.append(t, ...)
	local i, v
	for i, v in pairs{...}
	do	table.insert(t, v)
	end
	return t
end

local rserialize
function rserialize(r, ...)
	local t = {}
	local push_t = function()
		if	#t <= 0
		then	return
		end
		table.append(r, "s", #t, table.unpack(t))
		t={}
	end
	for	i, v in ipairs{...}
	do	if	type(v) == "table"
		then	push_t()
			table.append(r, "t")
			local k, vv
			for	k, vv in pairs(v)
			do	table.append(r, "k", k)
				if	type(vv) == "table"
				then	rserialize(r, vv)
				else	table.append(r, "v", vv)
				end
			end
			table.append(r, "n")
		elseif	type(v) == "function"
		then	push_t()
			table.append(r, "f")
		elseif  type(v) == "nil"
		then	push_t()
			table.append(r, "n")
		else	table.insert(t, v)
		end
	end
	if	#t > 0
	then	table.append(r, "s", #t, table.unpack(t))
		t={}
	end
end

function table.lua_serialize(...)
	local r = {}
	rserialize(r, ...)
	return table.unpack(r)
end

function msend(addr, seq, ...)
	local arg = {...}
	while(#arg > 7)
	do
		sendraw(addr, -seq, pop(arg), pop(arg), pop(arg), pop(arg),
			pop(arg), pop(arg),pop(arg))
	end
	sendraw(addr, seq, pop(arg), pop(arg), pop(arg), pop(arg),
		pop(arg), pop(arg), pop(arg))
end

while true
do	local e = {computer.pullSignal()}
	if	e[1] ~= "modem_message"
	then	goto not_modem_message
	end
	local	_mm, receiverAddress, senderAddress,
		port, distance, seq, fs = pop(e), pop(e), pop(e),
		pop(e), pop(e), pop(e), pop(e)
	if	type(seq) ~= "number"
	then	goto not_modem_message
	end

	seq = seq - 1;
	local f, s
	if	not fs
	then	msend(senderAddress, seq, table.lua_serialize(false, "nil"))
	else	if	string.sub(fs,1,7) ~= "return "
		then	fs = "return " .. fs
		end
		f, s = load(fs)
		if	f
		then	msend(senderAddress, seq, table.lua_serialize(pcall(f(),
				table.unpack(e))))
		else	msend(senderAddress, seq, table.lua_serialize(
				false, "complie failed: ".. s))
		end
	end
	::not_modem_message::
end
