"""
Tests the Frame specific Lua libraries over Bluetooth.
"""

import asyncio, sys
from frameutils import Bluetooth


class TestBluetooth(Bluetooth):
    def __init__(self):
        self._passed_tests = 0
        self._failed_tests = 0

    def _log_passed(self, sent, responded):
        self._passed_tests += 1
        if responded == None:
            print(f"\033[92mPassed: {sent}")
        else:
            print(f"\033[92mPassed: {sent} => {responded}")

    def _log_failed(self, sent, responded, expected):
        self._failed_tests += 1
        if expected == None:
            print(f"\033[91mFAILED: {sent} => {responded}")
        else:
            print(f"\033[91mFAILED: {sent} => {responded} != {expected}")

    async def initialize(self):
        await self.connect()

    async def end(self):
        passed_tests = self._passed_tests
        total_tests = self._passed_tests + self._failed_tests
        print("\033[0m")
        print(f"Done! Passed {passed_tests} of {total_tests} tests")
        await self.disconnect()

    async def lua_equals(self, send: str, expect):
        response = await self.send_lua(f"print({send})", await_print=True)
        if response == str(expect):
            self._log_passed(send, response)
        else:
            self._log_failed(send, response, expect)

    async def lua_is_type(self, send: str, expect):
        response = await self.send_lua(f"print(type({send}))", await_print=True)
        if response == str(expect):
            self._log_passed(send, response)
        else:
            self._log_failed(send, response, expect)

    async def lua_has_length(self, send: str, length: int):
        response = await self.send_lua(f"print({send})", await_print=True)
        if len(response) == length:
            self._log_passed(send, response)
        else:
            self._log_failed(send, f"len({len(response)})", f"len({length})")

    async def lua_send(self, send: str):
        response = await self.send_lua(send + ";print(nil)", await_print=True)
        if response == "nil":
            self._log_passed(send, None)
        else:
            self._log_failed(send, response, None)

    async def lua_error(self, send: str):
        response = await self.send_lua(send + ";print(nil)", await_print=True)
        if response != "nil":
            self._log_passed(send, response.partition(":1: ")[2])
        else:
            self._log_failed(send, response, None)

    async def data_equal(self, send: bytearray, expect: bytearray):
        response = await self.send_data(send, await_data=True)
        if response == expect:
            self._log_passed(send, response)
        else:
            self._log_failed(send, response, expect)


async def main():
    test = TestBluetooth()
    await test.initialize()

    # Version
    await test.lua_is_type("frame.HARDWARE_VERSION", "string")
    await test.lua_has_length("frame.FIRMWARE_VERSION", 12)
    await test.lua_has_length("frame.GIT_TAG", 7)

    # Bluetooth

    ## MAC address
    await test.lua_has_length("frame.bluetooth.address()", 17)

    ## Send and receive callback
    await test.lua_send(
        "frame.bluetooth.receive_callback((function(d)frame.bluetooth.send(d)end))"
    )
    await test.data_equal(b"test", b"test")
    await test.lua_send("frame.bluetooth.receive_callback(nil)")

    ## MTU size
    max_length = test.max_data_payload()
    await test.lua_equals("frame.bluetooth.max_length()", max_length)
    await test.lua_send("frame.bluetooth.send('123')")
    await test.lua_send("frame.bluetooth.send('12\\0003')")
    await test.lua_send(f"frame.bluetooth.send(string.rep('a',{max_length}))")
    await test.lua_error(f"frame.bluetooth.send(string.rep('a',{max_length + 1}))")

    # Display

    ## Power mode
    await test.lua_send("frame.display.power_save(true)")
    await asyncio.sleep(1)
    await test.lua_send("frame.display.power_save(false)")

    ## Text

    ### Position
    await test.lua_send("frame.display.text('Hello there!', 50, 50)")
    await test.lua_error("frame.display.text('Hello there!', 0, 50)")
    await test.lua_error("frame.display.text('Hello there!', 50, 0)")

    ### Spacing
    await test.lua_send("frame.display.text('Wide text!', 50, 100, {spacing=10})")

    ### Colors
    await test.lua_send("frame.display.text('Red', 50, 150, {color='RED'})")
    await test.lua_send("frame.display.text('Green', 50, 200, {color='GREEN'})")
    await test.lua_send("frame.display.text('Blue', 50, 250, {color='SKYBLUE'})")
    await test.lua_error("frame.display.text('Blue', 50, 250, {color='BLUE'})")

    await test.lua_send("frame.display.show()")
    await asyncio.sleep(1)

    ### Change colors
    await test.lua_send("frame.display.assign_color('RED', 0, 255, 128)")
    await test.lua_send("frame.display.assign_color('GREEN', 255, 0, 255)")
    await test.lua_send("frame.display.assign_color('SKYBLUE', 50, 50, 50)")
    await asyncio.sleep(1)

    await test.lua_error("frame.display.assign_color('BLUE', 0, 0, 0)")

    await test.lua_error("frame.display.assign_color('SKYBLUE', 256, 0, 0)")
    await test.lua_error("frame.display.assign_color('SKYBLUE', 0, 256, 0)")
    await test.lua_error("frame.display.assign_color('SKYBLUE', 0, 0, 256)")

    await test.lua_send("frame.display.assign_color_ycbcr('RED', 5, 3, 6)")
    await test.lua_send("frame.display.assign_color_ycbcr('GREEN', 6, 2, 3)")
    await test.lua_send("frame.display.assign_color_ycbcr('SKYBLUE', 8, 5, 2)")

    await test.lua_error("frame.display.assign_color_ycbcr('BLUE', 13, 4, 3)")

    await test.lua_error("frame.display.assign_color_ycbcr('RED', 16, 0, 0)")
    await test.lua_error("frame.display.assign_color_ycbcr('RED', 0, 8, 0)")
    await test.lua_error("frame.display.assign_color_ycbcr('RED', 0, 0, 8)")

    # TODO justification

    ## Vectors
    # TODO

    ## Sprites
    # TODO

    # Camera

    ## Test capture and ready flag
    await test.lua_send("frame.camera.capture{}")
    await test.lua_equals("frame.camera.image_ready()", "false")
    await test.lua_send("frame.sleep(0.05)")
    await test.lua_equals("frame.camera.image_ready()", "true")

    await test.lua_send("frame.camera.capture{}")
    await test.lua_equals("frame.camera.image_ready()", "false")
    await test.lua_send("frame.sleep(0.05)")
    await test.lua_equals("frame.camera.image_ready()", "true")

    ## Capture in different resolutions
    await test.lua_send("frame.camera.capture { resolution = 100 }")
    await test.lua_send("frame.camera.capture { resolution = 256 }")
    await test.lua_send("frame.camera.capture { resolution = 512 }")
    await test.lua_send("frame.camera.capture { resolution = 720 }")

    await test.lua_error("frame.camera.capture { resolution = 80 }")
    await test.lua_error("frame.camera.capture { resolution = 513 }")
    await test.lua_error("frame.camera.capture { resolution = 721 }")

    ## Capture in different quality
    await test.lua_send("frame.camera.capture { quality = 'VERY_HIGH' }")
    await test.lua_send("frame.camera.capture { quality = 'HIGH' }")
    await test.lua_send("frame.camera.capture { quality = 'MEDIUM' }")
    await test.lua_send("frame.camera.capture { quality = 'LOW' }")
    await test.lua_send("frame.camera.capture { quality = 'VERY_LOW' }")

    await test.lua_error("frame.camera.capture { quality = 50 }")
    await test.lua_error("frame.camera.capture { quality = 'BAD' }")

    ## Capture with different pan amounts
    await test.lua_send("frame.camera.capture { pan = -140 }")
    await test.lua_send("frame.camera.capture { pan = -75 }")
    await test.lua_send("frame.camera.capture { pan = 0 }")
    await test.lua_send("frame.camera.capture { pan = 75 }")
    await test.lua_send("frame.camera.capture { pan = 140 }")

    await test.lua_error("frame.camera.capture { pan = -141 }")
    await test.lua_error("frame.camera.capture { pan = 200 }")

    ## Read
    await test.lua_send("frame.sleep(0.1)")
    await test.lua_equals("#frame.camera.read(123)", "123")
    await test.lua_equals("#frame.camera.read_raw(54)", "54")

    ## Test sleep prevents captures
    await test.lua_send("frame.camera.power_save(true)")
    await test.lua_error("frame.camera.capture{}")
    await test.lua_send("frame.camera.power_save(false)")
    await test.lua_send("frame.sleep(0.1)")
    await test.lua_send("frame.camera.capture{}")

    ## Manual exposure & gain
    # TODO

    ## Auto exposure & gain
    # TODO

    # Microphone

    ## Start and stop mic in different modes
    await test.lua_send("frame.microphone.start{}")
    await test.lua_send("frame.microphone.stop()")

    await test.lua_send("frame.microphone.start{sample_rate=16000}")
    await test.lua_send("frame.microphone.stop()")

    await test.lua_send("frame.microphone.start{bit_depth=16}")
    await test.lua_send("frame.microphone.stop()")

    await test.lua_send("frame.microphone.start{sample_rate=16000, bit_depth=16}")
    await test.lua_send("frame.microphone.stop()")

    ## Unexpected parameters
    await test.lua_error("frame.microphone.start{sample_rate=24000}")
    await test.lua_error("frame.microphone.start{bit_depth=32}")

    ## Read some data
    await test.lua_send("frame.microphone.start{}")
    await asyncio.sleep(0.25)
    await test.lua_equals("#frame.microphone.read(10)", "10")
    await test.lua_equals("#frame.microphone.read(256)", "256")
    await test.lua_error("frame.microphone.read(11)")
    await test.lua_send("frame.microphone.stop()")

    # IMU

    ## Direction
    await test.lua_is_type("frame.imu.direction()['heading']", "number")
    await test.lua_is_type("frame.imu.direction()['roll']", "number")
    await test.lua_is_type("frame.imu.direction()['pitch']", "number")

    ## Tap callback
    await test.lua_send("frame.imu.tap_callback((function()print('tap')end))")
    await test.lua_send("frame.imu.tap_callback(nil)")

    # Time functions

    ## Delays
    await test.lua_send("frame.time.utc(1698756584)")
    await test.lua_send("frame.sleep(2.0)")
    await test.lua_equals("math.floor(frame.time.utc()+0.5)", "1698756586")

    ## Date now under different timezones
    await test.lua_send("frame.time.zone('0:00')")
    await test.lua_equals("frame.time.zone()", "+00:00")

    await test.lua_equals("frame.time.date()['second']", "46")
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

    # System functions

    ## Resets
    await test.send_reset_signal()
    await asyncio.sleep(1)
    await test.send_reset_signal()

    ## Battery level
    await test.lua_is_type("frame.battery_level()", "number")

    ## Preventing sleep
    await test.lua_equals("frame.stay_awake()", "false")
    await test.lua_send("frame.stay_awake(true)")
    await test.send_lua("frame.sleep()")
    await asyncio.sleep(1)
    await test.lua_equals("frame.stay_awake()", "true")
    await test.lua_send("frame.stay_awake(false)")

    ## Break from sleep early
    await test.send_lua("frame.sleep(100)")
    await asyncio.sleep(1)
    await test.send_break_signal()

    ## Update function exists
    await test.lua_is_type("frame.update", "function")

    ## FPGA IO
    await test.lua_equals("string.byte(frame.fpga_read(0xDB, 1))", "129")
    await test.lua_send("frame.fpga_write(0xDC, 'test data')")

    # File handling

    ## Test all modes (writable, read only, and append)
    await test.lua_send("f=frame.file.open('test.lua', 'w')")
    await test.lua_send("f:write('test 123')")
    await test.lua_send("f:close()")

    await test.lua_send("f=frame.file.open('test.lua', 'a')")
    await test.lua_send("f:write('\\n456')")
    await test.lua_send("f:close()")

    await test.lua_send("f=frame.file.open('test.lua', 'r')")
    await test.lua_error("f:write('789')")
    await test.lua_equals("f:read()", "test 123")
    await test.lua_equals("f:read()", "456")
    await test.lua_equals("f:read()", "nil")
    await test.lua_send("f:close()")

    # Reopening a file in write mode should erase the file
    await test.lua_send("f=frame.file.open('test.lua', 'w')")
    await test.lua_send("f:write('test 789')")
    await test.lua_send("f:close()")

    await test.lua_send("f=frame.file.open('test.lua', 'r')")
    await test.lua_equals("f:read()", "test 789")
    await test.lua_send("f:close()")

    ## Prevent operations when file is closed
    await test.lua_error("f:read()")
    await test.lua_error("f:write('000')")
    await test.lua_error("f:close()")

    ## List, rename and delete file
    await test.lua_equals("#frame.file.listdir('/')", "3")
    await test.lua_equals("frame.file.listdir('/')[3]['name']", "test.lua")
    await test.lua_equals("frame.file.listdir('/')[3]['size']", "8")
    await test.lua_equals("frame.file.listdir('/')[3]['type']", "1")
    await test.lua_send("frame.file.rename('test.lua', 'test2.lua')")
    await test.lua_equals("frame.file.listdir('/')[3]['name']", "test2.lua")
    await test.lua_send("frame.file.remove('test2.lua')")
    await test.lua_equals("#frame.file.listdir('/')", "2")

    ## Create and delete directories
    await test.lua_send("frame.file.mkdir('/this/is/some/path')")

    await test.lua_equals("#frame.file.listdir('/')", "3")
    await test.lua_equals("frame.file.listdir('/')[3]['name']", "this")
    await test.lua_equals("frame.file.listdir('/')[3]['type']", "2")

    await test.lua_send("frame.file.listdir('/this')")
    await test.lua_send("frame.file.listdir('/this/is')")
    await test.lua_error("frame.file.listdir('/this/is/not')")

    await test.lua_send("frame.file.remove('/this/is/some/path')")
    await test.lua_send("frame.file.remove('/this/is/some')")
    await test.lua_send("frame.file.remove('/this/is')")
    await test.lua_send("frame.file.remove('/this')")
    await test.lua_equals("#frame.file.listdir('/')", "2")

    # Standard libraries
    await test.lua_equals("math.sqrt(25)", "5.0")

    await test.end()


asyncio.run(main())
