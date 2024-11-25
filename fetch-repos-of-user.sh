#!/bin/bash

# Variables
GITHUB_TOKEN="your_personal_access_token"  # Replace with your GitHub PAT
ORG_NAME="your_organization_name"         # Replace with your organization name
USERNAME="target_username"                # Replace with the target user's GitHub username
OUTPUT_FILE="user_repos_info.csv"

# GitHub API Base URL
API_URL="https://api.github.com"

# Initialize the CSV file
echo "Repository Name,Last Updated,Admin Name" > $OUTPUT_FILE

# Function to fetch all pages of a GitHub API endpoint
fetch_all_pages() {
    local url=$1
    local result=""
    while [[ $url ]]; do
        response=$(curl -s -I -H "Authorization: token $GITHUB_TOKEN" "$url")
        next_url=$(echo "$response" | grep -oP '(?<=<).+?(?=>; rel="next")')
        content=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$url")
        result+="$content"
        url=$next_url
    done
    echo "$result"
}

# Get all repositories the user has access to
repos=$(fetch_all_pages "$API_URL/users/$USERNAME/repos?per_page=100" | jq -r --arg ORG "$ORG_NAME" '.[] | select(.owner.login == $ORG) | .name')

# Loop through each repository
for repo in $repos; do
    echo "Processing repository: $repo"

    # Get the last updated time
    last_updated=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$API_URL/repos/$ORG_NAME/$repo" | jq -r '.updated_at')

    # Get the admin name
    admin=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$API_URL/repos/$ORG_NAME/$repo/collaborators?per_page=100" | \
            jq -r '.[] | select(.permissions.admin == true) | .login' | paste -sd "," -)

    # Append to CSV file
    echo "$repo,\"$last_updated\",\"$admin\"" >> $OUTPUT_FILE
done

echo "Data exported to $OUTPUT_FILE"
