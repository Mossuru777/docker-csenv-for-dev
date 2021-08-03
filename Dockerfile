FROM ghcr.io/mossuru777/docker-csenv/csenv-for-test:latest
MAINTAINER Mossuru777 "mossuru777@gmail.com"

USER root

# Install IntelliJ Perl Remote Debugging Related Modules
RUN cpanm --notest Bundle::Camelcade

# Install & Setup msmtp
RUN mv /usr/bin/perl /usr/bin/perl.new && mv /usr/bin/perl.orig /usr/bin/perl \
    && apt-get update \
    && apt-get -q -y install --no-install-recommends \
         msmtp \
         msmtp-mta \
    && apt-get -q -y clean \
    && rm -rf /var/lib/apt/lists/* \
    && mv /usr/bin/perl /usr/bin/perl.orig && mv /usr/bin/perl.new /usr/bin/perl
COPY msmtprc.template /usr/local/share/msmtp/
RUN sed -i -e '/set -e/a \\nsudo sh -c "sed -e \\"s@smtp_hostname\\.invalid@\${SMTP_HOSTNAME:-smtp_hostname.undefined.invalid}@\\" -e \\"s@own_hostname\\.invalid@\$(hostname)@\\" \/usr\/local\/share\/msmtp\/msmtprc.template > \/etc\/msmtprc"' /usr/bin/entrypoint.sh

USER www-data

# Define default command (Start LiteSpeed Webserver and then watch error logs.)
ENTRYPOINT ["entrypoint.sh"]
CMD ["/usr/bin/tail", "-F", "/usr/local/lsws/logs/stderr.log", "/usr/local/lsws/logs/error.log"]

# Define mountable directories
VOLUME ["/var/www/html"]

# Expose LiteSpeed WebAdmin Port
EXPOSE 7080

# Expose LiteSpeed WebServer Port
EXPOSE 80