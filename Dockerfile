FROM alpine:3.10

# Our authorized_keys file path will always be fixed, so we don't need git to pull it.
# e.g. https://gitlab.com/mesalman/ssh-keys/-/raw/master/authorized_keys

# Notes:
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

EXPOSE 22

RUN apk update \
    && apk add bash openssh rsync shadow \
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
