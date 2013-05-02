RawDeflate = {};

load('js/sjcl.js');
load('js/base64.js');
load('js/rawinflate.js');
load('js/rawdeflate.js');
//load('js/jquery.js');
load('js/zerocli.js');

l = arguments.length;

if (l < 1) {
	print('Missing method!');
	quit(2);
}

method = arguments[0];

if (method == "put") {
	if (l != 2) {
		print('Missing filename!');
		quit(1);
	}

	filename = arguments[1];
	t = readFile(filename);
	//print('data: ' + t);
	encrypt_data(t);
} else if (method == "get") {
	if (l != 3) {
		print('Missing key and/or message');
		quit(1);
	}

	key = arguments[1];
	data = arguments[2];

	/*
	print('key: '+key);
	print('data: '+data);
	*/

	print(decrypt_data(key, data));
}
