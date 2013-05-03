RawDeflate = {};

l = arguments.length;

if (l < 1) {
	print('Missing path!');
	quit(1);
}

path = arguments[0];

load(path+'js/sjcl.js');
load(path+'js/base64.js');
load(path+'js/rawinflate.js');
load(path+'js/rawdeflate.js');
load(path+'js/zerocli.js');

if (l < ) {
	print('Missing method!');
	quit(2);
}

method = arguments[1];

if (method == "put") {
	if (l != 3) {
		print('Missing filename!');
		quit(3);
	}

	filename = arguments[2];
	t = readFile(filename);
	//print('data: ' + t);
	encrypt_data(t);
} else if (method == "get") {
	if (l != 4) {
		print('Missing key and/or message');
		quit(4);
	}

	key = arguments[2];
	data = arguments[3];

	/*
	print('key: '+key);
	print('data: '+data);
	*/

	print(decrypt_data(key, data));
}
