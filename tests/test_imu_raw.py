"""
Tests the Frame specific Lua libraries over Bluetooth.
"""

import asyncio
from frameutils import Bluetooth


async def main():
    b = Bluetooth()

    await b.connect(print_response_handler=lambda s: print(s))

    # Load the I2C bus
    await b.send_lua("frame.camera.auto(true, 'average')")

    # Enable taps
    await b.send_lua("frame.imu.tap_callback((function()print('Tap!')end))")

    while True:
        await b.send_lua("resp = frame.imu.raw()")

        await b.send_lua(
            "print(tostring(resp['accelerometer']['x'])..'\t'..tostring(resp['accelerometer']['y'])..'\t'..tostring(resp['accelerometer']['z'])..'\t'..tostring(resp['compass']['x'])..'\t'..tostring(resp['compass']['y'])..'\t'..tostring(resp['compass']['z']))",
            await_print=True,
        )
        asyncio.sleep(0.1)

    await b.disconnect()


asyncio.run(main())
