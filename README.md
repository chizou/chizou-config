# chizou-config

Public, reusable Ansible configuration for bootstrapping an Ubuntu WSL development
environment. The playbook targets Ubuntu 26.04 and avoids committing personal
identity, credentials, SSH keys, or machine-specific paths.

## First-time setup

Clone this repository over public HTTPS, then run the primer:

```bash
git clone https://github.com/chizou/chizou-config.git
cd chizou-config
./scripts/prime.sh
```

Without arguments, the primer runs interactively. It asks for the target username,
Git identity, optional GPG signing-key ID, optional `authorized_keys` source file,
and whether passwordless sudo should be enabled. Existing local/private values are
offered as defaults, so the primer can safely be rerun to complete or change fields.
It writes only ignored local files:

- `vars/local.yml`
- `local/authorized_keys` when supplied

To install defaults obtained from a private repository without prompting:

```bash
./scripts/prime.sh --defaults /path/to/private-defaults/vars/local.yml
```

The file is copied to the ignored `vars/private.yml`. If an `authorized_keys` file
is beside the supplied YAML file or in its parent directory, it is copied into the
ignored `local/` directory. Machine-local answers in `vars/local.yml` take precedence
over private defaults, while private defaults take precedence over public defaults.

Review those files, then run:

```bash
sudo apt update
sudo apt install -y ansible
ansible-playbook local.yml -v -K
```

To configure without the interactive primer, copy `vars/local.example.yml` to
`vars/local.yml`, edit it, and optionally place public SSH keys in
`local/authorized_keys`.

## Public-repository safety

Never commit `vars/local.yml`, `vars/private.yml`, `local/`, private keys, credentials, `.env` files,
or migration archives. The included `.gitignore` blocks common forms of these
files, but it is not a substitute for reviewing `git diff --cached` before pushing.

The GPG signing-key ID is public metadata, not signing authority: a private key is
still required to create a signature. It remains local here to avoid correlating
this repository with a specific identity.

Passwordless sudo is disabled by default. Enable it only by setting
`enable_passwordless_sudo: true` in `vars/local.yml`.

## Defaults

- Node.js 24 through NVM
- Docker Engine and Compose/Buildx plugins
- Python command-line tools isolated with `pipx`
- Optional Python 3.10 through Deadsnakes
- No CUDA or Anaconda installation
