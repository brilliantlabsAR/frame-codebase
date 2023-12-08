"""
Tests the Frame specific Lua libraries over Bluetooth.
"""

import asyncio
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

    # TODO frame.file.open()
    await test.lua_send("f=frame.file.open('test.lua', 'w')")
    await test.lua_send("f:write('test')")
    await test.lua_send("f:close()")
    await test.lua_send("f=frame.file.open('test.lua', 'r')")
    await test.lua_equals("f:read()", "test")
    await test.lua_send("f:close()")
    # frame.file.read()
    # TODO frame.file.write()
    # TODO frame.file.close()
    # TODO frame.file.remove()
    # frame.file.rename()

    await test.end()


asyncio.run(main())
