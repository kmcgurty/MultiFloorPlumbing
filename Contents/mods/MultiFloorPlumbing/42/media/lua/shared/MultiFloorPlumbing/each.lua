---@generic T
---@param list table<integer, T> | PZArrayList<T>
---@param fn   fun(value: T, index: integer, list: table<integer, T> | PZArrayList<T>)
local function each(list, fn)
	-- see: https://github.com/xiedacon/lua-utility#Array
	-- check to handle Java arrays (indexed 0)
	if list.size and list.get then
		for i = 0, list:size() - 1 do
			fn(list:get(i), i, list)
		end
	else
		for i, value in ipairs(list) do
			fn(value, i - 1, list)
		end
	end
end

return each
