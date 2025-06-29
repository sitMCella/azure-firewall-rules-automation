import logging
import os
import re
import requests
import base64
import time
import azure.functions as func

GITHUB_API = "https://api.github.com"
BRANCH_NAME = "update-branch"
TARGET_FILE = "main.tf"
COMMIT_MESSAGE = "Update main.tf with new Azure IP Addresses."
PR_TITLE = "Update Azure Firewall Policy rules"
BASE_BRANCH = "main"

app = func.FunctionApp()

def get_github_headers(token):
    return {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28"
    }

def update_block(text, target_name, replacements):
    logging.info(f"Search pattern: name = \"{target_name}")
    blocks = re.split(r'(?=^.*name\s*=)', text, flags=re.MULTILINE)
    updated_blocks = []
    for block in blocks:
        if not block:
            continue
        logging.info(f"Block: {block}")
        first_line = block.splitlines()[0].strip()
        logging.info(f"First Line: {first_line}")
        if first_line.startswith(f"name = \"{target_name}"):
            for key, value in replacements.items():
                block = re.sub(fr'^.*{key}\s*=.*$', f'{key} = {value}', block, flags=re.MULTILINE)
                logging.info(f"Replaced block: {block}")
        updated_blocks.append(block)
    return ''.join(updated_blocks)

@app.timer_trigger(schedule="0 0 5 * * 1", arg_name="myTimer", run_on_startup=False, use_monitor=False) 
def timer_trigger1(myTimer: func.TimerRequest) -> None:
    try:
        if myTimer.past_due:
            logging.info('The timer is past due!')

        REPO_OWNER = os.environ.get("GITHUB_REPOSITORY_OWNER")
        REPO_NAME = os.environ.get("GITHUB_REPOSITORY_NAME")
        PAT_TOKEN = os.environ.get("GITHUB_PAT")

        # Azure IP Ranges and Service Tags – Public Cloud
        # URL: https://www.microsoft.com/en-us/download/details.aspx?id=56519
        # Alternative approach: https://learn.microsoft.com/en-us/rest/api/virtualnetwork/service-tags/list?view=rest-virtualnetwork-2024-05-01&tabs=HTTP
        url = "https://download.microsoft.com/download/7/1/d/71d86715-5596-4529-9b13-da13a5de5b63/ServiceTags_Public_20250616.json"
        logging.info(f"Get URL: {url}")
        response = requests.get(url)
        response.raise_for_status()
        if response.status_code == 404:
            logging.info(f"Document not found")
        data = response.json()

        # Search for the IP Address Ranges of a specific value name
        name = "AzureMachineLearning.WestEurope"
        match = next((item for item in data["values"] if item.get("name") == name), None)

        if match:
            logging.info(f"Found: {match}")
            address_prefixes = match["properties"]["addressPrefixes"]
            logging.info(f"IP addressess: {address_prefixes}")

            headers = get_github_headers(PAT_TOKEN)

            ref_url = f"{GITHUB_API}/repos/{REPO_OWNER}/{REPO_NAME}/git/ref/heads/{BASE_BRANCH}"
            logging.info(f"Get URL {ref_url}")
            ref_resp = requests.get(ref_url, headers=headers)
            ref_resp.raise_for_status()
            logging.info(f"Response on get URL: {ref_resp.json()}")
            base_sha = ref_resp.json()["object"]["sha"]
            logging.info(f"Response base sha: {base_sha}")

            # Create new branch
            new_ref_url = f"{GITHUB_API}/repos/{REPO_OWNER}/{REPO_NAME}/git/refs"
            logging.info(f"Create branch {new_ref_url}")
            requests.post(new_ref_url, headers=headers, json={
                "ref": f"refs/heads/{BRANCH_NAME}",
                "sha": base_sha
            })
            logging.info(f"branch creation request sent")
            new_branch_url = f"{GITHUB_API}/repos/{REPO_OWNER}/{REPO_NAME}/git/refs/heads/{BRANCH_NAME}"
            max_retries = 10
            delay = 1 # seconds
            for attempt in range(max_retries):
                response = requests.get(new_branch_url, headers=headers)
                if response.status_code == 200:
                    logging.info(f"branch exists")
                    break
                elif response.status_code == 404:
                    logging.info(f"wait branch creation...")
                    time.sleep(delay)
                else:
                    logging.info(f"unexpected error: {response.status_code} - {response.text}")
                    break
            logging.info(f"branch avaiable")

            # Get existing file
            # https://docs.github.com/en/rest/repos/contents?apiVersion=2022-11-28#get-repository-content
            file_url = f"{GITHUB_API}/repos/{REPO_OWNER}/{REPO_NAME}/contents/{TARGET_FILE}"
            logging.info(f"Get file {file_url}")
            file_resp = requests.get(file_url, headers=headers)
            file_resp.raise_for_status()
            file_data = file_resp.json()
            logging.info(f"Get file data: {file_data}")
            file_sha = file_data["sha"]
            logging.info(f"File sha: {file_sha}")
            content = base64.b64decode(file_data["content"]).decode('utf-8')
            logging.info(f"File content: {content}")

            # Modify the file content
            address_prefixes = ",".join(f"\"{address_prefix}\"" for address_prefix in address_prefixes)
            replacements = {
                "destination_addresses": f"[{address_prefixes}]"
            }
            updated_content = update_block(content, "azuremachinelearning-", replacements)
            #updated_content = re.sub(r'destination_addresses\s*=\s*.*', f"destination_addresses = [{address_prefixes}]", content)
            logging.info(f"Updated file content: {updated_content}")
            updated_content = base64.b64encode(updated_content.encode()).decode()
            logging.info(f"Updated file content encoded: {updated_content}")

            # Update the file
            # https://docs.github.com/en/rest/repos/contents?apiVersion=2022-11-28#create-or-update-file-contents
            file_url = f"{file_url}?ref={BRANCH_NAME}"
            put_resp = requests.put(file_url, headers=headers, json={
                "message": COMMIT_MESSAGE,
                "content": updated_content,
                "sha": file_sha,
                "branch": BRANCH_NAME
            })
            put_resp.raise_for_status()
            logging.info(f"Updated the file in the branch {put_resp.json()}")

            # Create a Pull Request
            # https://docs.github.com/en/rest/pulls/pulls?apiVersion=2022-11-28#create-a-pull-request
            pr_url = f"{GITHUB_API}/repos/{REPO_OWNER}/{REPO_NAME}/pulls"
            logging.info(f"Create Pull Request {pr_url}")
            pr_resp = requests.post(pr_url, headers=headers, json={
                "title": PR_TITLE,
                "head": BRANCH_NAME,
                "base": BASE_BRANCH,
                "body": "Automated Pull Request from Azure Functions"
            })
            pr_resp.raise_for_status()
            pr_link = pr_resp.json()["html_url"]
            logging.info(f"Pull Request: {pr_link}")
        else:
            logging.info(f"No object found")

        logging.info('Python timer trigger function executed.')
    except Exception as e:
        logging.error(f"Error: {e}")