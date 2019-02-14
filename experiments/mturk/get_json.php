<?php
// allow anyone to run this script
header('Access-Control-Allow-Origin: *');

$fileName = $_POST["filename"];
$fh = fopen($fileName, 'r') or die("can't open file");


fpassthru($fh);
fclose($fh);
?>
