import json
import sys
import urllib.request
import urllib.error
from google.oauth2 import service_account
from google.auth.transport.requests import Request

def deploy_rules():
    print("=== Deploying Firestore Security Rules to Firebase ===")
    service_account_path = "serviceAccountKey.json"
    rules_path = "firestore.rules"

    with open(service_account_path, "r", encoding="utf-8") as f:
        sa_data = json.load(f)
    
    project_id = sa_data.get("project_id", "rlds-89374")
    print(f"Target Firebase Project: {project_id}")

    with open(rules_path, "r", encoding="utf-8") as f:
        rules_content = f.read()

    scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
        "https://www.googleapis.com/auth/firebase"
    ]
    credentials = service_account.Credentials.from_service_account_file(
        service_account_path, scopes=scopes
    )
    credentials.refresh(Request())
    token = credentials.token

    # 1. Create Ruleset
    create_ruleset_url = f"https://firebaserules.googleapis.com/v1/projects/{project_id}/rulesets"
    payload = {
        "source": {
            "files": [
                {
                    "name": "firestore.rules",
                    "content": rules_content
                }
            ]
        }
    }
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    print("Step 1: Creating ruleset on Firebase Rules API...")
    req = urllib.request.Request(
        create_ruleset_url,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST"
    )

    try:
        with urllib.request.urlopen(req) as response:
            ruleset_data = json.loads(response.read().decode("utf-8"))
            ruleset_name = ruleset_data.get("name")
            print(f"Ruleset created successfully: {ruleset_name}")
    except urllib.error.HTTPError as e:
        print(f"ERROR creating ruleset: {e.code} - {e.read().decode('utf-8')}")
        sys.exit(1)

    # 2. Update/Release Ruleset to cloud.firestore
    release_url = f"https://firebaserules.googleapis.com/v1/projects/{project_id}/releases/cloud.firestore?updateMask=rulesetName"
    release_payload = {
        "release": {
            "name": f"projects/{project_id}/releases/cloud.firestore",
            "rulesetName": ruleset_name
        }
    }

    print("Step 2: Releasing ruleset to production cloud.firestore...")
    req_release = urllib.request.Request(
        release_url,
        data=json.dumps(release_payload).encode("utf-8"),
        headers=headers,
        method="PATCH"
    )

    try:
        with urllib.request.urlopen(req_release) as response:
            res_data = json.loads(response.read().decode("utf-8"))
            print(f"Release updated successfully: {json.dumps(res_data, indent=2)}")
            print("\n>>> FIRESTORE RULES DEPLOYED SUCCESSFULLY TO FIREBASE! <<<")
    except urllib.error.HTTPError as e:
        print(f"ERROR releasing ruleset: {e.code} - {e.read().decode('utf-8')}")
        sys.exit(1)

if __name__ == "__main__":
    deploy_rules()
