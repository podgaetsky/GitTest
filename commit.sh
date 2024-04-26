#!/bin/bash

# Function to find column index by header name
find_column_index() {
    local header=$1
    local file=$2
    awk -F, -v header="$header" 'NR==1 { for(i=1;i<=NF;i++) { if($i == header) { print i; exit } } }' "$file"
}

# Check if the correct number of arguments are passed
if [ "$#" -gt 1 ]; then
    echo "Usage: $0 [DevDescription]"
    exit 1
fi

# Set the CSV file path
csv_file="./input.csv"

# Set the sample text file path
sample_text_file="./sample.txt"

# Check if the CSV file exists
if [ ! -f "$csv_file" ]; then
    echo "CSV file not found: $csv_file"
    exit 1
fi

# Check if the CSV file is empty
if [ ! -s "$csv_file" ]; then
    echo "CSV file is empty: $csv_file"
    exit 1
fi

# Find the index of the 'branch' column
branch_column=$(find_column_index "branch" "$csv_file")

# Check if 'branch' column exists
if [ -z "$branch_column" ]; then
    echo "Column 'branch' not found in the CSV file."
    exit 1
fi

# Read the CSV file and process each line
tail -n +2 "$csv_file" | while IFS=, read -r bug_id description branch dev_name bug_priority github_url; do
    # Get the value of the 'branch' column
    branch_name=$(echo "$branch" | tr -d '\r')

    # Prompt for developer description if provided as argument
    if [ "$#" -eq 1 ]; then
        echo "Enter developer description for Bug ID $bug_id:"
        read -r dev_description
    else
        dev_description=""
    fi

    # Perform staging commit and push for the branch
    echo "Staging commit and push for branch: $branch_name"
    commit_message="$bug_id:$(date +%Y-%m-%d_%H-%M-%S):$branch_name:$dev_name:$bug_priority:$description $dev_description"

    # Create a sample text file with the commit message
    echo "$commit_message" > "$sample_text_file"

    git add "$sample_text_file"
    git commit -m "$commit_message"
    git push origin "$branch_name"

    # Check if the push was successful
    if [ $? -eq 0 ]; then
        echo "Push to branch $branch_name completed successfully."
    else
        echo "Error: Push to branch $branch_name failed."
    fi

    # Remove the sample text file after the commit
    rm "$sample_text_file"
done
