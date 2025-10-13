# Node Tirion - Update zona
cat > /etc/bind/zones/db.k25.com << 'EOF'
$TTL    604800
@       IN      SOA     ns1.k25.com. admin.k25.com. (
                              2025101106
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
havens.k25.com.     IN      CNAME   www.k25.com.
melkor.k25.com.     IN      TXT     "Morgoth (Melkor)"
morgoth.k25.com.    IN      CNAME   melkor.k25.com.
EOF

named-checkzone k25.com /etc/bind/zones/db.k25.com
service named restart

# Node Valmar - Sync
rndc retransfer k25.com

# Node Sirion - Update Nginx (PENTING!)
cat > /etc/nginx/sites-available/www.k25.com << 'EOF'
server {
    listen 80;
    server_name 10.76.3.2 sirion.k25.com;
    return 301 http://www.k25.com$request_uri;
}
server {
    listen 80;
    server_name www.k25.com havens.k25.com;
    
    location /admin/ {
        auth_basic "Restricted Access - Admin Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
        alias /var/www/sirion/admin/;
        index index.html;
    }
    location = /admin {
        return 301 /admin/;
    }
    location /static/ {
        proxy_pass http://lindon.k25.com/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    location /static {
        proxy_pass http://lindon.k25.com/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    location /app/ {
        proxy_pass http://vingilot.k25.com/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    location /app {
        proxy_pass http://vingilot.k25.com/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    location / {
        root /var/www/sirion;
        index index.html;
        try_files $uri $uri/ =404;
    }
}
EOF

nginx -t && service nginx reload

# Verifikasi
dig havens.k25.com +short