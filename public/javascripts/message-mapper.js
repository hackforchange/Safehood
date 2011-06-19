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
        var london = new L.LatLng(51.505, -0.09);
        map.setView(london, 13).addLayer(cloudmade);
      }
    });
  })(jQuery);
}