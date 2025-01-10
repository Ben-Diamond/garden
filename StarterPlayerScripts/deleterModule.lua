-- StarterPlayer -> StarterPlayerScripts
local builder = {}
--we will create a class builder that has functions and attributes
local player = game:GetService("Players").LocalPlayer
local RepSto = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local cam = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local positionsModule = require(RepSto.positionsModule)
local raycastParams = RaycastParams.new()
local Tweens = game:GetService("TweenService")
local halfPi = math.pi/2

local function mouseRay(): CFrame | BoolValue
	local mouseLocation = UserInputService:GetMouseLocation()
	local ray = cam:ViewportPointToRay(mouseLocation.X,mouseLocation.Y)

	local cast = workspace:Raycast(ray.Origin,ray.Direction * 200,raycastParams)
	if cast and cast.Position then return CFrame.new(cast.Position) end
	return false --sad!
end


builder.__index= builder
function builder.new(plot: Model, moving: Model | BoolValue)
	local self = setmetatable({
		plot = plot,
		corner1 = 	plot.corner1.Position,
		ghost = nil,
		tile = Vector2.new(-1,-1),
		rotation = 0,
		targetCF = CFrame.new(0,0,0),
		itemType = nil,tileTarget = RepSto.tileTarget:Clone(),
		moving = moving
		
		
	},builder)

	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local exclusions = player.Character:GetChildren() --exclude the player
	for _,o in workspace.plots[player.UserId].objects:GetChildren() do table.insert(exclusions,o) end
	raycastParams.FilterDescendantsInstances = exclusions
	
	--setting the filters here because nothing exists when the module is initialised
	
	ContextActionService:BindAction("place",function(...)self:PlaceObject(...)end,false,Enum.UserInputType.MouseButton1) --click = place
	ContextActionService:BindAction("rotate",function(...)self:RotateGhost(...)end,false,Enum.KeyCode.R) --r = rotate

	RunService:BindToRenderStep("ghost",Enum.RenderPriority.Camera.Value,function(...)self:MoveGhost() end )
	--could be made more efficient by using mouse target (like mover module), if its a floor tile (can get coords by parent name or make an attribute) set tile there
	
	
	if moving then
		--when attemting to place...
		self.tile = positionsModule.getTile(moving.PrimaryPart.CFrame,plot)
		self.rotation = player.buildParts[self.tile.X][self.tile.Y].object:GetAttribute("rotation")
		self.targetCF = CFrame.new(self.corner1.X + 4*(self.tile.X) - 2,self.corner1.Y + if self.itemType=="floor" then 0.2 else 0,self.corner1.Z + 4*(self.tile.Y) - 2)

		self:SetItem(moving.Name)
	else
		self.targetCF = CFrame.new(self.corner1.X + 4*(self.tile.X) - 2,self.corner1.Y + if self.itemType=="floor" then 0.2 else 0,self.corner1.Z + 4*(self.tile.Y) - 2)
	end

	--dont forget to call the thingy ghost
	self.tileTarget.Parent = plot
	return self
end

function builder:PlaceObject(_,state,_) 
	if state ~= Enum.UserInputState.Begin then return end
	if not positionsModule.getTile(mouseRay(),self.plot) then positionsModule.alert(player,"That's not in your land!","red",1.2) return end
	local valid =  positionsModule.validateAllTiles(player,self.tile,
		RepSto.info[self.ghost.Name].tiles:GetChildren(),self.itemType,self.rotation)
	if valid then RepSto.functions.tryPlace:InvokeServer(self.tile,self.ghost.Name,self.itemType,self.rotation,
		if not self.moving then `Placed {RepSto.info[self.ghost.Name].displayName.Value}`
			else `Moved {RepSto.info[self.ghost.Name].displayName.Value}`)
	else
			
		positionsModule.alert(player,"Cannot place there!","red",1.2)
	end
end

function builder:RotateGhost(_,state,_)
	if state ~= Enum.UserInputState.Begin then return end
	self.rotation -= halfPi
	if self.rotation == -2*halfPi then self.rotation = 2*halfPi end
end

function builder:MoveGhost()
	local cf = mouseRay()
	
	if cf ~= false and self.ghost ~= nil then
		local tile = positionsModule.getTile(cf,self.plot)


		if tile then self.tile = tile
			
			self.targetCF = CFrame.new(self.corner1.X + 4*(tile.X) - 2,self.corner1.Y + if self.itemType=="floor" then 0.2 else 0,self.corner1.Z + 4*(tile.Y) - 2)
			self.tileTarget:PivotTo(self.targetCF)

		else self.tileTarget:PivotTo(CFrame.new(0,-1,0)) end
		local _,rotation1,_ = self.ghost:GetPivot():ToOrientation()
		if self.targetCF ~= self.ghost.PrimaryPart.CFrame or rotation1 ~= self.rotation then

			local diff = self.ghost.PrimaryPart.Position - self.targetCF.Position
			local move: CFrame
			if diff.Magnitude >= 0.025 then 
				move = CFrame.new(self.ghost.PrimaryPart.Position -(diff * math.log(diff.Magnitude+1)/(3*diff.Magnitude))) --LOOOOG
			else
				move = self.targetCF
			end
			--the rotation
			local rdiff = rotation1-self.rotation

			if rdiff <-4 then rotation1 +=4*halfPi rdiff += 4*halfPi end --fix overflow
			if rdiff >= 0.005 * halfPi then  
				move *=CFrame.Angles(0,rotation1 - math.log(rdiff+1)/5,0) --yeah
			else
				move *= CFrame.Angles(0,self.rotation,0) --or set rotation to be correct
			end
			self.ghost:PivotTo(move)
		end
		self.ghost.SelectionBox.Color3 = if tile and positionsModule.validateAllTiles(player,self.tile,
			RepSto.info[self.ghost.Name].tiles:GetChildren(),self.itemType,self.rotation
		) then Color3.fromRGB(13, 105, 172) else Color3.fromRGB(255,50,0)
		
	end
end


function builder:SetItem(name): nil
	self.itemType = RepSto.info[name].itemType.Value
	
	if self.ghost ~=nil then self.ghost:Destroy() end
	self.ghost = RepSto[`{self.itemType}s`][name]:Clone()
	for _, part in self.ghost:GetDescendants() do --all the parts in
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false --stops raycasting idk
			part.Transparency = 1 - 0.5*(1-part.Transparency) --half as opaque
		end
	end
	
	local outline = RepSto.SelectionBox:Clone()
	outline.Adornee = self.ghost
	outline.Parent = self.ghost
	
	

	outline.Color3 = if positionsModule.validateAllTiles(player,self.tile,
		RepSto.info[self.ghost.Name].tiles:GetChildren(),self.itemType,self.rotation
	) then Color3.fromRGB(13, 105, 172) else Color3.fromRGB(255,50,0)
	
	--self:MoveGhost()	
	self.ghost.Parent = self.plot.ghost
	self.ghost:PivotTo(self.targetCF*CFrame.Angles(0,self.rotation,0))
	
end

function builder:AddRaycastParam(obj: Model)
	local t = raycastParams.FilterDescendantsInstances
	table.insert(t,obj)
	raycastParams.FilterDescendantsInstances = t
	self.ghost.SelectionBox.Color3 = if positionsModule.validateAllTiles(player,self.tile,
		RepSto.info[self.ghost.Name].tiles:GetChildren(),self.itemType,self.rotation
	) then Color3.fromRGB(13, 105, 172) else Color3.fromRGB(255,50,0)
end

function builder:Destroy()
	--add moving thing
	if self.ghost ~=nil then self.ghost:Destroy() end
	RunService:UnbindFromRenderStep("ghost")
	ContextActionService:UnbindAction("place")
	ContextActionService:UnbindAction("rotate")
	self.tileTarget:Destroy()
end


return builder
