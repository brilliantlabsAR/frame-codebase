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

    ## Test all modes (writable, read only, and append)
    await test.lua_send("frame.file.mkdir('/this/is/some/path')")
    await test.lua_send("frame.file.listdir('/')")
    await test.lua_send("frame.file.listdir('/this')")
    await test.lua_send("frame.file.listdir('/this/is')")
    await test.lua_send("frame.file.listdir('/this/is/not')")

    # await test.lua_send("f=frame.file.open('test.lua', 'w')")
    # await test.lua_send("f:write('test 123\\n456')")
    # await test.lua_send("f:close()")

    # await test.lua_send("f=frame.file.open('test.lua', 'r')")
    # await test.lua_equals("f:read()", "test 123")
    # await test.lua_equals("f:read()", "456")
    # await test.lua_equals("f:read()", "nil")
    # await test.lua_send("f:close()")

    sys.exit(0)

    await test.lua_send("f=frame.file.open('test.lua', 'r')")
    await test.lua_error("f:write('456')")
    await test.lua_equals("f:read()", "test 123")
    await test.lua_send("f:close()")

    await test.lua_send("f=frame.file.open('test.lua', 'a')")
    await test.lua_send("f:write('456')")
    await test.lua_send("f:close()")

    await test.lua_send("f=frame.file.open('test.lua', 'r')")
    await test.lua_equals("f:read()", "test 123456")
    await test.lua_send("f:close()")

    ## Open with writable should reset file
    await test.lua_send("f=frame.file.open('test.lua', 'w')")
    await test.lua_send("f:write('test 789')")
    await test.lua_send("f:close()")

    await test.lua_send("f=frame.file.open('test.lua', 'r')")
    await test.lua_equals("f:read()", "789")
    await test.lua_send("f:close()")

    ## Prevent operations when file is closed
    # await test.lua_error("f:read()")
    # await test.lua_error("f:write('000')")
    # await test.lua_error("f:close()")

    ## List, rename and delete file
    await test.lua_equals("frame.file.listdir()", "table")
    await test.lua_send("file.file.rename('test.lua', 'test2.lua')")
    await test.lua_send("file.file.rename('test2.lua', 'test3.lua')")
    await test.lua_equals("frame.file.listdir()", "table")
    await test.lua_send("frame.file.remove('test3.lua')")
    await test.lua_error("frame.file.remove('test3.lua')")
    await test.lua_equals("frame.file.listdir()", "table")

    ## Create and delete directories
    await test.lua_send("frame.file.mkdir('my_dir1/nested_dir1')")
    await test.lua_equals("frame.file.listdir('my_dir1')", "table")
    await test.lua_send("frame.file.remove('my_dir1')")
    await test.lua_error("frame.file.listdir('my_dir1')")

    await test.end()


asyncio.run(main())
