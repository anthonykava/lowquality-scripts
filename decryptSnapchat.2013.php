#!/usr/bin/php -q
<?php
/*
   decryptSnapchat.2013.php - Rough script for decrypting Snapchat encrypted files in 2013

   Prerequisites: PHP 5 w/ modules for MCrypt and PDO (for SQLite)

   Looks for .jpg.nomedia and .mp4.nomedia files from the suspect phone
   Tries legacy simple encryption first then Stories encryption
   Needs key and initialisation vector (IV) for Stories (can read tcspahn.db)
   
   @anthonykava
   Updated: 2013-11-12 0430 hrs
*/

$tryAllKeys=1;	// set to 0 to stop script from trying all keys/IVs we know

if($argc<2)
{
	echo "\nUsage: $argv[0] inputFile [outputFile] [base64_key] [base64_iv]\n\n";
}
else
{
	$inputFile=$argv[1];
	$outputFile=null;
	$base64_key=null;
	$base64_iv=null;

	if($argc>2)
	{
		$outputFile=$argv[2];
		if($argc==5)
		{
			$base64_key=$argv[3];
			$base64_iv=$argv[4];
		}
	}
	else
	{
		$outputFile=preg_replace('/\.nomedia$/','',$inputFile);
		if($inputFile===$outputFile)
		{
			$outputFile=$inputFile.'.dec';
		}
	}

	if(!file_exists($inputFile))
	{
		echo "File not found: $inputFile\n";
	}
	elseif((!$base64_key || !$base64_iv) && !file_exists('tcspahn.db'))
	{
		echo "WARNING: Must provide key and IV or have 'tcspahn.db' in the working directory for Stories\n";
	}
	else
	{

		$cipherText=file_get_contents($inputFile);
		echo "Operation\tFilename\tBytes\tMD5\tSHA-1\tGuessedType\n";
		echo "Read\t$inputFile\t".strlen($cipherText)."\t".md5($cipherText)."\t".sha1($cipherText)."\t".guessType($cipherText)."\n";
		$plainText=decryptLegacy($cipherText);

		$guessedType=guessType($plainText);
		if($guessedType!=='Unknown' && $fh=fopen($outputFile,'w'))
		{
			fwrite($fh,$plainText,strlen($plainText));
			fclose($fh);
			echo "Wrote (LEGACY)\t$outputFile\t".strlen($plainText)."\t".md5($plainText)."\t".sha1($plainText)."\t".$guessedType."\n";
		}
		else
		{
			echo "FAIL LEGACY\t(didn't write)\t".strlen($plainText)."\t".md5($plainText)."\t".sha1($plainText)."\t".$guessedType."\n";

			if(!$base64_key || !$base64_iv)
			{
				if($dbh=new PDO('sqlite:tcspahn.db'))
				{
					$sth=$dbh->prepare("select SnapId from StoryVideoFiles where FilePath like '%$inputFile'");
					$sth->execute();
					$res=$sth->fetch(PDO::FETCH_ASSOC);
					$SnapId=$res['SnapId'];
					if(!$SnapId)
					{
						$sth=$dbh->prepare("select SnapId from StoryImageFiles where FilePath like '%$inputFile'");
						$sth->execute();
						$res=$sth->fetch(PDO::FETCH_ASSOC);
						$SnapId=$res['SnapId'];
						if(!$SnapId)
						{
							echo "ERROR: Need key/IV for decryption -- not provided and could not find SnapId in the database\n";
						}
					}
					else
					{
						$sth=$dbh->prepare("select MediaKey,MediaIv from FriendStoryTable where StoryId=?");
						$sth->execute(array($SnapId));
						$res=$sth->fetch(PDO::FETCH_ASSOC);
						$base64_key=$res['MediaKey'];
						$base64_iv=$res['MediaIv'];
					}
					$dbh=null;
					if($base64_key && $base64_iv)
					{
						echo "Info: Retrieved data from 'tcspahn.db' => SnapId=$SnapId MediaKey=$base64_key MediaIv=$base64_iv\n";
					}
				}
				else
				{
					echo "ERROR: Could not open database 'tcspahn.db'\n";
				}
			}

			$keysets=array();
			if(!$base64_key || !$base64_iv)
			{
				echo "WARN: Need key/IV for decryption -- not provided and did not find them in the database\n";
			}
			else
			{
				$keysets[]=array($base64_key,$base64_iv);
			}

			// Collect keys/IVs for a bit of lame brute force
			if($dbh=new PDO('sqlite:tcspahn.db'))
			{
				$sth=$dbh->prepare("select MediaKey,MediaIv from FriendStoryTable ".
							"union select MediaKey,MediaIv from MyStoryTable");
				$sth->execute();
				while($res=$sth->fetch(PDO::FETCH_ASSOC))
				{
					$keysets[]=array($res['MediaKey'],$res['MediaIv']);
				}
				$dbh=null;
			}

			$success=0;
			$i=-1;
			while(!$success && ++$i<count($keysets))
			{
				$keyset=$keysets[$i];
				$base64_key=$keyset[0];
				$base64_iv=$keyset[1];

				// Try Stories decryption
				$plainText=decrypt($cipherText,$base64_key,$base64_iv);
	
				$guessedType=guessType($plainText);
				if(strlen($plainText)>0)
				{
					if($guessedType!=='Unknown' && $fh=fopen($outputFile,'w'))
					{
						fwrite($fh,$plainText,strlen($plainText));
						fclose($fh);
						echo "Wrote (STORIES)\t$outputFile\t".strlen($plainText)."\t".md5($plainText)."\t".sha1($plainText)."\t".$guessedType."\n";
						$cipherText=null;
						$success=1;
					}
					elseif($fh=fopen($outputFile.'.'.$i,'w'))
					{
						fwrite($fh,$plainText,strlen($plainText));
						fclose($fh);
						echo "Wrote Possible (STORIES)\t$outputFile\.$i\t".strlen($plainText)."\t".md5($plainText)."\t".sha1($plainText)."\t".$guessedType."\n";
					}
				}
				else
				{
					echo "FAIL STORIES\t(didn't write)\t".strlen($plainText)."\t".md5($plainText)."\t".sha1($plainText)."\t".$guessedType."\n";
				}
			}
		}
	}
}

exit(0);

// guessType($data) - looks for file headers for MP4, JPEG, PNG
function guessType($data=null)
{
	$ret='Unknown';
	$firstBytes=64;
	if(preg_match('/mp4/i',substr($data,0,$firstBytes)))
	{
		$ret='video/mp4';
	}
	elseif(preg_match('/JFIF/i',substr($data,0,$firstBytes)) || preg_match('/Exif/i',substr($data,0,$firstBytes)))
	{
		$ret='image/jpeg';
	}
	elseif(preg_match('/sBIT/i',substr($data,0,$firstBytes)))
	{
		$ret='image/png';
	}
	return($ret);
}

/******************************************************************************

 The following functions were copied / inspired by:

   http://stackoverflow.com/questions/19196728/aes-128-encryption-in-java-decryption-in-php

 ******************************************************************************/

//decrypt(cipher_text,base64_key,base64_iv)
function decrypt($code,$base64_key,$base64_iv)
{        
	$blob_key=base64_decode($base64_key);
	$blob_iv=base64_decode($base64_iv);

	$td = mcrypt_module_open(MCRYPT_RIJNDAEL_128, '', MCRYPT_MODE_CBC, '');
	mcrypt_generic_init($td, $blob_key, $blob_iv);
	$str = mdecrypt_generic($td, $code);
	$block = mcrypt_get_block_size(MCRYPT_RIJNDAEL_128, MCRYPT_MODE_CBC);
	mcrypt_generic_deinit($td);
	mcrypt_module_close($td);        
	return strippadding($str);
}

/*
 For PKCS7 padding
 */

function addpadding($string, $blocksize = 16) {
	$len = strlen($string);
	$pad = $blocksize - ($len % $blocksize);
	$string .= str_repeat(chr($pad), $pad);
	return $string;
}

function strippadding($string) {
	$slast = ord(substr($string, -1));
	$slastc = chr($slast);
	$pcheck = substr($string, -$slast);
	if (preg_match("/$slastc{" . $slast . "}/", $string)) {
		$string = substr($string, 0, strlen($string) - $slast);
		return $string;
	} else {
		return false;
	}
}

function hexToStr($hex)
{
	$string='';
	for ($i=0; $i < strlen($hex)-1; $i+=2)
	{
		$string .= chr(hexdec($hex[$i].$hex[$i+1]));
	}
	return $string;
}

/******************************************************************************

 The following functions were copied / modified from:

   https://github.com/dstelljes/php-snapchat

 Here's the MIT license from the php-snapchat project:

Copyright (c) 2013 Daniel Stelljes

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

 ******************************************************************************/

  /**
   * Pads data using PKCS5.
   *
   * @param $data The data to be padded.
   * @param $blocksize The block size to pad to. Defaults to 16.
   * @return The padded data.
   */
  function padLegacy($data, $blocksize = 16) {
    $pad = $blocksize - (strlen($data) % $blocksize);
    return $data . str_repeat(chr($pad), $pad);
  }


  /**
   * Decrypts blob data.
   *
   * @param $data The data to decrypt.
   * @return The decrypted data.
   */
  function decryptLegacy($data) {
    $BLOB_ENCRYPTION_KEY = 'M02cnQ51Ji97vwT4'; // Blob encryption key
    return mcrypt_decrypt(MCRYPT_RIJNDAEL_128, $BLOB_ENCRYPTION_KEY, padLegacy($data), MCRYPT_MODE_ECB);
  }
?>
