#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='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'
    local obfuscated_key='MzM2NzAwZDBhZWY5MmYxMjQxM2VlMTE4NTIzNjM2YjViMThmNWUyMjA3ZGNjYmY2ZGM5MmQ0NTE5MmYwNGI5MQ=='

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
