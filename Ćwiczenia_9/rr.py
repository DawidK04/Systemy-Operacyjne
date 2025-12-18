#!/usr/bin/env python3
import sys
import csv
from collections import deque

class Process:
    def __init__(self, name, length, start):
        self.name = name
        self.remaining = length
        self.start = start

    def __repr__(self):
        return f"{self.name}(remaining={self.remaining}, start={self.start})"

class RoundRobinScheduler:
    def __init__(self, processes, quantum):
        self.incoming = deque(processes)
        self.ready = deque()
        self.quantum = quantum
        self.time = 0

    def load_new_processes(self):
        while self.incoming and self.incoming[0].start <= self.time:
            p = self.incoming.popleft()
            print(
                f"T={self.time}: New process {p.name} is waiting for execution "
                f"(length={p.remaining})"
            )
            self.ready.append(p)

    def run(self):
        while self.incoming or self.ready:
            self.load_new_processes()

            if not self.ready:
                print(f"T={self.time}: No processes currently available")
                if self.incoming:
                    self.time = self.incoming[0].start
                continue

            p = self.ready.popleft()
            run_time = min(self.quantum, p.remaining)

            print(
                f"T={self.time}: {p.name} will be running for {run_time} time units. "
                f"Time left: {p.remaining - run_time}"
            )

            self.time += run_time
            p.remaining -= run_time

            self.load_new_processes()

            if p.remaining > 0:
                self.ready.append(p)
            else:
                print(f"T={self.time}: Process {p.name} has been finished")

        print(f"T={self.time}: No more processes in queues")

def read_processes_from_csv(path):
    processes = []
    with open(path, newline="") as f:
        reader = csv.reader(f)
        for row in reader:
            name, length, start = row
            processes.append(Process(name, int(length), int(start)))
    return processes

def main():
    if len(sys.argv) != 3:
        print("Usage: ./rr.py file.csv quantum")
        sys.exit(1)

    csv_path = sys.argv[1]
    quantum = int(sys.argv[2])

    processes = read_processes_from_csv(csv_path)
    scheduler = RoundRobinScheduler(processes, quantum)
    scheduler.run()

if __name__ == "__main__":
    main()
