# 🚀 Nesa Node Setup (Super Simple)

> Setup Nesa Node dalam 5 menit — Cocok untuk pemula!

## 📋 Apa itu Nesa?

Nesa adalah **Layer-1 blockchain untuk AI** — jalankan AI model secara **private, verifiable, dan terdesentralisasi**.

**Node Types:**
- 🏆 **Validator** — Validasi transaksi (butuh stake)
- ⛏️ **Miner** — Jalankan AI inference
  - **Distributed** — Gabung swarm (tim)
  - **Non-Distributed** — Solo mining

---

## ⚡ Quick Start (1 Command)

```bash
bash <(curl -s https://raw.githubusercontent.com/nesaorg/bootstrap/master/bootstrap.sh)
```

**Done!** 🎉

---

## 📝 Step-by-Step (Detail)

### Step 1: Pastikan Docker Running
```bash
docker --version
```
Kalau belum install: [Install Docker](https://docs.docker.com/get-docker/)

### Step 2: Jalankan Bootstrap Script
```bash
bash <(curl -s https://raw.githubusercontent.com/nesaorg/bootstrap/master/bootstrap.sh)
```

### Step 3: Isi Konfigurasi

Script akan minta:

| Pertanyaan | Jawaban |
|------------|---------|
| **Moniker** | Nama node (contoh: `john-node`) |
| **Node Type** | Pilih: `Validator` atau `Miner` |
| **Validator** | Masukin private key wallet |
| **Miner Type** | `Distributed` (tim) atau `Non-Distributed` (solo) |
| **Model** | Contoh: `meta-llama/Llama-2-13b-Chat-Hf` |

### Step 4: Cek Node

```bash
# Cek container running
docker ps

# Cek status node
# Buka: https://node.nesa.ai
# Masukin Node ID (dari output script)
```

---

## 🔧 Cara Lain (Manual)

### Docker Compose

```bash
# 1. Clone repo
git clone https://github.com/nesaorg/nesa-docker.git
cd nesa-docker

# 2. Copy config
cp .env.example .env

# 3. Edit config
nano .env
```

**Edit `.env`:**
```env
MONIKER=my-node
NODE_TYPE=miner
MINER_TYPE=non-distributed
MODEL_NAME=meta-llama/Llama-2-13b-Chat-Hf
```

```bash
# 4. Start
docker-compose up -d

# 5. Cek logs
docker-compose logs -f
```

---

## 📊 Monitoring

### Cek Status Node
- **Website:** https://node.nesa.ai
- **Masukin:** Node ID (dari script awal)

### Cek Container
```bash
docker ps
```

### Cek Logs
```bash
docker-compose logs -f
```

---

## 🆘 Troubleshooting

### Error: "Docker not running"
```bash
sudo systemctl start docker
```

### Error: "Port already in use"
```bash
# Cek port 26656, 26657
docker-compose down
sudo lsof -i :26656
# Kill process atau ganti port di config
```

### Node gak sync
```bash
# Restart
docker-compose restart

# Atau hapus data dan sync ulang (caution!)
docker-compose down -v
rm -rf ~/.nesa/data
```

---

## 💬 Butuh Bantuan?

- **Discord:** https://discord.gg/nesa
- **Docs:** https://docs.nesa.ai

---

## 📚 Resources

- [Official Bootstrap](https://github.com/nesaorg/bootstrap)
- [Nesa Docs](https://docs.nesa.ai)
- [Node Dashboard](https://node.nesa.ai)

---

**Happy Mining!** ⛏️🚀
