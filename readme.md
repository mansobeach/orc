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

### Database configuration

```
<Inventory>
    <Database_Adapter>postgresql</Database_Adapter>
    <Database_Host>localhost</Database_Host>
    <Database_Port>5432</Database_Port>      
    <Database_Name>minarc</Database_Name>
    <Database_User>minarc</Database_User>
    <Database_Password>minarc</Database_Password>
</Inventory>
```

### Execution

```
export MINARC_PLUGIN=S2PDGS
orcUnitTests
```


