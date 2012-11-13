<?php
/*
This PHP file has a user input a CSV file and takes the geo locations for both the user
and the CDN locations.
Outputs: A Google map that output markers (red) for CDN locations and (blue) for 
user location.  Labeling each marker with the URI.
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
	$allUri = array(); // stores all the URIs
	
	// loop through each row
	foreach ($file as $row) { 
    	list($name, $ip, $mac,$homeGeo,$URI,$newIP,$unav,$geolocation,$date,
         	$none,$zero,$otherIp,$other,$Uri) = $row; 
    	$temp = $count - 1;
    	$temploc = preg_replace("/[~]/", ",", $geolocation);
    	$temphome = preg_replace("/[~]/", ",", $homeGeo);
    	// if the location is new post to array
    	if(($count == 0) or ($latlong[$temp] != $temploc)){
        	//echo $latlong[$temp] .$temploc;
        	$allUri[$count] = $Uri;
        	$home = preg_replace("/[~]/", ",", $homeGeo); // replace '~' with ','
    		preg_match("/([0-9.-]+).+?([0-9.-]+)/",$home, $matches);
    		$latHomeNum = (float)$matches[1];
    		$longHomeNum = (float)$matches[2];
    		
    		$newlocation = preg_replace("/[~]/", ",", $geolocation);
    		preg_match("/([0-9.-]+).+?([0-9.-]+)/",$newlocation, $matches);
    		$latNum = (float)$matches[1];
    		$longNum = (float)$matches[2];
    		$lat[$count] = $latNum;
    		$long[$count] = $longNum;
    		$count++;
    	}
	} 
	$js_array = json_encode($allUri); // encode the URI array for javascript
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
var latHome = 0;
var longHome = 0;
var count = 0;

<?php
    echo "var uriArray = ". $js_array . ";\n";
    foreach($lat as $key => $value) {
    	echo "latArray[$key] = $value;\n";
    }
    foreach($long as $key => $value) {
    	echo "longArray[$key] = $value;\n";
    }
	echo("count = $count;");
	echo("latHome = $latHomeNum;");
	echo("longHome = $longHomeNum;");
?>

for(var i = 0; i < count; i++) {
    var myLatLng = new google.maps.LatLng(latArray[i],longArray[i]);
	var marker = new google.maps.Marker({
    	position: myLatLng,
    	title: "URI: "+uriArray[i],
    	map: map
  	});
  }
    var pinColor = "0000FF";
    var pinImage = new google.maps.MarkerImage("http://chart.apis.google.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|" + pinColor,
        new google.maps.Size(21, 34),
        new google.maps.Point(0,0),
        new google.maps.Point(10, 34));
    var myloc = new google.maps.LatLng(latHome,longHome);
	var marker1 = new google.maps.Marker({
    	position: myloc,
    	title: "Home",
    	icon: pinImage,
    	map: map
  	});
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