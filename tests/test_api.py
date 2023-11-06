"""
Tests the Frame specific Lua libraries over Bluetooth.
"""

import asyncio, sys
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
            self._log_passed(lua_string, response.partition(":1: ")[2])
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
    ## TODO frame.bluetooth.data_receive_callback?()

    # Display
    ## TODO frame.display.text("string", x, y, {color, alignment})
    ## TODO frame.display.show()

    # Camera
    ## TODO camera.output_format(xres, yres, colordepth)
    ## TODO pan and zoom?
    ## TODO camera.capture()
    ## TODO camera.read(bytes)

    # Microphone
    await test.lua_send("frame.microphone.record(10.0001, 4000, 16)")
    await asyncio.sleep(1)
    await test.lua_send("frame.microphone.record(20, 4000, 16)")
    # await test.lua_equals("frame.microphone.read()[0]", "0")

    # IMU
    ## imu.heading().exactly                 => ±180 degrees
    ## imu.heading().roughly                 => N, NNE, NE, NEE, E, ...
    ## imu.yaw().exactly                     => ±180 degrees
    ## imu.yaw().roughly                     => LEFT, SLIGHTLY_LEFT, CENTER, ...
    ## imu.pitch().exactly                   => ±180 degrees
    ## imu.pitch().roughly                   => UP, SLIGHTLY_UP, CENTER
    ## TODO Tap, double tap?

    # Time & sleep functions

    ## Delays
    await test.lua_send("frame.time.utc(1698756584)")
    await test.lua_send("frame.sleep(2.0)")
    await test.lua_equals("math.floor(frame.time.utc()+0.5)", "1698756586")

    ## Cancelling deep sleep
    await test.send_lua("frame.sleep()", wait=False)
    await asyncio.sleep(2)
    await test.send_break_signal()

    ## Date now under different timezones
    await test.lua_send("frame.time.zone('0:00')")
    await test.lua_equals("frame.time.zone()", "+00:00")

    await test.lua_equals("frame.time.date()['second']", "48")
    await test.lua_equals("frame.time.date()['minute']", "49")
    await test.lua_equals("frame.time.date()['hour']", "12")
    await test.lua_equals("frame.time.date()['day']", "31")
    await test.lua_equals("frame.time.date()['month']", "10")
    await test.lua_equals("frame.time.date()['year']", "2023")
    await test.lua_equals("frame.time.date()['weekday']", "2")
    await test.lua_equals("frame.time.date()['day of year']", "303")
    await test.lua_equals("frame.time.date()['is daylight saving']", "false")

    await test.lua_send("frame.time.zone('2:30')")
    await test.lua_equals("frame.time.zone()", "+02:30")

    await test.lua_equals("frame.time.date()['minute']", "19")
    await test.lua_equals("frame.time.date()['hour']", "15")

    await test.lua_send("frame.time.zone('-3:45')")
    await test.lua_equals("frame.time.zone()", "-03:45")

    ## Invalid timezones
    await test.lua_error("frame.time.zone('0:25')")
    await test.lua_error("frame.time.zone('15:00')")
    await test.lua_error("frame.time.zone('-13:00')")

    ## Date table from UTC timestamp
    await test.lua_send("frame.time.zone('+01:00')")
    await test.lua_equals("frame.time.date(1698943733)['second']", "53")
    await test.lua_equals("frame.time.date(1698943733)['minute']", "48")
    await test.lua_equals("frame.time.date(1698943733)['hour']", "17")
    await test.lua_equals("frame.time.date(1698943733)['day']", "2")
    await test.lua_equals("frame.time.date(1698943733)['month']", "11")
    await test.lua_equals("frame.time.date(1698943733)['year']", "2023")
    await test.lua_equals("frame.time.date(1698943733)['weekday']", "4")
    await test.lua_equals("frame.time.date(1698943733)['day of year']", "305")
    await test.lua_equals("frame.time.date(1698943733)['is daylight saving']", "false")

    # Misc
    await test.lua_equals("frame.battery_level()", "100.0")
    await test.lua_equals("frame.stay_awake()", "false")
    await test.lua_send("frame.stay_awake(true)")
    await test.lua_equals("frame.stay_awake()", "true")
    await test.lua_send("frame.stay_awake(false)")
    ## frame.fpga.read()
    ## frame.fpga.write()

    # File handling
    ## TODO frame.file.open()
    ## frame.file.read()
    ## TODO frame.file.write()
    ## TODO frame.file.close()
    ## TODO frame.file.remove()
    ## frame.file.rename()

    # Standard libraries
    await test.lua_equals("math.sqrt(25)", "5.0")

    await test.end()


asyncio.run(main())
