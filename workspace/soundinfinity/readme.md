# SymLink Roblox

This is meant to be used within exploit environments such as JJSploit or Krnl.

# Example

Simple RemoteSpy

```lua
local mt_mod = import('soundinfinity/metatable-modifier.lua')
local mt = mt_mod:open(game, "w")

local function log_event(ev)
    coroutine.wrap(function()
        if ev.target.Name:match('Anal') then return end
        if ev.target.Name:match('^__GetData') then return end
        local buff = {}
        for k,v in next, ev.arguments do
            table.insert(buff, '"'..tostring(v)..'"')
        end
        rconsolewarn('arguments: '.. table.concat(buff, ' '))
        rconsolewarn('target: '..ev.target:GetFullName())
        rconsolewarn('method: '..ev.method)
        rconsolewarn('type: '..ev.target.ClassName .. '\n')
    end)(ev)
end

mt:unhookNamecall()
mt:addNamecallListener('FireServer', log_event)
mt:addNamecallListener('Fire', log_event)
mt:addNamecallListener('InvokeServer', log_event)
mt:addNamecallListener('Invoke', log_event)

```
