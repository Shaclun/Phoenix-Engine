# IMPORTANT

G2O Server requires **data.xml** file, without it, it won't work properly!
You need to generate this file by yourself, in order to do that:

1. Edit `config.xml`, set `<debug>true</debug>`
2. Run the default G2O Server
3. Join the server
4. Open up ingame debug console (tilde key)
5. Type: `generate data`
6. Copy the generated **data.xml** from `YOUR_GAME_PATH/Multiplayer/data.xml` to `SERVER_ROOT/data.xml`
7. Uncomment loading of **data.xml** file in **config.xml**

#### This file needs to be regenerated when you introduce new changes to:
- your game scripts (**gothic.dat**)
- your model scripts (.mds, e.g: **Humans.mds**)

# Docker setup

This project allows you to run your **Gothic 2 Online Server** via docker compose.  
It simplifies the overall setup and allows you to host your server with just `2` commands!

## Description

The **docker-compose.yml** defines three services that interact with each other:
- mysql-server

	Checkout `config/mysql.env` file and adjust the variables to your needs.  
	For more possible env var config values, checkout [official mysql image](https://hub.docker.com/_/mysql).  

	You can also include **.sql** files that will be imported during first `docker compose` in `migrations/` folder.  
	If for some reason migrations need to be imported in predefined order, name them alphabetically, e.g: `0-migration.sql`, `1-migration.sql`
	
- http-server

	To offer the best performance it's best to use external http server services like [nginx](https://hub.docker.com/_/nginx).  
	That way required download files wil be served quicker and more reliably to the players.

- server

	Base service that requires all of the required files:
	- scripts
	- modules
	- config
	
	Those files should be placed in root directory.

## Installation

Before you start using this project, you need to install newest docker.io package on your system.  
In order to do that, you can checkout this [article](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-22-04)

## G2O_Server configuration

### MySQL

To connect with your mysql-server you need to use `mysql-server` as IP, here's the code example:
```js
local conn = mysql_connect("mysql-server", "root", "root", "database")
```

### HTTP Server

For file downloader to work properly, configure it to use external http service.  
Checkout the following config example (you need to put it in `config.xml` file):
```xml
<downloader>
    <url>http://YOUR_SERVER_PUBLIC_IP:28971</url>
</downloader>
```

## Uploading root directory

Connect to your VPS server via any FTP client and upload this root folder  
with your gamemode and all required files to run it.

## Server managing commands

Before you proceed further, make sure to `cd` into folder that contains **`docker compose`.yml** that you've uploaded.  
If you're already in the right directory, checkout the common commands for achieving certain action.

### Running server
```bash
docker compose up -d --build
```

### Shutting down server
```bash
docker compose down
```

### Importing new migrations

If you need to re-import .sql migrations you need to first shutdown your services,  
and remove the volumes created by the `docker compose`.

After this operation you can safely restart all of the services in detached mode.

```bash
docker compose down -v
docker compose up -d
```

### Displaying server console output

```bash
docker compose logs server
```

### Attaching to running docker service

In some rare cases maybe you'd like to check if something works correctly in specific service.  
To attach to specific docker container (e.g g2o_server), you can use this command:

```bash
docker exec -it g2o_server_image-server-1 /bin/bash
```

Use `exit` command to go back to host.

## Customization

You can customize this image to your needs by defining new services, or removing the existing ones.  
The recommmended minimum services are **http-server** and **server**.
