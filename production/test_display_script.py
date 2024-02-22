from frameutils import Bluetooth
import asyncio


async def test_display(b: Bluetooth):
    await b.send_lua("frame.display.clear()")
    await b.send_lua(f"frame.display.text('Hello Frame!', 50, 50)")
    await b.send_lua(f"frame.display.text('The quick brown fox jumped', 50, 150)")
    await b.send_lua(f"frame.display.text('over the lazy dog.', 50, 200)")
    await b.send_lua("frame.display.show()")


if __name__ == "__main__":
    b = Bluetooth()

    loop = asyncio.get_event_loop()
    loop.run_until_complete(b.connect())
    loop.run_until_complete(test_display(b))
    loop.run_until_complete(b.disconnect())
