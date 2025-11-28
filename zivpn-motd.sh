#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='U2FsdGVkX19BDzXoS8E4svkEPu1lQ120y52wYKLjZzjDsMWOpHgE9n+vTFMV8aJfbr/To9kBx7TzzlBfVMRhEjE/tnmAa2euHimHg8PZ7cj67/s866iBtDkBVopKW0BBDXFDV1hPaLUSNBcnnuUJnAOZdRZRe5RT39f283s24+VTS3eHTvoLNma1l6JDvBEWpmf1CkJEf5IYfkHOd1DkuwzzTPbRBLat72+5b5EO5kb7JMEUTJ0ZhhLOubjsQUMHrg7eF265tP7RvpRs+kw+ya68Qi4HE5PawENVWt0YSHVv7GBWEwxvFc1G6+9q3zOo9IWBjWGj2j7zbIjEqfPHg51NW9GGG0SPimqy/kn2QpNqArw1ilrtzCw8U0ImfuUMyNRjs4jqi5gZRXjLpX3JlhJM/rLZfXP8wjNcpgMmsbhQGk3yH0YoomLf1QxL/hy6O9hHgBomw8lBds5AR6eH+kaxzTodOnFUyng7MImryNyEemhpC0V0WHCfPHhmXaP1NLgGcjRUFfy5sgmnXiPrIYjyijqDrR/uyphzPVeWYDVng4g6Ho+qr/WAoy7w4OTge3+7uvlnwUZqMLAd1uX0z+NwInCM8VNWh54O80A2Gwim1HMPxB6Ghqik6Q3+kPOIIeYACDHcASy23JdctE8IYomAft2UR+V21ARoma6OjqqgHpEeudRZjVOmGT58r/+VoVIPHX5fj1X4Osk7FwRWDuUqtPx5bWTuuqKpmML/1MPE56HES/5MIHJkXsaMOGd1EohaioUQD+xV0aOa7NKbdVlOH1XjlHTABCPmE4nRZ3zvVjlWmN+iA/vqAv8vW/BdCV00tCag6K+/GypO68GwrPZNpBD1NNlovF697EAVgrcjZR2bMeZWbGQ/FJW0FenX'
    local obfuscated_key='ZWUxNTg2ZmIwYjRhZDFmZmE0OTg4ZTZkMWRmYzczZDQ0MjlmMmIxNDg1NGE1ODgxMTE0YWI4YjMwMDJlOTlmYg=='

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
