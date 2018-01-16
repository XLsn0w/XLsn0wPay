/*
 @author: ideawu
 @link: https://github.com/ideawu/Objective-C-RSA
*/

#import "RSA.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>

@implementation RSA

static NSString *base64_encode_data(NSData *data){
	data = [data base64EncodedDataWithOptions:0];
	NSString *ret = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	return ret;
}

static NSData *base64_decode(NSString *str){
	NSData *data = [[NSData alloc] initWithBase64EncodedString:str options:NSDataBase64DecodingIgnoreUnknownCharacters];
	return data;
}

+ (NSData *)stripPublicKeyHeader:(NSData *)d_key{
	// Skip ASN.1 public key header
	if (d_key == nil) return(nil);
	
	unsigned long len = [d_key length];
	if (!len) return(nil);
	
	unsigned char *c_key = (unsigned char *)[d_key bytes];
	unsigned int  idx	 = 0;
	
	if (c_key[idx++] != 0x30) return(nil);
	
	if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
	else idx++;
	
	// PKCS #1 rsaEncryption szOID_RSA_RSA
	static unsigned char seqiod[] =
	{ 0x30,   0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
		0x01, 0x05, 0x00 };
	if (memcmp(&c_key[idx], seqiod, 15)) return(nil);
	
	idx += 15;
	
	if (c_key[idx++] != 0x03) return(nil);
	
	if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
	else idx++;
	
	if (c_key[idx++] != '\0') return(nil);
	
	// Now make a new NSData from this buffer
	return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}

//credit: http://hg.mozilla.org/services/fx-home/file/tip/Sources/NetworkAndStorage/CryptoUtils.m#l1036
+ (NSData *)stripPrivateKeyHeader:(NSData *)d_key{
	// Skip ASN.1 private key header
	if (d_key == nil) return(nil);

	unsigned long len = [d_key length];
	if (!len) return(nil);

	unsigned char *c_key = (unsigned char *)[d_key bytes];
	unsigned int  idx	 = 22; //magic byte at offset 22

	if (0x04 != c_key[idx++]) return nil;

	//calculate length of the key
	unsigned int c_len = c_key[idx++];
	int det = c_len & 0x80;
	if (!det) {
		c_len = c_len & 0x7f;
	} else {
		int byteCount = c_len & 0x7f;
		if (byteCount + idx > len) {
			//rsa length field longer than buffer
			return nil;
		}
		unsigned int accum = 0;
		unsigned char *ptr = &c_key[idx];
		idx += byteCount;
		while (byteCount) {
			accum = (accum << 8) + *ptr;
			ptr++;
			byteCount--;
		}
		c_len = accum;
	}

	// Now make a new NSData from this buffer
	return [d_key subdataWithRange:NSMakeRange(idx, c_len)];
}

+ (SecKeyRef)addPublicKey:(NSString *)key{
	NSRange spos = [key rangeOfString:@"-----BEGIN PUBLIC KEY-----"];
	NSRange epos = [key rangeOfString:@"-----END PUBLIC KEY-----"];
	if(spos.location != NSNotFound && epos.location != NSNotFound){
		NSUInteger s = spos.location + spos.length;
		NSUInteger e = epos.location;
		NSRange range = NSMakeRange(s, e-s);
		key = [key substringWithRange:range];
	}
	key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
	key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];
	
	// This will be base64 encoded, decode it.
	NSData *data = base64_decode(key);
	data = [RSA stripPublicKeyHeader:data];
	if(!data){
		return nil;
	}

	//a tag to read/write keychain storage
	NSString *tag = @"RSAUtil_PubKey";
	NSData *d_tag = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];
	
	// Delete any old lingering key with the same tag
	NSMutableDictionary *publicKey = [[NSMutableDictionary alloc] init];
	[publicKey setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
	[publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
	[publicKey setObject:d_tag forKey:(__bridge id)kSecAttrApplicationTag];
	SecItemDelete((__bridge CFDictionaryRef)publicKey);
	
	// Add persistent version of the key to system keychain
	[publicKey setObject:data forKey:(__bridge id)kSecValueData];
	[publicKey setObject:(__bridge id) kSecAttrKeyClassPublic forKey:(__bridge id)
	 kSecAttrKeyClass];
	[publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)
	 kSecReturnPersistentRef];
	
	CFTypeRef persistKey = nil;
	OSStatus status = SecItemAdd((__bridge CFDictionaryRef)publicKey, &persistKey);
	if (persistKey != nil){
		CFRelease(persistKey);
	}
	if ((status != noErr) && (status != errSecDuplicateItem)) {
		return nil;
	}

	[publicKey removeObjectForKey:(__bridge id)kSecValueData];
	[publicKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
	[publicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
	[publicKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
	
	// Now fetch the SecKeyRef version of the key
	SecKeyRef keyRef = nil;
	status = SecItemCopyMatching((__bridge CFDictionaryRef)publicKey, (CFTypeRef *)&keyRef);
	if(status != noErr){
		return nil;
	}
	return keyRef;
}

+ (SecKeyRef)addPrivateKey:(NSString *)key{
	NSRange spos = [key rangeOfString:@"-----BEGIN RSA PRIVATE KEY-----"];
	NSRange epos = [key rangeOfString:@"-----END RSA PRIVATE KEY-----"];
	if(spos.location != NSNotFound && epos.location != NSNotFound){
		NSUInteger s = spos.location + spos.length;
		NSUInteger e = epos.location;
		NSRange range = NSMakeRange(s, e-s);
		key = [key substringWithRange:range];
	}
	key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
	key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];

	// This will be base64 encoded, decode it.
	NSData *data = base64_decode(key);
	data = [RSA stripPrivateKeyHeader:data];
	if(!data){
		return nil;
	}

	//a tag to read/write keychain storage
	NSString *tag = @"RSAUtil_PrivKey";
	NSData *d_tag = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];

	// Delete any old lingering key with the same tag
	NSMutableDictionary *privateKey = [[NSMutableDictionary alloc] init];
	[privateKey setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
	[privateKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
	[privateKey setObject:d_tag forKey:(__bridge id)kSecAttrApplicationTag];
	SecItemDelete((__bridge CFDictionaryRef)privateKey);

	// Add persistent version of the key to system keychain
	[privateKey setObject:data forKey:(__bridge id)kSecValueData];
	[privateKey setObject:(__bridge id) kSecAttrKeyClassPrivate forKey:(__bridge id)
	 kSecAttrKeyClass];
	[privateKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)
	 kSecReturnPersistentRef];

	CFTypeRef persistKey = nil;
	OSStatus status = SecItemAdd((__bridge CFDictionaryRef)privateKey, &persistKey);
	if (persistKey != nil){
		CFRelease(persistKey);
	}
	if ((status != noErr) && (status != errSecDuplicateItem)) {
		return nil;
	}

	[privateKey removeObjectForKey:(__bridge id)kSecValueData];
	[privateKey removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
	[privateKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
	[privateKey setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];

	// Now fetch the SecKeyRef version of the key
	SecKeyRef keyRef = nil;
	status = SecItemCopyMatching((__bridge CFDictionaryRef)privateKey, (CFTypeRef *)&keyRef);
	if(status != noErr){
		return nil;
	}
	return keyRef;
}

/* START: Encryption & Decryption with RSA private key */

+ (NSData *)encryptData:(NSData *)data withKeyRef:(SecKeyRef) keyRef{
	const uint8_t *srcbuf = (const uint8_t *)[data bytes];
	size_t srclen = (size_t)data.length;
	
	size_t block_size = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
	void *outbuf = malloc(block_size);
	size_t src_block_size = block_size - 11;
	
	NSMutableData *ret = [[NSMutableData alloc] init];
	for(int idx=0; idx<srclen; idx+=src_block_size){
		//NSLog(@"%d/%d block_size: %d", idx, (int)srclen, (int)block_size);
		size_t data_len = srclen - idx;
		if(data_len > src_block_size){
			data_len = src_block_size;
		}
		
		size_t outlen = block_size;
		OSStatus status = noErr;
		status = SecKeyEncrypt(keyRef,
							   kSecPaddingNone,//kSecPaddingPKCS1,
							   srcbuf + idx,
							   data_len,
							   outbuf,
							   &outlen
							   );
		if (status != 0) {
			NSLog(@"SecKeyEncrypt fail. Error Code: %d", (int)status);
			ret = nil;
			break;
		}else{
			[ret appendBytes:outbuf length:outlen];
		}
	}
	
	free(outbuf);
	CFRelease(keyRef);
	return ret;
}

+ (NSString *)encryptString:(NSString *)str privateKey:(NSString *)privKey{
	NSData *data = [RSA encryptData:[str dataUsingEncoding:NSASCIIStringEncoding] privateKey:privKey];
	NSString *ret = base64_encode_data(data);
	return ret;
}

+ (NSData *)encryptData:(NSData *)data privateKey:(NSString *)privKey{
	if(!data || !privKey){
		return nil;
	}
	SecKeyRef keyRef = [RSA addPrivateKey:privKey];
	if(!keyRef){
		return nil;
	}
	return [RSA encryptData:data withKeyRef:keyRef];
}

+ (NSData *)decryptData:(NSData *)data withKeyRef:(SecKeyRef) keyRef{
    
	const uint8_t *srcbuf = (const uint8_t *)[data bytes];
	
	size_t block_size = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
	UInt8 *outbuf = malloc(block_size);

	
	NSMutableData *ret = [[NSMutableData alloc] init];
    
    size_t outlen = block_size;
    OSStatus status = noErr;
    status = SecKeyDecrypt(keyRef,
                           kSecPaddingNone,
                           srcbuf ,
                           block_size,
                           outbuf,
                           &outlen
                           );
    [ret appendBytes:&outbuf[0] length:block_size];
    

	free(outbuf);
	CFRelease(keyRef);
	return ret;
}


+ (NSString *)decryptString:(NSString *)str privateKey:(NSString *)privKey{
	NSData *data = [[NSData alloc] initWithBase64EncodedString:str options:NSDataBase64DecodingIgnoreUnknownCharacters];
	data = [RSA decryptData:data privateKey:privKey];
	NSString *ret = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	return ret;
}

+ (NSData *)decryptData:(NSData *)data privateKey:(NSString *)privKey{
	if(!data || !privKey){
		return nil;
	}
	SecKeyRef keyRef = [RSA addPrivateKey:privKey];
	if(!keyRef){
		return nil;
	}
	return [RSA decryptData:data withKeyRef:keyRef];
}

/* END: Encryption & Decryption with RSA private key */

/* START: Encryption & Decryption with RSA public key */

+ (NSString *)encryptString:(NSString *)str publicKey:(NSString *)pubKey{
	NSData *data = [RSA encryptData:[str dataUsingEncoding:NSASCIIStringEncoding] publicKey:pubKey];
	NSString *ret = base64_encode_data(data);
	return ret;
}

+ (NSString *)encryptBCDString:(NSString *)str publicKey:(NSString *)pubKey{

    NSData *data = [RSA encryptData:[str dataUsingEncoding:NSASCIIStringEncoding] publicKey:pubKey];

    return [self bcd2Str:data];
//    NSString * hexStr = [ByteDataConvert hexStringFromData:data];
//    NSData * dt = [ByteDataConvert HEXToBCD:hexStr];
//    NSString *ret = [[NSString alloc] initWithData:dt encoding:NSASCIIStringEncoding];
//    return ret;
    
}

+ (NSData *)encryptData:(NSData *)data publicKey:(NSString *)pubKey{
	if(!data || !pubKey){
		return nil;
	}
	SecKeyRef keyRef = [RSA addPublicKey:pubKey];
	if(!keyRef){
		return nil;
	}
	return [RSA encryptData:data withKeyRef:keyRef];
}




+ (NSString *)decryptString:(NSString *)str publicKey:(NSString *)pubKey{
    
    NSData *data = [[NSData alloc] initWithBase64EncodedString:str options:NSDataBase64DecodingIgnoreUnknownCharacters];
	data = [RSA decryptData:data publicKey:pubKey];
	NSString *ret = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	return ret;
}


+ (OSStatus)verifyData:(NSData *)data sig:(NSData *)sig  publicKey:(NSString*) pubKey{

    if(!data || !pubKey || !sig) return 0;
    
    SecKeyRef keyRef = [RSA addPublicKey:pubKey];
    if(!keyRef) return 0;
    return [RSA verifyData:data sig:sig withKeyRef:keyRef];
}



+ (OSStatus)verifyData:(NSData *)data sig:(NSData *)sig  withKeyRef:(SecKeyRef) keyRef{


    OSStatus status = noErr;
    uint8_t hash[CC_SHA1_DIGEST_LENGTH];

    //先做一次SHA之后验证签名
    CC_SHA1((const void *)[data bytes], (CC_LONG)[data length], (unsigned char *)hash);
    status = SecKeyRawVerify (keyRef,
                              kSecPaddingPKCS1SHA1,
                              hash,
                              CC_SHA1_DIGEST_LENGTH,
                              (const uint8_t *)[sig bytes],
                              [sig length]
                              );
    
    if (status != 0) {
        NSLog(@"SecKeyEncrypt fail. Error Code: %d", status);
    }
    
    return status;
}


+ (NSData *)decryptData:(NSData *)data publicKey:(NSString *)pubKey{
	if(!data || !pubKey){
		return nil;
	}
	SecKeyRef keyRef = [RSA addPublicKey:pubKey];
	if(!keyRef){
		return nil;
	}
	return [RSA decryptData:data withKeyRef:keyRef];
}

/* END: Encryption & Decryption with RSA public key */


+(NSString*) bcd2Str:(NSData*)data {
    
    Byte* bytes=(Byte*)[data bytes];

    NSInteger length = [data length];
    char temp[2*length];
    char val;
    
    for (int i = 0; i < length; i++) {
        val = (char) (((bytes[i] & 0xf0) >> 4) & 0x0f);
        temp[i * 2] = (char) (val > 9 ? val + 'A' - 10 : val + '0');
        
        val = (char) (bytes[i] & 0x0f);
        temp[i * 2 + 1] = (char) (val > 9 ? val + 'A' - 10 : val + '0');
    }
    
    NSData* dt =[NSData dataWithBytes:temp length:2*length];
    
    return [[NSString alloc ] initWithData:dt encoding:NSASCIIStringEncoding];
}


@end
