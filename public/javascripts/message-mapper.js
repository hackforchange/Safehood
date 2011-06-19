// Mapping logic
if (typeof L != 'undefined' && typeof jQuery != 'undefined') {
  jQuery.noConflict();
  var cloudmadeUrl = 'http://{s}.tile.cloudmade.com/90480db8a5a4470d87c3c21800806e02/997/256/{z}/{x}/{y}.png';
  var cloudmadeAttrib = 'Map data &copy; 2011 OSM, Imagery &copy; 2011 CloudMade';
  
  (function($) {
    $(document).ready(function() {
      // Signup location map
      var $LocationInput = $('#user_location');
      if ($LocationInput.length) {
        var marker;
        var $LocationLabel = $('.location-label');
        var $LocationHelp = $('.location-help');
        
        // Start input map.  Update help since we have mapping capabilities.
        $LocationHelp.html('Type in an address or cross street, then click <strong>Locate address</strong> we\'ll try to find that.  Move around the marker to make your location for more accurate.  <strong>We will never publish your address.</strong>');
        $LocationHelp.after('<div id="location-map"></div>');
        var map = new L.Map('location-map');
        var cloudmade = new L.TileLayer(cloudmadeUrl, {maxZoom: 18, attribution: cloudmadeAttrib});
        var center = new L.LatLng(38, -97);
        map.setView(center, 3).addLayer(cloudmade);
        
        // Add input geolocating
        $LocationInput.after('<a class="geolocate-address" href="#geolocate-address">Locate address</a>');
        $('a.geolocate-address').click(function() {
          var location = $LocationInput.val();
          localGeocode($LocationInput.val(), function(result) {
              result = result[0];
              $LocationInput.val(result.formatted_address);
              $('input#user_lat').val(result.geometry.location.lat());
              $('input#user_lon').val(result.geometry.location.lng());
              if (marker) {
                map.removeLayer(marker);
              }
              var found = new L.LatLng(result.geometry.location.lat(), result.geometry.location.lng());
              marker = new L.Marker(found, { 'draggable': true });
              map.addLayer(marker);
              map.setView(found, 14);
                
              // Handle moving of the marker
              marker.on('dragend', function(e) {
                var position = e.target.getLatLng();
                localGeocode(position, function(result) {
                  $LocationInput.val(result);
                },
                function(s) { });
              });
            },
            function(s) {
              alert('We could not find that address, please try again.');
            }
          );
        });
        
        // Add browser geolocating link
        if (typeof Modernizr != 'undefined' && Modernizr.geolocation) {
          $LocationHelp.html('Use the <strong>Auto find Me</strong> and we\'ll try to automatically find you.  Or type in an address or cross street, then click <strong>Locate address</strong> and we\'ll try to find that.  Move around the marker to make your location more accurate.  <strong>We will never publish your address.</strong>');
          $LocationLabel.after('<a class="geolocate-me" href="#geolocate">Auto find me</a>');
          $('.geolocate-me').click(function() {
            navigator.geolocation.getCurrentPosition(function(position) {
              if (marker) {
                map.removeLayer(marker);
              }
              var found = new L.LatLng(position.coords.latitude, position.coords.longitude);
              marker = new L.Marker(found, { 'draggable': true });
              map.addLayer(marker);
              map.setView(found, 14);
              
              $('input#user_lat').val(position.coords.latitude);
              $('input#user_lon').val(position.coords.longitude);
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
        $.getJSON("/messages/", function(data) {
          var map = new L.Map('map-messages');
          var cloudmade = new L.TileLayer(cloudmadeUrl, {maxZoom: 18, attribution: cloudmadeAttrib});
          var center = new L.LatLng(37.77917, -122.390903);
          map.setView(center, 14).addLayer(cloudmade);
          
          markers = [];
          for (var i in data) {
            msg = data[i].message;
            if (msg) {
              markers[i] = new L.Marker(new L.LatLng(msg.lat, msg.lon));
              map.addLayer(markers[i]);
              markers[i].bindPopup(msg.message);
            }
          }
        });
      }
      
      // Geocoding function
      var localGeocode = function(location, success, error) {
        var geocoder = new google.maps.Geocoder();
        
        // Check what format we have
        if (typeof location.lat == 'undefined') {
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