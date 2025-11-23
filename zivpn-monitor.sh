#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='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'
    local obfuscated_key='NDAxMDM1NmE5ZDYxNjg2ZDYwYzA3MTRhOGI2ZDZjMWIyMGVmZjBhZWQ5MDY1MzFkYWZjZTI1ODgzMjZjNDhhNQ=='

    local decoded_key=$(echo "$obfuscated_key" | base64 -d)
    if [ -z "$decoded_key" ]; then
        echo "Error: Failed to decode key." >&2
        return 1
    fi

    local decrypted_content=$(echo "$encrypted_content" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$decoded_key" 2>/dev/null)
    if [ -z "$decrypted_content" ]; then
        echo "Error: Decryption failed." >&2
        return 1
    fi

    # Bersihkan jejak sebelum eksekusi
    unset encrypted_content obfuscated_key decoded_key

    eval "$decrypted_content"
}

__run_protected
