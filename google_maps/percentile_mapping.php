<?php
/*
This PHP file has a user input a CSV file and takes the geo locations for both the user
and the CDN locations.
Outputs: A Google map that output markers (red) for CDN locations.
*/
//Check if the user submitted a file
if(isset($_POST['Submit'])) {
    //upload the file
	$link = $_FILES['file']['name'];
	$file = new SplFileObject($link); 
	$file->setFlags(SplFileObject::READ_CSV); 
	$file->setCsvControl(","); 
    
	$count = 0;	// number of rows
	$temp = 0; // temp number of rows
	$lat = array(); // stores the latitudes 
	$long = array(); // stores the longitudes
	
	// loop through each row
	foreach ($file as $row) { 
    	list($geolocation) = $row; 
 
    	$temp = $count - 1;
    	$temploc = preg_replace("/[~]/", ",", $geolocation);
    
    	// if the location is new post to array
    	if(($count == 0) or ($latlong[$temp] != $temploc)){
    		$newlocation = preg_replace("/[~]/", ",", $geolocation);
    		preg_match("/([0-9.-]+).+?([0-9.-]+)/",$newlocation, $matches);
    		$latNum = (float)$matches[1];
    		$longNum = (float)$matches[2];
    		$lat[$count] = $latNum;
    		$long[$count] = $longNum;
    		$count++;
    	}
	} 
}
?>
<!DOCTYPE html>
<html>
<head>
<script
src="http://maps.googleapis.com/maps/api/js?key=AIzaSyAsISy0DeNV89CA7AJCj0Cq4ei5ObY_nho&sensor=false">
</script>

<script>
function initialize() {
var mapProp = {
  center:new google.maps.LatLng(43.7004,-122.8964),
  zoom:5,
  mapTypeId:google.maps.MapTypeId.ROADMAP
};
var map=new google.maps.Map(document.getElementById("googleMap"),mapProp);

var latArray = new Array();
var longArray = new Array();
var count = 0;

<?php
    foreach($lat as $key => $value) {
    	echo "latArray[$key] = $value;\n";
    }
    foreach($long as $key => $value) {
    	echo "longArray[$key] = $value;\n";
    }
	echo("count = $count;");
?>

for(var i = 0; i < count; i++) {
    var myLatLng = new google.maps.LatLng(latArray[i],longArray[i]);
	var marker = new google.maps.Marker({
    	position: myLatLng,
    	map: map
  	});
  }
}
google.maps.event.addDomListener(window, 'load', initialize);
</script>
</head>

<body>
<form method="post" action="<?php echo $_SERVER['PHP_SELF']; ?>" enctype="multipart/form-data">
		<label for="file">Filename:</label>
		<input type="file" name="file" id="file" /> 
		<input type="submit" name="Submit" value="Submit">
</form>
<div id="googleMap" style="width:800px;height:600px;"></div>

</body>
</html>