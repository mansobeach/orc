# OS dependencies

## Ubuntu / Debian
```
sudo apt-get install curl libcurl4-openssl-dev jq libssl-dev sshpass libsqlite3-dev sqlite3 libpq-dev libxml2-utils ncftp p7zip-full
```

## Red Hat / CentOS
```
sudo dnf groupinstall "Development Tools"
sudo dnf install sqlite
yum install perl-IPC-Cmd curl curl-devel sqlite-devel libxml2 openssl-devel
```


# Auxiliary data converter

## Introduction
Install the aux gem before the orc gem. 

## Dependencies

```
gem install dotenv
```


## Build

```
rake -f build_orc.rake orc:build[orctest,localhost]
```


## Install

```
rake -f build_orc.rake orc:install[orctest,localhost]
```


## Execute unit tests

```
orcUnitTests
```


