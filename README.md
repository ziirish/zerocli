`ZeroCli` is a simple cli for [ZeroBin](http://sebsauvage.net/wiki/doku.php?id=php:zerobin) written in bash.

# Requirements

It requires [rhino](https://developer.mozilla.org/en-US/docs/Rhino) to execute javascript in command line (as the encryption is
done on client-side)

Alternatively, you can now use [v8](https://developers.google.com/v8/build) instead of rhino.

# Usage

```
zerocli.sh [options...] [files...]
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
```

# Features:

* You can now have a config file either in `$HOME/.zeroclirc` or in the `zerocli` directory
or you can hard code the config file location in `zerocli.sh`
`$HOME/.zeroclirc` is the last file we probe so it override the previous settings
The options passed to the command-line override all the settings
A `zerocli.conf` is given in example
* You can build a self-extractible script using `compact.sh`. This will extract the required
files in your working directory (if set) or in your script's directory
* You can send multiple files
    * with the -G option all the files will be send together as one file

# Examples

I wrote `zerocli` for pasting output of commands on my servers without having to copy/paste
them using *pipes*.

As a side-effect, you can paste binary files :

``` bash
$ file qrcode.png    
qrcode.png: PNG image data, 248 x 248, 1-bit colormap, non-interlaced
$ md5sum qrcode.png
c4fc209e25e8b2703a5b2a2691a7d9b3  qrcode.png
$ base64 qrcode.png | zerocli

Encrypting data... [done]
[i] OK server returned code 200
Your data have been successfully pasted
url: https://paste.example.org/?7951f1b227c52e83#ZZZZZZZZZZ6N3fFRSFIOfXlFMwSYzNa9dpGy0=
delete url: https://paste.example.org/?pasteid=XXXXXXXXX&deletetoken=YYYYYYYYYYYYYY
$ zerocli -g https://paste.example.org/?7951f1b227c52e83#ZZZZZZZZZZ6N3fFRSFIOfXlFMwSYzNa9dpGy0= | base64 -d >/tmp/getzerocli
Decrypting data... [done]
$ file /tmp/getzerocli
/tmp/getzerocli: PNG image data, 248 x 248, 1-bit colormap, non-interlaced
$ md5sum /tmp/getzerocli
c4fc209e25e8b2703a5b2a2691a7d9b3  /tmp/getzerocli
```
