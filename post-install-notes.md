# Fresh Post-Install Notes

## tealdeer (tldr replacement)

After installation, run once to download the tldr pages cache:

```bash
tldr --update
```

Then use it like normal tldr:
```bash
tldr tar
tldr rsync
tldr stow
```

**Note:** `tealdeer` provides the `tldr` command - it's a faster Rust implementation.

## Stow Usage for Dotfiles

**WRONG:** `stow -t ~ .` (tries to stow the current directory itself)

**CORRECT:**

From your dotfiles directory, stow each package individually:
```bash
# Individual packages
stow -t ~ bash
stow -t ~ zsh
stow -t ~ nvim

# Or all at once with a loop
for dir in */; do stow -t ~ "${dir%/}"; done

# Or if you're in parent directory of dotfiles
cd ~/dotfiles
stow */
```

**Explanation:**
- Stow expects each subdirectory to be a "package"
- Each package should mirror your home directory structure
- Example: `dotfiles/bash/.bashrc` → `~/.bashrc`

## rsync for Preserving Permissions

Instead of `cp -r`, use:
```bash
rsync -avH /source/path/ /dest/path/
```

Options:
- `-a` archive mode (preserves permissions, timestamps, symlinks)
- `-v` verbose
- `-H` preserve hard links
- `--progress` show progress
- `-n` dry run (test first!)

**Note the trailing slash:** `/source/path/` copies contents, `/source/path` copies the directory itself.
