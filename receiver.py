import sounddevice as sd
import numpy as np
import scipy.io.wavfile as wav

# Settings
duration = 16  # seconds
sample_rate = 6000  # Hz
# 60 samples = 1 bit

print("Recording...")

# Record audio
audio_data = sd.rec(int(duration * sample_rate), samplerate=sample_rate, channels=1, dtype='int16')
audio_data = np.abs(audio_data)

sd.wait()

chunk_size = 6000 # sample_rate * bit_duration
trimmed_length = (len(audio_data) // chunk_size) * chunk_size
# medians = audio_data[:trimmed_length].reshape(-1, chunk_size).median(axis=1)
medians = np.median(audio_data[:trimmed_length].reshape(-1, chunk_size), axis=1)
threshold = 50
print('medians', medians)
bits = (medians > threshold).astype(int)
print('BITS: ', bits)

# Save to WAV
# wav.write('recording.wav', sample_rate, audio_data)
print(audio_data.shape)

print("Saved as 'recording.wav'")

import numpy as np
import sounddevice as sd
import time
import scipy.signal as signal
import threading
import queue

# 1's: [22179.5  9147.   8307.   2172.   9565.   6926.5  5330.   3025.   7104.
#  4206.5  3708.5 11122.  25123.5 24947.  25199.  25185. ]

