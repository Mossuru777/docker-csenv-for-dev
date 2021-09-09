################################################################################
# CSEnv for Development
# Stage Name: csenv-for-dev
################################################################################
FROM mossuru777/csenv:latest AS csenv-for-dev
MAINTAINER Mossuru777 "mossuru777@gmail.com"

# Install useful packages for development
RUN apt-get -q update \
    && apt-get -q -y install --no-install-recommends \
         sudo \
         vim \
         dnsutils \
         traceroute \
         git \
         ssh \
         tar \
         gzip \
         ca-certificates \
         nkf \
         zip \
    && apt-get -q clean \
    && rm -rf /var/lib/apt/lists/* \

# Use Perl version to that installed
    && mv /usr/bin/perl /usr/bin/perl.orig \
    && ln -s /usr/local/bin/perl /usr/bin/perl \

# Install IntelliJ Perl Remote Debugging Related Modules
    && cpanm --notest --no-man-pages Bundle::Camelcade

# Copy entrypoint script and make it executable
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

# Define EntryPoint
ENTRYPOINT ["entrypoint.sh"]



################################################################################
# CSEnv for Development with Apache
# Stage Name: csenv-for-dev-apache
################################################################################
FROM csenv-for-dev AS csenv-for-dev-apache

# Copy Apache site configuration
COPY apache/all-catch.conf /etc/apache2/sites-available/all-catch.conf

# Copy msmtprc template
COPY msmtp/msmtprc.template /usr/local/share/msmtp/

# Temporarily revert the Perl version to the original
RUN mv /usr/bin/perl /usr/bin/perl.new \
    && mv /usr/bin/perl.orig /usr/bin/perl \

# Install Apache, msmtp \
    && apt-get -q update \
    && apt-get -q -y install --no-install-recommends \
         apache2 \
         msmtp \
         msmtp-mta \
    && apt-get -q clean \
    && rm -rf /var/lib/apt/lists/* \

# Setup Apache
    && service apache2 stop \
    && a2enmod cgi \
    && a2dissite 000-default \
    && a2ensite all-catch \

# Add entrypoint step for configure/launch msmtp and apache when container starting
    && sed -i \
         -e '6ased -e "s@smtp_hostname\.invalid@${SMTP_HOSTNAME:-smtp_hostname.undefined.invalid}@" -e "s@own_hostname\.invalid@$(hostname)@" /usr/local/share/msmtp/msmtprc.template | sudo tee /etc/msmtprc > /dev/null'"\\n" \
         -e '6asudo sed -i -e "s@own_hostname\.invalid@$(hostname)@" /etc/apache2/sites-available/all-catch.conf'"\\n" \
         -e '6asudo rm -f /var/run/apache2/*'"\\n" \
         -e '6aif [ -n "${PERL5_DEBUG_ROLE}" ]; then' \
         -e '6a  echo -en "\\nexport PERL5_DEBUG_ROLE=${PERL5_DEBUG_ROLE}" | sudo tee -a /etc/apache2/envvars > /dev/null' \
         -e '6afi' \
         -e '6aif [ -n "${PERL5_DEBUG_HOST}" ]; then' \
         -e '6a  echo -en "\\nexport PERL5_DEBUG_HOST=${PERL5_DEBUG_HOST}" | sudo tee -a /etc/apache2/envvars > /dev/null' \
         -e '6afi' \
         -e '6aif [ -n "${PERL5_DEBUG_PORT}" ]; then' \
         -e '6a  echo -n "\nexport PERL5_DEBUG_PORT=${PERL5_DEBUG_PORT}" | sudo tee -a /etc/apache2/envvars > /dev/null' \
         -e '6afi'"\\n" \
         -e '6aecho "Starting for Apache WebServer..."'"\\n"'sudo /etc/init.d/apache2 start'"\\n" \
         /usr/bin/entrypoint.sh \

# Restore the Perl version to that installed
    && mv /usr/bin/perl /usr/bin/perl.orig \
    && mv /usr/bin/perl.new /usr/bin/perl \
    
# Create /var/www/html
    && mkdir -p /var/www/html \

# Configure User www-data to allow sudo
    && echo 'www-data ALL=NOPASSWD: ALL' >> /etc/sudoers.d/50-www-data \
    && echo 'Defaults:www-data env_keep += "PERL5_DEBUG_ROLE PERL5_DEBUG_HOST PERL5_DEBUG_PORT"' >> /etc/sudoers.d/50-www-data \
    && echo 'Defaults    env_keep += "DEBIAN_FRONTEND"' >> /etc/sudoers.d/env_keep

# Switch User to www-data
WORKDIR /var/www
USER www-data

# Define default command (Start Apache Webserver and then watch error logs.)
CMD ["sudo", "/usr/bin/tail", "-F", "/var/log/apache2/error.log"]

# Define mountable directories
VOLUME ["/var/www/html"]

# Expose Apache WebServer Port
EXPOSE 80

# Expose Perl Remote Debug Port (Camelcadedb)
EXPOSE 7765
