# Node Vingilot
apt-get update
apt-get install -y nginx php8.4-fpm

# Node Vingilot
cat > /etc/nginx/sites-available/app.k25.com << 'EOF'
server {
    listen 80;
    server_name app.k25.com vingilot.k25.com;
    
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
        include fastcgi_params;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF

# Node Vingilot
ln -sf /etc/nginx/sites-available/app.k25.com /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

mkdir -p /var/www/app

# Node Vingilot
cat > /var/www/app/index.php << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Vingilot - Dynamic Application</title>
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
        .info { background: rgba(255,255,255,0.1); padding: 15px; border-radius: 5px; margin: 20px 0; }
        a { color: #ffd700; }
    </style>
</head>
<body>
    <h1>Welcome to Vingilot</h1>
    <p>The ship that sails through dynamic waters</p>
    
    <div class="info">
        <h2>Server Information</h2>
        <p><strong>Server Time:</strong> <?php echo date('Y-m-d H:i:s'); ?></p>
        <p><strong>Client IP:</strong> <?php echo $_SERVER['REMOTE_ADDR']; ?></p>
        <p><strong>User Agent:</strong> <?php echo $_SERVER['HTTP_USER_AGENT']; ?></p>
    </div>
    
    <p><a href="/about">Learn more about Vingilot</a></p>
</body>
</html>
EOF

# Node Vingilot
cat > /var/www/app/about.php << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>About Vingilot</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            color: white;
        }
        h1 { margin-bottom: 10px; }
        .content { background: rgba(255,255,255,0.1); padding: 20px; border-radius: 5px; margin: 20px 0; }
        a { color: #ffd700; }
    </style>
</head>
<body>
    <h1>About Vingilot</h1>
    
    <div class="content">
        <h2>The Star Ship</h2>
        <p>Vingilot adalah kapal yang dipandu oleh Earendil, membawa Silmaril melintasi langit sebagai bintang paling terang.</p>
        
        <h3>Technical Details</h3>
        <p><strong>Powered by:</strong> PHP <?php echo phpversion(); ?></p>
        <p><strong>Server:</strong> Nginx</p>
        <p><strong>Current Path:</strong> <?php echo $_SERVER['REQUEST_URI']; ?></p>
        <p><strong>Access Time:</strong> <?php echo date('Y-m-d H:i:s'); ?></p>
    </div>
    
    <p><a href="/">Back to Home</a></p>
</body>
</html>
EOF

# Node Vingilot
chown -R www-data:www-data /var/www/app
nginx -t
systemctl restart nginx
systemctl restart php8.4-fpm

# Test dari Node manapun
curl http://app.k25.com
curl http://app.k25.com/about