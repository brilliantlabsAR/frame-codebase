import asyncio
from frameutils import Bluetooth


async def main():
    b = Bluetooth()

    await b.connect(print_response_handler=lambda s: print(s))

    await b.send_lua("function process_function(data) print(data) end")
    await b.send_lua("frame.compression.process_function(process_function)")
    await b.send_lua("frame.compression.decompress(1024)")
    await b.send_lua("process_function(1)")

    await asyncio.sleep(1)

    await b.disconnect()


asyncio.run(main())
