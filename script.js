import * as d3 from 'https://cdn.jsdelivr.net/npm/d3@7/+esm';

// Part 1: Build the map
let map;
const buildMarkerDetails = (community) => {
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
    center: { lat: 30.539, lng: 114.3 },
    zoom: 18,
    minZoom: 16,
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

// Part 2: Build Calculator
const uniformRates = document.querySelector('#uniform-rates');
const tercilesRates = document.querySelector('#terciles-rates');
const quartilesRates = document.querySelector('#quartiles-rates');
const quintilesRates = document.querySelector('#quintiles-rates');

document.querySelectorAll('input[name="tierOption"]').forEach((radio) => {
  radio.addEventListener('click', () => {
    // Hide all the slider elements
    uniformRates.setAttribute('hidden', '');
    tercilesRates.setAttribute('hidden', '');
    quartilesRates.setAttribute('hidden', '');
    quintilesRates.setAttribute('hidden', '');

    // Show the corresponding
    if (radio.value === 'uniform') {
      uniformRates.removeAttribute('hidden');
    } else if (radio.value === 'terciles') {
      tercilesRates.removeAttribute('hidden');
    } else if (radio.value === 'quartiles') {
      quartilesRates.removeAttribute('hidden');
    } else if (radio.value === 'quintiles') {
      quintilesRates.removeAttribute('hidden');
    }
  });
});

// Get the tax rate sliders
const uniformSlider = document.querySelector('.uniform-slider');
const tercilesSliders = document.querySelectorAll('.terciles-slider');
const quartilesSliders = document.querySelectorAll('.quartiles-slider');
const quintilesSliders = document.querySelectorAll('.quintiles-slider');

// Set the sum of tax base according to data
const sum = 1340179198060;
const AreaTercileSum = [266386428105, 376902435808, 696890334147];
const AreaQuartileSum = [
  185065947100, 264452707885, 303405932606, 587254610469,
];
const AreaQuintileSum = [
  144947979664, 190181906219, 227557419835, 257108209441, 520383682901,
];

const PriceTercileSum = [269349493710, 355901582170, 714928122180];
const PriceQuartileSum = [
  194136282111, 231545166789, 317144247317, 597353501843,
];
const PriceQuintileSum = [
  153693024196, 178286477531, 204750008495, 297058330768, 506391357070,
];

function updateTaxRevenue() {
  // Get the selected tax rate based on the selected radio button
  let taxRate;
  let taxBase;
  const selectedTier = document.querySelector(
    'input[name="tierOption"]:checked'
  );
  const selectedGroup = document.querySelector('input[name="groupBy"]:checked');

  if (selectedTier.value === 'uniform') {
    taxRate = uniformSlider.value / 100;
    taxBase = sum;
  } else if (selectedTier.value === 'terciles') {
    taxRate = Array.from(tercilesSliders).map((slider) => slider.value / 100);
    taxBase = selectedGroup.value === 'area' ? AreaTercileSum : PriceTercileSum;
  } else if (selectedTier.value === 'quartiles') {
    taxRate = Array.from(quartilesSliders).map((slider) => slider.value / 100);
    taxBase =
      selectedGroup.value === 'area' ? AreaQuartileSum : PriceQuartileSum;
  } else if (selectedTier.value === 'quintiles') {
    taxRate = Array.from(quintilesSliders).map((slider) => slider.value / 100);
    taxBase =
      selectedGroup.value === 'area' ? AreaQuintileSum : PriceQuintileSum;
  }

  // Calculate the total tax revenue by taking the dot product of taxRate and taxBase
  const totalRevenue =
    selectedTier.value == 'uniform'
      ? taxRate * taxBase
      : taxRate.reduce((acc, rate, index) => acc + rate * taxBase[index], 0);

  const perperson = totalRevenue / 1092750;

  // Update the tax revenue element
  document.querySelector('#tax-revenue').textContent =
    totalRevenue.toLocaleString('en-US');
  document.querySelector('#tax-substitution').textContent =
    Math.round((totalRevenue / 15100000000) * 10000) / 100;
  document.querySelector('#tax-perperson').textContent = (
    Math.round(perperson * 10) / 10
  ).toLocaleString('en-US');
  document.querySelector('#tax-incomeshare').textContent =
    Math.round((perperson / 67180) * 10000) / 100;
}

// Update tax revenue whenever radio buttons are changed
document.querySelectorAll('input[name="groupBy"]').forEach((radio) => {
  radio.addEventListener('click', () => {
    updateTaxRevenue();
  });
});
document.querySelectorAll('input[name="tierOption"]').forEach((radio) => {
  radio.addEventListener('click', () => {
    updateTaxRevenue();
  });
});

// Update tax revenue when sliders are changed
uniformSlider.addEventListener('input', updateTaxRevenue);
tercilesSliders.forEach((slider) =>
  slider.addEventListener('input', updateTaxRevenue)
);
quartilesSliders.forEach((slider) =>
  slider.addEventListener('input', updateTaxRevenue)
);
quintilesSliders.forEach((slider) =>
  slider.addEventListener('input', updateTaxRevenue)
);

// Part 3: Build Controls
const dataComponent = document.querySelector('#data');
const calculatorComponent = document.querySelector('#calculator');
const aboutComponent = document.querySelector('#about');
document.querySelector('#calculator-button').addEventListener('click', () => {
  // toggle the visibility of the calculator section depending on if it is hidden or not
  if (calculatorComponent.hasAttribute('hidden')) {
    calculatorComponent.removeAttribute('hidden');
  } else {
    calculatorComponent.setAttribute('hidden', '');
  }
});

document.querySelector('#about-button').addEventListener('click', () => {
  // toggle the visibility of the about section depending on if it is hidden or not
  if (aboutComponent.hasAttribute('hidden')) {
    aboutComponent.removeAttribute('hidden');
  } else {
    aboutComponent.setAttribute('hidden', '');
  }
});
