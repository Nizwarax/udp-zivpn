#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='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'
    local obfuscated_key='M2M5YWE1MTAxZTdlOGM5MTI4NzQ5MmM5MWFmMzMyZmFhYjY4NzNlYTU2MDE5MWIzNTczMjUyYmUwY2I4NGJhZg=='

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
