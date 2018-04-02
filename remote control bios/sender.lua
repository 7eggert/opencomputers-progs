local component = require("component")
package.loaded.tablex = nil
local table = require("tablex")
local event = require("event")

local running = true

function do_send(q,w,e,r,t)
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

	component.tunnel.send(myseq+1, q,w,e,r,t)
	event.pull("cont")
	
	return	table.lua_unserialize(recbuf)
end

table.dump{ret={do_send(...)}}
running = false

