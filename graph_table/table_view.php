<?php
//error_reporting(E_ALL);
/*
This PHP file allows a user to upload a CSV file.  Once the file is uploaded the 
function getCountry, takes each IP address in the CSBV file and finds the country
originating form that IP address.

Output: A table with the countries and number of times each country appears in the CSV file
*/

// holds all the IP addresses
$country = array();

//Check if the user submitted a file
if(isset($_POST['Submit'])) {
    //upload the file
	$link = $_FILES['file']['name'];
	$file = new SplFileObject($link); 
	$file->setFlags(SplFileObject::READ_CSV); 
	$file->setCsvControl(","); 
	$geo = array();
	$prevIP = "99.99.99.99";
	
	// loop through each row finding each IP address
	foreach ($file as $row) { 
    	list($name, $ip, $mac,$homeGeo,$URI,$newIP,$unav,$geolocation,$date,$none,$zero,$otherIp,$other,$Uri) = $row; 
    	    $temp = $newIP;
    	    // If it is nto a new Ip address do not keep
    	    if(($temp != $prevIP) && ($temp != null)) {
        		$country[] = $newIP;
        		$prevIP = $newIP;
        	}
	}
	// call getCountry
	getCountry($country);
}

function getCountry($ipAddr) {
	$ipDetail = array(); //initialize a blank array
	$detail = 0;

	foreach($ipAddr as $ip) {
		//verify the IP address for the
		if(ip2long($ip)== -1 || ip2long($ip) === false) { 
	    
		//trigger_error("Invalid IP", E_USER_ERROR); 
		}
		else {
			//get the XML result from hostip.info
			$xml = file_get_contents("http://api.hostip.info/?ip=".$ip);
			//get the country name inside the node <countryName> and </countryName>
			preg_match("@<countryName>(.*?)</countryName>@si",$xml,$matches);
			//assign the country name to the $ipDetail array
			if($matches[1] == "(Unknown Country?)") {
				$matches[1] = "No Country";
		}
		$ipDetail[] = $matches[1];
		$detail += 1;
	}
}

// count values in Array
$newArray = array_count_values($ipDetail);

// output table of countries and number of countries found
echo '<table style="border:1px solid black; border-collapse:collapse;">';
echo '<tr><th style="border:1px solid black;">Country</th>
          <th style="border:1px solid black;">Count</th></tr>';
foreach($newArray as $key => $value) {
	echo '<tr'. (($LineNum++ & 1) ?' bgcolor="#EEEEEE"' : '').' >
	<td style="border:1px solid black;">' 
	. $key .'</td> <td style="border:1px solid black;">' . $value . '</td></tr>';
}
echo "</table>";

}
?>
<!DOCTYPE html>
<html>
<head>

</head>

<body>
<form method="post" action="<?php echo $_SERVER['PHP_SELF']; ?>" enctype="multipart/form-data">
		<label for="file">Filename:</label>
		<input type="file" name="file" id="file" /> 
		<input type="submit" name="Submit" value="Submit">
</form>

</body>
</html>
