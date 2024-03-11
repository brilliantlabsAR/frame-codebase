from frameutils import Bluetooth
import asyncio
import numpy as np
import sounddevice as sd

audio_buffer = b""
expected_length = 0


def receive_data(data):
    global audio_buffer
    global expected_length
    audio_buffer += data
    print(
        f"                        Downloading microphone data {str(len(audio_buffer))} / {str(int(expected_length))} bytes      ",
        end="\r",
    )


async def test_microphone(b: Bluetooth):
    global audio_buffer
    global expected_length
    expected_length = 3 * 8000 * (8 / 8)

    await b.send_lua("frame.microphone.record{seconds=3}")
    await asyncio.sleep(3)

    audio_buffer = b""

    await b.send_lua(
        "while true do local i = frame.microphone.read(frame.bluetooth.max_length()) if (i == nil) then break end while true do if pcall(frame.bluetooth.send, i) then break end end end"
    )

    while len(audio_buffer) < expected_length:
        await asyncio.sleep(0.001)

    audio_data = np.frombuffer(audio_buffer, dtype=np.int8)
    audio_data = audio_data.astype(np.float32)
    audio_data /= np.iinfo(np.int8).max

    sd.play(audio_data, 8000)
    sd.wait()


if __name__ == "__main__":
    b = Bluetooth()

    loop = asyncio.get_event_loop()
    loop.run_until_complete(b.connect(data_response_handler=receive_data))
    loop.run_until_complete(test_microphone(b))
    loop.run_until_complete(b.disconnect())
