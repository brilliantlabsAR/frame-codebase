"""
Tests the Frame specific Lua libraries over Bluetooth.
"""

import asyncio
from frameutils import Bluetooth


async def main():
    b = Bluetooth()

    await b.connect()

    while True:
        await b.send_lua("resp = frame.imu.raw()")
        print(
            await b.send_lua(
                "print(tostring(resp['accelerometer']['x'])..'\t'..tostring(resp['accelerometer']['y'])..'\t'..tostring(resp['accelerometer']['z'])..'\t'..tostring(resp['compass']['x'])..'\t'..tostring(resp['compass']['y'])..'\t'..tostring(resp['compass']['z']))",
                await_print=True,
            )
        )
        asyncio.sleep(0.1)

    await b.disconnect()


asyncio.run(main())
