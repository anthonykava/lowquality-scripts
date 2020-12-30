<?php
// -----------------------------------------------------------------------------
// avak.crypto.php
// -----------------------------------------------------------------------------
// I'm old and have successfully resisted the powers of the dark side, i.e., ob-
// ject-oriented programming, since at least the 1990s.
//
// Hence this procedural cruft with functions useful for cryptography in PHP.
// -----------------------------------------------------------------------------
//                                            @anthonykava 2020-12-29.1842.78-75

// shortcut to trigger a warning
function warn( $errorMessage='Unknown error, blame the scribe' ) {
    trigger_error( $errorMessage, E_USER_WARNING );
}

// generates and returns $len random bytes (32 bytes = 256 bits)
function randomBytes( $len=32 ) {
    $ret = openssl_random_pseudo_bytes( $len, $cryptoStrong );
    if( !$cryptoStrong ) warn( "WARNING: randomBytes() -> openssl_random_pseudo_bytes() not crypto_strong !!" );
    return( $ret );
}

// shortcut for SHA-256 hashing, takes arbitrary $data; calculates and returns string of hexits (text of hex bytes)
function sha256( $data=null ) {
    return( hash( 'sha256', $data ) );
}

// Some inspirations:
//   https://github.com/spatie/crypto
//   https://freek.dev/1829-encrypting-and-signing-data-using-privatepublic-keys-in-php
//   https://paragonie.com/blog/2016/12/everything-you-know-about-public-key-encryption-in-php-is-wrong

// takes arbitrary $data, ASCII public key; returns binary cipher text
function rsaEncryptPublic( $data=null, $publicKeyString=null ) {
    $encryptedData = null;
    if( $data && $publicKeyString ) {
        $publicKey = openssl_pkey_get_public( $publicKeyString );
        if( $publicKey ) {
            openssl_public_encrypt( $data, $encryptedData, $publicKey, OPENSSL_PKCS1_OAEP_PADDING ); // default OPENSSL_PKCS1_PADDING
        } else {
            warn( "WARNING: rsaEncryptPublic() -> openssl_pkey_get_public()" );
        }
    }
    return( $encryptedData );
}

// takes binary cipher text $data, ASCII public key; returns (binary) plain text
function rsaDecryptPublic( $data=null, $publicKeyString=null ) {
    $decryptedData = null;
    if( $data && $publicKeyString ) {
        $publicKey = openssl_pkey_get_public( $publicKeyString );
        if( $publicKey ) {
            openssl_public_decrypt( $data, $decryptedData, $publicKey, OPENSSL_PKCS1_OAEP_PADDING );
            if( is_null( $decryptedData ) ) {
                warn( "WARNING: rsaDecryptPublic() -> openssl_public_decrypt()" );
            }
        } else {
            warn( "WARNING: rsaDecryptPublic() -> openssl_pkey_get_public()" );
        }
    }
    return( $encryptedData );
}

// takes arbitrary $data, base64-encoded $signature, ASCII public key; returns 1=good, 0=bad, -1=error
function rsaVerifyPublic( $data=null, $signature=null, $publicKeyString=null ) {
    $verification = -1;
    if( $data && $signature && $publicKeyString ) {
        $publicKey = openssl_pkey_get_public( $publicKeyString );
        if( $publicKey ) {
            $verification = openssl_verify( $data, base64_decode( $signature ), $publicKey, OPENSSL_ALGO_SHA256 );
        } else {
            warn( "WARNING: rsaVerifyPublic() -> openssl_pkey_get_public()" );
        }
    }
    return( $verification );
}

// takes ASCII public key; returns array() from openssl_pkey_get_details
function rsaDetailsPublic( $publicKeyString=null ) {
    $details = null;
    if( $publicKeyString ) {
        $publicKey = openssl_pkey_get_public( $publicKeyString );
        if( $publicKey ) {
            $details = openssl_pkey_get_details( $publicKey );
        } else {
            warn( "WARNING: rsaDetailsPublic() -> openssl_pkey_get_public()" );
        }
    }
    return( $details );
}

// takes arbitrary $data, ASCII private key, optional $password (for encrypted keys); returns binary cipher text
function rsaEncryptPrivate( $data=null, $privateKeyString=null, $password=null ) {
    $encryptedData = null;
    if( $data && $privateKeyString ) {
        $privateKey = openssl_pkey_get_private( $privateKeyString, $password );
        if( $privateKey ) {
            openssl_private_encrypt( $data, $encryptedData, $privateKey, OPENSSL_PKCS1_OAEP_PADDING ); // default OPENSSL_PKCS1_PADDING
        } else {
            warn( "WARNING: rsaEncryptPrivate() -> openssl_pkey_get_private()" );
        }
    }
    return( $encryptedData );
}

// takes binary cipher text $data, ASCII private key, optional $password (for encrypted keys); returns (binary) plain text
function rsaDecryptPrivate( $data=null, $privateKeyString=null, $password=null ) {
    $decryptedData = null;
    if( $data && $privateKeyString ) {
        $privateKey = openssl_pkey_get_private( $privateKeyString, $password );
        if( $privateKey ) {
            openssl_private_decrypt( $data, $decryptedData, $privateKey, OPENSSL_PKCS1_OAEP_PADDING );
            if( is_null( $decryptedData ) ) {
                warn( "WARNING: rsaDecryptPrivate() -> openssl_private_decrypt()" );
            }
        } else {
            warn( "WARNING: rsaDecryptPrivate() -> openssl_pkey_get_private()" );
        }
    }
    return( $decryptedData );
}

// takes arbitrary $data, ASCII private key, optional $password (for encrypted keys); returns base64-encoded $signature
function rsaSignPrivate( $data=null, $privateKeyString=null, $password=null ) {
    $signature = null;
    if( $data && $privateKeyString ) {
        $privateKey = openssl_pkey_get_private( $privateKeyString, $password );
        if( $privateKey ) {
            openssl_sign( $data, $signature, $privateKey, OPENSSL_ALGO_SHA256 );
        } else {
            warn( "WARNING: rsaSignPrivate() -> openssl_pkey_get_private()" );
        }
    }
    return( base64_encode( $signature ) );
}

// takes ASCII private key, optional $password (for encrypted keys); returns array() from openssl_pkey_get_details()
function rsaDetailsPrivate( $privateKeyString=null, $password=null ) {
    $details = null;
    if( $privateKeyString ) {
        $privateKey = openssl_pkey_get_private( $privateKeyString, $password );
        if( $privateKey ) {
            $details = openssl_pkey_get_details( $privateKey );
        } else {
            warn( "WARNING: rsaDetailsPrivate() -> openssl_pkey_get_private()" );
        }
    }
    return( $details );
}

// takes optional passphrase; returns ASCII private key and public key, respectively, in an array()
function rsaGenKeypair( $password=null ) {
    $rawPrivKey = openssl_pkey_new([
        'digest_alg'        => OPENSSL_ALGO_SHA512,
        'private_key_type'  => OPENSSL_KEYTYPE_RSA,
        'private_key_bits'  => 4096,
    ]);
    openssl_pkey_export( $rawPrivKey, $privateKey, $password );     // export private key to $privateKey
    $publicKey = openssl_pkey_get_details( $rawPrivKey )['key'];    // export public key to $publicKey
    return( [ $privateKey, $publicKey ] );
}

// Some inspirations:
//   https://gist.github.com/turret-io/957e82d44fd6f4493533
//   https://www.php.net/manual/en/function.openssl-encrypt.php
//     ^-- also see: Example #2 AES Authenticated Encryption example for PHP 5.6+

// just a shortcut for randomBytes() for legacy work
function aesGenKey( $len=32 ) {
    return( randomBytes( $len ) );  // 32 bytes = 256 bits
}

// returns appropriate number of random bytes to provide an IV for cipher $cipher
function aesGenIV( $cipher='aes-256-ctr' ) {
    return( randomBytes( openssl_cipher_iv_length( $cipher ) ) );
}

// takes arbitrary $data, binary $key; returns base64-encoded data (16-byte IV, 32-byte HMAC, then cipher text)
function aesEncrypt( $data=null, $key=null, $cipher='aes-256-ctr', $iv=null ) {
    if( is_null( $iv ) ) $iv = aesGenIV( $cipher );             // generate random IV if not specified
    $encryptedData = openssl_encrypt( $data, $cipher, $key, OPENSSL_RAW_DATA, $iv );
    $hmac = hash_hmac( 'sha256', $encryptedData, $key, true );  // true = as binary
    return( base64_encode( $iv . $hmac . $encryptedData ) );
}

// takes base64-encoded $data (16-byte IV, 32-byte HMAC, then cipher text), binary $key; returns raw plain text
function aesDecrypt( $data=null, $key=null, $cipher='aes-256-ctr', $iv=null ) {
    $ret = null;
    $bin = base64_decode( $data );                                                      // decode base64-encoded $data
    if( is_null( $iv ) ) $iv = substr( $bin, 0, openssl_cipher_iv_length( $cipher ) );  // extract IV if not specified
    $hmac = substr( $bin, openssl_cipher_iv_length( $cipher ), 32 );                    // 32 bytes = 256 bits for SHA-256
    $encryptedData = substr( $bin, openssl_cipher_iv_length( $cipher ) + 32 );          // rest is cipher text
    if( hash_equals( $hmac, hash_hmac( 'sha256', $encryptedData, $key, true ) ) ) {     // return plain text only if HMAC matches
        $ret = openssl_decrypt( $encryptedData, $cipher, $key, OPENSSL_RAW_DATA, $iv );
    } else {
        warn( "WARNING: aesDecrypt() HMAC mismatch" );
    }
    return( $ret );
}

// derives a 256-bit key from arbitrary $password; returns a string with salt:iterations:key (salt and key base64-encoded)
function deriveKey( $password=null, $salt=null, $iterations=null ) {
    if( !$salt )        $salt = randomBytes( 16 );
    if( !$iterations )  $iterations = 331337;   // 100,000 took ~250 ms on my 2018-era PC
    return( base64_encode( $salt ) . ":${iterations}:" . base64_encode( hash_pbkdf2( 'sha256', $password, $salt, $iterations, 32, true ) ) );
}

?>
