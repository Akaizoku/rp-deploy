# RiskPro-deploy

RiskPro-deploy is a utility script to install, configure, and manage OneSumX for Risk Management.

## Usage

1.  Check the `default.ini` configuration file located under the `conf` folder;
2.  If needed, add custom configuration to the `custom.ini` configuration file in the same configuration folder;
3.  Update the database configuration in the file `database.ini`;
3.  Update the `grid.csv` configuration file;
4.  Update the `server.ini` configuration file;
5.  Place the license file (if any) in the directory `res\license`;
6.  Place the patches (if any) in the directory `res\patch`;
7.  Run the `Deploy-WildFly.ps1` script located with the appropriate parameter for the action to execute:
    -   backup:     Take a backup of the RiskPro database
    -   clean-up:   Clean-up RiskPro application files
    -   configure:  Configure RiskPro
    -   deploy:     Deploy RiskPro web-application
    -   extract:    Extract RiskPro distribution files
    -   install:    Install and configure RiskPro
    -   package:    Generate RiskPro web-application (WAR file)
    -   restore:    Restore backup of the RiskPro database
    -   show:       Display configuration
    -   undeploy:   Un-deploy RiskPro web-application
    -   uninstall:  Uninstall RiskPro
    -   upgrade:    Upgrade RiskPro
8.  Check the logs

## Configuration

### Script configuration

The default configuration of the utility is stored into `default.ini`. This file should not be amended. All custom configuration must be made in the `custom.ini` file. Any customisation done in that file will override the default values.

Below is an example of configuration file:

```ini
[Paths]
# Configuration directory
ConfDirectory       = \conf
# Directory containing the libraries
LibDirectory        = \lib

[Filenames]
# Server properties
ServerProperties    = server.ini
# Custom configuration
CustomProperties    = custom.ini
```

**Remark:** Sections (and comments) are ignored in these configuration files. You can make use of them for improved readability.

### Database configuration

The configuration of the database is done in the `database.ini` file located under the `conf` directory. It contains eleven prperties:

| Property              | Descripton                            |
| --------------------- | ------------------------------------- |
| DatabaseType          | Type of the database                  |
| DatabaseHost          | Name of the database server           |
| DatabaseInstance      | Name of the database instance         |
| DatabasePort          | Port used by the database             |
| DatabaseName          | Name of the RiskPro database          |
| DatabaseSchema        | Default schema of the database        |
| DatabaseCollation     | Collation of the database             |
| DatabaseUsername      | RiskPro database user name            |
| DatabaseUserPassword  | RiskPro database user password        |
| DatabaseAdminUsername | Database administration user name     |
| DatabaseAdminPassword | Database administration user password |

Below is an example of the configuration for a SQL Server database:

```ini
DatabaseType          = SQLServer
DatabaseHost          = 127.0.0.1
DatabaseInstance      = MSSQLSERVER
DatabasePort          = 1433
DatabaseName          = RiskPro
DatabaseSchema        = dbo
DatabaseCollation     = Latin1_General_BIN
DatabaseUsername      = RiskPro
DatabaseUserPassword  = welcome
DatabaseAdminUsername = sa
DatabaseAdminPassword = system
```

### Grid configuration

The configuration of the grid is done using the `grid.csv` configuration file.

### Server configuration

The `server.ini` file contains the configuration for each server of the grid. It contains six properties:

| Property          | Descripton                                     |
| ----------------- | ---------------------------------------------- |
| AdminPort         | Port used by the web-server management console |
| AppServerProtocol | HTTP protocol used                             |
| Hostname          | Name of the server                             |
| HTTPPort          | Standard port of the web-server                |
| ServiceName       | Name of the WildFly service                    |
| WebServerType     | Type of the web-server                         |

**Remark:** Each environment is delimited using sections.

Below is an example of the configuration for the application server:

```ini
# Web-application main host and TESS
[apphost]
AdminPort             = 9990
AppServerProtocol     = HTTP
Hostname              = 127.0.0.1
HTTPPort              = 8080
ServiceName           = WildFly
WebServerType         = WildFly
```

## Security

When running in unattended mode, the script will use the credentials provided in the configuration files. The passwords provided **must** be stored as a plain-text representation of a secure string.

In order to generate the required value, please use the command below with the corresponding password:

```powershell
ConvertFrom-SecureString -SecureString (ConvertTo-SecureString -String "<password>" -AsPlainText -Force) -Key (Get-Content -Path ".\res\security\encryption.key")
```

## Known issues

### RPD-1

> The archive file distribution-x.x.x-dist.zip is empty.

The distribution files of OneSumX for Risk Management version 9.9.0 and 9.10.0 were compressed in a way that prevents the [Expand-Archive](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.archive/expand-archive) PowerShell function to read the archive file (see [SalesForce ticket #00547102](https://wkfs.force.com/WKSupportPortal/5001T00001HZGFh)).

The workaround is to extract the files manually and recreate a new compressed file using Windows built-in compress utility or a third-party tool such as [WinRAR](https://www.win-rar.com/) or [7-Zip](https://www.7-zip.org/). This implies disabling the integrity check as the new distribution file will not have the same signature.
