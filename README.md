| Nama                        | NRP        |
| --------------------------- | ---------- |
| Syifa Nurul Alfiah          | 5027241019 |
| Theodorus Aaron Ugraha      | 5027241056 |

# Laporan Praktikum Jaringan Komputer - Modul 2

## Soal 1: IP Addressing dan Interface

### Tujuan
Menetapkan skema alamat IP untuk semua node dan menyetel nameserver default.

### Solusi / Langkah
File: `script/soal_1.sh` — konfigurasi `/etc/network/interfaces` (repr sentral dalam skrip):

```bash
# Contoh (potongan dari skrip)
auto eth1
iface eth1 inet static
    address 10.76.1.1
    netmask 255.255.255.0

# ... dan seterusnya untuk subnet 10.76.1.0/24, 10.76.2.0/24, 10.76.3.0/24

# Nameserver lokal/testing
echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

### Perintah penting
- Konfigurasi interface: tulis file konfigurasi yang sesuai pada masing-masing node (atau gunakan `ip addr add ...` untuk testing sementara).

### Hasil yang diharapkan
- Node-router dan klien mempunyai alamat sesuai daftar (mis. Eonwe 10.76.1.1, Earendil 10.76.1.2, Cirdan 10.76.2.2, Sirion 10.76.3.2, Tirion 10.76.3.1, dsb).

### Verifikasi
- `ip addr show` pada masing-masing node
- `cat /etc/resolv.conf`

---

## Soal 2: Konfigurasi NAT dan IP Forwarding

### Tujuan
Mengizinkan host di jaringan internal mengakses internet melalui NAT pada gateway.

### Solusi / Langkah
File: `script/soal_2.sh`:

```bash
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE -s 10.76.0.0/16
```

### Perintah penting
- Aktifkan IP forwarding
- Atur rule MASQUERADE untuk subnet 10.76.0.0/16

### Hasil yang diharapkan
- Host internal dapat melakukan ping/curl ke alamat internet normal (mis. google.com)

### Verifikasi
- `sysctl net.ipv4.ip_forward` atau `cat /proc/sys/net/ipv4/ip_forward`
- `iptables -t nat -S` atau `iptables-save | grep MASQUERADE`
- `ping google.com -c 2` dari klien

---

## Soal 3: Aturan Forwarding IPTables & Pengujian Konektivitas

### Tujuan
Mengizinkan forwarding trafik antar interface internal sesuai topologi.

### Solusi / Langkah
File: `script/soal_3.sh` — menambahkan rule FORWARD untuk mengizinkan trafik antar subnet:

```bash
iptables -A FORWARD -i eth1 -o eth2 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth3 -j ACCEPT
iptables -A FORWARD -i eth3 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth3 -j ACCEPT
iptables -A FORWARD -i eth3 -o eth2 -j ACCEPT

# Pengujian konektivitas
ping 10.76.2.2  # ping Cirdan (klien Timur)
ping 10.76.3.2  # ping Sirion (DMZ)
```

### Hasil yang diharapkan
- Paket antar subnet diteruskan oleh router; ping antar node berhasil.

### Verifikasi
- `iptables -L FORWARD -n -v`
- `ping` hasil dari beberapa node

---

## Soal 4: Setup DNS (Master Tirion dan Slave Valmar)

### Tujuan
Men-setup server DNS master (Tirion) dan slave (Valmar) untuk zona `k25.com`.

### Solusi / Langkah
File: `script/soal_4.sh` — instalasi BIND9, konfigurasi `named.conf.options`, `named.conf.local` dan file zona master:

```bash
# Tirion (master)
cat > /etc/bind/named.conf.options << 'EOF'
options {
    directory "/var/cache/bind";
    forwarders { 192.168.122.1; };
    allow-transfer { 10.76.3.4; };
    listen-on { any; };
};
EOF

cat > /etc/bind/named.conf.local << 'EOF'
zone "k25.com" {
    type master;
    file "/etc/bind/zones/db.k25.com";
    allow-transfer { 10.76.3.4; };
    also-notify { 10.76.3.4; };
};
EOF

# Contoh record di db.k25.com: ns1=10.76.3.3, ns2=10.76.3.4, apex=10.76.3.2
```

### Perintah penting
- `named-checkconf` dan `named-checkzone k25.com /etc/bind/zones/db.k25.com`
- Restart service `service named restart`

### Hasil yang diharapkan
- Tirion menjadi authoritative untuk `k25.com` dan Valmar sinkron sebagai slave.

### Verifikasi
- `dig @10.76.3.3 k25.com SOA`
- `dig ns1.k25.com`, `dig ns2.k25.com` dari klien

---

## Soal 5: Hostname & Update Zona DNS

### Tujuan
Menetapkan hostname pada tiap node dan memperbarui zone file `db.k25.com` dengan semua host.

### Solusi / Langkah
File: `script/soal_5.sh` — set `hostname` pada setiap node dan update zone file:

```bash
echo "eonwe" > /etc/hostname; hostname -F /etc/hostname
... (berulang untuk earendil, elwing, cirdan, dst)

# Update db.k25.com untuk menambahkan A record semua node
```

### Hasil yang diharapkan
- Semua nama host dapat di-resolve melalui DNS internal (ns1/ns2).

### Verifikasi
- `hostname` pada tiap node
- `dig earendil.k25.com`, `dig sirion.k25.com`

---

## Soal 6: Validasi Zona & Force Transfer

### Tujuan
Memvalidasi file zona dan memastikan file tersimpan di cache bind; memaksa transfer (retransfer) di slave.

### Solusi / Langkah
File: `script/soal_6.sh` — cek SOA, lihat cache, lakukan `rndc retransfer` jika perlu:

```bash
dig @10.76.3.3 k25.com SOA
dig @10.76.3.4 k25.com SOA
ls -la /var/cache/bind/
cat /var/cache/bind/db.k25.com
rndc retransfer k25.com
```

### Hasil yang diharapkan
- Serial di ns1 dan ns2 sama; zone file ada di cache slave.

### Verifikasi
- `dig k25.com SOA` dari master dan slave
- isi `/var/cache/bind/db.k25.com`

---

## Soal 7: Menambahkan CNAME untuk Layanan

### Tujuan
Menambah CNAME records untuk layanan `www.k25.com`, `static.k25.com`, `app.k25.com` yang menunjuk ke host backend.

### Solusi / Langkah
File: `script/soal_7.sh` — update zone file di Tirion dan restart named:

```bash
# Tambahan di db.k25.com
www.k25.com.        IN      CNAME   sirion.k25.com.
static.k25.com.     IN      CNAME   lindon.k25.com.
app.k25.com.        IN      CNAME   vingilot.k25.com.
```

### Hasil yang diharapkan
- `www`, `static`, `app` resolve ke host backend masing-masing.

### Verifikasi
- `dig www.k25.com`, `dig static.k25.com`, `dig app.k25.com`

---

## Soal 8: Reverse DNS (PTR) untuk 10.76.3.0/24

### Tujuan
Membuat zone reverse PTR untuk subnet DMZ (10.76.3.0/24) sehingga IP dapat direverse-resolve ke nama host.

### Solusi / Langkah
File: `script/soal_8.sh` — konfigurasi `named.conf.local` untuk zone `3.76.10.in-addr.arpa` dan file `db.10.76.3`:

```bash
zone "3.76.10.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.10.76.3";
    allow-transfer { 10.76.3.4 };
};

# PTRs: 2 -> sirion.k25.com., 3 -> ns1.k25.com., 4 -> ns2.k25.com., etc.
```

### Hasil yang diharapkan
- `dig -x 10.76.3.2` mengembalikan `sirion.k25.com.` dan PTR lainnya sesuai file.

### Verifikasi
- `dig -x 10.76.3.2`, `dig -x 10.76.3.5` dll.

---

## Soal 9: Web Static - Nginx di Lindon

### Tujuan
Menyajikan konten statis (arsip) pada host Lindon dengan Nginx.

### Solusi / Langkah
File: `script/soal_9.sh` — install nginx, konfigurasi site `static.k25.com`, buat konten di `/var/www/static`:

```bash
apt-get update; apt-get install -y nginx
cat > /etc/nginx/sites-available/static.k25.com << 'EOF'
server { listen 80; server_name static.k25.com lindon.k25.com; root /var/www/static; }
EOF
ln -sf /etc/nginx/sites-available/static.k25.com /etc/nginx/sites-enabled/
mkdir -p /var/www/static/annals
echo "<h1>Welcome to Lindon - Static Archives</h1>" > /var/www/static/index.html
nginx -t && service nginx restart
```

### Hasil yang diharapkan
- `curl http://static.k25.com` menampilkan halaman index; `/annals/` menunjukkan file-file arsip.

### Verifikasi
- `nginx -t` output
- `curl http://static.k25.com`
- `ls -la /var/www/static/annals`

---

## Soal 10: Web Dinamis - Nginx + PHP-FPM di Vingilot

### Tujuan
Men-deploy aplikasi PHP sederhana di Vingilot dan melayani lewat Nginx + PHP-FPM.

### Solusi / Langkah
File: `script/soal_10.sh` — install nginx, php8.4-fpm, buat situs `app.k25.com`, buat `index.php` dan `about.php`:

```bash
apt-get update; apt-get install -y nginx php8.4-fpm
cat > /etc/nginx/sites-available/app.k25.com << 'EOF'
server { listen 80; server_name app.k25.com vingilot.k25.com; root /var/www/app; index index.php; }
EOF
mkdir -p /var/www/app
cat > /var/www/app/index.php << 'EOF'
<?php echo "Welcome to Vingilot"; ?>
EOF
nginx -t && service nginx restart && service php8.4-fpm restart
```

### Hasil yang diharapkan
- `curl http://app.k25.com` menampilkan konten PHP; `/about` menampilkan halaman PHP tentang aplikasi.

### Verifikasi
- `nginx -t` dan `service php8.4-fpm status`
- `curl http://app.k25.com` dan `curl http://app.k25.com/about`

---

## Soal 11: Reverse Proxy dengan Path-Based Routing

### Solusi

#### Langkah 1: Install Nginx di Node Sirion
```bash
# Node Sirion
apt-get update
apt-get install -y nginx
```

**Screenshot yang dibutuhkan:**
- Screenshot hasil instalasi nginx yang berhasil

#### Langkah 2: Konfigurasi Reverse Proxy
```bash
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
```

**Penjelasan Konfigurasi:**
- **server_name**: Sirion menerima request dari `www.k25.com` dan `sirion.k25.com`
- **location /static/**: Semua request ke `/static` akan di-proxy ke Lindon
- **location /app/**: Semua request ke `/app` akan di-proxy ke Vingilot
- **proxy_set_header Host**: Meneruskan hostname asli ke backend
- **proxy_set_header X-Real-IP**: Meneruskan IP address klien asli ke backend (penting untuk logging)
- **proxy_set_header X-Forwarded-For**: Meneruskan chain IP address untuk tracking
- **proxy_pass http://lindon.k25.com/**: Mengarahkan ke backend dengan trailing slash agar path di-rewrite

#### Langkah 3: Enable Site dan Buat Halaman Default
```bash
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
```

#### Langkah 4: Set Permissions dan Restart Nginx
```bash
# Node Sirion - Set permissions
chown -R www-data:www-data /var/www/sirion

# Node Sirion - Test konfigurasi dan restart
nginx -t
service nginx restart
service nginx status
```

**Screenshot yang dibutuhkan:**
- Screenshot output `nginx -t` yang menunjukkan konfigurasi valid
- Screenshot status nginx yang running

### Testing dan Verifikasi

#### Test 1: Akses Root Sirion
```bash
# Testing dari Node manapun (misal Earendil atau Cirdan)
# Test akses ke Sirion root
curl http://www.k25.com
curl http://sirion.k25.com
```

**Screenshot yang dibutuhkan:**
- Screenshot hasil curl menampilkan halaman welcome Sirion

#### Test 2: Routing ke Lindon (Static)
```bash
# Test routing ke Lindon (static)
curl http://www.k25.com/static
curl http://www.k25.com/static/annals/
```

**Screenshot yang dibutuhkan:**
- Screenshot hasil curl yang menampilkan konten dari Lindon
- Screenshot directory listing dari `/static/annals/`

#### Test 3: Routing ke Vingilot (App)
```bash
# Test routing ke Vingilot (app)
curl http://www.k25.com/app
curl http://www.k25.com/app/about
```

**Screenshot yang dibutuhkan:**
- Screenshot hasil curl yang menampilkan halaman PHP dari Vingilot
- Screenshot halaman about dari Vingilot

#### Test 4: Verifikasi Header Forwarding
```bash
# Verifikasi header diteruskan dengan benar
curl -v http://www.k25.com/static 2>&1 | grep -i "host\|x-real-ip"
curl -v http://www.k25.com/app 2>&1 | grep -i "host\|x-real-ip"
```

**Screenshot yang dibutuhkan:**
- Screenshot output curl verbose yang menunjukkan header diteruskan

## Soal 12: Basic Authentication untuk Path /admin 

### Solusi

#### Langkah 1: Install Apache2-utils
```bash
# Node Sirion
apt-get update
apt-get install -y apache2-utils
```

**Screenshot yang dibutuhkan:**
- Screenshot instalasi apache2-utils berhasil

#### Langkah 2: Buat Password File
```bash
# Buat password file menggunakan htpasswd
htpasswd -c -b /etc/nginx/.htpasswd admin admin123

# Set permissions
chmod 644 /etc/nginx/.htpasswd
chown www-data:www-data /etc/nginx/.htpasswd
```

**Penjelasan Perintah:**
- **htpasswd -c**: Create new password file
- **-b**: Batch mode (password dari command line)
- Username: `admin`
- Password: `admin123`
- File disimpan di `/etc/nginx/.htpasswd`

**Screenshot yang dibutuhkan:**
- Screenshot pembuatan password file berhasil
- Screenshot isi file `.htpasswd` (cat /etc/nginx/.htpasswd)

#### Langkah 3: Update Konfigurasi Nginx dengan Basic Auth
```bash
# Konfigurasi Nginx dengan Basic Auth
cat > /etc/nginx/sites-available/www.k25.com << 'EOF'
server {
    listen 80;
    server_name www.k25.com sirion.k25.com;
    
    # Protected /admin path
    location /admin/ {
        auth_basic "Restricted Access - Admin Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        alias /var/www/sirion/admin/;
        index index.html;
    }
    
    location = /admin {
        return 301 /admin/;
    }
    
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
    
    # Default location
    location / {
        root /var/www/sirion;
        index index.html;
        try_files $uri $uri/ =404;
    }
}
EOF
```

**Penjelasan Konfigurasi:**
- **auth_basic**: Mengaktifkan Basic Authentication dengan pesan "Restricted Access - Admin Area"
- **auth_basic_user_file**: Menunjuk ke file password yang sudah dibuat
- **alias /var/www/sirion/admin/**: Directory untuk konten admin
- **location = /admin**: Redirect dari `/admin` ke `/admin/` (trailing slash)

#### Langkah 4: Buat Halaman Admin
```bash
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
```

#### Langkah 5: Set Permissions dan Reload Nginx
```bash
# Set permissions
chown -R www-data:www-data /var/www/sirion

# Test dan reload nginx
nginx -t
service nginx reload
```

**Screenshot yang dibutuhkan:**
- Screenshot nginx -t menunjukkan konfigurasi valid
- Screenshot nginx reload berhasil

### Testing dan Verifikasi

#### Test 1: Akses Tanpa Kredensial (Harus Ditolak - 401)
```bash
# Test tanpa kredensial (harus 401)
curl http://www.k25.com/admin/
```

**Expected Output:**
```
<html>
<head><title>401 Authorization Required</title></head>
<body>
<center><h1>401 Authorization Required</h1></center>
<hr><center>nginx</center>
</body>
</html>
```

**Screenshot yang dibutuhkan:**
- Screenshot curl tanpa kredensial menampilkan error 401

#### Test 2: Akses dengan Kredensial Salah (Harus Ditolak - 401)
```bash
# Test dengan kredensial salah (harus 401)
curl -u admin:wrongpass http://www.k25.com/admin/
```

**Screenshot yang dibutuhkan:**
- Screenshot curl dengan password salah menampilkan error 401

#### Test 3: Akses dengan Kredensial Benar (Harus Berhasil - 200 OK)
```bash
# Test dengan kredensial benar (harus 200 OK)
curl -u admin:admin123 http://www.k25.com/admin/
```

**Expected Output:**
Halaman HTML admin panel lengkap.

**Screenshot yang dibutuhkan:**
- Screenshot curl dengan kredensial benar menampilkan halaman admin
- Screenshot browser menampilkan prompt login Basic Auth
- Screenshot halaman admin setelah login berhasil

#### Test 4: Path Lain Tidak Terproteksi
```bash
# Test path lain tidak terproteksi
curl http://www.k25.com/
curl http://www.k25.com/static
curl http://www.k25.com/app
```

**Screenshot yang dibutuhkan:**
- Screenshot akses ke path lain tanpa autentikasi berhasil

## Soal 13: Kanonisasi Hostname dengan Redirect 301

### Solusi

#### Konfigurasi Redirect 301
```bash
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
```

**Penjelasan Konfigurasi:**

**Server Block Pertama (Redirect):**
- **server_name 10.76.3.2 sirion.k25.com**: Menangkap request dari IP address dan hostname non-kanonik
- **return 301 http://www.k25.com$request_uri**: Melakukan permanent redirect (301) ke hostname kanonik dengan mempertahankan path asli

**Server Block Kedua (Kanonik):**
- **server_name www.k25.com**: Hanya menerima request dari hostname kanonik
- Semua konfigurasi service (admin, static, app) berada di server block ini

#### Reload Nginx
```bash
# Test dan reload nginx
nginx -t
service nginx reload
```

**Screenshot yang dibutuhkan:**
- Screenshot nginx -t berhasil
- Screenshot nginx reload

### Testing dan Verifikasi

#### Test 1: Akses via IP Address
```bash
# Harus redirect 301 ke www.k25.com
curl -I http://10.76.3.2/
```

**Expected Output:**
```
HTTP/1.1 301 Moved Permanently
Server: nginx
Location: http://www.k25.com/
```

**Screenshot yang dibutuhkan:**
- Screenshot curl -I dari IP menunjukkan redirect 301
- Screenshot header Location mengarah ke www.k25.com

#### Test 2: Akses via sirion.k25.com
```bash
# Harus redirect 301 ke www.k25.com
curl -I http://sirion.k25.com/
```

**Expected Output:**
```
HTTP/1.1 301 Moved Permanently
Server: nginx
Location: http://www.k25.com/
```

**Screenshot yang dibutuhkan:**
- Screenshot curl -I dari sirion.k25.com menunjukkan redirect 301

#### Test 3: Akses via www.k25.com
```bash
# Langsung OK tanpa redirect
curl -I http://www.k25.com/
```

**Expected Output:**
```
HTTP/1.1 200 OK
Server: nginx
Content-Type: text/html
```

**Screenshot yang dibutuhkan:**
- Screenshot curl -I dari www.k25.com menunjukkan 200 OK (tanpa redirect)

#### Test 4: Redirect dengan Path
```bash
# Redirect mempertahankan path
curl -I http://10.76.3.2/static
curl -I http://sirion.k25.com/app
```

**Expected Output:**
```
HTTP/1.1 301 Moved Permanently
Location: http://www.k25.com/static

HTTP/1.1 301 Moved Permanently
Location: http://www.k25.com/app
```

**Screenshot yang dibutuhkan:**
- Screenshot redirect dengan path mempertahankan URI asli

## Soal 14: Logging IP Klien Asli di Vingilot

### Solusi

#### Update Konfigurasi Nginx di Vingilot
```bash
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
```

**Penjelasan Konfigurasi:**

1. **log_format real_ip**: Custom log format yang mencatat:
   - `$remote_addr`: IP yang dilihat Nginx (setelah di-set dari X-Real-IP)
   - `$http_x_real_ip`: Header X-Real-IP dari Sirion
   - Format lengkap termasuk timestamp, request, status, dll

2. **set_real_ip_from 10.76.3.2**: Nginx akan trust header X-Real-IP dari IP Sirion (10.76.3.2)

3. **real_ip_header X-Real-IP**: Gunakan header X-Real-IP sebagai sumber IP asli

4. **real_ip_recursive on**: Rekursif memproses chain X-Forwarded-For jika ada

5. **access_log dengan format real_ip**: Log menggunakan format custom yang mencatat IP asli

#### Restart Nginx
```bash
# Test konfigurasi dan restart
nginx -t
service nginx restart
```

**Screenshot yang dibutuhkan:**
- Screenshot nginx -t berhasil
- Screenshot nginx restart

#### Buat File PHP untuk Testing
```bash
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
```

### Testing dan Verifikasi

#### Test 1: Akses Langsung ke Vingilot (dari Earendil)
```bash
# Node Earendil (IP: 10.76.1.2)
curl http://vingilot.k25.com/checkip
```

**Expected:** Menampilkan IP Earendil: `10.76.1.2`

**Screenshot yang dibutuhkan:**
- Screenshot curl menampilkan IP klien yang benar (10.76.1.2)

#### Test 2: Akses via Sirion (Reverse Proxy)
```bash
# Node Earendil
curl http://www.k25.com/app/checkip
```

**Expected:** Menampilkan IP Earendil: `10.76.1.2` (bukan IP Sirion 10.76.3.2)

**Screenshot yang dibutuhkan:**
- Screenshot curl menampilkan IP asli klien (10.76.1.2), bukan IP Sirion
- Screenshot header X-Real-IP terisi dengan benar

#### Test 3: Cek Access Log
```bash
**Expected Output:**
10.76.1.2 - 10.76.1.2 - - [21/Oct/2025:10:30:45 +0000] "GET /checkip HTTP/1.0" 200 1523 "-" "curl/7.68.0"
```

**Penjelasan Log:**
- Kolom pertama `10.76.1.2`: IP yang tercatat (IP asli klien)
- Kolom kedua `10.76.1.2`: Header X-Real-IP
- Log menunjukkan IP klien asli (10.76.1.2), bukan IP Sirion (10.76.3.2)

**Screenshot yang dibutuhkan:**
- Screenshot tail access log menunjukkan IP klien asli tercatat
- Screenshot perbandingan log sebelum dan sesudah konfigurasi

#### Test 4: Testing dari Klien Berbeda
```bash
# Node Cirdan (IP: 10.76.2.2)
curl http://www.k25.com/app/checkip
```

**Expected:** Menampilkan IP Cirdan: `10.76.2.2`

**Screenshot yang dibutuhkan:**
- Screenshot akses dari klien berbeda (Cirdan) menampilkan IP yang benar

## Soal 15: Load Testing dengan ApacheBench

### Solusi

#### Langkah 1: Install ApacheBench di Elrond
```bash
# Node Elrond - Install ApacheBench
apt-get update
apt-get install -y apache2-utils
```

**Screenshot yang dibutuhkan:**
- Screenshot instalasi apache2-utils berhasil

#### Langkah 2: Benchmark Endpoint /app/
```bash
# Test 1: Benchmark endpoint /app/
echo "=========================================="
echo "Testing http://www.k25.com/app/"
echo "=========================================="
ab -n 500 -c 10 http://www.k25.com/app/
```

**Penjelasan Parameter:**
- **-n 500**: Total 500 requests
- **-c 10**: Concurrency level 10 (10 request bersamaan)

**Screenshot yang dibutuhkan:**
- Screenshot output lengkap benchmark /app/
- Screenshot fokus pada metrics penting (requests/sec, time per request, transfer rate)

#### Langkah 3: Benchmark Endpoint /static/
```bash
# Test 2: Benchmark endpoint /static/
echo "=========================================="
echo "Testing http://www.k25.com/static/"
echo "=========================================="
ab -n 500 -c 10 http://www.k25.com/static/
```

**Screenshot yang dibutuhkan:**
- Screenshot output lengkap benchmark /static/
- Screenshot fokus pada metrics penting

#### Langkah 4: Simpan Hasil ke File
```bash
# Simpan hasil ke file untuk analisis
echo "=========================================="
echo "Saving results to files..."
echo "=========================================="

ab -n 500 -c 10 http://www.k25.com/app/ > /root/benchmark_app.txt
ab -n 500 -c 10 http://www.k25.com/static/ > /root/benchmark_static.txt

echo "Results saved!"
echo "View with: cat /root/benchmark_app.txt"
echo "View with: cat /root/benchmark_static.txt"
```

#### Langkah 5: Script untuk Parse Hasil
```bash
# Node Elrond - Script untuk parse hasil benchmark
cat > /root/parse_benchmark.sh << 'EOF'
#!/bin/bash

echo "+------------------+------------------------+------------------------+"
echo "| Metric           | /app/ (Dynamic)        | /static/ (Static)      |"
echo "+------------------+------------------------+------------------------+"

# Parse hasil /app/
time_app=$(grep "Time taken for tests:" /root/benchmark_app.txt | awk '{print $5, $6}')
rps_app=$(grep "Requests per second:" /root/benchmark_app.txt | awk '{print $4}')
tpr_app=$(grep "Time per request:" /root/benchmark_app.txt | head -1 | awk '{print $4, $5}')
transfer_app=$(grep "Transfer rate:" /root/benchmark_app.txt | awk '{print $3, $4}')
failed_app=$(grep "Failed requests:" /root/benchmark_app.txt | awk '{print $3}')

# Parse hasil /static/
time_static=$(grep "Time taken for tests:" /root/benchmark_static.txt | awk '{print $5, $6}')
rps_static=$(grep "Requests per second:" /root/benchmark_static.txt | awk '{print $4}')
tpr_static=$(grep "Time per request:" /root/benchmark_static.txt | head -1 | awk '{print $4, $5}')
transfer_static=$(grep "Transfer rate:" /root/benchmark_static.txt | awk '{print $3, $4}')
failed_static=$(grep "Failed requests:" /root/benchmark_static.txt | awk '{print $3}')

printf "| %-16s | %-22s | %-22s |\n" "Total Requests" "500" "500"
printf "| %-16s | %-22s | %-22s |\n" "Concurrency" "10" "10"
printf "| %-16s | %-22s | %-22s |\n" "Time taken" "$time_app" "$time_static"
printf "| %-16s | %-22s | %-22s |\n" "Requests/sec" "$rps_app" "$rps_static"
printf "| %-16s | %-22s | %-22s |\n" "Time/request" "$tpr_app" "$tpr_static"
printf "| %-16s | %-22s | %-22s |\n" "Transfer rate" "$transfer_app" "$transfer_static"
printf "| %-16s | %-22s | %-22s |\n" "Failed requests" "$failed_app" "$failed_static"
echo "+------------------+------------------------+------------------------+"
EOF

chmod +x /root/parse_benchmark.sh
/root/parse_benchmark.sh
```

**Screenshot yang dibutuhkan:**
- Screenshot output tabel hasil benchmark yang sudah di-parse

### Hasil Benchmark (Contoh)

**Tabel Ringkasan Hasil:**

| Metric           | /app/ (Dynamic)        | /static/ (Static)      |
|------------------|------------------------|------------------------|
| Total Requests   | 500                    | 500                    |
| Concurrency      | 10                     | 10                     |
| Time taken       | 15.234 seconds         | 2.845 seconds          |
| Requests/sec     | 32.81                  | 175.75                 |
| Time/request     | 304.68 ms              | 56.90 ms               |
| Transfer rate    | 52.34 KB/sec           | 245.67 KB/sec          |
| Failed requests  | 0                      | 0                      |

**Analisis Hasil:**

1. **Performance Static vs Dynamic:**
   - Static content (~5x lebih cepat) karena tidak ada pemrosesan PHP
   - Dynamic content memerlukan PHP-FPM processing

2. **Requests per Second:**
   - Static: ~175 req/s (lebih tinggi karena hanya serve file)
   - Dynamic: ~32 req/s (lebih rendah karena PHP processing)

3. **Response Time:**
   - Static: ~57ms per request (lebih cepat)
   - Dynamic: ~305ms per request (lebih lambat karena PHP execution)

4. **Reliability:**
   - Tidak ada failed requests (0 failures)
   - Sistem stabil menangani load

**Screenshot yang dibutuhkan:**
- Screenshot tabel perbandingan lengkap
- Screenshot grafik (opsional jika ada tools visualisasi)

## Soal 16: DNS Record Migration dengan TTL

### Solusi

#### Langkah 1: Query DNS Sebelum Perubahan
```bash
# Node Earendil (atau klien lain)
echo "Query lindon.k25.com sebelum perubahan:"
dig +short lindon.k25.com
echo "Query static.k25.com (CNAME) sebelum perubahan:"
dig +short static.k25.com
```

**Expected Output:**
```
10.76.3.5
lindon.k25.com.
10.76.3.5
```

**Screenshot yang dibutuhkan:**
- Screenshot query sebelum perubahan menunjukkan IP lama (10.76.3.5)

#### Langkah 2: Ubah IP Lindon
```bash
# Node Lindon - Ubah IP dari 10.76.3.5 ke 10.76.3.15
cat > /tmp/lindon_interfaces << 'EOF'
auto eth0
iface eth0 inet static
    address 10.76.3.15
    netmask 255.255.255.0
    gateway 10.76.3.1
    up echo nameserver 10.76.3.3 > /etc/resolv.conf
    up echo nameserver 10.76.3.4 >> /etc/resolv.conf
    up echo nameserver 192.168.122.1 >> /etc/resolv.conf
EOF
```

**Screenshot yang dibutuhkan:**
- Screenshot konfigurasi interface baru di Lindon

#### Langkah 3: Update Zone File dengan TTL 30 Detik
```bash
# Node Tirion - Update zone file dengan IP baru dan TTL 30 detik
cat > /etc/bind/zones/db.k25.com << 'EOF'
;
; BIND data file for k25.com
;
$TTL    604800
@       IN      SOA     ns1.k25.com. admin.k25.com. (
                              2025101104         ; Serial (DINAIKKAN!)
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
lindon.k25.com.     30      IN      A       10.76.3.15    ; IP BARU dengan TTL 30 detik
vingilot.k25.com.   IN      A       10.76.3.6

; CNAME Records untuk layanan
www.k25.com.        IN      CNAME   sirion.k25.com.
static.k25.com.     30      IN      CNAME   lindon.k25.com.    ; TTL 30 detik
app.k25.com.        IN      CNAME   vingilot.k25.com.
EOF
```

**Penjelasan Perubahan:**
- **Serial dinaikkan**: Dari 2025101103 ke 2025101104 (wajib untuk trigger zone transfer)
- **lindon.k25.com TTL 30**: IP diubah dari 10.76.3.5 ke 10.76.3.15 dengan TTL 30 detik
- **static.k25.com TTL 30**: CNAME juga diberi TTL 30 detik agar propagasi cepat

**Screenshot yang dibutuhkan:**
- Screenshot zone file yang sudah diupdate

#### Langkah 4: Validasi dan Restart BIND9
```bash
# Node Tirion
named-checkzone k25.com /etc/bind/zones/db.k25.com
if [ $? -eq 0 ]; then
    echo "Zone file valid!"
    service named restart
    echo "BIND9 restarted di Tirion"
else
    echo "ERROR: Zone file tidak valid!"
    exit 1
fi
```

**Screenshot yang dibutuhkan:**
- Screenshot named-checkzone berhasil
- Screenshot service restart

#### Langkah 5: Verifikasi Sinkronisasi ke Valmar
```bash
echo ""
echo "Menunggu sinkronisasi ke Valmar (ns2)..."
sleep 5

# Cek SOA serial di Tirion
dig @10.76.3.3 k25.com SOA +short | awk '{print $3}'

# Cek SOA serial di Valmar
dig @10.76.3.4 k25.com SOA +short | awk '{print $3}'
```

**Expected:** Kedua nameserver menunjukkan serial yang sama: `2025101104`

**Screenshot yang dibutuhkan:**
- Screenshot SOA serial di ns1 dan ns2 sama

### Testing 3 Momen (Propagasi DNS)

#### Momen 1: Sebelum Perubahan (Alamat Lama)
```bash
# Testing dari Node Earendil - SEBELUM perubahan
dig +short lindon.k25.com
dig +short static.k25.com
```

**Expected Output:**
```
10.76.3.5
lindon.k25.com.
10.76.3.5
```

**Screenshot yang dibutuhkan:**
- Screenshot query menunjukkan IP lama (10.76.3.5)

#### Momen 2: Sesaat Setelah Perubahan (Cache Belum Expire)
```bash
# Testing dari Node Earendil - 15 detik setelah perubahan
sleep 15

dig +short lindon.k25.com
dig +short static.k25.com
```

**Expected Output:** Masih menunjukkan IP lama karena cache belum expire
```
10.76.3.5
lindon.k25.com.
10.76.3.5
```

**Screenshot yang dibutuhkan:**
- Screenshot query masih menunjukkan IP lama (masih di-cache)
- Screenshot timestamp untuk bukti waktu

#### Momen 3: Setelah TTL Expire (Alamat Baru)
```bash
# Testing dari Node Earendil - Setelah 30 detik (TTL expired)
sleep 20  # Total 35 detik dari perubahan

dig +short lindon.k25.com
dig +short static.k25.com
```

**Expected Output:** Sekarang menunjukkan IP baru
```
10.76.3.15
lindon.k25.com.
10.76.3.15
```

**Screenshot yang dibutuhkan:**
- Screenshot query menunjukkan IP baru (10.76.3.15)
- Screenshot timestamp untuk bukti waktu setelah TTL expire

#### Visualisasi Timeline:
```
T+0s   : Perubahan zone file & restart BIND9
         Query: 10.76.3.5 (dari cache lama)
         
T+15s  : Masih dalam TTL window
         Query: 10.76.3.5 (masih cache)
         
T+35s  : TTL sudah expire (> 30 detik)
         Query: 10.76.3.15 (IP baru!)
```

### Verifikasi CNAME Following
```bash
# Verifikasi static.k25.com mengikuti lindon.k25.com
dig static.k25.com

# Output harus menunjukkan:
# static.k25.com. 30 IN CNAME lindon.k25.com.
# lindon.k25.com. 30 IN A 10.76.3.15
```

**Screenshot yang dibutuhkan:**
- Screenshot full dig output menunjukkan CNAME chain
- Screenshot TTL countdown

## Soal 17: Service Autostart Configuration

### Solusi

#### Node Tirion (ns1) - Autostart BIND9
```bash
# TIRION
cat > /etc/init.d/autostart-tirion << 'EOF'
#!/bin/bash
/usr/sbin/named -u bind
EOF

chmod +x /etc/init.d/autostart-tirion
update-rc.d autostart-tirion defaults
```

**Penjelasan:**
- Script init.d untuk menjalankan BIND9 saat boot
- `/usr/sbin/named -u bind`: Start BIND9 daemon sebagai user bind
- `update-rc.d`: Register script ke runlevel startup

**Screenshot yang dibutuhkan:**
- Screenshot pembuatan script autostart
- Screenshot update-rc.d berhasil

#### Node Valmar (ns2) - Autostart BIND9
```bash
# VALMAR
cat > /etc/init.d/autostart-valmar << 'EOF'
#!/bin/bash
/usr/sbin/named -u bind
EOF

chmod +x /etc/init.d/autostart-valmar
update-rc.d autostart-valmar defaults
```

**Screenshot yang dibutuhkan:**
- Screenshot konfigurasi autostart Valmar

#### Node Sirion - Autostart Nginx
```bash
# SIRION
cat > /etc/init.d/autostart-sirion << 'EOF'
#!/bin/bash
/usr/sbin/nginx
EOF

chmod +x /etc/init.d/autostart-sirion
update-rc.d autostart-sirion defaults
```

**Screenshot yang dibutuhkan:**
- Screenshot konfigurasi autostart Sirion

#### Node Lindon - Autostart Nginx
```bash
# LINDON
cat > /etc/init.d/autostart-lindon << 'EOF'
#!/bin/bash
/usr/sbin/nginx
EOF

chmod +x /etc/init.d/autostart-lindon
update-rc.d autostart-lindon defaults
```

**Screenshot yang dibutuhkan:**
- Screenshot konfigurasi autostart Lindon

#### Node Vingilot - Autostart PHP-FPM dan Nginx
```bash
# VINGILOT
cat > /etc/init.d/autostart-vingilot << 'EOF'
#!/bin/bash
/usr/sbin/php-fpm8.4
/usr/sbin/nginx
EOF

chmod +x /etc/init.d/autostart-vingilot
update-rc.d autostart-vingilot defaults
```

**Penjelasan:**
- Vingilot memerlukan 2 service: PHP-FPM (untuk dynamic content) dan Nginx (web server)
- PHP-FPM harus start sebelum Nginx

**Screenshot yang dibutuhkan:**
- Screenshot konfigurasi autostart Vingilot

### Testing Autostart

#### Metode 1: Reboot Simulation (Tanpa Benar-benar Reboot)
```bash
# Stop semua service
service named stop      # di Tirion & Valmar
service nginx stop      # di Sirion, Lindon, Vingilot
service php8.4-fpm stop # di Vingilot

# Jalankan script autostart manual
/etc/init.d/autostart-tirion
/etc/init.d/autostart-valmar
/etc/init.d/autostart-sirion
/etc/init.d/autostart-lindon
/etc/init.d/autostart-vingilot
```

**Screenshot yang dibutuhkan:**
- Screenshot service stopped
- Screenshot script autostart dijalankan

#### Metode 2: Verifikasi Service Running
```bash
# TESTING: (dari client, setelah semua node dikonfig)
dig k25.com +short
dig www.k25.com +short
curl -s http://static.k25.com | head -1
curl -s http://app.k25.com | head -1
```

**Expected Output:**
```bash
# dig k25.com +short
10.76.3.2

# dig www.k25.com +short
sirion.k25.com.
10.76.3.2

# curl static.k25.com
<h1>Welcome to Lindon - Static Archives</h1>

# curl app.k25.com
<!DOCTYPE html>...Vingilot...
```

**Screenshot yang dibutuhkan:**
- Screenshot dig queries berhasil (DNS working)
- Screenshot curl static berhasil (Nginx di Lindon working)
- Screenshot curl app berhasil (PHP-FPM & Nginx di Vingilot working)

#### Metode 3: Check Service Status
```bash
# Node Tirion
ps aux | grep named

# Node Sirion
ps aux | grep nginx

# Node Vingilot
ps aux | grep php-fpm
ps aux | grep nginx
```

**Screenshot yang dibutuhkan:**
- Screenshot process list menunjukkan service running

### Verifikasi Lengkap Semua Service

#### Test DNS (Tirion & Valmar)
```bash
# dari klien manapun
dig @10.76.3.3 k25.com  # ns1 (Tirion)
dig @10.76.3.4 k25.com  # ns2 (Valmar)
```

**Screenshot yang dibutuhkan:**
- Screenshot query ke ns1 berhasil
- Screenshot query ke ns2 berhasil

#### Test Web Static (Lindon)
```bash
curl -I http://static.k25.com
curl http://static.k25.com/annals/
```

**Screenshot yang dibutuhkan:**
- Screenshot HTTP response dari Lindon

#### Test Web Dynamic (Vingilot)
```bash
curl -I http://app.k25.com
curl http://app.k25.com/about
```

**Screenshot yang dibutuhkan:**
- Screenshot HTTP response dari Vingilot
- Screenshot PHP content rendered

#### Test Reverse Proxy (Sirion)
```bash
curl -I http://www.k25.com
curl -I http://www.k25.com/static
curl -I http://www.k25.com/app
```

**Screenshot yang dibutuhkan:**
- Screenshot routing ke backend bekerja

### Alternative: Systemd Service (Modern Approach)
Jika menggunakan systemd (lebih modern), bisa gunakan:

```bash
# Enable service startup
systemctl enable bind9      # Tirion & Valmar
systemctl enable nginx      # Sirion, Lindon, Vingilot
systemctl enable php8.4-fpm # Vingilot

# Check status
systemctl status bind9
systemctl status nginx
systemctl status php8.4-fpm
```

## Soal 18: TXT Record dan CNAME Alias

### Solusi

#### Update Zone File di Tirion
```bash
# Node Tirion - Update zona
cat > /etc/bind/zones/db.k25.com << 'EOF'
$TTL    604800
@       IN      SOA     ns1.k25.com. admin.k25.com. (
                              2025101105         ; Serial (DINAIKKAN!)
                              604800         ; Refresh
                              86400         ; Retry
                              2419200         ; Expire
                              604800 )       ; Negative Cache TTL
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

; TXT Record dan CNAME untuk Melkor/Morgoth
melkor.k25.com.     IN      TXT     "Morgoth (Melkor)"
morgoth.k25.com.    IN      CNAME   melkor.k25.com.
EOF
```

**Penjelasan:**
- **Serial dinaikkan**: 2025101104 → 2025101105 (untuk trigger zone transfer)
- **TXT Record**: `melkor.k25.com` berisi text "Morgoth (Melkor)"
- **CNAME**: `morgoth.k25.com` adalah alias ke `melkor.k25.com`

**Screenshot yang dibutuhkan:**
- Screenshot zone file dengan TXT dan CNAME baru

#### Validasi dan Restart BIND9
```bash
# Node Tirion
named-checkzone k25.com /etc/bind/zones/db.k25.com
service named restart
```

**Screenshot yang dibutuhkan:**
- Screenshot named-checkzone berhasil

#### Sinkronisasi ke Valmar
```bash
# Node Valmar - Force sync
rndc retransfer k25.com
sleep 3
```

**Screenshot yang dibutuhkan:**
- Screenshot zone transfer berhasil

### Testing dan Verifikasi

#### Test 1: Query TXT Record langsung ke melkor.k25.com
```bash
dig melkor.k25.com TXT +short
```

**Expected Output:**
```
"Morgoth (Melkor)"
```

**Screenshot yang dibutuhkan:**
- Screenshot dig TXT mengembalikan text "Morgoth (Melkor)"

#### Test 2: Query TXT via CNAME (morgoth.k25.com)
```bash
dig morgoth.k25.com TXT +short
```

**Expected Output:**
```
"Morgoth (Melkor)"
```

**Penjelasan:** Query TXT ke morgoth akan follow CNAME ke melkor, lalu return TXT record

**Screenshot yang dibutuhkan:**
- Screenshot query TXT via CNAME berhasil

#### Test 3: Query CNAME Record
```bash
dig morgoth.k25.com CNAME +short
```

**Expected Output:**
```
melkor.k25.com.
```

**Screenshot yang dibutuhkan:**
- Screenshot CNAME resolution

#### Test 4: Full Query (Tanpa +short)
```bash
dig morgoth.k25
```

**Expected Output:**
```
; <<>> DiG 9.x.x <<>> morgoth.k25.com TXT
;; ANSWER SECTION:
morgoth.k25.com.        604800  IN      CNAME   melkor.k25.com.
melkor.k25.com.         604800  IN      TXT     "Morgoth (Melkor)"
```

**Penjelasan Output:**
- Baris pertama: CNAME record menunjukkan morgoth → melkor
- Baris kedua: TXT record dari melkor berisi "Morgoth (Melkor)"
- Query TXT mengikuti CNAME chain secara otomatis

**Screenshot yang dibutuhkan:**
- Screenshot full dig output menunjukkan CNAME chain dan TXT record

#### Test 5: Query dari Nameserver Berbeda
```bash
# Query ke ns1 (Tirion)
dig @10.76.3.3 melkor.k25.com TXT +short

# Query ke ns2 (Valmar)
dig @10.76.3.4 melkor.k25.com TXT +short

# Keduanya harus return: "Morgoth (Melkor)"
```

**Screenshot yang dibutuhkan:**
- Screenshot query ke ns1 dan ns2 konsisten

## Soal 19: Additional CNAME Alias

### Solusi

#### Langkah 1: Update Zone File di Tirion
```bash
# Node Tirion - Update zona
cat > /etc/bind/zones/db.k25.com << 'EOF'
$TTL    604800
@       IN      SOA     ns1.k25.com. admin.k25.com. (
                              2025101106         ; Serial (DINAIKKAN!)
                              604800         ; Refresh
                              86400         ; Retry
                              2419200         ; Expire
                              604800 )       ; Negative Cache TTL
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
havens.k25.com.     IN      CNAME   www.k25.com.           ; CNAME BARU!

melkor.k25.com.     IN      TXT     "Morgoth (Melkor)"
morgoth.k25.com.    IN      CNAME   melkor.k25.com.
EOF
```

**Penjelasan:**
- **Serial dinaikkan**: 2025101105 → 2025101106
- **havens.k25.com**: CNAME yang mengarah ke www.k25.com
- **CNAME Chain**: havens → www → sirion → 10.76.3.2

**Screenshot yang dibutuhkan:**
- Screenshot zone file dengan CNAME baru

#### Langkah 2: Validasi dan Restart
```bash
# Node Tirion
named-checkzone k25.com /etc/bind/zones/db.k25.com
service named restart
```

**Screenshot yang dibutuhkan:**
- Screenshot named-checkzone berhasil

#### Langkah 3: Sinkronisasi ke Valmar
```bash
# Node Valmar - Force sync
rndc retransfer k25.com
```

**Screenshot yang dibutuhkan:**
- Screenshot zone transfer berhasil

#### Langkah 4: Update Nginx di Sirion (PENTING!)
```bash
# Node Sirion - Update Nginx untuk accept havens.k25.com
cat > /etc/nginx/sites-available/www.k25.com << 'EOF'
server {
    listen 80;
    server_name 10.76.3.2 sirion.k25.com;
    return 301 http://www.k25.com$request_uri;
}

server {
    listen 80;
    server_name www.k25.com havens.k25.com;    # TAMBAHKAN havens.k25.com!
    
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
```

**Penjelasan:**
- **server_name** ditambahkan `havens.k25.com` agar Nginx accept request dari hostname tersebut
- Tanpa ini, Nginx akan return default server atau 404

**Screenshot yang dibutuhkan:**
- Screenshot nginx -t berhasil
- Screenshot nginx reload

### Testing dan Verifikasi

#### Test 1: DNS Resolution
```bash
# Verifikasi CNAME chain
dig havens.k25.com +short
```

**Expected Output:**
```
www.k25.com.
sirion.k25.com.
10.76.3.2
```

**Penjelasan:** Query havens.k25.com mengikuti CNAME chain:
- havens.k25.com → www.k25.com (CNAME)
- www.k25.com → sirion.k25.com (CNAME)
- sirion.k25.com → 10.76.3.2 (A record)

**Screenshot yang dibutuhkan:**
- Screenshot dig menunjukkan CNAME chain lengkap

#### Test 2: Akses dari Klien Pertama (Earendil)
```bash
# Node Earendil (IP: 10.76.1.2)
echo "Testing dari Earendil:"

# Test homepage
curl http://havens.k25.com | head -20

# Test /static
curl http://havens.k25.com/static | head -10

# Test /app
curl http://havens.k25.com/app | head -10
```

**Expected:** Semua endpoint dapat diakses dan return content yang benar

**Screenshot yang dibutuhkan:**
- Screenshot curl homepage dari Earendil
- Screenshot curl /static berhasil
- Screenshot curl /app berhasil

#### Test 3: Akses dari Klien Kedua (Cirdan)
```bash
# Node Cirdan (IP: 10.76.2.2)
echo "Testing dari Cirdan:"

# Test homepage
curl -I http://havens.k25.com

# Test /static
curl -I http://havens.k25.com/static

# Test /app  
curl -I http://havens.k25.com/app
```

**Expected:** Semua HTTP status code 200 OK

**Screenshot yang dibutuhkan:**
- Screenshot curl dari Cirdan menunjukkan HTTP 200
- Screenshot akses berbagai path berhasil

#### Test 4: Full Query Detail
```bash
# Query detail CNAME
dig havens.k25.com

# Output harus menampilkan:
# havens.k25.com.  IN  CNAME  www.k25.com.
# www.k25.com.     IN  CNAME  sirion.k25.com.
# sirion.k25.com.  IN  A      10.76.3.2
```

**Screenshot yang dibutuhkan:**
- Screenshot full dig output dengan ANSWER SECTION

#### Test 5: Browser Access (Optional)
Jika menggunakan browser di klien:
```
http://havens.k25.com
http://havens.k25.com/static
http://havens.k25.com/app
```

**Screenshot yang dibutuhkan:**
- Screenshot browser menampilkan homepage
- Screenshot browser navigasi ke /static dan /app

### Verifikasi Cross-Client Consistency

#### Matrix Testing
| Klien     | Endpoint                    | Expected Result |
|-----------|----------------------------|-----------------|
| Earendil  | havens.k25.com             | Homepage ✓      |
| Earendil  | havens.k25.com/static      | Lindon ✓        |
| Earendil  | havens.k25.com/app         | Vingilot ✓      |
| Cirdan    | havens.k25.com             | Homepage ✓      |
| Cirdan    | havens.k25.com/static      | Lindon ✓        |
| Cirdan    | havens.k25.com/app         | Vingilot ✓      |

**Screenshot yang dibutuhkan:**
- Screenshot tabel hasil testing (bisa manual atau script)

## Soal 20: Final Homepage dengan Navigation

### Solusi

#### Langkah 1: Buat Homepage yang Menarik
```bash
# Node Sirion - Buat homepage
cat > /var/www/sirion/index.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>War of Wrath: Lindon Bertahan</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 50%, #7e22ce 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            color: white;
            padding: 20px;
        }
        .container { max-width: 900px; width: 100%; }
        .header {
            text-align: center;
            margin-bottom: 40px;
            animation: fadeInDown 1s ease;
        }
        .header h1 {
            font-size: 3.5em;
            margin-bottom: 10px;
            text-shadow: 0 4px 6px rgba(0,0,0,0.3);
            background: linear-gradient(to right, #ffd700, #ffed4e);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .header .subtitle { font-size: 1.5em; color: #e0e7ff; margin-bottom: 15px; }
        .header .tagline { font-size: 1.1em; color: #c7d2fe; font-style: italic; }
        .content {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            margin-bottom: 30px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            animation: fadeInUp 1s ease;
        }
        .content h2 {
            color: #ffd700;
            margin-bottom: 20px;
            font-size: 2em;
            border-bottom: 2px solid rgba(255, 215, 0, 0.3);
            padding-bottom: 10px;
        }
        .content p { line-height: 1.8; margin-bottom: 20px; font-size: 1.1em; }
        .services {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 25px;
            margin-top: 30px;
        }
        .service-card {
            background: rgba(0, 0, 0, 0.4);
            border-radius: 12px;
            padding: 30px;
            transition: all 0.3s ease;
            border: 2px solid rgba(255, 255, 255, 0.1);
            text-align: center;
        }
        .service-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 12px 24px rgba(0, 0, 0, 0.4);
            border-color: #ffd700;
        }
        .service-card h3 { color: #ffd700; margin-bottom: 15px; font-size: 1.5em; }
        .service-card p { margin-bottom: 20px; font-size: 0.95em; color: #d0d0d0; }
        .service-card a {
            display: inline-block;
            padding: 12px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            border-radius: 25px;
            font-weight: bold;
            transition: all 0.3s ease;
            border: 2px solid transparent;
        }
        .service-card a:hover {
            background: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
            border-color: #ffd700;
            transform: scale(1.05);
        }
        .footer {
            text-align: center;
            padding: 20px;
            background: rgba(0, 0, 0, 0.3);
            border-radius: 10px;
            margin-top: 30px;
            font-size: 0.9em;
            color: #b0b0b0;
        }
        .icon { font-size: 2.5em; margin-bottom: 15px; }
        @keyframes fadeInDown {
            from { opacity: 0; transform: translateY(-30px); }
            to { opacity: 1; transform: translateY(0); }
        }
        @keyframes fadeInUp {
            from { opacity: 0; transform: translateY(30px); }
            to { opacity: 1; transform: translateY(0); }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>⚔️ War of Wrath ⚔️</h1>
            <p class="subtitle">Lindon Bertahan</p>
            <p class="tagline">Di tengah kehancuran Beleriand, harapan masih bersinar</p>
        </div>
        <div class="content">
            <h2>📜 Kisah Akhir Zaman Pertama</h2>
            <p>
                Di penghujung Zaman Pertama, Eärendil dengan Vingilot-nya membawa cahaya Silmaril 
                melintasi lautan menuju Valinor, memohon belas kasihan Valar untuk menyelamatkan 
                Beleriand dari cengkeraman Morgoth. Perang dahsyat pun pecah—War of Wrath—yang 
                menghancurkan sebagian besar daratan.
            </p>
            <p>
                Di tengah kehancuran itu, Lindon tetap berdiri. Pelabuhan Círdan menjadi harapan 
                terakhir bagi para pengungsi Eldar. Dari Sirion hingga Grey Havens, jejak peradaban 
                Elves masih dapat ditelusuri melalui arsip dan kisah yang tersimpan.
            </p>
        </div>
        <div class="services">
            <div class="service-card">
                <div class="icon">🏛️</div>
                <h3>Static Archives</h3>
                <p>Jelajahi arsip sejarah Beleriand, dokumen kuno, dan catatan para bijak di perpustakaan Lindon.</p>
                <a href="/static">Telusuri Arsip →</a>
            </div>
            <div class="service-card">
                <div class="icon">⛵</div>
                <h3>Dynamic Application</h3>
                <p>Saksikan Vingilot dalam perjalanannya melintasi langit, membawa harapan dan cahaya Silmaril.</p>
                <a href="/app">Layarkan Vingilot →</a>
            </div>
        </div>
        <div class="footer">
            <p>🌊 Sirion - Gateway of Beleriand 🌊</p>
            <p>Melayani dari tepi sungai hingga ujung laut</p>
        </div>
    </div>
</body>
</html>
EOF
```

**Penjelasan Desain:**
- **Responsive Design**: Grid layout yang menyesuaikan dengan ukuran layar
- **Gradient Background**: Visual menarik dengan warna biru-ungu
- **Hover Effects**: Interactive cards dengan animasi
- **Navigation Links**: Tautan ke `/static` dan `/app` dengan styling button
- **Storytelling**: Menceritakan lore Tolkien sesuai tema praktikum

**Screenshot yang dibutuhkan:**
- Screenshot kode HTML homepage

#### Langkah 2: Set Permissions dan Reload
```bash
chown -R www-data:www-data /var/www/sirion
nginx -t && service nginx reload
```

**Screenshot yang dibutuhkan:**
- Screenshot nginx reload berhasil

### Testing dari Semua Klien

#### Test 1: Akses Homepage dari Earendil
```bash
# Node Earendil (Klien Barat 1)
curl http://www.k25.com | grep -i "war of wrath"
```

**Expected Output:**
```
<h1>⚔️ War of Wrath ⚔️</h1>
```

**Screenshot yang dibutuhkan:**
- Screenshot curl dari Earendil menampilkan homepage
- Screenshot browser (jika ada) menampilkan halaman lengkap

#### Test 2: Akses Homepage dari Elwing
```bash
# Node Elwing (Klien Barat 2)
curl -I http://www.k25.com
```

**Expected:** HTTP/1.1 200 OK

**Screenshot yang dibutuhkan:**
- Screenshot HTTP response dari Elwing

#### Test 3: Akses Homepage dari Cirdan
```bash
# Node Cirdan (Klien Timur 1)
curl http://www.k25.com | head -30
```

**Screenshot yang dibutuhkan:**
- Screenshot curl dari Cirdan

#### Test 4: Akses Homepage dari Elrond
```bash
# Node Elrond (Klien Timur 2)
curl http://www.k25.com > /tmp/homepage.html
cat /tmp/homepage.html | grep -E "(Static Archives|Dynamic Application)"
```

**Screenshot yang dibutuhkan:**
- Screenshot dari Elrond menunjukkan links terdeteksi

#### Test 5: Akses Homepage dari Maglor
```bash
# Node Maglor (Klien Timur 3)
curl -s http://www.k25.com | grep "href"
```

**Expected:** Menampilkan href="/static" dan href="/app"

**Screenshot yang dibutuhkan:**
- Screenshot links terekstrak

### Testing Navigation Links

#### Test 6: Follow Link ke /static dari Earendil
```bash
# Node Earendil
curl -I http://www.k25.com/static
```

**Expected:** HTTP/1.1 200 OK, content dari Lindon

**Screenshot yang dibutuhkan:**
- Screenshot akses /static berhasil routing ke Lindon

#### Test 7: Follow Link ke /app dari Cirdan
```bash
# Node Cirdan
curl http://www.k25.com/app | head -20
```

**Expected:** Halaman Vingilot dynamic application

**Screenshot yang dibutuhkan:**
- Screenshot akses /app berhasil routing ke Vingilot

#### Test 8: Testing dengan Alternative Hostname (havens)
```bash
# Node Elrond
curl http://havens.k25.com | grep "War of Wrath"
curl http://havens.k25.com/static | head -5
curl http://havens.k25.com/app | head -5
```

**Screenshot yang dibutuhkan:**
- Screenshot akses via havens.k25.com juga berhasil

### Comprehensive Testing Matrix

| Klien     | Hostname         | Path     | Expected Result                |
|-----------|------------------|----------|--------------------------------|
| Earendil  | www.k25.com      | /        | Homepage ✓                     |
| Earendil  | www.k25.com      | /static  | Lindon archives ✓              |
| Earendil  | www.k25.com      | /app     | Vingilot app ✓                 |
| Elwing    | www.k25.com      | /        | Homepage ✓                     |
| Cirdan    | www.k25.com      | /        | Homepage ✓                     |
| Cirdan    | www.k25.com      | /static  | Lindon archives ✓              |
| Elrond    | www.k25.com      | /app     | Vingilot app ✓                 |
| Maglor    | havens.k25.com   | /        | Homepage via CNAME ✓           |
| Maglor    | havens.k25.com   | /app     | Vingilot via CNAME ✓           |

**Screenshot yang dibutuhkan:**
- Screenshot tabel testing hasil (dapat dibuat manual atau dengan script)

### Verifikasi No IP Access
```bash
# Verifikasi bahwa akses via hostname, BUKAN IP
# Test ini harus GAGAL atau REDIRECT:
curl -I http://10.76.3.2/

# Expected: HTTP/1.1 301 Moved Permanently
# Location: http://www.k25.com/
```

**Screenshot yang dibutuhkan:**
- Screenshot akses via IP redirect ke hostname kanonik

### Final Verification Script
```bash
# Script comprehensive test
cat > /root/final_test.sh << 'EOF'
#!/bin/bash

echo "=========================================="
echo "FINAL VERIFICATION - WAR OF WRATH PROJECT"
echo "=========================================="
echo ""

CLIENTS=("earendil" "elwing" "cirdan" "elrond" "maglor")
HOSTNAME="www.k25.com"

for client in "${CLIENTS[@]}"; do
    echo "Testing from: $client"
    echo "  - Homepage: $(curl -s -o /dev/null -w '%{http_code}' http://$HOSTNAME)"
    echo "  - /static:  $(curl -s -o /dev/null -w '%{http_code}' http://$HOSTNAME/static)"
    echo "  - /app:     $(curl -s -o /dev/null -w '%{http_code}' http://$HOSTNAME/app)"
    echo ""
done

echo "=========================================="
echo "All tests completed!"
echo "=========================================="
EOF

chmod +x /root/final_test.sh
/root/final_test.sh
```
