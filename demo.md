# Panduan Demonstrasi & Verifikasi Praktikum Modul 2
**Kelompok**: K-02  
**IP Prefix**: `192.212.x.x`  
**Domain**: `k02.com`  
**Topologi**: The Mesh (14 Entitas, 5 Subnet)

---

## 1. Pemetaan Entitas & Subnet Jaringan

| Entitas | Subnet / IP | Peran Topologi | File / Layanan Kunci |
|---|---|---|---|
| **rootkit** | `192.212.1.1` s.d. `5.1` | Router Sentral / Gateway | NAT WAN (`eth0`), IP Forwarding |
| **prab** | `192.212.1.2` | Master DNS (ns1) | BIND9 Master (`k02.com`, PTR Zones) |
| **tedd** | `192.212.1.3` | Slave DNS (ns2) | BIND9 Slave (Zone Replication) |
| **obladi** | `192.212.1.4` | Area Vault 1 (Statis) | Apache2, Autoindex `/var/www/html/arsip/` |
| **desmond** | `192.212.1.5` | Area Vault 2 (Statis) | Apache2, Autoindex `/var/www/html/arsip/` |
| **oblada** | `192.212.1.6` | Area Core 1 (Dinamis) | Apache2 + PHP8.4-FPM, Rewrite `/profil` |
| **molly** | `192.212.1.7` | Area Core 2 (Dinamis) | Apache2 + PHP8.4-FPM, Rewrite `/profil` |
| **alpha, beta, gamma** | `192.212.2.2` s.d. `.4` | Klien Sayap Kiri | Testing & Resolver Internal |
| **delta, epsilon** | `192.212.3.2` s.d. `.3` | Klien Sayap Kanan | Testing & Resolver Internal |
| **abbey** | `192.212.4.2` | Gerbang Core | Nginx Reverse Proxy (Upstream Core) |
| **penny** | `192.212.5.2` | Gerbang Vault | Apache2 Reverse Proxy (Balancer Vault) |

---

## 2. Alur Demonstrasi Skrip Otomasi & Pemulihan Layanan (`/root/init.sh` & `/root/setup_*.sh`)

Seluruh konfigurasi jaringan, resolver DNS, dan service aplikasi telah diotomasi penuh menggunakan skrip shell (`.sh`) modular yang diletakkan pada direktori `/root/` di setiap node. Hal ini menjamin bahwa jika node di-restart oleh asisten praktikum, seluruh konfigurasi dan layanan akan pulih secara instan tanpa perlu dikonfigurasi ulang satu per satu.

### A. Struktur Berkas Skrip pada Direktori `/root/`
| Node | Berkas Skrip di `/root/` | Fungsi Utama Skrip |
|---|---|---|
| **Seluruh 14 Node** | `/root/init.sh` | Skrip universal: auto-detect nama host, restore interface IP, gateway, resolv.conf, & auto-start service |
| **prab** | `/root/setup_prab.sh` | Otomasi BIND9 Master untuk zona forward `k02.com` dan reverse zones (Subnet 1, 4, 5) |
| **tedd** | `/root/setup_tedd.sh` | Otomasi BIND9 Slave untuk replikasi seluruh zona forward dan reverse dari master |
| **Host Non-Router** | `/root/update_resolvers.sh` | Otomasi pembaruan resolver internal: `192.212.1.2` -> `192.212.1.3` -> `192.168.122.1` |
| **obladi & desmond** | `/root/setup_vault.sh` | Otomasi Apache2 Web Statis + direktori arsip autoindex `/arsip/` |
| **oblada & molly** | `/root/setup_core.sh` | Otomasi Apache2 + PHP8.4-FPM + mod_rewrite Clean URL `/profil` |
| **penny** | `/root/setup_proxy.sh` | Otomasi Apache2 Reverse Proxy & Round-Robin Load Balancer ke Area Vault |
| **abbey** | `/root/setup_proxy.sh` | Otomasi Nginx Reverse Proxy & Round-Robin Load Balancer ke Area Core |

### B. Cara Menunjukkan Skrip Otomasi Saat Sesi Demo
1. **Menunjukkan daftar skrip otomasi yang ada di node**:
   ```bash
   ls -la /root/*.sh
   ```
2. **Menampilkan isi logika skrip otomasi ke layar terminal**:
   ```bash
   # Menampilkan skrip inisialisasi universal:
   cat /root/init.sh

   # Menampilkan skrip instalasi/konfigurasi layanan spesifik:
   cat /root/setup_<nama_layanan>.sh
   ```
3. **Menunjukkan persistensi auto-start pada antarmuka jaringan**:
   Tunjukkan baris `up service ...` atau `post-up ...` pada `/etc/network/interfaces`:
   ```bash
   cat /etc/network/interfaces
   ```
   *Setiap kali interface jaringan aktif saat booting, hook `up` otomatis memicu service terkait (BIND9, Apache2, Nginx, PHP-FPM, NAT) sehingga langsung berjalan di background.*
4. **Mendemonstrasikan auto-recovery instan (Live Demo)**:
   Jika asisten ingin menguji bagaimana node memulihkan seluruh konfigurasi dan layanan dari awal:
   ```bash
   bash /root/init.sh
   ```
   *Skrip akan secara otomatis mendeteksi nama node, menerapkan IP, gateway, resolver, dan menyalakan semua daemon service dalam 1-2 detik.*

---

## Soal 1: Penetapan Alamat IP & Default Gateway Seluruh Entitas

### 1. Berkas Konfigurasi & Script
- **Lokasi Script**: `/root/init.sh` pada seluruh node.
- **Konfigurasi Interface**: `/etc/network/interfaces`

```bash
# Inspeksi konfigurasi router (rootkit):
cat /etc/network/interfaces

# Inspeksi konfigurasi host klien (alpha):
cat /etc/network/interfaces
cat /root/init.sh
```

### 2. Parameter Kunci Konfigurasi
- **Node `rootkit`**:
  - `eth0`: DHCP (terhubung ke NAT WAN `192.168.122.x/24`).
  - `eth1` s.d. `eth5`: Static IP `192.212.1.1/24` s.d. `192.212.5.1/24`.
- **Node Non-Router (Host)**:
  - Alamat IP statis sesuai subnet masing-masing entitas dengan subnet mask `/24` (`255.255.255.0`).
  - Default gateway menunjuk ke alamat IP `rootkit` pada subnet tersebut (misal: `alpha` gateway `192.212.2.1`).

### 3. Perintah Verifikasi & Validasi
```bash
# Pada node rootkit (memastikan seluruh interface aktif):
ip -br a

# Pada node klien (alpha):
ip a show eth0
ip route show
```

### 4. Ekspektasi Output
- Interface `eth0` pada node `alpha` memiliki IP `192.212.2.2/24`.
- Tabel perutean menampilkan:
  ```text
  default via 192.212.2.1 dev eth0
  192.212.2.0/24 dev eth0 proto kernel scope link src 192.212.2.2
  ```

---

## Soal 2: Konfigurasi NAT WAN Forwarding via IP

### 1. Berkas Konfigurasi & Script
- **Lokasi Script**: `/root/init.sh` di `rootkit`.
- **Konfigurasi Interface**: `/etc/network/interfaces` di `rootkit`.

```bash
# Pada node rootkit:
sysctl net.ipv4.ip_forward
iptables -t nat -L -v -n
grep -A 5 "iface eth0" /etc/network/interfaces
```

### 2. Parameter Kunci Konfigurasi
- Kernel IPv4 Forwarding diaktifkan: `net.ipv4.ip_forward = 1`.
- NAT Masquerade pada interface WAN (`eth0`):
  ```bash
  iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  ```
- Persistensi dikonfigurasi pada direktif `post-up` di `/etc/network/interfaces`.

### 3. Perintah Verifikasi & Validasi
```bash
# Pada node klien (alpha / delta):
ping -c 3 8.8.8.8
```

### 4. Ekspektasi Output
- Ping ke IP publik `8.8.8.8` dari node internal menerima *reply* dengan packet loss 0%:
  ```text
  3 packets transmitted, 3 received, 0% packet loss, time ...
  rtt min/avg/max/mdev = ... ms
  ```

---

## Soal 3: Routing Internal Antar Subnet & Initial Resolver

### 1. Berkas Konfigurasi & Script
- **Konfigurasi Resolver Awal**: `/etc/resolv.conf` di seluruh node non-router.
- **Konfigurasi Persistensi**: `/etc/network/interfaces` dan `/root/init.sh`.

```bash
# Pada node klien (alpha):
cat /etc/resolv.conf
```

### 2. Parameter Kunci Konfigurasi
- Seluruh subnet internal (`192.212.1.0/24` s.d. `192.212.5.0/24`) saling terhubung langsung melalui routing internal router `rootkit`.
- Resolver awal disetel mengarah ke nameserver gateway NAT `192.168.122.1` tanpa menambahkan resolver publik seperti Google, sesuai instruksi awal modul.

### 3. Perintah Verifikasi & Validasi
```bash
# Pada node klien (alpha - Subnet 2):
# 1. Uji komunikasi internal antar subnet:
ping -c 2 192.212.1.2    # Ke prab (Subnet 1)
ping -c 2 192.212.4.2    # Ke abbey (Subnet 4)
ping -c 2 192.212.5.2    # Ke penny (Subnet 5)

# 2. Uji resolusi domain internet awal:
ping -c 2 google.com
```

### 4. Ekspektasi Output
- Seluruh ping antar subnet sukses tanpa *packet loss*.
- Ping ke `google.com` berhasil melakukan translasi DNS via `192.168.122.1` dan merespons paket ICMP.

---

## Soal 4: Authoritative DNS Master (`prab`) & Slave (`tedd`) Zona `k02.com`

### 1. Berkas Konfigurasi & Script
- **Node `prab` (Master)**:
  - Script: `/root/setup_prab.sh`
  - Deklarasi Zona: `/etc/bind/named.conf.local`
  - Konfigurasi Opsi: `/etc/bind/named.conf.options`
  - Berkas Basis Data Zona: `/etc/bind/k02/db.k02.com`
- **Node `tedd` (Slave)**:
  - Script: `/root/setup_tedd.sh`
  - Deklarasi Zona: `/etc/bind/named.conf.local`
  - Replika Zona: `/var/cache/bind/db.k02.com`
- **Node Non-Router**:
  - Script update resolver: `/root/update_resolvers.sh`

```bash
# Inspeksi pada node prab (Master):
cat /root/setup_prab.sh
cat /etc/bind/named.conf.local
cat /etc/bind/named.conf.options
cat /etc/bind/k02/db.k02.com

# Inspeksi pada node tedd (Slave):
cat /root/setup_tedd.sh
cat /etc/bind/named.conf.local
ls -l /var/cache/bind/db.k02.com

# Inspeksi resolver pada klien (alpha):
cat /etc/resolv.conf
```

### 2. Parameter Kunci Konfigurasi
- **Master (`prab`)**:
  - `zone "k02.com"` bertipe `master`, dengan direktif `notify yes`, `also-notify { 192.212.1.3; };`, dan `allow-transfer { 192.212.1.3; };`.
  - `forwarders { 192.168.122.1; };` pada `named.conf.options`.
  - SOA menunjuk ke `prab.k02.com.` dan `root.k02.com.`.
  - Record NS menunjuk ke `prab.k02.com.` dan `tedd.k02.com.`.
  - A record apex `k02.com.` mengarah ke IP `penny` (`192.212.5.2`).
- **Slave (`tedd`)**:
  - `zone "k02.com"` bertipe `slave`, `file "/var/cache/bind/db.k02.com"`, dan `masters { 192.212.1.2; };`.
- **Urutan Resolver Klien**:
  - Urutan mutlak: `192.212.1.2` (prab) $\rightarrow$ `192.212.1.3` (tedd) $\rightarrow$ `192.168.122.1`.

### 3. Perintah Verifikasi & Validasi
```bash
# 1. Query langsung ke Master (prab):
dig @192.212.1.2 k02.com

# 2. Query langsung ke Slave (tedd):
dig @192.212.1.3 k02.com

# 3. Query domain apex dari klien (alpha):
dig k02.com +short
ping -c 2 k02.com
```

### 4. Ekspektasi Output
- Bagian `flags` pada output `dig` memuat flag `aa` (*Authoritative Answer*).
- Bagian `ANSWER SECTION` mengembalikan alamat IP `192.212.5.2` (penny).
- Klien `alpha` dapat me-resolve dan melakukan ping langsung ke domain apex `k02.com`.

---

## Soal 5: Hostname System-Wide & Subdomain Setiap Node

### 1. Berkas Konfigurasi & Script
- **Hostname Lokal**: `/etc/hostname` dan `/etc/hosts` di semua host.
- **Berkas Zona Master**: `/etc/bind/k02/db.k02.com` di `prab`.

```bash
# Inspeksi hostname pada node (contoh: alpha & abbey):
hostname
cat /etc/hostname

# Inspeksi skrip otomasi BIND9 Master:
cat /root/setup_prab.sh

# Inspeksi daftar A record entitas pada prab:
grep -E "IN\s+A" /etc/bind/k02/db.k02.com
```

### 2. Parameter Kunci Konfigurasi
- Seluruh 14 entitas dikonfigurasi identitas hostname-nya secara *system-wide* (`/etc/hostname`).
- Berkas zona `k02.com` memuat A record untuk masing-masing entitas:
  - `alpha` (`192.212.2.2`), `beta` (`.3`), `gamma` (`.4`)
  - `delta` (`192.212.3.2`), `epsilon` (`.3`)
  - `abbey` (`192.212.4.2`), `penny` (`192.212.5.2`)
  - `obladi` (`192.212.1.4`), `desmond` (`.5`), `oblada` (`.6`), `molly` (`.7`), `rootkit` (`.1`)

### 3. Perintah Verifikasi & Validasi
```bash
# Pada terminal klien (alpha / beta):
ping -c 1 alpha.k02.com
ping -c 1 beta.k02.com
ping -c 1 abbey.k02.com
ping -c 1 penny.k02.com
ping -c 1 obladi.k02.com
ping -c 1 oblada.k02.com
```

### 4. Ekspektasi Output
- Seluruh hostname subdomain entitas berhasil di-resolve ke IP target masing-masing dengan 0% packet loss.

---

## Soal 6: Sinkronisasi Replikasi Zone Transfer & Kesamaan Serial SOA Master (Prab) dan Slave (Tedd)

### 1. Berkas Konfigurasi & Script
- **Master (`prab`)**: `/etc/bind/k02/db.k02.com` dan `/root/setup_prab.sh`
- **Slave (`tedd`)**: `/var/cache/bind/db.k02.com` dan `/root/setup_tedd.sh`

```bash
# Inspeksi skrip otomasi konfigurasi BIND9 Master & Slave:
cat /root/setup_prab.sh
cat /root/setup_tedd.sh

# Periksa status daemon named:
service named status
```

### 2. Parameter Kunci Konfigurasi
- Pada node `prab`, zona `k02.com` dikonfigurasikan dengan `notify yes;`, `also-notify { 192.212.1.3; };`, dan `allow-transfer { 192.212.1.3; };`.
- Pada node `tedd`, zona `k02.com` dikonfigurasikan sebagai `type slave;` yang menarik salinan zona dari master `192.212.1.2`.
- Nilai serial SOA pada Master dan Slave harus identik (sama persis), membuktikan replikasi berlangsung sukses tanpa desinkronisasi.

### 3. Perintah Verifikasi & Validasi
```bash
# Query serial SOA langsung ke Master (prab):
dig @192.212.1.2 SOA k02.com +short

# Query serial SOA langsung ke Slave (tedd):
dig @192.212.1.3 SOA k02.com +short
```

### 4. Ekspektasi Output
- Output serial SOA pada Master (`prab`) dan Slave (`tedd`) bernilai sama persis:
  ```text
  prab.k02.com. root.k02.com. 2026092803 604800 86400 2419200 604800
  ```

---

## Soal 7: Round-Robin A Records untuk Vault & Core + CNAME `www` & `static`

### 1. Berkas Konfigurasi & Script
- **Berkas Zona Master**: `/etc/bind/k02/db.k02.com` di `prab`.

```bash
# Inspeksi record round-robin dan CNAME pada prab:
grep -E "vault|core|www|static" /etc/bind/k02/db.k02.com
```

### 2. Parameter Kunci Konfigurasi
- **Round-Robin A Records**:
  - `vault.k02.com.` memiliki 2 A record: `192.212.1.4` (obladi) dan `192.212.1.5` (desmond).
  - `core.k02.com.` memiliki 2 A record: `192.212.1.6` (oblada) dan `192.212.1.7` (molly).
- **CNAME Records**:
  - `www.k02.com.` $
ightarrow$ `penny.k02.com.`
  - `static.k02.com.` $
ightarrow$ `abbey.k02.com.`
- Serial SOA dinaikkan menjadi `2026092803`.

### 3. Perintah Verifikasi & Validasi
Pengujian dijalankan dari dua klien berbeda (`alpha` dan `delta`):

```bash
# Pada klien alpha (Subnet 2):
dig vault.k02.com +short
dig core.k02.com +short
dig www.k02.com
dig static.k02.com

# Pada klien delta (Subnet 3):
dig vault.k02.com +short
dig core.k02.com +short
dig www.k02.com +short
dig static.k02.com +short
```

### 4. Ekspektasi Output
- Query `vault.k02.com` mengembalikan sepasang IP: `192.212.1.4` dan `192.212.1.5`.
- Query `core.k02.com` mengembalikan sepasang IP: `192.212.1.6` dan `192.212.1.7`.
- Query `www.k02.com` mengembalikan CNAME `penny.k02.com.` yang meresolusi IP `192.212.5.2`.
- Query `static.k02.com` mengembalikan CNAME `abbey.k02.com.` yang meresolusi IP `192.212.4.2`.
- Hasil konsisten pada kedua klien.

---

## Soal 8: Reverse DNS Zones & PTR Records (Authoritative)

### 1. Berkas Konfigurasi & Script
- **Master (`prab`)**:
  - `/etc/bind/named.conf.local`
  - `/etc/bind/k02/db.192.212.1` (Subnet 1)
  - `/etc/bind/k02/db.192.212.4` (Subnet 4)
  - `/etc/bind/k02/db.192.212.5` (Subnet 5)
- **Slave (`tedd`)**:
  - `/etc/bind/named.conf.local`
  - `/var/cache/bind/db.192.212.*`

```bash
# Inspeksi skrip otomasi konfigurasi BIND9 Master & Slave:
cat /root/setup_prab.sh
cat /root/setup_tedd.sh

# Inspeksi deklarasi zona reverse di prab dan tedd:
cat /etc/bind/named.conf.local

# Inspeksi berkas PTR di prab:
cat /etc/bind/k02/db.192.212.1
cat /etc/bind/k02/db.192.212.4
cat /etc/bind/k02/db.192.212.5

# Verifikasi replikasi berkas slave pada tedd:
ls -l /var/cache/bind/
```

### 2. Parameter Kunci Konfigurasi
- Zona reverse dideklarasikan untuk:
  - `1.212.192.in-addr.arpa`: PTR untuk obladi (.4), desmond (.5), oblada (.6), molly (.7), prab (.2), tedd (.3), rootkit (.1).
  - `4.212.192.in-addr.arpa`: PTR untuk abbey (.2), rootkit (.1).
  - `5.212.192.in-addr.arpa`: PTR untuk penny (.2), rootkit (.1).
- Seluruh zona ditarik oleh slave `tedd` dan menjawab query dengan status authoritative.

### 3. Perintah Verifikasi & Validasi
```bash
# 1. Query reverse authoritative langsung ke Slave (tedd):
dig @192.212.1.3 -x 192.212.5.2    # IP penny
dig @192.212.1.3 -x 192.212.4.2    # IP abbey

# 2. Uji utilitas pencarian balik host dari klien (alpha / beta):
host 192.212.4.2
host 192.212.5.2
host 192.212.1.4
host 192.212.1.6
```

### 4. Ekspektasi Output
- Output `dig -x` pada `tedd` memiliki status `NOERROR` dan memuat flag `aa` (*Authoritative Answer*).
- Hasil perintah `host`:
  - `192.212.4.2` pointer `abbey.k02.com.`
  - `192.212.5.2` pointer `penny.k02.com.`
  - `192.212.1.4` pointer `obladi.k02.com.`
  - `192.212.1.6` pointer `oblada.k02.com.`

---

## Soal 9: Layanan Web Statis Apache & Autoindex Direktori `/arsip/` pada Area Vault

### 1. Berkas Konfigurasi & Script
- **Lokasi Script**: `/root/setup_vault.sh` pada `obladi` dan `desmond`.
- **Konfigurasi Autoindex**: `/etc/apache2/conf-available/arsip.conf`
- **Konfigurasi VirtualHost**: `/etc/apache2/sites-available/000-default.conf`
- **Direktori Berkas**: `/var/www/html/arsip/`

```bash
# Pada node obladi dan desmond:
cat /root/setup_vault.sh
cat /etc/apache2/conf-available/arsip.conf
cat /etc/apache2/sites-available/000-default.conf
ls -la /var/www/html/arsip/
```

### 2. Parameter Kunci Konfigurasi
- Web server menggunakan **Apache2** pada `obladi` (`192.212.1.4`) dan `desmond` (`192.212.1.5`).
- Direktori `/var/www/html/arsip/` memuat berkas arsip tanpa adanya `index.html` default.
- Fitur autoindex diaktifkan melalui:
  ```apache
  <Directory /var/www/html/arsip>
      Options +Indexes +FollowSymLinks
      IndexOptions FancyIndexing VersionSort NameWidth=* DescriptionWidth=* FoldersFirst
      AllowOverride None
      Require all granted
  </Directory>
  ```
- Sesuai ketentuan soal, pengujian diwajibkan menggunakan **hostname**.

### 3. Perintah Verifikasi & Validasi
```bash
# Pada terminal klien (alpha / beta):
curl -i http://obladi.k02.com/arsip/
curl -i http://desmond.k02.com/arsip/
curl -i http://vault.k02.com/arsip/
```

### 4. Ekspektasi Output
- Status respon `HTTP/1.1 200 OK` dengan header `Server: Apache/2.4.68 (Debian)`.
- Body HTML menyajikan autoindex direktori:
  ```html
  <title>Index of /arsip</title>
  ...
  <a href="arsip_obladi.txt">arsip_obladi.txt</a>
  <a href="database_vault_backup.tar.gz">database_vault_backup.tar.gz</a>
  <a href="dokumen_mesh.txt">dokumen_mesh.txt</a>
  <a href="secret_data.pdf">secret_data.pdf</a>
  ```

---

## Soal 10: Layanan Web Dinamis (PHP-FPM) & Clean URL `/profil` pada Area Core

### 1. Berkas Konfigurasi & Script
- **Lokasi Script**: `/root/setup_core.sh` pada `oblada` dan `molly`.
- **Konfigurasi VirtualHost**: `/etc/apache2/sites-available/000-default.conf`
- **Berkas Web Dinamis**:
  - `/var/www/html/index.php` (Halaman Beranda)
  - `/var/www/html/profil.php` (Halaman Profil)

```bash
# Pada node oblada dan molly:
cat /root/setup_core.sh
cat /etc/apache2/sites-available/000-default.conf
service php8.4-fpm status
service apache2 status
cat /var/www/html/profil.php
```

### 2. Parameter Kunci Konfigurasi
- Web server menggunakan **Apache2** yang diintegrasikan dengan **PHP8.4-FPM** melalui modul `mod_proxy_fcgi` (`/run/php/php8.4-fpm.sock`).
- Modul `mod_rewrite` diaktifkan untuk menerjemahkan URL bersih `/profil` ke berkas backend `profil.php`:
  ```apache
  RewriteEngine On
  RewriteRule ^profil/?$ /profil.php [L,QSA]
  ```
- Akses pengujian wajib menggunakan **hostname**.

### 3. Perintah Verifikasi & Validasi
```bash
# Pada terminal klien (alpha / beta):
# 1. Uji Beranda Dinamis:
curl -i http://oblada.k02.com/

# 2. Uji Clean URL /profil pada oblada:
curl -i http://oblada.k02.com/profil

# 3. Uji Clean URL /profil pada molly:
curl -i http://molly.k02.com/profil

# 4. Uji via cluster domain core.k02.com:
curl -i http://core.k02.com/profil
```

### 4. Ekspektasi Output
- Status respon `HTTP/1.1 200 OK` dengan header `Server: Apache/2.4.68 (Debian)`.
- Beranda menampilkan versi engine dinamis `PHP Version: 8.4.26`.
- Akses ke `http://oblada.k02.com/profil` (tanpa ekstensi `.php`) menampilkan profil entitas:
  ```text
  Identitas: OBLADA
  Divisi: Area Core (Repositori Web Dinamis The Mesh)
  Status Rewrite: Clean URL Aktif (/profil -> profil.php)
  ```
- Akses ke `http://molly.k02.com/profil` menampilkan identitas `MOLLY`.

---

## Soal 11: Reverse Proxy Penny (Apache) & Abbey (Nginx) dengan Load Balancing & Header Forwarding

### 1. Berkas Konfigurasi & Script
- **Node `penny` (Apache Proxy ke Vault)**:
  - Script: `/root/setup_proxy.sh`
  - Konfigurasi: `/etc/apache2/sites-available/000-default.conf`
- **Node `abbey` (Nginx Proxy ke Core)**:
  - Script: `/root/setup_proxy.sh`
  - Konfigurasi: `/etc/nginx/sites-available/default`

```bash
# Inspeksi konfigurasi proxy pada penny:
cat /root/setup_proxy.sh
cat /etc/apache2/sites-available/000-default.conf

# Inspeksi konfigurasi proxy pada abbey:
cat /root/setup_proxy.sh
cat /etc/nginx/sites-available/default
```

### 2. Parameter Kunci Konfigurasi
- **Penny (Apache2 Reverse Proxy)**:
  - Cluster balancer mengarah ke `obladi` (`192.212.1.4:80`) dan `desmond` (`192.212.1.5:80`) dengan `lbmethod=byrequests`.
  - Meneruskan header identitas asli pengunjung:
    ```apache
    ProxyPreserveHost On
    RequestHeader set X-Real-IP "expr=%{REMOTE_ADDR}"
    ```
- **Abbey (Nginx Reverse Proxy)**:
  - Upstream `core_backend` mengarah ke `oblada` (`192.212.1.6:80`) dan `molly` (`192.212.1.7:80`) secara round-robin.
  - Meneruskan header identitas asli pengunjung:
    ```nginx
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    ```
- **Backend Display**: Skrip `profil.php` di backend mencetak nilai header `Host` dan `X-Real-IP` yang diterima untuk verifikasi.

### 3. Perintah Verifikasi & Validasi
```bash
# Pada terminal klien (alpha / beta):

# 1. Uji Load Balancing Penny -> Vault (Obladi & Desmond):
# Catatan: Gunakan opsi -L jika redirect Soal 13 telah aktif, atau uji langsung domain kanonik www.k02.com:
for i in 1 2 3 4; do curl -sL http://penny.k02.com/ | grep "Node "; done
# Atau:
for i in 1 2 3 4; do curl -s http://www.k02.com/ | grep "Node "; done

# 2. Uji Load Balancing Abbey -> Core (Oblada & Molly):
# Catatan: Gunakan opsi -L jika redirect Soal 13 telah aktif, atau uji langsung domain kanonik static.k02.com:
for i in 1 2 3 4; do curl -sL http://abbey.k02.com/profil | grep Identitas; done
# Atau:
for i in 1 2 3 4; do curl -s http://static.k02.com/profil | grep Identitas; done

# 3. Uji Forwarding Header Host dan X-Real-IP:
curl -iL http://abbey.k02.com/profil
```

### 4. Ekspektasi Output
- **Load Balancing Penny**: Respon bergantian secara bergilir (*round-robin*) antara `Node DESMOND` dan `Node OBLADI`.
- **Load Balancing Abbey**: Respon bergantian secara bergilir (*round-robin*) antara `MOLLY` dan `OBLADA`.
- **Header Forwarding**: Respon memuat bukti penerusan IP klien dan Host:
  ```html
  <p>Forwarded Host: <strong>abbey.k02.com</strong></p>
  <p>Forwarded X-Real-IP: <strong>192.212.2.2</strong></p>
  <p>Backend Client Source IP: <strong>192.212.4.2</strong></p>
  ```

---

## Soal 12: Perlindungan Basic Authentication untuk Path `/admin` di Penny

### 1. Berkas Konfigurasi & Script
- **Target Node**: `penny` (Apache2 Web Server)
- **Berkas Kredensial**: `/etc/apache2/.htpasswd`
- **Konfigurasi VirtualHost**: `/etc/apache2/sites-available/000-default.conf`
- **Dokumen Rahasia**: `/var/www/html/admin/index.html`

```bash
# Pada node penny:
cat /etc/apache2/.htpasswd
grep -A 10 "<Directory /var/www/html/admin>" /etc/apache2/sites-available/000-default.conf
cat /var/www/html/admin/index.html
```

### 2. Parameter Kunci Konfigurasi
- Direktori `/var/www/html/admin/` dilindungi autentikasi dasar HTTP (`mod_auth_basic`).
- Path `/admin` dikecualikan dari `ProxyPass` (`ProxyPass /admin !`) agar diproses lokal di `penny`.
- Kredensial pengguna:
  - Username: `prabs`
  - Password: `pakar_pinter_jadi_goblok` (atau `pakar_pinter_jadi_gob***`)

### 3. Perintah Verifikasi & Validasi
```bash
# Pada terminal klien (alpha / beta):

# 1. Akses tanpa kredensial (Wajib 401 Unauthorized):
curl -i http://penny.k02.com/admin

# 2. Akses dengan password salah (Wajib 401 Unauthorized):
curl -i -u prabs:salah http://penny.k02.com/admin

# 3. Akses dengan kredensial benar (Wajib 200 OK):
# Gunakan akhiran trailing slash (/) karena admin adalah direktori fisik, atau tambahkan -L:
curl -i -u prabs:pakar_pinter_jadi_goblok http://penny.k02.com/admin/
# Atau:
curl -iL -u prabs:pakar_pinter_jadi_goblok http://penny.k02.com/admin
```

### 4. Ekspektasi Output
- Request tanpa kredensial / password salah menghasilkan status `HTTP/1.1 401 Unauthorized` dengan header `WWW-Authenticate: Basic realm=...`.
- Request dengan kredensial benar menghasilkan status `HTTP/1.1 200 OK` dan menampilkan isi dokumen rahasia sindikat.

---

## Soal 13: Canonical Redirect Permanen 301 (Penny) & Sementara 302 (Abbey)

### 1. Berkas Konfigurasi & Script
- **Node `penny`**: `/etc/apache2/sites-available/000-default.conf`
- **Node `abbey`**: `/etc/nginx/sites-available/default`

### 2. Parameter Kunci Konfigurasi
- **Penny (Apache2)**: Akses ke alamat IP `192.212.5.2` atau domain non-kanonik `penny.k02.com` dipaksa redirect permanen (**Status Code 301**) menuju `http://www.k02.com/`.
- **Abbey (Nginx)**: Akses ke alamat IP `192.212.4.2` atau domain non-kanonik `abbey.k02.com` dipaksa redirect sementara (**Status Code 302**) menuju `http://static.k02.com/`.

### 3. Perintah Verifikasi & Validasi
```bash
# Pada terminal klien (alpha / beta):

# 1. Uji redirect Penny (301 Permanent):
curl -i http://192.212.5.2/
curl -i http://penny.k02.com/

# 2. Uji redirect Abbey (302 Found / Temporary):
curl -i http://192.212.4.2/
curl -i http://abbey.k02.com/
```

### 4. Ekspektasi Output
- Curl ke Penny mengembalikan header `HTTP/1.1 301 Moved Permanently` dengan `Location: http://www.k02.com/`.
- Curl ke Abbey mengembalikan header `HTTP/1.1 302 Moved Temporarily` (atau `302 Found`) dengan `Location: http://static.k02.com/`.

---

## Soal 14: Real Client IP Logging pada Area Vault & Area Core

### 1. Berkas Konfigurasi & Script
- **Area Vault (Apache2 - `obladi` & `desmond`)**: `/etc/apache2/conf-available/remoteip.conf` & `/etc/apache2/apache2.conf`
- **Area Core (Apache2 - `oblada` & `molly`)**: `/etc/apache2/conf-available/remoteip.conf` & `/etc/apache2/apache2.conf`
- **Berkas Log**: `/var/log/apache2/access.log`

`ash
# Inspeksi konfigurasi remoteip pada backend (obladi / oblada):
cat /etc/apache2/conf-available/remoteip.conf
grep -E "%[ah]" /etc/apache2/apache2.conf
`

### 2. Parameter Kunci Konfigurasi
- Modul `remoteip` aktif (`a2enmod remoteip`).
- Menetapkan `RemoteIPHeader X-Real-IP`.
- Menetapkan proxy internal terpercaya:
  - `RemoteIPInternalProxy 192.212.5.2` (Penny)
  - `RemoteIPInternalProxy 192.212.4.2` (Abbey)
- Format log diubah dari `%h` (IP koneksi langsung) menjadi `%a` (IP asli klien yang diekstrak oleh remoteip).

### 3. Perintah Verifikasi & Validasi
`ash
# 1. Dari terminal klien alpha, lakukan request melalui gerbang:
curl -I http://www.k02.com/
curl -I http://static.k02.com/profil

# 2. Periksa access log di backend Area Vault (obladi / desmond):
tail -n 3 /var/log/apache2/access.log

# 3. Periksa access log di backend Area Core (oblada / molly):
tail -n 3 /var/log/apache2/access.log
`

### 4. Ekspektasi Output
- Baris log akses diawali dengan alamat IP asli milik klien `alpha` (`192.212.2.2`), bukan IP milik Penny (`192.212.5.2`) ataupun Abbey (`192.212.4.2`).

---

## Soal 15: Dedicated Path /eternal (PHP pada Penny) & /orion (Statis pada Abbey)

### 1. Berkas Konfigurasi & Script
- **Penny**: `/etc/apache2/sites-available/000-default.conf` & `/var/www/eternal/index.php`
- **Abbey**: `/etc/nginx/sites-available/default` & `/var/www/orion/index.html`

`ash
# Inspeksi konfigurasi Penny:
grep -A 10 "<Directory /var/www/eternal>" /etc/apache2/sites-available/000-default.conf
cat /var/www/eternal/index.php

# Inspeksi konfigurasi Abbey:
grep -A 5 "location /orion" /etc/nginx/sites-available/default
cat /var/www/orion/index.html
`

### 2. Parameter Kunci Konfigurasi
- **Penny (Apache2 + PHP)**:
  - Path `/eternal` dialiaskan ke `/var/www/eternal`.
  - File `.php` diproses melalui FastCGI PHP-FPM (`proxy:unix:/run/php/php8.4-fpm.sock`).
- **Abbey (Nginx Statis)**:
  - Path `/orion` dialiaskan ke `/var/www/orion`.
  - Murni statis, tidak ada instruksi `fastcgi_pass`.

### 3. Perintah Verifikasi & Validasi
`ash
# Dari node alpha:

# 1. Uji jalur /eternal pada Penny (Wajib render PHP):
curl -i http://www.k02.com/eternal/

# 2. Uji jalur /orion pada Abbey (Wajib murni statis):
curl -i http://static.k02.com/orion/
`

### 4. Ekspektasi Output
- Akses ke `/eternal/` mengembalikan respon `200 OK` dengan output eksekusi dinamis PHP (versi PHP & waktu server).
- Akses ke `/orion/` mengembalikan respon `200 OK` menyajikan dokumen statis murni `index.html`.

---

## Soal 16: Stress Test Benchmark ApacheBench (-n 250 -c 10)

### 1. Berkas Konfigurasi & Script
- **Node Penguji**: `alpha` (Klien)
- **Paket**: `apache2-utils` (perintah `ab`)

### 2. Perintah Demonstrasi & Verifikasi
`ash
# Di terminal node alpha:

# 1. Stress test ke gerbang Penny (Vault):
ab -n 250 -c 10 http://www.k02.com/

# 2. Stress test ke gerbang Abbey (Core):
ab -n 250 -c 10 http://static.k02.com/
`

### 3. Poin Penjelasan ke Asisten
- **Complete requests 250**: Seluruh 250 permintaan sukses dieksekusi secara konkuren 10 request bersamaan.
- **Penny Throughput**: Menghasilkan throughput tinggi sebesar ~1373 requests/second tanpa ada kegagalan (Failed requests: 0).
- **Abbey Throughput**: Menghasilkan throughput ~615 requests/second. Catatan Length: 125 membuktikan round-robin load balancing ke backend Oblada dan Molly aktif karena panjang response bita HTML kedua backend sedikit berbeda.

---

## Soal 17: Query TXT Record Klien Sayap Kiri & Kanan

### 1. Berkas Konfigurasi & Script
- **DNS Master (prab)**: `/etc/bind/k02/db.k02.com`
- **Skrip Otomasi**: `/root/setup_prab.sh` & [`scripts/setup_prab.sh`](scripts/setup_prab.sh)

`ash
# Inspeksi TXT record pada zona Master (prab):
grep -i "TXT" /etc/bind/k02/db.k02.com
`

### 2. Perintah Demonstrasi & Verifikasi
`ash
# Di terminal node alpha:
dig @192.212.1.2 alpha.k02.com TXT +short
dig @192.212.1.2 beta.k02.com TXT +short
dig @192.212.1.2 delta.k02.com TXT +short
`

### 3. Ekspektasi Output
- Setiap query TXT mengembalikan nama host masing-masing dalam tanda kutip: \"alpha\", \"beta\", \"gamma\", \"delta\", \"epsilon\".

---

## Soal 18: Pengujian DNS Caching dan TTL 15 Detik

### 1. Berkas Konfigurasi & Script
- **DNS Master (prab)**: `/etc/bind/k02/db.k02.com` (Record: `abbey 15 IN A 10.99.99.1`)
- **DNS Slave (tedd)**: Sinkronisasi otomatis AXFR/IXFR

### 2. Perintah Demonstrasi & Verifikasi Tiga Fase
`ash
# Di terminal node alpha:

# Fase 1: Sebelum Perubahan (IP Asli)
dig @192.212.1.2 abbey.k02.com +short

# Verifikasi sinkronisasi di tedd (Slave):
dig @192.212.1.3 abbey.k02.com +short

# Fase 2: Observasi TTL 15 Detik
dig abbey.k02.com

# Fase 3: Setelah TTL Habis (sleep 16)
sleep 16
dig abbey.k02.com +short
`

### 3. Ekspektasi Output
- Fase 1 mengembalikan 192.212.4.2.
- Sinkronisasi Tedd mengembalikan 10.99.99.1.
- Fase 2 memperlihatkan angka TTL 15 detik.
- Fase 3 mengembalikan IP fiktif 10.99.99.1.

---

## Soal 19: External CNAME Binding (outbound.k02.com -> http.badssl.com)

### 1. Berkas Konfigurasi & Script
- **DNS Master (prab)**: `/etc/bind/k02/db.k02.com` (Record: `outbound IN CNAME http.badssl.com.`)

`ash
# Inspeksi CNAME record di prab:
grep "outbound" /etc/bind/k02/db.k02.com
`

### 2. Perintah Demonstrasi & Verifikasi
`ash
# Di terminal node alpha:

# 1. Resolusi CNAME dua tingkat:
dig @192.212.1.2 outbound.k02.com

# 2. Curl HTTP header:
curl -I http://outbound.k02.com

# 3. Cuplikan konten HTML dari internet:
curl -s http://outbound.k02.com | head -n 15
`

### 3. Ekspektasi Output
- Query mengembalikan CNAME http.badssl.com. dan IP publik 104.154.89.105.
- Curl mengembalikan status 200 OK dari server publik 
ginx/1.10.3 (Ubuntu).

---

## Soal 20: Normalisasi Koordinat DNS dan Uji Autostart (/root/init.sh)

### 1. Berkas Konfigurasi & Script
- **Normalisasi Abbey (prab)**: `/etc/bind/k02/db.k02.com` (Record: `abbey IN A 192.212.4.2`)
- **Universal Init Script**: `/root/init.sh` di semua 14 entitas

`ash
# Cek A record abbey kembali normal di prab:
grep "abbey" /etc/bind/k02/db.k02.com
`

### 2. Perintah Demonstrasi & Verifikasi
`ash
# Di terminal node alpha:
dig @192.212.1.2 abbey.k02.com +short
# Output wajib: 192.212.4.2

# Uji eksekusi pemulihan instan di node mana saja (misal: penny / abbey / prab):
bash /root/init.sh
`

### 3. Poin Penjelasan ke Asisten
- **Koordinat Normal**: IP fiktif Soal 18 telah dikembalikan ke koordinat aslinya (192.212.4.2) agar seluruh arsitektur reverse proxy The Mesh berjalan normal kembali.
- **Autostart & Resiliensi**: Seluruh service didaftarkan pada /etc/network/interfaces dan didukung skrip /root/init.sh yang menjamin sistem pulih seketika saat di-restart oleh penguji.
