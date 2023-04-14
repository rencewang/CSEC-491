let map;

async function initMap() {
  //@ts-ignore
  const { Map } = await google.maps.importLibrary('maps');

  // Set the bounds of the map to the New York City area
  var bounds = new google.maps.LatLngBounds(
    new google.maps.LatLng(30.25, 114.0),
    new google.maps.LatLng(30.85, 114.66)
  );

  map = new Map(document.getElementById('map'), {
    center: { lat: 30.553, lng: 114.314 },
    zoom: 13,
    restriction: {
      latLngBounds: bounds,
      strictBounds: true,
    },
  });
}

initMap();
