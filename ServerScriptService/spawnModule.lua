local RepSto = game:GetService("ReplicatedStorage")
local takenSpawners = {}
local plotTemplate = game:GetService("ServerStorage").plotTemplate
local positionsModule = require(RepSto.positionsModule)
local module = {}

function module.spawnPlot(player: Player) : Model
	for _,spawner in workspace.spawners:GetChildren() do
		if takenSpawners[spawner] == nil then
			--give it to them
			takenSpawners[spawner] = player.UserId
			local plot = plotTemplate:Clone()
			plot:PivotTo(spawner.CFrame)
			plot.Name = player.UserId
			plot.Parent = game.Workspace.plots --move this 
			
			
			--here we would get the player data
			
			

			return plot
		end
	end	
end

function module.getPlot(player: Player):Model
	--return takenSpawners[player.UserId]
	return workspace.plots:WaitForChild(player.UserId,5) 
end

function module.relinquish(player: Player)
	for _,spawner in workspace.spawners:GetChildren() do
		if takenSpawners[spawner] == player.UserId then
			--take it away
			takenSpawners[spawner] = nil
			break
		end
	end	
end

return module
