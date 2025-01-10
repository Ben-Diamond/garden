local RepSto = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local storageModule = require(script.Parent.storageModule)
local spawnModule = require(script.Parent.spawnModule)
local positionsModule = require(RepSto.positionsModule)






--dont need to calculate corner1 just put a part there and use that position... (i commented out bit that creates part)



Players.PlayerAdded:Connect(storageModule.load)
Players.PlayerRemoving:Connect(storageModule.save)
game:BindToClose(storageModule.waitSave)

RepSto.functions.getPlot.OnServerInvoke = spawnModule.getPlot
RepSto.functions.tryPlace.OnServerInvoke = function(player: Player, tile: Vector2, name: StringValue, itemType: StringValue, rotation: IntValue, message:StringValue)--, moving: Model | BoolValue
	print("TRYING TO PLACE:",player,tile,name,itemType,rotation,message)
	local valid =  positionsModule.validateAllTiles(player,tile,
		RepSto.info[name].tiles:GetChildren(),itemType,rotation
	)
	if valid then
	local plot = workspace.plots[player.UserId]
	local centre = plot.base.Position
	--yippee
	--would do inventory checks and such
	local clone = RepSto[`{itemType}s`][name]:Clone() --naming conventions be like
	clone:PivotTo(positionsModule.calculateTilePositions(plot)[tile.X][tile.Y] * CFrame.Angles(0,rotation,0)) --please
	--workspace.plots
	if itemType == "floor" then --get rid of the one that is there
		for _,floor in plot.floors:GetChildren() do
			if positionsModule.getTile(floor.PrimaryPart.CFrame,plot) == tile then
				floor:Destroy() break
			end
		end
	end
	
	clone.Parent = plot[`{itemType}s`]
	
	for _,t in RepSto.info[name].tiles:GetChildren() do --now add dummy parts
		if t ~= Vector3.new(0,0,0) then
			local currentTile = positionsModule.getRotatedTile(tile,t.Value,rotation)
			player.buildParts[currentTile.X][currentTile.Y][itemType].Value = "tail"
		end
	end
	player.buildParts[tile.X][tile.Y][itemType].Value = name
	player.buildParts[tile.X][tile.Y][itemType]:SetAttribute("rotation",rotation)
		
	RepSto.functions.tryPlace:InvokeClient(player,true,clone)
	RepSto.events.alert:FireClient(player,message,"green",1)
	--if	player.PlayerGui.ScreenGui.messageFolder:FindFirstChild("messageBox") then print("GAH! serv") end
	
else
	RepSto.functions.tryPlace:InvokeClient(player,false,nil)
	RepSto.events.alert:FireClient(player,message,"red",1)

	end
end
RepSto.functions.removeObject.OnServerInvoke = function(player: Player, object: Model, moving: BoolValue)
	--check they have that object
	local tile = positionsModule.getTile(CFrame.new(object.PrimaryPart.Position),workspace.plots[player.UserId],nil)
	if player.buildParts[tile.X][tile.Y].object.Value == object.Name then --works
		--remove all of them
		for _,t in RepSto.info[object.Name].tiles:GetChildren() do
			local tail = positionsModule.getRotatedTile(tile,t.Value,player.buildParts[tile.X][tile.Y].object:GetAttribute("rotation"))
			player.buildParts[tail.x][tail.Y].object.Value = ""  --as opposed to "tail"	
		end
		if not moving then RepSto.events.alert:FireClient(player,`Destroyed {RepSto.info[object.Name].displayName.Value}`,"green",1) end

		object:Destroy()
	end
	

end


RepSto.events.reset.OnServerEvent:Connect(function(player)print("the great reset")
	if storageModule.reset(player,spawnModule.getPlot(player)) then
		RepSto.events.alert:FireClient(player,"Reset Land","green",1.2)
	end
end)
