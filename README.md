# ⚡ Ritual Sovereign Agent — One-Click Deploy

Deploy a **free, recurring AI agent** on Ritual testnet in 5 minutes. No API keys. No coding. No experience needed.

---

## 📋 What you need

| Item | How to get it |
|------|---------------|
| **A computer** | Windows, Mac, or Linux |
| **EVM Wallet** | MetaMask ([get it here](https://metamask.io)) or Rabby |
| **RITUAL tokens** | Free from the [faucet](https://faucet.ritualfoundation.org) — ask in Ritual Discord for an access code |
| **~5 minutes** | That's it |

---

## 🚀 Step-by-step

### 1. Open your terminal

**Windows:** Press `Windows + R`, type `cmd`, press Enter. Then type `wsl` and press Enter.
**Mac:** Press `Cmd + Space`, type `terminal`, press Enter.
**Linux:** Press `Ctrl + Alt + T`.

### 2. Paste this one command

Copy and paste this entire line into your terminal, then press Enter:

```bash
git clone https://github.com/norbert351/ritual-agent.git && cd ritual-agent && bash run.sh
```

> ⏳ **First run only:** The script will automatically install Foundry and uv (tools it needs). This takes ~1 minute.

### 3. Enter your wallet details

The script will ask you for:

| Prompt | What to enter |
|--------|---------------|
| 🔑 **Private key** | Your MetaMask/Rabby wallet private key (starts with `0x`) |
| 🔑 **Set a password** | Any password you'll remember — this encrypts your key safely |
| 🤖 **Agent name** | A name for your agent (or just press Enter for a random one) |

> 🔒 **Your private key is NEVER stored in plaintext.** It gets encrypted into a Foundry keystore. Nobody can read it without your password.

### 4. Wait for deployment

You'll see:

```
  ⚡ RITUAL SOVEREIGN AGENT
  Balance: 5.09 RITUAL
  Deploying harness...
  ✓ Harness: 0x...
  Building payload...
  Simulating...
  Deploying...
  ✅ AGENT DEPLOYED!
```

### 5. Check your agent

Open this link in your browser (replace YOUR_HARNESS_ADDRESS with the address shown):

```
https://explorer.ritualfoundation.org/agents/YOUR_HARNESS_ADDRESS
```

---

## ❓ Troubleshooting

| Problem | Fix |
|---------|-----|
| `git: command not found` | Install Git: [git-scm.com](https://git-scm.com/downloads) |
| `Insufficient balance` | Get free RITUAL from the [faucet](https://faucet.ritualfoundation.org) |
| `Simulation failed` | Your wallet may be low on funds — check your balance and add more RITUAL |
| Anything else? | Open an issue on this repo |

---

## 💡 How it works (for the curious)

| Step | What happens |
|------|-------------|
| 1 | Script installs Foundry + uv (command-line tools) |
| 2 | Encrypts your private key into a secure keystore |
| 3 | Deploys a "harness" contract via the SovereignAgentFactory |
| 4 | Funds the harness with 0.1 RITUAL + sets up a recurring schedule |
| 5 | Agent wakes every ~1 minute, runs AI inside a TEE, posts results on-chain |

The AI model (`zai-org/GLM-4.7-FP8`) runs on Ritual's own infrastructure — **completely free, no API key needed.**

---

## 📜 License

MIT
