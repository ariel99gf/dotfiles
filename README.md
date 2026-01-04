# 🚀 Ariel's Dotfiles (DevOps Profile)

This repository contains my personal configuration files (dotfiles) and setup scripts to bootstrap a professional DevOps environment on Arch Linux (specifically targeted for **Omarchy**).

It focuses on:
*   **Infrastructure as Code:** Terraform, Ansible, Kubernetes.
*   **Cloud Security:** Prowler, Checkov, ScoutSuite (installed via Mise/Pipx).
*   **Productivity:** Neovim, Tmux, Starship, Zoxide.
*   **Automation:** Comprehensive `setup.sh` script.

## 🛠 Installation

To bootstrap a new machine:

```bash
# Clone the repository
git clone https://github.com/ariel99gf/dotfiles.git ~/Work/dotfiles
cd ~/Work/dotfiles

# Run the setup script
./setup.sh
```

## 🧪 Testing

This repository includes a Docker-based test suite to verify the `setup.sh` script logic in a clean environment.

### Prerequisites
*   Docker (or Rancher Desktop / Podman)

### Running Tests

To test the installation process inside a container (mocking system commands):

```bash
./tests/run_tests.sh
```

> **Note:** The test suite mocks Omarchy-specific commands (`omarchy-webapp-install`, etc.) and uses `pacman` to install base dependencies, validating that the script flow works correctly from start to finish.
