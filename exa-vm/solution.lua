--A parser for .solution files
--[[Based on the following community's documentation:
- https://ramilego4game.github.io/TEC-Redshift-Disk-Specification/
- https://www.reddit.com/r/exapunks/comments/973luq/current_solution_file_format/
]]

local root_module = string.sub(...,1,-1-string.len("solution"))

--Require some libraries
local class = require(root_module..".middleclass")
local utils = require(root_module..".utilities")

--Require some classes
local EXA = require(root_module..".exa")

local solution = class('exa-vm.Solution')

function solution:initialize()
	self.version = 1007 --The save file version ?

	self.level_id = "PB039" --The internal EXAPUNKS level ID.
	--Defaults to the TEC Homebrew (Sandbox) level.

	self.name = "NEW SOLUTION 1" --The solution name.

	self.competition_wins = 0 --The competition wins count, in battle levels.
	--completely useless for a VM.

	self.redshift_size = 0 --The size of the Redshift game solution, it's the sum of functional instructions count of all the starting EXAs.
	--The NOTE and DATA instructions are not counted.

	self.win_statistics = {} --The win statistics, empty when not won, or if non-standard.
	--Completely useless for a VM.
	--When the solution is won, this table would have those keys and values:
	--[cycles]: number, the won cycles count.
	--[size]: the size of the solution, it's the sum of functional instructions count of all the starting EXAs.
	--[activity]: the activity count.

	self.starting_exas = {} --The exa instances used when starting the solution execution.
	--Move instances could be created during execution using the REPL instruction.
end

--Used for decoding and encoding .solution files.
local win_statistics_keys = {"cycles","size","activity";cycles=0,size=1,activity=2}

--Decode EXAPUNKS .solution save file.
--file (io file instance): The save file object open in rb mode !
function solution:decode(file)
	self.version = utils.readInt32(file)
	self.level_id = utils.readString(file)
	self.name = utils.readString(file)
	self.competition_wins = utils.readInt32(file)
	self.redshift_size = utils.readInt32(file)

	local win_statistics_length = utils.readInt32(file)
	self.win_statistics = {}
	for i=1, win_statistics_length do
		local key = win_statistics_keys[utils.readInt32(file)+1]
		self.win_statistics[key] = utils.readInt32(file)
	end

	local starting_exas_count = utils.readInt32(file)
	self.starting_exas = {}
	for i=1, starting_exas_count do
		self.starting_exas[i] = EXA(file)
	end
end

--Encode EXAPUNKS .solution save file.
--file (io file instance): The save file object open in wb mode !
function solution:encode(file)
	utils.writeInt32(file,self.version)
	utils.writeString(file,self.level_id)
	utils.writeString(file,self.name)
	utils.writeInt32(file,self.competition_wins)
	utils.writeInt32(file,self.redshift_size)
	utils.writeInt32(file,#self.win_statistics)
	for k,v in pairs(self.win_statistics) do
		utils.writeInt32(file,win_statistics_keys[k])
		utils.writeInt32(file,v)
	end
	utils.writeInt32(file,#self.starting_exas)
	for i=1, #self.starting_exas do
		self.starting_exas[i]:encode(file)
	end
end

return solution