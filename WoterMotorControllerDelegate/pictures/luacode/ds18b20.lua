local M = {}

-- Константы единиц измерения
M.C = 0
M.F = 1
M.K = 2

-- Локальные переменные модуля
local pin = nil
local defaultPin = 4

-- Локальные ссылки на глобальные модули для ускорения работы
local table = table
local string = string
local ow = ow
local tmr = tmr

-- Реализация функций модуля
function M.setup(dq)
  pin = dq
  if(pin == nil) then
    pin = defaultPin
  end
  ow.setup(pin)
end

function M.addrs()
  M.setup(pin)
  local tbl = {}
  ow.reset_search(pin)
  repeat
    local addr = ow.search(pin)
    if(addr ~= nil) then
      table.insert(tbl, addr)
    end
    tmr.wdclr()
  until (addr == nil)
  ow.reset_search(pin)
  return tbl
end

function M.readNumber(addr, unit)
  local result = nil
  M.setup(pin)
  
  if(addr == nil) then
    ow.reset_search(pin)
    local count = 0
    repeat
      count = count + 1
      addr = ow.search(pin)
      tmr.wdclr()
    until((addr ~= nil) or (count > 50))
    ow.reset_search(pin)
  end
  if(addr == nil) then
    return result
  end
  
  local crc = ow.crc8(string.sub(addr,1,7))
  if (crc == addr:byte(8)) then
    if ((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
      ow.reset(pin)
      ow.select(pin, addr)
      ow.write(pin, 0x44, 1)
      
      local present = ow.reset(pin)
      ow.select(pin, addr)
      ow.write(pin,0xBE,1)
      
      local data = string.char(ow.read(pin))
      for i = 1, 8 do
        data = data .. string.char(ow.read(pin))
      end
      
      crc = ow.crc8(string.sub(data,1,8))
      if (crc == data:byte(9)) then
        local t = (data:byte(1) + data:byte(2) * 256)
        if (t > 32767) then
          t = t - 65536
        end
        if(unit == nil or unit == M.C) then
          t = t * 625
        elseif(unit == M.F) then
          t = t * 1125 + 320000
        elseif(unit == M.K) then
          t = t * 625 + 2731500
        else
          return nil
        end
        return t
      end
      tmr.wdclr()
    else
      print("Device family is not recognized.")
    end
  else
    print("CRC is not valid!")
  end
  return result
end

function M.read(addr, unit)
  local t = M.readNumber(addr, unit)
  if (t == nil) then
    return nil
  else
    return t
  end
end

-- Возвращаем таблицу модуля
return M