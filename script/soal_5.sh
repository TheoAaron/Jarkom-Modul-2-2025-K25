# Node Eonwe
echo "eonwe" > /etc/hostname
hostname -F /etc/hostname

# Node Earendil
echo "earendil" > /etc/hostname
hostname -F /etc/hostname

# Node Elwing
echo "elwing" > /etc/hostname
hostname -F /etc/hostname

# Node Cirdan
echo "cirdan" > /etc/hostname
hostname -F /etc/hostname

# Node Elrond
echo "elrond" > /etc/hostname
hostname -F /etc/hostname

# Node Maglor
echo "maglor" > /etc/hostname
hostname -F /etc/hostname

# Node Sirion
echo "sirion" > /etc/hostname
hostname -F /etc/hostname

# Node Tirion
echo "tirion" > /etc/hostname
hostname -F /etc/hostname

# Node Valmar
echo "valmar" > /etc/hostname
hostname -F /etc/hostname

# Node Lindon
echo "lindon" > /etc/hostname
hostname -F /etc/hostname

# Node Vingilot
echo "vingilot" > /etc/hostname
hostname -F /etc/hostname

# Node Tirion
cat > /etc/bind/zones/db.k25.com << 'EOF'
;
; BIND data file for k25.com
;
$TTL    604800
@       IN      SOA     ns1.k25.com. admin.k25.com. (
                              2025101102         ; Serial (naikkan!)
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
lindon.k25.com.     IN      A       10.76.3.5
vingilot.k25.com.   IN      A       10.76.3.6
EOF

# Node Tirion 
named-checkzone k25.com /etc/bind/zones/db.k25.com
service named restart

# Node manapun
hostname
dig earendil.k25.com
dig sirion.k25.com