from frameutils import Bluetooth
import asyncio
import numpy as np
import sounddevice as sd

audio_buffer = b""
expected_samples = 0


def receive_data(data):
    global audio_buffer
    global expected_samples
    audio_buffer += data
    print(
        f"                        Downloading microphone data {str(len(audio_buffer))} / {str(int(expected_samples))} bytes      ",
        end="\r",
    )


async def test_microphone(b: Bluetooth):
    global audio_buffer
    global expected_samples
    expected_samples = 3 * 8000 * (8 / 8)

    await b.send_lua("frame.microphone.record(3, 8000, 8)")
    await asyncio.sleep(0.5)

    audio_buffer = b""

    mtu = b.max_data_payload()

    while len(audio_buffer) < expected_samples:
        await b.send_lua(f"frame.bluetooth.send(frame.microphone.read({mtu}))")

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
