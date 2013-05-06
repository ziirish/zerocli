#!/bin/bash

tar cvzf package.tgz main.js VERSION js/

var=$(base64 <package.tgz)

nvar=$(echo "$var" | perl -pe "s/\n/#NEWLINE#/g")

rm package.tgz

perl -pe "s|^package=.*$|package='$nvar'|" zerocli.sh >zerocli.tmp
perl -pe "s|#NEWLINE#|\n|g" zerocli.tmp >zerocli

rm zerocli.tmp

chmod +x zerocli
