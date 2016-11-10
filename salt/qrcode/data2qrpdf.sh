#!/bin/bash

usage() {
    cat <<EOF
Usage: $0 datafile

takes (compressed) binary data,
encodes it in base32 and generates one alphanumeric qrcode,
and put this qrcode inside a pdf,
or if to large for one qrcode generates max 100 x Version 29 alphanumeric qrcodes
and arranges them in a 2x2 matrix per page pdf
writes it to \${datafile}.pdf

Limits:
 * Single QRCode:
   * Medium Error Correction: Max Version 40:
     * 3391 alphanumeric (3376) => base32 <= 2110 Bytes (8 Bit)

 * manually linked QRCode, Version 29, 4 Codes per A4 Page (25 A4 Pages Maximum)
   * Medium Error Correction: 100 x Version 29:
     * 1839 alphanumeric (base32 decode of (1839 -6 (padding) -3 (split header) -4 (safety)= 1826):
       * 1141 * 100 ~<= 114.100 (8 Bit)

QR-Code Standard:
 * Version 40: alphanumeric Limits: L 4296, M 3391, Q 2420, H 1852
 * Version 29: alphanumeric Limits: L 2369, M 1839, Q 1322, H 1016

Tests:
 * $0 --unittest

EOF
    exit 1
}


unittest() {
    local a x
    for a in 2110 4200 19900 50000 114100; do
        x="test${a}"
        echo "a: $a x: $x"
        if test -f $x; then rm $x; fi
        if test -f ${x}.pdf; then rm ${x}.pdf; fi
        if test -f ${x}.new; then rm ${x}.new; fi
        touch $x
        shred -x -s $a $x
        data2pdf $x
        zbarimg --raw -q "-S*.enable=0" "-Sqrcode.enable=1" ${x}.pdf |
            sort -n | cut -f 2 -d " " | tr -d "\n" | python -c "import sys, base64; sys.stdout.write(base64.b32decode(sys.stdin.read()))" > ${x}.new
        diff $x ${x}.new
        if test $? -eq 0; then
            rm $x ${x}.new $x.pdf
        else
            echo "Error: $x and $x.new differ, leaving $x $x.new and $x.pdf for analysis"
        fi
    done
}


data2pdf() {
    local a
    local fname=`readlink -f $1`
    local fbase=`basename $fname`
    local fsize=`stat -c "%s" $fname`

    if test ! -f $fname; then
        echo "ERROR: could not find datafile $fname; call $0 for usage information"
        exit 2
    fi

    if test $fsize -gt 114100; then
        echo "ERROR: source file bigger than max capacity of 1141*100 bytes ($fsize); call $0 for usage information"
        exit 3
    fi

    local tempdir=`mktemp -d`
    if test ! -d $tempdir; then echo "ERROR: creating tempdir"; exit 10; fi

    if test $fsize -le 2110; then
        cat $fname | python -c "import sys, base64; sys.stdout.write(base64.b32encode(sys.stdin.read()))" | qrencode -o $tempdir/$fbase.png -l M -i
        montage -label '%f' -page A4 -geometry +10 $tempdir/$fbase.png ${fbase}.pdf
    else
        cat $fname | python -c "import sys, base64; sys.stdout.write(base64.b32encode(sys.stdin.read()))" | split -a 2 -b 1826 -d - $tempdir/$fbase-
        for a in `ls $tempdir/$fbase-* | sort -n`; do
            echo -n "${a: -2:2} " | cat - $a | qrencode -o $tempdir/`basename $a`.png -l M -i
        done
        list=`ls $tempdir/$fbase*.png | sort -n | tr "\n" " "`
        montage -label '%f' -page A4 -tile 2x2 -geometry +10 $list ${fbase}.pdf
    fi

    if test -d $tempdir; then
        rm -r $tempdir
    fi
}


if test "$1" = ""; then usage; fi
if test "$1" = "--unittest"; then
    unittest
else
    data2pdf $1
fi
