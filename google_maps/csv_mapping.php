<?php
/*
This PHP file has a user input a CSV file and takes the geo locations for both the user
and the CDN locations.
Outputs: A Google map that output markers (red) for CDN locations and (blue) for 
user location
*/
if(isset($_POST['Submit'])) {
	$link = $_FILES['file']['name'];
	$file = new SplFileObject($link); 
	$file->setFlags(SplFileObject::READ_CSV); 
	$file->setCsvControl(","); 
	$count = 0;
	$temp = 0;
	$lat = array();
	$long = array();
	$allUri = array();
	foreach ($file as $row) { 
    	list($name, $ip, $mac,$homeGeo,$URI,$newIP,$unav,$geolocation,$date,
         	$none,$zero,$otherIp,$other,$Uri) = $row; 
    	$temp = $count - 1;
    	$temploc = preg_replace("/[~]/", ",", $geolocation);
    	$temphome = preg_replace("/[~]/", ",", $homeGeo);
    	if(($count == 0) or ($latlong[$temp] != $temploc)){
        	//echo $latlong[$temp] .$temploc;
        	$allUri[$count] = "Hello";
        	
        	$home = preg_replace("/[~]/", ",", $homeGeo);
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
var uriArray = new Array();
var latHome = 0;
var longHome = 0;
var count = 0;
<?php
/*
    foreach($allUri as $key => $value) {
    	echo "uriArray[$key] = $value;\n";
    } */
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
    	title: "URI: ",
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
<div id="googleMap" style="width:500px;height:380px;"></div>

</body>
</html>