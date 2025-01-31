import asyncio
from frameutils import Bluetooth


async def main():

    b = Bluetooth()

    await b.connect(print_response_handler=lambda s: print(s))

    # Upload the Lua script
    lua_script = """
        -- Decompression function
        function decomp_func(data)
            print(data)
        end

        -- Register the decompression function
        frame.compression.process_function(decomp_func)

        -- Function to handle the compressed data received from Bluetooth
        function ble_func(data)    
            frame.compression.decompress(data, 1024)
        end

        -- Register the Bluetooth receive callback
        frame.bluetooth.receive_callback(ble_func)

    """

    await b.upload_file(lua_script, "main.lua")
    await b.send_reset_signal()

    await asyncio.sleep(1)

    # Send the compressed data. Here the total size of the data is is pretty small,
    # but usually you would want to split the data into MTU sized chunks and stitch
    # them together on the device side before decompressing.
    compressed_data = bytearray(
        b"\x04\x22\x4d\x18\x64\x40\xa7\x6f\x00\x00\x00\xf5\x3d\x48\x65\x6c\x6c\x6f\x21\x20\x49\x20\x77\x61\x73\x20\x73\x6f\x6d\x65\x20\x63\x6f\x6d\x70\x72\x65\x73\x73\x65\x64\x20\x64\x61\x74\x61\x2e\x20\x49\x6e\x20\x74\x68\x69\x73\x20\x63\x61\x73\x65\x2c\x20\x73\x74\x72\x69\x6e\x67\x73\x20\x61\x72\x65\x6e\x27\x74\x20\x70\x61\x72\x74\x69\x63\x75\x6c\x61\x72\x6c\x79\x3b\x00\xf1\x01\x69\x62\x6c\x65\x2c\x20\x62\x75\x74\x20\x73\x70\x72\x69\x74\x65\x49\x00\xa0\x20\x77\x6f\x75\x6c\x64\x20\x62\x65\x2e\x00\x00\x00\x00\x5f\xd0\xa3\x47"
    )

    await b.send_data(compressed_data)

    await b.send_break_signal()
    await b.disconnect()


asyncio.run(main())
