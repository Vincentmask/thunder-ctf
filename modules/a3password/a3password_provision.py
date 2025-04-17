from pathlib import Path
import os
import random
import json
import zipfile

# Paths
base_dir = os.path.dirname(__file__)
function_dir = os.path.join(base_dir, "function")
generated_dir = os.path.join(base_dir, "generated")
os.makedirs(function_dir, exist_ok=True)
os.makedirs(generated_dir, exist_ok=True)

# Generate XOR values
xor_password = random.randint(100000000000, 999999999999)
xor_factor = random.randint(100000000000, 999999999999)
correct_password = xor_password ^ xor_factor

# cloud function code
# The function will be deployed to Google Cloud Functions
main_py_code = f"""
def main(request):
    XOR_FACTOR = {xor_factor}
    import os
    xor_password = int(os.environ.get("XOR_PASSWORD"))
    password = request.args.get("password")

    if not password:
        return "Missing password\\n", 400
    try:
        if int(password) ^ XOR_FACTOR == xor_password:
            return "Correct!\\n"
        else:
            return "Incorrect password\\n", 403
    except:
        return "Invalid password\\n", 400
"""

main_py_path = os.path.join(function_dir, "main.py")
with open(main_py_path, "w") as f:
    f.write(main_py_code.strip())

# Zip the function
zip_path = os.path.join(base_dir, "function.zip")
with zipfile.ZipFile(zip_path, "w") as zipf:
    zipf.write(main_py_path, arcname="main.py")

# Save values for Terraform to consume
Path(os.path.join(generated_dir, "xor_password.txt")).write_text(str(xor_password))
Path(os.path.join(generated_dir, "correct_password.txt")).write_text(str(correct_password))
Path(os.path.join(generated_dir, "xor_factor.txt")).write_text(str(xor_factor))

