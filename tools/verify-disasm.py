#!/usr/bin/env python3
# /tools/verify-disasm.py
#
# Check every byte column in src/GDOS-2.4-SYS-files/*-sys-disassembly.asm
# against the real file in DMK/G3S-GDOS24.DMK, and report each byte where the
# listing and the shipped file disagree.
#
# Every reported difference should correspond to a patch run-hdboottest.sh
# actually applies. Anything else is a stale listing -- the disassembly was
# regenerated from a build whose patch set no longer exists.
#
# Found exactly that on 2026-08-21: sys0's 4C1Dh was listed as three NOPs from
# an earlier six-patch build, while stock (and the current five-patch build)
# both have "cc 00 00". Analysis was being done against a byte the machine
# never actually executes.
#
# Usage: python3 tools/verify-disasm.py     (run from the repo root)
#
#
# The MEMDISK listing gets the same re-assembly check, by address rather than
# by offset: its records are not contiguous (3000h-33FDh, then 5200h-5242h),
# so a flat low-to-high comparison would run through a 7 KB gap that is not
# in the file.
# ----------------------------------------------------------------------------
# Here add more sys files if needed, or other non-SYS modules that are not contiguous. 
# The check_by_address function is more expensive than the simple offset-based check, 
# so it is only used for those modules that need it.
# ----------------------------------------------------------------------------

import re, subprocess, sys, os
DMK="DMK/G3S-GDOS24.DMK"
pairs=[("sys0","SYS0/SYS"),("sys1","SYS1/SYS"),("sys2","SYS2/SYS"),("sys6","SYS6/SYS"),
       ("sys7","SYS7/SYS"),("sys17","SYS17/SYS"),("sys22","SYS22/SYS"),
       ("sys26","SYS26/SYS"),("sys29","SYS29/SYS"),("sys8","SYS8/SYS"),
       ("sys9","SYS9/SYS")]


def records(path):
    """A /SYS or /CMD load module -> [(file offset, lo, hi)]."""
    out=subprocess.run(["python3","tools/trsload.py",path,"--map"],
                       capture_output=True,text=True).stdout
    return [(int(m.group(1),16),int(m.group(3),16),int(m.group(4),16)) for m in
            (re.match(r'\s+0x([0-9a-f]+)\s+LOAD\s+(\d+)B\s+'
                      r'([0-9A-F]{4})\.\.([0-9A-F]{4})',l)
             for l in out.splitlines()) if m]


def check_by_address(tag, listing, module):
    """Assemble the listing and compare it with the module address by address,
    so records that are not contiguous still line up."""
    recs=records(module); raw=open(module,"rb").read()
    real={}
    for off,lo,hi in recs:
        for i in range(hi-lo+1): real[lo+i]=raw[off+4+i]
    r=subprocess.run(["pasmo",listing,"/tmp/v.md.bin"],capture_output=True,text=True)
    if r.returncode:
        err=[l for l in (r.stdout+r.stderr).splitlines() if "ERROR" in l.upper()]
        print(f"{tag:6} does not assemble: {err[0].strip() if err else 'pasmo failed'}")
        return
    blob=open("/tmp/v.md.bin","rb").read(); base=min(real); top=max(real)
    got={base+i:b for i,b in enumerate(blob)}
    # pasmo emits one flat image, so the holes between records come out as
    # padding it invented -- those are not the listing's doing and are
    # ignored. Anything the listing puts beyond the module's last byte is.
    missing=[a for a in real if a not in got]
    extra=[a for a in got if a not in real and (a>top or got[a])]
    diff=[a for a in real if a in got and real[a]!=got[a]]
    if not (missing or extra or diff):
        print(f"{tag:6} {len(real):6} bytes re-assembled, round-trips exactly")
        return
    print(f"{tag:6} {len(real):6} bytes in the module, {len(diff)} differ, "
          f"{len(missing)} not produced, {len(extra)} past its end"
          f"   <-- does NOT match the module")
    for a in sorted(diff)[:20]:
        print(f"        {a:04X}h listing={got[a]:02X} stock={real[a]:02X}")
# SYS8-magnus-1989-listing.asm is deliberately not in that list: it is
# A. Magnus's 1989 listing of a different build of the module, which this
# disk's SYS8/SYS does not match (see that file's own header). sys8-sys-
# disassembly.asm is the one made from this disk, and it is checked.
for tag,name in pairs:
    for cand in (f"src/GDOS-2.4-SYS-files/{tag}-sys-disassembly.asm",):
        if not os.path.exists(cand): continue
        r=subprocess.run(["python3","tools/dmk.py",DMK,"--extract",name,"-o","/tmp/v.orig"],
                         capture_output=True,text=True)
        if r.returncode!=0: print(f"{tag}: cannot extract {name}"); continue
        out=subprocess.run(["python3","tools/trsload.py","/tmp/v.orig","--map"],
                           capture_output=True,text=True).stdout
        recs=[(int(m.group(1),16),int(m.group(3),16),int(m.group(4),16)) for m in
              (re.match(r'\s+0x([0-9a-f]+)\s+LOAD\s+(\d+)B\s+([0-9A-F]{4})\.\.([0-9A-F]{4})',l)
               for l in out.splitlines()) if m]
        raw=open("/tmp/v.orig","rb").read()
        def stock(a):
            o=None
            for rr,lo,hi in recs:
                if lo<=a<=hi: o=rr+4+(a-lo)
            return None if o is None else raw[o]
        mism=[];checked=0
        for line in open(cand):
            m=re.match(r'^([0-9A-F]{4})  ((?:[0-9a-f]{2} )+)',line)      # sys0 style
            if not m:
                m2=re.search(r';([0-9a-f]{4})\t((?:[0-9a-f]{2} )*[0-9a-f]{2})',line)  # z80dasm style
                if not m2: continue
                addr=int(m2.group(1),16); bs=[int(x,16) for x in m2.group(2).split()]
            else:
                addr=int(m.group(1),16); bs=[int(x,16) for x in m.group(2).split()]
            for i,b in enumerate(bs):
                s=stock(addr+i)
                if s is None: continue
                checked+=1
                if s!=b: mism.append((addr+i,b,s))
        if checked:
            flag="" if not mism else "   <-- differs from stock"
            print(f"{tag:6} {checked:6} bytes checked, {len(mism):3} differ{flag}")
            continue

        # No byte column: try the stronger check instead -- assemble it and
        # compare with the module.
        lo=min(l for _,l,_ in recs); hi=max(h for _,_,h in recs)
        subprocess.run(["python3","tools/trsload.py","/tmp/v.orig","--extract",
                        f"{lo:04X}-{hi:04X}","-o","/tmp/v.flat"],capture_output=True)
        r=subprocess.run(["pasmo",cand,"/tmp/v.asm.bin"],capture_output=True,text=True)
        if r.returncode!=0:
            err=[l for l in (r.stdout+r.stderr).splitlines() if "ERROR" in l.upper()]
            print(f"{tag:6} does not assemble: {err[0].strip() if err else 'pasmo failed'}")
            continue
        a=open("/tmp/v.flat","rb").read(); b=open("/tmp/v.asm.bin","rb").read()
        if a==b:
            print(f"{tag:6} {len(a):6} bytes re-assembled, round-trips exactly")
        else:
            d=[i for i in range(min(len(a),len(b))) if a[i]!=b[i]]
            print(f"{tag:6} {len(a):6} bytes in the module, {len(b)} assembled, "
                  f"{len(d)} differ   <-- does NOT match the module")
        for a,x,y in mism[:20]: print(f"        {a:04X}h listing={x:02X} stock={y:02X}")

# OVL4/SYS -- a 58-record overlay, none of it contiguous with the rest.
_lst="src/GDOS-2.4-SYS-files/ovl4-sys-disassembly.asm"
if os.path.exists(_lst):
    r=subprocess.run(["python3","tools/dmk.py",DMK,"--extract","OVL4/SYS",
                      "-o","/tmp/v.ovl4"],capture_output=True,text=True)
    if r.returncode: print("ovl4: cannot extract OVL4/SYS")
    else: check_by_address("ovl4",_lst,"/tmp/v.ovl4")

# MEMDISK/CMD -- not a /SYS module, and its records are not contiguous.
_lst="src/GDOS-2.4-SYS-files/memdisk-cmd-disassembly.asm"
if os.path.exists(_lst):
    r=subprocess.run(["python3","tools/dmk.py",DMK,"--extract","MEMDISK/CMD",
                      "-o","/tmp/v.memdisk"],capture_output=True,text=True)
    if r.returncode: print("memdisk: cannot extract MEMDISK/CMD")
    else: check_by_address("memdisk",_lst,"/tmp/v.memdisk")
