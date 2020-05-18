#!/bin/sh
# entrypoint for ssh-server
# It expects an environment variable containing a web-link to a publicly available ssh-keys file.
# e.g. https://gitlab.com/kamranazeem/public-ssh-keys/-/raw/master/authorized_keys
# That file is then pulled and saved into /home/sshuser/.ssh/authorized_keys.
# There are other ways to provide this file too. 
#   For example by mounting a directory containing authorized_keys onto "/home/sshuser/.ssh/" .
# When the main authorized_keys file is updated on the web-link (git repo),
#   the container can simply by re-started, which will pull latest keys.

AUTH_KEYS_PATH=/home/sshuser/.ssh/authorized_keys

if [ ! -z "${AUTH_KEYS_URL}" ]; then
  echo "Downloading public authentication 'authorized_keys' file from AUTH_KEYS_URL: ${AUTH_KEYS_URL} ..."
  wget -q -O ${AUTH_KEYS_PATH} ${AUTH_KEYS_URL}
  echo "Found $(grep -v "^$" ${AUTH_KEYS_PATH}| wc -l) keys in ${AUTH_KEYS_PATH} file."
  chown sshuser:sshuser ${AUTH_KEYS_PATH}
else
  echo "The variable AUTH_KEYS_URL was found empty, just so you know!"
fi 


if [ "${ALLOW_INTERACTIVE_LOGIN}" == "true" ]; then
  echo "ALLOW_INTERACTIVE_LOGIN was set to true. Enabling interactive login ..."
  usermod -s /bin/sh sshuser
else
  echo "ALLOW_INTERACTIVE_LOGIN was not set. Interactive login will not be available"
fi

echo "Updating /etc/motd with the version of Alpine Linux being used ..."
grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//'  >> /etc/motd

# Execute the actual command mentioned in CMD of the Dockerfile, to start SSHD process.
echo "Now starting actual ssh server process ..."
echo "Executing: $@ ..."
exec "$@"
