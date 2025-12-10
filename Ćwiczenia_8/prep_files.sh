#!/bin/bash

RANDOM_DIR="/tmp/data/random"
EMPTY_DIR="/tmp/data/empty"
VARIOUS_DIR="/tmp/data/various"
SILESIA_REPO="https://github.com/MiloszKrajewski/SilesiaCorpus.git"

FILE_SIZE_MB=5
FILE_COUNT=5

mkdir -p /tmp/data

mkdir -p "$RANDOM_DIR"
for i in $(seq 1 $FILE_COUNT); do
    dd if=/dev/urandom of="$RANDOM_DIR/file$i.dat" bs=1M count=$FILE_SIZE_MB iflag=fullblock status=none
done

mkdir -p "$EMPTY_DIR"
for i in $(seq 1 $FILE_COUNT); do
    dd if=/dev/zero of="$EMPTY_DIR/file$i.dat" bs=1M count=$FILE_SIZE_MB status=none
done


if [ -d "$VARIOUS_DIR" ]; then
    rm -rf "$VARIOUS_DIR"
fi

git clone --depth 1 "$SILESIA_REPO" "$VARIOUS_DIR"

if [ $? -ne 0 ]; then
    exit 1
fi

rm -rf "$VARIOUS_DIR/.git"
rm -f "$VARIOUS_DIR/README.md"