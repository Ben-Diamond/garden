-- StarterPlayer -> StarterPlayerScripts
local mover = {}
--we will create a class mover that has functions and attributes
local player = game:GetService("Players").LocalPlayer
local mouse = player:GetMouse()
local mouseMover
local RepSto = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local build = require(script.Parent.builderModule)
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local positionsModule = require(RepSto.positionsModule)
local raycastParams = RaycastParams.new()
local Tweens = game:GetService("TweenService")
local halfPi = math.pi/2
local cancelButton = player.PlayerGui:WaitForChild("ScreenGui").cancel


function mover:MouseFunction()
	local targ = mouse.Target
	if targ~= nil and targ:IsA("BasePart") and targ.Parent and targ.Parent:IsA("Model") and targ.Parent.Parent == self.plot.objects then --part should always be "bounds"
		if targ ~= self.selectTarget then 
			self.outline.Adornee = targ.Parent
			self.selectTarget = targ.Parent
		end
	else
		self.outline.Adornee = nil 
		self.selectTarget = nil
	end
end

mover.__index= mover
function mover.new(plot: Model)
	local self = setmetatable({
		plot = plot,
		builder = nil,
		selectTarget = nil,
		outline = RepSto.SelectionBox:Clone(),
		selectCopy = nil,
		oldRotation = 0,



	},mover)
	self.outline.Parent = workspace
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	RunService:BindToRenderStep("select",Enum.RenderPriority.Camera.Value,function(...)self:MouseFunction() end )
	
	ContextActionService:BindAction("select",function(...)self:Select(...)end,false,Enum.UserInputType.MouseButton1) --click = select
	return self
end



function mover:Select(_,state,_)
	if state ~= Enum.UserInputState.Begin then return end
	if self.selectTarget == nil then return end
	local tile = positionsModule.getTile(CFrame.new(self.selectTarget.PrimaryPart.Position),self.plot)
	--self.selectTarget = nil
	
	self.selectCopy = self.selectTarget:Clone()
	RepSto.functions.removeObject:InvokeServer(self.selectTarget,true)
	self.builder = build.new(self.plot,self.selectCopy)
	self.oldRotation = player.buildParts[tile.X][tile.Y].object:GetAttribute("rotation")
	for _, part in self.selectCopy:GetDescendants() do --all the parts in
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false --stops raycasting
			part.Transparency = 1 - 0.5*(1-part.Transparency) --half as opaque
		end
	end
	self.selectCopy.Parent = workspace
	--self.selectCopy.Parent = workspace --?
	RunService:UnbindFromRenderStep("select")
	self.outline.Adornee = nil
	self.selectTarget = nil
	cancelButton.Visible = true
end

function mover:ConfirmMove()
	RunService:BindToRenderStep("select",Enum.RenderPriority.Camera.Value,function(...)self:MouseFunction()end)
	cancelButton.Visible = false
	self.selectCopy:Destroy()
	self.selectCopy = nil
	self.builder:Destroy()
end

function mover:CancelMove()
	RunService:BindToRenderStep("select",Enum.RenderPriority.Camera.Value,function(...)self:MouseFunction() end )
	cancelButton.Visible = false
	--if self.builder then self.builder:CancelMove() end
	
	--try to replace the clone
	
	if self.builder then 
		if self.selectCopy ~= nil then
			local tile = positionsModule.getTile(CFrame.new(self.selectCopy.PrimaryPart.Position),self.plot)
			RepSto.functions.tryPlace:InvokeServer(tile
				,self.selectCopy.Name,"object",self.oldRotation, "Movement cancelled"
			)
			--player tile name type rotation
			--self.builder:Destroy()              this gets done in confirm move
			--self.selectCopy:Destroy()
			--self.selectCopy = nil
		end
	
	end
end

function mover:Destroy() print("luix")
	self:CancelMove()
	self.outline.Adornee = nil
	RunService:UnbindFromRenderStep("select")
end

return mover
--USE	 MOUSE.TARGET AND THE POSMODULE OF OBJECT PRIMARY PART
--when moving, transparent the object only on our side. then, either cancel (cancel function will be big)
--or, when submitting to server, send original location and new location. server will check if tile is free and if there is a "tail" of the original in the desired locaiton, if 
--so then we are ok.
--create a builer instance INSIDE this one
