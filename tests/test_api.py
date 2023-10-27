"""
Tests the Frame specific Lua libraries over Bluetooth.
"""

import asyncio
from frameutils import Bluetooth


async def main():
    b = Bluetooth()
    await b.connect(lua_response_handler=lambda str: None)

    print(await b.send_lua("print(device.NAME)", wait=True))
    print(await b.send_lua("print(device.FIRMWARE_VERSION)", wait=True))
    print(await b.send_lua("print(device.GIT_TAG)", wait=True))
    print(await b.send_lua("print(device.mac_address())", wait=True))
    print(await b.send_lua("print(device.battery_level())", wait=True))

    print(await b.send_lua("print(device.stay_awake())", wait=True))

    await b.send_lua("device.stay_awake(true)")
    await asyncio.sleep(0.1)

    print(await b.send_lua("print(device.stay_awake())", wait=True))

    await b.send_lua("print(device.sleep())")
    await asyncio.sleep(0.1)

    await b.send_reset_signal()
    await asyncio.sleep(0.1)

    await b.disconnect()


asyncio.run(main())
