#!/bin/bash
# /src/hd-driver/omti/run-stock-session.sh
#
# Provenance: interactive session. Boots STOCK G-DOS 2.4 from the floppy via
# Sopp's 1986 EPROM's forced-floppy path, with the OMTI hard disk attached,
# and then gets out of the way.
#
#   ./run-stock-session.sh [image.hdv]
#
# No timer, no screen dump, no pass/fail. The emulator window is yours: type
# at it, run HDFORMAT, GENDIR 5, COPY, whatever the session needs. The script
# only exists to set the forced-floppy latch, which cannot be done from the
# keyboard once the machine is already running.
#
# The forced-floppy path is the EPROM's F2 hotkey. Rather than simulate a
# keypress, the latched byte is written directly: breakpoint at 001Fh, the
# instruction after 0019h LD A,(38A0h) / 001Ch LD (FFFFh),A, then
# set FFFF = 02 -- bit 1 set, bit 0 clear. F2 is documented as bit 1 in the
# Technische Beschreibung and confirmed on the physical machine.
#
# Scratch lives in work/stock-session/ inside the repository. It is NOT
# wiped between runs: a formatted, GENDIR'd disk is work you do not want to
# redo, so the scratch disk persists and is reused. Pass --fresh to start
# from a clean copy of the source image.
#
# The originals in DMK/ and HDV/ are copied, never attached. HDV/*.hdv is
# gitignored, so the populated image exists on disk and nowhere else.
#
# When the emulator exits, the scratch disk is left in place and its path
# printed. Copy it back into HDV/ under a dated name if the session produced
# something worth keeping.

set -e
cd "$(dirname "$0")"

export REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -n "$REPO" ] && [ -d "$REPO/DMK" ] && [ -d "$REPO/HDV" ] \
  || { echo "not in the CalvaDOS repository: REPO='$REPO'"; exit 1; }

FRESH=0
ARGS=()
for a in "$@"; do
  case "$a" in
    --fresh) FRESH=1 ;;
    *) ARGS+=("$a") ;;
  esac
done

EMU="${EMU:-$HOME/Documents/GitHub/sdltrs-MultiHDC}"
BIN="$EMU/build/sdl2trs"
ROM="${ROM:-$EMU/ROM/g3s_hd-omti_bootrom_2764.bin}"
DMK="${DMK:-$REPO/DMK/G3S-GDOS24.DMK}"
# calvados-drive5-populated-20260813.hdv is 615x4x17 -- stale geometry from
# before the 56ec00d Tandon 612x2x17/512-byte-sector rework; bootrd.asm's
# heds/secs and omti.asm's hdheds/hdsecs no longer match it. Kept below,
# commented out, for reference only -- do not attach it.
# IMAGE="${ARGS[0]:-$REPO/HDV/calvados-drive5-populated-20260813.hdv}"
IMAGE="${ARGS[0]:-$REPO/HDV/calvados-20260824.hdv}"

WORK="${WORK:-$REPO/work/stock-session}"
mkdir -p "$WORK"

for f in "$BIN" "$ROM" "$DMK" "$IMAGE"; do
  [ -f "$f" ] || { echo "missing: $f"; exit 1; }
done

# The floppy is always a fresh read-only copy -- nothing in a session should
# write to it, and if something does, the md5 check at the end says so.
DMK_BEFORE=$(md5 -q "$DMK")
# Remove the previous run's copy first: it was left 444, and cp cannot
# overwrite a read-only file. Unlinking it needs write permission on the
# directory, not on the file, so this works where the plain cp did not.
rm -f "$WORK/floppy.dmk"
cp "$DMK" "$WORK/floppy.dmk"
chmod 444 "$WORK/floppy.dmk"

# The hard disk persists between sessions unless --fresh is given.
if [ "$FRESH" = "1" ] || [ ! -f "$WORK/test.hdv" ]; then
  cp "$IMAGE" "$WORK/test.hdv"
  DISK_NOTE="fresh copy of $(basename "$IMAGE")"
else
  DISK_NOTE="carried over from the previous session (--fresh to reset)"
fi
chmod 644 "$WORK/test.hdv"

cat > "$WORK/sdltrs.t8c" <<EOF
model=1
romfile1=$ROM
EOF

echo "== configuration =="
echo "  repo    : $REPO"
echo "  scratch : $WORK"
echo "  binary  : $BIN"
echo "  sha256  : $(shasum -a 256 "$BIN" | cut -d' ' -f1)"
echo "  floppy  : $(basename "$DMK") (read-only copy)"
echo "  hard0   : $WORK/test.hdv"
echo "            $DISK_NOTE"
echo
echo "  drive 5 = volume 0, drive 6 = volume 1."
echo "  GENDIR 0 destroys the DOS. Never type it, with any argument but 5."
echo "  GENDIR 6 is known to crash: gtab entry 2 declares DDGA = 0."
echo

echo "== setting the forced-floppy latch, then handing over =="
BIN="$BIN" WORK="$WORK" python3 - <<'PY'
# Sets the latch through zbx, then relays the terminal so the session is
# interactive. No timeout anywhere: the run ends when the emulator does.
import os
import pty
import re
import select
import signal
import subprocess
import sys
import termios
import time
import tty

WORK = os.environ["WORK"]
BIN = os.environ["BIN"]

master_fd, slave_fd = pty.openpty()
proc = subprocess.Popen(
    [BIN, f"{WORK}/sdltrs.t8c",
     "-disk0", f"{WORK}/floppy.dmk", "-disk1", "", "-disk2", "", "-disk3", "",
     "-hard0", f"{WORK}/test.hdv", "-hard1", "", "-hard2", "", "-hard3", "",
     "-omtisecsize", "512", "-nofullscreen", "-zbx"],
    stdin=slave_fd, stdout=slave_fd, stderr=slave_fd, close_fds=True,
)
os.close(slave_fd)

log = open(f"{WORK}/session.log", "w")
buffer = b""


def read_until_prompt(timeout):
    """Only used for the few setup commands. The session itself is not
    driven this way."""
    global buffer
    prompt = b"(zbx) "
    deadline = time.time() + timeout
    while True:
        if prompt in buffer:
            before, _, after = buffer.partition(prompt)
            buffer = after
            return before.decode("latin-1", "replace")
        remaining = deadline - time.time()
        if remaining <= 0:
            raise TimeoutError()
        r, _, _ = select.select([master_fd], [], [], remaining)
        if not r:
            raise TimeoutError()
        chunk = os.read(master_fd, 4096)
        if not chunk:
            raise EOFError()
        text = chunk.decode("latin-1", "replace")
        log.write(text)
        log.flush()
        sys.stdout.write(text)
        sys.stdout.flush()
        buffer += chunk


def cmd(c, timeout=15):
    os.write(master_fd, (c + "\n").encode())
    return read_until_prompt(timeout)


forced = False
try:
    read_until_prompt(30)                            # initial zbx banner
    cmd("timeron")
    cmd("b 001f")
    out = cmd("g", 30)
    if re.search(r"Stopped at\s+001f\b", out, re.IGNORECASE):
        cmd("set FFFF = 02")
        cmd("delete *")
        forced = True
    print(f"\n  forced-floppy latch: {'set' if forced else 'NOT SET'}")
    print("  handing over -- the emulator window is yours."
          " Ctrl-C here quits.\n")
    os.write(master_fd, b"g\n")
except (TimeoutError, EOFError) as e:
    print(f"\n  setup did not complete ({type(e).__name__});"
          " handing over anyway.\n")

# Relay stdin <-> pty until the emulator exits. No deadline.
try:
    old = termios.tcgetattr(sys.stdin)
    tty.setraw(sys.stdin.fileno())
    raw = True
except Exception:
    raw = False

try:
    while proc.poll() is None:
        r, _, _ = select.select([master_fd, sys.stdin], [], [], 0.2)
        if master_fd in r:
            try:
                chunk = os.read(master_fd, 4096)
            except OSError:
                break
            if not chunk:
                break
            log.write(chunk.decode("latin-1", "replace"))
            log.flush()
            os.write(sys.stdout.fileno(), chunk)
        if sys.stdin in r:
            chunk = os.read(sys.stdin.fileno(), 4096)
            if chunk:
                os.write(master_fd, chunk)
except KeyboardInterrupt:
    pass
finally:
    if raw:
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old)
    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except Exception:
            proc.kill()
    log.close()
PY

echo
echo "== after the session =="
if [ "$(md5 -q "$DMK")" = "$DMK_BEFORE" ]; then
  echo "  source DMK unchanged ($DMK_BEFORE)"
else
  echo "  FAIL: source DMK changed!"
fi
echo "  source image untouched: $IMAGE"
echo
echo "  the disk you worked on:"
echo "    $WORK/test.hdv"
echo "    $(md5 -q "$WORK/test.hdv")  $(wc -c < "$WORK/test.hdv" | tr -d ' ') bytes"
echo
echo "  it persists into the next run. To keep it, copy it into HDV/"
echo "  under a dated name and add a line to HDV/MANIFEST-*.md."
echo "  Session log: $WORK/session.log"