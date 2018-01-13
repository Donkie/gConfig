
local fonti = 0
local function makeFont(tbl)
	local name = "gConfigFont" .. fonti

	tbl.font = tbl.font or "Arial"
	tbl.size = tbl.size or 16
	tbl.weight = tbl.weight or 500

	surface.CreateFont(name, tbl)

	fonti = fonti + 1

	return name
end

local fontButton1 = makeFont({size = 16, weight = 700})
local fontHeader1 = makeFont({size = 26, weight = 600})
local fontConfigItem1 = makeFont({size = 18, weight = 700})
local fontConfigItem2 = makeFont({size = 18, weight = 600})
local fontConfigItem2i = makeFont({size = 18, weight = 600, italic = true})
local fontConfigItem3 = makeFont({size = 14, weight = 500})

local function drawPanelBackground(w, h, clr)
	derma.GetDefaultSkin().tex.Panels.Normal(0, 0, w, h, clr)
end

local function configEditClick(config, configItemId)
	local item = config.items[configItemId]

	-- Setup popup
	local frame = vgui.Create("DFrame")
		frame:SetTitle(string.format("Edit %q", item.name))
		frame:SetSizable(false)
		frame:SetDeleteOnClose(true)
		frame:SetSize(300, 300) -- Set an initial size just so it's not 0, 0 if it breaks
		frame:MakePopup()
		frame.btnMaxim:SetVisible(false)
		frame.btnMinim:SetVisible(false)

	local panel = vgui.Create("Panel", frame)

	local commentEntry = vgui.Create("DTextEntryPlaceholder", frame)
		commentEntry:SetPlaceholderText("Optional Comment")
		commentEntry:SetDrawLanguageID(false)

	local doneBtn = vgui.Create("DButton", frame)
		doneBtn:SetSize(50, 25)
		doneBtn:SetText("Done")

	-- Call the type's gui function
	local currentValue
	if config.data[configItemId] != nil then
		currentValue = config.data[configItemId]
	else
		currentValue = item.default
	end

	local itemType = gConfig.Types[item.type]

	local getValueFunction = itemType.gui(panel, currentValue, item.typeOptions, item)

	-- Update popup layout
	local panelW, panelH = panel:GetSize()

	frame:SetSize(math.max(panelW + 10, doneBtn:GetWide() + 10, 200), 30 + panelH + 5 + commentEntry:GetTall() + 5 + doneBtn:GetTall() + 5)
	local mx, my = gui.MousePos()
	local fx, fy = frame:GetSize()
	frame:SetPos(mx - fx / 2, my - fy / 2) -- Center on mouse

	panel:AlignTop(30)
	panel:CenterHorizontal()

	commentEntry:SetWide(frame:GetWide() - 10)
	commentEntry:MoveBelow(panel, 5)
	commentEntry:AlignLeft(5)

	doneBtn:AlignBottom(5)
	doneBtn:CenterHorizontal()
	doneBtn.DoClick = function()
		frame:Close()
		local newValue = getValueFunction()
		gConfig.setValue(config, configItemId, newValue, commentEntry:GetValue())
	end
end

local currentHistoryFrame
local function configHistoryClick(config, configItemId)
	if IsValid(currentHistoryFrame) then currentHistoryFrame:Remove() end

	local item = config.items[configItemId]

	local frame = vgui.Create("DFrame")
		frame:SetSize(500, 300)
		frame:Center()
		frame:SetSizable(true)
		frame:SetTitle(string.format("History for %q", item.name))
		frame:MakePopup()

	local listView = vgui.Create("DListView", frame)
		listView:Dock(FILL)
		listView:AddColumn("Date")
		listView:AddColumn("Author")
		listView:AddColumn("Value")
		listView:AddColumn("Comment")

	frame.listView = listView
	frame.config = config.name
	frame.configItemId = configItemId

	currentHistoryFrame = frame

	net.Start("gConfigRequestHistory")
		net.WriteString(config.name)
		net.WriteString(configItemId)
	net.SendToServer()
end

net.Receive("gConfigSendHistory", function()
	if not IsValid(currentHistoryFrame) then return end

	local addon = net.ReadString()
	local configItemId = net.ReadString()

	if currentHistoryFrame.config != addon or
		currentHistoryFrame.configItemId != configItemId then return end

	local config = gConfig.get(addon)
	local item = config.items[configItemId]
	local itemType = gConfig.Types[item.type]

	currentHistoryFrame.listView:Clear()

	for _ = 1, net.ReadUInt(8) do
		local date = net.ReadUInt(32)
		local author = net.ReadString()
		local authorsid = net.ReadString()
		local comment = net.ReadString()
		local value = net.ReadType()

		local datestr = os.date("%Y-%m-%d %H:%M:%S %z", date)
		local datestr = os.date("%c", date)
		local previewValue = itemType.preview(value, item.typeOptions)

		currentHistoryFrame.listView:AddLine(datestr, string.format("%s (%s)", author, authorsid), previewValue, comment)
	end
end)

local function selectConfig(configItemList, configName, config)
	configItemList:Clear()
	configItemList.configItemPanels = {}

	local header = vgui.Create("DLabel", configItemList)
		header:SetText(configName)
		header:SetFont(fontHeader1)
		header:SizeToContents()
		header:Dock(TOP)
		header:DockMargin(0, 0, 0, 5)

	local itemCategories = {}
	-- Pick out the items we can access, and put in their categories
	for id, struct in pairs(config.items) do
		if config:hasAccess(id, LocalPlayer()) then
			local cat = struct.category or "Uncategorized"

			itemCategories[cat] = itemCategories[cat] or {}

			table.insert(itemCategories[cat], struct)
		end
	end

	-- Make the table sequential so we can sort it
	itemCategories = table.ClearKeys(itemCategories, true)

	-- Sort the categories
	table.sort(itemCategories, function(a, b)
		return a.__key < b.__key
	end)

	-- Sort the items in every category
	for _, tbl in pairs(itemCategories) do
		table.sort(tbl, function(a, b)
			-- Sort by realm
			local isClientA = a.realm == gConfig.Client
			local isClientB = b.realm == gConfig.Client
			if isClientA != isClientB then
				return isClientA
			end

			-- Sort by name
			return a.name < b.name
		end)
	end

	local categories = vgui.Create("DCategoryList", configItemList)
		categories:Dock(FILL)
		categories.Paint = function(_, w, h)
			drawPanelBackground(w, h, Color(60, 60, 60))
		end

	-- Create categories and panels
	for _, items in pairs(itemCategories) do
		local category = categories:Add(items.__key)
		local listLayout = vgui.Create("DListLayout")
		category:SetContents(listLayout)

		listLayout.panels = {}

		for k, tbl in pairs(items) do
			if k == "__key" then continue end

			local pnl = vgui.Create("DPanel")
				pnl:Dock(TOP)
				pnl:DockMargin(0, 2, 0, 2)

			local itemName = vgui.Create("DLabel", pnl)
				itemName:SetText(tbl.name)
				itemName:SetFont(fontConfigItem1)
				itemName:SetTextColor(Color(30, 30, 30))
				itemName:SizeToContentsY()
				itemName:SetPos(5, 5)

			local itemDescription = vgui.Create("DLabel", pnl)
				itemDescription:SetFont(fontConfigItem3)
				itemDescription:SetTextColor(Color(30, 30, 30))
				itemDescription:SetPos(5, 5 + itemName:GetTall() + 1)

			local itemValuePreview = vgui.Create("DLabel", pnl)

			local itemEdit = vgui.Create("DImageButton", pnl)
				itemEdit:SetImage("icon16/pencil.png")
				itemEdit:SetTooltip("Edit")
				itemEdit:SetSize(16, 16)
				itemEdit.DoClick = function()
					configEditClick(config, tbl.id)
				end

			local itemHistory = vgui.Create("DImageButton", pnl)
				itemHistory:SetImage("icon16/clock.png")
				itemHistory:SetTooltip("History")
				itemHistory:SetSize(16, 16)
				itemHistory.DoClick = function()
					configHistoryClick(config, tbl.id)
				end

			pnl.PerformLayout = function(_, w, h)
				local nameW = w / 2 - 20
				local valueW = w / 2 - 20
				local descw = w - 40

				itemName:SetWide(nameW)

				local hasDescription = tbl.description and #tbl.description > 0
				local descTall = 0
				if hasDescription then
					local text = table.concat(string.Wrap(fontConfigItem3, tbl.description, descw), "\n")
					itemDescription:SetText(text)
					itemDescription:SizeToContents()
					descTall = itemDescription:GetTall()
				end
				itemDescription:SetVisible(hasDescription)

				itemValuePreview:SetPos(5 + nameW, 5)
				itemValuePreview:SetWide(valueW)

				pnl:SetTall(11 + itemName:GetTall() + descTall)

				if hasDescription then
					local spacing = (h - 16 * 2) / 3
					itemHistory:AlignTop(spacing)
					itemHistory:AlignRight(5)

					itemEdit:AlignBottom(spacing)
					itemEdit:AlignRight(5)
				else
					itemEdit:CenterVertical()
					itemEdit:AlignRight(5)

					itemHistory:CenterVertical()
					itemHistory:MoveLeftOf(itemEdit, 5)
				end
			end

			pnl.Think = function()
				local lastData = pnl.lastData
				local curData = config.data[tbl.id]
				if curData != lastData then
					pnl:UpdateValue()
				end
			end

			pnl.UpdateValue = function()
				pnl.lastData = config.data[tbl.id]

				local itemValue, isDefaultValue = config:getPreview(tbl.id)

				itemValuePreview:SetText(itemValue)
				if isDefaultValue then
					itemValuePreview:SetFont(fontConfigItem2i)
					itemValuePreview:SetTextColor(Color(80, 80, 80))
				else
					itemValuePreview:SetFont(fontConfigItem2)
					itemValuePreview:SetTextColor(Color(80, 150, 80))
				end
				itemValuePreview:SizeToContentsY()

				pnl:InvalidateLayout()
			end
			pnl:UpdateValue()


			pnl.itemValuePreview = itemValuePreview
			listLayout:Add(pnl)
			configItemList.configItemPanels[tbl.id] = pnl
		end
	end
end

local function createMenu()
	local configs = gConfig.getList()

	local frame = vgui.Create("DFrame")
		frame:SetSize(600, 600)
		frame:SetTitle("gConfig")
		frame:Center()
		frame:SetSizable(true)
		frame:SetDeleteOnClose(false)

	local divider = vgui.Create("DHorizontalDivider", frame)
		divider:Dock(FILL)
		divider:SetLeftMin(150)
		divider:SetRightMin(300)
		divider:SetLeftWidth(150)

	local addonList = vgui.Create("DScrollPanel")
		addonList.Paint = function(_, w, h)
			drawPanelBackground(w, h, Color(60, 60, 60))
		end
	divider:SetLeft(addonList)
	local configItemList = vgui.Create("DPanel")
		configItemList.Paint = function() end
	divider:SetRight(configItemList)

	local selectedPnl
	for name, tbl in pairs(configs) do
		local btn = vgui.Create("DButton", pnl)
			btn:SetText(name)
			btn:SetTall(30)
			btn:SetFont(fontButton1)
			btn:Dock(TOP)
			btn:DockMargin(2, 2, 2, 2)
			btn:SetTextColor(Color(20, 20, 20))
			btn.DoClick = function()
				selectedPnl = pnl
				selectConfig(configItemList, name, tbl)
			end

		addonList:AddItem(btn)
	end


	frame:MakePopup()
	return frame
end

function gConfig.openMenu()
	--if IsValid(gConfig.frame) then
	if false and IsValid(gConfig.frame) then
		gConfig.frame:SetVisible(true)
		gConfig.frame:MakePopup()
	else
		gConfig.frame = createMenu()
	end
end

function gConfig.closeMenu()
	if IsValid(gConfig.frame) then
		gConfig.frame:Close()
	end
end

concommand.Add("gconfig_menu", function()
	gConfig.openMenu()
end)
