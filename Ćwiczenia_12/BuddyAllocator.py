import math
from collections import defaultdict
from typing import Optional, Tuple, List

class BuddyAllocator:
    def __init__(self, memory_size: int, limit_divisions: int):
        if memory_size <= 0 or (memory_size & (memory_size - 1)) != 0:
            raise ValueError("memory_size musi być potęgą 2 i > 0")
        if limit_divisions < 0:
            raise ValueError("limit_divisions musi być >= 0")
        self.memory_size = memory_size
        self.limit_divisions = limit_divisions
        self.min_block_size = memory_size >> limit_divisions
        if self.min_block_size < 1:
            raise ValueError("limit_divisions za duże dla podanego memory_size")
        self.sizes = []
        s = memory_size
        while s >= self.min_block_size:
            self.sizes.append(s)
            s >>= 1
        self.free_lists: dict[int, List[int]] = {size: [] for size in self.sizes}
        self.free_lists[memory_size].append(0)
        self.allocated: dict[int, int] = {}

    def _next_power_of_two(self, n: int) -> int:
        if n <= 0:
            return 1
        return 1 << ((n - 1).bit_length())

    def alloc(self, size: int) -> Optional[Tuple[int, int]]:
        if size <= 0:
            raise ValueError("size must be > 0")

        target = self._next_power_of_two(size)
        if target < self.min_block_size:
            target = self.min_block_size
        if target > self.memory_size:
            return None

        current = target
        found_size = None
        while current <= self.memory_size:
            if current in self.free_lists and self.free_lists[current]:
                found_size = current
                break
            current <<= 1
        if found_size is None:
            return None

        addr = self.free_lists[found_size].pop(0)
        size_now = found_size
        while size_now > target:
            size_now //= 2
            right_buddy = addr + size_now
            self.free_lists[size_now].append(right_buddy)
        self.allocated[addr] = target
        return (addr, target)

    def free(self, address: int) -> None:
        if address not in self.allocated:
            raise ValueError("Invalid or double free: address not allocated")
        size = self.allocated.pop(address)

        addr = address
        block_size = size

        while True:
            buddy = addr ^ block_size
            free_list = self.free_lists.get(block_size, [])
            if buddy in free_list:
                free_list.remove(buddy)
                addr = min(addr, buddy)
                block_size *= 2
                if block_size > self.memory_size:
                    self.free_lists[self.memory_size].append(0)
                    break
                continue
            else:
                self.free_lists[block_size].append(addr)
                break

    def dump_free_lists(self):
        return {size: sorted(self.free_lists[size]) for size in sorted(self.free_lists.keys(), reverse=True)}

    def dump_allocated(self):
        return dict(self.allocated)

    def __repr__(self):
        return f"<BuddyAllocator total={self.memory_size} min_block={self.min_block_size} allocated={len(self.allocated)}>"

if __name__ == "__main__":
    b = BuddyAllocator(2048, 6)
    print("Początkowy stan free lists:", b.dump_free_lists())

    a1 = b.alloc(100)
    print("alloc(100) ->", a1)
    a2 = b.alloc(1000)
    print("alloc(1000) ->", a2)
    a3 = b.alloc(20)
    print("alloc(20) ->", a3)

    print("Free lists po alokacjach:", b.dump_free_lists())
    print("Allocated map:", b.dump_allocated())

    b.free(a1[0])
    print("Po free(a1):", b.dump_free_lists())
    b.free(a3[0])
    print("Po free(a3):", b.dump_free_lists())
    b.free(a2[0])
    print("Po free(a2) (powinno być scalenie do jednego dużego):", b.dump_free_lists())
