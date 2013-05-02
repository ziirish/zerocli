/**
 * code inspired by ZeroBin
 */

// TODO: fix the generator
// Immediately start random number generator collector.
//sjcl.random.startCollectors();

/**
 * Compress a message (deflate compression). Returns base64 encoded data.
 *
 * @param string message
 * @return base64 string data
 */
function compress(message) {
    return Base64.toBase64( RawDeflate.deflate( Base64.utob(message) ) );
}

/**
 * Decompress a message compressed with compress().
 */
function decompress(data) {
    return Base64.btou( RawDeflate.inflate( Base64.fromBase64(data) ) );
}

/**
 * Compress, then encrypt message with key.
 *
 * @param string key
 * @param string message
 * @return encrypted string data
 */
function zeroCipher(key, message) {
    return sjcl.encrypt(key,compress(message));
}
/**
 *  Decrypt message with key, then decompress.
 *
 *  @param key
 *  @param encrypted string data
 *  @return string readable message
 */
function zeroDecipher(key, data) {
    return decompress(sjcl.decrypt(key,data));
}

function encrypt_data(message) {
	// FIXME
    // If sjcl has not collected enough entropy yet, display a message.
//    if (!sjcl.random.isReady())
//    {
//        print('Not enough entropy...');
//        sjcl.random.addEventListener('seeded', function(){ test_send_data(message); }); 
//        return; 
//    }
    
    var randomkey = sjcl.codec.base64.fromBits(sjcl.random.randomWords(8, 0), 0);
    var cipherdata = zeroCipher(randomkey, message);
	print('key:' + randomkey);
	print('data:' + cipherdata);

}

function decrypt_data(key, data) {
	return zeroDecipher(key, data);
}
