# Node Tirion
cat > /etc/bind/zones/db.k25.com << 'EOF'
;
; BIND data file for k25.com
;
$TTL    604800
@       IN      SOA     ns1.k25.com. admin.k25.com. (
                              2025101103         ; Serial (naikkan!)
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

; A Record for apex
@                   IN      A       10.15.3.2

; A Records for all nodes
eonwe.k25.com.      IN      A       10.15.1.1
earendil.k25.com.   IN      A       10.15.1.2
elwing.k25.com.     IN      A       10.15.1.3
cirdan.k25.com.     IN      A       10.15.2.2
elrond.k25.com.     IN      A       10.15.2.3
maglor.k25.com.     IN      A       10.15.2.4
sirion.k25.com.     IN      A       10.15.3.2
lindon.k25.com.     IN      A       10.15.3.5
vingilot.k25.com.   IN      A       10.15.3.6

; CNAME Records untuk layanan
www.k25.com.        IN      CNAME   sirion.k25.com.
static.k25.com.     IN      CNAME   lindon.k25.com.
app.k25.com.        IN      CNAME   vingilot.k25.com.
EOF

# Node Tirion
named-checkzone k25.com /etc/bind/zones/db.k25.com
service named restart

# Testing dari 2 Node berbeda (Earendil dan Cirdan)
# Node Earendil
dig www.k25.com
dig static.k25.com
dig app.k25.com

# Node Cirdan
dig www.k25.com
dig static.k25.com
dig app.k25.com