#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='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'
    local obfuscated_key='MjE3YzE4NDFjODEzYWQ5Y2YzNzBmNDI5N2JmZTEyMDhmMDc0MGM4NWZmODdlZWVmOWE5MzQ3MTg0YjBlOWM4ZQ=='

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
