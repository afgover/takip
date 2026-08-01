---
id: A-2026-08-01-028
session: none
type: info
title: "Agents Hub - Security & Credential Management"
created: 2026-08-01T00:00:00Z
---

> **Arşiv.** Kaynak: `taskr@project-taskr:.gemini/security.md` — 2026-08-01'de
> olduğu gibi taşındı, içeriği değiştirilmedi. Project Taskr arşive
> kaldırıldığı için bu belge tarihsel kayıttır; güncel değildir.

# Agents Hub - Security & Credential Management

**Confidential**: This document contains security-critical information. Protect this file.

---

## SSH Keys & GitHub Access

### Current SSH Setup

**SSH Key Location**: `~/.ssh/`

Available keys:
- `hetzner_key` — For Hetzner server access
- No GitHub-specific SSH key currently configured

### GitHub Authentication Methods

#### Method 1: Personal Access Token (Currently Used)
**Token Format**: `ghp_[alphanumeric]` (GitHub Personal Access Token)

**Location**: Stored in git remote URLs (not .env files)
```bash
# Check current authentication:
cd ~/Desktop/CoPilot
git remote -v
# Shows: https://ghp_[TOKEN]@github.com/afgover/Copilot.git
```

**Token Details**:
- Full repository access (public + private)
- Used for both read (clone) and write (push) operations
- Expires: Check GitHub Settings → Developer Settings → Personal Access Tokens

**Security Notes**:
- ✅ Token embedded in git remote URL (valid method for CLI)
- ⚠️ Token visible in git remote (acceptable for local development)
- ⚠️ Never commit .git/config with exposed token
- Never paste token in chat, logs, or documentation

#### Method 2: SSH Keys (Recommended for Future)

**Setup required**:
```bash
# Generate new GitHub SSH key (if needed)
ssh-keygen -t ed25519 -C "afgover@gmail.com" -f ~/.ssh/id_github

# Add to GitHub:
# 1. Settings → SSH and GPG keys
# 2. New SSH key
# 3. Paste public key: ~/.ssh/id_github.pub

# Test connection:
ssh -T git@github.com
```

**Usage**:
```bash
# Clone with SSH:
git clone git@github.com:afgover/agents.git

# Change existing repo:
git remote set-url origin git@github.com:afgover/agents.git
```

**Advantages**:
- No token in URL
- Key-based authentication more secure
- Easier to rotate keys
- Better for multiple GitHub accounts

#### Method 3: GitHub CLI (Alternative)

**Installation**:
```bash
brew install gh  # macOS
```

**Setup**:
```bash
gh auth login
# Prompts for authentication method (SSH or browser OAuth)
```

**Usage**:
```bash
gh repo clone afgover/agents
gh pr create --title "..." --body "..."
gh issue create --title "..."
```

---

## Token Management

### Current Token Status

**Token**: Embedded in CoPilot remote URL  
**Scope**: Full repository access  
**Used for**: Clone, push operations  
**Last verified**: 2026-05-06

### Token Rotation Checklist

When token nears expiration or compromised:

1. **Generate new token**
   - GitHub → Settings → Developer Settings → Personal Access Tokens
   - Select "Tokens (classic)"
   - Generate new token with same scopes
   - Copy immediately (can't see again)

2. **Update git remotes**
   ```bash
   # CoPilot project:
   cd ~/Desktop/CoPilot
   git remote set-url origin https://ghp_[NEW_TOKEN]@github.com/afgover/Copilot.git
   
   # Agents hub:
   cd ~/Desktop/agents
   git remote set-url origin https://ghp_[NEW_TOKEN]@github.com/afgover/agents.git
   ```

3. **Verify working**
   ```bash
   git pull origin main  # Should work without prompting
   ```

4. **Revoke old token**
   - GitHub → Settings → Developer Settings → Personal Access Tokens
   - Delete or revoke old token
   - ⚠️ Do this AFTER verifying new token works everywhere

### Environment Variables

**Never use** `.env` files for GitHub tokens. Use git remote URL instead.

**Incorrect** ❌:
```
GITHUB_TOKEN=ghp_xxxxx
```

**Correct** ✅:
```bash
git remote add origin https://ghp_xxxxx@github.com/user/repo.git
```

---

## Repository Access Control

### CoPilot Repository
- **URL**: https://github.com/afgover/Copilot
- **Access**: Private (fatih owns)
- **CI/CD**: Coolify auto-deploy on main branch
- **Deployment**: copilot.net.tr (production)

### Agents Hub Repository
- **URL**: https://github.com/afgover/agents
- **Access**: Private (fatih owns)
- **Purpose**: Central documentation hub
- **No auto-deploy**: Manual coordination

### GitHub User
- **Account**: afgover (fatih)
- **Email**: afgover@gmail.com
- **Organizations**: None (personal repos)

---

## Secure Communication Patterns

### What NOT to Do

❌ **Don't share**:
- GitHub tokens
- SSH private keys
- Database connection strings
- API keys
- Password hashes

❌ **Don't store in**:
- Chat messages
- Commit messages
- Documentation files
- Email
- Shared notes

❌ **Don't commit**:
- .env files
- .env.local
- Private keys
- API credentials
- Secrets

### What TO Do

✅ **Use git remote URLs** for authentication (like current setup)

✅ **Rotate credentials** when:
- Access changes (new team member)
- Suspected compromise
- Token nears expiration
- Security patch released

✅ **Verify access** before operations:
```bash
git ls-remote origin HEAD
# Should succeed if auth is correct
```

✅ **Document procedures** (like this file) but not secrets

---

## SSH Key Management

### Current SSH Keys

**Location**: `~/.ssh/`

| Key | Purpose | Created | Status |
|-----|---------|---------|--------|
| hetzner_key | Hetzner VPS access | 2026-05-02 | Active |
| hetzner_key.pub | Public key | 2026-05-02 | Active |
| known_hosts | SSH known hosts | 2026-05-02 | Updated |

### SSH Config (Optional Setup)

**File**: `~/.ssh/config`

```
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_github
  IdentitiesOnly yes

Host hetzner
  HostName [IP_ADDRESS]
  User root
  IdentityFile ~/.ssh/hetzner_key
```

**Usage**: `ssh hetzner` (instead of `ssh -i ~/.ssh/hetzner_key root@IP`)

### SSH Key Rotation

When adding new servers or rotating keys:

```bash
# Generate new key
ssh-keygen -t ed25519 -C "description" -f ~/.ssh/[keyname]

# Add to server
ssh-copy-id -i ~/.ssh/[keyname].pub user@server

# Test
ssh -i ~/.ssh/[keyname] user@server

# Update ~/.ssh/config if using config file
```

---

## Database Security

### PostgreSQL (Production)

**Connection String Format**:
```
postgresql://user:password@host:5432/database
```

**Security Practices**:
- ✅ Store in .env.local (never commit)
- ✅ Use strong passwords (32+ chars)
- ✅ Restrict network access (whitelist IPs)
- ✅ Enable SSL/TLS for remote connections
- ✅ Regular backups (daily minimum)
- ✅ Limit user permissions (Principle of Least Privilege)

**For CoPilot Project**:
```
DATABASE_URL stored in: .env.local (not in repo)
Accessed via: Prisma ORM with connection pooling
```

### Prisma Safety

**Never do this**:
```javascript
// ❌ Don't construct queries with string concatenation
const userId = req.query.id
prisma.user.findMany({
  where: { id: userId }  // SQL injection risk if not validated
})
```

**Do this instead**:
```javascript
// ✅ Use Prisma's type-safe queries
const userId = req.query.id
if (!userId || typeof userId !== 'string') throw new Error('Invalid ID')
prisma.user.findUnique({
  where: { id: userId }  // Prisma parameterizes this
})
```

---

## API Keys & External Services

### Google OAuth
- **Keys stored in**: .env.local
- **Type**: OAuth 2.0 credentials
- **Rotation**: Monthly recommended
- **Security**: Never log or expose to client

### Email Service (if using external)
- **API Key**: .env.local
- **Rate limits**: Check provider docs
- **Fallback**: Implement graceful degradation

### Monitoring & Logging
- **Never log**: Passwords, tokens, keys
- **Do log**: Actions, timestamps, user IDs
- **Example**:
  ```javascript
  // ❌ Bad
  console.log(`User ${user.email} auth with password ${password}`)
  
  // ✅ Good
  console.log(`User ${user.id} authenticated successfully`)
  ```

---

## Credential Checklist

### Daily Operations

- [ ] SSH/Git authentication working (can clone/push)
- [ ] Database connection available (can access Prisma)
- [ ] OAuth credentials valid (no auth errors)

### When Adding New Service

- [ ] Read service's security documentation
- [ ] Use API keys with minimal required permissions
- [ ] Store in .env.local (never in code)
- [ ] Test before deploying
- [ ] Set up key rotation reminder

### Monthly Maintenance

- [ ] Check GitHub token expiration date
- [ ] Review SSH keys (remove unused)
- [ ] Rotate database password if shared
- [ ] Verify no credentials in git history

---

## Incident Response

### If You Suspect Credential Compromise

1. **Stop immediately** — Don't push/pull with compromised credential
2. **Revoke credential** — GitHub settings, SSH remove, etc.
3. **Generate new credential** — Follow rotation checklist
4. **Audit git history** — Check `git log -p` for exposed secrets
5. **Update all locations** — All remotes, configs, .env files
6. **Test access** — Verify new credential works
7. **Document incident** — What happened, how it was fixed

### If You Accidentally Commit a Secret

1. **If not pushed to GitHub**:
   ```bash
   git reset HEAD~1
   # Remove secret from file
   git add [file]
   git commit -m "remove secret from file"
   ```

2. **If pushed to GitHub**:
   - Revoke credential immediately
   - Use `git filter-branch` or `bfg-repo-cleaner` to remove from history
   - Force push (⚠️ impacts all developers)
   - Document what was exposed

---

## Security Best Practices for Agents

### Every Agent Should Know

1. **Never echo credentials** — Don't print tokens, passwords, keys
2. **File permissions** — Keep SSH keys readable only by owner (`chmod 600`)
3. **Session cleanup** — Don't leave credentials in shell history
4. **Verification** — Test access before assuming credentials work
5. **Rotation** — Follow schedules for credential updates

### Before Pushing to GitHub

```bash
# Check what you're about to push:
git diff origin/main

# Search for common secrets:
git diff | grep -E "password|token|key|secret|api" -i

# Never include:
# - .env files
# - .env.local files
# - Private SSH keys
# - API tokens
# - Database credentials
```

### Code Review Checklist

When reviewing commits:
- [ ] No .env files added
- [ ] No credentials in commit message
- [ ] No hardcoded API keys
- [ ] No database passwords
- [ ] Authentication pattern follows project standards

---

## References & Tools

### Useful Commands

```bash
# Check git remote (see if token is exposed):
git remote -v

# Change to SSH (recommended):
git remote set-url origin git@github.com:user/repo.git

# Test SSH access:
ssh -T git@github.com

# View SSH key fingerprint:
ssh-keygen -lf ~/.ssh/id_github.pub

# Check git config:
git config --global --list | grep github
```

### GitHub Resources

- [GitHub Docs: Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [GitHub Docs: SSH Key Setup](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [GitHub Docs: Removing Sensitive Data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)

### Tools

- `bfg-repo-cleaner` — Remove secrets from git history
- `git-secrets` — Local git hook to prevent secret commits
- `truffleHog` — Scan for leaked secrets

---

## Approval & Authorization

### Who Can:

| Action | Authorized |
|--------|-----------|
| Push to main | User (ask first) |
| Rotate tokens | fatih only |
| Change SSH keys | fatih only |
| Deploy to production | User (requires approval) |
| Access database | fatih only |
| Add new team members | fatih only |

---

**Version**: 1.0  
**Last Updated**: 2026-05-06  
**Classification**: Internal / Confidential  
**Reviews**: Quarterly recommended  

⚠️ Keep this file secure. Don't share with untrusted parties.
