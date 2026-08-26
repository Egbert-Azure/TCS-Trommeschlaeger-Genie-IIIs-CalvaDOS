#!/usr/bin/env python3
# /tools/zbx-dap/adapter.py
#
# A Debug Adapter Protocol (DAP) server that drives sdl2trs's built-in zbx
# console instead of implementing its own debugger. VS Code talks DAP to
# this process over stdin/stdout; this process talks zbx's plain-text
# console to sdl2trs over a pty, the same way run-stock-session.sh already
# does by hand.
#
# Scope (step 1 of the plan in the dev-environment notes): launch, single
# instruction stepping, continue, and a live register view. No breakpoints
# yet -- zbx only takes bare hex addresses, and mapping a source line to one
# needs either the annotated-disassembly address text or a pasmo listing
# correlation, neither of which is wired up here. setBreakpoints is answered
# but every breakpoint comes back unverified.
#
# zbx has no step-over: `n`/`s` both execute exactly one instruction, so a
# CALL always steps into the callee. DAP's "step over" therefore behaves
# identically to "step into" here.
#
# zbx also has no asynchronous break-in (no SIGINT handler, no keystroke
# read while the Z80 is running), so once `continue` is sent, the only way
# back to a stopped state is a breakpoint or a HALT configured to trap --
# neither exists yet in this build, so Continue is a one-way trip until you
# stop the session. That mirrors real zbx, not a bug here.
import json
import os
import pty
import re
import subprocess
import sys
import tempfile
import threading
import time

PROMPT = b"(zbx) "
LOG = os.environ.get("ZBX_DAP_LOG")


def log(msg):
    if LOG:
        with open(LOG, "a") as f:
            f.write(f"{time.time():.3f} {msg}\n")


# --- DAP wire protocol -----------------------------------------------------

class Dap:
    def __init__(self):
        self._seq = 0
        self._out_lock = threading.Lock()
        self._stdin = sys.stdin.buffer
        self._stdout = sys.stdout.buffer

    def read_message(self):
        headers = {}
        while True:
            line = self._stdin.readline()
            if not line:
                return None
            line = line.decode("utf-8").rstrip("\r\n")
            if line == "":
                break
            k, _, v = line.partition(":")
            headers[k.strip().lower()] = v.strip()
        length = int(headers.get("content-length", "0"))
        body = self._stdin.read(length)
        return json.loads(body.decode("utf-8"))

    def _send(self, obj):
        self._seq += 1
        obj["seq"] = self._seq
        data = json.dumps(obj).encode("utf-8")
        with self._out_lock:
            self._stdout.write(f"Content-Length: {len(data)}\r\n\r\n".encode("ascii"))
            self._stdout.write(data)
            self._stdout.flush()

    def send_response(self, request, success=True, body=None, message=None):
        obj = {
            "type": "response",
            "request_seq": request["seq"],
            "command": request["command"],
            "success": success,
        }
        if body is not None:
            obj["body"] = body
        if message is not None:
            obj["message"] = message
        self._send(obj)

    def send_event(self, event, body=None):
        obj = {"type": "event", "event": event}
        if body is not None:
            obj["body"] = body
        self._send(obj)


# --- zbx console session ----------------------------------------------------

class ZbxSession:
    def __init__(self):
        self.master_fd = None
        self.proc = None
        self._buf = b""
        self._eof = False
        self._cv = threading.Condition()

    def launch(self, args):
        sdl2trs = args["sdl2trs"]
        rom = args["rom"]
        floppy = args.get("floppy") or ""
        hard0 = args.get("hard0") or ""
        omtisecsize = args.get("omtisecsize") or 0

        fd, cfg_path = tempfile.mkstemp(prefix="zbx-dap-", suffix=".t8c")
        with os.fdopen(fd, "w") as f:
            f.write(f"model=1\nromfile1={rom}\n")

        cmd = [
            sdl2trs, cfg_path,
            "-disk0", floppy, "-disk1", "", "-disk2", "", "-disk3", "",
            "-hard0", hard0, "-hard1", "", "-hard2", "", "-hard3", "",
        ]
        if hard0 and omtisecsize:
            cmd += ["-omtisecsize", str(omtisecsize)]
        cmd += ["-nofullscreen", "-zbx"]

        log(f"spawning: {cmd}")
        master_fd, slave_fd = pty.openpty()
        self.proc = subprocess.Popen(
            cmd, stdin=slave_fd, stdout=slave_fd, stderr=slave_fd, close_fds=True,
        )
        os.close(slave_fd)
        self.master_fd = master_fd
        threading.Thread(target=self._reader, daemon=True).start()
        # Entering the debugger halts at 0000h before printing the first
        # prompt -- this is the natural "stopped at entry" state.
        return self.wait_for_prompt(timeout=15)

    def _reader(self):
        while True:
            try:
                chunk = os.read(self.master_fd, 4096)
            except OSError:
                chunk = b""
            with self._cv:
                if chunk:
                    self._buf += chunk
                else:
                    self._eof = True
                self._cv.notify_all()
            if not chunk:
                return

    def wait_for_prompt(self, timeout):
        deadline = None if timeout is None else time.time() + timeout
        with self._cv:
            while PROMPT not in self._buf:
                if self._eof:
                    raise EOFError("sdl2trs exited")
                remaining = None if deadline is None else deadline - time.time()
                if remaining is not None and remaining <= 0:
                    raise TimeoutError(f"no (zbx) prompt within timeout; buffer={self._buf!r}")
                self._cv.wait(timeout=remaining)
            idx = self._buf.index(PROMPT)
            text = self._buf[:idx]
            self._buf = self._buf[idx + len(PROMPT):]
            return text.decode("latin-1", "replace")

    def send_and_wait(self, command, timeout=8):
        os.write(self.master_fd, (command + "\n").encode())
        return self.wait_for_prompt(timeout=timeout)

    def send_nowait(self, command):
        os.write(self.master_fd, (command + "\n").encode())

    def terminate(self):
        if self.proc and self.proc.poll() is None:
            try:
                self.proc.terminate()
                self.proc.wait(timeout=3)
            except Exception as e:
                log(f"terminate: graceful shutdown failed ({e!r}), killing")
                try:
                    self.proc.kill()
                    self.proc.wait(timeout=3)
                except Exception as e2:
                    log(f"terminate: kill also failed: {e2!r}")


# --- zbx text parsing --------------------------------------------------------

_PAIR_RE = {
    "A": r"A F:\s*([0-9a-fA-F]{2})\s+([0-9a-fA-F]{2})",  # -> A, F
    "B": r"B C:\s*([0-9a-fA-F]{2})\s+([0-9a-fA-F]{2})",  # -> B, C
    "D": r"D E:\s*([0-9a-fA-F]{2})\s+([0-9a-fA-F]{2})",  # -> D, E
    "H": r"H L:\s*([0-9a-fA-F]{2})\s+([0-9a-fA-F]{2})",  # -> H, L
    "I": r"I R:\s*([0-9a-fA-F]{2})\s+([0-9a-fA-F]{2})",  # -> I, R
}
_PAIR_NAMES = {"A": ("A", "F"), "B": ("B", "C"), "D": ("D", "E"),
               "H": ("H", "L"), "I": ("I", "R")}
_WORD_RE = {name: rf"\b{name}:\s*([0-9a-fA-F]+)" for name in ("IX", "IY", "PC", "SP")}
_SHADOW_RE = {name: rf"{name}':\s*([0-9a-fA-F]+)" for name in ("AF", "BC", "DE", "HL")}


def parse_dump(text):
    regs = {}
    for key, pattern in _PAIR_RE.items():
        m = re.search(pattern, text)
        if m:
            n1, n2 = _PAIR_NAMES[key]
            regs[n1], regs[n2] = m.group(1), m.group(2)
    for name, pattern in _WORD_RE.items():
        m = re.search(pattern, text)
        if m:
            regs[name] = m.group(1)
    for name, pattern in _SHADOW_RE.items():
        m = re.search(pattern, text)
        if m:
            regs[name + "'"] = m.group(1)
    return regs


# --- the adapter proper ------------------------------------------------------

class Adapter:
    THREAD_ID = 1
    FRAME_ID = 1
    REGISTERS_REF = 1

    def __init__(self):
        self.dap = Dap()
        self.zbx = ZbxSession()
        self.running = False
        self.stop_on_entry = True

    def run(self):
        while True:
            req = self.dap.read_message()
            if req is None:
                return
            if req.get("type") != "request":
                continue
            handler = getattr(self, f"cmd_{req['command']}", None)
            log(f"-> {req['command']} {req.get('arguments')}")
            try:
                if handler:
                    handler(req)
                else:
                    self.dap.send_response(req, success=False, message="unsupported request")
            except Exception as e:
                log(f"!! {req['command']} raised {e!r}")
                self.dap.send_response(req, success=False, message=str(e))

    # -- lifecycle --

    def cmd_initialize(self, req):
        self.dap.send_response(req, body={
            "supportsConfigurationDoneRequest": True,
        })
        self.dap.send_event("initialized")

    def cmd_launch(self, req):
        args = req["arguments"]
        self.stop_on_entry = args.get("stopOnEntry", True)
        banner = self.zbx.launch(args)
        log(f"launch banner: {banner!r}")
        self.running = False
        self.dap.send_response(req)

    def cmd_configurationDone(self, req):
        self.dap.send_response(req)
        if self.stop_on_entry:
            self.dap.send_event("stopped", {
                "reason": "entry", "threadId": self.THREAD_ID, "allThreadsStopped": True,
            })

    def cmd_disconnect(self, req):
        # Acknowledge first: sdl2trs teardown can take a moment (SIGTERM,
        # then a wait, then SIGKILL if it didn't take), and there's no
        # reason to make VS Code wait on that before confirming disconnect.
        self.dap.send_response(req)
        self.zbx.terminate()
        sys.exit(0)

    def cmd_terminate(self, req):
        self.zbx.terminate()
        self.dap.send_response(req)

    # -- breakpoints: accepted, not yet implemented (see module docstring) --

    def cmd_setBreakpoints(self, req):
        src_bps = req["arguments"].get("breakpoints", [])
        body = {"breakpoints": [
            {"verified": False, "line": bp.get("line"),
             "message": "address resolution not implemented yet"}
            for bp in src_bps
        ]}
        self.dap.send_response(req, body=body)

    def cmd_setExceptionBreakpoints(self, req):
        self.dap.send_response(req, body={})

    # -- execution control --

    def _stop(self, reason):
        self.running = False
        self.dap.send_event("stopped", {
            "reason": reason, "threadId": self.THREAD_ID, "allThreadsStopped": True,
        })

    def cmd_continue(self, req):
        self.running = True
        self.zbx.send_nowait("g")
        self.dap.send_response(req, body={"allThreadsContinued": True})

        def watch():
            try:
                text = self.zbx.wait_for_prompt(timeout=None)
                reason = "breakpoint" if "Stopped at" in text else "pause"
                self._stop(reason)
            except EOFError:
                self.running = False
                self.dap.send_event("terminated")

        threading.Thread(target=watch, daemon=True).start()

    def cmd_pause(self, req):
        self.dap.send_response(
            req, success=False,
            message="zbx has no asynchronous break-in; Continue can't be interrupted",
        )

    def cmd_next(self, req):
        self._step(req, "n")

    def cmd_stepIn(self, req):
        self._step(req, "n")

    def _step(self, req, zbx_cmd):
        if self.running:
            self.dap.send_response(req, success=False, message="target is running")
            return
        self.zbx.send_and_wait(zbx_cmd)
        self.dap.send_response(req)
        self._stop("step")

    # -- state inspection --

    def cmd_threads(self, req):
        self.dap.send_response(req, body={"threads": [{"id": self.THREAD_ID, "name": "Z80"}]})

    def cmd_stackTrace(self, req):
        dump = self.zbx.send_and_wait("dump")
        regs = parse_dump(dump)
        pc = regs.get("PC", "0000")
        frame = {
            "id": self.FRAME_ID,
            "name": f"{pc.upper()}h",
            "line": 0,
            "column": 0,
            "instructionPointerReference": f"0x{pc}",
        }
        self.dap.send_response(req, body={"stackFrames": [frame], "totalFrames": 1})

    def cmd_scopes(self, req):
        self.dap.send_response(req, body={"scopes": [
            {"name": "Registers", "variablesReference": self.REGISTERS_REF, "expensive": False},
        ]})

    def cmd_variables(self, req):
        if req["arguments"]["variablesReference"] != self.REGISTERS_REF:
            self.dap.send_response(req, body={"variables": []})
            return
        dump = self.zbx.send_and_wait("dump")
        regs = parse_dump(dump)
        order = ["PC", "SP", "A", "F", "B", "C", "D", "E", "H", "L",
                 "IX", "IY", "I", "R", "AF'", "BC'", "DE'", "HL'"]
        variables = [{"name": n, "value": regs[n], "variablesReference": 0}
                     for n in order if n in regs]
        self.dap.send_response(req, body={"variables": variables})


def main():
    Adapter().run()


if __name__ == "__main__":
    main()
