FROM ubuntu:latest

ARG REPO_COUNT=1


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
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    touch /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys

# Enable Apache SSL and CGI modules
RUN a2enmod ssl && \
    a2enmod cgi && \
    a2enmod auth_basic && \
    a2enmod authn_file && \
    a2ensite default-ssl

# Set up Apache to serve the Git repository
# Create multiple repositories based on the REPO_COUNT argument
RUN for i in $(seq 1 $REPO_COUNT); do \
    mkdir -p "/var/www/git/repo$i.git" && \
    git init --bare "/var/www/git/repo$i.git" && \
    chown -R www-data:www-data "/var/www/git/repo$i.git"; \
    done

# Setup Apache for Git HTTP and HTTPS access with Basic authentication
RUN mkdir /auth && \
    htpasswd -cb /auth/.htpasswd root root && \
    echo "<VirtualHost *:80>\n\
    SetEnv GIT_PROJECT_ROOT /var/www/git\n\
    SetEnv GIT_HTTP_EXPORT_ALL\n\
    ScriptAlias /git/ /usr/lib/git-core/git-http-backend/\n\
    <Location /git>\n\
    AuthType Basic\n\
    AuthName \"Git Access\"\n\
    AuthUserFile /auth/.htpasswd\n\
    Require valid-user\n\
    </Location>\n\
    </VirtualHost>\n\
    <VirtualHost *:443>\n\
    SSLEngine on\n\
    SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem\n\
    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key\n\
    SetEnv GIT_PROJECT_ROOT /var/www/git\n\
    SetEnv GIT_HTTP_EXPORT_ALL\n\
    ScriptAlias /git/ /usr/lib/git-core/git-http-backend/\n\
    <Location /git>\n\
    AuthType Basic\n\
    AuthName \"Git Access\"\n\
    AuthUserFile /auth/.htpasswd\n\
    Require valid-user\n\
    </Location>\n\
    </VirtualHost>" > /etc/apache2/sites-available/000-default.conf


# Enable the site and ensure the Apache user can read the .htpasswd file
RUN a2ensite 000-default && \
    chmod 644 /auth/.htpasswd && \
    chown www-data:www-data /auth/.htpasswd

# Expose port 22 for SSH access, 80 for HTTP access, and 443 for HTTPS access
EXPOSE 22 80 443


RUN for i in $(seq 1 $REPO_COUNT); do \
    mkdir /tmp/git-repo$i && \
    cd /tmp/git-repo$i && \
    git init && \
    git config --global user.email "you@example.com" && \
    git config --global user.name "Your Name" && \
    echo "some: data" > data.yaml && \
    git add data.yaml && \
    git commit -m "Initial commit" && \
    git push /var/www/git/repo$i.git master;\
    done


# Copy the start script into the container and set permissions
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Command to run the startup script
CMD ["/start.sh"]
