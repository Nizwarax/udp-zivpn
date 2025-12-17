#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='U2FsdGVkX1/KVDdRj/TugVRgyfrsxukrbYzeG3hdEzAN7Iw6JdudJQoz5J7I69k/Fdx8xYVBA57G4TLp6zbBu9/Eh1IXwH/jFdrKGj5n/hHyXtF7n8v2F9MUP/l/+Rh8N8GYJUTLcOsbSeZ5uxJCCplHvwonhdpBlVpVtZaOYsunME03nGV8fD9Rozw+pR1rJ0rZC0GZOUyh39QeY9X1yWi8fYgibOqTDkpZI9rzIFeCdyrRTLNdIFQqX+wpitqsw6p+iNrR5hzTjtSqK8kN2oJarqvj22sdRR+HS2x2DNT2BJsYnZIV83lu867KNpzu2vkvZdZNu7x4zbJBvxXg58K0S/0b2hSM7uaoOSfAJORIZELnArM/Estv0CHn2Mgv0XzoRGJV+vIdEm9pS9nialnyZuOjlfIBjjL7vYYKZdsG2AMoPLLkLtLHPo6YUZm8ckyySk88OuPVLcOimYgXCOUoO7gWqNhuWAnJzr9OHa5zeF1VCoBHp+aepN6Nlv3zTYwYnRLV8a4WKuaebqf8ErBXfLj76VPc6CCQ0+AO/y68z5TnmTSPhb1Sm9SVJQGt/zPxMxVt94uWx+Dip2uA5uOatqxNitMkHxp4SyDGC2wyEF1bOWL42DngdjD2Cw0NYOkUENvAqhPD+WbexXiBBtwiGGZAoj/S24j3gSO00AU+NA2HdEAuIyHgNiic20pQhM1uC4v2WmNAmAEEJgr6W0buxzTHwhDHdIg1nOqhRog9s9tIiMRELCpaL1Z2/BZn9rUq3zN2Y5NBAZsC4AcvItTJHP+HCot6foyUVnrnJujnAzm20o/qyca4S+qeYPQCv6Ra0Lpy21avOFWF7wDpdUKHHN3cl1oAwhmmMFUgdoJrHGd6LapfL17JTThWo9LL'
    local obfuscated_key='MDFhNzEwNjQwMDdhMjQxMzgwOWQzNzA0NGI2M2MzMWE3M2UwNmE3ZDI3NGY4ZGI1ZTMxOTVmMTNkYjVmOTU1Mg=='

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
