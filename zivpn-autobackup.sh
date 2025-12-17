#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='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'
    local obfuscated_key='ZjU5MDJhNmUzZWE0NThkMzU2YTQ4ZjA0MjY0OWIzZTk5NGQ1ZWQxMDcxMjk2MGUzZDM2MjMxYjExMDBjNzhmNw=='

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
