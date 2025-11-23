#!/bin/bash

# --- LOADER ---
if [[ $(ps -o args= -p $$) == *"bash -x"* || $(ps -o args= -p $$) == *"sh -x"* ]]; then
    echo "Debugging is not allowed." >&2
    exit 1
fi

__run_protected() {
    local encrypted_content='U2FsdGVkX1+ab6NenZlBlYPvl08xao+XvC6/Fhu6wel47KKl8Ss0cyYYiTcE1ITvZdJR5EZ0rHLqA1gy5pdrXPnnTyO8hh2Qvh7/PamyuMybZZ6ZymX0ZaoSQ2NcuT+LQKLkpxp0d94uQbZBKbxZ7eLTbk8sWM8M8xgjZjP1kHgNrOxjBMF0Y5h9DMu5/05sq6br5Wvqb7oatxRmU45fXdFGYM6nLTbT7LtNFf/FqJeL71irf8cA/6LCMPZUdokOiW5n+2XzgW2Ey850Y/rBmIl2xNOkqEkg1t2qL8Ielb69tTi3XpVfN/2/Me93IwUGFkKhsRsb1KTbYgqCTVAIskj540YLtnEq+oQeLhdUzFyjfZaitMJ2Z1rPNU70KUA2SI+cWlgQkkzrQxrmvOodEu3TJIbLXPmV7IDFWJkufOvFWe3z06KlwtqL8nFZAjL90jQgwafgCuYToKgrdythigMQPSlQKV/c1fH3hsV/i/6j804je71h3Fhvd6zs5JT2eJy6SykMiYjF1hQh+usLiJRLqGv/0/62Jk2caQYn0VlHRqruAYK9n44P+d55OdMwFWIqEBHxqUuUYH1vnJSohALne0am88Ac1EtJ6p8wZWtXNqj0xN7K5fj+Qzk3r11Q024BYTbxACbXMLt7xtFs54PFuUyTHncrNJ6bbAmE/A77baV2ryUhaTlxVmzodgGIw5F4uC9jCoJqCnyWzozHCYRfBSRnNMuvT5f6sqxJArCGjqqNHx0BNNfSf/a1x4rTPhyMTqpYZOBGO1NXvB1TPOfXVV+3DWBU54pIzCqU97/fMn7Njb5yZFkNyPry6DgUsjXjEXh0b8dTgJo28EHJzA+lsYrkO535Mq+fW9SXB4toLaSZ7SH/RhUh5Jc963pG'
    local obfuscated_key='MjZkY2FlM2NjMDdlYzBlMmNjZTViYTc1NGU3MDgyZWE2ZTRiMzUyYmMyYjJkN2FkYTU4NzZjZGY4ZTNlZWUyZQ=='

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
