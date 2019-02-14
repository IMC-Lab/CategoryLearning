<?php
 header("Access-Control-Allow-Origin: *");
$fileName = $_POST["filename"];
$fh = fopen($fileName, 'w+') or die("can't open file");
$stringData = $_POST["data"];
fwrite($fh, $stringData);
fclose($fh);
chmod($fileName, 0666);
?>
