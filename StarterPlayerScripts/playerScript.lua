-- StarterPlayer -> StarterPlayerScripts
local player = game:GetService("Players").LocalPlayer
local RepSto = game:GetService("ReplicatedStorage")
local build = require(script.Parent.builderModule)
local moveModule = require(script.Parent.moverModule)
local deleteModule = require(script.Parent.deleterModule)
local builder = nil
local mover = nil
local luix = nil
local positionsModule = require(RepSto.positionsModule)
local Tweens = game:GetService("TweenService") 
local menu = player.PlayerGui:WaitForChild("ScreenGui").menu
local move = player.PlayerGui.ScreenGui.move
local delete = player.PlayerGui.ScreenGui.delete
local numbers = {-10,-7,-5,-3,4,6,8,12}
local tab = nil
local cancelButton = player.PlayerGui.ScreenGui.cancel
local moveTween =  Tweens:Create(move.UIGradient,TweenInfo.new(5,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1,false,0),{Offset=Vector2.new(1,1)})
local menuTween = Tweens:Create(menu.UIGradient,TweenInfo.new(5,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1,false,0),{Offset=Vector2.new(1,1)})
local deleteTween = Tweens:Create(delete.UIGradient,TweenInfo.new(5,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1,false,0),{Offset=Vector2.new(1,1)})
local plot = RepSto.functions.getPlot:InvokeServer()

menuTween:Play()
local tilePositions = nil

local function setAction(action) --"build" is for when we were building -> are building, "" is used for when we stop doing something (including build)
	print("ACTION",action)
	if action == "move" then
		Tweens:Create(move,TweenInfo.new(0.2),{Size=UDim2.new(0.075,0,0.16,0)}):Play()
		moveTween:Play()
		cancelButton.Visible = false
		
		Tweens:Create(menu,TweenInfo.new(0.2),{BackgroundTransparency=0.5}):Play()
		menuTween:Pause() menu.UIGradient.Offset = Vector2.new(-1,-1)
		Tweens:Create(menu.info,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(1,0,0,0)}):Play()
		
		if luix ~= nil then luix:Destroy() luix = nil
			deleteTween:Pause() delete.UIGradient.Offset = Vector2.new(-1,-1)
			Tweens:Create(delete,TweenInfo.new(0.2),{Size=UDim2.new(0.062,0,0.141,0)}):Play()
		end
	
	elseif action == "delete" then
		Tweens:Create(delete,TweenInfo.new(0.2),{Size=UDim2.new(0.075,0,0.16,0)}):Play()
		deleteTween:Play()
		cancelButton.Visible = true
		
		Tweens:Create(menu,TweenInfo.new(0.2),{BackgroundTransparency=0.5}):Play()
		menuTween:Pause() menu.UIGradient.Offset = Vector2.new(-1,-1)
		Tweens:Create(menu.info,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(1,0,0,0)}):Play()
		
		if mover ~= nil then mover:Destroy() mover = nil
			moveTween:Pause() move.UIGradient.Offset = Vector2.new(-1,-1)
			Tweens:Create(move,TweenInfo.new(0.2),{Size=UDim2.new(0.062,0,0.141,0)}):Play()
		end
		
	elseif action == "build" or action == "" then--the default
		Tweens:Create(menu,TweenInfo.new(0.2),{BackgroundTransparency=0}):Play()
		menuTween:Play()
		
		
		if luix ~= nil then luix:Destroy() luix = nil 
			deleteTween:Pause() delete.UIGradient.Offset = Vector2.new(-1,-1)
			Tweens:Create(delete,TweenInfo.new(0.2),{Size=UDim2.new(0.062,0,0.141,0)}):Play()
		end

		if mover ~= nil then mover:Destroy() mover = nil
			moveTween:Pause() move.UIGradient.Offset = Vector2.new(-1,-1)
			Tweens:Create(move,TweenInfo.new(0.2),{Size=UDim2.new(0.062,0,0.141,0)}):Play()
		end
		
	end
	if builder ~= nil and builder.ghost and tab == builder.itemType then
		Tweens:Create(menu[builder.itemType][builder.ghost.Name].Frame,TweenInfo.new(0.2),{Size=UDim2.new(0.8,0,0.8,0)}):Play()
	end
	if action ~= "build" and builder ~= nil then
		builder:Destroy() builder = nil
	end
end

local function setDesc(name)
	Tweens:Create(menu.info,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(1, 0,0.146, 0)}):Play()
	local tw = Tweens:Create(menu.info.itemName.TextLabel,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{Size=UDim2.new(0,0,0,0)})
	tw:Play()
	tw.Completed:Connect(function()
		menu.info.itemName.TextLabel.Text = if name ~= "" then RepSto.info[name].displayName.Value else ""
		Tweens:Create(menu.info.itemName.TextLabel,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0),{Size=UDim2.new(1,0,1,0)}):Play()
	end)
end
local function removeDesc()
	Tweens:Create(menu.info,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(1, 0,0, 0)}):Play()
end

plot.ghost.childAdded:Connect(function(ghost)setDesc(ghost.Name)end)
plot.ghost.ChildRemoved:Connect(function() removeDesc()
end)



local function selectA(item,itemInfo) 
	--if mover then mover:Destroy() mover=nil end
	if builder == nil then
		setAction("build")
		cancelButton.Visible = true

		builder = build.new(plot,nil)
		tilePositions = positionsModule.calculateTilePositions(plot,nil)
		

	elseif builder.ghost.Name == item.Name then

		--deselect
		setAction("build")
		cancelButton.Visible = false
		builder:Destroy() builder = nil
		return
	else
		setAction("build")
	end
	
	builder:SetItem(item.Name)
	Tweens:Create(item.Frame,TweenInfo.new(0.2),{Size=UDim2.new(0.9,0,0.9,0)}):Play()
end

for x,item in RepSto.info:GetChildren() do
	local clone = RepSto.gui.itemTemplate:Clone()
	clone.Name = item.Name
	clone.Frame.ImageButton.Image = `rbxthumb://type=Asset&id={item.assetID.Value}&w=420&h=420`
	clone.Frame.Size=UDim2.new(0,0,0,0)
	--if item.itemType.Value == "floor" then clone.
	clone.Parent = menu[item.itemType.Value]
	local n = numbers[math.random(#numbers)]
	clone.MouseEnter:Connect(function()
		Tweens:Create(clone.Frame,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{Rotation = n}):Play()
		if not builder and not mover and not luix and tab == item.itemType.Value then setDesc(clone.Name) end
	end)
	clone.MouseLeave:Connect(function()
		Tweens:Create(clone.Frame,TweenInfo.new(0.2,Enum.EasingStyle.Quad),{Rotation = 0}):Play()
		--removeDesc()
		--setDesc("")
	end)
	clone.Frame.ImageButton.MouseButton1Click:Connect(function()
		selectA(clone,item)
	end)
end


local function changeTab(new)
	if tab == new then return end
	if tab~= nil then for i,item in menu[tab]:GetChildren() do
		if item:IsA("Frame") then
			Tweens:Create(item.Frame,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In,0,false,0.1*(i-1)),{Size=UDim2.new(0,0,0,0)}) :Play()
		end
	end Tweens:Create(menu.tabs[tab],TweenInfo.new(0.3),{BackgroundTransparency=1}):Play() end
	tab = new
	Tweens:Create(menu.tabs[tab],TweenInfo.new(0.3),{BackgroundTransparency=0.77}):Play()
	for i, item in menu[new]:GetChildren() do
		if item:IsA("Frame") then
			if builder and builder.ghost and builder.ghost.Name == item.Name then--if we have selected an item and it needs to be bigger
				Tweens:Create(item.Frame,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0.1 + 0.1*i),{Size=UDim2.new(0.9,0,0.9,0)}) :Play()
			else
				Tweens:Create(item.Frame,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,0.1 + 0.1*i),{Size=UDim2.new(0.8,0,0.8,0)}) :Play()
			end
		end
	end
end

move.TextButton.MouseButton1Click:Connect(function()
	if mover == nil then
		setAction("move")
		mover = moveModule.new(plot)
		mover.outline:GetPropertyChangedSignal("Adornee"):Connect(function() 
			if mover.outline.Adornee == nil then if mover.builder == nil then removeDesc() end else setDesc(mover.outline.Adornee.Name) end end)
	else
		setAction("")
		cancelButton.Visible = false
	end
end)
cancelButton.TextButton.MouseButton1Click:Connect(function()
	cancelButton.Visible = false
	if mover ~= nil then
		setAction("move")
		mover:CancelMove()
	elseif builder ~= nil then
		setAction("")
	elseif luix ~= "nil" then
		setAction("")
	end
end)

delete.TextButton.MouseButton1Click:Connect(function()
	if luix == nil then
		setAction("delete")
		luix = deleteModule.new(plot)
		luix.outline:GetPropertyChangedSignal("Adornee"):Connect(function()
			if luix then if luix.outline.Adornee == nil then removeDesc() else setDesc(luix.outline.Adornee.Name) end  end end)
	else
		setAction("")
		cancelButton.Visible = false
	end
end)

local function ffffffffffffffff()
menu.tabs.object.TextButton.MouseButton1Click:Connect(function()
	changeTab("object")
end)
menu.tabs.object.MouseEnter:Connect(function() if tab ~= "object" then
	Tweens:Create(menu.tabs.object,TweenInfo.new(0.15),{BackgroundTransparency=0.9}):Play() end
end)menu.tabs.object.MouseLeave:Connect(function() if tab ~= "object" then
		Tweens:Create(menu.tabs.object,TweenInfo.new(0.15),{BackgroundTransparency=1}):Play() end
end)
menu.tabs.floor.TextButton.MouseButton1Click:Connect(function()
	changeTab("floor")
end)
menu.tabs.floor.MouseEnter:Connect(function() if tab ~= "floor" then
		Tweens:Create(menu.tabs.floor,TweenInfo.new(0.15),{BackgroundTransparency=0.9}):Play() end
end)menu.tabs.floor.MouseLeave:Connect(function() if tab ~= "floor" then
		Tweens:Create(menu.tabs.floor,TweenInfo.new(0.15),{BackgroundTransparency=1}):Play() end
end)

move.MouseEnter:Connect(function()
	Tweens:Create(move.ImageLabel,TweenInfo.new(0.2),{Size=UDim2.new(0.9,0,0.9,0)}):Play()
end)move.MouseLeave:Connect(function()
	Tweens:Create(move.ImageLabel,TweenInfo.new(0.2),{Size=UDim2.new(0.8,0,0.8,0)}):Play()
	end)delete.MouseEnter:Connect(function()
		Tweens:Create(delete.ImageLabel,TweenInfo.new(0.2),{Size=UDim2.new(0.675,0,0.9,0)}):Play()
	end)delete.MouseLeave:Connect(function()
		Tweens:Create(delete.ImageLabel,TweenInfo.new(0.2),{Size=UDim2.new(0.6,0,0.8,0)}):Play()
	end)
end ffffffffffffffff()



RepSto.functions.tryPlace.OnClientInvoke = function(confirm,obj)

	if confirm == true then
		if builder then   
			builder:AddRaycastParam(obj)
			else
  
			mover:ConfirmMove()


			end
	else
		print("sad!") --when i make gui
	end
end


plot.objects.ChildAdded:Connect(function(obj)
	for _, part in obj:GetDescendants() do print("myth confirmed")--all the parts in
		if part:IsA("BasePart") then print("based")
			local pos = part.Position
			part.Position = Vector3.new(pos.X,pos.Y+1.5,pos.Z)
			--local transp = part.Transparency
			--part.Transparency = 1 - 0.5*(1-transp) --half as opaque
			Tweens:Create(part,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false),{Position = pos}):Play()
		end
	end
end)


plot.floors.ChildAdded:Connect(function(floor)
	
	--for now all floors just have one "Part"
	local part = floor:WaitForChild("Part",1)
		local pos = part.Position
		part.Position = Vector3.new(pos.X,pos.Y+1.5,pos.Z)
		--local transp = part.Transparency
		--part.Transparency = 1 - 0.5*(1-transp) --half as opaque
		Tweens:Create(part,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false),{Position = pos}):Play()
end)




RepSto.events.alert.OnClientEvent:Connect(function(message: StringValue, colour: StringValue, duration: NumberValue)
	positionsModule.alert(player,message,colour,duration)	
end)


player.PlayerGui.ScreenGui.reset.TextButton.MouseButton1Click:Connect(function()
	RepSto.events.reset:FireServer()
end)
