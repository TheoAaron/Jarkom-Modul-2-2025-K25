#cukup dikonfig gausah dimatiin biar ga hilang konfigurainya tapi testing dengan stop node
# dimasukkin ke nano bashrc
# TIRION

cat > /etc/init.d/autostart-tirion << 'EOF'
#!/bin/bash
/usr/sbin/named -u bind
EOF
chmod +x /etc/init.d/autostart-tirion
update-rc.d autostart-tirion defaults


# VALMAR

cat > /etc/init.d/autostart-valmar << 'EOF'
#!/bin/bash
/usr/sbin/named -u bind
EOF
chmod +x /etc/init.d/autostart-valmar
update-rc.d autostart-valmar defaults

# SIRION

cat > /etc/init.d/autostart-sirion << 'EOF'
#!/bin/bash
/usr/sbin/nginx
EOF
chmod +x /etc/init.d/autostart-sirion
update-rc.d autostart-sirion defaults

# LINDON
cat > /etc/init.d/autostart-lindon << 'EOF'
#!/bin/bash
/usr/sbin/nginx
EOF
chmod +x /etc/init.d/autostart-lindon
update-rc.d autostart-lindon defaults

# VINGILOT

cat > /etc/init.d/autostart-vingilot << 'EOF'
#!/bin/bash
/usr/sbin/php-fpm8.4
/usr/sbin/nginx
EOF
chmod +x /etc/init.d/autostart-vingilot
update-rc.d autostart-vingilot defaults

# TESTING: (dari client, setelah semua node dikonfig)
dig k25.com +short
dig www.k25.com +short
curl -s http://static.k25.com | head -1
curl -s http://app.k25.com | head -1
