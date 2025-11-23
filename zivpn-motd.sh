#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='U2FsdGVkX1+4WvqzTEaZyIPUQhTQvMuL+MRPBBqnMFNgNLyEtQehNR5NvMWRSp0872Vq5nVpv1Dlr5afF4uiMotEYyeu7ymZ+aa7KIu5WDT9A0E7LHRkeCWqNj0ghEdPFqH9affo5CBpYD5dAR0szc7KBpoV5hluTKDPCG6S+yq5q3n9YQHJ+LZ5lPWzAxNfaGBjC8+Vl8Vx2B1iJqev1f0OXprnwmeSKt40VBkip5xStF/AhFwG7CLHnqJGm13BPLc0s7jIH/JBm5rj1VixLc5mKyHqkSn+0CLQtZ22enw8LmA6DB8OBY94vjtZoqf98Yxf+D+NZRiCUJkvDoGjj5F0s1+YxE1SbdYCps5/R6BfXiWiXeDLFiTT0VqVPiJNkCJfSLnZLNnjmmoevp8g2go9zYJzCXIMdaPMWj3JXRixVch5KGQBLkic+6OWM5FCb3pqUDipWqtqBFsUZ/F8FphslWKheH3MYexwiWXkxYJcM6vdhCDGtFRAYLqMK2fcyCYwMYZ1DSJvBC83vzAVuJsA+pnB43+/GqaZ1uzeUlKefmCkOrDM5H6taehRbBo4hwkktJ7NqzUkFr6qiZDT6qOrKbHXx82lXtHnf6ZGF1K/TO+p8JmJlUEy+QHioG/RPi71vGaLDkipirV6L3zpTbEgFHENVXcqEfJxvOWCBcKBtwFq4PkI9t0EQvHV4fbPm7ZFRkeBZyvv2DU4zSdoDyhwcLkg2o1d7GcneWHQ4k7OBfsNxGscSltSmM4xtnXKB+2LJsoEfo8rakVe59xFzsd+r09PvfdiXhrxxRlE0l5UfZDD8nZuW7JI9nAJmjDtUx2FV2I9DF33iMYbvep0pqiQpJxcQFXDOTEYXElKm6Y1pyV04cpWXn0avi7/3ghn'
    local obfuscated_key='YjBhODE2NGVmZDUwZDIxMmYwNTg4Yzc3ZjI3ZWNjOGEyNDIyNmU4OTYyNGQyZDI2NzMxMjA4ZmU1NTg3ZTE1MA=='

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
