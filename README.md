ZeroCli is a simple cli for ZeroBin

It requires rhino to execute javascript in command line (as the encryption is
one client-side) : https://developer.mozilla.org/en-US/docs/Rhino

TODO:
	- finish the POST

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

Example:
$ ./zerocli.sh --get="http://myserver.tld/?51a7e2fdaba81d23#GkWVhyg4bvwi3rQzkXSvW4pPIByOx8C1NzC+QVtTKZAs=" | tee -a pouet
gfgfdgfd                                                
gfdgfd
fdsgf
fdsfds
$ cat pouet 
gfgfdgfd
gfdgfd
fdsgf
fdsfds
