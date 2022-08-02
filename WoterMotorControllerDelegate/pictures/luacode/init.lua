wifi.setmode(wifi.STATION) --1:Station mode, where the NodeMCU device joins an existing network
print('set mode=STATION (mode='..wifi.getmode()..')')
print('MAC: ',wifi.sta.getmac())
-- wifi config start:
local stationCfg = {}
stationCfg.auto=true
stationCfg.ssid='QwinCor_WiFi'
stationCfg.pwd=nil
stationCfg.bssid="F0:7D:68:82:C0:12"
wifi.sta.config(stationCfg)
-- wifi config end
Fmain="main.lua"
l = file.list()
for k,v in pairs(l) do
  if k == Fmain then
    print("*** You have got 10 sec to stop timer 0 ***")
    tmr.alarm(0, 10000, 0, function()
      print("Executing ".. Fmain)
      dofile(Fmain)
    end)
  end
end
