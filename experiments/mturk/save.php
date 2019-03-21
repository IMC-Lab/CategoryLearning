<?php

# Structure on the server (bradylab.ucsd.edu):
#
#  This file:
#    bradylab.ucsd.edu/turk/save.php
#  Data gets saved in:
#    bradylab.ucsd.edu/turk/data/{experimenter}/{experimentName}
#  Each subject gets saved using their id:
#	 harvardvisionlab.com/turk/data/{experimenter}/{experimentName}/{id}.txt
#
# Warning:
# Note that this means that anybody can load this file directly and
# create files on your server. E.g., if somebody goes to the URL
# bradylab.ucsd.edu/turk/save.py?id=hello&experimentName=tim&curData=you+da+bomb,
# that will create a file on the server in the directory "data". So it isn't the
# safest thing in the world.

# How to make this file work:
# Make sure php is enabled on your server. That's it.
# You might have to make your "data" folder writeable to the world:
# in terminal:
# sudo chmod -R 777 data

	// standard setup
	ob_start();
	error_reporting(E_ALL);
	ini_set('display_errors', '1');

	// allow anyone to run this script from local host!
	// perhaps comment this out after testing your setup?
	// header('Access-Control-Allow-Origin: http://localhost:8888');
	header('Access-Control-Allow-Origin: *');

	// get posted data
	$data=$_POST;
	$id = $_POST['id'];
	$experimenter = $_POST['experimenter'];
	$experimentName = $_POST['experimentName'];
	$directory = $_POST['directory'];
	$curData = $_POST['curData'];

	// setup directories
	$dataDir= $directory . "/" . $experimenter . "/" . $experimentName . "/";
	$dataDir= str_replace("///", "/", str_replace("//", "/", $dataDir)); // if experimenter isn't provided, get rid of extra "/"
	if (!file_exists($dataDir)) {
		// 0755 (directory, permissions mode, recursive = true for creating full path))
		if (!mkdir($dataDir, 0777, true)) {	// 0644, 0750, 0755
			print_r($_SERVER);
		    die("Failed to create directory!\n$dataDir");
		}
	} else {
		print_r("Writing to $dataDir\n");
	}

	// check whether data file exists, if so, make unique name using uniqueid, which
	// gets a prefixed unique identifier based on the current time in microseconds.
	$fileName=$dataDir . "$id.txt";
	while (file_exists($fileName)) $fileName = $dataDir . "$id" . "_" . uniqid() . ".txt";

	// save file
	if (file_put_contents($fileName,$curData)) {
		chmod($fileName, 0777);
		ob_end_clean();	ob_start();
		//print_r($_POST); echo "\n";
		print_r("Success saving data!\n");
		print_r("fileName: $fileName \n");
	} else {
		print_r("Error...could not save data!\n");
		print_r("fileName: $fileName \n");
	}

	exit();

	function recurse_copy($src,$dst) {
		$dir = opendir($src);
		@mkdir($dst);
		while(false !== ( $file = readdir($dir)) ) {
			if (( $file != '.' ) && ( $file != '..' )) {
				if ( is_dir($src . '/' . $file) ) {
					recurse_copy($src . '/' . $file,$dst . '/' . $file);
				}
				else {
					copy($src . '/' . $file,$dst . '/' . $file);
				}
			}
		}
		closedir($dir);
	}
?>
