# Node Eonwe

echo 1 > /proc/sys/net/ipv4/ip_forward

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE -s 10.76.0.0/

# Test di semua Node

ping google.com -c 2 # Tes Internet