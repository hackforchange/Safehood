// Mapping logic

if (typeof L != 'undefined' && typeof jQuery != 'undefined') {
  jQuery.noConflict();
  
  (function($) {
    $(document).ready(function() {
      if ($('#map-messages').length) {
        var map = new L.Map('map-messages');
        var cloudmadeUrl = 'http://{s}.tile.cloudmade.com/90480db8a5a4470d87c3c21800806e02/997/256/{z}/{x}/{y}.png';
        var cloudmadeAttrib = 'Map data &copy; 2011 OpenStreetMap contributors, Imagery &copy; 2011 CloudMade';
        var cloudmade = new L.TileLayer(cloudmadeUrl, {maxZoom: 18, attribution: cloudmadeAttrib});
        var london = new L.LatLng(37.77917, -122.390903);
        map.setView(london, 14).addLayer(cloudmade);
        
        var markerLocation = new L.LatLng(37.77918, -122.390953);
        var marker = new L.Marker(markerLocation);
        map.addLayer(marker);
        var circleLocation = new L.LatLng(37.77915, -122.395003),
            circleOptions = {
                color: 'red', 
                fillColor: '#f03', 
                fillOpacity: 0.5
            };
            
        var circle = new L.Circle(circleLocation, 100, circleOptions);
        map.addLayer(circle);
        marker.bindPopup("<b>Hello world!</b><br />I am a popup.");
        circle.bindPopup("I am a circle.");
      }
    });
  })(jQuery);
}