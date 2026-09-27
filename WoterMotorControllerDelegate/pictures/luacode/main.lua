local ds18b20 = require("ds18b20")
local gpio2 = 4 --температура
local gpio4 = 2 --реле давления, gpio4 и gnd
local gpio5 = 1 --управление ssr реле, gpio5 и gnd
gpio.mode(gpio5, gpio.OUTPUT)
gpio.mode(gpio4, gpio.INT, gpio.PULLUP) --режим кнопки

ds18b20.setup(gpio2)
local addres = ds18b20.addrs()
local sensors = #addres
local debounce_timer = tmr.create() -- Создаем таймер для защиты от дребезга контактов (50-100 мс)

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

-- Колбэк прерывания
gpio.trig(gpio4, "both", function(level, when)
    -- Как только контакт двинулся, запускаем/перезапускаем таймер на 200 мс
    -- Опрос состояния произойдет только после того, как контакты успокоятся
    debounce_timer:stop()
    debounce_timer:alarm(200, tmr.ALARM_SINGLE, function()
        getRelayState()
    end)
end)

getRelayState()-- Первичный опрос при старте платы, чтобы сразу выставить нужное состояние

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



