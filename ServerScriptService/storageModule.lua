local playersLeft = Instance.new("NumberValue")
local spawnModule = require(script.Parent.spawnModule)
local DataStore = game:GetService("DataStoreService")
local plotStore = DataStore:GetDataStore("PlotStore")
local Players = game:GetService("Players")
local RepSto = game:GetService("ReplicatedStorage")
local positionsModule = require(RepSto.positionsModule)

local function makeVar(name:StringValue, dataType: type, val, parent: Instance)
	local var = Instance.new(dataType)
	var.Name = name
	if val ~= nil then var.Value = val end
	var.Parent = parent
	return var
end

local function initialise(player: Player)
	local objects = {}
	local floors = {}
	local objectRotations = {}
	local floorRotations = {}
	local plotSize = Vector2.new(10,10)
	for x=1, plotSize.X do
		objects[x] = {}
		objectRotations[x] = {}
		floorRotations[x] = {}
		floors[x] = {}
		for y=1, plotSize.Y do
			objects[x][y] = ""
			floors[x][y] = "default"
			objectRotations[x][y] = 0
			floorRotations[x][y] = 0
		end
	end
	local data = {objects = objects,floors = floors, objectRotations = objectRotations, floorRotations = floorRotations}
	local success, errorMessage = pcall(function()
		plotStore:SetAsync(player.UserId,data)
	end)

	if not success then warn(errorMessage) end
	return data
end



local function formatData(player: Player)
	--player looks like
	--buildParts
	  --1
		 --1
			--floor="wood1" rotation=0
		--2
			--floor="wood1" rotation=0,object="chair1" rotation=pi/2
	--we want to make it into tables to store it
	local parentFolder = player.buildParts
	local objects = {} --we add to these
	local floors = {}
	local objectRotations = {}
	local floorRotations = {}
	local plotSize = Vector2.new(10,10) --would be stored in the player
	for x=1,plotSize.X do
		local folder = parentFolder[x]
		objects[x] = {}
		floors[x] = {}
		objectRotations[x] = {}
		floorRotations[x] = {}
		for y=1,plotSize.Y do
			objects[x][y] = parentFolder[x][y].object.Value
			objectRotations[x][y] = parentFolder[x][y].object:GetAttribute("rotation")
			floors[x][y] = parentFolder[x][y].floor.Value
			floorRotations[x][y] = parentFolder[x][y].floor:GetAttribute("rotation")
		end
	end

	return {objects = objects, floors = floors, objectRotations = objectRotations, floorRotations = floorRotations}
end

local module = {}


function module.reset(player: Player,plot: Model)
	local data = initialise(player)
	local plotSize = Vector2.new(10,10)
	for _,obj in plot.objects:GetChildren() do
		obj:Destroy()
	end
	for _,floor in plot.floors:GetChildren() do
		floor:Destroy()
	end
	local positions = positionsModule.calculateTilePositions(plot,nil)
	for x=1,plotSize.X do
		for y=1,plotSize.Y do
			local folder2 = player.buildParts[x][y]
			folder2.object.Value = ""
			folder2.object:SetAttribute("rotation",0)
			folder2.floor.Value = "default"
			folder2.floor:SetAttribute("rotation",0)
			--place the floor
			local clone = RepSto.floors.default:Clone() --lol
			clone:PivotTo(positions[x][y])
			clone.Parent = plot.floors

		end
	end
	return true
end


function module.load(player: Player)
	local success, data = pcall(function()
		return plotStore:GetAsync(player.UserId)
	end)
	if not success then warn(data) playersLeft.Value += 1 return end


	if not Players:GetPlayerByUserId(player.UserId) then --they have left quickly
		return
	end
	if false or data == nil then
		data = initialise(player)
	end
	local plot = spawnModule.spawnPlot(player)

	print("there is stored",data)
	--local floors = {
	--	[1] = {"default","default","default","default","default","default","default","default","default","default"},
	--	[2] = {"default","default","default","default","default","default","default","default","default","default"},
	--	[3] = {"default","default","default","default","default","default","default","default","default","default"},
	--	[4] = {"default","default","default","default","default","default","default","default","default","default"},
	--	[5] = {"default","default","default","default","default","default","default","default","default","default"},
	--	[6] = {"default","default","default","default","default","default","default","default","default","default"},
	--	[7] = {"default","default","default","default","default","default","default","default","default","default"},
	--	[8] = {"default","default","default","default","default","default","default","default","default","default"},
	--	[9] = {"default","default","default","default","default","default","default","default","default","default"},
	--	[10] = {"wood1","wood1","wood1","wood1","wood1","wood1","wood1","wood1","wood1","wood1"}
	--}
	--local objects = {
	--	[1] = {"","","","","chair1","","","","",""},
	--	[2] = {"","","","","","","","","",""},
	--	[3] = {"","","","","","","","","",""},
	--	[4] = {"","","","","","","","","",""},
	--	[5] = {"","","","","","","","","",""},
	--	[6] = {"","","","","","","","","",""},
	--	[7] = {"","","","","","","","","",""},
	--	[8] = {"","","","","","","","","",""},
	--	[9] = {"","","","","","","","","",""},
	--	[10] = {"","","","","","","","","",""},
	--}
	local objects = data.objects
	local floors = data.floors
	local objectRotations = data.objectRotations
	local floorRotations = data.floorRotations
	
	local plotSize = Vector2.new(10,10) --could vary
	local parentFolder = makeVar("buildParts","Folder",nil,player)
	for x = 1,plotSize.X do
		local folder = makeVar(x,"Folder",nil,parentFolder)
		for y=1,plotSize.Y do
			local folder2 = makeVar(y,"Folder",nil,folder)
			--we make folders
			makeVar("object","StringValue",objects[x][y],folder2)
			folder2.object:SetAttribute("rotation",objectRotations[x][y])
			makeVar("floor","StringValue",floors[x][y],folder2)
			folder2.floor:SetAttribute("rotation",floorRotations[x][y])

		end
	end
	
	local positions = positionsModule.calculateTilePositions(plot,nil)
	local clone
	for x=1,plotSize.X do
		for y=1,plotSize.Y do --now make the things appear
			clone = RepSto.floors[parentFolder[x][y].floor.Value]:Clone() --lol
			clone:PivotTo(positions[x][y]*CFrame.Angles(0,floorRotations[x][y],0))
			clone.Parent = plot.floors
			
			if player.buildParts[x][y].object.Value ~= "" and player.buildParts[x][y].object.Value ~= "tail" then
				clone = RepSto.objects[parentFolder[x][y].object.Value]:Clone()
				clone:PivotTo(positions[x][y]*CFrame.Angles(0,objectRotations[x][y],0))
				clone.Parent = plot.objects
			end
		end
	end
	
	playersLeft.Value += 1


end
function module.save(player: Player)
	local plot = spawnModule.getPlot(player)
	if not plot or not plot:IsDescendantOf(workspace) then playersLeft.Value -= 1 return end --shame

	--local data = formatCFrames(plot)
	local data = formatData(player)
	plot:Destroy()
	spawnModule.relinquish(player)
	local success, errorMessage = pcall(function()
		plotStore:SetAsync(player.UserId,{objects = data.objects,floors = data.floors, objectRotations = data.objectRotations, floorRotations = data.floorRotations}) --save their stuff
	end)

	if not success then warn(errorMessage) end

	playersLeft.Value -= 1

end

function module.waitSave()
	while playersLeft.Value > 0 do playersLeft.Changed:Wait()
	end
end



return module