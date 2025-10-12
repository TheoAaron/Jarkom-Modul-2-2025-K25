# Node Eonwe
echo "nameserver 192.168.122.1" > /etc/resolv.conf

auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
    address 10.15.1.1
    netmask 255.255.255.0

auto eth2
iface eth2 inet static
    address 10.15.2.1
    netmask 255.255.255.0

auto eth3
iface eth3 inet static
    address 10.15.3.1
    netmask 255.255.255.0

# Node Earendil
auto eth0
iface eth0 inet static
    address 10.15.1.2
    netmask 255.255.255.0
    gateway 10.15.1.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Elwing
auto eth0
iface eth0 inet static
    address 10.15.1.3
    netmask 255.255.255.0
    gateway 10.15.1.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Cirdan
auto eth0
iface eth0 inet static
    address 10.15.2.2
    netmask 255.255.255.0
    gateway 10.15.2.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Elrond
auto eth0
iface eth0 inet static
    address 10.15.2.3
    netmask 255.255.255.0
    gateway 10.15.2.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Maglor
auto eth0
iface eth0 inet static
    address 10.15.2.4
    netmask 255.255.255.0
    gateway 10.15.2.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Sirion
auto eth0
iface eth0 inet static
    address 10.15.3.2
    netmask 255.255.255.0
    gateway 10.15.3.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Tirion
auto eth0
iface eth0 inet static
    address 10.15.3.3
    netmask 255.255.255.0
    gateway 10.15.3.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Valmar
auto eth0
iface eth0 inet static
    address 10.15.3.4
    netmask 255.255.255.0
    gateway 10.15.3.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Lindon
auto eth0
iface eth0 inet static
    address 10.15.3.5
    netmask 255.255.255.0
    gateway 10.15.3.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf

# Node Vingilot
auto eth0
iface eth0 inet static
    address 10.15.3.6
    netmask 255.255.255.0
    gateway 10.15.3.1
    up echo nameserver 192.168.122.1 > /etc/resolv.conf