#!/usr/bin/env python3

import argparse
import time
import os
import signal
import sys

def main():
    parser = argparse.ArgumentParser(description="Appends a line number to the file every second.")
    parser.add_argument('file', help='Name of the file to create/append.')
    args = parser.parse_args()

    filename = os.path.abspath(args.file)

    open(filename, 'w').close()

    f = open(filename, 'a', buffering=1, encoding='utf-8')
    fd = f.fileno()
    pid = os.getpid()

    print(f"PID: {pid}")
    print(f"Created file: {filename}")
    print(f"File descriptor (fd): {fd}")
    print(f"Path to the descriptor in /proc: /proc/{pid}/fd/{fd}")
    sys.stdout.flush()

    def _cleanup(signum, frame):
        try:
            f.close()
        except Exception:
            pass
        sys.exit(0)

    signal.signal(signal.SIGINT, _cleanup)
    signal.signal(signal.SIGTERM, _cleanup)

    i = 0
    try:
        while True:
            line = f"{i}\n"
            f.write(line)
            try:
                f.flush()
                os.fsync(fd)
            except Exception:
                pass
            i += 1
            time.sleep(1)
    finally:
        try:
            f.close()
        except Exception:
            pass

if __name__ == '__main__':
    main()
