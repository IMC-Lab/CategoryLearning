<?php
$myFile = $_POST["filename"];
$fh = fopen($myFile, 'w+') or die("can't open file");
$stringData = $_POST["data"];
fwrite($fh, $stringData);
fclose($fh)
?>
