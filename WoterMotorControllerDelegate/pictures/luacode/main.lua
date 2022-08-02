require("ds18b20")
gpio2 = 4 --температура
gpio4 = 2 --реле давления, gpio4 и gnd
gpio5 = 1 --управление ssr реле, gpio5 и gnd
gpio.mode(gpio5, gpio.OUTPUT)
gpio.mode(gpio4, gpio.INT, gpio.PULLUP) --режим кнопки

ds18b20.setup(gpio2)
addres=ds18b20.addrs()
sensors=table.getn(addres)

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
    print(sensors)
    local tm
    local dataN
    dataN = "#18fe34000000\n" -- узнаем по команде wifi.sta.getmac() в ESPlorer, его же требует narodmon
	tm = ds18b20.read(addres[sensors])
	local tm2 = tm % 10000
	local tm1 = (tm - tm2)/10000
	dataN = dataN.."#T1#"..tm1.."."..tm2.."\n"
	dataN = dataN.."##\n"
	print(dataN)
	if tonumber(tm1) ~= 85 then 
		conn=net.createConnection(net.TCP, 0)
		conn:on("connection",function(conn, payload)
				conn:send(dataN)
				end)
		conn:on("receive",function(conn, payload)
				print('\nRetrieved in '..((tmr.now()-t)/1000)..' milliseconds.')
				print('Narodmon says '..payload)
				conn:close()
				end)
		t = tmr.now()
		conn:connect(8283,'narodmon.ru')
	else 
		print ('Fail to get temp')
	end
end

--Таймер 1, опрос реле давления
tmr.alarm(1, 2000, 1, function()
    getRelayState()
end)

--Таймер 0, опрос датчика температуры
tmr.alarm(0, 900000, 1, function()
   if wifi.sta.getip() == nil then
     print("Connecting to AP...")
   else
     print('IP+: ',wifi.sta.getip())
     sendNarod()
   end
end)



