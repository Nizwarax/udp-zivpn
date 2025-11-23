#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='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'
    local obfuscated_key='ODQwMWRjMDFmNGExY2FiMzM3ZDJhYmFkOTllMWNjOWU0YmJiYTRiYzUwNzUzYzYzNTg4ZGNlZDk4MGM1ZmFmYg=='

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
