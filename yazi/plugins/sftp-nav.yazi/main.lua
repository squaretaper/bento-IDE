local home = os.getenv("HOME") or ""
local remote_dir = home .. "/remote"

local server_homes = {
	studio = "/Users/joshua",
}

-- Sync: override for l/Right — directory entry only
local function entry()
	local cwd = tostring(cx.active.current.cwd)
	local h = cx.active.current.hovered

	-- Server stub dir → SFTP redirect
	if h and cwd == remote_dir and server_homes[h.name] then
		ya.emit("cd", { Url("sftp://" .. h.name .. "/" .. server_homes[h.name]) })
		return
	end

	-- Default: enter directory (works for both local and SFTP dirs)
	ya.emit("enter", {})
end

-- cd event: redirect ~/remote/<name>/ to SFTP
local function setup()
	ps.sub("cd", function()
		local cwd = tostring(cx.active.current.cwd)
		if cwd:sub(1, #remote_dir + 1) == remote_dir .. "/" then
			local server = cwd:sub(#remote_dir + 2):match("^([^/]+)")
			if server and server_homes[server] then
				ya.emit("cd", { Url("sftp://" .. server .. "/" .. server_homes[server]) })
			end
		end
	end)
end

return { setup = setup, entry = entry }
