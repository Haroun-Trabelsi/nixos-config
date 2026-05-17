#!/usr/bin/env python3
"""
Parse MemTest86 logs from ~/Downloads (or paths passed as args), extract failing
byte-addresses, coalesce them into contiguous 4 KiB-page ranges, and emit Linux
`memmap=SIZE$START` kernel parameters.

Equivalent to Windows' `bcdedit /set {badmemory} badmemorylist` flow, but for
Linux. On NixOS, drop the generated list into `boot.kernelParams`.

Usage:
    badmem-from-memtest86.py                    # scans ~/Downloads
    badmem-from-memtest86.py /path/to/log ...   # explicit files
    badmem-from-memtest86.py --nixos            # also print a NixOS module snippet
"""

import argparse
import glob
import os
import re
import sys

PAGE = 4096
# MemTest86 v4+ format: "[MEM ERROR ...] ... Address: HEXADDR ..."
ADDR_RE = re.compile(r"\[MEM ERROR[^\]]*\][^A]*Address:\s*([0-9A-Fa-f]+)")


def parse_logs(paths):
    pfns = set()
    for p in paths:
        try:
            with open(p, "r", errors="replace") as f:
                data = f.read()
        except OSError as e:
            print(f"warn: cannot read {p}: {e}", file=sys.stderr)
            continue
        for m in ADDR_RE.finditer(data):
            addr = int(m.group(1), 16)
            pfns.add(addr // PAGE)
    return sorted(pfns)


def coalesce(pfns):
    """Merge contiguous PFNs into (start_pfn, count) ranges."""
    ranges = []
    if not pfns:
        return ranges
    start = prev = pfns[0]
    for p in pfns[1:]:
        if p == prev + 1:
            prev = p
            continue
        ranges.append((start, prev - start + 1))
        start = prev = p
    ranges.append((start, prev - start + 1))
    return ranges


def fmt_memmap(start_pfn, count):
    size_bytes = count * PAGE
    start_bytes = start_pfn * PAGE
    return f"memmap={size_bytes:#x}${start_bytes:#x}"


def human_mb(n_bytes):
    return n_bytes / (1024 * 1024)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("logs", nargs="*", help="MemTest86 log files (default: ~/Downloads/MemTest86-*.log)")
    ap.add_argument("--nixos", action="store_true", help="emit a NixOS module snippet")
    args = ap.parse_args()

    paths = args.logs or sorted(glob.glob(os.path.expanduser("~/Downloads/MemTest86-*.log")))
    if not paths:
        print("No MemTest86 logs found.", file=sys.stderr)
        sys.exit(1)

    print(f"Scanning {len(paths)} log file(s):", file=sys.stderr)
    for p in paths:
        print(f"  {p}", file=sys.stderr)

    pfns = parse_logs(paths)
    print(f"\nUnique failing 4 KiB pages: {len(pfns)}", file=sys.stderr)
    if not pfns:
        print("No bad pages found.", file=sys.stderr)
        sys.exit(0)

    min_addr = pfns[0] * PAGE
    max_addr = (pfns[-1] + 1) * PAGE
    print(f"Physical span: {min_addr / 2**30:.3f} GiB - {max_addr / 2**30:.3f} GiB", file=sys.stderr)
    print(f"Total excluded: {len(pfns) * PAGE / 2**20:.2f} MiB", file=sys.stderr)

    ranges = coalesce(pfns)
    print(f"Contiguous ranges after coalescing: {len(ranges)}", file=sys.stderr)

    params = [fmt_memmap(s, c) for s, c in ranges]
    cmdline_bytes = sum(len(p) + 1 for p in params)
    print(f"Kernel cmdline cost: {cmdline_bytes} bytes ({len(params)} memmap= params)", file=sys.stderr)
    if cmdline_bytes > 2048:
        print(
            "WARNING: exceeds typical 2 KiB cmdline budget. Consider using\n"
            f"  memmap={human_mb(max_addr - min_addr):.0f}M${min_addr:#x}\n"
            "to reserve the whole span instead.",
            file=sys.stderr,
        )

    print("\n# Raw memmap= params (for any bootloader):", file=sys.stderr)
    for p in params:
        print(p)

    if args.nixos:
        print("\n# --- NixOS snippet (paste into boot.kernelParams) ---", file=sys.stderr)
        print("boot.kernelParams = [")
        for p in params:
            # In Nix strings, escape the literal $ to avoid antiquotation
            print(f'  "{p.replace("$", "\\$")}"')
        print("];")


if __name__ == "__main__":
    main()
