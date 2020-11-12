#!/bin/bash
set -eu -o pipefail

export LC_CTYPE=C
export LC_ALL=C

export BASEDIR=out/amiga

rm -rf $BASEDIR/{in,out,raw,colormap,pcx,vgamap,tmp} || true
mkdir -p $BASEDIR/{in,out,raw,colormap,pcx,vgamap,tmp}

# Unpack Amiga images

echo '==================================================='
echo ' Unpack Amiga images'
echo '==================================================='
xdftool inputs/Planet\ of\ Lust\ \(1989\)\(Free\ Spirit\ Software\)\(Disk\ 1\ of\ 2\).adf unpack $BASEDIR/tmp
xdftool inputs/Planet\ of\ Lust\ \(1989\)\(Free\ Spirit\ Software\)\(Disk\ 2\ of\ 2\).adf unpack $BASEDIR/tmp

mv $BASEDIR/tmp/*/Pics/* $BASEDIR/in
echo `ls -l $BASEDIR/in | wc -l` images found

# From the raw files

echo '==================================================='
echo ' Decode raw files'
echo '==================================================='
ls -1 $BASEDIR/in/ |
	xargs -n1 -I{} echo 'scripts/decode-amiga.sh $BASEDIR/in/{} $BASEDIR/raw/`basename -s .pic {} | tr "[:lower:]." "[:upper:]_"`.png' |
	sh


# Trim

echo '==================================================='
echo ' Trimming images'
echo '==================================================='
ls -1 $BASEDIR/raw/ |
	xargs -n1 -I{} echo "pngtopnm < $BASEDIR/raw/{} | pamcut -top 0 -left 0 -right 319 -bottom 154 | pnmtopng > $BASEDIR/out/{}" |
	sh
# But not the title/intro files...
cp $BASEDIR/raw/{I*,T*} $BASEDIR/out/
# And we don't need this
rm $BASEDIR/out/scorebar3.png
echo `ls -l $BASEDIR/out | wc -l` files


# Build a colormap for each file

echo '==================================================='
echo ' Get colormaps'
echo '==================================================='
ls -1 $BASEDIR/out/ |
	xargs -n1 -I{} echo "pngtopnm $BASEDIR/out/{} | pnmcolormap all -sort > $BASEDIR/colormap/{}.ppm 2> >(grep found 1>&2)" |
	bash


# Build the global colormap

echo '==================================================='
echo ' Build the global colormap'
echo '==================================================='
# Generate the base palette
(
	echo 'P6 1 16 255'
	printf '\x00\x00\x00\x00\x00\xaa\x00\xaa\x00\x00\xaa\xaa\xaa\x00\x00\xaa\x00\xaa\xaaU\x00\xaa\xaa\xaaUUUUU\xffU\xffUU\xff\xff\xffUU\xf6n\xc3\xff\xffD\xff\xff\xff'
) | pnmtoplainpnm > $BASEDIR/colormap/ega.ppm
# pnmremap -mapfile=$BASEDIR/finalcolors.ppm < $BASEDIR/ega.ppm > $BASEDIR/egamapped.ppm
pnmcat -tb $BASEDIR/colormap/* | pnmcolormap all -sort | pnmtoplainpnm > $BASEDIR/finalcolors.ppm
# Sort the EGA colors into the right spot
cat $BASEDIR/finalcolors.ppm | tail -n +4 | xargs -n 3 | sort > /tmp/colors1.txt
cat $BASEDIR/colormap/ega.ppm | tail -n +4 | xargs -n 3 | sort > /tmp/colors2.txt
(
	echo P3
	echo 1 `wc -l < /tmp/colors1.txt` 255
	cat $BASEDIR/colormap/ega.ppm | tail -n +4
	comm -2 -3 /tmp/colors1.txt /tmp/colors2.txt
) | pnmtopnm > $BASEDIR/finalcolors.ppm

# Generate PCX files
echo '==================================================='
echo ' Convert to a trimmed PCX using the global colormap'
echo '==================================================='
# Remap to our files and move it to a PCX
ls -1 $BASEDIR/out/ | 
	xargs -n1 -I{} echo 'cat $BASEDIR/out/{} | 
	pngtopnm | 
	ppmtopcx -8bit -palette=$BASEDIR/finalcolors.ppm > $BASEDIR/pcx/`basename -s .png {}`.pcx' | sh
ls -1 $BASEDIR/pcx/ | 
	xargs -n1 -I{} echo 'cat $BASEDIR/pcx/{} | 
	scripts/trim_pcx.py > $BASEDIR/vgamap/`basename -s .pcx {}`.VIQ' | sh
echo `ls -l $BASEDIR/vgamap | wc -l` images processed

echo
echo Moving output files to out/disk...
cat $BASEDIR/finalcolors.ppm | scripts/vgapal.py > out/disk/VGA.PAL
cp $BASEDIR/vgamap/*.VIQ out/disk/

echo Done.
