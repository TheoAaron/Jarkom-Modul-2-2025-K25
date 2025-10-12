# Node Sirion
apt-get update
apt-get install -y nginx

# Node Sirion - Konfigurasi Reverse Proxy
cat > /etc/nginx/sites-available/www.k25.com << 'EOF'
server {
    listen 80;
    server_name www.k25.com sirion.k25.com;
    
    # Path-based routing ke Lindon (static)
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
    
    # Path-based routing ke Vingilot (app)
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
    
    # Default location untuk root
    location / {
        root /var/www/sirion;
        index index.html;
        try_files $uri $uri/ =404;
    }
}
EOF

# Node Sirion - Enable site dan remove default
ln -sf /etc/nginx/sites-available/www.k25.com /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Node Sirion - Buat halaman default untuk Sirion
mkdir -p /var/www/sirion
cat > /var/www/sirion/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Sirion - Gateway of Beleriand</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        h1 { margin-bottom: 10px; }
        .info { 
            background: rgba(255,255,255,0.1); 
            padding: 15px; 
            border-radius: 5px; 
            margin: 20px 0; 
        }
        a { 
            color: #ffd700; 
            text-decoration: none;
            display: block;
            margin: 10px 0;
        }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>Welcome to Sirion</h1>
    <p>The Gateway and Reverse Proxy of Beleriand</p>
    
    <div class="info">
        <h2>Available Services</h2>
        <a href="/static">→ Static Archives (Lindon)</a>
        <a href="/app">→ Dynamic Application (Vingilot)</a>
    </div>
    
    <div class="info">
        <h3>About Sirion</h3>
        <p>Sirion berdiri sebagai reverse proxy yang mengarahkan trafik ke berbagai layanan di Beleriand.</p>
    </div>
</body>
</html>
EOF

# Node Sirion - Set permissions
chown -R www-data:www-data /var/www/sirion

# Node Sirion - Test konfigurasi dan restart
nginx -t
service nginx restart
service nginx status

# Testing dari Node manapun (misal Earendil atau Cirdan)
# Test akses ke Sirion root
curl http://www.k25.com
curl http://sirion.k25.com

# Test routing ke Lindon (static)
curl http://www.k25.com/static
curl http://www.k25.com/static/annals/

# Test routing ke Vingilot (app)
curl http://www.k25.com/app
curl http://www.k25.com/app/about

# Verifikasi header diteruskan dengan benar
curl -v http://www.k25.com/static 2>&1 | grep -i "host\|x-real-ip"
curl -v http://www.k25.com/app 2>&1 | grep -i "host\|x-real-ip"