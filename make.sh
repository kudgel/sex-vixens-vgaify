#!/bin/bash
set -eu -o pipefail

# Ensure the working directory is set properly
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

# Check MD5 of inputs (this doesn't work inline for some reason)
bash -c 'cd inputs; diff MD5SUM <(find . -type f -print0 | xargs -0 openssl md5 | grep -v "MD5SUM" | sort) || (echo Mismatched inputs && exit 1)'

rm -rf out/ || true
mkdir out
mkdir out/disk

mkdir out/asm
nasm -Ox -f bin asm/patch1.asm -o out/asm/patch1.com
nasm -Ox -f bin asm/patch3.asm -o out/asm/patch3.com
nasm -Ox -f bin asm/vgadetect.asm -o out/asm/vgadetect.com

scripts/make-images.sh
scripts/patch.py
cp inputs/sexvixen/*.{PIQ,EXE} out/disk/
cp out/asm/vgadetect.com out/disk/VGADET.COM
cp scripts/SEXVIXEN.BAT out/disk/

# Check MD5 of outputs (this doesn't work inline for some reason)
bash -c 'diff buildhash/0.9.MD5SUM <(find out/disk -type f | xargs openssl md5 | sort) || (echo Mismatched output && exit 1)'
