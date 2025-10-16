#!/bin/bash
set -e

SSH_PORT=2222
REMOTE_NODE="$1"

if [ -z "$REMOTE_NODE" ]; then
    echo "Usage: $0 <peer_hostname_or_ip>"
    exit 1
fi

echo "[+] Installing openssh-server..."
apt-get update && apt-get install -y openssh-server

echo "[+] Generating server host keys..."
ssh-keygen -A

echo "[+] Generating SSH keypair for root..."
mkdir -p /root/.ssh
chmod 700 /root/.ssh
[ ! -f /root/.ssh/id_rsa ] && ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa

echo "[+] Updating sshd_config..."
grep -q "^Port " /etc/ssh/sshd_config && sed -i "s/^Port .*/Port ${SSH_PORT}/" /etc/ssh/sshd_config || echo "Port ${SSH_PORT}" >> /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
grep -q "^PubkeyAuthentication" /etc/ssh/sshd_config && sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config || echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

echo "[+] Starting sshd..."
mkdir -p /var/run/sshd
/usr/sbin/sshd -p ${SSH_PORT}

echo
echo "=== COPY THIS PUBLIC KEY to the OTHER container's /root/.ssh/authorized_keys ==="
cat /root/.ssh/id_rsa.pub
echo "=== END OF PUBLIC KEY ==="
echo

# Client side config
SSH_CONFIG_FILE="/root/.ssh/config"
[ -f "$SSH_CONFIG_FILE" ] && cp "$SSH_CONFIG_FILE" "${SSH_CONFIG_FILE}.bak"
if ! grep -q "Host ${REMOTE_NODE}" "$SSH_CONFIG_FILE" 2>/dev/null; then
    cat >> "$SSH_CONFIG_FILE" <<EOF

Host ${REMOTE_NODE}
    Port ${SSH_PORT}
    User root
EOF
    chmod 600 "$SSH_CONFIG_FILE"
fi

echo "[+] Added SSH client config for ${REMOTE_NODE} with Port ${SSH_PORT}."
echo "[+] After exchanging keys both ways, test with: ssh ${REMOTE_NODE} hostname"
