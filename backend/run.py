import sys
import os

# Add backend directory to sys.path
backend_dir = os.path.dirname(os.path.abspath(__file__))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from app import create_app

app = create_app()

if __name__ == '__main__':
    print("=" * 70)
    print("  The Church of Jesus Christ Restoration Ministry (RLDS Church)")
    print("  Offline-First Backend API & Stewardship Kitty Portal")
    print("  Faith, Consecration & Divine Stewardship")
    print("  Running locally on: http://127.0.0.1:5000")
    print("=" * 70)
    app.run(host='0.0.0.0', port=5000, debug=True)
