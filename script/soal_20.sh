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

chown -R www-data:www-data /var/www/sirion
nginx -t && service nginx reload

# Verifikasi
curl http://www.k25.com | grep -i "war of wrath"
# Expected: Muncul teks "War of Wrath"

curl -I http://www.k25.com/static
# Expected: HTTP/1.1 200 OK

curl -I http://www.k25.com/app
# Expected: HTTP/1.1 200 OK