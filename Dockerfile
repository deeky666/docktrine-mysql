FROM deeky666/base

MAINTAINER Steve Müller "st.mueller@dzh-online.de"

ARG MYSQL_VERSION

# Download and install MySQL server $MYSQL_VERSION as lightweight package.
RUN \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        perl \
        wget \
        && \

    groupadd mysql && \
    useradd -r -g mysql mysql && \

    mkdir -p /mysql/conf.d /mysql/srv /mysql/log /usr/local/mysql && \
    touch /mysql/log/error.log && \
    chown -R mysql:mysql /mysql/srv /mysql/log && \
    chmod 755 /mysql/conf.d && \
    chmod -R 700 /mysql/srv && \
    touch /mysql/conf.d/my.cnf && \

    cd /tmp && \

    wget \
        -nv \
        --no-check-certificate \
        -O mysql.tar.gz \
        http://dev.mysql.com/get/mysql-$MYSQL_VERSION-linux-glibc2.5-x86_64.tar.gz || \

    wget \
        -nv \
        --no-check-certificate \
        -O mysql.tar.gz \
        http://dev.mysql.com/get/mysql-$MYSQL_VERSION-linux2.6-x86_64.tar.gz || \

    wget \
        -nv \
        --no-check-certificate \
        -O mysql.tar.gz \
        http://dev.mysql.com/get/mysql-$MYSQL_VERSION-linux-x86_64-glibc23.tar.gz || \

    wget \
        -nv \
        --no-check-certificate \
        -O mysql.tar.gz \
        http://dev.mysql.com/get/mysql-standard-$MYSQL_VERSION-linux-x86_64-glibc23.tar.gz && \

    tar xf mysql.tar.gz --strip 1 && \

    cp -p bin/my_print_defaults /usr/sbin/ && \
    cp -p bin/mysql /usr/bin/ && \
    cp -p bin/mysqld /usr/bin/ && \
    cp -p bin/mysqld_safe /usr/sbin/ && \
    cp -rp share /usr/local/mysql/ && \

    sed -i "s/'localhost',\s*'root'/'%','root'/g" share/mysql_system_tables_data.sql || \
    sed -i "s/'localhost',\s*'root'/'%','root'/g" bin/mysql_create_system_tables && \

    ./scripts/mysql_install_db --basedir=. --user=mysql --datadir=/mysql/srv || \
    ( \
        echo "UPDATE mysql.user SET Host='%' WHERE Host='localhost' AND User='root';" > init.sql && \
        echo "FLUSH PRIVILEGES;" >> init.sql && \
        ./bin/mysqld --initialize-insecure --init-file=/tmp/init.sql --basedir=. --user=mysql --datadir=/mysql/srv \
    ) && \

    apt-get purge --auto-remove -y \
        perl \
        wget \
        && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /mysql/srv/ib*

# Copy MySQL configuration file which is used as fixed basic server configuration.
ADD ./my.cnf /etc/my.cnf

# Expose volumes for custom server configuration, data and log files.
VOLUME ["/mysql/conf.d", "/mysql/log", "/mysql/srv"]

# Define MySQL server binary as entrypoint.
ENTRYPOINT ["/usr/sbin/mysqld_safe", "--defaults-extra-file=/mysql/conf.d/my.cnf", "--ledir=/usr/bin"]

# Expose MySQL server port 3306.
EXPOSE 3306

COPY healthcheck /usr/local/bin/

HEALTHCHECK --interval=1s --retries=30 CMD ["healthcheck"]
