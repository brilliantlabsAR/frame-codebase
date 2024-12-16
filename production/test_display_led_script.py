from frameutils import Bluetooth
import asyncio

lua_script = """
if frame.HARDWARE_VERSION == 'Frame' then
    width = 640
    height = 400
    t = string.rep('\\xFF', width * height / 8)
    frame.display.bitmap(1, 1, width, 2, 2, t)
    frame.display.show()
    frame.sleep(1)
    frame.display.bitmap(1, 1, width, 2, 9, t)
    frame.display.show()
    frame.sleep(1)
    frame.display.bitmap(1, 1, width, 2, 13, t)
    frame.display.show()
    frame.sleep(1)
else
    frame.led.set_color(100, 0, 0)
    frame.sleep(1)
    frame.led.set_color(0, 100, 0)
    frame.sleep(1)
    frame.led.set_color(0, 0, 100)
    frame.sleep(1)
end
"""


async def main():
    b = Bluetooth()
    await b.connect()
    await b.upload_file(lua_script, "main.lua")
    await b.send_reset_signal()
    await asyncio.sleep(3)
    await b.disconnect()


asyncio.run(main())
