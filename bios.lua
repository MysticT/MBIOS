-- MBIOS

-- Paths to search for boot files
local tBootPaths = {
"/rom/boot",
"/boot"
}

-- Wheter to load boot files from disks or not
local bBootFromDisk = true

-- Paths to search for boot files in disks
local tDiskBootPaths = {
"/boot"
}

-- Version string
local sVersion = "MBIOS 1.1"

-- Protect string metatable

local strMeta = getmetatable("")
if type(strMeta) == "table" then
	strMeta.__metatable = "string"
end

-- Local functions

-- clear function:
-- clears the screen and sets the cursor to the top-left corner
local function clear()
	term.clear()
	term.setCursorPos(1, 1)
end

-- write function:
-- writes the given text to the screen on the specified line
local function write(y, s)
	-- set the cursor position
	term.setCursorPos(1, y)
	-- write the text
	term.write(s)
end

-- boot function:
-- loads a boot file as a function and then calls it
local function boot(sPath)
	-- open the file
	local file = fs.open(sPath, "r")
	-- if the file is open
	if file then
		-- read the file contents and load it as a function
		local func, err = loadstring(file.readAll(), fs.getName(sPath))
		-- close the file handle
		file.close()
		-- if the function was loaded correctly
		if func then
			-- make a protected call in case of error
			return pcall(func)
		else
			-- return false to indicate the error and the error message
			return false, err
		end
	end
	-- error opening the file
	return false, "Error opening file "..sPath
end

-- getBootFiles function:
-- searches a directory for boot files
local function getBootFiles(sPath, tList)
	-- for each entry in the directory
	for _,name in ipairs(fs.list(sPath)) do
		-- get the full path to the file/directory
		local path = fs.combine(sPath, name)
		-- check if it's a file
		if not fs.isDir(path) then
			-- add the path to the list
			tList[#tList + 1] = path
		end
	end
end

-- The list of boot files
local tList = {}

-- Get every boot file on the specified paths
for i = 1, #tBootPaths do
	-- check if it's a directroy
	if fs.exists(tBootPaths[i]) and fs.isDir(tBootPaths[i]) then
		-- check for boot files
		getBootFiles(tBootPaths[i], tList)
	end
end
-- Get boot files from disks
if bBootFromDisk then
	-- for each side
	for _,side in ipairs(rs.getSides()) do
		-- check if there's a disk drive
		if peripheral.isPresent(side) and peripheral.getType(side) == "drive" then
			-- check if it has a floppy disk
			if peripheral.call(side, "hasData") then
				for i = 1, #tDiskBootPaths do
					local sDiskPath = fs.combine(peripheral.call(side, "getMountPath"), tDiskBootPaths[i])
					-- check if it's a directroy
					if fs.exists(sDiskPath) and fs.isDir(sDiskPath) then
						-- check for boot files
						getBootFiles(sDiskPath, tList)
					end
				end
			end
		end
	end
end

if #tList == 0 then
	-- No boot file found, let the user know
	write(1, "No boot file found.")
	write(2, "Press any key to shutdown")
	coroutine.yield("key")
elseif #tList == 1 then
	-- Only one boot file, load it
	boot(tList[1])
else
	-- More than one boot file, let the user choose one
	-- currently selected option
	local nSelected = 1
	-- scroll amount
	local nScroll = 0
	-- get the terminal size
	local w, h = term.getSize()
	-- redraw function: redraws the menu
	local function redraw()
		-- clear the screen
		clear()
		-- print the boot loader version
		write(1, sVersion)
		-- print the options
		for i = 1, math.min(#tList, h - 1) do
			if i + nScroll == nSelected then
				write(i + 1, ">"..tList[i + nScroll])
			else
				write(i + 1, " "..tList[i + nScroll])
			end
		end
	end
	while true do
		-- redraw the menu
		redraw()
		-- get a key press
		local evt, k = coroutine.yield("key")
		if k == 28 then -- Enter
			-- clear the screen
			clear()
			-- load the boot file
			local ok, err = boot(tList[nSelected])
			-- check if there was an error
			if not ok then
				-- show the error
				write(1, err)
				write(2, "Press any key to continue")
				coroutine.yield("key")
			end
			-- stop the loop
			break
		elseif k == 200 then -- Up
			-- Move the cursor up
			if nSelected > 1 then
				nSelected = nSelected - 1
				if nSelected == nScroll then
					nScroll = nScroll - 1
				end
			else
				nSelected = #tList
				if #tList >= h then
					nScroll = #tList - (h - 1)
				end
			end
		elseif k == 208 then -- Down
			-- Move the cursor down
			if nSelected < #tList then
				nSelected = nSelected + 1
				if nSelected - nScroll >= h then
					nScroll = nScroll + 1
				end
			else
				nSelected = 1
				nScroll = 0
			end
		end
	end
end

os.shutdown() -- just in case