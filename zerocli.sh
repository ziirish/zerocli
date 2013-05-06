#!/bin/bash

version="0.3"
tmpfile="/tmp/.zerocli.tmp"
datafile="/tmp/.zerocli.data"
curloutput="/tmp/.zerocli.curl.out"
curlerr="/tmp/.zerocli.curl.err"
curltmp="/tmp/.zerocli.curl.tmp"
server=""
me=$(basename $0)
path=$(dirname $0)
workingdir=""
config=""

ttw=10
burn=0
open=0
syntax=0
expire=1week
get=0
post=1
quiet=0
group=0
file=""
atime="5min 10min 1hour 1day 1week 1month 1year never"
engine=$(which rhino)
engineopts="rhino"

# search fo a config file and load it if present
if [ -d "$path" -a -e "$path/zerocli.conf" ]; then
	. "$path/zerocli.conf"
fi

if [ ! -z "$config" -a -e "$config" ]; then
	. "$config"
fi

if [ -f "$HOME/.zeroclirc" ]; then
	. "$HOME/.zeroclirc"
fi

# set the path variable based on the $workingdir variable
function setpath() {
	if [ ! -z "$workingdir" ]; then
		[ ! -d "$workingdir" ] && {
			cat <<EOF
Error: '$workingdir' no such directory
EOF
			exit 1
		}   
		path=$workingdir
	else
		if [ "$path" != "." ]; then
			echo $path | grep -e "^/" &>/dev/null || {
				path=$(which $me)
				[ -z "$path" ] && {
					cat <<EOF
Error: no working dir found
You can solve this problem either by calling this program with an absolute path
or by adding the script to your PATH or by setting up the 'workingdir' variable
into the script or conf file
EOF
					exit 1
				}   
			}   
		fi  
	fi
}

# DO NOT EDIT THE FOLLOWING LINE!
package=""

[ ! -x "$engine" ] && {
	myerror "Error: '$engine' not found or not executable"
	exit 1
}

# Check for curl
curl=$(which curl)
[ ! -x "$curl" ] && {
	myerror "Please install curl"
	exit 1
}

# function to extract the archive contained in $package (you can generate a self extractible archive using the compact.sh script)
function unpak() {
	[ -z "$package" ] && return
	required="js/zerocli.js js/base64.js js/flate.js js/rawdeflate.js js/rawinflate.js js/sjcl.js main.js VERSION"
	br=0
	for f in $required; do
		[ ! -f "$path/$f" ] && {
			mylog "missing '$path/$f'"
			rm -rf "$path/main.js" "$path/js" "$path/VERSION" &>/dev/null
			br=1
			break
		}
	done
	v=$(cat $path/VERSION 2>/dev/null)
	[ $br -eq 0 -a "$v" = "$version" ] && return
	mylog "Extracting files '$v' -> '$version'"
	# if $br = 1 or version mismatch at least 1 file is missing so we unpack the archive
	sav=$PWD
	cd $path || exit $?
	echo "$package" | base64 -d >package.tgz
	tar xzf package.tgz
	rm package.tgz
	cd $sav
}

# prints a log unless $quiet = 1
function mylog() {
	[ $quiet -ne 1 ] && echo "[i] $*" >&2
}

# prints error in all cases
function myerror() {
	echo "[e] $*" >&2
}

# prints the help menu and exit
function usage() {
	cat <<EOF
$me [options...] [files...]
usage:
	-c, --config <file>   use this configuration file
	-q, --quiet           do not display logs
	-b, --burn            burn after reading
	-o, --open            open discussion
	-s, --syntax          syntax coloring
	-e, --expire <time>   specify the expiration time (default: 1week)
	-f, --file <file>     file to send, you can have multiple (default: read from stdin)
	-g, --get <url>       get data from URL
	-G, --group           group all the specified files
	-p, --post            post data to server (it is the default behaviour)
	-S, --server <server> specify the server url
	-t, --ttw             time to wait between two posts (default: 10)
	-h, --help            prints this menu and exit

available time settings:
5min,10min,1hour,1day,1week,1month,1year,never
EOF
	exit 1
}

# check if the file we want to send is not empty
function testfile() {
	file=$1
	size=$(ls -l $file | awk '{print $5; }')
	test "$size" = "0" && {
		myerror "Could not send empty file"
		[ -f $tmpfile ] && rm $tmpfile
		exit 2
	}
}

# options may be followed by one colon to indicate they have a required argument
options=$(getopt -n "$me" -o "Ghpqbose:f:g:S:c:t::" -l "group,help,put,quiet,burn,open,syntax,expire:,file:,get:,server:,config:,ttw::" -- "$@") || {
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
		-q|--quiet) quiet=1 ;;
		-b|--burn) burn=1 ;;
		-o|--open) open=1 ;;
		-s|--syntax) syntax=1 ;;
		-p|--post) post=1 ;;
		-h|--help) usage ;;
		-G|--group) group=1 ;;
		# for options with required arguments, an additional shift is required
		-e|--expire) 
			expire=$(echo $2 | sed "s/^.//;s/.$//")
			shift
			t=0
			for e in $atime; do
				if [ "$expire" = "$e" ]; then
					t=1
					break
				fi
			done
			[ $t -ne 1 ] && {
				myerror "Error: '$expire' is not a valide expiration time"
				exit 1
			}
			;;
		-f|--file) file="$file $2" ; shift ;; #$(echo $2 | sed "s/^.//;s/.$//") ; shift ;;
		-g|--get) get=$(echo $2 | sed "s/^.//;s/.$//") ; shift ;;
		-S|--server) server=$(echo $2 | sed "s/^.//;s/.$//") ; shift ;;
		-t|--ttw) ttw=$(echo $2 | sed "s/^.//;s/.$//") ; shift ;;
		-c|--config) 
			config=$(echo $2 | sed "s/^.//;s/.$//")
			shift
			[ ! -e "$config" ] && {
				myerror "Error: '$config' does not exist"
				exit
			}
			. "$config"
			;;
		(--) shift; break ;;
		(-*) myerror "$me: error - unrecognized option $1"; usage ;;
		(*) break ;;
	esac
	shift
done

for arg do file="$file $arg" ; done

setpath

unpak

# verify we have a server address to post data
[ -z "$server" -a "$get" = "0" ] && {
	myerror "Error: You must specify a server in order to post data"
	myerror "You can set it in the script or use the -S argument or the config file"
	exit 1
}

# function that post or get data using curl
function mycurl() {
	url=$1
	data=$2
	if [ -z "$data" ]; then
		output=$($curl -i                                         \
			 -o $curloutput                                       \
			 --stderr $curlerr                                    \
			 $url)
		ret=$?
	else
		echo "$data" >$curltmp
		output=$($curl -i                                         \
			 -H "Content-Type: application/x-www-form-urlencoded" \
			 -X POST                                              \
			 -d @$curltmp                                         \
			 -o $curloutput                                       \
			 --stderr $curlerr                                    \
			 $url)
		ret=$?
		rm $curltmp
	fi
		
	# check the return code
	[ $ret -ne 0 ] && {
		myerror "Error: curl returned $ret"
		myerror "Please refer to curl manpage for more details"
		cat $curlerr >&2
		rm $curlerr $curloutput &>/dev/null
		exit $ret
	}

	# check the HTTP return code
	code=$(grep -e "^HTTP/1\." $curloutput | tail -1 | awk '{print $2;}')
	case $code in
		200)
			[ -z "$data" ] && return
			# When we post data, we expect the Content-Type to be application/json
			ct=$(grep "^Content-Type:" $curloutput | awk '{print $2;}' | perl -pe "s/\r\n$//")
			[ -z "$ct" -o "$ct" != "application/json" ] && {
				myerror "Error: server returned code $code but with content-type '$ct' where 'application/json' is expected"
				rm $curlerr $curloutput &>/dev/null
				exit 6
			}
			mylog "OK server returned code 200" ;;
		302|301)
			redirect=$(grep "^Location:" $curloutput | awk '{print $2;}' | perl -pe "s/\r\n$//")
			mylog "Got a redirection $code to '$redirect'"
			mylog "retrying..."
			mycurl "$redirect" "$data"
			;;
		*) 
			myerror "Error: server returned $code"
			rm $curlerr $curloutput &>/dev/null
			exit 5
			;;
	esac
}

# function that post data
# it cat take a list of file as argument and will send them recursively
function post() {
	myfile=$1
	[ -z "$myfile" ] && {
		cat >$tmpfile <&0
		myfile=$tmpfile
	}

	i=0
	for f in $myfile; do
		i=$(($i+1))
		[ $i -eq 2 ] && break
	done

	[ $i -eq 2 ] && {
		for f in $myfile; do
			if [ $group -eq 0 ]; then
				post $f
				# by default ZeroBin expect us to wait 10s between each post
				mylog "waiting $ttw seconds before next post"
				sleep $ttw
			else
				tmp=$(echo $f | sed "s/^.//;s/.$//")
				cat $tmp >>$tmpfile
				myfile=$tmpfile
			fi
		done
		[ $group -eq 0 ] && return
	}

	[ "$myfile" != "$tmpfile" ] && myfile=$(echo $myfile | sed "s/^.//;s/.$//")

	testfile $myfile
	
	$engine "$path/main.js" $engineopts "$path/" "post" "$myfile" 2>&1 >$datafile &
	pid=$!

	[ $quiet -ne 1 ] && echo >&2

	dot=".  "
	while ps $pid &>/dev/null; do
		[ $quiet -ne 1 ] && echo -n -e "\rEncrypting data$dot" >&2
		case $dot in
			".  ") dot=".. " ;;
			".. ") dot="..." ;;
			"...") dot=".  " ;;
		esac
		sleep 1
	done

	[ -f $tmpfile ] && rm $tmpfile

	wait $pid
	ret=$?
	[ $ret -ne 0 ] && {
		[ $quiet -ne 1 ] && echo -e "\rEncrypting data... [failed]" >&2
		myerror "Error: javascript engine returned $ret"
		cat $datafile >&2
		rm $datafile
		exit $ret
	}

	[ $quiet -ne 1 ] && echo -e "\rEncrypting data... [done]" >&2

	key=$(grep "key:" $datafile | sed "s/^key://")

	# we need to 'htmlencode' our data before posting them. We use this hack to handle large data
	encode=$(perl -MURI::Escape -e '@f=<>; foreach (@f) { if (m/^data:/) { s/^data://; print uri_escape($_); exit(0); } }' $datafile)
	rm $datafile
	params="data=$encode&burnafterreading=$burn&expire=$expire&opendiscussion=$open&syntaxcoloring=$syntax"

	mycurl "$server" "$params"

	status=$(tail -1 $curloutput | python -m json.tool 2>/dev/null | grep status | cut -d: -f2 | sed "s/ //g");
	[ -z "$status" -o "$status" != "0" ] && {
		myerror "something went wrong..."
		cat $curloutput >&2
		rm $curlerr $curloutput &>/dev/null
		exit 4
	}
	id=$(tail -1 $curloutput | python -m json.tool | grep id | cut -d: -f2 | sed "s/ //g;s/,//g;s/\"//g");
	deletetoken=$(tail -1 $curloutput | python -m json.tool | grep deletetoken | cut -d: -f2 | sed "s/ //g;s/,//g;s/\"//g");

	# add a / in server if not present
	server=$(echo $server | sed -r "s|^(.+[^/])$|\1/|")

	if [ "$myfile" = "$tmpfile" ]; then
		echo "Your data have been successfully pasted"
	else
		echo "The file '$myfile' has been successfully pasted"
	fi
	echo "url: $server?$id#$key"
	echo "delete url: $server?pasteid=$id&deletetoken=$deletetoken"

	rm $curlerr $curloutput &>/dev/null
}

function get() {

	echo $get | grep -E "^.*\?.*#(.+)$" &>/dev/null
	[ $? -ne 0 ] && {
		myerror "Error: missing key to decrypt data"
		exit 7
	}
	key=$(echo $get | sed -r "s/^.*\?.*#(.+)$/\1/")
	mycurl "$get"
	str=$(grep "cipherdata" $curloutput)
	rm $curlerr $curloutput &>/dev/null
	data=$(echo $str | grep ">\[.*\]<")
	[ -z "$data" ] && {
		myerror "Paste does not exist is expired or has been removed"
		exit 3
	}
	clean=$(echo $str | sed -r "s/^.*(\[.*)$/\1/;s/^(.*\]).*$/\1/")
	data=$(echo $clean | sed -r "s/^.*data\":(.*),\"meta.*$/\1/;s/\\\\//g;s/^.//;s/.$//")

	$engine "$path/main.js" $engineopts "$path/" "get" "$key" "$data" 2>&1 >$datafile &
	pid=$!

	dot=".  "
	while ps $pid &>/dev/null; do
		[ $quiet -ne 1 ] && echo -n -e "\rDecrypting data$dot" >&2
		case $dot in
			".  ") dot=".. " ;;
			".. ") dot="..." ;;
			"...") dot=".  " ;;
		esac
		sleep 1
	done

	wait $pid
	ret=$?
	[ $ret -ne 0 ] && {
		[ $quiet -ne 1 ] && echo -e "\rDecrypting data... [failed]" >&2
		myerror "Error: javascript engine returned $ret"
		cat $datafile >&2
		rm $datafile
		exit $ret
	}

	[ $quiet -ne 1 ] && echo -e "\rDecrypting data... [done]" >&2

	cat $datafile
	rm $datafile

	exit 0
}

[ "$get" != "0" ] && get

>$tmpfile

[ "$post" = "1" ] && post "$file"

exit 0
