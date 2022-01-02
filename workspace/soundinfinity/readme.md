# SymLink Roblox

This is meant to be used within exploit environments such as JJSploit or Krnl.

# Example

Simple RemoteSpy

```lua
local mt_mod = import('soundinfinity/metatable-modifier.lua')
local mt = mt_mod:open(game, "w")
mt:close()

local function log_event(ev)
    if ev.target.Name:lower():match("tilt") then return end
    if ev.target.Name:lower():match("anal") then return end
    local buff = {}
    for k,v in next, ev.arguments do
        table.insert(buff, '"'..tostring(v)..'"')
    end
    rconsolewarn('arguments: '.. table.concat(buff, ' '))
    rconsolewarn('target: '..ev.target:GetFullName())
    rconsolewarn('type: '..ev.target.ClassName .. '\n')
end

mt:addNamecallListener('FireServer', log_event)
mt:addNamecallListener('Fire', log_event)
mt:addNamecallListener('InvokeServer', log_event)
```
