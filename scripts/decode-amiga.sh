#!/bin/bash
set -euf -o pipefail

export LC_CTYPE=C
export LC_ALL=C
cat $1 | sed 's/MARK/ILBM/' | ilbmtoppm -adjustcolors | pnmtopng > $2
