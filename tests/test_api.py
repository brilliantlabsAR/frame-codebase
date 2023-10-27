"""
Tests the Frame specific Lua libraries over Bluetooth.
"""

import asyncio
from frameutils import Bluetooth


class TestBluetooth(Bluetooth):
    def __init__(self):
        self._passed_tests = 0
        self._failed_tests = 0

    def _log_passed(self, lua_string, response):
        self._passed_tests += 1
        print(f"\033[92mPassed: {lua_string} => {response}")

    def _log_failed(self, lua_string, response, expected):
        self._failed_tests += 1
        print(f"\033[91mFAILED: {lua_string} => {response} != {expected}")

    async def initialize(self):
        await self.connect(lua_response_handler=lambda str: None)

    async def end(self):
        passed_tests = self._passed_tests
        total_tests = self._passed_tests + self._failed_tests
        print("\033[0m")
        print(f"Done! Passed {passed_tests} of {total_tests} tests")
        await self.disconnect()

    async def lua_equals(self, lua_string: str, expect: str):
        response = await self.send_lua(f"print({lua_string})", wait=True)
        if response == expect:
            self._log_passed(lua_string, response)
        else:
            self._log_failed(lua_string, response, expect)

    async def lua_has_length(self, lua_string: str, length: int):
        response = await self.send_lua(f"print({lua_string})", wait=True)
        if len(response) == length:
            self._log_passed(lua_string, response)
        else:
            self._log_failed(lua_string, f"len({len(response)})", f"len({length})")


async def main():
    test = TestBluetooth()
    await test.initialize()

    # Test device module
    await test.lua_equals("frame.device.NAME", "frame")
    await test.lua_has_length("frame.device.FIRMWARE_VERSION", 12)
    await test.lua_has_length("frame.device.GIT_TAG", 7)
    await test.lua_has_length("frame.device.mac_address()", 17)
    await test.lua_equals("frame.device.battery_level()", "100.0")

    await test.end()


asyncio.run(main())
