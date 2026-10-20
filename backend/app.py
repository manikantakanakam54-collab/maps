import os
from flask import Flask, request, jsonify
from dotenv import load_dotenv
from googlemaps import Client as GoogleMapsClient

# Load environment variables from .env (if present)
load_dotenv()

app = Flask(__name__)

# Retrieve the API key from environment – it will NOT be committed to source control
GMAPS_API_KEY = os.getenv('GMAPS_API_KEY')
if not GMAPS_API_KEY:
    raise RuntimeError('GMAPS_API_KEY not set in environment')

gmaps = GoogleMapsClient(GMAPS_API_KEY)

@app.route('/directions', methods=['GET'])
def get_directions():
    """Return walking directions between origin and destination.
    Query parameters:
      - origin: "lat,lng" (optional, defaults to current location on client side)
      - destination: "lat,lng" (required)
    """
    dest = request.args.get('destination')
    if not dest:
        return jsonify({'error': 'destination parameter required'}), 400
    origin = request.args.get('origin')
    try:
        directions_result = gmaps.directions(
            origin=origin,
            destination=dest,
            mode='walking',
            alternatives=False,
        )
        return jsonify(directions_result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # For development use only – production should be run with a WSGI server
    app.run(host='0.0.0.0', port=5000, debug=True)
