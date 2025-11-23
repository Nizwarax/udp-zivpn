#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='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'
    local obfuscated_key='MzA5MzJkNjhlZGYyYTU3MGU5YmQ3N2MxMWNhM2Y5ZDU4Y2Y1ODYwYzAwMWM2NTRiYjgxOGRlMjJkOTBkNDI3ZQ=='

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
