local ds18b20 = require("ds18b20")
local gpio2 = 4 --температура
local gpio4 = 2 --реле давления, gpio4 и gnd
local gpio5 = 1 --управление ssr реле, gpio5 и gnd
gpio.mode(gpio5, gpio.OUTPUT)
gpio.mode(gpio4, gpio.INT, gpio.PULLUP) --режим кнопки

ds18b20.setup(gpio2)
local addres = ds18b20.addrs()
local sensors = #addres

--получить состояние контактов реле давления
function getRelayState()
    --1 когда реле разомкнуто, gpio4 и gnd
    --0 когда реле замкнуто
    local relayState = gpio.read(gpio4)
    print('relay is: '..relayState)
    if relayState == 0 then --реле замкнуто, давление ноль
        gpio.write(gpio5, 1) --включаем насос
    else
    --реле разомкнуто
        gpio.write(gpio5, 0) --выключаем насос
    end
end

function sendNarod()
    local sensors = sensors
    print("Sensors count: ", sensors)
    if sensors == 0 then
        print("No DS18B20 sensors found!")
        return
    end
	
    local dataN = "#18fe34000000\n" -- узнаем по команде wifi.sta.getmac() в ESPlorer, его же требует narodmon
	local tm = ds18b20.read(addres[sensors])
	if tm == nil then
        print("Fail to read sensor")
        return
    end
	
	local tm2 = tm % 10000
	local tm1 = (tm - tm2)/10000
	dataN = dataN.."#T1#"..tm1.."."..tm2.."\n"
	dataN = dataN.."##\n"
	print(dataN)
	
	if tonumber(tm1) ~= 85 then 
		local conn=net.createConnection(net.TCP, 0)
		conn:on("connection", function(sck)
				sck:send(dataN)
				end)
				
		conn:on("receive", function(sck, payload)
				local diff = (tmr.now() - t) / 1000
				print('\nRetrieved in '..diff..' milliseconds.')
				print('Narodmon says '..payload)
				sck:close()
				end)
		t = tmr.now()
		conn:connect(8283,'narodmon.ru')
	else 
		print ('Fail to get temp')
	end
end

--Таймер 1, опрос реле давления
relay_timer = tmr.create()
relay_timer:alarm(2000, tmr.ALARM_AUTO, function()
    getRelayState()
end)

--Таймер 0, опрос датчика температуры
narod_timer = tmr.create()
narod_timer:alarm(900000, tmr.ALARM_AUTO, function()
   if wifi.sta.getip() == nil then
     print("Connecting to AP...")
   else
     print('IP+: ',wifi.sta.getip())
     sendNarod()
   end
end)



