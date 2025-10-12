# Node Vingilot
# Update konfigurasi Nginx untuk logging IP asli dari header X-Real-IP

cat > /etc/nginx/sites-available/app.k25.com << 'EOF'
# Custom log format yang mencatat X-Real-IP
log_format real_ip '$remote_addr - $http_x_real_ip - $remote_user [$time_local] '
                   '"$request" $status $body_bytes_sent '
                   '"$http_referer" "$http_user_agent"';

server {
    listen 80;
    server_name app.k25.com vingilot.k25.com;
    
    # Set real IP dari header yang dikirim Sirion
    set_real_ip_from 10.76.3.2;  # IP Sirion
    real_ip_header X-Real-IP;
    real_ip_recursive on;
    
    # Log dengan format yang mencatat IP asli
    access_log /var/log/nginx/vingilot_access.log real_ip;
    error_log /var/log/nginx/vingilot_error.log;
    
    root /var/www/app;
    index index.php;
    
    location / {
        try_files $uri $uri/ @rewrite;
    }
    
    location @rewrite {
        rewrite ^/(.+)$ /$1.php last;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param REMOTE_ADDR $remote_addr;
        include fastcgi_params;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF

# Test konfigurasi dan restart
nginx -t
service nginx restart

# Buat file PHP untuk menampilkan IP address
cat > /var/www/app/checkip.php << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Check IP - Vingilot</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .info { 
            background: rgba(255,255,255,0.1); 
            padding: 15px; 
            border-radius: 5px; 
            margin: 20px 0; 
        }
        .highlight { color: #ffd700; font-weight: bold; }
    </style>
</head>
<body>
    <h1>IP Address Check - Vingilot</h1>
    
    <div class="info">
        <h2>Client Information</h2>
        <p><strong>Your Real IP:</strong> <span class="highlight"><?php echo $_SERVER['REMOTE_ADDR']; ?></span></p>
        <p><strong>X-Real-IP Header:</strong> <span class="highlight"><?php echo isset($_SERVER['HTTP_X_REAL_IP']) ? $_SERVER['HTTP_X_REAL_IP'] : 'Not set'; ?></span></p>
        <p><strong>X-Forwarded-For:</strong> <span class="highlight"><?php echo isset($_SERVER['HTTP_X_FORWARDED_FOR']) ? $_SERVER['HTTP_X_FORWARDED_FOR'] : 'Not set'; ?></span></p>
    </div>
    
    <div class="info">
        <h2>Request Information</h2>
        <p><strong>Request Time:</strong> <?php echo date('Y-m-d H:i:s'); ?></p>
        <p><strong>Request URI:</strong> <?php echo $_SERVER['REQUEST_URI']; ?></p>
        <p><strong>User Agent:</strong> <?php echo $_SERVER['HTTP_USER_AGENT']; ?></p>
    </div>
</body>
</html>
EOF

chown -R www-data:www-data /var/www/app

# Test 1: cek di earendil
curl http://vingilot.k25.com/checkip
# Seharusnya menampilkan IP Earendil: 10.76.1.2

# Test 2: cek di earendil
curl http://www.k25.com/app/checkip
# Seharusnya juga menampilkan IP Earendil: 10.76.1.2 (bukan IP Sirion)

# Node Vingilot - Cek access log
tail -20 /var/log/nginx/vingilot_access.log
# Seharusnya mencatat IP asli klien (10.76.1.2 atau 10.76.2.2), bukan IP Sirion (10.76.3.2)