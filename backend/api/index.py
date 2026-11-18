import sys
import os

# Ensure the backend directory is in the Python system path
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)

from app import create_app

# Vercel looks for the WSGI application instance named `app`
app = create_app()

# Allows running directly with `python api/index.py`
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
