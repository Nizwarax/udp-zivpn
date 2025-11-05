#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='U2FsdGVkX1+eJ859xSn5MDutRW1+J0n/5/kCpIEBco+JdFyJCZn2RqFgU75qBtb8bVJMPP5e/l/y+yvGQpMMLrn3kETnjbcMgKPLNtE+PYEm5xxvbmYFO4ch9U/lxLkqftRtl2l7OZ2uXjyugLVuzTlGUVYPW9VRLypnuVt2grcMzsXpLbLSjUGuTWfRfyb1pCSXxbPojOB8jN3Pyr5dMLAQjqKOqZwGjAYLaa+cXrtiE6dmjk2TTr17dcVaQLZ9Sq6nXRep+ygWJKYYQBkXVZiR3W+1VbgCl1xjqBrz1XjkgT3deZ7rI2At/pVHg16J5+3eBd9bxsZjfvXUgN6Ni92B0cG6BEhWSfewkcrefrm4GQYGRh6AD/lSNpS/xp0ARNKKgTUPbF82b2MwOXAOzmig8tVgqEcm3b1N/Uw8kG6MrEZkdLFm4bzJr4kVvGy0ILzIkB0bNlnW6geG3qXw0sHXl1RYTwudv3oDoGBtpk0oWQeaSjyYV+QJF0l26fvgIcNxOyxLP5JMLGJVg3MITi2AfS8hukuFhGdhXSEbvl5ewUjbKB1m1z+/+F9YA1WgU6Ha9OIC2osqHO4NPNvYHmeLaUQqc4K2vMZZGHzx19Bdg7rbWkXibTbjMMmbYSEA38H6dzoYGH+HrOTB3qRH3L4UFACdPpHycfdQWkzV/yMAILqG2wnUHxlgUqCZy2qKTTWehVwEiuq7QapNXNY6l+zAbMRsD+rMCIWqBDr+dFihLiYLu0532nH/04a05W0KYFWnRCrAGFUy1LpUM6me6yxqM0GtbZKHiWXA+SYHCtxW9nReU8k/EEruvfLXJCQBL7Lq06BIoB+3tgqAfOMpu+klmTj1sssa/SLDUO/Ww5vKUFIFYQZ1vc+3JUWZUS3W'
    local obfuscated_key='MmU1Y2YzYWFiMjJmOGI0NmNiZDYxNmNkMmM4MWM0OTY1NmJmZTVmOTcxOWMwMWMwYzNhYjlmOTBmN2I3NjNlNQ=='

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
