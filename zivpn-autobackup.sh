#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='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'
    local obfuscated_key='YmYxNzY3ODAzN2I1MjZlMWM0NmVkYTc0ODAyMDM0YzZmOTg2MTUxZmZiMDcxMTc1MzdiMjc4NzAzOTAzMmFhOQ=='

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
