import asyncio
from frameutils import Bluetooth


async def main():
    bluetooth = Bluetooth()

    await bluetooth.connect(
        print_response_handler=lambda string: print(f"Print: {string}"),
        data_response_handler=lambda data: print(f"Data: {data.decode()}"),
    )

    await bluetooth.send_reset_signal()
    await bluetooth.send_lua("function ble_event(d)frame.bluetooth.send(d)end")
    await bluetooth.send_lua("frame.bluetooth.peripheral_receive_callback(ble_event)")
    await bluetooth.send_lua("for i=1,10 do print(i); frame.sleep(1) end")

    await asyncio.sleep(1)
    await bluetooth.send_data(b"hello there")
    await asyncio.sleep(1)
    await bluetooth.send_data(b"hello")
    await asyncio.sleep(10)

    await bluetooth.disconnect()


asyncio.run(main())
