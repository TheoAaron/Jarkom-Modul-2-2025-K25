# Node Tirion
apt-get update
apt-get install -y bind9 dnsutils

# Node Tirion
cat > /etc/bind/named.conf.options << 'EOF'
options {
    directory "/var/cache/bind";
    
    forwarders {
        192.168.122.1;
    };
    
    allow-transfer { 10.15.3.4; };
    notify yes;
    listen-on { any; };
    
    dnssec-validation auto;
    listen-on-v6 { any; };
};
EOF

# Node Tirion
cat > /etc/bind/named.conf.local << 'EOF'
zone "k25.com" {
    type master;
    file "/etc/bind/zones/db.k25.com";
    allow-transfer { 10.15.3.4; };
    also-notify { 10.15.3.4; };
    notify yes;
};
EOF

# Node Tirion
mkdir -p /etc/bind/zones

cat > /etc/bind/zones/db.k25.com << 'EOF'
;
; BIND data file for k25.com
;
$TTL    604800
@       IN      SOA     ns1.k25.com. admin.k25.com. (
                              2025101101         ; Serial
                              604800         ; Refresh
                              86400         ; Retry
                              2419200         ; Expire
                              604800 )       ; Negative Cache TTL
;
; Name Servers
@       IN      NS      ns1.k25.com.
@       IN      NS      ns2.k25.com.

; A Records for Name Servers
ns1.k25.com.        IN      A       10.15.3.3
ns2.k25.com.        IN      A       10.15.3.4

; A Record for apex (front door)
@                   IN      A       10.15.3.2
EOF

# Node Tirion
chown -R bind:bind /etc/bind/zones
named-checkconf
named-checkzone k25.com /etc/bind/zones/db.k25.com
service named restart

# Node Valmar
apt-get update
apt-get install -y bind9 dnsutils

# Node Valmar
cat > /etc/bind/named.conf.options << 'EOF'
options {
    directory "/var/cache/bind";
    
    forwarders {
        192.168.122.1;
    };
    
    dnssec-validation auto;
    listen-on-v6 { any; };
};
EOF

# Node Valmar
cat > /etc/bind/named.conf.local << 'EOF'
zone "k25.com" {
    type slave;
    file "/etc/bind/zones/db.k25.com";
    masters { 10.15.3.3; };
};
EOF


# Node Valmar
named-checkconf
service named restart

# Semua Node Kecuali Eonwa
echo "nameserver 10.15.3.3" > /etc/resolv.conf
echo "nameserver 10.15.3.4" >> /etc/resolv.conf
echo "nameserver 192.168.122.1" >> /etc/resolv.conf

# Testing dari klien manapun
dig k25.com
dig ns1.k25.com
dig ns2.k25.com