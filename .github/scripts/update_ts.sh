#!/bin/bash

# Function to print an error message and exit
error_exit() {
    echo "Error: $1" 1>&2
    exit 1
}

# Check for the required Aztec version parameter
if [ $# -ne 1 ]; then
    error_exit "Usage: $0 aztec-packages-vX.Y.Z"
fi

aztec_version_parameter="$1"
aztec_version=${aztec_version_parameter#*v}

# Check if tmp directory exists
if [ ! -d "tmp" ]; then
    error_exit "tmp directory not found. Did update_aztec_contracts.sh run successfully?"
fi

# Directory containing the aztec-packages TypeScript files
source_ts_dir="tmp/yarn-project/end-to-end/src"

# Base directories
target_dirs=("./tutorials" "./workshops")

echo "----------"
echo "Step 1: Attempting to update e2e_sandbox_example.test.ts"
# Update e2e_sandbox_example.test.ts file
source_e2e_file=$(find "$source_ts_dir" -name "e2e_sandbox_example.test.ts")
target_e2e_file="./tutorials/sandbox-tutorial/src/e2e_sandbox_example.test.ts"

if [ -f "$source_e2e_file" ]; then
    echo "Updating $target_e2e_file..."
    cp "$source_e2e_file" "$target_e2e_file"
    echo "Updated $target_e2e_file"
else
    echo "Source file $source_e2e_file not found."
fi

echo "----------"
echo "Step 2: Attempting to update all @aztec packages in all package.jsons"
# Update all @aztec packages in package.json files in the project
find . -name "package.json" | while read -r package_file; do
    if ! sed -i "s/\(@aztec\/[a-zA-Z0-9_-]*\": \"\)[^\"]*/\1^$aztec_version/g" "$package_file" > /dev/null 2>&1; then
        echo "Error updating $package_file"
    fi
done

echo "----------"
echo "Step 3: Attempting to update token bridge e2e"
# Token Bridge e2e
# Grab delay function from aztec-packages
source_delay_function_file="$source_ts_dir/fixtures/utils.ts"
target_delay_function_file="./tutorials/token-bridge-e2e/packages/src/test/fixtures/utils.ts"

# Copying delay function
echo "Copying delay function from $source_delay_function_file to $target_delay_function_file..."
cp "$source_delay_function_file" "$target_delay_function_file"

# Copy cross_chain_test_harness.ts
source_cross_chain_file="$source_ts_dir/shared/cross_chain_test_harness.ts"
target_cross_chain_file="./tutorials/token-bridge-e2e/packages/src/test/shared/cross_chain_test_harness.ts"

echo "Copying cross_chain_test_harness from $source_cross_chain_file to $target_cross_chain_file..."
cp "$source_cross_chain_file" "$target_cross_chain_file"
echo "Token bridge e2e processed."

source_messaging_test_file="$source_ts_dir/e2e_cross_chain_messaging.test.ts"
target_messaging_test_file="./tutorials/token-bridge-e2e/packages/src/test/e2e_cross_chain_messaging.test.ts"

if [ -f "$source_messaging_test_file" ]; then
    echo "Updating test cases in $target_messaging_test_file..."
    # Write test cases to a temporary file
    sed -n '/it(.*/,/});/p' "$source_messaging_test_file" > temp_test_cases.txt

    # Use 'r' command in sed to read from a file and append after the line containing "afterAll("
    if ! sed -i "/afterAll(.*/r temp_test_cases.txt" "$target_messaging_test_file"; then
        echo "Error updating test cases in $target_messaging_test_file"
    else
        echo "Updated test cases in $target_messaging_test_file"
    fi

    # Cleanup temporary file
    rm -f temp_test_cases.txt
else
    echo "Source file $source_messaging_test_file not found."
fi

echo "----------"
echo "Complete"
