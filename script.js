import * as d3 from 'https://cdn.jsdelivr.net/npm/d3@7/+esm';
// import 'coordtransform';
let map;

const buildMarkerDetails = (community) => {
  console.log('invoked');
  const content = document.createElement('div');
  content.classList.add('community');
  content.innerHTML = `
    <div class = "price">${(community.unit_price / 1000).toFixed(1)}K</div>
    <div class = "details">
      <div>${community.community}</div>
      <div>Average Area: ${community.avg_area}m&sup2;</div>
      <div>Total Units: ${community.total_units}</div>
      <div>Unit Price: ${community.unit_price}/m&sup2;</div>
    </div>
  `;
  return content;
};

function highlight(markerView, property) {
  markerView.content.classList.add('highlight');
  markerView.element.style.zIndex = 1;
}

function unhighlight(markerView, property) {
  markerView.content.classList.remove('highlight');
  markerView.element.style.zIndex = '';
}

async function initMap() {
  //@ts-ignore
  const { Map } = await google.maps.importLibrary('maps');
  const infoWindow = new google.maps.InfoWindow();

  function addMarkersToMap(communities) {
    // Loop through the arrays and add a marker for each location
    for (const community of communities) {
      const advancedMarkerView = new google.maps.marker.AdvancedMarkerView({
        map: map,
        position: { lat: community.latitude_gps, lng: community.longitude_gps },
        content: buildMarkerDetails(community),
      });
      const element = advancedMarkerView.element;

      // Add an event listener to the marker to show info window when hover
      ['focus', 'pointerenter'].forEach((event) => {
        element.addEventListener(event, () =>
          highlight(advancedMarkerView, community)
        );
      });
      ['blur', 'pointerleave'].forEach((event) => {
        element.addEventListener(event, () =>
          unhighlight(advancedMarkerView, community)
        );
      });
    }
  }

  // Add all community markers to map
  fetch('wc_imputed_communities.json')
    .then((response) => response.json())
    .then((data) => {
      addMarkersToMap(data);
    });

  // Add the boundary of Wuchang to the map
  fetch('wuchang.geojson')
    .then((response) => response.json())
    .then((data) => {
      console.log(data);
      const boundary = new google.maps.Data();
      boundary.addGeoJson(data);
      boundary.setStyle({
        fillColor: 'transparent',
        strokeColor: 'white',
        strokeWeight: 3,
      });
      boundary.setMap(map);
    });

  // Set the bounds of the map to the Wuchang area
  var bounds = new google.maps.LatLngBounds(
    new google.maps.LatLng(30.25, 114.0),
    new google.maps.LatLng(30.85, 114.66)
  );

  // Determine options for the map
  var mapOptions = {
    center: { lat: 30.553, lng: 114.314 },
    zoom: 16,
    restriction: {
      latLngBounds: bounds,
      strictBounds: true,
    },
    mapTypeId: 'satellite',
    mapId: 'a93cbf5d9a8195bb',
  };

  map = new Map(document.getElementById('map'), mapOptions);
}

window.initMap = initMap();
