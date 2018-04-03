local component = require("component")
package.loaded.tablex = nil
local table = require("tablex")
local event = require("event")

local running = true

local port = 1

function com(s)
	local	addr = component.list(s)()
	return	addr and component.proxy(addr)
end

local senddev = com("tunnel")

local	sendraw = function(addr, ...)
	return senddev.send(...)
end

if	not senddev
then	senddev = com("modem")
	senddev.open(port)
	sendraw = function(addr, ...)
		--return senddev.send(addr, port, ...) -- todo
		return senddev.broadcast(port, ...)
	end
end

function do_send(...)
	local recbuf = {}
	local n = 0
	local myseq = math.random() + 1
	event.listen("modem_message", function(_mm, receiverAddress, senderAddress, port, distance, seq, ...)
		if	not running
		then	return false
		end
		--print("seq:", seq, ...)
		local	i
		local	arg = {...}
		seq = (seq + 0)
		if	seq ~= myseq
		and	seq ~= -myseq
		then	return true
		end
		
		for	i = 1, #arg
		do	recbuf[n+i] = arg[i]
		end
		n = n + 7
		if	seq > 0
		then	--print("seq:", seq, table.unpack(recbuf))
			event.push("cont")
			return false -- unregister
		end
		return true
	end)

	sendraw(0, myseq+1, ...)
	event.pull("cont")
	
	return	table.lua_unserialize(recbuf)
end

table.dump{ret={do_send(...)}}
running = false

