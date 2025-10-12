# Node Lindon
apt-get update
apt-get install -y nginx

# Node Lindon
cat > /etc/nginx/sites-available/static.k25.com << 'EOF'
server {
    listen 80;
    server_name static.k25.com lindon.k25.com;
    
    root /var/www/static;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location /annals/ {
        alias /var/www/static/annals/;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    }
}
EOF

# Node Lindon
ln -sf /etc/nginx/sites-available/static.k25.com /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

mkdir -p /var/www/static/annals

echo "<h1>Welcome to Lindon - Static Archives</h1>" > /var/www/static/index.html
echo "Archive 1: The Fall of Beleriand" > /var/www/static/annals/archive1.txt
echo "Archive 2: The Ships of Cirdan" > /var/www/static/annals/archive2.txt
echo "Archive 3: The Grey Havens" > /var/www/static/annals/archive3.txt

nginx -t
systemctl restart nginx

# Test dari Node manapun
curl http://static.k25.com
curl http://static.k25.com/annals/