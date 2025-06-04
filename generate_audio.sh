#!/bin/bash

# Script to generate placeholder audio files for the block puzzle game
# These are simple sine wave tones that can be replaced with real sound effects later

AUDIO_DIR="blockbomb/Assets.xcassets/Audio"
mkdir -p "$AUDIO_DIR"

echo "Generating placeholder audio files..."

# Function to generate a simple tone using afplay and sox (if available) or basic audio
generate_tone() {
    local filename=$1
    local frequency=$2
    local duration=$3
    local wave_type=${4:-"sine"}
    
    # Create a simple audio file using Python (most reliable cross-platform)
    python3 -c "
import math
import wave
import struct

def generate_tone(frequency, duration, sample_rate=44100, amplitude=0.5, wave_type='sine'):
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
        decay = max(0, 1 - (t / duration) * 0.5)
        value *= decay
        
        packed_value = struct.pack('<h', int(value * 32767))
        samples.append(packed_value)
    
    with wave.open('$filename', 'w') as wav_file:
        wav_file.setnchannels(1)  # mono
        wav_file.setsampwidth(2)  # 2 bytes per sample
        wav_file.setframerate($sample_rate)
        wav_file.writeframes(b''.join(samples))

generate_tone($frequency, $duration, wave_type='$wave_type')
"
}

# Generate sound files
echo "Creating block_place.wav..."
generate_tone "$AUDIO_DIR/block_place.wav" 440 0.1 "sine"

echo "Creating line clear sounds..."
generate_tone "$AUDIO_DIR/line_clear_single.wav" 523 0.3 "sine"  # C5
generate_tone "$AUDIO_DIR/line_clear_double.wav" 659 0.4 "sine"  # E5
generate_tone "$AUDIO_DIR/line_clear_triple.wav" 784 0.5 "sine"  # G5
generate_tone "$AUDIO_DIR/line_clear_quad.wav" 1047 0.6 "sine"   # C6

echo "Creating combo sounds..."
generate_tone "$AUDIO_DIR/combo_small.wav" 880 0.4 "sawtooth"    # A5
generate_tone "$AUDIO_DIR/combo_medium.wav" 1109 0.5 "sawtooth"  # C#6
generate_tone "$AUDIO_DIR/combo_large.wav" 1319 0.6 "sawtooth"   # E6

echo "Creating game state sounds..."
generate_tone "$AUDIO_DIR/game_over.wav" 220 1.0 "sine"         # A3 - low, sad
generate_tone "$AUDIO_DIR/new_high_score.wav" 1760 1.5 "sine"   # A6 - high, celebratory
generate_tone "$AUDIO_DIR/invalid_placement.wav" 150 0.2 "square" # Very low, harsh

echo "All placeholder audio files generated!"
echo "These are basic tone files. Replace them with professional sound effects for production."
