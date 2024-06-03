from frameutils import Bluetooth
import asyncio
import numpy as np
import sounddevice as sd

audio_buffer = b""
expected_length = 0


def receive_data(data):
    global audio_buffer
    audio_buffer += data
    print(
        f"                        Downloading microphone data {str(len(audio_buffer))} bytes      ",
        end="\r",
    )


async def test_microphone(b: Bluetooth):
    global audio_buffer
    audio_buffer = b""

    await b.send_lua("frame.microphone.start { bit_depth=16 }")

    await b.send_lua(
        "while true do s=frame.microphone.read(frame.bluetooth.max_length()); if s==nil then break end if s~='' then while true do if (pcall(frame.bluetooth.send,s)) then break end end end end"
    )

    await asyncio.sleep(5)

    await b.send_break_signal()
    await b.send_lua(f"frame.microphone.stop()")

    audio_data = np.frombuffer(audio_buffer, dtype=np.int16)
    audio_data = audio_data.astype(np.float32)
    audio_data /= np.iinfo(np.int16).max

    sd.play(audio_data, 8000)
    sd.wait()


async def main():
    b = Bluetooth()
    await b.connect(data_response_handler=receive_data)
    await test_microphone(b)
    await b.disconnect()


asyncio.run(main())
