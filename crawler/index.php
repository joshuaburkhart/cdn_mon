<?php
/*
Tracks all domains within the given page. 
Outputs: URI, domain name and page count
*/
if(isset($_POST['Submit'])){
include_once('simple_html_dom.php');
$target_url = $_POST['link'];
$html = new simple_html_dom();
$html->load_file($target_url);
$myFile = "testFile.txt";
$count = 0;
$pagecount = 0;
$fh = fopen($myFile, 'w') or die("can't open file");
//if user wants to view the URIs on the web
if($_POST['show'] == yes) {
	foreach($html->find('a') as $post) {
		if(isset($post->href)) {
			echo "Href: ".$post->href."....."."Name: ".$post->plaintext."........"."Page count: ".$pagecount++."\n";
			$data = "Href: ".$post->href."....."."Name: ".$post->plaintext."........"."Page count: ".$pagecount++."\n";
			fwrite($fh, $data);
			$count++;
		}
	}
} else { // else just write them to txt file
    $link = array();
	foreach($html->find('a') as $post) {
	   $data = "Href: ".$post->href."....."."Name: ".$post->plaintext."........"."Page count: ".$pagecount++."\n";
	   fwrite($fh, $data);
	   $link[] = $post->href;
	   $count++;
	}
}
fclose($fh);
echo "Crawled through ".$target_url ." and found ". $count. " links <br />";
echo "Text file saved to ".$myFile . "<br />";
}
?>

<html>
<body>
	<form method="post" action="<?php echo $_SERVER['PHP_SELF']; ?>">
		<input name="link" type="text" id="link" size="150">
		<input type="checkbox" name="show" value="yes">Show all Reference IDs<br>
		<input type="submit" name="Submit" value="Submit">
</form>
</body
</html>