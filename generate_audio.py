#!/usr/bin/env python3
"""
Script to generate placeholder audio files for the block puzzle game
These are simple sine wave tones that can be replaced with real sound effects later
"""

import math
import wave
import struct
import os

def generate_tone(filename, frequency, duration, sample_rate=44100, amplitude=0.3, wave_type='sine'):
    """Generate a simple audio tone and save it as a WAV file"""
    frames = int(duration * sample_rate)
    samples = []
    
    for i in range(frames):
        t = float(i) / sample_rate
        if wave_type == 'sine':
            value = amplitude * math.sin(2 * math.pi * frequency * t)
        elif wave_type == 'square':
            value = amplitude * (1 if math.sin(2 * math.pi * frequency * t) > 0 else -1)
        elif wave_type == 'sawtooth':
            value = amplitude * (2 * (t * frequency - math.floor(t * frequency + 0.5)))
        else:
            value = amplitude * math.sin(2 * math.pi * frequency * t)
        
        # Add some decay for more realistic sound
        decay = max(0.1, 1 - (t / duration) * 0.7)
        value *= decay
        
        # Convert to 16-bit integer
        sample_value = int(value * 32767)
        # Clamp to prevent overflow
        sample_value = max(-32767, min(32767, sample_value))
        packed_value = struct.pack('<h', sample_value)
        samples.append(packed_value)
    
    # Create directory if it doesn't exist
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # mono
        wav_file.setsampwidth(2)  # 2 bytes per sample
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(b''.join(samples))
    
    print(f"Generated: {filename}")

def create_dataset_contents(dataset_name, filename):
    """Create Contents.json file for a dataset"""
    contents = {
        "data": [
            {
                "filename": filename,
                "idiom": "universal"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    import json
    with open(f"blockbomb/Assets.xcassets/{dataset_name}.dataset/Contents.json", 'w') as f:
        json.dump(contents, f, indent=2)

def main():
    assets_dir = "blockbomb/Assets.xcassets"
    
    print("Generating placeholder audio files...")
    
    # Define audio files with their dataset names
    audio_files = [
        ("block_place", 440, 0.1, "sine"),
        ("line_clear_single", 523, 0.3, "sine"),
        ("line_clear_double", 659, 0.4, "sine"),
        ("line_clear_triple", 784, 0.5, "sine"),
        ("line_clear_quad", 1047, 0.6, "sine"),
        ("combo_small", 880, 0.4, "sawtooth"),
        ("combo_medium", 1109, 0.5, "sawtooth"),
        ("combo_large", 1319, 0.6, "sawtooth"),
        ("game_over", 220, 1.0, "sine"),
        ("new_high_score", 1760, 1.5, "sine"),
        ("invalid_placement", 150, 0.2, "square")
    ]
    
    for name, freq, duration, wave_type in audio_files:
        filename = f"{name}.wav"
        dataset_path = f"{assets_dir}/{name}.dataset"
        audio_path = f"{dataset_path}/{filename}"
        
        # Generate the audio file
        generate_tone(audio_path, freq, duration, wave_type=wave_type)
        
        # Create the Contents.json file for the dataset
        create_dataset_contents(name, filename)
    
    print("\nAll placeholder audio files generated!")
    print("These are basic tone files. Replace them with professional sound effects for production.")
    print(f"\nFiles created in: {assets_dir}/")

if __name__ == "__main__":
    main()
