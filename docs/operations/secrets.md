---
title: Secrets Management
sidebar_position: 3
description: Encrypting secrets with SOPS and age
---

# Secrets Management

Secrets are encrypted using [SOPS](https://github.com/getsops/sops) with [age](https://github.com/FiloSottile/age) encryption.

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                     YOUR MAC / CI                           │
│  .sops.yaml (public key) + age private key                  │
│  → Can encrypt AND decrypt                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     GIT REPOSITORY                          │
│  *.env.sops files (encrypted secrets)                       │
│  → Safe to commit                                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   TOUCAN / HORNBILL                         │
│  age private key + sops                                     │
│  → Decrypts secrets at deploy time                          │
└─────────────────────────────────────────────────────────────┘
```

## File Naming Convention

| File | Description | Committed |
|------|-------------|-----------|
| `.env.sops` | Encrypted secrets | Yes |
| `.env` | Decrypted secrets | No (gitignored) |
| `.env.example` | Template (no real values) | Optional |

## Configuration

### .sops.yaml

Located at repository root:

```yaml
creation_rules:
  - path_regex: \.env\.sops$
    age: age1nh9zuzsmewquyr0xlv7vzzsug0fat6ju5kznxhlpkcrujwtjevyqe6vl5g
```

### Key Locations

| Machine | Key Location |
|---------|--------------|
| Mac | `~/.config/sops/age/keys.txt` |
| Toucan | `~/.config/sops/age/keys.txt` |
| Hornbill | `~/.config/sops/age/keys.txt` |

Set environment variable in shell profile:
```bash
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
```

## Common Operations

### Create New Encrypted Secret

```bash
# Create plaintext .env
echo 'MY_SECRET=value' > service/.env

# Encrypt in place
sops -e -i service/.env

# Rename to .env.sops
mv service/.env service/.env.sops
```

### Edit Encrypted Secret

```bash
# Opens in $EDITOR, decrypts, then re-encrypts on save
sops service/.env.sops
```

### Decrypt for Deployment

```bash
# On server, after git pull
sops --input-type dotenv --output-type dotenv -d service/.env.sops > service/.env
```

### View Encrypted Secret

```bash
sops -d service/.env.sops
```

## Deployment Workflow

### Initial Deployment

```bash
# On server
cd /srv/services/myservice
git pull
sops --input-type dotenv --output-type dotenv -d .env.sops > .env
docker compose up -d
```

### Secret Rotation

1. Edit secret locally: `sops webhook/.env.sops`
2. Commit and push
3. On server: `git pull && sops -d .env.sops > .env && docker compose restart`

## Security Notes

- **Private key**: Store in 1Password, deploy to servers manually
- **Public key**: Safe to commit in `.sops.yaml`
- **Never commit**: Decrypted `.env` files (gitignored)
- **One key for all repos**: Same age key works across repositories

## Backup

The age private key is stored in:
- 1Password (primary backup)
- Each server at `~/.config/sops/age/keys.txt`

If the key is lost, encrypted secrets cannot be recovered. Always maintain backups.
