#!/bin/bash

version="0.1"
tmpfile=".zerocli.tmp"
datafile=".zerocli.data"
server=""

burn=0
open=0
syntax=0
expire=1week
get=0
post=1
file=""

# DO NOT EDIT THE FOLLOWING!
package=""

# Check for rhino
rhino=$(which rhino)
[ ! -x "$rhino" ] && {
	echo "Please install rhino first"
	echo "https://developer.mozilla.org/en-US/docs/Rhino"
	exit 1
}

function unpak() {
	[ -z "$package" ] && return
	required="js/zerocli.js js/base64.js js/flate.js js/jquery.js js/rawdeflate.js js/rawinflate.js js/sjcl.js main.js VERSION"
	br=0
	for f in $required; do
	    [ ! -f $f ] && {
	        rm -rf main.js js &>/dev/null
	        br=1
	        break
		}
	done
	v=$(cat VERSION 2>/dev/null)
	[ $br -eq 0 -a "$v" = "$version" ] && return
	# if $br = 1 or version missmatch at least 1 file is missing so we unpack the archive
	echo "$package" | base64 -d >package.tgz
	tar xzf package.tgz
	rm package.tgz
}

unpak

function usage() {
	cat <<EOF
usage:
	-b, --burn            burn after reading
	-o, --open            open discussion
	-s, --syntax          syntax coloring
	-e, --expire <time>   specify the expiration time (default: 1week)
	-f, --file <file>     file to send (default: read from stdin)
	-g, --get <url>       get data from URL
	-p, --post            post data to server
	-S, --server <server> specify the server url

available time settings:
5min,10min,1hour,1day,1week,1month,1year,never
EOF
	exit 1
}

function testfile() {
	file=$1
	size=$(ls -l $file | awk '{print $5; }')
	test "$size" = "0" && {
		echo "Could not send empty file"
		[ -f $tmpfile ] && rm $tmpfile
		exit 2
	}
}

# options may be followed by one colon to indicate they have a required argument
options=$(getopt -o pbose:f:g:S: -l put,burn,open,syntax,expire:,file:,get:,server: -- "$@") || {
	# something went wrong, getopt will put out an error message for us
	usage
}

set -- $options

if [ "$(getopt --version)" = " --" ]; then
	# bsd getopt - skip configuration declarations
	nb_delims_to_remove=2
	while [ $# -gt 0 ]; do
		if [ $1 = "--" ]; then
			shift
			nb_delims_to_remove=$(expr $nb_delims_to_remove - 1)
			if [ $nb_delims_to_remove -lt 1 ]; then
				break
			fi
		fi

		shift
	done
fi

while [ $# -gt 0 ]
do
	case $1 in
	    -b|--burn) burn=1 ;;
		-o|--open) open=1  ;;
	    -s|--syntax) syntax=1 ;;
	    -p|--post) post=1 ;;
	    # for options with required arguments, an additional shift is required
		-e|--expire) expire=$(echo $2 | sed "s/^.//;s/.$//") ; shift ;;
		-f|--file) file=$(echo $2 | sed "s/^.//;s/.$//") ; shift ;;
		-g|--get) get=$(echo $2 | sed "s/^.//;s/.$//") ; shift ;;
		-S|--server) server=$(echo $2 | sed "s/^.//;s/.$//") ; shift ;;
	    (--) shift; break ;;
		(-*) echo "$0: error - unrecognized option $1" 1>&2; usage;;
	    (*) break ;;
	esac
	shift
done

[ -z "$server" -a "$get" = "0" ] && {
	echo "Error: You must specify a server"
	echo "You can set it in the script or use the -S argument"
	exit 1
}

function post() {
	[ -z "$file" ] && {
		cat >$tmpfile <&0
		file=$tmpfile
	}

	testfile $file

	$rhino main.js put $file 2>&1 >$datafile &
	pid=$!

	dot=".  "
	while ps $pid &>/dev/null; do
		echo -n -e "\rEncrypting data$dot"
		case $dot in
			".  ") dot=".. " ;;
			".. ") dot="..." ;;
			"...") dot=".  " ;;
		esac
		sleep 1
	done

	echo -e -n "\r                                                                   \r"

	[ -f $tmpfile ] && rm $tmpfile

	key=$(grep "key:" $datafile | sed "s/^key://")
	data=$(grep "data:" $datafile | sed "s/^data://")

	rm $datafile

	encode=$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$data")
	params="data=$encode&burnafterreading=$burn&expire=$expire&opendiscussion=$open&syntaxcoloring=$syntax"

	output=$(curl -s                                          \
		 -H "Content-Type: application/x-www-form-urlencoded" \
		 -X POST                                              \
		 -d "$params"                                         \
		 $server)

	status=$(echo $output | python -m json.tool | grep status | cut -d: -f2 | sed "s/ //g");
	[ $status -ne 0 ] && {
		echo $output | python -m json.tool
		exit 4
	}
	id=$(echo $output | python -m json.tool | grep id | cut -d: -f2 | sed "s/ //g;s/,//g;s/\"//g");
	deletetoken=$(echo $output | python -m json.tool | grep deletetoken | cut -d: -f2 | sed "s/ //g;s/,//g;s/\"//g");

	echo "Your data have been successfully pasted"
	echo "url: $server?$id#$key"
	echo "delete url: $server?pasteid=$id&deletetoken=$deletetoken"

	exit 0
}

function get() {

	key=$(echo $get | sed -r "s/^.*\?.*#(.*)$/\1/")
	str=$(wget -q "$get" -O - | grep "cipherdata")
	data=$(echo $str | grep ">\[.*\]<")
	[ -z "$data" ] && {
		echo "Paste does not exist or is expired"
		exit 3
	}
	clean=$(echo $str | sed -r "s/^.*(\[.*)$/\1/;s/^(.*\]).*$/\1/")
	data=$(echo $clean | sed -r "s/^.*data\":(.*),\"meta.*$/\1/;s/\\\\//g;s/^.//;s/.$//")

	$rhino main.js get "$key" "$data" 2>&1 >$datafile &
	pid=$!

	dot=".  "
	while ps $pid &>/dev/null; do
	    echo -n -e "\rDecrypting data$dot" >&2
	    case $dot in
	        ".  ") dot=".. " ;;
	        ".. ") dot="..." ;;
	        "...") dot=".  " ;;
	    esac
	    sleep 1
	done

	echo -e -n "\r                                                        \r" >&2

	cat $datafile
	rm $datafile

	exit 0
}

[ "$get" != "0" ] && get
[ "$post" = "1" ] && post

exit 0

# DO NOT EDIT THE FOLLOWING!
