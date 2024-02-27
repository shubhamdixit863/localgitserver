FROM ubuntu:latest


RUN apt-get update && \
    apt-get install -y git openssh-server apache2 apache2-utils ssl-cert && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up SSH access
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/^#?PasswordAuthentication\s+.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/^#?ChallengeResponseAuthentication\s+.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

# Add  SSH public key to root's authorized keys
RUN mkdir /root/.ssh && \
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHAtto0bVGTAUATJhiDTjKa/lZg1LYu+gdJcyn4cK8D local" > /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys

# Enable Apache SSL and CGI modules
RUN a2enmod ssl && \
    a2enmod cgi && \
    a2ensite default-ssl  # Enable the default SSL site configuration

# Set up Apache to serve the Git repository
RUN mkdir /var/www/git && \
    git init --bare /var/www/git/test.git && \
    chown -R www-data:www-data /var/www/git

# Setup Apache for Git HTTP and HTTPS access with Basic authentication
RUN mkdir /auth && \
    htpasswd -cb /auth/.htpasswd root root && \
    echo "<VirtualHost *:80>\n\
        SetEnv GIT_PROJECT_ROOT /var/www/git\n\
        SetEnv GIT_HTTP_EXPORT_ALL\n\
        ScriptAlias /git/ /usr/lib/git-core/git-http-backend/\n\
        <Directory \"/usr/lib/git-core\">\n\
            Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch\n\
            Require all granted\n\
        </Directory>\n\
        <Directory /var/www/git>\n\
            Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch\n\
            AuthType Basic\n\
            AuthName \"Git Access\"\n\
            AuthUserFile /auth/.htpasswd\n\
            Require valid-user\n\
        </Directory>\n\
        </VirtualHost>\n\
        <VirtualHost *:443>\n\
        SSLEngine on\n\
        SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem\n\
        SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key\n\
        SetEnv GIT_PROJECT_ROOT /var/www/git\n\
        SetEnv GIT_HTTP_EXPORT_ALL\n\
        ScriptAlias /git/ /usr/lib/git-core/git-http-backend/\n\
        <Directory \"/usr/lib/git-core\">\n\
            Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch\n\
            Require all granted\n\
        </Directory>\n\
        <Directory /var/www/git>\n\
            Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch\n\
            AuthType Basic\n\
            AuthName \"Git Access\"\n\
            AuthUserFile /auth/.htpasswd\n\
            Require valid-user\n\
        </Directory>\n\
        </VirtualHost>" > /etc/apache2/sites-available/000-default.conf

# Expose port 22 for SSH access, 80 for HTTP access, and 443 for HTTPS access
EXPOSE 22 80 443

# Initialize repository and add files
RUN mkdir /tmp/git-repo && \
    cd /tmp/git-repo && \
    git init && \
    git config --global user.email "you@example.com" && \
    git config --global user.name "Your Name" && \
    echo "some: data" > data.yaml && \
    git add data.yaml && \
    git commit -m "Initial commit" && \
    git push /var/www/git/test.git master


# Copy the start script into the container and set permissions
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Command to run the startup script
CMD ["/start.sh"]



