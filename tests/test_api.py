"""
Tests the Frame specific Lua libraries over Bluetooth.
"""

import asyncio
import sys
from frameutils import Bluetooth


class TestBluetooth(Bluetooth):
    def __init__(self):
        self._passed_tests = 0
        self._failed_tests = 0

    def _log_passed(self, lua_string, response):
        self._passed_tests += 1
        if response == None:
            print(f"\033[92mPassed: {lua_string}")
        else:
            print(f"\033[92mPassed: {lua_string} => {response}")

    def _log_failed(self, lua_string, response, expected):
        self._failed_tests += 1
        if expected == None:
            print(f"\033[91mFAILED: {lua_string} => {response}")
        else:
            print(f"\033[91mFAILED: {lua_string} => {response} != {expected}")

    async def initialize(self):
        await self.connect(
            lua_response_handler=lambda str: None,
            data_response_handler=lambda str: None,
        )

    async def end(self):
        passed_tests = self._passed_tests
        total_tests = self._passed_tests + self._failed_tests
        print("\033[0m")
        print(f"Done! Passed {passed_tests} of {total_tests} tests")
        await self.disconnect()

    async def lua_equals(self, lua_string: str, expect):
        response = await self.send_lua(f"print({lua_string})", wait=True)
        if response == str(expect):
            self._log_passed(lua_string, response)
        else:
            self._log_failed(lua_string, response, expect)

    async def lua_has_length(self, lua_string: str, length: int):
        response = await self.send_lua(f"print({lua_string})", wait=True)
        if len(response) == length:
            self._log_passed(lua_string, response)
        else:
            self._log_failed(lua_string, f"len({len(response)})", f"len({length})")

    async def lua_send(self, lua_string: str):
        response = await self.send_lua(lua_string + ";print(nil)", wait=True)
        if response == "nil":
            self._log_passed(lua_string, None)
        else:
            self._log_failed(lua_string, response, None)

    async def lua_error(self, lua_string: str):
        response = await self.send_lua(lua_string + ";print(nil)", wait=True)
        if response != "nil":
            self._log_passed(lua_string, response)
        else:
            self._log_failed(lua_string, response, None)

    async def data_equal(self, lua_string: str, reponse: bytearray):
        pass


async def main():
    test = TestBluetooth()
    await test.initialize()

    # Version
    await test.lua_has_length("frame.FIRMWARE_VERSION", 12)
    await test.lua_has_length("frame.GIT_TAG", 7)

    # Bluetooth
    await test.lua_has_length("frame.bluetooth.address()", 17)
    max_length = test.max_data_payload()
    await test.lua_equals("frame.bluetooth.data_max_length()", max_length)
    await test.lua_send("frame.bluetooth.data_send('123')")
    await test.lua_send("frame.bluetooth.data_send('12\\0003')")
    await test.lua_send(f"frame.bluetooth.data_send(string.rep('a',{max_length}))")
    await test.lua_error(f"frame.bluetooth.data_send(string.rep('a',{max_length + 1}))")
    ## TODO test multiple bluetooth sends which block
    ## frame.bluetooth.data_receive_callback?()

    # Display
    ## frame.display.text("string", x, y, {color, alignment})
    ## frame.display.show()

    # Camera
    ## camera.output_format(xres, yres, colordepth)
    ## pan and zoom?
    ## camera.capture()
    ## camera.read(bytes)

    # Microphone
    ## frame.microphone.record(seconds, samplerate, bitdepth)
    ## frame.microphone.read(bytes)

    # IMU
    ## imu.heading().exactly                 => ±180 degrees
    ## imu.heading().roughly                 => N, NNE, NE, NEE, E, ...
    ## imu.yaw().exactly                     => ±180 degrees
    ## imu.yaw().roughly                     => LEFT, SLIGHTLY_LEFT, CENTER, ...
    ## imu.pitch().exactly                   => ±180 degrees
    ## imu.pitch().roughly                   => UP, SLIGHTLY_UP, CENTER
    ## Tap, double tap?

    # Sleep
    ## frame.sleep(1.0)
    ## frame.sleep() # Wakes up on a tap event

    # Time
    ## frame.time()                          => get epoch
    ## frame.time.set_utc(epoch)             => set epoch
    ## frame.time.zone()                     => get timezeone
    ## frame.time.zone(offset)               => set timeznone
    ## frame.time.date()                     => get current time as table
    ## frame.time.date(epoch)                => get table from epoch
    ## frame.time.date({day, month, ..})     => get epoch from table

    # Misc
    await test.lua_equals("frame.battery_level()", "100.0")
    await test.lua_equals("frame.stay_awake()", "false")
    await test.lua_send("frame.stay_awake(true)")
    await test.lua_equals("frame.stay_awake()", "true")
    await test.lua_send("frame.stay_awake(false)")
    ## frame.fpga.read()
    ## frame.fpga.write()

    # File handling
    ## frame.file.open()
    ## frame.file.read()
    ## frame.file.write()
    ## frame.file.close()
    ## frame.file.remove()
    ## frame.file.rename()

    # Math
    await test.lua_equals("math.sqrt(25)", "5.0")

    await test.end()


asyncio.run(main())
