# Node Tirion
cat > /etc/bind/named.conf.local << 'EOF'
zone "k25.com" {
    type master;
    file "/etc/bind/zones/db.k25.com";
    allow-transfer { 10.15.3.4; };
    also-notify { 10.15.3.4; };
    notify yes;
};

zone "3.15.10.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.10.15.3";
    allow-transfer { 10.15.3.4; };
    also-notify { 10.15.3.4; };
    notify yes;
};
EOF

# Node Tirion
cat > /etc/bind/zones/db.10.15.3 << 'EOF'
;
; BIND reverse data file for 10.15.3.0/24
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

; PTR Records
2       IN      PTR     sirion.k25.com.
3       IN      PTR     ns1.k25.com.
4       IN      PTR     ns2.k25.com.
5       IN      PTR     lindon.k25.com.
6       IN      PTR     vingilot.k25.com.
EOF

# Node Tirion
named-checkzone 3.15.10.in-addr.arpa /etc/bind/zones/db.10.15.3
systemctl restart bind9

# Node Valmar
cat > /etc/bind/named.conf.local << 'EOF'
zone "k25.com" {
    type slave;
    file "db.k25.com";
    masters { 10.15.3.3; };
};

zone "3.15.10.in-addr.arpa" {
    type slave;
    file "db.10.15.3";
    masters { 10.15.3.3; };
};
EOF

# Node Valmar
systemctl restart bind9

# Test Node manapun
dig -x 10.15.3.2
dig -x 10.15.3.5
dig -x 10.15.3.6