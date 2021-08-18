FROM ghcr.io/mossuru777/docker-csenv/csenv-for-test-apache-general:latest
MAINTAINER Mossuru777 "mossuru777@gmail.com"

USER root

# Copy msmtprc template
COPY msmtprc.template /usr/local/share/msmtp/

# Install IntelliJ Perl Remote Debugging Related Modules
RUN cpanm --notest --no-man-pages Bundle::Camelcade \

# Install & Setup msmtp
    && mv /usr/bin/perl /usr/bin/perl.new && mv /usr/bin/perl.orig /usr/bin/perl \
    && apt-get -q update \
    && apt-get -q -y install --no-install-recommends \
         msmtp \
         msmtp-mta \
    && apt-get -q clean \
    && rm -rf /var/lib/apt/lists/* \
    && mv /usr/bin/perl /usr/bin/perl.orig && mv /usr/bin/perl.new /usr/bin/perl \
    && sed -i -e '/set -e/a \\nsudo sh -c "sed -e \\"s@smtp_hostname\\.invalid@\${SMTP_HOSTNAME:-smtp_hostname.undefined.invalid}@\\" -e \\"s@own_hostname\\.invalid@\$(hostname)@\\" \/usr\/local\/share\/msmtp\/msmtprc.template > \/etc\/msmtprc"' /usr/bin/entrypoint.sh \

# Add hostname of Gateway(Host) to resolve its IP address
    && sed -i -e '3aecho -e "$(/sbin/ip -4 route list match 0/0 | /usr/bin/awk "{ print \\$3 }")\\thost.docker.internal" | sudo tee -a /etc/hosts > /dev/null'"\\n" /usr/bin/entrypoint.sh

# Switch User to www-data
WORKDIR /var/www
USER www-data

# Define default command (Start Apache Webserver and then watch error logs.)
ENTRYPOINT ["entrypoint.sh"]
CMD ["sudo", "/usr/bin/tail", "-F", "/var/log/apache2/error.log"]

# Define mountable directories
VOLUME ["/var/www/html"]

# Expose Apache WebServer Port
EXPOSE 80
