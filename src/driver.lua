-- driver.lua for BeoLiving Intelligence Gen 3
-- Integration: Intesis FJ-RC-WMP-1 (Fujitsu HVAC)

local tcp_channel = nil

-- 1. INITIALIZATION
function on_init()
    log("Initializing FJ-RC-WMP-1 Driver...")
    connect_to_gateway()
end

function connect_to_gateway()
    -- BLI Gen 3 uses setup fields from manifest.json
    tcp_channel = TCP(setup.ip_address, setup.port)
    
    tcp_channel:on_connected(function()
        log("Connected to Intesis Gateway at " .. setup.ip_address)
        -- Initial Sync: Request System ID and all states via Wildcard
        send_intesis_command("ID")
        send_intesis_command("GET,*:*")
        update_all_units_comm_status("Online")
    end)

    tcp_channel:on_disconnected(function()
        log("Connection lost to Intesis Gateway.")
        update_all_units_comm_status("Offline Error")
    end)

    tcp_channel:on_data(function(data)
        -- Split stream by Carriage Return (\r) per WMP Spec
        for message in data:gmatch("[^\r]+") do
            parse_intesis_message(message)
        end
    end)
    
    -- Heartbeat: Prevents the 60s idle timeout [HMS WMP Specs]
    Timer(45, function()
        if tcp_channel:is_connected() then
          send_intesis_command("GET,*:ONOFF")  
          send_intesis_command("ID")
        end
    end, true)
end

-- 2. COMMAND HANDLING (BLI -> Intesis)
function on_resource_event(resource, event, value)
    local unit_id = resource.parameters.unit_id
    if not unit_id then return end

    if event == "SET POWER" then
        local pwr = (value == "On" or value == true) and "ON" or "OFF"
        send_intesis_command(string.format("SET,%d:ONOFF,%s", unit_id, pwr))

    elseif event == "SET SETPOINT" then
        -- Scale 22.5 to 225 for Intesis
        local temp = math.floor(tonumber(value) * 10)
        send_intesis_command(string.format("SET,%d:SETPOINT,%d", unit_id, temp))

    elseif event == "SET MODE" then
        local mode_map = { Heat="HEAT", Cool="COOL", Dry="DRY", Fan="FAN", Auto="AUTO" }
        send_intesis_command(string.format("SET,%d:MODE,%s", unit_id, mode_map[value] or "AUTO"))

    elseif event == "SET FAN_SPEED" then
        local fan_map = { Low="1", Medium="2", High="3", Auto="AUTO" }
        send_intesis_command(string.format("SET,%d:FANSP,%s", unit_id, fan_map[value] or "AUTO"))

    elseif event == "RESET FILTER" then
        send_intesis_command(string.format("SET,%d:FILTER,OFF", unit_id))
    end
end

-- 3. FEEDBACK PARSING (Intesis -> BLI)
function parse_intesis_message(msg)
    -- Capture Message Type (CHN/ANS/ACK), Address:Function, and Value
    local msg_type, func_path, val = msg:match("^<([^,]+),([^,]+),([^,]+)")
    
    -- Handle Errors (e.g., <ERR,1:COMM,02)
    if msg:match("^<ERR") then
        local u_id, err_type, err_code = msg:match("<ERR,(%d+):([^,]+),?([^,]*)")
        local res = find_resource_by_parameter("unit_id", tonumber(u_id))
        if res then
            res:set_state("error_code", err_type .. (err_code ~= "" and (": " .. err_code) or ""))
            res:set_state("comm_status", "Offline Error")
        end
        return
    end

    if not msg_type or msg_type == "ACK" then return end

    local unit_id, function_name = func_path:match("([^:]+):([^:]+)")
    local resource = find_resource_by_parameter("unit_id", tonumber(unit_id))
    if not resource then return end

    -- Map Fujitsu/Intesis functions to BLI states
    if function_name == "ONOFF" then
        resource:set_state("power", val == "ON")
        resource:set_state("error_code", "None")
        resource:set_state("comm_status", "Online")
    elseif function_name == "SETPOINT" then
        resource:set_state("setpoint", tonumber(val) / 10)
    elseif function_name == "AMB_TEMP" then
        resource:set_state("temperature", tonumber(val) / 10)
    elseif function_name == "MODE" then
        local rev_mode = { HEAT="Heat", COOL="Cool", DRY="Dry", FAN="Fan", AUTO="Auto" }
        resource:set_state("mode", rev_mode[val] or "Auto")
    elseif function_name == "FANSP" then
        local rev_fan = { ["1"]="Low", ["2"]="Medium", ["3"]="High", AUTO="Auto" }
        resource:set_state("fan_speed", rev_fan[val] or "Auto")
    elseif function_name == "FILTER" then
        resource:set_state("filter_alarm", val == "ON")
    end
end

-- 4. UTILS
function send_intesis_command(cmd)
    if tcp_channel and tcp_channel:is_connected() then
        tcp_channel:write("<" .. cmd .. "\r")
    end
end

function update_all_units_comm_status(status)
    for _, res in ipairs(resources) do
        if res.type == "AC_UNIT" then res:set_state("comm_status", status) end
    end
end

function find_resource_by_parameter(name, val)
    for _, res in ipairs(resources) do
        if tonumber(res.parameters[name]) == val then return res end
    end
    return nil
end

-- 5. DISCOVERY (UDP Broadcast)
function on_discovery()
    local udp = UDP()
    udp:send("255.255.255.255", 3310, "DISCOVER")
    udp:on_data(function(data, ip)
        local mac, found_ip, model = data:match("^<DISCOVER,([^,]+),([^,]+),([^,]+)")
        if found_ip then
            add_discovery_result({
                id = mac,
                label = model .. " (" .. found_ip .. ")",
                setup = { ip_address = found_ip, port = 3310 }
            })
        end
    end)
    Timer(5, function() udp:close() end)
end
