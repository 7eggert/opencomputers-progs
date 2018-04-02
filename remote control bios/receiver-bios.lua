if not component
then component = require("component")
end
if	not table
then	table=require("table")
end
if	not computer
then	computer = require("computer")
end
function com(s)
	return	component.proxy(component.list(s)())
end
tunnel = com("tunnel")
--local event = require("event")

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

function msend(seq, ...)
	local arg = {...}
	while(#arg > 7)
	do
		tunnel.send(-seq, table.remove(arg,1), table.remove(arg,1), table.remove(arg,1), table.remove(arg,1), table.remove(arg,1), table.remove(arg,1), table.remove(arg,1))
	end
	tunnel.send(seq, table.remove(arg,1), table.remove(arg,1), table.remove(arg,1), table.remove(arg,1), table.remove(arg,1), table.remove(arg,1), table.remove(arg,1))
end

while true
do
	--local e = table.pack(event.pull("modem_message"))
	--local _mm, receiverAddress, senderAddress, port, distance, seq, fs = table.remove(e,1), table.remove(e,1),  table.remove(e,1), table.remove(e,1), table.remove(e,1), table.remove(e,1), table.remove(e,
	local e = {computer.pullSignal()}
	if	e[1] ~= "modem_message"
	then	goto not_modem_message
	end
	local _mm, receiverAddress, senderAddress, port, distance, seq, fs = table.remove(e,1), table.remove(e,1),  table.remove(e,1), table.remove(e,1), table.remove(e,1), table.remove(e,1), table.remove(e,1)
	local f
	if	not fs
	then	f=function()return nil;end
	else	f = load("return " .. fs)
	end
	seq = seq - 1;
	--local ret = {pcall(f(), table.unpack(e))}
	msend(seq, table.lua_serialize(pcall(f(), table.unpack(e))))
	::not_modem_message::
end
