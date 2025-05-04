import os
import base64
import time
import zipfile
import google.auth
from google.cloud import storage
from googleapiclient import discovery

SERVICE_ACCOUNT_ID = "a5-access"
KEY_FILENAME = f"{SERVICE_ACCOUNT_ID}.json"


base_dir = os.path.dirname(__file__)
start_dir = os.path.abspath(os.path.join(base_dir, "../../start"))
generated_dir = os.path.join(base_dir, "generated")
bucket_file = os.path.join(generated_dir, "bucket_name.txt")
bucket_dir = os.path.join(base_dir, "bucket")
function_dir = os.path.join(base_dir, "function")
function_zip_path = os.path.join(base_dir, "function.zip")

def upload_secret(bucket_name: str):
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob("secret.txt")
    blob.upload_from_string("ThunderCTF{privilege_escalation_via_cloud_functions}\n")
    print(f"[UPLOAD] secret.txt -> gs://{bucket_name}/secret.txt")

def generate_service_account_key(service_account_id: str) -> str:
    credentials, project_id = google.auth.default()
    service_account_email = f"{service_account_id}@{project_id}.iam.gserviceaccount.com"
    iam_api = discovery.build('iam', 'v1', credentials=credentials)

    key = iam_api.projects().serviceAccounts().keys().create(
        name=f'projects/{project_id}/serviceAccounts/{service_account_email}',
        body={}
    ).execute()

    return key["privateKeyData"]

def write_start_file(message: str, key_data: str):
    os.makedirs(start_dir, exist_ok=True)

    with open(os.path.join(start_dir, "a5power.txt"), "w") as f:
        f.write(message)
    os.chmod(os.path.join(start_dir, "a5power.txt"), 0o400)

    with open(os.path.join(start_dir, KEY_FILENAME), "w") as f:
        f.write(base64.b64decode(key_data).decode("utf-8"))
    os.chmod(os.path.join(start_dir, KEY_FILENAME), 0o400)

def create_function_zip():
    os.makedirs(function_dir, exist_ok=True)

    main_code = """
def main(request):
    return "Hello World!\\n"
""".strip()

    with open(os.path.join(function_dir, "main.py"), "w") as f:
        f.write(main_code)

    with open(os.path.join(function_dir, "requirements.txt"), "w") as f:
        f.write("")  # No deps

    with zipfile.ZipFile(function_zip_path, "w") as zipf:
        zipf.write(os.path.join(function_dir, "main.py"), arcname="main.py")
        zipf.write(os.path.join(function_dir, "requirements.txt"), arcname="requirements.txt")

    print(f"[INFO] Created Cloud Function zip at {function_zip_path}")

def main():
    with open(bucket_file) as f:
        bucket_name = f.read().strip()

    print(f"[INFO] Uploading dummy files to {bucket_name}")
    upload_secret(bucket_name)

    print(f"[INFO] Creating function.zip")
    create_function_zip()

    print(f"[INFO] Generating service account key for {SERVICE_ACCOUNT_ID}")
    key_data = generate_service_account_key(SERVICE_ACCOUNT_ID)

    instructions = (
        "Use the compromised service account credentials given to you to find the secret, "
        "which is located in a file called secret.txt in a private bucket on the project."
    )

    print("[INFO] Writing start files")
    write_start_file(instructions, key_data)
    print("[DONE] a5power provision complete.")

if __name__ == "__main__":
    main()
