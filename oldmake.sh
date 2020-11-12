#!/bin/bash
set -eu -o pipefail

export LC_CTYPE=C
export LC_ALL=C

rm -rf amiga/{out,raw,colormap,vgamap} || true
mkdir amiga/{out,raw,colormap,vgamap}

# From the raw files

echo '==================================================='
echo ' Decode raw files'
echo '==================================================='
ls -l1 amiga/in/ |
	xargs -n1 -I{} echo 'amiga/decode-amiga.sh amiga/in/{} amiga/raw/`basename -s .pic {} | tr "[:lower:]." "[:upper:]_"`.png' |
	sh


# Trim

echo '==================================================='
echo ' Trimming images'
echo '==================================================='
ls -l1 amiga/raw/ |
	xargs -n1 -I{} echo "pngtopnm < amiga/raw/{} | pamcut -top 0 -left 0 -right 319 -bottom 154 | pnmtopng > amiga/out/{}" |
	sh
# But not the title/intro files...
cp amiga/raw/T* amiga/out/
# And we don't need this
rm amiga/out/scorebar3.png
echo `ls -l amiga/out | wc -l` files


# Build a colormap for each file

echo '==================================================='
echo ' Get colormaps'
echo '==================================================='
ls -l1 amiga/out/ |
	xargs -n1 -I{} echo "pngtopnm amiga/out/{} | pnmcolormap all -sort > amiga/colormap/{}.ppm 2> >(grep found 1>&2)" |
	bash
rm amiga/colormap/TITLE*

# Build the global colormap

echo '==================================================='
echo ' Build the global colormap'
echo '==================================================='
# Generate the base palette
# (
# 	echo 'P6 1 16 255'
# 	printf '\x00\x00\x00\x00\x00\xaa\x00\xaa\x00\x00\xaa\xaa\xaa\x00\x00\xaa\x00\xaa\xaaU\x00\xaa\xaa\xaaUUUUU\xffU\xffUU\xff\xff\xffUU\xf6n\xc3\xff\xffD\xff\xff\xff'
# ) | pnmtoplainpnm > amiga/colormap/ega.ppm
# pnmremap -mapfile=amiga/finalcolors.ppm < amiga/ega.ppm > amiga/egamapped.ppm
pnmcat -tb amiga/colormap/* | pnmcolormap 256 -sort | pnmtoplainpnm > amiga/finalcolors.ppm
# Sort the EGA colors into the right spot
# cat amiga/finalcolors.ppm | tail -n +4 | xargs -n 3 | sort > /tmp/colors1.txt
# cat amiga/colormap/ega.ppm | tail -n +4 | xargs -n 3 | sort > /tmp/colors2.txt
# (
# 	echo P3
# 	echo 1 `wc -l < /tmp/colors1.txt` 255
# 	cat amiga/colormap/ega.ppm | tail -n +4
# 	comm -2 -3 /tmp/colors1.txt /tmp/colors2.txt
# ) | pnmtopnm > amiga/finalcolors.ppm

# Generate PCX files
echo '==================================================='
echo ' Convert to a trimmed PCX using the global colormap'
echo '==================================================='
# Remap to our files and move it to a PCX
ls -l1 amiga/out/ | 
	xargs -n1 -I{} echo 'cat amiga/out/{} | 
	pngtopnm |
	pnmremap -mapfile=amiga/finalcolors.ppm |
	ppmtopcx -8bit -palette=amiga/finalcolors.ppm | 
	dd bs=1 skip=0x80 2>/dev/null | amiga/trim_pcx_palette.py > amiga/vgamap/`basename -s .png {}`.VIQ' | sh

cat amiga/finalcolors.ppm | amiga/vgapal.py > sexvixev/VGA.PAL
