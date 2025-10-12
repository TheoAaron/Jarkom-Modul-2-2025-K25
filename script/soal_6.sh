# Node Tirion
dig @10.76.3.3 k25.com SOA

# Node Valmar
dig @10.76.3.4 k25.com SOA

ls -la /var/cache/bind/
cat /var/cache/bind/db.k25.com

# force transfer di Node Valmar
rndc retransfer k25.com