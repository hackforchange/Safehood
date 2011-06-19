// Mapping logic

var testData = [
  {
    'id': '8374987349873',
    'message': 'This is a test message',
    'lat': 37.77918,
    'lon': -122.390953,
    'location': 'Townsend and 2nd, San Francisco, CA',
    'hashed_phone': '#3493oijf34ij4non4rij43900',
    'hashed_ip': '#ndj98fehreef9fjsdf09',
    'timestamp': new Date()
  },
  {
    'id': '3874598374598743',
    'message': 'This is a test message 02',
    'lat': 37.77918,
    'lon': -122.390953,
    'location': 'Townsend and 2nd, San Francisco, CA',
    'hashed_phone': '#3493oijf34ij4non4rij43900',
    'hashed_ip': '#ndj98fehreef9fjsdf09',
    'timestamp': new Date()
  },
  {
    'id': '2772727272772',
    'message': 'This is a test message 03',
    'lat': 37.77918,
    'lon': -122.390953,
    'location': 'Townsend and 2nd, San Francisco, CA',
    'hashed_phone': '#3493oijf34ij4non4rij43900',
    'hashed_ip': '#ndj98fehreef9fjsdf09',
    'timestamp': new Date()
  }
];

if (typeof L != 'undefined' && typeof jQuery != 'undefined') {
  jQuery.noConflict();
  var cloudmadeUrl = 'http://{s}.tile.cloudmade.com/90480db8a5a4470d87c3c21800806e02/997/256/{z}/{x}/{y}.png';
  var cloudmadeAttrib = 'Map data &copy; 2011 OSM, Imagery &copy; 2011 CloudMade';
  
  (function($) {
    $(document).ready(function() {
      // Signup location map
      var $LocationInput = $('.location-input');
      if ($LocationInput.length) {
        var $LocationLabel = $('.location-label');
        
        // Start map
        $LocationInput.after('<div id="location-map"></div>');
        var map = new L.Map('location-map');
        var cloudmade = new L.TileLayer(cloudmadeUrl, {maxZoom: 18, attribution: cloudmadeAttrib});
        var center = new L.LatLng(38, -97);
        map.setView(center, 3).addLayer(cloudmade);
        
        // Add geolocating link
        if (typeof Modernizr != 'undefined' && Modernizr.geolocation) {
          $LocationLabel.after('<a class="geolocate-me" href="#geolocate">Find me</a>');
          $('.geolocate-me').click(function() {
            navigator.geolocation.getCurrentPosition(function(position) {
              var found = new L.LatLng(position.coords.latitude, position.coords.longitude);
              var marker = new L.Marker(found, { 'draggable': true });
              map.addLayer(marker);
              map.setView(found, 14);
              
              $('input[name="location-lat"]').val(position.coords.latitude);
              $('input[name="location-lon"]').val(position.coords.longitude);
              localGeocode({ 'lat': position.coords.latitude, 'lng': position.coords.longitude}, 
                function(result) {
                  $LocationInput.val(result);
                },
                function(s) { }
              );
                
              // Handle moving of the marker
              marker.on('dragend', function(e) {
                var position = e.target.getLatLng();
                localGeocode(position, function(result) {
                  $LocationInput.val(result);
                },
                function(s) { });
              });
            }, function(error) {
              alert('Could not find you, trying typing in an address or intersection.');
            }, {enableHighAccuracy: true});
            
            return false;
          });
        }
      }
    
      // Message explorer map
      if ($('#map-messages').length) {
        var map = new L.Map('map-messages');
        var cloudmade = new L.TileLayer(cloudmadeUrl, {maxZoom: 18, attribution: cloudmadeAttrib});
        var center = new L.LatLng(37.77917, -122.390903);
        map.setView(center, 14).addLayer(cloudmade);
        
        markers = [];
        for (var i in testData) {
          testData[i].lat = (Math.random() > .5) ? testData[i].lat + (Math.random() * .005) :
            testData[i].lat - (Math.random() * .005);
          testData[i].lon = (Math.random() > .5) ? testData[i].lon + (Math.random() * .005) :
            testData[i].lon - (Math.random() * .005);
          
          markers[i] = new L.Marker(new L.LatLng(testData[i].lat, testData[i].lon));
          map.addLayer(markers[i]);
          markers[i].bindPopup(testData[i].message);
        }
      }
      
      // Geocoding function
      var localGeocode = function(location, success, error) {
        var geocoder = new google.maps.Geocoder();
        
        // Check what format we have
        if (typeof location == 'String') {
          // Geocode address
          geocoder.geocode( { 'address': location}, function(results, status) {
            if (status == google.maps.GeocoderStatus.OK) {
              success(results);
            } else {
              error(status);
            }
          });
        }
        else {
          // Reverse geocode
          var latlng = new google.maps.LatLng(location.lat, location.lng);
          geocoder.geocode({'latLng': latlng}, function(results, status) {
            if (status == google.maps.GeocoderStatus.OK && results[0]) {
              success(results[0].formatted_address);
            } else {
              error(status);
            }
          });
        }
      }
    });
  })(jQuery);
}