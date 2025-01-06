"""
Tests the Frame specific Lua libraries over Bluetooth.
"""

import asyncio
from frameutils import Bluetooth


async def main():
    b = Bluetooth()

    await b.connect(print_response_handler=lambda s: print(s))

    await b.send_lua("print(frame.HARDWARE_VERSION)")
    await b.send_lua("print(frame.FIRMWARE_VERSION)")
    await b.send_lua("print(frame.GIT_TAG)")

    await asyncio.sleep(1)

    await b.disconnect()


asyncio.run(main())
