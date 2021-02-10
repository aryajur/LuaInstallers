-- Script to patch LuaSec Makefile to add rpath 
local fileName = arg[1]
local f = io.open(fileName)
local fd = f:read("*a")
f:close()

f = io.open(fileName,"w+")
fd = fd:gsub("(%cLNX_LDFLAGS.-) (%$.-%c)","%1 -Wl,-rpath,. %2")
f:write(fd)
f:close()