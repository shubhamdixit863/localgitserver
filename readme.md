# Docker Image for SSH and Apache2 with Git

This Docker image is based on Ubuntu latest version and includes Apache2, Git, and SSH server setup for general web and Git repository serving purposes.

## Features

- **Ubuntu Latest**: Based on the latest version of Ubuntu.
- **Apache2**: Web server set up with SSL and CGI modules enabled.
- **SSH Server**: SSH access configured with root login enabled.
- **Git Repository**: Bare Git repository set up under Apache for HTTP and HTTPS access.
- **Security**: Basic authentication set up for Git access.

## Getting Started

These instructions will cover usage information and for the docker container.

### Prerequisities

In order to run this container, you'll need Docker installed:

- [Windows](https://docs.docker.com/windows/started)
- [OS X](https://docs.docker.com/mac/started/)
- [Linux](https://docs.docker.com/linux/started/)

### Installing

Pull the image from the Docker repository:

```bash
docker pull yourusername/yourimagename:tag
```

Or build the image using the Dockerfile:

```bash
docker build -t yourusername/yourimagename:tag .
```

For multiarch build

```bash
sudo docker buildx build  --no-cache --build-arg REPO_COUNT=5 --platform linux/amd64,linux/arm64 -t quay.io/numaio/localgitserver:latest --push .

```

### Usage

#### Container Parameters

Run the container with the following command,changethe the volume path if and when required

```bash
sudo docker build --no-cache --build-arg REPO_COUNT=5   -t localgitserver .

docker run  -d \
  -v "$(pwd)/authorized_keys":/root/.ssh/authorized_keys \
  -v "$(pwd)/.htpasswd":/auth/.htpasswd \
  -p 2222:22 -p 8080:80 -p 8443:443 \
  --name localgitserver \
  localgitserver
```

This will start the container with SSH, HTTP, and HTTPS access. You can access the services provided by the container by connecting to the ports mapped on your host.

#### Environment Variables

None specified.

#### Volumes

None specified.

### Accessing Services

- **SSH**: Connect via SSH at `ssh root@<host-ip>`. The default password is `root`.
- **HTTP**: Access the Git repository by navigating to `http://<host-ip>/git/test.git`.
- **HTTPS**: Access the Git repository securely by navigating to `https://<host-ip>/git/test.git`.

## Built With

- Ubuntu
- Apache2
- OpenSSH Server
- Git

## To Geneerate new apache username password

`htpasswd -c .htpasswd root`

## Find Us

- [GitHub](https://github.com/shubhamdixit863)

## Authors

- **Shubham Dixit** - _Initial work_ - [Shubhamd dixit](https://github.com/shubhamdixit863)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
