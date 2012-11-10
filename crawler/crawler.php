<?php
/*
Tracks all domains within the given URI and outputs to a text file all URIs and how
 many children is located underneath it
 Output: URI,URI, URI........
*/
/* To ignore 404 error messages from file_get_content and unset index notices from $domains. */
error_reporting( E_ERROR );
 
define( "CRAWL_LIMIT_PER_DOMAIN", 50 );
if(isset($_POST['Submit'])) {
	$link = $_POST['link'];
	// Used to store the number of pages crawled per domain.
	$domains = array();
	// List of all our crawled URLs.
	$urls = array();
	$myFile = "testFile.txt";
	$fh = fopen($myFile, 'w') or die("can't open file");
	function crawl( $url ) {
  		global $domains, $urls, $fh;
 
  		//echo "Crawling $url... ";
 		$u = "$url, ";
 		fwrite($fh, $u);
  		$parse = parse_url( $url );
 
  		/// This is where we add to the count of crawled URLs and to our list of crawled URLs.
 	    $domains[ $parse['host'] ]++;
  		$urls[] = $url;
 
  		$content = file_get_contents( $url );
  		if ( $content === FALSE ) {
    		echo "Error.\n";
    		return;
  		}	
 
  		$content = stristr( $content, "body" );
  		preg_match_all( '/http:\/\/[^ "\']+/', $content, $matches );
  
  		//$q = 'Found ' . count( $matches[0] ) . " urls."."\n";
  		//fwrite($fh, $q);
  		foreach( $matches[0] as $crawled_url ) {
    		$parse = parse_url( $crawled_url );
 
   			 /* Check that we haven't hit our limit for crawled pages per domain
     		* and that we haven't crawled that specific URL yet. */
    		if ( count( $domains[ $parse['host'] ] ) < CRAWL_LIMIT_PER_DOMAIN
        	&& !in_array( $crawled_url, $urls ) ) {
      			sleep( 1 );
      			crawl( $crawled_url );
    		}
  		}
}
crawl($link);
fclose($fh);
}
?>
<html>
<body>
	<form method="post" action="<?php echo $_SERVER['PHP_SELF']; ?>">
		<input name="link" type="text" id="link" size="150">
		<input type="submit" name="Submit" value="Submit">
</form>
</body
</html>