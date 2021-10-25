ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('esx_evidence:getStockItem')
AddEventHandler('esx_evidence:getStockItem', function(itemName, count, k)
    local _source    = source
    local xPlayer    = ESX.GetPlayerFromId(_source)

    TriggerEvent('esx_addoninventory:getSharedInventory', Config.EvidenceLockers[k].Society, function(inventory)

        local inventoryItem = inventory.getItem(itemName)

        -- is there enough in the society?
        if count > 0 and inventoryItem.count >= count then

            -- can the player carry the said amount of x item?
            if CanCarryItem(_source, itemName, count) then
                inventory.removeItem(itemName, count)
                xPlayer.addInventoryItem(itemName, count)
                TriggerClientEvent('esx:showNotification', _source, _U('have_withdrawn', count, inventoryItem.label))
            else
                TriggerClientEvent('esx:showNotification', _source, _U('quantity_invalid'))
            end
        else
            TriggerClientEvent('esx:showNotification', _source, _U('quantity_invalid'))
        end
    end)

end)

RegisterServerEvent('esx_evidence:putStockItems')
AddEventHandler('esx_evidence:putStockItems', function(itemName, count, k)
    local xPlayer    = ESX.GetPlayerFromId(source)
    local sourceItem = xPlayer.getInventoryItem(itemName)

    TriggerEvent('esx_addoninventory:getSharedInventory', Config.EvidenceLockers[k].Society, function(inventory)

        local inventoryItem = inventory.getItem(itemName)

        -- does the player have enough of the item?
        if sourceItem.count >= count and count > 0 then
            xPlayer.removeInventoryItem(itemName, count)
            inventory.addItem(itemName, count)
            TriggerClientEvent('esx:showNotification', xPlayer.source, _U('have_deposited', count, inventoryItem.label))
        else
            TriggerClientEvent('esx:showNotification', xPlayer.source, _U('quantity_invalid'))
        end

    end)

end)

RegisterServerEvent('esx_evidence:removeBlack')
AddEventHandler('esx_evidence:removeBlack', function(itemName, count, k)
    local xPlayer = ESX.GetPlayerFromId(source)
    -- xPlayer.removeAccountMoney(itemName, count)
    TriggerEvent('esx_addoninventory:getSharedInventory', Config.EvidenceLockers[k].Society, function(inventory)

        local inventoryItem = inventory.getItem(itemName)

        -- does the player have enough of the item?
        if sourceItem.count >= count and count > 0 then
            xPlayer.removeAccountMoney(itemName, count)
            inventory.addItem(itemName, count)
            TriggerClientEvent('esx:showNotification', xPlayer.source, _U('have_deposited', count, inventoryItem.label))
        else
            TriggerClientEvent('esx:showNotification', xPlayer.source, _U('quantity_invalid'))
        end

    end)
    
end)

ESX.RegisterServerCallback('esx_evidence:getArmoryWeapons', function(source, cb, k)

    TriggerEvent('esx_datastore:getSharedDataStore', Config.EvidenceLockers[k].Society, function(store)

        local weapons = store.get('weapons')

        if weapons == nil then
            weapons = {}
        end

        cb(weapons)

    end)

end)

ESX.RegisterServerCallback('esx_evidence:addArmoryWeapon', function(source, cb, weaponName, removeWeapon, k)

    local xPlayer = ESX.GetPlayerFromId(source)

    if removeWeapon then
        xPlayer.removeWeapon(weaponName)
    end

    TriggerEvent('esx_datastore:getSharedDataStore', Config.EvidenceLockers[k].Society, function(store)

        local weapons = store.get('weapons')

        if weapons == nil then
            weapons = {}
        end

        local foundWeapon = false

        for i = 1, #weapons, 1 do
            if weapons[i].name == weaponName then
                weapons[i].count = weapons[i].count + 1
                foundWeapon      = true
            end
        end

        if not foundWeapon then
            table.insert(weapons, {
                name  = weaponName,
                count = 1
            })
        end

        store.set('weapons', weapons)

        cb()

    end)

end)

ESX.RegisterServerCallback('esx_evidence:removeArmoryWeapon', function(source, cb, weaponName, k)

    local xPlayer = ESX.GetPlayerFromId(source)

    xPlayer.addWeapon(weaponName, Config.WeaponBullets)

    TriggerEvent('esx_datastore:getSharedDataStore', Config.EvidenceLockers[k].Society, function(store)

        local weapons = store.get('weapons')

        if weapons == nil then
            weapons = {}
        end

        local foundWeapon = false

        for i = 1, #weapons, 1 do
            if weapons[i].name == weaponName then
                weapons[i].count = (weapons[i].count > 0 and weapons[i].count - 1 or 0)
                foundWeapon      = true
            end
        end

        if not foundWeapon then
            table.insert(weapons, {
                name  = weaponName,
                count = 0
            })
        end

        store.set('weapons', weapons)

        cb()

    end)

end)

ESX.RegisterServerCallback('esx_evidence:getStockItems', function(source, cb, k)

    TriggerEvent('esx_addoninventory:getSharedInventory', Config.EvidenceLockers[k].Society, function(inventory)
        cb(inventory.items)
    end)

end)

ESX.RegisterServerCallback('esx_evidence:getPlayerInventory', function(source, cb)

    local xPlayer = ESX.GetPlayerFromId(source)

    local items   = xPlayer.inventory

    cb({ items = items })

end)

AddEventHandler('playerDropped', function()
    -- Save the source in case we lose it (which happens a lot)
    local _source = source

    -- Did the player ever join?
    if _source ~= nil then
        local xPlayer = ESX.GetPlayerFromId(_source)

    end
end)

RegisterServerEvent('esx_evidence:spawned')
AddEventHandler('esx_evidence:spawned', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then

    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then

    end
end)

function CanCarryItem(target, item, count)
    local xPlayer = ESX.GetPlayerFromId(target)
    if Config.OldESX then
        local sourceItem = xPlayer.getInventoryItem(item)
        return sourceItem.limit ~= -1 and (sourceItem.count + count) > sourceItem.limit
    else
        return xPlayer.canCarryItem(item, count)
    end
end