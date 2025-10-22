#!/usr/bin/env python3

import os, pwd

def uid_to_user(uid):
    try:
        return pwd.getpwuid(uid).pw_name
    except KeyError:
        return str(uid)

print(f"{'USER':<8} {'PID':>6} {'COMMAND'}")
proc_dir = "/proc"
for entry in sorted(os.listdir(proc_dir), key=lambda x: (not x.isdigit(), int(x) if x.isdigit() else x)):
    if not entry.isdigit():
        continue
    pid = entry
    status_path = os.path.join(proc_dir, pid, "status")
    comm_path = os.path.join(proc_dir, pid, "comm")
    try:
        uid = None
        with open(status_path, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                if line.startswith("Uid:"):
                    parts = line.split()
                    if len(parts) >= 2:
                        uid = int(parts[1])
                    break
        user = uid_to_user(uid) if uid is not None else "?"
        try:
            with open(comm_path, "r", encoding="utf-8", errors="ignore") as f:
                comm = f.read().strip()
        except Exception:
            comm = "?"
        print(f"{user:<8} {int(pid):6d} {comm}")
    except FileNotFoundError:
        continue
    except PermissionError:
        continue
