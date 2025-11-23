#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='U2FsdGVkX1/VoP2T7cii/Y9WUP2hVjemFdq9vvkC+GJfcqdFhtfcmL3apyagIF1f0WaPew25LYHn85JwQqwEgZC1aJivKdsxgFGW85ME1YJoAoX4Fyr+rfK2dUTddhkwzmLZykGENvi86e2QYTZEAhEO5hZD4nxOiA9DWoVOVVr688y1euSe+RFcyg9V2oQ9s81XD6iNCFfy4+R+TjafU0u6FUk9QLvDfoPF7jz+8iyo7X6DRjsevwNU4CiduzgF9aqq0m8tqPVrtMvr7Mp+XW14d/IjP/GWrywIben6VUOoz5VUih1Z12DYju803zkK4mBFnNnmyfUyKeSIrP+4WDEUgr2460L0l+x36qhI24W7VCvcgTUYP7TG0/qn2Rztr3f5oICidxdAG0D2GRtIrT7lyU9S+NnzLG4dvmsPmTHNNzuL4n6ej5dTYhqq591cgoZLj7tf9mQnDmSEhMj6+gdg50k2LKPjL80kuyXGsOK/dBFGSLPZ/enITM76keRO+3PEkDZXmqk+2ICNYIqCdD2O4WSjqi6dWaxL14c3lQqpVyYyHB+7RZsp6akPvqoXhfKs3Sku3pGwNXcXIhNwG0K85HT/9isPqm4yLNnYvfcFNGxRpSNcFfFlX1cy6ZYbmXp5+hwVha5Y074lRzy+gSBymtREr98oHB3a25OTkev5kz0m+dkfgEdWEOXu+riKLSK77oQGqrwP/Ac18eHgUIC6Sq+456709iF5bEgJG/Myt4jLM9YnrN014YZUxOac6XR24s0FK32CCmOiLu1r6/vhJuFXCY5HBnxx9F9HbN8mERoHP+24IrImDtT+38hEwb7T4rsTregsIpYeTuIN5Mld9XlQfKjzhP0I7UTvldi/rbUmj5NCttrf4WMh9Ovi'
    local obfuscated_key='MzgzMzc2YTYyNmQ4Mzk5NzEwZmNlMWNlZDgxYWVkNmE4MTQwNDU0MTRhYTM0MmJhOGJlY2NjZmQ4MWNmZTM4MQ=='

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
