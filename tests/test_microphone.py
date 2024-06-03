"""
Tests the Frame specific Lua libraries over Bluetooth.
"""

import asyncio
from frameutils import Bluetooth
import sounddevice as sd
import numpy as np

audio_buffer = b""


def receive_data(data):
    global audio_buffer
    audio_buffer += data
    print(f"Received {str(len(audio_buffer))} bytes", end="\r")


async def record_and_play(b: Bluetooth, sample_rate, bit_depth):
    global audio_buffer

    audio_buffer = b""

    print(f"Streaming at {sample_rate/1000}kHz {bit_depth}bit")
    await b.send_lua(
        f"frame.microphone.start{{sample_rate={sample_rate}, bit_depth={bit_depth}}}"
    )

    # await asyncio.sleep(1)

    await b.send_lua(
        f"while true do s=frame.microphone.read({b.max_data_payload()}); if s==nil then break end if s~='' then while true do if (pcall(frame.bluetooth.send,s)) then break end end end end"
    )

    await asyncio.sleep(5)

    await b.send_break_signal()
    await b.send_lua(f"frame.microphone.stop()")

    print("\nConverting to audio")

    # Convert audio bytes to a NumPy array of type int8
    if bit_depth == 16:
        audio_data = np.frombuffer(audio_buffer, dtype=np.int16)
    if bit_depth == 8:
        audio_data = np.frombuffer(audio_buffer, dtype=np.int8)

    # Convert it to float32 which is what sounddevice expects for playback
    audio_data = audio_data.astype(np.float32)

    # Normalize the 8 or 16 bit data range to (-1, 1) for playback
    if bit_depth == 16:
        audio_data /= np.iinfo(np.int16).max
    if bit_depth == 8:
        audio_data /= np.iinfo(np.int8).max

    sd.play(audio_data, sample_rate)

    sd.wait()


async def main():
    b = Bluetooth()

    await b.connect(data_response_handler=receive_data)

    await record_and_play(b, 8000, 8)
    await record_and_play(b, 8000, 16)
    await record_and_play(b, 16000, 8)

    await b.disconnect()


asyncio.run(main())
