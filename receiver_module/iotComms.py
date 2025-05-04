def is_one_element_away(listA, listB):
    lenA = len(listA)
    mistakes = 0
    
    for i in range(lenA):
        if listA[i] != listB[i]:
            mistakes += 1
        if mistakes >= 2:
            return False
    return True



import sounddevice as sd
import numpy as np
import scipy.io.wavfile as wav

# Settings
PREAMBLE = [1, 0, 1, 0, 1, 0, 1, 0]
DELIMITER = [1, 1, 1, 1, 0, 0, 0, 0]
sample_rate = 6000  # Hz
bit_duration = 30.0 #ms
duration = (bit_duration/1000 * 16 + 1) * 2  # seconds

# 60 samples = 1 bit

print("Recording...")

# Record audio
audio_data = sd.rec(int(duration * sample_rate), samplerate=sample_rate, channels=1, dtype='int16')
sd.wait()

audio_data = np.abs(audio_data)

chunk_size = int(sample_rate * bit_duration/1000)
trimmed_length = (len(audio_data) // chunk_size) * chunk_size
# medians = audio_data[:trimmed_length].reshape(-1, chunk_size).median(axis=1)
medians = np.median(audio_data[:trimmed_length].reshape(-1, chunk_size), axis=1)
threshold = 100
print('medians', medians)
bits = (medians > threshold).astype(int)
print('BITS: ', bits)

for i in range(len(bits) - 15):
    if(is_one_element_away(bits[i : i+8], PREAMBLE)):
        if(bits[i+8 : i+16] == DELIMITER):
            temperature_str = ''.join(str(bit) for bit in bits[i+16 : i+24])
            conductivity_str = ''.join(str(bit) for bit in bits[i+24 : i+32])

            # Convert to decimal
            temperature = int(temperature_str, 2) / 100
            conductivity = int(conductivity_str, 2) / 100

            break


# Save to WAV
# wav.write('recording.wav', sample_rate, audio_data)
print("Audio Data Shape:", audio_data.shape)
print("Saved as 'recording.wav'")

print("Temperature:", temperature)
print("Conductivity:", conductivity)
