#!/bin/bash

# GitHub Gist ID
GIST_ID="e6160d25739b1436fc5c47a48ce91d78"

# GitHub Personal Access Token file path
GITHUB_TOKEN_FILE="$HOME/.bm_github_token"

BREWFILE_PATH="$HOME/Brewfile"

###### Main ######

# Check for curl
if ! command -v curl >/dev/null; then
    echo "Error: curl is not installed. Please install curl and try again." >&2
    exit 1
fi

# Check and Install Homebrew
if ! command -v brew >/dev/null; then
    echo "Homebrew is not installed. Installing..."

    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
      echo "Homebrew installed successfully!"
    else
      echo "Failed to download or install Homebrew. Please check your internet connection or try again later." >&2
      exit 1
    fi
fi

if ! command -v jq >/dev/null; then
    echo "jq is not installed. Installing..."

    if brew install jq; then
      echo "jq installed successfully"
    else
      echo "Failed to download or install jq. Please check your internet connection or try again later." >&2
      exit 1
    fi
fi

# Check for existing GitHub personal access token
if [[ -z "$GITHUB_TOKEN" ]]; then
  # Check for a stored token in the file
  if [[ -f "$GITHUB_TOKEN_FILE" ]]; then
    GITHUB_TOKEN=$(cat "$GITHUB_TOKEN_FILE")
  fi
fi

# Prompt for token if it's not set or invalid
while [[ -z "$GITHUB_TOKEN" ]]; do
  read -r -s -p "Enter your GitHub personal access token: " GITHUB_TOKEN
  echo
done

# Create or update Brewfile
echo "Dumping Brewfile..."
if brew bundle dump --force --file="$BREWFILE_PATH"; then
  echo "Brewfile successfully dumped at $BREWFILE_PATH!"
else
  echo "Error: Failed to dump Brewfile."
  exit 1
fi

# Upload Brewfile to GitHub Gist (update if exists, create otherwise)
echo "Uploading Brewfile to the gist..."
BREWFILE_CONTENT=$(< "$BREWFILE_PATH")
BREWFILE_CONTENT_ESCAPED=$(printf "%s" "$BREWFILE_CONTENT" | jq -Rsa .)
status_code=$(curl -L \
  -X PATCH \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/gists/$GIST_ID \
  -o /dev/null \
  -w "%{http_code}" \
  -d "{\"files\":{\"Brewfile\":{\"content\":$BREWFILE_CONTENT_ESCAPED}}}"
)

# Save the token to a file and secure it
if [ $status_code -eq 401 ]; then
  echo "Error: Invalid token (Make sure the gist permission is granted)"
  echo "" > "$GITHUB_TOKEN_FILE"
else
  echo "$GITHUB_TOKEN" > "$GITHUB_TOKEN_FILE"
  chmod 600 "$GITHUB_TOKEN_FILE"  # Ensure only the user can access the file
fi

# Print status result
if [ $status_code -eq 200 ]; then
  echo "Brewfile uploaded successfully to the Gist!"
elif [ $status_code -eq 404 ]; then
  echo "Error: Gist not found!"
elif [ $status_code -eq 422 ]; then
  echo "Error: Validation failed, or the endpoint has been spammed."
else
  echo "Error: Something went wrong. HTTP status code: $status_code"
fi
