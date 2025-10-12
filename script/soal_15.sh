# Node Elrond - Install ApacheBench
apt-get update
apt-get install -y apache2-utils

# Test 1: Benchmark endpoint /app/
echo "=========================================="
echo "Testing http://www.k25.com/app/"
echo "=========================================="
ab -n 500 -c 10 http://www.k25.com/app/

# Test 2: Benchmark endpoint /static/
echo "=========================================="
echo "Testing http://www.k25.com/static/"
echo "=========================================="
ab -n 500 -c 10 http://www.k25.com/static/

# Simpan hasil ke file untuk analisis
echo "=========================================="
echo "Saving results to files..."
echo "=========================================="

ab -n 500 -c 10 http://www.k25.com/app/ > /root/benchmark_app.txt
ab -n 500 -c 10 http://www.k25.com/static/ > /root/benchmark_static.txt

echo "Results saved!"
echo "View with: cat /root/benchmark_app.txt"
echo "View with: cat /root/benchmark_static.txt"

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