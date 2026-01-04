FROM archlinux:latest

# 1. Update and install base requirements
# Added python-pipx explicitly here so mise can use it
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    base-devel git sudo curl vim unzip man-db openssh jq python-pipx

# 2. Create the user 'agfonseca'
RUN useradd -m -G wheel -s /bin/bash agfonseca && \
    echo "agfonseca ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 3. Install MISE
RUN curl https://mise.jdx.dev/install.sh | sh && \
    mv /root/.local/bin/mise /usr/local/bin/mise

# 4. MOCK Helper
# IMPORTANT: We do NOT mock pipx anymore, because we installed the real one above.
# We still mock 'yay' because we don't want to build AUR packages in this test.
RUN printf "#!/bin/bash\necho \"[MOCK] \$0 \$*\"" > /usr/local/bin/mock-template && chmod +x /usr/local/bin/mock-template && \
    cp /usr/local/bin/mock-template /usr/local/bin/omarchy-webapp-install && \
    cp /usr/local/bin/mock-template /usr/local/bin/omarchy-install-tailscale && \
    cp /usr/local/bin/mock-template /usr/local/bin/omarchy-tui-install && \
    cp /usr/local/bin/mock-template /usr/local/bin/omarchy-install-dev-env && \
    cp /usr/local/bin/mock-template /usr/local/bin/omarchy-debug && \
    cp /usr/local/bin/mock-template /usr/local/bin/yay && \
    cp /usr/local/bin/mock-template /usr/local/bin/systemctl && \
    cp /usr/local/bin/mock-template /usr/local/bin/sysctl && \
    chmod +x /usr/local/bin/omarchy-* /usr/local/bin/yay /usr/local/bin/systemctl /usr/local/bin/sysctl

# 5. Set up directory and COPY files
WORKDIR /home/agfonseca/Work/dotfiles
COPY . .
RUN chown -R agfonseca:agfonseca /home/agfonseca

# 6. Switch to user
USER agfonseca
ENV PATH="/usr/local/bin:/home/agfonseca/.local/bin:$PATH"

# 7. Pre-configure git
RUN git config --global user.email "test@example.com" && \
    git config --global user.name "Test User"

# Run setup.sh by default
CMD ["./setup.sh"]