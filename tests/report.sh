#!/bin/bash

(
cat <<EOF
Algorithm
-------------
Baseline
Girouard
Girouard-Ford
EOF

cat dal.out lon.out tok.out >all.out

for j in dal lon tok all
do
	echo $j | tr 'a-z' 'A-Z'
	echo ------------------
	for i in 1 2 3
	do
		grep Extract $j.out | \
		awk '{print $NF}' | \
		paste - - - | \
		awk '{print $'$i'}' | \
		grep -v '^$' | \
		awk '
			BEGIN {l=9999}
			{s+=$1; h = h>$1 ? h : $1; l = l<$1 ? l : $1}
			END {
				ll=""; lh="";
				if (l+((h-l)/2) > s/NR) ll="--"; else lh="--";
				if (l == h) ll=lh="-";
				print l lh "-[" int(s/NR + 0.5) "]-" ll h
			}
		'
	done
done

) | pr -5 -t -w100
