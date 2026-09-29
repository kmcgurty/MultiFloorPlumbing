local function log(...)
	local count = select("#", ...)
	local args = {}

	for i = 1, count do
		args[i] = tostring(select(i, ...))
	end

	DebugLog.log("[MultiFloorPlumbing] " .. table.concat(args, " "))
end

return log
