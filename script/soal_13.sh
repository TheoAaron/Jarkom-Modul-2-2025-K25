# Node Sirion
cat > /etc/nginx/sites-available/www.k25.com << 'EOF'
# Redirect dari IP dan sirion.k25.com ke www.k25.com
server {
    listen 80;
    server_name 10.76.3.2 sirion.k25.com;
    
    return 301 http://www.k25.com$request_uri;
}

# Server utama dengan hostname kanonik
server {
    listen 80;
    server_name www.k25.com;
    
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

# Test dan reload nginx
nginx -t
service nginx reload

# Test 1: Akses via IP (harus redirect 301 ke www.k25.com)
curl -I http://10.76.3.2/

# Test 2: Akses via sirion.k25.com (harus redirect 301 ke www.k25.com)
curl -I http://sirion.k25.com/

# Test 3: Akses via www.k25.com (langsung OK tanpa redirect)
curl -I http://www.k25.com/

# Test 4: Redirect dengan path
curl -I http://10.76.3.2/static
curl -I http://sirion.k25.com/app