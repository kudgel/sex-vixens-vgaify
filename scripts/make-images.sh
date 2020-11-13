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
xdftool 'inputs/Sex Vixens from Space (1988)(Free Spirit Software)(Disk 1 of 2).adf' unpack $BASEDIR/tmp
xdftool 'inputs/Sex Vixens from Space (1988)(Free Spirit Software)(Disk 2 of 2).adf' unpack $BASEDIR/tmp
mv $BASEDIR/tmp/{DISK1/bigt,DISK1/hotel,DISK1/lobby,DISK1/p1,DISK1/p10,DISK1/p11,DISK1/p12,DISK1/p13.5,DISK1/p14,DISK1/p15,DISK1/p16,DISK1/p17,DISK1/p18,DISK1/p19,DISK1/p2,DISK1/p20,DISK1/p21,DISK1/p3,DISK1/p33,DISK1/p4,DISK1/p5,DISK1/p7,DISK1/p7.5,DISK1/p8,DISK1/p9,DISK1/scorebar3,DISK1/title,DISK1/title2} $BASEDIR/in
mv $BASEDIR/tmp/{DISK2/end,DISK2/gpanel,DISK2/limp,DISK2/p1.5,DISK2/p2,DISK2/p23,DISK2/p24,DISK2/p25,DISK2/p26,DISK2/p27,DISK2/p28,DISK2/p29,DISK2/p30,DISK2/p31,DISK2/p32} $BASEDIR/in
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
cp $BASEDIR/raw/T* $BASEDIR/out/
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


# Build the EGA colormap

echo '==================================================='
echo ' Build the EGA colormap'
echo '==================================================='
# Generate the base palette
(
	echo 'P6 16 1 255'
	printf '\x00\x00\x00\x00\x00\xaa\x00\xaa\x00\x00\xaa\xaa\xaa\x00\x00\xaa\x00\xaa\xaaU\x00\xaa\xaa\xaaUUUUU\xffU\xffUU\xff\xff\xffUU\xf6n\xc3\xff\xffD\xff\xff\xff'
) | pnmtoplainpnm > $BASEDIR/ega.ppm
echo 'Done (16 colors)'


# Generate PCX files
echo '==================================================='
echo ' Convert to a trimmed PCX using the global colormap'
echo '==================================================='
# Remap to our files and move it to a PCX
ls -1 $BASEDIR/out/ | 
	xargs -n1 -I{} echo 'cat $BASEDIR/out/{} | 
	pngtopnm | 
	ppmtopcx -8bit -palette=<(pnmcat -lr $BASEDIR/ega.ppm $BASEDIR/colormap/{}.ppm) > $BASEDIR/pcx/`basename -s .png {}`.pcx' | bash
ls -1 $BASEDIR/pcx/ | 
	xargs -n1 -I{} echo 'cat $BASEDIR/pcx/{} | 
	scripts/trim_pcx.py > $BASEDIR/vgamap/`basename -s .pcx {}`.VIQ' | sh
echo `ls -l $BASEDIR/vgamap | wc -l` images processed

echo
echo Moving output files to out/disk...
cp $BASEDIR/vgamap/*.VIQ out/disk/

echo Done.
