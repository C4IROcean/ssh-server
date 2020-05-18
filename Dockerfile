FROM alpine:3.11

# Notes:
# * The authorized_keys file will always be a fixed direct URL to the file itself, 
#     so we don't need to add/install "git" to pull it. 
#     Wget is enough, which is already part of alpine linux.
#     e.g. https://gitlab.com/kamranazeem/public-ssh-keys/-/raw/master/authorized_keys
# * The instructions: "mkdir -p ~root/.ssh && chmod 700 ~root/.ssh/" seems unnecessary,
#     but they are needed to be able to run ssh-keygen as root, 
#     which in-turn is needed by sshd server process - later.
# * There is a password being generated for the user "sshuser",
#     because otherwise the account of "sshuser" remains locked,
#     and the user will not be able to login even if we setup authorized_keys file for it.
#     This password will never be used, because password-based login is disabled.
# * The only user able to login to this container over SSH will be sshuser, 
#     by using SSH keys.
# * The `/bin/true` prevents the user logging in interactively. 
#     So, by default the users can only do SSH tunnels.
# * If you have a need for interactive login, 
#     then set the environment variable `ALLOW_INTERACTIVE_LOGIN` to `true`
# * tzdata is added to be able to record any incoming ssh connections 
#     with the correct timestamp of the timezone related to the infrastructure.
#     It adds some megabytes in size, but is necessary for auditing.
# * Use TZ environment variable to set (and use) timezone for your ssh instance.
#   

EXPOSE 22


RUN apk update \
    && apk add openssh rsync shadow tzdata \
    && mkdir -p ~root/.ssh && chmod 700 ~root/.ssh/ \
    && ssh-keygen -A \
    && PASSWORD=$(date | sha256sum | cut -d ' ' -f 1) \
    && useradd -m sshuser -p ${PASSWORD} -s /bin/true \
    && mkdir -p ~sshuser/.ssh && chown -R sshuser:sshuser ~sshuser && chmod -R 700 ~sshuser \
    && rm -rf /var/cache/apk/*

COPY sshd_config /etc/ssh/
COPY motd /etc/
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/sbin/sshd", "-D", "-e", "-f", "/etc/ssh/sshd_config"]
