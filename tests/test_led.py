"""
Tests the Frame specific Lua libraries over Bluetooth.
"""

import asyncio
from frameutils import Bluetooth


async def main():
    b = Bluetooth()

    await b.connect(print_response_handler=lambda s: print(s))

    await b.send_lua("frame.led.set_color(100, 0, 0)")
    await asyncio.sleep(1)

    await b.send_lua("frame.led.set_color(0, 100, 0)")
    await asyncio.sleep(1)

    await b.send_lua("frame.led.set_color(0, 0, 100)")
    await asyncio.sleep(1)

    await b.disconnect()


asyncio.run(main())
