local component = require("component")
package.loaded.tablex = nil
local table = require("tablex")
local event = require("event")
local shell = require("shell")

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
	local myseq = math.random(2147483646) + 1
	local waiting = true
	local timeout = 10
	event.listen("modem_message", function(_mm, receiverAddress, senderAddress, port, distance, seq, ...)
		if	not waiting
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
		
		for	i = 1, 7
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
	local	i
	event.pull(timeout, "cont")
	
	waiting = false
	return	table.lua_unserialize(recbuf)
end

--table.dump{do_send(...)}

function table.printPairs(t,before, after)
	local	k,v
	if	before ~= nil
	then	print(before)
	end
	for	k,v in pairs(t)
	do	print(k, v)
	end
	if	after ~= nil
	then	print(after)
	end
end

local env = setmetatable({}, {__index=_G})
env[_G] = env
do
	--not local
	env_robot = {}

	local	result, ori_robot = do_send("function()\
		robot=require('robot')\
		function tcall(t,k,...)\
			return _ENV[t][k](...)\
		end;\
		function ccall(c,...)\
			local	t = _ENV\
			local	part\
			for	part in string.gmatch(c, '[^.]+')\
			do	t = t[part]\
			end\
			return t(...)\
		end\
		function geoscan(...)\
			return component.geolyzer.scan(...)\
		end\
	return robot;end")
	--table.dump(ori_robot)
	local	k, v
	local	function tcall_factoty(t,k)
		return function(...)
			print("do_send tcall", t, k, ...)
			local res = {do_send("tcall", t, k, ...)}
			table.remove(res,1)
			return table.unpack(res)
		end
	end

	for	k, v in pairs(ori_robot)
	do	if	type(v) == "function"
		then	env_robot[k] = tcall_factoty("robot", k)
		end
	end
	
	env_component = table.join(component)
	local env_component_m = getmetatable(component)
	env_component.robot = nil
	env_component.inventory_controller = nil
	env_component.experience = nil
	env_component_m__index_old = env_component_m.__index
	env_component_m.__index = function(t, k)
		return setmetatable({}, { __index = function(tt, kk)
			-- todo: Filter for some local components?
			return function(...)
				local f = "component.".. k.. "." .. kk
				print("do_send ccall ".. f, ...)
				local res 
				if	f == "component.geolyzer.scan"
				then	res = {do_send("geoscan", ...)} -- hack!
				else	res = {do_send("ccall", f, ...)}
				end
				table.remove(res,1)
				return table.unpack(res)
			end
		end})
	end
	setmetatable(env_component, env_component_m)
	env_component.isAvailable = tcall_factoty("component", "isAvailable")
	--table.printPairs(env_component, "components:", "---")

	--env.component = env_component
	--print (env.component.isAvailable("robot"))
	
	local ori_env_require = env.require
	env.package = table.join(package)
	env.package.loaded={
		robot         = env_robot,
		component     = env_component,
		["_G"]        = env,
		["bit32"]     = table.join(package.loaded.bit32),
		["coroutine"] = table.join(package.loaded.coroutine),
		["math"]      = table.join(package.loaded.math),
		["os"]        = table.join(package.loaded.os),
		["package"]   = table.join(package.loaded.package),
		["string"]    = table.join(package.loaded.string),
		["table"]     = table.join(package.loaded.table),
		["unicode"]   = table.join(package.loaded.unicode),
	}
	env.here="h2"
	local env_package_loading = {}
	env.require = function(lib)
		print("require", lib, env.package.loaded[lib], type(env.package.loaded[lib]))
		if	lib == "robot"
		then	print("pre rovot")
			return env_robot
		elseif	lib == "component"
		then	print("pre component")
			return env_component
		else	if	env.package.loaded[lib]
			then	return env.package.loaded[lib]
			end
			if	env_package_loading[lib]
			then	error("circular dependecy on "..lib)
			end
			env_package_loading[lib] = true
			--print("searchpath", lib, env.package.path)
			local file, err = package.searchpath(lib, env.package.path)
			--print(file, err)
			local libf , err = loadfile(file, "t", env)
			--print(libf, err)
			local ret = libf()
			env.package.loaded[lib] = ret
			--print(ret)
			env_package_loading[lib] = nil
			return ret
			
			
--[[		return assert(load("return function(rq, lib, g)\
			print('rq', lib, here);\
			local pl = g.package.loaded\
			g.package.loaded = package.loaded\
			ret=assert(rq(lib));\
			package.loaded = g.package.loaded\
			g.package.loaded = pl\
			print(ret, type(ret), package.loaded[lib], type(package.loaded[lib]), g.package.loaded[lib], type(g.package.loaded[lib]))\
			return ret\
		end",
		"env_require("..lib..")",
		"t",
		env))()(ori_env_require, lib, _G)
		]]
		end
	end
end

--local ext = assert(loadfile("/home/u.lua", "t", env))
--table.dump{ext()}
--local ext = assert(loadfile("/home/d.lua", "t", env))
--table.dump{ext()}
--table.dump{env_component.robot.turn(false)}
--table.dump{do_send("t2call", "component","robot","turn", false, ...)}

local arg={...}
local path = string.gsub(os.getenv("PATH") or ".", ":", "/?.lua:") .. "/?.lua"
local pwd = shell.resolve(".")
path = string.gsub(string.gsub(path, "^%.", pwd), ":%.", ":"..pwd)
path = string.gsub(path, ':', ';')
local file = assert(package.searchpath(arg[1], path))
local ext = assert(loadfile(file, "t", env))
table.dump{ext()}
