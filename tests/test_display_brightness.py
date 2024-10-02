import asyncio, sys
from frameutils import Bluetooth


async def main():
    b = Bluetooth()
    await b.connect()

    await b.send_lua(f"frame.display.text('Hello Frame!', 50, 50)")
    await b.send_lua(f"frame.display.text('The quick brown fox jumped', 50, 150)")
    await b.send_lua(f"frame.display.text('over the lazy dog.', 50, 200)")
    await b.send_lua("frame.display.show()")
    await asyncio.sleep(1.00)

    # Using API
    await b.send_lua("frame.display.set_brightness(-2)")
    await asyncio.sleep(1.00)

    await b.send_lua("frame.display.set_brightness(-1)")
    await asyncio.sleep(1.00)

    await b.send_lua("frame.display.set_brightness(0)")
    await asyncio.sleep(1.00)

    await b.send_lua("frame.display.set_brightness(1)")
    await asyncio.sleep(1.00)

    await b.send_lua("frame.display.set_brightness(2)")
    await asyncio.sleep(1.00)

    # Same thing using bare write register commands
    await b.send_lua("frame.display.write_register(0x05, 0xC8 | 1)")
    await asyncio.sleep(1.00)

    await b.send_lua("frame.display.write_register(0x05, 0xC8 | 2)")
    await asyncio.sleep(1.00)

    await b.send_lua("frame.display.write_register(0x05, 0xC8 | 0)")
    await asyncio.sleep(1.00)

    await b.send_lua("frame.display.write_register(0x05, 0xC8 | 3)")
    await asyncio.sleep(1.00)

    await b.send_lua("frame.display.write_register(0x05, 0xC8 | 4)")
    await asyncio.sleep(1.00)

    await b.disconnect()


asyncio.run(main())
