import * as d3 from 'https://cdn.jsdelivr.net/npm/d3@7/+esm';
// import 'coordtransform';

let map;
let geourl = 'wuchang.geojson';
let all_communities_url = 'wc_communities_imputed.csv';

async function initMap() {
  //@ts-ignore
  const { Map } = await google.maps.importLibrary('maps');
  const infoWindow = new google.maps.InfoWindow();

  function addMarkersToMap(latitudes, longitudes, names, area, units, price) {
    // Loop through the arrays and add a marker for each location
    for (let i = 0; i < latitudes.length; i++) {
      const price_marker = document.createElement('div');
      price_marker.classList.add('price-marker');
      price_marker.textContent = (price[i] / 1000).toFixed(1) + 'K';

      const marker = new google.maps.marker.AdvancedMarkerView({
        map: map,
        position: { lat: latitudes[i], lng: longitudes[i] },
        content: price_marker,
      });

      // Add an event listener to the marker to show the info window when clicked
      marker.addEventListener('click', () => {
        infoWindow.setContent(
          names[i] +
            ', area: ' +
            area[i] +
            ', units: ' +
            units[i] +
            ', price: ' +
            price[i]
        );
        infoWindow.open(map, marker);
      });
    }
  }

  // Add all community markers to map
  fetch('wc_imputed.csv')
    .then((response) => response.text())
    .then((data) => {
      const parsed_csv = d3.csvParse(data);
      console.log(parsed_csv);

      const latitudes = parsed_csv.map((d) => Number(d.latitude_gps));
      const longitudes = parsed_csv.map((d) => Number(d.longitude_gps));
      const names = parsed_csv.map((d) => d.community);
      const area = parsed_csv.map((d) => d.avg_area);
      const units = parsed_csv.map((d) => d.total_units);
      const price = parsed_csv.map((d) => d.unit_price);

      addMarkersToMap(latitudes, longitudes, names, area, units, price);
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
