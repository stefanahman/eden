# Eden Local Configuration Templates

These templates provide examples for machine-specific configurations that you don't want in the public Eden repository.

## The Branch Concept

Eden supports **branches** - separate repositories that extend Eden with private, contextual, or experimental configurations.

Think of Eden as the **trunk** (public, shared) and branches as **extensions** (private, specific):

```
🌳 Eden (trunk)          → Shared foundation
  ├─ 🌿 work-repo        → Work configs (email, aliases, VPN)
  ├─ 🌿 personal-repo    → Personal experiments
  └─ 🌿 client-repo      → Client-specific settings
```

All branches stow together into `$HOME`, layering naturally.

## Creating a Branch

### 1. Create the Branch Repository

```bash
# Example: work branch repo
mkdir -p ~/Development/eden-branches/work-repo/.config/eden/local
cd ~/Development/eden-branches/work-repo

# Initialize git
git init
git remote add origin git@github.com:yourusername/eden-branch-work-repo.git

# Add your configs
cp ~/.config/eden/templates/gitconfig.work.template .config/eden/local/gitconfig.work
# Edit with actual values
vim .config/eden/local/gitconfig.work

# Commit
git add .
git commit -m "Initial work branch repo"
git push -u origin main
```

### 2. Register the Branch with Eden

```bash
# Tell Eden about this branch repo
echo "$HOME/Development/eden-branches/work-repo" >> ~/.config/eden/branches

# Eden will stow all registered branch repos automatically
```

### 3. Deploy (Manual for Now)

```bash
# Stow the branch repo
stow -t $HOME -d ~/Development/eden-branches/work-repo .config
```

Your branch repo configs now overlay Eden's base configs!

## Branch Structure

A branch repo should mirror the parts of `$HOME` it wants to populate:

```
eden-branches/work-repo/
  └── .config/
      └── eden/
          └── local/
              ├── gitconfig.work
              ├── zshrc.work
              └── ssh/
                  └── config.work
```

When stowed: `.config/eden/local/gitconfig.work` → `~/.config/eden/local/gitconfig.work`

## Multiple Branches

Eden supports multiple branch repos simultaneously:

```bash
# ~/.config/eden/branches
/home/stefan/Development/eden-branches/work-repo
/home/stefan/Development/eden-branches/personal-repo
/home/stefan/Development/eden-branches/client-acme-repo
```

Each branch repo stows independently. Later branches can override earlier ones if they define the same files.

## Branch Use Cases

**work-repo**: Work email, VPN configs, company git aliases  
**personal-repo**: Experimental zsh themes, beta tool configs  
**client-repo**: Per-client contexts (different emails/credentials)  
**machine-repo**: Machine-specific overrides (different hardware)

## Templates in This Directory

- `gitconfig.template` - Base local git config with conditional includes
- `gitconfig.work.template` - Work-specific git settings
- More templates as Eden grows...

Copy these into your branch repo and customize!

## Future: Eden Branch Manager

Eventually, Eden will have commands like:
```bash
eden branch add work ~/Development/eden-branches/work-repo
eden branch list
eden branch deploy
```

For now, manage branch repos manually with the `~/.config/eden/branches` file.
