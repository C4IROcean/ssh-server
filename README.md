# The smallest SSH server container
The title says it all.

## Why?
Because, I needed a way to forward MySQL port from inside a kubernetes cluster to a dev (or even ops) computer, without needing to give full `kubectl` access to the kubernetes cluster. Using this image as a sidecar with the MySQL db container, and by using SSH port-forwarding, in concert with public part of SSH key-pairs, anyone can be given access to the MySQL service *"only"*.

## How to setup SSH tunnel with mysql using this sidecar?

```
[kamran@kworkhorse ~]$ ssh -L 3306:127.0.0.1:3306 -p 32222 sshuser@34.142.115.100
mysql-0:~$
```

Now open another terminal and use normal mysql command to connect to this forwarded port:
```
[kamran@kworkhorse ~]$ mysql -h 127.0.0.1 -u dbadmin -p
Enter password: 

MariaDB [(none)]>

MariaDB [(none)]> show databases;
```

## What if I have a local mysql instance running already on port 3306?
If - for some reason - you have a local mysql instance on your local computer, then simply edit the command shown above, and assign a different port number to the forwarded port on local computer.

Example:
```
[kamran@kworkhorse ~]$ ssh -L 33060:127.0.0.1:3306 -p 32222 sshuser@34.142.115.100
mysql-0:~$
```

Then, use the mysql command with extra `-P 33060` parameter:


```
[kamran@kworkhorse ~]$ mysql -h 127.0.0.1 -P 33060 -u dbadmin -p
Enter password: 

MariaDB [(none)]> 
``` 

## Can "anyone" login to my SSH container?

Or, **"Can "anyone" get access to my DB service through this SSH container?"**

**No.** The only people who will ever be able to **login**, or use **port-forwarding** will be the ones having their keys saved inside the git repository, which is used in this container. We maintain a single `authorized_keys` file in that repository, and pull only the master branch, which is locked and protected. So only the admins will be able to allow who gets in. The repository itself does not need to be private, as it only contains public keys anyway. Still, if you don't understand how *"public key authentication"* works, or if you are just paranoid, you can make the repository private to your team.

Of-course the entire thing will only work when you provide a link to the authorized_keys file as an environment variable. If you don't, then there are absolutely no keys in the container, and no one will ever be able to use it. 

**There are no default/hidden public keys placed in this image**. It should be as safe as the underlying OS permits, which is Alpine Linux.

## How does it work?
We keep a list of user's ssh keys in a (separate) git repository and use the raw link of the authorized_keys file from the master branch of that repository, by passing it as an environment variable (`AUTH_KEYS_URL`) to the container. The container pulls this file from the URL, and stores it as `/home/sshuser/.ssh/authorized_keys`. The user then connects to this container using `sshuser` user account.

By default, the user is not allowed interactive shell login. If you want interactive login, you will need to setup another environment variable (`ALLOW_INTERACTIVE_LOGIN`).

## Environment variables used in this image:
### `AUTH_KEYS_URL` 
Example: `AUTH_KEYS_URL=https://gitlab.com/kamranazeem/public-ssh-keys/-/raw/master/authorized_keys`

### `ALLOW_INTERACTIVE_LOGIN`
Example: `ALLOW_INTERACTIVE_LOGIN=true`

**Note:** Any value other than the word `true` is ignored.

### `TZ`
You would want that any incoming SSH connections are logged with correct timestamp according to the timezone. That is why `tzdata` is added to the container. Use `TZ` environment variable to set (and use) timezone for your ssh container instance.

Example: `TZ=Europe/London`

**Note:** List of time zones can be obtained by listing the contents of `/usr/share/zoneinfo/` .

## Test run / examples:

### Run without using any git repository URL for `authorized_keys`:
```
[kamran@kworkhorse ssh-server]$ docker run -d local/ssh-server
```

Notice, I can't connect, nor login:
```
[kamran@kworkhorse ssh-server]$ ssh sshuser@172.17.0.2
Received disconnect from 172.17.0.2 port 22:2: Too many authentication failures
Disconnected from 172.17.0.2 port 22
[kamran@kworkhorse ssh-server]$ 
```


### Using a git repository for `authorized_keys`: 
```
[kamran@kworkhorse ssh-server]$ docker run \
  -e AUTH_KEYS_URL=https://gitlab.com/kamranazeem/public-ssh-keys/-/raw/master/authorized_keys  \
  -d local/ssh-server 
```

Notice, I can connect, but am not allowed an interactive shell/login. The helpful text below is coming from `/etc/motd` file.
```
[kamran@kworkhorse ssh-server]$ ssh sshuser@172.17.0.2
Welcome to Alpine based ssh-server!

How does it work?
----------------
You should have a list of user's (public) ssh keys (in openssh format), 
  in a (separate) git repository. Then use the raw link of the 
  authorized_keys file from the master branch of that repository, 
  by passing it as an environment variable (`AUTH_KEYS_URL`) to the container. 
  The container pulls this file from the URL, 
  and stores it as `/home/sshuser/.ssh/authorized_keys`. 

Then, you can connect to this container using `sshuser` user account. 

Remember, by default, the user is not allowed interactive shell login, 
  because the purpose is just to use this container for "port-forwarding" 
  over SSH connection. 

If you want interactive login as well, you will need to pass 
  another environment variable (`ALLOW_INTERACTIVE_LOGIN`).

Use `TZ` environment variable to set (and use) correct timezone 
  for your ssh container instance.
  
Read more at https://gitlab.com/kamranazeem/ssh-server

"Alpine Linux v3.10"
Connection to 172.17.0.2 closed.
[kamran@kworkhorse ssh-server]$ 
```

### Allow interactive shell/login:
```
[kamran@kworkhorse ssh-server]$ docker run \
  -e AUTH_KEYS_URL=https://gitlab.com/kamranazeem/public-ssh-keys/-/raw/master/authorized_keys \
  -e ALLOW_INTERACTIVE_LOGIN=true  \
  -e TZ=Europe/London \
  -d local/ssh-server 
```

Notice, this time I am able to connect, and login interactively.
```
[kamran@kworkhorse ssh-server]$ ssh sshuser@172.17.0.2
Welcome to Alpine based ssh-server!

How does it work?
----------------
You should have a list of user's (public) ssh keys (in openssh format), 
  in a (separate) git repository. Then use the raw link of the 
  authorized_keys file from the master branch of that repository, 
  by passing it as an environment variable (`AUTH_KEYS_URL`) to the container. 
  The container pulls this file from the URL, 
  and stores it as `/home/sshuser/.ssh/authorized_keys`. 

Then, you can connect to this container using `sshuser` user account. 

Remember, by default, the user is not allowed interactive shell login, 
  because the purpose is just to use this container for "port-forwarding" 
  over SSH connection. 

If you want interactive login as well, you will need to pass 
  another environment variable (`ALLOW_INTERACTIVE_LOGIN`).

Use `TZ` environment variable to set (and use) correct timezone 
  for your ssh container instance.

Read more at https://gitlab.com/kamranazeem/ssh-server

"Alpine Linux v3.10"

902b2ff30c4f:~$ date
Mon May 18 13:16:33 BST 2020
902b2ff30c4f:~$
```

------

### Acknowledgment/Credits: 
This SSH container is built on the ideas generated during a workshop with my friend [Salman Mukhtar](https://gitlab.com/mesalman).
