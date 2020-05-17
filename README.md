# The smallest SSH server container
The title says it all.

## Why?
Because, I needed a way to forward MySQL port from inside a kubernetes cluster to a dev (or even ops) computer, without needing to give full `kubectl` access to the kubernetes cluster. Using this image as a sidecar with the MySQL db container, and by using SSH port-forwarding, in concert with public part of SSH key-pairs, anyone can be given access to the MySQL service *"only"*.

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

Read more at https://gitlab.com/kamranazeem/docker-ssh-server

"Alpine Linux v3.10"
Connection to 172.17.0.2 closed.
[kamran@kworkhorse ssh-server]$ 
```

### Allow interactive shell/login:
```
[kamran@kworkhorse ssh-server]$ docker run \
  -e AUTH_KEYS_URL=https://gitlab.com/kamranazeem/public-ssh-keys/-/raw/master/authorized_keys \
  -e ALLOW_INTERACTIVE_LOGIN=true  \
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

Read more at https://gitlab.com/kamranazeem/docker-ssh-server

"Alpine Linux v3.10"

902b2ff30c4f:~$ 
```
