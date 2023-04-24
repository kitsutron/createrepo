# createrepo

## Table of Contents

1. [Module description](#description)
1. [Setup - The basics of getting started with createrepo](#setup)
    * [What createrepo affects](#what-createrepo-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with createrepo](#beginning-with-createrepo)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Module description

Createrepo is a linux repository management tool. It provides the ability to
create and manage local package repositories on a server you control, which can
either contain local packages you create or packages you sync from a remote
source. This Puppet module streamlines installing and configuring createrepo as
well as configuring periodic rescans of repo content and presenting created
repos using Apache/HTTPD.

## Setup

### What createrepo affects

* Configuration files and directories
** Optional cron files under `/etc/cron.d/`
** Optional Apache vhosts under `/etc/httpd/sites-available` and `/etc/httpd/sites-enabled`
* Package files for createrepo
* Optional package files for Apache
** **WARNING:** Do not configure this module to manage Apache if you are installing it using another Puppet module.

### Beginning with createrepo

To have Puppet install createrepo, declare the createrepo class:
```
class { 'createrepo': }
```

When you declare createrepo with no parameters set, the module will
* Install the createrepo package
* Install and configure the Apache package
* Create the `sites-available` and `sites-enabled` directories under Apache's config directory
* Deploy a default VHost to `sites-enabled`

**Note:** Apache VHosts will declare a ServerName of `<repo name>.<host fqdn>`.
You will need to add these records to DNS as either CNAME or A records.

## Usage

To have Puppet install createrepo and deploy a repository, override the repo
hash (empty by default). This will create repos under the path specified by
`createrepo::params::repo_base`.
```
class { 'createrepo':
  repo => {
    foo => {},
    bar => {},
    baz => {},
  }
}
```

The repo hash can also be overridden in hiera using the following:
```
---
createrepo::repo:
  foo: {}
  bar: {}
  baz: {}
```

Repositories will default to refreshing their index every 5 minutes. To disable
this behavior, set the desired repo's `auto_refresh` parameter to false.

The refresh time can also be adjusted by changing the value of the
`refresh_period` parameter using crontab syntax.

Finally, a timeout can be set for executing the createrepo command to ensure if
there are any issues, the command will not wait forever to time out. This can
be set with the `timeout` parameter which defaults to 300 seconds (5 minutes).

The following example creates 3 repositories. The first will not automatically
refresh. The second will refresh every 30 minutes. The third will timeout if
the createrepo command takes longer than 10 minutes to execute.
```
class { 'createrepo':
  repo => {
    foo => { auto_refresh => false, },
    bar => { refresh_period => '*/30 * * * * *'},
    baz => { timeout => 600 },
  }
}
```

These options can also be specified in hiera:
```
---
createrepo::repo:
  foo:
    auto_refresh: false
  bar:
    refresh_period: '*/30 * * * * *'
  baz:
    timeout: 600
```

## Limitations

Management of apache using this module should be disabled when using another
module to manage Apache in your environment.

Apache VHosts in this module are simple VHosts with the following configuration:
```
<VirtualHost *:80>
  ServerName foo.your.host.fqdn
  ServerAlias foo.yor.host.fqdn

  DocumentRoot /var/www/html/repos/foo
</VirtualHost>
```

These VHosts can be added to your existing Apache configuration instead.

## Release Notes/Contributors/Etc. **Optional**

### 1.0.0
* Initial module release.
