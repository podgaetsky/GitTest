#!/bin/bash

# Log file path
log_file="$1.log"

# Function to log messages
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$log_file"
}

# Check if the correct number of arguments are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <directory_name> <user_id> [<user_id> ...]"
    exit 1
fi

# Check if curl and jq are installed
if ! command -v curl &> /dev/null || ! command -v jq &> /dev/null; then
    echo "Error: curl or jq is not installed. Please install them and try again."
    log_message "Error: curl or jq is not installed."
    exit 1
fi

# Extract the directory name and user IDs from command line arguments
directory_name=$1
shift
user_ids=("$@")

# Create the directory to save the photos
mkdir -p "$directory_name"

# Iterate over user IDs and download their photos
for id in "${user_ids[@]}"; do
    # Get user data from the API
    user_data=$(curl -s "https://reqres.in/api/users/$id")

    # Check if user data is empty (user does not exist)
    if [ "$(echo "$user_data" | jq -r '.data')" == "null" ]; then
        echo "Error: User with ID $id does not exist."
        log_message "Error: User with ID $id does not exist."
        continue
    fi

    # Extract user information using jq
    first_name=$(echo "$user_data" | jq -r '.data.first_name')
    last_name=$(echo "$user_data" | jq -r '.data.last_name')
    photo_url=$(echo "$user_data" | jq -r '.data.avatar')

    # Download the photo and save it in the directory
    start_time=$(date +%s.%N)
    curl -s -o "${directory_name}/${id}_${first_name}_${last_name}.jpg" "$photo_url"
    end_time=$(date +%s.%N)
    elapsed_time=$(echo "($end_time - $start_time) * 1000" | bc -l | awk '{printf "%.3f", $1}')

    # Log the action
    log_message "User: $first_name $last_name (ID: $id)"
    log_message "Current Git Branch: $(git branch --show-current)"
    log_message "Elapsed Time: ${elapsed_time} ms"
    log_message "Action Description: Photo downloaded and saved"
done

echo "Photos downloaded successfully!"
