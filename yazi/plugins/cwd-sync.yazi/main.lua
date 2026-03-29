local function setup()
	ps.sub("cd", function()
		local cwd = cx.active.current.cwd
		if cwd then
			local f = io.open("/tmp/bento-cwd", "w")
			if f then
				f:write(tostring(cwd))
				f:close()
			end
		end
	end)
end

return { setup = setup }
