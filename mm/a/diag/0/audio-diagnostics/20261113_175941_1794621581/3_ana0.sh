python3 - <<'PY'
import wave, array, math

path = "3.capture_default.wav"
window_ms = 10

with wave.open(path, "rb") as w:
    channels = w.getnchannels()
    rate = w.getframerate()
    width = w.getsampwidth()
    frames = w.getnframes()
    raw = w.readframes(frames)

if width != 2:
    raise SystemExit(f"Expected 16-bit PCM; got {width * 8}-bit")

samples = array.array("h")
samples.frombytes(raw)

if __import__("sys").byteorder != "little":
    samples.byteswap()

window_frames = rate * window_ms // 1000
results = []

for start in range(0, frames, window_frames):
    end = min(start + window_frames, frames)
    vals = [[], []]

    for i in range(start * channels, end * channels, channels):
        vals[0].append(samples[i])
        vals[1].append(samples[i + 1])

    peaks = [max(abs(x) for x in v) for v in vals]
    rms = [
        math.sqrt(sum(x*x for x in v) / len(v))
        for v in vals
    ]

    results.append((
        max(peaks),
        start / rate,
        peaks,
        rms
    ))

print(f"Duration: {frames / rate:.3f}s; window: {window_ms}ms")
print("Top 25 windows by peak amplitude:")

for peak, t, peaks, rms in sorted(
    results, key=lambda x: x[0], reverse=True
)[:25]:
    db = 20 * math.log10(max(peak, 1) / 32768)
    print(
        f"{t:8.3f}s  peak={db:7.2f} dBFS  "
        f"L={peaks[0]:6d} R={peaks[1]:6d}  "
        f"RMS_L={rms[0]:7.1f} RMS_R={rms[1]:7.1f}"
    )
PY
