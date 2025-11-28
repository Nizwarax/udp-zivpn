#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='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'
    local obfuscated_key='OWM2Y2Y2MWNmOThlYzZmNDA5MzU3MTNhNjIyMjMwNmJjMzA2YWQ4NmZkNmFjMDQ0NTVhM2UwOTczMGRiMDVkMw=='

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
