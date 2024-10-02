import asyncio
from frameutils import Bluetooth


async def main():
    b = Bluetooth()

    await b.connect(print_response_handler=lambda s: print(s))

    # Display
    await b.send_lua("frame.display.power_save(false)")

    await b.send_lua("frame.display.text('Test', 1, 1)")
    await b.send_lua("frame.display.text('Test', 563, 1)")
    await b.send_lua("frame.display.text('Test', 1, 352)")
    await b.send_lua("frame.display.text('Test', 563, 352)")
    await b.send_lua("frame.display.show()")
    await asyncio.sleep(2.00)

    await b.send_lua("frame.display.power_save(true)")
    await asyncio.sleep(5.00)
    await b.send_lua("frame.display.power_save(false)")

    # Camera
    await b.send_lua("frame.camera.power_save(true)")
    await asyncio.sleep(5.00)
    await b.send_lua("frame.camera.power_save(false)")

    # Both
    await b.send_lua("frame.display.power_save(true)")
    await b.send_lua("frame.camera.power_save(true)")
    await asyncio.sleep(5.00)
    await b.send_lua("frame.display.power_save(false)")
    await b.send_lua("frame.camera.power_save(false)")

    await b.disconnect()


asyncio.run(main())
