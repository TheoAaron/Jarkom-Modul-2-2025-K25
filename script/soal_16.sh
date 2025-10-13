# kalau misal error coba perhatiin ip lindon itu stay .5 atau .7 oke gitu aja sih

# Node Earendil (atau klien lain)
echo "Query lindon.k25.com sebelum perubahan:"
dig +short lindon.k25.com
echo "Query static.k25.com (CNAME) sebelum perubahan:"
dig +short static.k25.com

# Node Lindon - Ubah IP dari 10.76.3.5 ke 10.76.3.15
cat > /tmp/lindon_interfaces << 'EOF'
auto eth0
iface eth0 inet static
    address 10.76.3.15
    netmask 255.255.255.0
    gateway 10.76.3.1
    up echo nameserver 10.76.3.3 > /etc/resolv.conf
    up echo nameserver 10.76.3.4 >> /etc/resolv.conf
    up echo nameserver 192.168.122.1 >> /etc/resolv.conf
EOF

# Node Tirion - Update zone file dengan IP baru dan TTL 30 detik
cat > /etc/bind/zones/db.k25.com << 'EOF'
;
; BIND data file for k25.com
;
$TTL    604800
@       IN      SOA     ns1.k25.com. admin.k25.com. (
                              2025101104         ; Serial (DINAIKKAN!)
                              604800         ; Refresh
                              86400         ; Retry
                              2419200         ; Expire
                              604800 )       ; Negative Cache TTL
;
; Name Servers
@       IN      NS      ns1.k25.com.
@       IN      NS      ns2.k25.com.

; A Records for Name Servers
ns1.k25.com.        IN      A       10.76.3.3
ns2.k25.com.        IN      A       10.76.3.4

; A Record for apex
@                   IN      A       10.76.3.2

; A Records for all nodes
eonwe.k25.com.      IN      A       10.76.1.1
earendil.k25.com.   IN      A       10.76.1.2
elwing.k25.com.     IN      A       10.76.1.3
cirdan.k25.com.     IN      A       10.76.2.2
elrond.k25.com.     IN      A       10.76.2.3
maglor.k25.com.     IN      A       10.76.2.4
sirion.k25.com.     IN      A       10.76.3.2
lindon.k25.com.     30      IN      A       10.76.3.15    ; IP BARU dengan TTL 30 detik
vingilot.k25.com.   IN      A       10.76.3.6

; CNAME Records untuk layanan
www.k25.com.        IN      CNAME   sirion.k25.com.
static.k25.com.     30      IN      CNAME   lindon.k25.com.    ; TTL 30 detik
app.k25.com.        IN      CNAME   vingilot.k25.com.
EOF

# Node Tirion
named-checkzone k25.com /etc/bind/zones/db.k25.com
if [ $? -eq 0 ]; then
    echo "Zone file valid!"
    service named restart
    echo "BIND9 restarted di Tirion"
else
    echo "ERROR: Zone file tidak valid!"
    exit 1
fi

echo ""
echo "Menunggu sinkronisasi ke Valmar (ns2)..."
sleep 5

dig @10.76.3.3 k25.com SOA +short | awk '{print $3}'

dig @10.76.3.4 k25.com SOA +short | awk '{print $3}'

# TAHAP 4: Testing 3 Momen

# Testing dari Node Earendil
dig +short lindon.k25.com
dig +short static.k25.com

sleep 15

dig +short lindon.k25.com
dig +short static.k25.com

sleep 20

dig +short lindon.k25.com
dig +short static.k25.com