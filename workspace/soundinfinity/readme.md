# SymLink Roblox
This is meant to be used within exploit environments such as JJSploit or Krnl.

# Usage
expected syntax:
```ts
function symlink(object: Instance, target: Instance): void {}
```

the following is a robust example: (i will try later to make more sense of it)
```lua
local remotes = Instance.new("Folder")
remotes.Name = "__REMOTES"
remotes.Parent = workspace.Terrain

local things = Instance.new("Folder")
things.Name = "__THINGS"
things.Parent = workspace

symlink(things, remotes)

print(things.ChildName.Name) --> remotes.ChildName.Name
things.ChildName:FireServer() --> remotes.ChildName:FireServer()
```

To summarize, this will redirect references of the children from "things" to be retrieved from "remotes" instead.

# Why?
I made this to patch a exploiting script for Pet Simulator, because they have moved the __REMOTES folder.