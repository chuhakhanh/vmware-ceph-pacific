#!/bin/bash
filename=$1
while read line; do
# reading each line
sshpass -p "admin123" ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$line
done < $filename