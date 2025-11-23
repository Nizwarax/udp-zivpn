#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='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'
    local obfuscated_key='NTlmNjNiYTlhYTU5MDc0YjYzOWE1ZjhkZjgzNmNkNTYxNzQwMTcwOGEzZTg5MDQ3ZmE5ZDMzNjM1NmRkNTI3YQ=='

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
