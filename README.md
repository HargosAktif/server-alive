# 📡 ServerAlive

<div align="center">

![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Kali](https://img.shields.io/badge/Kali_Linux-557C94?style=for-the-badge&logo=kalilinux&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-a78bfa?style=for-the-badge)

*ICMP, TCP ve HTTP üçlüsüyle hedefin canlı olup olmadığını test eden Bash aracı.*

</div>

---

## Nedir?

ServerAlive, tek bir IP'den tüm subnet'e kadar hedeflerin canlı olup olmadığını 3 farklı yöntemle kontrol eden bir Bash scriptidir. Firewall ICMP'yi bloklasa bile TCP ve HTTP kontrolleriyle hedefi yakalar.

## Özellikler

```
[*] ICMP ping kontrolü
[*] TCP port knock (80, 443, 22, 8080, 8443)
[*] HTTP durum kodu tespiti
[*] Subnet tarama (/24)
[*] Dosyadan toplu hedef okuma
[*] Renkli özet rapor
```

## Kurulum

```bash
git clone https://github.com/HargosAktif/server-alive
cd server-alive
chmod +x server_alive.sh
```

## Kullanım

```bash
# Tek hedef
./server_alive.sh 192.168.1.1

# Dosyadan toplu tarama
./server_alive.sh -f hedefler.txt

# Tüm subnet
./server_alive.sh -s 192.168.1.0/24
```

```
[*] Kontrol ediliyor: 192.168.1.1        [ALIVE]
         ├── ICMP ping  : OK
         ├── TCP port   : OPEN
         └── HTTP kodu  : 200

[*] Kontrol ediliyor: 192.168.1.2        [DEAD / FILTERED]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ÖZET
  [+] ALIVE   192.168.1.1
  [-] DEAD    192.168.1.2

  Alive : 1
  Dead  : 1
  Süre  : 3s
```

## ⚠️ Yasal Uyarı

Bu araç yalnızca **izinli ağlarda** ve **eğitim amaçlı** kullanım içindir. İzinsiz ağlarda kullanmak yasa dışıdır.

---

<div align="center">

*by [LatenT](https://github.com/HargosAktif)*

</div>
