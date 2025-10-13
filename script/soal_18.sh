cat > /etc/bind/zones/db.k25.com << 'EOF'
$TTL    604800
@       IN      SOA     ns1.k25.com. admin.k25.com. (
                              2025101105
                              604800
                              86400
                              2419200
                              604800 )
@       IN      NS      ns1.k25.com.
@       IN      NS      ns2.k25.com.
ns1.k25.com.        IN      A       10.76.3.3
ns2.k25.com.        IN      A       10.76.3.4
@                   IN      A       10.76.3.2
eonwe.k25.com.      IN      A       10.76.1.1
earendil.k25.com.   IN      A       10.76.1.2
elwing.k25.com.     IN      A       10.76.1.3
cirdan.k25.com.     IN      A       10.76.2.2
elrond.k25.com.     IN      A       10.76.2.3
maglor.k25.com.     IN      A       10.76.2.4
sirion.k25.com.     IN      A       10.76.3.2
lindon.k25.com.     30      IN      A       10.76.3.7
vingilot.k25.com.   IN      A       10.76.3.6
www.k25.com.        IN      CNAME   sirion.k25.com.
static.k25.com.     30      IN      CNAME   lindon.k25.com.
app.k25.com.        IN      CNAME   vingilot.k25.com.
melkor.k25.com.     IN      TXT     "Morgoth (Melkor)"
morgoth.k25.com.    IN      CNAME   melkor.k25.com.
EOF

named-checkzone k25.com /etc/bind/zones/db.k25.com
service named restart

# Node Valmar - Sync
rndc retransfer k25.com
sleep 3

# Verifikasi
dig melkor.k25.com TXT +short
# Expected: "Morgoth (Melkor)"

dig morgoth.k25.com TXT +short
# Expected: "Morgoth (Melkor)"

dig morgoth.k25.com CNAME +short
# Expected: melkor.k25.com.