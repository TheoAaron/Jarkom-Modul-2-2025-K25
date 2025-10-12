# Node Sirion
apt-get update
apt-get install -y apache2-utils

# Buat password file menggunakan htpasswd
htpasswd -c -b /etc/nginx/.htpasswd admin admin123

# Set permissions
chmod 644 /etc/nginx/.htpasswd
chown www-data:www-data /etc/nginx/.htpasswd

# Konfigurasi Nginx dengan Basic Auth
cat > /etc/nginx/sites-available/www.k25.com << 'EOF'
server {
    listen 80;
    server_name www.k25.com sirion.k25.com;
    
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

# Buat direktori dan halaman admin
mkdir -p /var/www/sirion/admin

cat > /var/www/sirion/admin/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Admin Panel - Sirion</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: linear-gradient(135deg, #232526 0%, #414345 100%);
            color: white;
        }
        h1 { 
            margin-bottom: 10px;
            color: #ffd700;
        }
        .panel { 
            background: rgba(255,255,255,0.1); 
            padding: 20px; 
            border-radius: 5px; 
            margin: 20px 0;
            border-left: 4px solid #ffd700;
        }
        .warning {
            background: rgba(255,0,0,0.2);
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
            border-left: 4px solid #ff0000;
        }
        a { 
            color: #ffd700; 
            text-decoration: none;
        }
        a:hover { text-decoration: underline; }
        .status { color: #00ff00; }
    </style>
</head>
<body>
    <h1>🔐 Admin Panel</h1>
    <p>Welcome to Sirion's restricted area</p>
    
    <div class="warning">
        <h3>⚠️ Restricted Access</h3>
        <p>This area is protected by Basic Authentication. Only authorized personnel are allowed.</p>
    </div>
    
    <div class="panel">
        <h2>System Status</h2>
        <p><span class="status">●</span> Sirion Gateway: <strong>Online</strong></p>
        <p><span class="status">●</span> Lindon Backend: <strong>Online</strong></p>
        <p><span class="status">●</span> Vingilot Backend: <strong>Online</strong></p>
    </div>
    
    <div class="panel">
        <h2>Quick Links</h2>
        <p><a href="/">← Back to Home</a></p>
        <p><a href="/static">View Static Content</a></p>
        <p><a href="/app">View Dynamic App</a></p>
    </div>
    
    <div class="panel">
        <h3>Admin Actions</h3>
        <p>• Server Configuration</p>
        <p>• Monitor Traffic</p>
        <p>• View Logs</p>
        <p>• Manage Users</p>
    </div>
</body>
</html>
EOF

# Set permissions
chown -R www-data:www-data /var/www/sirion

# Test dan reload nginx
nginx -t
service nginx reload

# Test 1: Tanpa kredensial (harus 401)
curl http://www.k25.com/admin/

# Test 2: Dengan kredensial salah (harus 401)
curl -u admin:wrongpass http://www.k25.com/admin/

# Test 3: Dengan kredensial benar (harus 200 OK)
curl -u admin:admin123 http://www.k25.com/admin/

# Test 4: Path lain tidak terproteksi
curl http://www.k25.com/
curl http://www.k25.com/static
curl http://www.k25.com/app