import pandas as pd
import requests

# Define a function to get the coordinates for a single address
def get_coordinates(address):
    # Replace YOUR_API_KEY with your actual Google Maps API key
    url = f'https://maps.googleapis.com/maps/api/geocode/json?address={address}&key=AIzaSyBecqIQaiyZ0iYd6vyXt9GSaI83TLv0JsQ'
    response = requests.get(url).json()

    # Check if the geocoding was successful
    if response['status'] == 'OK':
        # Get the first result and extract the latitude and longitude
        result = response['results'][0]
        latitude = result['geometry']['location']['lat']
        longitude = result['geometry']['location']['lng']
        return latitude, longitude
    else:
        return None

# Read the CSV file into a pandas DataFrame
df1 = pd.read_csv('wc_newhouse.csv')
df2 = pd.read_csv('wc_secondhand.csv')

# Add columns for latitude and longitude coordinates
df1['latitude'] = None
df1['longitude'] = None

# Loop through the rows and get the coordinates for each address
for index, row in df1.iterrows():
    address = row['address']
    coordinates = get_coordinates(address)
    if coordinates:
        df1.at[index, 'latitude'] = coordinates[0]
        df1.at[index, 'longitude'] = coordinates[1]

# Write the updated DataFrame back to the CSV file
df1.to_csv('addresses_with_coordinates.csv', index=False)


# Add columns for latitude and longitude coordinates
df2['latitude'] = None
df2['longitude'] = None

# Loop through the rows and get the coordinates for each address
for index, row in df2.iterrows():
    address = row['address']
    coordinates = get_coordinates(address)
    if coordinates:
        df2.at[index, 'latitude'] = coordinates[0]
        df2.at[index, 'longitude'] = coordinates[1]

# Write the updated DataFrame back to the CSV file
df2.to_csv('addresses_with_coordinates.csv', index=False)