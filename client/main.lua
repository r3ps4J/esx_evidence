local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local PlayerData              = {}
local HasAlreadyEnteredMarker = false
local LastStation             = nil
local LastPart                = nil
local LastPartNum             = nil
local LastEntity              = nil
local CurrentAction           = nil
local CurrentActionMsg        = ''
local CurrentActionData       = {}
local IsHandcuffed            = false
local HandcuffTimer           = {}
local DragStatus              = {}
DragStatus.IsDragged          = false
local hasAlreadyJoined        = false
local blipsCops               = {}
local isDead                  = false
local CurrentTask             = {}
local playerInService         = false

ESX                           = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	Citizen.Wait(5000)
	PlayerData = ESX.GetPlayerData()
end)

function OpenArmoryMenu()


    local elements = {
      {label = _U('deposit_object'), value = 'put_stock'}
    }

    if not Config.TakeBossOnly or (PlayerData.job.grade_name == 'boss' or PlayerData.job.grade_name == 'chief' or PlayerData.job.grade_name == 'chief') then
      table.insert(elements, {label = _U('remove_object'),  value = 'get_stock'})
    end

    if Config.EnableWeapons then
      table.insert(elements, {label = _U('put_weapon'),     value = 'put_weapon'})
      if not Config.TakeBossOnly or (PlayerData.job.grade_name == 'boss' or PlayerData.job.grade_name == 'chief' or PlayerData.job.grade_name == 'chief') then
        table.insert(elements, {label = _U('get_weapon'),     value = 'get_weapon'})
      end
    end

    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'armory',
      {
        title    = 'Evidence Locker',
        align    = 'top-left',
        elements = elements,
      },
      function(data, menu)

        if data.current.value == 'get_weapon' then
          OpenGetWeaponMenu()
        end

        if data.current.value == 'put_weapon' then
          OpenPutWeaponMenu()
        end

        if data.current.value == 'put_stock' then
          OpenPutStocksMenu()
        end

        if data.current.value == 'get_stock' then
          OpenGetStocksMenu()
        end

      end,
      function(data, menu)

        menu.close()

        CurrentAction     = 'menu_armory'
        CurrentActionMsg  = _U('open_armory')
      end
    )
end


function OpenGetWeaponMenu()

  ESX.TriggerServerCallback('esx_evidence:getArmoryWeapons', function(weapons)

    local elements = {}

    for i=1, #weapons, 1 do
      if weapons[i].count > 0 then
        table.insert(elements, {label = 'x' .. weapons[i].count .. ' ' .. ESX.GetWeaponLabel(weapons[i].name), value = weapons[i].name})
      end
    end

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'armory_get_weapon',
      {
        title    = 'Evidence Locker',
        align    = 'top-left',
        elements = elements
      },
      function(data, menu)

        menu.close()

        ESX.TriggerServerCallback('esx_evidence:removeArmoryWeapon', function()
          OpenGetWeaponMenu()
        end, data.current.value, CurrentActionData.station)

      end,
      function(data, menu)
        menu.close()
      end
    )

  end, CurrentActionData.station)

end

function OpenPutWeaponMenu()

  local elements   = {}
  local playerPed  = PlayerPedId()
  local weaponList = ESX.GetWeaponList()

  for i=1, #weaponList, 1 do

    local weaponHash = GetHashKey(weaponList[i].name)

    if HasPedGotWeapon(playerPed,  weaponHash,  false) and weaponList[i].name ~= 'WEAPON_UNARMED' then
      table.insert(elements, {label = weaponList[i].label, value = weaponList[i].name})
    end

  end

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'armory_put_weapon',
    {
      title    = 'Evidence - Put Weapon',
      align    = 'top-left',
      elements = elements
    },
    function(data, menu)

      menu.close()

      ESX.TriggerServerCallback('esx_evidence:addArmoryWeapon', function()
        OpenPutWeaponMenu()
      end, data.current.value, true, CurrentActionData.station)

    end,
    function(data, menu)
      menu.close()
    end
  )
end

function OpenGetStocksMenu()

  ESX.TriggerServerCallback('esx_evidence:getStockItems', function(items)


    local elements = {}

    for i=1, #items, 1 do
      if items[i].count ~= 0 then
        table.insert(elements, {label = 'x' .. items[i].count .. ' ' .. items[i].label, value = items[i].name})
      end
    end

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'stocks_menu',
      {
        title    = 'Evidence Locker',
        align    = 'top-left',
        elements = elements
      },
      function(data, menu)

        local itemName = data.current.value

        ESX.UI.Menu.Open(
          'dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count',
          {
            title = _U('quantity')
          },
          function(data2, menu2)

            local count = tonumber(data2.value)

            if count == nil then
              ESX.ShowNotification(_U('quantity_invalid'))
            else
              menu2.close()
              menu.close()
              TriggerServerEvent('esx_evidence:getStockItem', itemName, count, CurrentActionData.station)

              Citizen.Wait(300)
              OpenGetStocksMenu()
            end

          end,
          function(data2, menu2)
            menu2.close()
          end
        )

      end,
      function(data, menu)
        menu.close()
      end
    )

  end, CurrentActionData.station)

end

function OpenPutStocksMenu()

  ESX.TriggerServerCallback('esx_evidence:getPlayerInventory', function(inventory)

    local elements = {}

    for i=1, #inventory.items, 1 do

		local item = inventory.items[i]
	
		if item.count > 0 then
		table.insert(elements, {label = item.label .. ' x' .. item.count, type = 'item_standard', value = item.name})
		end

    end
	
	PlayerData = ESX.GetPlayerData()
	for i=1, #PlayerData.accounts, 1 do
		if PlayerData.accounts[i].name == 'black_money' then
		-- if PlayerData.accounts[i].money > 0 then
		local itemBlack = 1
			table.insert(elements, {
			label     = PlayerData.accounts[i].label .. ' [ $'.. math.floor(PlayerData.accounts[i].money+0.5) ..' ]',
			count     = PlayerData.accounts[i].money,
			value     = PlayerData.accounts[i].name,
			name      = PlayerData.accounts[i].label,
			limit     = PlayerData.accounts[i].limit,
			type		= 'item_account',
			})
		end
	end

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'stocks_menu',
      {
        title    = 'Evidence - Put Stock',
        align    = 'top-left',
        elements = elements
      },
      function(data, menu)

        local itemName = data.current.value

		
        ESX.UI.Menu.Open(
          'dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count',
          {
            title = _U('quantity')
          },
          function(data2, menu2)

            local count = tonumber(data2.value)

			if itemName == "black_money" then
				TriggerServerEvent('esx_evidence:removeBlack', itemName, count, CurrentActionData.station)
			end
			
            if count == nil then
              ESX.ShowNotification(_U('quantity_invalid'))
            else
              menu2.close()
              menu.close()
              TriggerServerEvent('esx_evidence:putStockItems', itemName, count, CurrentActionData.station)

              Citizen.Wait(300)
              OpenPutStocksMenu()
            end

          end,
          function(data2, menu2)
            menu2.close()
          end
        )

      end,
      function(data, menu)
        menu.close()
      end
    )

  end, CurrentActionData.station)

end

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
	
	Citizen.Wait(5000)
end)

AddEventHandler('esx_evidence:hasEnteredMarker', function(station, part, partNum)

  if part == 'Armory' then
    CurrentAction     = 'menu_armory'
    CurrentActionMsg  = _U('open_armory')
    CurrentActionData = {station = station}
  end

end)

AddEventHandler('esx_evidence:hasExitedMarker', function(station, part, partNum)
  ESX.UI.Menu.CloseAll()
  CurrentAction = nil
end)

-- Display markers
Citizen.CreateThread(function()
  while true do

    Wait(0)

    local playerPed = PlayerPedId()
    local coords    = GetEntityCoords(playerPed)

    for k,v in pairs(Config.EvidenceLockers) do
      if PlayerData.job ~= nil and (PlayerData.job.name == v.Job) then
       for i=1, #v.Locker, 1 do
          local dist = GetDistanceBetweenCoords(coords,  v.Locker[i].x,  v.Locker[i].y,  v.Locker[i].z,  true)
          if dist < 5.0 then
            DrawMarker(20, v.Locker[i].x, v.Locker[i].y, v.Locker[i].z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.15, 0.17, 200, 200, 200, 222, false, false, false, true, false, false, false)
            if dist < 1.0 then
              DrawText3D(v.Locker[i].x, v.Locker[i].y, v.Locker[i].z + 0.1, "~g~E~w~ - ".. _U("open_armory"))
            end
          end
        end
      end
    end

  end
end)

-- Enter / Exit marker events
Citizen.CreateThread(function()

  while true do

    Wait(0)

    local playerPed      = PlayerPedId()
    local coords         = GetEntityCoords(playerPed)
    local isInMarker     = false
    local currentStation = nil
    local currentPart    = nil
    local currentPartNum = nil

    for k,v in pairs(Config.EvidenceLockers) do
      if PlayerData.job ~= nil and (PlayerData.job.name == v.Job) then
        for i=1, #v.Locker, 1 do
          if GetDistanceBetweenCoords(coords,  v.Locker[i].x,  v.Locker[i].y,  v.Locker[i].z,  true) < 1.0 then
            isInMarker     = true
            currentStation = k
            currentPart    = 'Armory'
            currentPartNum = i
          end
        end
      end

    end

    local hasExited = false

    if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum) ) then

      if
        (LastStation ~= nil and LastPart ~= nil and LastPartNum ~= nil) and
        (LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)
      then
        TriggerEvent('esx_evidence:hasExitedMarker', LastStation, LastPart, LastPartNum)
        hasExited = true
      end

      HasAlreadyEnteredMarker = true
      LastStation             = currentStation
      LastPart                = currentPart
      LastPartNum             = currentPartNum

      TriggerEvent('esx_evidence:hasEnteredMarker', currentStation, currentPart, currentPartNum)
    end

    if not hasExited and not isInMarker and HasAlreadyEnteredMarker then

      HasAlreadyEnteredMarker = false

      TriggerEvent('esx_evidence:hasExitedMarker', LastStation, LastPart, LastPartNum)
    end

  end
end)


-- Key Controls
Citizen.CreateThread(function()
	while true do

		Citizen.Wait(0)

		if CurrentAction ~= nil then
      if PlayerData.job.name == Config.EvidenceLockers[CurrentActionData.station].Job then
        if IsControlJustReleased(0, Keys['E']) and CurrentAction == "menu_armory" then
          OpenArmoryMenu()
          CurrentAction = nil
        end
      end
		end -- CurrentAction end
	end
end)


AddEventHandler('playerSpawned', function(spawn)
	isDead = false
	
	if not hasAlreadyJoined then
		TriggerServerEvent('esx_evidence:spawned')
	end
	hasAlreadyJoined = true
end)

AddEventHandler('esx:onPlayerDeath', function(data)
	isDead = true
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then

	end
end)

function DrawText3D(x, y, z, text)
	SetTextScale(0.35, 0.35)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextColour(255, 255, 255, 215)
	SetTextEntry("STRING")
	SetTextCentre(true)
	AddTextComponentString(text)
	SetDrawOrigin(x,y,z, 0)
	DrawText(0.0, 0.0)
	local factor = (string.len(text)) / 370
	DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
	ClearDrawOrigin()
end