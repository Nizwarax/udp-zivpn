#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='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'
    local obfuscated_key='MjczNjZiYzY2MTk1MzQxODAwZTkwMjNlNmE2N2YyM2ZjNGFkOWYzNzZlZDdmNzhiNWQ4NGYyNDRlMzY4NDJkZA=='

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
