#!/usr/bin/env bash
# run.sh — Deploy your free sovereign AI agent on Ritual testnet
# No API keys. No coding. One command.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.foundry/bin:$HOME/.local/bin:$PATH"

ESC=$'\033'; R="${ESC}[0m"; B="${ESC}[1m"; D="${ESC}[2m"
C="${ESC}[38;5;141m"; G="${ESC}[38;5;78m"; X="${ESC}[38;5;203m"; W="${ESC}[38;5;214m"

echo ""
echo "  ${C}⚡ RITUAL SOVEREIGN AGENT${R}"
echo "  ${D}Free AI agent — Ritual testnet (1979)${R}"
echo ""

# ── 1. Auto-install tools ──
if ! command -v cast &>/dev/null; then
  echo "  Installing Foundry..."; curl -L https://foundry.paradigm.xyz | bash &>/dev/null
  export PATH="$HOME/.foundry/bin:$HOME/.local/bin:$PATH"
  foundryup &>/dev/null
fi
if ! command -v uv &>/dev/null; then
  echo "  Installing uv..."; curl -LsSf https://astral.sh/uv/install.sh | sh &>/dev/null
  export PATH="$HOME/.foundry/bin:$HOME/.local/bin:$PATH"
fi

# ── 2. Keystore ──
KS_DIR="$HOME/.foundry/keystores"; mkdir -p "$KS_DIR"
KS_FILE="$KS_DIR/ritual-agent"
if [ -f "$KS_FILE" ]; then
  read -s -p "  🔑 Keystore password: " PW; echo
  ADDR=$(cast wallet address --account ritual-agent --password "$PW" 2>/dev/null) || { echo "  ${X}Wrong password${R}"; exit 1; }
else
  echo "  ${W}First run — setting up your wallet${R}"
  read -s -p "  Private key (0x...): " KEY; echo
  read -s -p "  Set a password (save this!): " PW; echo
  echo "$KEY" | cast wallet import ritual-agent --private-key /dev/stdin --password "$PW" &>/dev/null
  ADDR=$(cast wallet address --account ritual-agent --password "$PW")
  echo "  ${G}✓ Wallet: $ADDR${R}"
fi
echo ""

# ── 3. Agent name ──
SALT="agent-$(date +%s)"
if [ -f "$HERE/.env" ]; then source "$HERE/.env"; fi
read -p "  Agent name [${SALT}]: " S; SALT="${S:-$SALT}"
echo ""

# ── 4. Deploy ──
FACTORY="0x9dC4C054e53bCc4Ce0A0Ff09E890A7a8e817f304"
WALLET="0x532F0dF0896F353d8C3DD8cc134e8129DA2a3948"
REGISTRY="0x9644e8562cE0Fe12b4deeC4163c064A8862Bf47F"
RPC="https://rpc.ritualfoundation.org"
DEPOSIT="100000000000000000"
GAS=5000000

BAL=$(cast balance "$ADDR" --rpc-url "$RPC" --ether 2>/dev/null || echo "0")
echo "  Balance: ${BAL} RITUAL"

US=$(cast keccak "$SALT")
HARNESS=$(cast call "$FACTORY" 'predictHarness(address,bytes32)(address)' "$ADDR" "$US" --rpc-url "$RPC" 2>/dev/null || echo "")

HAS_CODE=$(cast code "$HARNESS" --rpc-url "$RPC" 2>/dev/null | wc -c)
if [ "$HAS_CODE" -le 2 ]; then
  echo "  Deploying harness..."
  cast send "$FACTORY" 'deployHarness(bytes32)' "$US" --account ritual-agent --password "$PW" --rpc-url "$RPC" --gas-limit 3000000 &>/dev/null
fi
echo "  ${G}✓ Harness: $HARNESS${R}"

# ── 5. Build calldata ──
echo "  Building payload..."
TMP=$(mktemp).py
cat > "$TMP" << 'PYEOF'
import json, os, sys
from ecies import encrypt as ecies_encrypt; from ecies.config import ECIES_CONFIG
from eth_abi.abi import encode; from web3 import Web3
ECIES_CONFIG.symmetric_nonce_length = 12
w3 = Web3(Web3.HTTPProvider(os.environ["RPC"]))
reg = w3.eth.contract(address=Web3.to_checksum_address(os.environ["REG"]), abi=json.loads(os.environ["ABI"]))
svc = reg.functions.getServicesByCapability(0, True).call()
executor = Web3.to_checksum_address(svc[0][0][1])
enc = ecies_encrypt(bytes(svc[0][0][3]).hex(), b'{"LLM_PROVIDER":"ritual"}')
sel = Web3.keccak(text="onSovereignAgentResult(bytes32,bytes)")[:4]
h = Web3.to_checksum_address(os.environ["HARNESS"])
p = [
  executor, 500, b"", 5, w3.eth.block_number + 10_000_000,
  "SOVEREIGN_AGENT_TASK", h, sel,
  3_000_000, 1_000_000_000, 100_000_000,
  int(os.environ.get("CLI","6")), os.environ["PROMPT"], enc,
  ("hf","unused/sessions/session-001.jsonl",""),
  ("hf","unused/artifacts/",""), [],
  ("hf","unused/prompts/default-system.md",""),
  os.environ.get("MODEL","zai-org/GLM-4.7-FP8"), [], 50, 8192, "",
]
PT="address,uint256,bytes,uint64,uint64,string,address,bytes4,uint256,uint256,uint256,uint16,string,bytes,(string,string,string),(string,string,string),(string,string,string)[],(string,string,string),string,string[],uint16,uint32,string"
ST="(uint32,uint32,uint32,uint256,uint256,uint256)"; RT="(uint32,uint16,uint16)"
d = Web3.keccak(text=f"configureFundAndStart({PT},{ST},{RT},uint256)")[:4] + encode([f"({PT})",ST,RT,"uint256"],[p,(800000,180,500,1000000000,100000000,0),(5,5000,1),int(os.environ["LOCK"])])
print("EXEC="+executor); print("DATA="+d.hex())
PYEOF

ABI='[{"name":"getServicesByCapability","type":"function","stateMutability":"view","inputs":[{"name":"capability","type":"uint8"},{"name":"checkValidity","type":"bool"}],"outputs":[{"type":"tuple[]","components":[{"type":"tuple","components":[{"name":"paymentAddress","type":"address"},{"name":"teeAddress","type":"address"},{"name":"teeType","type":"uint8"},{"name":"publicKey","type":"bytes"},{"name":"endpoint","type":"string"},{"name":"certPubKeyHash","type":"bytes32"},{"name":"capability","type":"uint8"}]},{"type":"bool"},{"type":"bytes32"}]}]}]'

OUT=$(RPC=$RPC REG=$REGISTRY ABI="$ABI" HARNESS=$HARNESS PROMPT="Analyze Ritual chain activity." LOCK=100000 uv run --quiet --with eciespy --with eth-abi --with web3 python3 "$TMP" 2>&1)
rm -f "$TMP"
DATA=$(echo "$OUT" | grep "^DATA=" | cut -d= -f2-)
[ -z "$DATA" ] && { echo "  ${X}Failed to build payload${R}"; exit 1; }

# ── 6. Simulate ──
echo "  Simulating..."
cast call "$HARNESS" "$DATA" --account ritual-agent --password "$PW" --rpc-url "$RPC" --value "$DEPOSIT" &>/dev/null || { echo "  ${X}Simulation failed. Check your balance.${R}"; exit 1; }

# ── 7. Deploy for real ──
echo "  Deploying..."
cast send "$HARNESS" "$DATA" --account ritual-agent --password "$PW" --rpc-url "$RPC" --value "$DEPOSIT" --gas-limit $GAS &>/dev/null

echo ""
echo "  ${G}══════════════════════════════════════════${R}"
echo "  ${G}✅ AGENT DEPLOYED!${R}"
echo "  ${G}Harness: $HARNESS${R}"
echo "  ${G}Explorer: https://explorer.ritualfoundation.org/agents/$HARNESS${R}"
echo "  ${G}══════════════════════════════════════════${R}"
echo ""
