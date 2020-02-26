# RiskPro deployment process

This document will present the step-by-step process to deploy OneSumX for Risk Management.

This document will display extracts of the logs for each step as a reference.

## Table of contents

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:1 -->

1.  [Table of contents](#table-of-contents)
2.  [Setup distribution files](#setup-distribution-files)
3.  [Setup database](#setup-database)
4.  [Configure the application server(s)](#configure-the-application-servers)
5.  [Package web-application](#package-web-application)
6.  [Deploy application](#deploy-application)
7.  [RiskPro administration](#riskpro-administration)
8.  [Smoke test](#smoke-test)

<!-- /TOC -->

## Setup distribution files

In this section, we will go through the steps to setup the RiskPro distribution files.

1.  Download the distribution file from Wolters Kluwer Product Download Center.
2.  Check file integrity using file hash.
    ```
    2020-02-26 17:29:50	INFO	Checking distribution source files
    DEBUG: C:\WKFS\Scripts\rp-deploy\res\checksum\distribution-9.14.0-dist.zip.md5
    DEBUG: Reference checksum:    9553174B7D820577DD464113F0C6F8BF
    DEBUG: Distribution checksum: 9553174B7D820577DD464113F0C6F8BF
    2020-02-26 17:29:50	CHECK	Distribution file integrity check successful
    ```
3.  Expand archive to target location.
    ```
    2020-02-26 17:29:50	INFO	Extracting RiskPro to C:\WKFS\RiskPro\rp-9.14.0
    DEBUG: Using native PowerShell v5.0 Expand-Archive function
    DEBUG: Expand archive to "C:\WKFS\RiskPro"
    DEBUG: Directory: C:\WKFS\RiskPro\rp-9.14.0
    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    d-----       26/02/2020     17:29                bin
    d-----       26/02/2020     17:29                conf
    d-----       26/02/2020     17:29                etc
    d-----       26/02/2020     17:29                ui
    d-----       26/02/2020     17:30                webapp
    ```
4.  Set `RP_HOME` environment variable.
    ```
    2020-02-26 17:30:08	INFO	Configuring RP_HOME environment variable
    DEBUG: Machine	RP_HOME=C:\WKFS\RiskPro\rp-9.14.0
    2020-02-26 17:30:10	CHECK	RP_HOME environment variable has been set
    ```

## Setup database

In this section, we will go through the steps to setup the RiskPro database.

1.  Setup RiskPro database.
    ```
    2020-02-26 17:30:10	INFO	Creating RiskPro database and user
    DEBUG: cmd.exe /c '"C:\WKFS\RiskPro\rp-9.14.0\bin\riskpro.bat" "C:\WKFS\RiskPro\rp-9.14.0\bin\setup-sqlserver.xml" createUser -D"sqlserver.cmdline"="sqlcmd" -D"sqlserver.collation"="Latin1_General_BIN" -D"sqlserver.db"="RiskPro" -D"sqlserver.host"="127.0.0.1\\MSSQLSERVER2017" -D"sqlserver.password"="welcome" -D"sqlserver.port"="1433" -D"sqlserver.schema"="dbo" -D"sqlserver.system.password"="system" -D"sqlserver.system.user"="sa" -D"sqlserver.user"="RiskPro" 2>&1'
    DEBUG: JAVA_HOME=C:\app\Java\jdk1.8.0_211
    java version "1.8.0_211"
    Java(TM) SE Runtime Environment (build 1.8.0_211-b12)
    Java HotSpot(TM) 64-Bit Server VM (build 25.211-b12, mixed mode)

    Buildfile: C:\WKFS\RiskPro\rp-9.14.0\bin\setup-sqlserver.xml

    createUser:
          [sql] Executing commands
          [sql] 8 of 8 SQL statements executed successfully

    BUILD SUCCESSFUL
    Total time: 10 seconds
    2020-02-26 17:30:21	CHECK	RiskPro database has been successfully created
    ```
2.  Load RiskPro database schema.
    ```
    2020-02-26 17:30:21	INFO	Load database schema
    DEBUG: cmd.exe /c '"C:\WKFS\RiskPro\rp-9.14.0\bin\riskpro.bat" "C:\WKFS\RiskPro\rp-9.14.0\bin\setup-sqlserver.xml" loadSchema -D"sqlserver.cmdline"="sqlcmd" -D"sqlserver.collation"="Latin1_General_BIN" -D"sqlserver.db"="RiskPro" -D"sqlserver.host"="127.0.0.1\\MSSQLSERVER2017" -D"sqlserver.password"="welcome" -D"sqlserver.port"="1433" -D"sqlserver.schema"="dbo" -D"sqlserver.system.password"="system" -D"sqlserver.system.user"="sa" -D"sqlserver.user"="RiskPro" 2>&1'
    DEBUG: JAVA_HOME=C:\app\Java\jdk1.8.0_211
    java version "1.8.0_211"
    Java(TM) SE Runtime Environment (build 1.8.0_211-b12)
    Java HotSpot(TM) 64-Bit Server VM (build 25.211-b12, mixed mode)

    Buildfile: C:\WKFS\RiskPro\rp-9.14.0\bin\setup-sqlserver.xml

    loadSchema:
         [echo] Scripts are loaded from [../etc/sqlserver]

    execSqlServer:
          [sql] Executing resource: C:\WKFS\RiskPro\rp-9.14.0\etc\sqlserver\creating_schema_sqlserver.sql
          [sql] 5162 of 5162 SQL statements executed successfully

    execSqlServer:
          [sql] Executing resource: C:\WKFS\RiskPro\rp-9.14.0\etc\sqlserver\insert_data_ref_table.sql
          [sql] 1 of 1 SQL statements executed successfully

    execSqlServer:
          [sql] Executing resource: C:\WKFS\RiskPro\rp-9.14.0\etc\sqlserver\setup_admin.sql
          [sql] 1 of 1 SQL statements executed successfully

    execSqlServer:
          [sql] Executing resource: C:\WKFS\RiskPro\rp-9.14.0\etc\sqlserver\setup_roles.sql
          [sql] 1 of 1 SQL statements executed successfully

    BUILD SUCCESSFUL
    Total time: 6 seconds
    2020-02-26 17:30:29	CHECK	Database schema has been successfully loaded
    ```
3.  Configure database partitionning (if applicable).
    ```
    2020-02-26 17:30:29	INFO	Enabling database partitioning
    DEBUG: cmd.exe /c '"C:\WKFS\RiskPro\rp-9.14.0\bin\riskpro.bat" "C:\WKFS\RiskPro\rp-9.14.0\bin\setup-sqlserver.xml" enablePartitioning -D"sqlserver.cmdline"="sqlcmd" -D"sqlserver.collation"="Latin1_General_BIN" -D"sqlserver.db"="RiskPro" -D"sqlserver.host"="127.0.0.1\\MSSQLSERVER2017" -D"sqlserver.password"="welcome" -D"sqlserver.port"="1433" -D"sqlserver.schema"="dbo" -D"sqlserver.system.password"="system" -D"sqlserver.system.user"="sa" -D"sqlserver.user"="RiskPro" 2>&1'
    DEBUG: JAVA_HOME=C:\app\Java\jdk1.8.0_211
    java version "1.8.0_211"
    Java(TM) SE Runtime Environment (build 1.8.0_211-b12)
    Java HotSpot(TM) 64-Bit Server VM (build 25.211-b12, mixed mode)

    Buildfile: C:\WKFS\RiskPro\rp-9.14.0\bin\setup-sqlserver.xml

    enablePartitioning:

    execSqlServer:
          [sql] Executing resource: C:\WKFS\RiskPro\rp-9.14.0\etc\sqlserver\installing_partitioning_sqlserver.sql
          [sql] 23 of 23 SQL statements executed successfully

    execSqlServer:
          [sql] Executing resource: C:\WKFS\RiskPro\rp-9.14.0\etc\sqlserver\managing_partitioning_sqlserver.sql
          [sql] 26 of 26 SQL statements executed successfully

    execSqlServer:
          [sql] Executing resource: C:\WKFS\RiskPro\rp-9.14.0\etc\sqlserver\call_perform_param_partitioning.sql
          [sql] 1 of 1 SQL statements executed successfully

    BUILD SUCCESSFUL
    Total time: 7 seconds
    2020-02-26 17:30:37	CHECK	Database partinioning has been successfully enabled
    ```
4.  Define grid configuration in the database.
    ```
    2020-02-26 17:30:37	INFO	Setup RiskPro calculation configuration
    DEBUG: IF EXISTS (SELECT COUNT(1) FROM RiskPro.dbo.SLV_CONFIGURATION_DESC WHERE SLV_CONFIGURATION_DESC_ID = 1)
    BEGIN
    	UPDATE RiskPro.dbo.SLV_CONFIGURATION_DESC SET INITIAL_PORT = 8280, VERSION_KEY = -1 WHERE SLV_CONFIGURATION_DESC_ID = 1
    END
    ELSE
    BEGIN
    	INSERT INTO RiskPro.dbo.SLV_CONFIGURATION_DESC (SLV_CONFIGURATION_DESC_ID, INITIAL_PORT, VERSION_KEY) VALUES (1, 8280, -1)
    END
    2020-02-26 17:30:37	CHECK	RiskPro calculation configuration complete
    2020-02-26 17:30:37	INFO	Setup RiskPro environment configuration
    DEBUG: IF EXISTS (SELECT COUNT(1) FROM RiskPro.dbo.SLV_ENVIRONMENT_DESC WHERE SLV_ENVIRONMENT_DESC_ID = 1)
    BEGIN
    	UPDATE RiskPro.dbo.SLV_ENVIRONMENT_DESC SET VERSION_KEY = -1, IS_AUDIT_ACTIVATED = 1 WHERE SLV_ENVIRONMENT_DESC_ID = 1
    END
    ELSE
    BEGIN
    	INSERT INTO RiskPro.dbo.SLV_ENVIRONMENT_DESC (SLV_ENVIRONMENT_DESC_ID, VERSION_KEY, IS_AUDIT_ACTIVATED) VALUES (1, -1, 1)
    END
    2020-02-26 17:30:37	CHECK	RiskPro environment configuration complete
    2020-02-26 17:30:37	INFO	Configuring job controller
    DEBUG: IF EXISTS (SELECT COUNT(1) FROM RiskPro.dbo.SLV_JOB_CONTROLLER_DESC WHERE SLV_JOB_CONTROLLER_DESC_ID = 1)
    BEGIN
    	UPDATE RiskPro.dbo.SLV_JOB_CONTROLLER_DESC SET HOSTNAME = '127.0.0.1', DG_CACHE_ENABLED = 1, DG_CACHE_EVICTION = 24, DG_CACHE_FILE_SIZE = 1000, DG_CACHE_TEMP_DIR = 'C:\WKFS\RiskPro\rp-cache', DG_CACHE_MAX_DG = 100, DG_CACHE_MIN_CT = 1000, VERSION_KEY = -1 WHERE SLV_JOB_CONTROLLER_DESC_ID = 1
    END
    ELSE
    BEGIN
    	INSERT INTO RiskPro.dbo.SLV_JOB_CONTROLLER_DESC (SLV_JOB_CONTROLLER_DESC_ID, HOSTNAME, DG_CACHE_ENABLED, DG_CACHE_EVICTION, DG_CACHE_FILE_SIZE, DG_CACHE_TEMP_DIR, DG_CACHE_MAX_DG, DG_CACHE_MIN_CT, VERSION_KEY) VALUES (1, '127.0.0.1', 1, 24, 1000, 'C:\WKFS\RiskPro\rp-cache', 100, 1000, -1)
    END
    2020-02-26 17:30:37	CHECK	Job controller configuration complete
    2020-02-26 17:30:37	INFO	Configuring staging area
    DEBUG: IF EXISTS (SELECT COUNT(1) FROM RiskPro.dbo.SLV_STAGING_AREA_DESC WHERE SLV_STAGING_AREA_DESC_ID = 1)
    BEGIN
    	UPDATE RiskPro.dbo.SLV_STAGING_AREA_DESC SET HOSTNAME = '127.0.0.1', PERSISTNT_RES_MGR_THREAD_COUNT = 5, VERSION_KEY = -1 WHERE SLV_STAGING_AREA_DESC_ID = 1
    END
    ELSE
    BEGIN
    	INSERT INTO RiskPro.dbo.SLV_STAGING_AREA_DESC (SLV_STAGING_AREA_DESC_ID, HOSTNAME, PERSISTNT_RES_MGR_THREAD_COUNT, VERSION_KEY) VALUES (1, '127.0.0.1', 5, -1)
    END
    2020-02-26 17:30:37	CHECK	Staging area configuration complete
    2020-02-26 17:30:37	INFO	Configure OLAP cube
    DEBUG: "9.14.0" -ge "9.0.0"
    DEBUG: IF EXISTS (SELECT COUNT(1) FROM SLV_OLAP_DESC WHERE SLV_OLAP_DESC_ID = 1)
    BEGIN
    	UPDATE SLV_OLAP_DESC SET HOSTNAME = '127.0.0.1', PERSISTNT_RES_MGR_THREAD_COUNT = 5, VERSION_KEY = -1 WHERE SLV_OLAP_DESC_ID = 1
    END
    ELSE
    BEGIN
    	INSERT INTO SLV_OLAP_DESC (SLV_OLAP_DESC_ID, HOSTNAME, PERSISTNT_RES_MGR_THREAD_COUNT, VERSION_KEY) VALUES (1, '127.0.0.1', 5, -1)
    END
    2020-02-26 17:30:37	CHECK	OLAP cube configuration complete
    2020-02-26 17:30:37	INFO	Configuring Task Execution Support Service (TESS)
    DEBUG: IF EXISTS (SELECT COUNT(1) FROM RiskPro.dbo.SLV_TESS_DESC WHERE SLV_TESS_DESC_ID = 1)
    BEGIN
    	UPDATE RiskPro.dbo.SLV_TESS_DESC SET HOSTNAME = '127.0.0.1', SHARED_FILESYSTEM_ROOT = 'C:\WKFS\RiskPro\rp-root', FTP_PORT = 2121, INITIAL_PORT = 8275, VERSION_KEY = -1 WHERE SLV_TESS_DESC_ID = 1
    END
    ELSE
    BEGIN
    	INSERT INTO RiskPro.dbo.SLV_TESS_DESC (SLV_TESS_DESC_ID, HOSTNAME, SHARED_FILESYSTEM_ROOT, FTP_PORT, INITIAL_PORT, VERSION_KEY) VALUES (1, '127.0.0.1', 'C:\WKFS\RiskPro\rp-root', 2121, 8275, -1)
    END
    2020-02-26 17:30:37	CHECK	TESS configuration complete
    2020-02-26 17:30:37	INFO	Configuring 127.0.0.1 calculator
    DEBUG: IF EXISTS (SELECT COUNT(1) FROM RiskPro.dbo.SLV_CALCULATOR_HOSTNAME WHERE SLV_CALCULATOR_DESC_ID = 1)
    BEGIN
    	UPDATE RiskPro.dbo.SLV_CALCULATOR_HOSTNAME SET HOSTNAME = '127.0.0.1' WHERE SLV_CALCULATOR_DESC_ID = 1
    END
    ELSE
    BEGIN
    	INSERT INTO RiskPro.dbo.SLV_CALCULATOR_HOSTNAME (SLV_CALCULATOR_DESC_ID, HOSTNAME) VALUES (1, '127.0.0.1')
    END
    2020-02-26 17:30:37	INFO	Configuring 127.0.0.1 calculation units
    DEBUG: IF EXISTS (SELECT COUNT(1) FROM RiskPro.dbo.SLV_CALCULATOR_DESC WHERE SLV_CALCULATOR_DESC_ID = 1)
    BEGIN
    	UPDATE RiskPro.dbo.SLV_CALCULATOR_DESC SET NAME = '127.0.0.1', CALCULATION_UNIT_COUNT = 1, PROCESSING_THREAD_COUNT = 4, VERSION_KEY = -1 WHERE SLV_CALCULATOR_DESC_ID = 1
    END
    ELSE
    BEGIN
    	INSERT INTO RiskPro.dbo.SLV_CALCULATOR_DESC (SLV_CALCULATOR_DESC_ID, NAME, CALCULATION_UNIT_COUNT, PROCESSING_THREAD_COUNT, VERSION_KEY) VALUES (1, '127.0.0.1', 1, 4, -1)
    END
    2020-02-26 17:30:37	CHECK	Calculator configuration complete
    ```

##  Configure the application server(s)

In this section, we will go through the steps to configure the application server(s) for RiskPro.

1.  Configure header and post size values.
    ```
    2020-02-26 17:30:41	INFO	Setup application server settings
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='/subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=max-header-size,value=500000000)'
    DEBUG: {"outcome" => "success"}
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='/subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=max-post-size,value=500000000)'
    DEBUG: {"outcome" => "success"}
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='/subsystem=undertow/server=default-server/https-listener=https:write-attribute(name=max-header-size,value=500000000)'
    DEBUG: {"outcome" => "success"}
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='/subsystem=undertow/server=default-server/https-listener=https:write-attribute(name=max-post-size,value=500000000)'
    DEBUG: {"outcome" => "success"}
    2020-02-26 17:30:54	CHECK	Application server configured successfully
    ```
2.  Install provided JDBC module.
    ```
    2020-02-26 17:30:54	INFO	Install mssql.jdbc module
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='module add --name=mssql.jdbc --resources=\"C:\WKFS\RiskPro\rp-9.14.0\etc\drivers\sqljdbc42.jar\" --dependencies=javax.api,javax.transaction.api'
    2020-02-26 17:30:58	CHECK	mssql.jdbc module successfully installed
    ```
3.  Install JDBC driver.
    ```
    2020-02-26 17:30:58	INFO	Install mssql JDBC driver
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='/subsystem=datasources/jdbc-driver=\"mssql\":add(driver-module-name=\"mssql.jdbc\",driver-name=\"mssql\",driver-class-name=\"com.microsoft.sqlserver.jdbc.SQLServerDriver\")'
    DEBUG: {"outcome" => "success"}
    2020-02-26 17:31:01	CHECK	mssql JDBC driver has been successfully installed
    ```
4.  Create `RiskProDS` data-source (the security domain steps are optional but provide encryption support for the database user password).
    ```
    2020-02-26 17:31:02	INFO	Create data-source security domain
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='/subsystem=security/security-domain=RiskproDS:add(cache-type=\"default\")'
    DEBUG: {"outcome" => "success"}
    2020-02-26 17:31:05	CHECK	RiskproDS security domain has been successfully created
    DEBUG: Set security domain authentication method
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='/subsystem=security/security-domain=RiskproDS/authentication=\"classic\":add()'
    DEBUG: {
        "outcome" => "success",
        "response-headers" => {
            "operation-requires-reload" => true,
            "process-state" => "reload-required"
        }
    }
    2020-02-26 17:31:09	CHECK	Security domain authentication method has been successfully set
    DEBUG: Configure security domain authentication
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='/subsystem=security/security-domain=RiskproDS/authentication=\"classic\"/login-module=\"org.picketbox.datasource.security.SecureIdentityLoginModule\":add(code=\"org.picketbox.datasource.security.SecureIdentityLoginModule\",flag=\"required\",module-options={\"username\" => \"RiskPro\",\"password\" =>\"6114b7577e2a0af2
    \",\"managedConnectionFactoryName\" =>\"name=java:/RiskproDS\"}):add()'
    DEBUG: {
        "outcome" => "success",
        "response-headers" => {
            "operation-requires-reload" => true,
            "process-state" => "reload-required"
        }
    }
    2020-02-26 17:31:12	CHECK	Security domain authentication has been successfully configured
    2020-02-26 17:31:12	INFO	Register RiskproDS data-source
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='/subsystem=datasources/data-source=\"RiskproDS\":add(enabled=\"True\", jndi-name=\"java:/jdbc/RiskproDS\", driver-name=\"mssql\", connection-url=\"jdbc:sqlserver://;serverName=127.0.0.1;portNumber=1433;instanceName=MSSQLSERVER2017;databaseName=RiskPro\", security-domain=\"RiskproDS\", valid-connection-checker-class-name=\"org.jboss.jca.adapters.jdbc.extensions.mssql.MSSQLValidConnectionChecker\", exception-sorter-class-name=\"org.jboss.jca.adapters.jdbc.extensions.mssql.MSSQLExceptionSorter\", validate-on-match=True, background-validation=False)'
    DEBUG: {
        "outcome" => "success",
        "response-headers" => {"process-state" => "reload-required"}
    }
    2020-02-26 17:31:16	CHECK	RiskproDS data-source has been successfully registered
    ```
5.  Configure RiskPro grid properties.
    ```
    2020-02-26 17:31:16	INFO	Configure grid properties
    DEBUG: Name                           Value
    ----                           -----
    app.stagingarea                TRUE
    app.jobcontroller              TRUE
    app.calculator                 TRUE
    app.tess                       TRUE
    app.configuration              Configuration
    DEBUG: C:\WKFS\RiskPro\rp-conf\riskpro.grid.properties
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='/system-property=user.grid.properties.file:read-resource()'
    DEBUG: {
        "outcome" => "failed",
        "failure-description" => "WFLYCTL0216: Management resource '[(\"system-property\" => \"user.grid.properties.file\")]' not found",
        "rolled-back" => true,
        "response-headers" => {"process-state" => "reload-required"}
    }
    DEBUG: /system-property=user.grid.properties.file:add(value="C:/WKFS/RiskPro/rp-conf/riskpro.grid.properties")
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='/system-property=user.grid.properties.file:add(value="C:/WKFS/RiskPro/rp-conf/riskpro.grid.properties")'
    DEBUG: {
        "outcome" => "success",
        "response-headers" => {"process-state" => "reload-required"}
    }
    2020-02-26 17:31:24	CHECK	Grid properties have been successfully set
    ```
6.  Configure RiskPro log properties.
    ```
    2020-02-26 17:31:24	INFO	Configure log properties
    DEBUG: Name                           Value
    ----                           -----
    log4j.rootLogger               INFO, logfile
    log4j.appender.logfile         org.apache.log4j.DailyRollingFileAppender
    log4j.appender.logfile.File    C:/WKFS/RiskPro/rp-logs/riskpro.log
    log4j.appender.logfile.Date... '.'yyyy-MM-dd
    log4j.appender.logfile.layout  org.apache.log4j.PatternLayout
    log4j.appender.logfile.layo... [%20.20t] %40.40c [%5.5p] (%d{yyyy-MM-dd HH:mm:ss.SSS}) %m%n
    log4j.logger.com.frsglobal.... WARN
    log4j.logger.org.apache.ftp... ERROR
    log4j.logger.org.hibernate     ERROR
    log4j.logger.org.jboss         ERROR
    log4j.logger.com.frsglobal.... WARN
    log4j.logger.com.frsglobal.... WARN
    DEBUG: C:\WKFS\RiskPro\rp-conf\riskpro.log4j.properties
    DEBUG: /system-property=riskpro.log4j.properties.file:read-resource()
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='/system-property=riskpro.log4j.properties.file:read-resource()'
    DEBUG: {
        "outcome" => "failed",
        "failure-description" => "WFLYCTL0216: Management resource '[(\"system-property\" => \"riskpro.log4j.properties.file\")]' not found",
        "rolled-back" => true,
        "response-headers" => {"process-state" => "reload-required"}
    }
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='/system-property=riskpro.log4j.properties.file:add(value="C:/WKFS/RiskPro/rp-conf/riskpro.log4j.properties")'
    DEBUG: {
        "outcome" => "success",
        "response-headers" => {"process-state" => "reload-required"}
    }
    2020-02-26 17:31:30	CHECK	Log properties have been successfully set
    ```
7.  Reload application server.
    ```
    2020-02-26 17:31:30	INFO	Reload WildFly
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command=':reload()'
    DEBUG: {
        "outcome" => "success",
        "result" => undefined
    }
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command=':read-attribute(name=server-state)'
    DEBUG: {
        "outcome" => "success",
        "result" => "running"
    }
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='/subsystem=datasources/data-source=\"RiskproDS\":test-connection-in-pool()'
    DEBUG: {
        "outcome" => "success",
        "result" => [true]
    }
    2020-02-26 17:31:41	CHECK	riskpro application server configuration complete
    ```

## Package web-application

In this section, we will go through the steps to create the RiskPro web-application file.

1.  Create a `lib` folder in the distribution repository.
    ```
    DEBUG: Create path C:\WKFS\RiskPro\rp-9.14.0\lib\patch
    ```
2.  Setup the license file.
    ```
    2020-02-26 17:31:41	INFO	Setup license file
    DEBUG: license-1.0.15-dev.jar
    ```
3.  Setup patches (if applicable).
    ```
    2020-02-26 17:31:41	INFO	Setup patches
    DEBUG: No JAR patch was found
    DEBUG: No ZIP patch was found
    ```
4.  Generate web-application.
    ```
    2020-02-26 17:31:41	INFO	Generate riskpro-web application
    DEBUG: cmd.exe /c '"C:\WKFS\RiskPro\rp-9.14.0\bin\riskpro.bat" "C:\WKFS\RiskPro\rp-9.14.0\bin\run.xml" generateDefaultWebApp -D"jboss.host"="" -D"jboss.port.admin"="" -D"jboss.port.http"="" -D"webapp.name"="riskpro-web" 2>&1'
    DEBUG: JAVA_HOME=C:\app\Java\jdk1.8.0_211
    java version "1.8.0_211"
    Java(TM) SE Runtime Environment (build 1.8.0_211-b12)
    Java HotSpot(TM) 64-Bit Server VM (build 25.211-b12, mixed mode)

    Buildfile: C:\WKFS\RiskPro\rp-9.14.0\bin\run.xml

    prepareWebAppPatch:
        [mkdir] Created dir: C:\WKFS\RiskPro\rp-9.14.0\webapp\patch
        [unzip] Expanding: C:\WKFS\RiskPro\rp-9.14.0\lib\patch\license-1.0.15-dev.jar into C:\WKFS\RiskPro\rp-9.14.0\webapp\patch\WEB-INF\classes

    generateDefaultWebApp:
          [zip] Building zip: C:\WKFS\RiskPro\rp-9.14.0\webapp\riskpro-web.war
          [zip] Updating zip: C:\WKFS\RiskPro\rp-9.14.0\webapp\riskpro-web.war

    BUILD SUCCESSFUL
    Total time: 27 seconds
    2020-02-26 17:32:09	CHECK	riskpro-web WAR file has been successfully generated
    ```

## Deploy application

In this section, we will go through the steps to deploy the RiskPro application.

1.  Check that the `RiskProDS` data-source is working.
    ```
    2020-02-26 17:32:09	INFO	Checking RiskproDS data-source connection on host riskpro
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='/subsystem=datasources/data-source=\"RiskproDS\":test-connection-in-pool()'
    DEBUG: {
        "outcome" => "success",
        "result" => [true]
    }
    2020-02-26 17:32:13	CHECK	Database connection successfully established
    ```
2.  Deploy RiskPro web-application.
    ```
    2020-02-26 17:32:13	INFO	Deploying riskpro-web application on host riskpro
    DEBUG: & "C:\WKFS\WildFly\wildfly-17.0.1.Final\bin\jboss-cli.ps1" --connect --controller='127.0.0.1:9990' --user='admin' --password='*******' --command='deploy \"C:\WKFS\RiskPro\rp-9.14.0\webapp\riskpro-web.war\" --force'
    DEBUG:
    2020-02-26 17:34:24	CHECK	riskpro-web application deployed successfully on host riskpro
    ```

## RiskPro administration

In this section, we will go through the steps to administer the RiskPro application.

1.  Create an administration user group.
    ```
    2020-02-26 17:34:24	INFO	Creating administration user group
    DEBUG: & "C:\app\Java\jdk1.8.0_211\bin\java.exe" -classpath "C:\WKFS\RiskPro\rp-9.14.0\bin\riskpro-batch-client.jar" -D"ws.operation"="createUserGroup" -D"ws.epr.base"="http://127.0.0.1:8080/riskpro-web/batchapi" -D"rs.epr.base"="http://127.0.0.1:8080/riskpro-web/api" -D"od.service.address"="http://127.0.0.1:8080/riskpro-web/res.svc" -D"ws.user.name"="admin" -D"ws.user.pswd"="*******" -D"ad.groupName"="Administrators" -D"java.io.tmpdir"="C:\WKFS\RiskPro\rp-tmp" -Xmx1G com.frsglobal.pub.batch.client.cli.AdministrationClient
    DEBUG: [                main] [ INFO] (17:34:24.962) Batch interface client successfully setup at [admin@http://127.0.0.1:8080/riskpro-web/batchapi?]
    [                main] [ INFO] (17:34:24.977)                   ad.groupName [Administrators]
    [                main] [ INFO] (17:34:24.977)                    awt.toolkit [sun.awt.windows.WToolkit]
    [                main] [ INFO] (17:34:24.977)                  file.encoding [Cp1252]
    [                main] [ INFO] (17:34:24.977)              file.encoding.pkg [sun.io]
    [                main] [ INFO] (17:34:24.977)                 file.separator [\]
    [                main] [ INFO] (17:34:24.977)           java.awt.graphicsenv [sun.awt.Win32GraphicsEnvironment]
    [                main] [ INFO] (17:34:24.993)            java.awt.printerjob [sun.awt.windows.WPrinterJob]
    [                main] [ INFO] (17:34:24.993)             java.class.version [52.0]
    [                main] [ INFO] (17:34:24.993)             java.endorsed.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\endorsed]
    [                main] [ INFO] (17:34:24.993)                  java.ext.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\ext;C:\WINDOWS\Sun\Java\lib\ext]
    [                main] [ INFO] (17:34:24.993)                      java.home [C:\app\Java\jdk1.8.0_211\jre]
    [                main] [ INFO] (17:34:24.993)                 java.io.tmpdir [C:\WKFS\RiskPro\rp-tmp]
    [                main] [ INFO] (17:34:24.993)              java.runtime.name [Java(TM) SE Runtime Environment]
    [                main] [ INFO] (17:34:24.993)           java.runtime.version [1.8.0_211-b12]
    [                main] [ INFO] (17:34:24.993)        java.specification.name [Java Platform API Specification]
    [                main] [ INFO] (17:34:24.993)      java.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:24.993)     java.specification.version [1.8]
    [                main] [ INFO] (17:34:24.993)                    java.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:24.993)                java.vendor.url [http://java.oracle.com/]
    [                main] [ INFO] (17:34:24.993)            java.vendor.url.bug [http://bugreport.sun.com/bugreport/]
    [                main] [ INFO] (17:34:24.993)                   java.version [1.8.0_211]
    [                main] [ INFO] (17:34:24.993)                   java.vm.info [mixed mode]
    [                main] [ INFO] (17:34:24.993)                   java.vm.name [Java HotSpot(TM) 64-Bit Server VM]
    [                main] [ INFO] (17:34:24.993)     java.vm.specification.name [Java Virtual Machine Specification]
    [                main] [ INFO] (17:34:24.993)   java.vm.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:24.993)  java.vm.specification.version [1.8]
    [                main] [ INFO] (17:34:24.993)                 java.vm.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:24.993)                java.vm.version [25.211-b12]
    [                main] [ INFO] (17:34:24.993)                 line.separator [
    ]
    [                main] [ INFO] (17:34:24.993)             od.service.address [http://127.0.0.1:8080/riskpro-web/res.svc]
    [                main] [ INFO] (17:34:24.993)                        os.arch [amd64]
    [                main] [ INFO] (17:34:24.993)                        os.name [Windows 10]
    [                main] [ INFO] (17:34:24.993)                     os.version [10.0]
    [                main] [ INFO] (17:34:24.993)                 path.separator [;]
    [                main] [ INFO] (17:34:24.993)                    rs.epr.base [http://127.0.0.1:8080/riskpro-web/api]
    [                main] [ INFO] (17:34:24.993)            sun.arch.data.model [64]
    [                main] [ INFO] (17:34:24.993)            sun.boot.class.path [C:\app\Java\jdk1.8.0_211\jre\lib\resources.jar;C:\app\Java\jdk1.8.0_211\jre\lib\rt.jar;C:\app\Java\jdk1.8.0_211\jre\lib\sunrsasign.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jsse.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jce.jar;C:\app\Java\jdk1.8.0_211\jre\lib\charsets.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jfr.jar;C:\app\Java\jdk1.8.0_211\jre\classes]
    [                main] [ INFO] (17:34:24.993)          sun.boot.library.path [C:\app\Java\jdk1.8.0_211\jre\bin]
    [                main] [ INFO] (17:34:24.993)                 sun.cpu.endian [little]
    [                main] [ INFO] (17:34:24.993)                sun.cpu.isalist [amd64]
    [                main] [ INFO] (17:34:24.993)                    sun.desktop [windows]
    [                main] [ INFO] (17:34:24.993)        sun.io.unicode.encoding [UnicodeLittle]
    [                main] [ INFO] (17:34:24.993)               sun.java.command [com.frsglobal.pub.batch.client.cli.AdministrationClient]
    [                main] [ INFO] (17:34:24.993)              sun.java.launcher [SUN_STANDARD]
    [                main] [ INFO] (17:34:24.993)               sun.jnu.encoding [Cp1252]
    [                main] [ INFO] (17:34:24.993)        sun.management.compiler [HotSpot 64-Bit Tiered Compilers]
    [                main] [ INFO] (17:34:24.993)             sun.os.patch.level []
    [                main] [ INFO] (17:34:24.993)            sun.stderr.encoding [cp437]
    [                main] [ INFO] (17:34:24.993)                   user.country [GB]
    [                main] [ INFO] (17:34:24.993)                       user.dir [C:\WKFS\Scripts\rp-deploy]
    [                main] [ INFO] (17:34:24.993)                      user.home [C:\Users\florian.carrier]
    [                main] [ INFO] (17:34:24.993)                  user.language [en]
    [                main] [ INFO] (17:34:24.993)                      user.name [Florian.Carrier]
    [                main] [ INFO] (17:34:24.993)                    user.script []
    [                main] [ INFO] (17:34:24.993)                  user.timezone [Europe/London]
    [                main] [ INFO] (17:34:24.993)                   user.variant []
    [                main] [ INFO] (17:34:24.993)                    ws.epr.base [http://127.0.0.1:8080/riskpro-web/batchapi]
    [                main] [ INFO] (17:34:24.993)                   ws.operation [createUserGroup]
    [                main] [ INFO] (17:34:24.993)                   ws.user.name [admin]
    [                main] [ INFO] (17:34:24.993)                   ws.user.pswd [********]
    [                main] [ INFO] (17:34:28.502) Synchronous mode = false
    2020-02-26 17:34:28	CHECK	"Administrators" user group has been successfully created
    ```
2.  Add default `admin` user to the administration user group.
    ```
    2020-02-26 17:34:28	INFO	Adding admin user to administration user group
    DEBUG: & "C:\app\Java\jdk1.8.0_211\bin\java.exe" -classpath "C:\WKFS\RiskPro\rp-9.14.0\bin\riskpro-batch-client.jar" -D"ws.operation"="modifyUser" -D"ws.epr.base"="http://127.0.0.1:8080/riskpro-web/batchapi" -D"rs.epr.base"="http://127.0.0.1:8080/riskpro-web/api" -D"od.service.address"="http://127.0.0.1:8080/riskpro-web/res.svc" -D"ws.user.name"="admin" -D"ws.user.pswd"="*******" -D"ad.userName"="admin" -D"ad.newUserName"="admin" -D"ad.newEmployeeName"="Administrator" -D"ad.userGroups"="Administrators" -D"java.io.tmpdir"="C:\WKFS\RiskPro\rp-tmp" -Xmx1G com.frsglobal.pub.batch.client.cli.AdministrationClient
    DEBUG: [                main] [ INFO] (17:34:28.912) Batch interface client successfully setup at [admin@http://127.0.0.1:8080/riskpro-web/batchapi?]
    [                main] [ INFO] (17:34:28.927)             ad.newEmployeeName [Administrator]
    [                main] [ INFO] (17:34:28.927)                 ad.newUserName [admin]
    [                main] [ INFO] (17:34:28.927)                  ad.userGroups [Administrators]
    [                main] [ INFO] (17:34:28.927)                    ad.userName [admin]
    [                main] [ INFO] (17:34:28.927)                    awt.toolkit [sun.awt.windows.WToolkit]
    [                main] [ INFO] (17:34:28.927)                  file.encoding [Cp1252]
    [                main] [ INFO] (17:34:28.927)              file.encoding.pkg [sun.io]
    [                main] [ INFO] (17:34:28.927)                 file.separator [\]
    [                main] [ INFO] (17:34:28.927)           java.awt.graphicsenv [sun.awt.Win32GraphicsEnvironment]
    [                main] [ INFO] (17:34:28.927)            java.awt.printerjob [sun.awt.windows.WPrinterJob]
    [                main] [ INFO] (17:34:28.927)             java.class.version [52.0]
    [                main] [ INFO] (17:34:28.927)             java.endorsed.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\endorsed]
    [                main] [ INFO] (17:34:28.927)                  java.ext.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\ext;C:\WINDOWS\Sun\Java\lib\ext]
    [                main] [ INFO] (17:34:28.927)                      java.home [C:\app\Java\jdk1.8.0_211\jre]
    [                main] [ INFO] (17:34:28.927)                 java.io.tmpdir [C:\WKFS\RiskPro\rp-tmp]
    [                main] [ INFO] (17:34:28.927)              java.runtime.name [Java(TM) SE Runtime Environment]
    [                main] [ INFO] (17:34:28.927)           java.runtime.version [1.8.0_211-b12]
    [                main] [ INFO] (17:34:28.927)        java.specification.name [Java Platform API Specification]
    [                main] [ INFO] (17:34:28.927)      java.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:28.927)     java.specification.version [1.8]
    [                main] [ INFO] (17:34:28.927)                    java.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:28.927)                java.vendor.url [http://java.oracle.com/]
    [                main] [ INFO] (17:34:28.927)            java.vendor.url.bug [http://bugreport.sun.com/bugreport/]
    [                main] [ INFO] (17:34:28.927)                   java.version [1.8.0_211]
    [                main] [ INFO] (17:34:28.927)                   java.vm.info [mixed mode]
    [                main] [ INFO] (17:34:28.927)                   java.vm.name [Java HotSpot(TM) 64-Bit Server VM]
    [                main] [ INFO] (17:34:28.927)     java.vm.specification.name [Java Virtual Machine Specification]
    [                main] [ INFO] (17:34:28.927)   java.vm.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:28.927)  java.vm.specification.version [1.8]
    [                main] [ INFO] (17:34:28.927)                 java.vm.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:28.927)                java.vm.version [25.211-b12]
    [                main] [ INFO] (17:34:28.927)                 line.separator [
    ]
    [                main] [ INFO] (17:34:28.927)             od.service.address [http://127.0.0.1:8080/riskpro-web/res.svc]
    [                main] [ INFO] (17:34:28.927)                        os.arch [amd64]
    [                main] [ INFO] (17:34:28.927)                        os.name [Windows 10]
    [                main] [ INFO] (17:34:28.927)                     os.version [10.0]
    [                main] [ INFO] (17:34:28.927)                 path.separator [;]
    [                main] [ INFO] (17:34:28.927)                    rs.epr.base [http://127.0.0.1:8080/riskpro-web/api]
    [                main] [ INFO] (17:34:28.927)            sun.arch.data.model [64]
    [                main] [ INFO] (17:34:28.927)            sun.boot.class.path [C:\app\Java\jdk1.8.0_211\jre\lib\resources.jar;C:\app\Java\jdk1.8.0_211\jre\lib\rt.jar;C:\app\Java\jdk1.8.0_211\jre\lib\sunrsasign.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jsse.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jce.jar;C:\app\Java\jdk1.8.0_211\jre\lib\charsets.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jfr.jar;C:\app\Java\jdk1.8.0_211\jre\classes]
    [                main] [ INFO] (17:34:28.927)          sun.boot.library.path [C:\app\Java\jdk1.8.0_211\jre\bin]
    [                main] [ INFO] (17:34:28.927)                 sun.cpu.endian [little]
    [                main] [ INFO] (17:34:28.927)                sun.cpu.isalist [amd64]
    [                main] [ INFO] (17:34:28.927)                    sun.desktop [windows]
    [                main] [ INFO] (17:34:28.927)        sun.io.unicode.encoding [UnicodeLittle]
    [                main] [ INFO] (17:34:28.927)               sun.java.command [com.frsglobal.pub.batch.client.cli.AdministrationClient]
    [                main] [ INFO] (17:34:28.927)              sun.java.launcher [SUN_STANDARD]
    [                main] [ INFO] (17:34:28.927)               sun.jnu.encoding [Cp1252]
    [                main] [ INFO] (17:34:28.927)        sun.management.compiler [HotSpot 64-Bit Tiered Compilers]
    [                main] [ INFO] (17:34:28.927)             sun.os.patch.level []
    [                main] [ INFO] (17:34:28.927)            sun.stderr.encoding [cp437]
    [                main] [ INFO] (17:34:28.927)                   user.country [GB]
    [                main] [ INFO] (17:34:28.927)                       user.dir [C:\WKFS\Scripts\rp-deploy]
    [                main] [ INFO] (17:34:28.927)                      user.home [C:\Users\florian.carrier]
    [                main] [ INFO] (17:34:28.927)                  user.language [en]
    [                main] [ INFO] (17:34:28.927)                      user.name [Florian.Carrier]
    [                main] [ INFO] (17:34:28.927)                    user.script []
    [                main] [ INFO] (17:34:28.927)                  user.timezone [Europe/London]
    [                main] [ INFO] (17:34:28.927)                   user.variant []
    [                main] [ INFO] (17:34:28.927)                    ws.epr.base [http://127.0.0.1:8080/riskpro-web/batchapi]
    [                main] [ INFO] (17:34:28.927)                   ws.operation [modifyUser]
    [                main] [ INFO] (17:34:28.927)                   ws.user.name [admin]
    [                main] [ INFO] (17:34:28.927)                   ws.user.pswd [********]
    [                main] [ INFO] (17:34:31.349) Synchronous mode = false
    2020-02-26 17:34:31	CHECK	Administrator user has been successfully added
    ```
3.  Create a model group for administration models.
    ```
    2020-02-26 17:34:31	INFO	Creating model group "System models"
    DEBUG: & "C:\app\Java\jdk1.8.0_211\bin\java.exe" -classpath "C:\WKFS\RiskPro\rp-9.14.0\bin\riskpro-batch-client.jar" -D"ws.operation"="createModelGroup" -D"ws.epr.base"="http://127.0.0.1:8080/riskpro-web/batchapi" -D"rs.epr.base"="http://127.0.0.1:8080/riskpro-web/api" -D"od.service.address"="http://127.0.0.1:8080/riskpro-web/res.svc" -D"ws.user.name"="admin" -D"ws.user.pswd"="*******" -D"ad.modelGroupName"="System models" -D"java.io.tmpdir"="C:\WKFS\RiskPro\rp-tmp" -Xmx1G com.frsglobal.pub.batch.client.cli.AdministrationClient
    DEBUG: [                main] [ INFO] (17:34:31.719) Batch interface client successfully setup at [admin@http://127.0.0.1:8080/riskpro-web/batchapi?]
    [                main] [ INFO] (17:34:31.719)              ad.modelGroupName [System models]
    [                main] [ INFO] (17:34:31.734)                    awt.toolkit [sun.awt.windows.WToolkit]
    [                main] [ INFO] (17:34:31.734)                  file.encoding [Cp1252]
    [                main] [ INFO] (17:34:31.734)              file.encoding.pkg [sun.io]
    [                main] [ INFO] (17:34:31.734)                 file.separator [\]
    [                main] [ INFO] (17:34:31.734)           java.awt.graphicsenv [sun.awt.Win32GraphicsEnvironment]
    [                main] [ INFO] (17:34:31.734)            java.awt.printerjob [sun.awt.windows.WPrinterJob]
    [                main] [ INFO] (17:34:31.734)             java.class.version [52.0]
    [                main] [ INFO] (17:34:31.734)             java.endorsed.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\endorsed]
    [                main] [ INFO] (17:34:31.734)                  java.ext.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\ext;C:\WINDOWS\Sun\Java\lib\ext]
    [                main] [ INFO] (17:34:31.734)                      java.home [C:\app\Java\jdk1.8.0_211\jre]
    [                main] [ INFO] (17:34:31.734)                 java.io.tmpdir [C:\WKFS\RiskPro\rp-tmp]
    [                main] [ INFO] (17:34:31.734)              java.runtime.name [Java(TM) SE Runtime Environment]
    [                main] [ INFO] (17:34:31.734)           java.runtime.version [1.8.0_211-b12]
    [                main] [ INFO] (17:34:31.734)        java.specification.name [Java Platform API Specification]
    [                main] [ INFO] (17:34:31.734)      java.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:31.734)     java.specification.version [1.8]
    [                main] [ INFO] (17:34:31.734)                    java.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:31.734)                java.vendor.url [http://java.oracle.com/]
    [                main] [ INFO] (17:34:31.734)            java.vendor.url.bug [http://bugreport.sun.com/bugreport/]
    [                main] [ INFO] (17:34:31.734)                   java.version [1.8.0_211]
    [                main] [ INFO] (17:34:31.734)                   java.vm.info [mixed mode]
    [                main] [ INFO] (17:34:31.734)                   java.vm.name [Java HotSpot(TM) 64-Bit Server VM]
    [                main] [ INFO] (17:34:31.734)     java.vm.specification.name [Java Virtual Machine Specification]
    [                main] [ INFO] (17:34:31.734)   java.vm.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:31.734)  java.vm.specification.version [1.8]
    [                main] [ INFO] (17:34:31.734)                 java.vm.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:31.734)                java.vm.version [25.211-b12]
    [                main] [ INFO] (17:34:31.734)                 line.separator [
    ]
    [                main] [ INFO] (17:34:31.734)             od.service.address [http://127.0.0.1:8080/riskpro-web/res.svc]
    [                main] [ INFO] (17:34:31.734)                        os.arch [amd64]
    [                main] [ INFO] (17:34:31.734)                        os.name [Windows 10]
    [                main] [ INFO] (17:34:31.734)                     os.version [10.0]
    [                main] [ INFO] (17:34:31.734)                 path.separator [;]
    [                main] [ INFO] (17:34:31.734)                    rs.epr.base [http://127.0.0.1:8080/riskpro-web/api]
    [                main] [ INFO] (17:34:31.734)            sun.arch.data.model [64]
    [                main] [ INFO] (17:34:31.734)            sun.boot.class.path [C:\app\Java\jdk1.8.0_211\jre\lib\resources.jar;C:\app\Java\jdk1.8.0_211\jre\lib\rt.jar;C:\app\Java\jdk1.8.0_211\jre\lib\sunrsasign.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jsse.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jce.jar;C:\app\Java\jdk1.8.0_211\jre\lib\charsets.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jfr.jar;C:\app\Java\jdk1.8.0_211\jre\classes]
    [                main] [ INFO] (17:34:31.734)          sun.boot.library.path [C:\app\Java\jdk1.8.0_211\jre\bin]
    [                main] [ INFO] (17:34:31.734)                 sun.cpu.endian [little]
    [                main] [ INFO] (17:34:31.734)                sun.cpu.isalist [amd64]
    [                main] [ INFO] (17:34:31.734)                    sun.desktop [windows]
    [                main] [ INFO] (17:34:31.734)        sun.io.unicode.encoding [UnicodeLittle]
    [                main] [ INFO] (17:34:31.734)               sun.java.command [com.frsglobal.pub.batch.client.cli.AdministrationClient]
    [                main] [ INFO] (17:34:31.734)              sun.java.launcher [SUN_STANDARD]
    [                main] [ INFO] (17:34:31.734)               sun.jnu.encoding [Cp1252]
    [                main] [ INFO] (17:34:31.734)        sun.management.compiler [HotSpot 64-Bit Tiered Compilers]
    [                main] [ INFO] (17:34:31.734)             sun.os.patch.level []
    [                main] [ INFO] (17:34:31.734)            sun.stderr.encoding [cp437]
    [                main] [ INFO] (17:34:31.734)                   user.country [GB]
    [                main] [ INFO] (17:34:31.734)                       user.dir [C:\WKFS\Scripts\rp-deploy]
    [                main] [ INFO] (17:34:31.734)                      user.home [C:\Users\florian.carrier]
    [                main] [ INFO] (17:34:31.734)                  user.language [en]
    [                main] [ INFO] (17:34:31.734)                      user.name [Florian.Carrier]
    [                main] [ INFO] (17:34:31.734)                    user.script []
    [                main] [ INFO] (17:34:31.734)                  user.timezone [Europe/London]
    [                main] [ INFO] (17:34:31.734)                   user.variant []
    [                main] [ INFO] (17:34:31.734)                    ws.epr.base [http://127.0.0.1:8080/riskpro-web/batchapi]
    [                main] [ INFO] (17:34:31.734)                   ws.operation [createModelGroup]
    [                main] [ INFO] (17:34:31.734)                   ws.user.name [admin]
    [                main] [ INFO] (17:34:31.734)                   ws.user.pswd [********]
    [                main] [ INFO] (17:34:33.724) Synchronous mode = false
    2020-02-26 17:34:33	CHECK	"System models" model group has been successfully created
    ```
5.  Grant administration permission on the administration model group to the administration user group.
    ```
    2020-02-26 17:34:33	INFO	Granting permissions to administration user group
    DEBUG: & "C:\app\Java\jdk1.8.0_211\bin\java.exe" -classpath "C:\WKFS\RiskPro\rp-9.14.0\bin\riskpro-batch-client.jar" -D"ws.operation"="grantRole" -D"ws.epr.base"="http://127.0.0.1:8080/riskpro-web/batchapi" -D"rs.epr.base"="http://127.0.0.1:8080/riskpro-web/api" -D"od.service.address"="http://127.0.0.1:8080/riskpro-web/res.svc" -D"ws.user.name"="admin" -D"ws.user.pswd"="*******" -D"ad.modelGroupName"="System models" -D"ad.roleName"="Administrator" -D"ad.groupName"="Administrators" -D"java.io.tmpdir"="C:\WKFS\RiskPro\rp-tmp" -Xmx1G com.frsglobal.pub.batch.client.cli.AdministrationClient
    DEBUG: [                main] [ INFO] (17:34:34.086) Batch interface client successfully setup at [admin@http://127.0.0.1:8080/riskpro-web/batchapi?]
    [                main] [ INFO] (17:34:34.109)                   ad.groupName [Administrators]
    [                main] [ INFO] (17:34:34.109)              ad.modelGroupName [System models]
    [                main] [ INFO] (17:34:34.109)                    ad.roleName [Administrator]
    [                main] [ INFO] (17:34:34.109)                    awt.toolkit [sun.awt.windows.WToolkit]
    [                main] [ INFO] (17:34:34.109)                  file.encoding [Cp1252]
    [                main] [ INFO] (17:34:34.109)              file.encoding.pkg [sun.io]
    [                main] [ INFO] (17:34:34.109)                 file.separator [\]
    [                main] [ INFO] (17:34:34.109)           java.awt.graphicsenv [sun.awt.Win32GraphicsEnvironment]
    [                main] [ INFO] (17:34:34.109)            java.awt.printerjob [sun.awt.windows.WPrinterJob]
    [                main] [ INFO] (17:34:34.109)             java.class.version [52.0]
    [                main] [ INFO] (17:34:34.109)             java.endorsed.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\endorsed]
    [                main] [ INFO] (17:34:34.109)                  java.ext.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\ext;C:\WINDOWS\Sun\Java\lib\ext]
    [                main] [ INFO] (17:34:34.109)                      java.home [C:\app\Java\jdk1.8.0_211\jre]
    [                main] [ INFO] (17:34:34.109)                 java.io.tmpdir [C:\WKFS\RiskPro\rp-tmp]
    [                main] [ INFO] (17:34:34.109)              java.runtime.name [Java(TM) SE Runtime Environment]
    [                main] [ INFO] (17:34:34.109)           java.runtime.version [1.8.0_211-b12]
    [                main] [ INFO] (17:34:34.109)        java.specification.name [Java Platform API Specification]
    [                main] [ INFO] (17:34:34.109)      java.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:34.109)     java.specification.version [1.8]
    [                main] [ INFO] (17:34:34.109)                    java.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:34.109)                java.vendor.url [http://java.oracle.com/]
    [                main] [ INFO] (17:34:34.109)            java.vendor.url.bug [http://bugreport.sun.com/bugreport/]
    [                main] [ INFO] (17:34:34.109)                   java.version [1.8.0_211]
    [                main] [ INFO] (17:34:34.109)                   java.vm.info [mixed mode]
    [                main] [ INFO] (17:34:34.109)                   java.vm.name [Java HotSpot(TM) 64-Bit Server VM]
    [                main] [ INFO] (17:34:34.109)     java.vm.specification.name [Java Virtual Machine Specification]
    [                main] [ INFO] (17:34:34.109)   java.vm.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:34.109)  java.vm.specification.version [1.8]
    [                main] [ INFO] (17:34:34.109)                 java.vm.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:34.109)                java.vm.version [25.211-b12]
    [                main] [ INFO] (17:34:34.109)                 line.separator [
    ]
    [                main] [ INFO] (17:34:34.109)             od.service.address [http://127.0.0.1:8080/riskpro-web/res.svc]
    [                main] [ INFO] (17:34:34.109)                        os.arch [amd64]
    [                main] [ INFO] (17:34:34.109)                        os.name [Windows 10]
    [                main] [ INFO] (17:34:34.109)                     os.version [10.0]
    [                main] [ INFO] (17:34:34.109)                 path.separator [;]
    [                main] [ INFO] (17:34:34.109)                    rs.epr.base [http://127.0.0.1:8080/riskpro-web/api]
    [                main] [ INFO] (17:34:34.109)            sun.arch.data.model [64]
    [                main] [ INFO] (17:34:34.109)            sun.boot.class.path [C:\app\Java\jdk1.8.0_211\jre\lib\resources.jar;C:\app\Java\jdk1.8.0_211\jre\lib\rt.jar;C:\app\Java\jdk1.8.0_211\jre\lib\sunrsasign.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jsse.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jce.jar;C:\app\Java\jdk1.8.0_211\jre\lib\charsets.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jfr.jar;C:\app\Java\jdk1.8.0_211\jre\classes]
    [                main] [ INFO] (17:34:34.109)          sun.boot.library.path [C:\app\Java\jdk1.8.0_211\jre\bin]
    [                main] [ INFO] (17:34:34.109)                 sun.cpu.endian [little]
    [                main] [ INFO] (17:34:34.109)                sun.cpu.isalist [amd64]
    [                main] [ INFO] (17:34:34.109)                    sun.desktop [windows]
    [                main] [ INFO] (17:34:34.109)        sun.io.unicode.encoding [UnicodeLittle]
    [                main] [ INFO] (17:34:34.109)               sun.java.command [com.frsglobal.pub.batch.client.cli.AdministrationClient]
    [                main] [ INFO] (17:34:34.109)              sun.java.launcher [SUN_STANDARD]
    [                main] [ INFO] (17:34:34.109)               sun.jnu.encoding [Cp1252]
    [                main] [ INFO] (17:34:34.109)        sun.management.compiler [HotSpot 64-Bit Tiered Compilers]
    [                main] [ INFO] (17:34:34.109)             sun.os.patch.level []
    [                main] [ INFO] (17:34:34.109)            sun.stderr.encoding [cp437]
    [                main] [ INFO] (17:34:34.109)                   user.country [GB]
    [                main] [ INFO] (17:34:34.109)                       user.dir [C:\WKFS\Scripts\rp-deploy]
    [                main] [ INFO] (17:34:34.109)                      user.home [C:\Users\florian.carrier]
    [                main] [ INFO] (17:34:34.109)                  user.language [en]
    [                main] [ INFO] (17:34:34.109)                      user.name [Florian.Carrier]
    [                main] [ INFO] (17:34:34.109)                    user.script []
    [                main] [ INFO] (17:34:34.109)                  user.timezone [Europe/London]
    [                main] [ INFO] (17:34:34.109)                   user.variant []
    [                main] [ INFO] (17:34:34.109)                    ws.epr.base [http://127.0.0.1:8080/riskpro-web/batchapi]
    [                main] [ INFO] (17:34:34.109)                   ws.operation [grantRole]
    [                main] [ INFO] (17:34:34.109)                   ws.user.name [admin]
    [                main] [ INFO] (17:34:34.109)                   ws.user.pswd [********]
    [                main] [ INFO] (17:34:36.946) Synchronous mode = false
    2020-02-26 17:34:37	CHECK	Administrator role has been successfully granted
    ```
6.  Create a system model.
    ```
    2020-02-26 17:34:37	INFO	Creating System model
    DEBUG: & "C:\app\Java\jdk1.8.0_211\bin\java.exe" -classpath "C:\WKFS\RiskPro\rp-9.14.0\bin\riskpro-batch-client.jar" -D"ws.operation"="createModel" -D"ws.epr.base"="http://127.0.0.1:8080/riskpro-web/batchapi" -D"rs.epr.base"="http://127.0.0.1:8080/riskpro-web/api" -D"od.service.address"="http://127.0.0.1:8080/riskpro-web/res.svc" -D"ws.user.name"="admin" -D"ws.user.pswd"="*******" -D"ad.name"="System" -D"ad.modelType"="PRODUCTION" -D"ad.description"="System model" -D"ad.baseCurrency"="GBP" -D"ad.modelGroupName"="System models" -D"java.io.tmpdir"="C:\WKFS\RiskPro\rp-tmp" -Xmx1G com.frsglobal.pub.batch.client.cli.AdministrationClient
    DEBUG: [                main] [ INFO] (17:34:37.484) Batch interface client successfully setup at [admin@http://127.0.0.1:8080/riskpro-web/batchapi?]
    [                main] [ INFO] (17:34:37.494)                ad.baseCurrency [GBP]
    [                main] [ INFO] (17:34:37.494)                 ad.description [System model]
    [                main] [ INFO] (17:34:37.494)              ad.modelGroupName [System models]
    [                main] [ INFO] (17:34:37.494)                   ad.modelType [PRODUCTION]
    [                main] [ INFO] (17:34:37.494)                        ad.name [System]
    [                main] [ INFO] (17:34:37.494)                    awt.toolkit [sun.awt.windows.WToolkit]
    [                main] [ INFO] (17:34:37.494)                  file.encoding [Cp1252]
    [                main] [ INFO] (17:34:37.494)              file.encoding.pkg [sun.io]
    [                main] [ INFO] (17:34:37.494)                 file.separator [\]
    [                main] [ INFO] (17:34:37.494)           java.awt.graphicsenv [sun.awt.Win32GraphicsEnvironment]
    [                main] [ INFO] (17:34:37.494)            java.awt.printerjob [sun.awt.windows.WPrinterJob]
    [                main] [ INFO] (17:34:37.494)             java.class.version [52.0]
    [                main] [ INFO] (17:34:37.494)             java.endorsed.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\endorsed]
    [                main] [ INFO] (17:34:37.494)                  java.ext.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\ext;C:\WINDOWS\Sun\Java\lib\ext]
    [                main] [ INFO] (17:34:37.494)                      java.home [C:\app\Java\jdk1.8.0_211\jre]
    [                main] [ INFO] (17:34:37.494)                 java.io.tmpdir [C:\WKFS\RiskPro\rp-tmp]
    [                main] [ INFO] (17:34:37.494)              java.runtime.name [Java(TM) SE Runtime Environment]
    [                main] [ INFO] (17:34:37.494)           java.runtime.version [1.8.0_211-b12]
    [                main] [ INFO] (17:34:37.494)        java.specification.name [Java Platform API Specification]
    [                main] [ INFO] (17:34:37.494)      java.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:37.494)     java.specification.version [1.8]
    [                main] [ INFO] (17:34:37.494)                    java.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:37.494)                java.vendor.url [http://java.oracle.com/]
    [                main] [ INFO] (17:34:37.494)            java.vendor.url.bug [http://bugreport.sun.com/bugreport/]
    [                main] [ INFO] (17:34:37.494)                   java.version [1.8.0_211]
    [                main] [ INFO] (17:34:37.494)                   java.vm.info [mixed mode]
    [                main] [ INFO] (17:34:37.494)                   java.vm.name [Java HotSpot(TM) 64-Bit Server VM]
    [                main] [ INFO] (17:34:37.494)     java.vm.specification.name [Java Virtual Machine Specification]
    [                main] [ INFO] (17:34:37.494)   java.vm.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:37.494)  java.vm.specification.version [1.8]
    [                main] [ INFO] (17:34:37.494)                 java.vm.vendor [Oracle Corporation]
    [                main] [ INFO] (17:34:37.494)                java.vm.version [25.211-b12]
    [                main] [ INFO] (17:34:37.494)                 line.separator [
    ]
    [                main] [ INFO] (17:34:37.494)             od.service.address [http://127.0.0.1:8080/riskpro-web/res.svc]
    [                main] [ INFO] (17:34:37.494)                        os.arch [amd64]
    [                main] [ INFO] (17:34:37.494)                        os.name [Windows 10]
    [                main] [ INFO] (17:34:37.494)                     os.version [10.0]
    [                main] [ INFO] (17:34:37.494)                 path.separator [;]
    [                main] [ INFO] (17:34:37.494)                    rs.epr.base [http://127.0.0.1:8080/riskpro-web/api]
    [                main] [ INFO] (17:34:37.494)            sun.arch.data.model [64]
    [                main] [ INFO] (17:34:37.494)            sun.boot.class.path [C:\app\Java\jdk1.8.0_211\jre\lib\resources.jar;C:\app\Java\jdk1.8.0_211\jre\lib\rt.jar;C:\app\Java\jdk1.8.0_211\jre\lib\sunrsasign.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jsse.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jce.jar;C:\app\Java\jdk1.8.0_211\jre\lib\charsets.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jfr.jar;C:\app\Java\jdk1.8.0_211\jre\classes]
    [                main] [ INFO] (17:34:37.494)          sun.boot.library.path [C:\app\Java\jdk1.8.0_211\jre\bin]
    [                main] [ INFO] (17:34:37.494)                 sun.cpu.endian [little]
    [                main] [ INFO] (17:34:37.494)                sun.cpu.isalist [amd64]
    [                main] [ INFO] (17:34:37.502)                    sun.desktop [windows]
    [                main] [ INFO] (17:34:37.502)        sun.io.unicode.encoding [UnicodeLittle]
    [                main] [ INFO] (17:34:37.502)               sun.java.command [com.frsglobal.pub.batch.client.cli.AdministrationClient]
    [                main] [ INFO] (17:34:37.502)              sun.java.launcher [SUN_STANDARD]
    [                main] [ INFO] (17:34:37.502)               sun.jnu.encoding [Cp1252]
    [                main] [ INFO] (17:34:37.502)        sun.management.compiler [HotSpot 64-Bit Tiered Compilers]
    [                main] [ INFO] (17:34:37.502)             sun.os.patch.level []
    [                main] [ INFO] (17:34:37.502)            sun.stderr.encoding [cp437]
    [                main] [ INFO] (17:34:37.502)                   user.country [GB]
    [                main] [ INFO] (17:34:37.504)                       user.dir [C:\WKFS\Scripts\rp-deploy]
    [                main] [ INFO] (17:34:37.504)                      user.home [C:\Users\florian.carrier]
    [                main] [ INFO] (17:34:37.504)                  user.language [en]
    [                main] [ INFO] (17:34:37.504)                      user.name [Florian.Carrier]
    [                main] [ INFO] (17:34:37.504)                    user.script []
    [                main] [ INFO] (17:34:37.504)                  user.timezone [Europe/London]
    [                main] [ INFO] (17:34:37.504)                   user.variant []
    [                main] [ INFO] (17:34:37.504)                    ws.epr.base [http://127.0.0.1:8080/riskpro-web/batchapi]
    [                main] [ INFO] (17:34:37.504)                   ws.operation [createModel]
    [                main] [ INFO] (17:34:37.504)                   ws.user.name [admin]
    [                main] [ INFO] (17:34:37.504)                   ws.user.pswd [********]
    [                main] [ INFO] (17:34:46.087) Synchronous mode = false
    2020-02-26 17:34:46	CHECK	"System" model has been successfully created
    ```

## Smoke test

In this section, we will go through the steps to test the RiskPro platform.

1.  Check RiskPro application deployment.
    ```
    2020-02-26 18:05:19	INFO	Checking RiskPro platform accessibility
    DEBUG: http://127.0.0.1:8080/riskpro-web
    DEBUG: HTTP status: 200
    ```
2.  Create test user.
    ```
    2020-02-26 18:05:23	INFO	Creating test user "test"
    DEBUG: Use RiskPro test user credentials from configuration file
    DEBUG: & "C:\app\Java\jdk1.8.0_211\bin\java.exe" -classpath "C:\WKFS\RiskPro\rp-9.14.0\bin\riskpro-batch-client.jar" -D"ws.operation"="deleteUser" -D"ws.epr.base"="http://127.0.0.1:8080/riskpro-web/batchapi" -D"rs.epr.base"="http://127.0.0.1:8080/riskpro-web/api" -D"od.service.address"="http://127.0.0.1:8080/riskpro-web/res.svc" -D"ws.user.name"="admin" -D"ws.user.pswd"="*******" -D"ad.userName"="test" -D"java.io.tmpdir"="C:\WKFS\RiskPro\rp-tmp" -Xmx1G com.frsglobal.pub.batch.client.cli.AdministrationClient
    DEBUG: [                main] [ INFO] (18:05:23.837) Batch interface client successfully setup at [admin@http://127.0.0.1:8080/riskpro-web/batchapi?]
    [                main] [ INFO] (18:05:23.844)                    ad.userName [test]
    [                main] [ INFO] (18:05:23.844)                    awt.toolkit [sun.awt.windows.WToolkit]
    [                main] [ INFO] (18:05:23.844)                  file.encoding [Cp1252]
    [                main] [ INFO] (18:05:23.844)              file.encoding.pkg [sun.io]
    [                main] [ INFO] (18:05:23.845)                 file.separator [\]
    [                main] [ INFO] (18:05:23.845)           java.awt.graphicsenv [sun.awt.Win32GraphicsEnvironment]
    [                main] [ INFO] (18:05:23.845)            java.awt.printerjob [sun.awt.windows.WPrinterJob]
    [                main] [ INFO] (18:05:23.845)             java.class.version [52.0]
    [                main] [ INFO] (18:05:23.845)             java.endorsed.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\endorsed]
    [                main] [ INFO] (18:05:23.845)                  java.ext.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\ext;C:\WINDOWS\Sun\Java\lib\ext]
    [                main] [ INFO] (18:05:23.846)                      java.home [C:\app\Java\jdk1.8.0_211\jre]
    [                main] [ INFO] (18:05:23.846)                 java.io.tmpdir [C:\WKFS\RiskPro\rp-tmp]
    [                main] [ INFO] (18:05:23.846)              java.runtime.name [Java(TM) SE Runtime Environment]
    [                main] [ INFO] (18:05:23.846)           java.runtime.version [1.8.0_211-b12]
    [                main] [ INFO] (18:05:23.847)        java.specification.name [Java Platform API Specification]
    [                main] [ INFO] (18:05:23.847)      java.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (18:05:23.847)     java.specification.version [1.8]
    [                main] [ INFO] (18:05:23.847)                    java.vendor [Oracle Corporation]
    [                main] [ INFO] (18:05:23.847)                java.vendor.url [http://java.oracle.com/]
    [                main] [ INFO] (18:05:23.847)            java.vendor.url.bug [http://bugreport.sun.com/bugreport/]
    [                main] [ INFO] (18:05:23.848)                   java.version [1.8.0_211]
    [                main] [ INFO] (18:05:23.848)                   java.vm.info [mixed mode]
    [                main] [ INFO] (18:05:23.848)                   java.vm.name [Java HotSpot(TM) 64-Bit Server VM]
    [                main] [ INFO] (18:05:23.848)     java.vm.specification.name [Java Virtual Machine Specification]
    [                main] [ INFO] (18:05:23.848)   java.vm.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (18:05:23.848)  java.vm.specification.version [1.8]
    [                main] [ INFO] (18:05:23.848)                 java.vm.vendor [Oracle Corporation]
    [                main] [ INFO] (18:05:23.849)                java.vm.version [25.211-b12]
    [                main] [ INFO] (18:05:23.849)                 line.separator [
    ]
    [                main] [ INFO] (18:05:23.849)             od.service.address [http://127.0.0.1:8080/riskpro-web/res.svc]
    [                main] [ INFO] (18:05:23.849)                        os.arch [amd64]
    [                main] [ INFO] (18:05:23.849)                        os.name [Windows 10]
    [                main] [ INFO] (18:05:23.849)                     os.version [10.0]
    [                main] [ INFO] (18:05:23.849)                 path.separator [;]
    [                main] [ INFO] (18:05:23.850)                    rs.epr.base [http://127.0.0.1:8080/riskpro-web/api]
    [                main] [ INFO] (18:05:23.850)            sun.arch.data.model [64]
    [                main] [ INFO] (18:05:23.850)            sun.boot.class.path [C:\app\Java\jdk1.8.0_211\jre\lib\resources.jar;C:\app\Java\jdk1.8.0_211\jre\lib\rt.jar;C:\app\Java\jdk1.8.0_211\jre\lib\sunrsasign.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jsse.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jce.jar;C:\app\Java\jdk1.8.0_211\jre\lib\charsets.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jfr.jar;C:\app\Java\jdk1.8.0_211\jre\classes]
    [                main] [ INFO] (18:05:23.850)          sun.boot.library.path [C:\app\Java\jdk1.8.0_211\jre\bin]
    [                main] [ INFO] (18:05:23.850)                 sun.cpu.endian [little]
    [                main] [ INFO] (18:05:23.850)                sun.cpu.isalist [amd64]
    [                main] [ INFO] (18:05:23.850)                    sun.desktop [windows]
    [                main] [ INFO] (18:05:23.851)        sun.io.unicode.encoding [UnicodeLittle]
    [                main] [ INFO] (18:05:23.851)               sun.java.command [com.frsglobal.pub.batch.client.cli.AdministrationClient]
    [                main] [ INFO] (18:05:23.851)              sun.java.launcher [SUN_STANDARD]
    [                main] [ INFO] (18:05:23.851)               sun.jnu.encoding [Cp1252]
    [                main] [ INFO] (18:05:23.851)        sun.management.compiler [HotSpot 64-Bit Tiered Compilers]
    [                main] [ INFO] (18:05:23.851)             sun.os.patch.level []
    [                main] [ INFO] (18:05:23.851)            sun.stderr.encoding [cp437]
    [                main] [ INFO] (18:05:23.852)                   user.country [GB]
    [                main] [ INFO] (18:05:23.852)                       user.dir [C:\WKFS\Scripts\rp-deploy]
    [                main] [ INFO] (18:05:23.852)                      user.home [C:\Users\florian.carrier]
    [                main] [ INFO] (18:05:23.852)                  user.language [en]
    [                main] [ INFO] (18:05:23.852)                      user.name [Florian.Carrier]
    [                main] [ INFO] (18:05:23.852)                    user.script []
    [                main] [ INFO] (18:05:23.852)                  user.timezone [Europe/London]
    [                main] [ INFO] (18:05:23.853)                   user.variant []
    [                main] [ INFO] (18:05:23.853)                    ws.epr.base [http://127.0.0.1:8080/riskpro-web/batchapi]
    [                main] [ INFO] (18:05:23.853)                   ws.operation [deleteUser]
    [                main] [ INFO] (18:05:23.853)                   ws.user.name [admin]
    [                main] [ INFO] (18:05:23.853)                   ws.user.pswd [********]
    [                main] [ERROR] (18:05:25.922) Errors within web service response:
    [                main] [ERROR] (18:05:25.922) USER_NOT_FOUND{[test]}
    [                main] [ERROR] (18:05:25.922) Exception within web service response:
    java.lang.Exception: USER_NOT_FOUND{[test]}
    	at com.frsglobal.riskpro.batch.impl.ServiceUtilities.getUserId(ServiceUtilities.java:399)
    	at com.frsglobal.riskpro.batch.impl.administration.DefaultAdministrationService.deleteUser(DefaultAdministrationService.java:1101)
    	at com.frsglobal.riskpro.batch.rest.administration.AdministrationResource.deleteUser(AdministrationResource.java:184)
    	at com.frsglobal.riskpro.batch.rest.administration.AdministrationResource$Proxy$_$$_WeldSubclass.deleteUser$$super(Unknown Source)
    	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
    	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
    	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
    	at java.lang.reflect.Method.invoke(Method.java:498)
    	at org.jboss.weld.interceptor.proxy.TerminalAroundInvokeInvocationContext.proceedInternal(TerminalAroundInvokeInvocationContext.java:51)
    	at org.jboss.weld.interceptor.proxy.AroundInvokeInvocationContext.proceed(AroundInvokeInvocationContext.java:78)
    	at com.frsglobal.riskpro.authorization.AuthorizationInterceptor.aroundInvoke(AuthorizationInterceptor.java:92)
    	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
    	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
    	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
    	at java.lang.reflect.Method.invoke(Method.java:498)
    	at org.jboss.weld.interceptor.reader.SimpleInterceptorInvocation$SimpleMethodInvocation.invoke(SimpleInterceptorInvocation.java:73)
    	at org.jboss.weld.interceptor.proxy.InterceptorMethodHandler.executeAroundInvoke(InterceptorMethodHandler.java:84)
    	at org.jboss.weld.interceptor.proxy.InterceptorMethodHandler.executeInterception(InterceptorMethodHandler.java:72)
    	at org.jboss.weld.interceptor.proxy.InterceptorMethodHandler.invoke(InterceptorMethodHandler.java:56)
    	at org.jboss.weld.bean.proxy.CombinedInterceptorAndDecoratorStackMethodHandler.invoke(CombinedInterceptorAndDecoratorStackMethodHandler.java:79)
    	at org.jboss.weld.bean.proxy.CombinedInterceptorAndDecoratorStackMethodHandler.invoke(CombinedInterceptorAndDecoratorStackMethodHandler.java:68)
    	at com.frsglobal.riskpro.batch.rest.administration.AdministrationResource$Proxy$_$$_WeldSubclass.deleteUser(Unknown Source)
    	at com.frsglobal.riskpro.batch.rest.administration.AdministrationResource$Proxy$_$$_WeldClientProxy.deleteUser(Unknown Source)
    	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
    	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
    	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
    	at java.lang.reflect.Method.invoke(Method.java:498)
    	at org.jboss.resteasy.core.MethodInjectorImpl.invoke(MethodInjectorImpl.java:138)
    	at org.jboss.resteasy.core.ResourceMethodInvoker.internalInvokeOnTarget(ResourceMethodInvoker.java:517)
    	at org.jboss.resteasy.core.ResourceMethodInvoker.invokeOnTargetAfterFilter(ResourceMethodInvoker.java:406)
    	at org.jboss.resteasy.core.ResourceMethodInvoker.lambda$invokeOnTarget$0(ResourceMethodInvoker.java:370)
    	at org.jboss.resteasy.core.interception.PreMatchContainerRequestContext.filter(PreMatchContainerRequestContext.java:355)
    	at org.jboss.resteasy.core.ResourceMethodInvoker.invokeOnTarget(ResourceMethodInvoker.java:372)
    	at org.jboss.resteasy.core.ResourceMethodInvoker.invoke(ResourceMethodInvoker.java:344)
    	at org.jboss.resteasy.core.ResourceMethodInvoker.invoke(ResourceMethodInvoker.java:317)
    	at org.jboss.resteasy.core.SynchronousDispatcher.invoke(SynchronousDispatcher.java:440)
    	at org.jboss.resteasy.core.SynchronousDispatcher.lambda$invoke$4(SynchronousDispatcher.java:229)
    	at org.jboss.resteasy.core.SynchronousDispatcher.lambda$preprocess$0(SynchronousDispatcher.java:135)
    	at org.jboss.resteasy.core.interception.PreMatchContainerRequestContext.filter(PreMatchContainerRequestContext.java:355)
    	at org.jboss.resteasy.core.SynchronousDispatcher.preprocess(SynchronousDispatcher.java:138)
    	at org.jboss.resteasy.core.SynchronousDispatcher.invoke(SynchronousDispatcher.java:215)
    	at org.jboss.resteasy.plugins.server.servlet.ServletContainerDispatcher.service(ServletContainerDispatcher.java:227)
    	at org.jboss.resteasy.plugins.server.servlet.HttpServletDispatcher.service(HttpServletDispatcher.java:56)
    	at org.jboss.resteasy.plugins.server.servlet.HttpServletDispatcher.service(HttpServletDispatcher.java:51)
    	at javax.servlet.http.HttpServlet.service(HttpServlet.java:791)
    	at io.undertow.servlet.handlers.ServletHandler.handleRequest(ServletHandler.java:74)
    	at io.undertow.servlet.handlers.FilterHandler$FilterChainImpl.doFilter(FilterHandler.java:129)
    	at org.apache.shiro.web.servlet.ProxiedFilterChain.doFilter(ProxiedFilterChain.java:61)
    	at org.apache.shiro.web.servlet.AdviceFilter.executeChain(AdviceFilter.java:108)
    	at org.apache.shiro.web.servlet.AdviceFilter.doFilterInternal(AdviceFilter.java:137)
    	at org.apache.shiro.web.servlet.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:125)
    	at org.apache.shiro.web.servlet.ProxiedFilterChain.doFilter(ProxiedFilterChain.java:66)
    	at org.apache.shiro.web.servlet.AdviceFilter.executeChain(AdviceFilter.java:108)
    	at org.apache.shiro.web.servlet.AdviceFilter.doFilterInternal(AdviceFilter.java:137)
    	at org.apache.shiro.web.servlet.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:125)
    	at org.apache.shiro.web.servlet.ProxiedFilterChain.doFilter(ProxiedFilterChain.java:66)
    	at org.apache.shiro.web.servlet.AbstractShiroFilter.executeChain(AbstractShiroFilter.java:449)
    	at org.apache.shiro.web.servlet.AbstractShiroFilter$1.call(AbstractShiroFilter.java:365)
    	at org.apache.shiro.subject.support.SubjectCallable.doCall(SubjectCallable.java:90)
    	at org.apache.shiro.subject.support.SubjectCallable.call(SubjectCallable.java:83)
    	at org.apache.shiro.subject.support.DelegatingSubject.execute(DelegatingSubject.java:383)
    	at org.apache.shiro.web.servlet.AbstractShiroFilter.doFilterInternal(AbstractShiroFilter.java:362)
    	at org.apache.shiro.web.servlet.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:125)
    	at io.undertow.servlet.core.ManagedFilter.doFilter(ManagedFilter.java:61)
    	at io.undertow.servlet.handlers.FilterHandler$FilterChainImpl.doFilter(FilterHandler.java:131)
    	at io.undertow.servlet.handlers.FilterHandler.handleRequest(FilterHandler.java:84)
    	at io.undertow.servlet.handlers.security.ServletSecurityRoleHandler.handleRequest(ServletSecurityRoleHandler.java:62)
    	at io.undertow.servlet.handlers.ServletChain$1.handleRequest(ServletChain.java:68)
    	at io.undertow.servlet.handlers.ServletDispatchingHandler.handleRequest(ServletDispatchingHandler.java:36)
    	at org.wildfly.extension.undertow.security.SecurityContextAssociationHandler.handleRequest(SecurityContextAssociationHandler.java:78)
    	at io.undertow.server.handlers.PredicateHandler.handleRequest(PredicateHandler.java:43)
    	at io.undertow.servlet.handlers.security.SSLInformationAssociationHandler.handleRequest(SSLInformationAssociationHandler.java:132)
    	at io.undertow.servlet.handlers.security.ServletAuthenticationCallHandler.handleRequest(ServletAuthenticationCallHandler.java:57)
    	at io.undertow.server.handlers.PredicateHandler.handleRequest(PredicateHandler.java:43)
    	at io.undertow.security.handlers.AuthenticationConstraintHandler.handleRequest(AuthenticationConstraintHandler.java:53)
    	at io.undertow.security.handlers.AbstractConfidentialityHandler.handleRequest(AbstractConfidentialityHandler.java:46)
    	at io.undertow.servlet.handlers.security.ServletConfidentialityConstraintHandler.handleRequest(ServletConfidentialityConstraintHandler.java:64)
    	at io.undertow.servlet.handlers.security.ServletSecurityConstraintHandler.handleRequest(ServletSecurityConstraintHandler.java:59)
    	at io.undertow.security.handlers.AuthenticationMechanismsHandler.handleRequest(AuthenticationMechanismsHandler.java:60)
    	at io.undertow.servlet.handlers.security.CachedAuthenticatedSessionHandler.handleRequest(CachedAuthenticatedSessionHandler.java:77)
    	at io.undertow.security.handlers.NotificationReceiverHandler.handleRequest(NotificationReceiverHandler.java:50)
    	at io.undertow.security.handlers.AbstractSecurityContextAssociationHandler.handleRequest(AbstractSecurityContextAssociationHandler.java:43)
    	at io.undertow.server.handlers.PredicateHandler.handleRequest(PredicateHandler.java:43)
    	at org.wildfly.extension.undertow.security.jacc.JACCContextIdHandler.handleRequest(JACCContextIdHandler.java:61)
    	at io.undertow.server.handlers.PredicateHandler.handleRequest(PredicateHandler.java:43)
    	at org.wildfly.extension.undertow.deployment.GlobalRequestControllerHandler.handleRequest(GlobalRequestControllerHandler.java:68)
    	at io.undertow.server.handlers.PredicateHandler.handleRequest(PredicateHandler.java:43)
    	at io.undertow.servlet.handlers.ServletInitialHandler.handleFirstRequest(ServletInitialHandler.java:292)
    	at io.undertow.servlet.handlers.ServletInitialHandler.access$100(ServletInitialHandler.java:81)
    	at io.undertow.servlet.handlers.ServletInitialHandler$2.call(ServletInitialHandler.java:138)
    	at io.undertow.servlet.handlers.ServletInitialHandler$2.call(ServletInitialHandler.java:135)
    	at io.undertow.servlet.core.ServletRequestContextThreadSetupAction$1.call(ServletRequestContextThreadSetupAction.java:48)
    	at io.undertow.servlet.core.ContextClassLoaderSetupAction$1.call(ContextClassLoaderSetupAction.java:43)
    	at org.wildfly.extension.undertow.security.SecurityContextThreadSetupAction.lambda$create$0(SecurityContextThreadSetupAction.java:105)
    	at org.wildfly.extension.undertow.deployment.UndertowDeploymentInfoService$UndertowThreadSetupAction.lambda$create$0(UndertowDeploymentInfoService.java:1502)
    	at org.wildfly.extension.undertow.deployment.UndertowDeploymentInfoService$UndertowThreadSetupAction.lambda$create$0(UndertowDeploymentInfoService.java:1502)
    	at org.wildfly.extension.undertow.deployment.UndertowDeploymentInfoService$UndertowThreadSetupAction.lambda$create$0(UndertowDeploymentInfoService.java:1502)
    	at org.wildfly.extension.undertow.deployment.UndertowDeploymentInfoService$UndertowThreadSetupAction.lambda$create$0(UndertowDeploymentInfoService.java:1502)
    	at org.wildfly.extension.undertow.deployment.UndertowDeploymentInfoService$UndertowThreadSetupAction.lambda$create$0(UndertowDeploymentInfoService.java:1502)
    	at io.undertow.servlet.handlers.ServletInitialHandler.dispatchRequest(ServletInitialHandler.java:272)
    	at io.undertow.servlet.handlers.ServletInitialHandler.access$000(ServletInitialHandler.java:81)
    	at io.undertow.servlet.handlers.ServletInitialHandler$1.handleRequest(ServletInitialHandler.java:104)
    	at io.undertow.server.Connectors.executeRootHandler(Connectors.java:364)
    	at io.undertow.server.HttpServerExchange$1.run(HttpServerExchange.java:830)
    	at org.jboss.threads.ContextClassLoaderSavingRunnable.run(ContextClassLoaderSavingRunnable.java:35)
    	at org.jboss.threads.EnhancedQueueExecutor.safeRun(EnhancedQueueExecutor.java:1982)
    	at org.jboss.threads.EnhancedQueueExecutor$ThreadBody.doRunTask(EnhancedQueueExecutor.java:1486)
    	at org.jboss.threads.EnhancedQueueExecutor$ThreadBody.run(EnhancedQueueExecutor.java:1377)
    	at java.lang.Thread.run(Thread.java:748)
    [                main] [ERROR] (18:05:25.930) com.frsglobal.pub.exception.BatchClientException: Server-side exception: [USER_NOT_FOUND{[test]}]
    DEBUG: & "C:\app\Java\jdk1.8.0_211\bin\java.exe" -classpath "C:\WKFS\RiskPro\rp-9.14.0\bin\riskpro-batch-client.jar" -D"ws.operation"="createUser" -D"ws.epr.base"="http://127.0.0.1:8080/riskpro-web/batchapi" -D"rs.epr.base"="http://127.0.0.1:8080/riskpro-web/api" -D"od.service.address"="http://127.0.0.1:8080/riskpro-web/res.svc" -D"ws.user.name"="admin" -D"ws.user.pswd"="*******" -D"ad.userName"="test" -D"ad.employeeName"="Test user" -D"ad.userGroups"="Administrators" -D"java.io.tmpdir"="C:\WKFS\RiskPro\rp-tmp" -Xmx1G com.frsglobal.pub.batch.client.cli.AdministrationClient
    DEBUG: [                main] [ INFO] (18:05:26.331) Batch interface client successfully setup at [admin@http://127.0.0.1:8080/riskpro-web/batchapi?]
    [                main] [ INFO] (18:05:26.338)                ad.employeeName [Test user]
    [                main] [ INFO] (18:05:26.338)                  ad.userGroups [Administrators]
    [                main] [ INFO] (18:05:26.338)                    ad.userName [test]
    [                main] [ INFO] (18:05:26.338)                    awt.toolkit [sun.awt.windows.WToolkit]
    [                main] [ INFO] (18:05:26.338)                  file.encoding [Cp1252]
    [                main] [ INFO] (18:05:26.338)              file.encoding.pkg [sun.io]
    [                main] [ INFO] (18:05:26.339)                 file.separator [\]
    [                main] [ INFO] (18:05:26.339)           java.awt.graphicsenv [sun.awt.Win32GraphicsEnvironment]
    [                main] [ INFO] (18:05:26.339)            java.awt.printerjob [sun.awt.windows.WPrinterJob]
    [                main] [ INFO] (18:05:26.339)             java.class.version [52.0]
    [                main] [ INFO] (18:05:26.339)             java.endorsed.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\endorsed]
    [                main] [ INFO] (18:05:26.339)                  java.ext.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\ext;C:\WINDOWS\Sun\Java\lib\ext]
    [                main] [ INFO] (18:05:26.340)                      java.home [C:\app\Java\jdk1.8.0_211\jre]
    [                main] [ INFO] (18:05:26.340)                 java.io.tmpdir [C:\WKFS\RiskPro\rp-tmp]
    [                main] [ INFO] (18:05:26.340)              java.runtime.name [Java(TM) SE Runtime Environment]
    [                main] [ INFO] (18:05:26.340)           java.runtime.version [1.8.0_211-b12]
    [                main] [ INFO] (18:05:26.341)        java.specification.name [Java Platform API Specification]
    [                main] [ INFO] (18:05:26.341)      java.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (18:05:26.341)     java.specification.version [1.8]
    [                main] [ INFO] (18:05:26.341)                    java.vendor [Oracle Corporation]
    [                main] [ INFO] (18:05:26.341)                java.vendor.url [http://java.oracle.com/]
    [                main] [ INFO] (18:05:26.341)            java.vendor.url.bug [http://bugreport.sun.com/bugreport/]
    [                main] [ INFO] (18:05:26.341)                   java.version [1.8.0_211]
    [                main] [ INFO] (18:05:26.342)                   java.vm.info [mixed mode]
    [                main] [ INFO] (18:05:26.342)                   java.vm.name [Java HotSpot(TM) 64-Bit Server VM]
    [                main] [ INFO] (18:05:26.342)     java.vm.specification.name [Java Virtual Machine Specification]
    [                main] [ INFO] (18:05:26.342)   java.vm.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (18:05:26.342)  java.vm.specification.version [1.8]
    [                main] [ INFO] (18:05:26.342)                 java.vm.vendor [Oracle Corporation]
    [                main] [ INFO] (18:05:26.342)                java.vm.version [25.211-b12]
    [                main] [ INFO] (18:05:26.343)                 line.separator [
    ]
    [                main] [ INFO] (18:05:26.343)             od.service.address [http://127.0.0.1:8080/riskpro-web/res.svc]
    [                main] [ INFO] (18:05:26.343)                        os.arch [amd64]
    [                main] [ INFO] (18:05:26.343)                        os.name [Windows 10]
    [                main] [ INFO] (18:05:26.343)                     os.version [10.0]
    [                main] [ INFO] (18:05:26.344)                 path.separator [;]
    [                main] [ INFO] (18:05:26.344)                    rs.epr.base [http://127.0.0.1:8080/riskpro-web/api]
    [                main] [ INFO] (18:05:26.344)            sun.arch.data.model [64]
    [                main] [ INFO] (18:05:26.344)            sun.boot.class.path [C:\app\Java\jdk1.8.0_211\jre\lib\resources.jar;C:\app\Java\jdk1.8.0_211\jre\lib\rt.jar;C:\app\Java\jdk1.8.0_211\jre\lib\sunrsasign.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jsse.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jce.jar;C:\app\Java\jdk1.8.0_211\jre\lib\charsets.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jfr.jar;C:\app\Java\jdk1.8.0_211\jre\classes]
    [                main] [ INFO] (18:05:26.344)          sun.boot.library.path [C:\app\Java\jdk1.8.0_211\jre\bin]
    [                main] [ INFO] (18:05:26.345)                 sun.cpu.endian [little]
    [                main] [ INFO] (18:05:26.345)                sun.cpu.isalist [amd64]
    [                main] [ INFO] (18:05:26.345)                    sun.desktop [windows]
    [                main] [ INFO] (18:05:26.345)        sun.io.unicode.encoding [UnicodeLittle]
    [                main] [ INFO] (18:05:26.346)               sun.java.command [com.frsglobal.pub.batch.client.cli.AdministrationClient]
    [                main] [ INFO] (18:05:26.346)              sun.java.launcher [SUN_STANDARD]
    [                main] [ INFO] (18:05:26.346)               sun.jnu.encoding [Cp1252]
    [                main] [ INFO] (18:05:26.346)        sun.management.compiler [HotSpot 64-Bit Tiered Compilers]
    [                main] [ INFO] (18:05:26.346)             sun.os.patch.level []
    [                main] [ INFO] (18:05:26.346)            sun.stderr.encoding [cp437]
    [                main] [ INFO] (18:05:26.346)                   user.country [GB]
    [                main] [ INFO] (18:05:26.347)                       user.dir [C:\WKFS\Scripts\rp-deploy]
    [                main] [ INFO] (18:05:26.347)                      user.home [C:\Users\florian.carrier]
    [                main] [ INFO] (18:05:26.347)                  user.language [en]
    [                main] [ INFO] (18:05:26.347)                      user.name [Florian.Carrier]
    [                main] [ INFO] (18:05:26.347)                    user.script []
    [                main] [ INFO] (18:05:26.347)                  user.timezone [Europe/London]
    [                main] [ INFO] (18:05:26.347)                   user.variant []
    [                main] [ INFO] (18:05:26.348)                    ws.epr.base [http://127.0.0.1:8080/riskpro-web/batchapi]
    [                main] [ INFO] (18:05:26.348)                   ws.operation [createUser]
    [                main] [ INFO] (18:05:26.348)                   ws.user.name [admin]
    [                main] [ INFO] (18:05:26.348)                   ws.user.pswd [********]
    [                main] [ INFO] (18:05:28.569) Synchronous mode = false
    DEBUG: Set test user password
    DEBUG: & "C:\app\Java\jdk1.8.0_211\bin\java.exe" -classpath "C:\WKFS\RiskPro\rp-9.14.0\bin\riskpro-batch-client.jar" -D"ws.operation"="setUserPassword" -D"ws.epr.base"="http://127.0.0.1:8080/riskpro-web/batchapi" -D"rs.epr.base"="http://127.0.0.1:8080/riskpro-web/api" -D"od.service.address"="http://127.0.0.1:8080/riskpro-web/res.svc" -D"ws.user.name"="admin" -D"ws.user.pswd"="*******" -D"ad.userName"="test" -D"ad.newPassword"="*******" -D"java.io.tmpdir"="C:\WKFS\RiskPro\rp-tmp" -Xmx1G com.frsglobal.pub.batch.client.cli.AdministrationClient
    DEBUG: [                main] [ INFO] (18:05:28.983) Batch interface client successfully setup at [admin@http://127.0.0.1:8080/riskpro-web/batchapi?]
    [                main] [ INFO] (18:05:28.990)                 ad.newPassword [welcome]
    [                main] [ INFO] (18:05:28.991)                    ad.userName [test]
    [                main] [ INFO] (18:05:28.991)                    awt.toolkit [sun.awt.windows.WToolkit]
    [                main] [ INFO] (18:05:28.991)                  file.encoding [Cp1252]
    [                main] [ INFO] (18:05:28.991)              file.encoding.pkg [sun.io]
    [                main] [ INFO] (18:05:28.991)                 file.separator [\]
    [                main] [ INFO] (18:05:28.991)           java.awt.graphicsenv [sun.awt.Win32GraphicsEnvironment]
    [                main] [ INFO] (18:05:28.991)            java.awt.printerjob [sun.awt.windows.WPrinterJob]
    [                main] [ INFO] (18:05:28.992)             java.class.version [52.0]
    [                main] [ INFO] (18:05:28.992)             java.endorsed.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\endorsed]
    [                main] [ INFO] (18:05:28.992)                  java.ext.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\ext;C:\WINDOWS\Sun\Java\lib\ext]
    [                main] [ INFO] (18:05:28.992)                      java.home [C:\app\Java\jdk1.8.0_211\jre]
    [                main] [ INFO] (18:05:28.992)                 java.io.tmpdir [C:\WKFS\RiskPro\rp-tmp]
    [                main] [ INFO] (18:05:28.992)              java.runtime.name [Java(TM) SE Runtime Environment]
    [                main] [ INFO] (18:05:28.993)           java.runtime.version [1.8.0_211-b12]
    [                main] [ INFO] (18:05:28.993)        java.specification.name [Java Platform API Specification]
    [                main] [ INFO] (18:05:28.993)      java.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (18:05:28.993)     java.specification.version [1.8]
    [                main] [ INFO] (18:05:28.993)                    java.vendor [Oracle Corporation]
    [                main] [ INFO] (18:05:28.993)                java.vendor.url [http://java.oracle.com/]
    [                main] [ INFO] (18:05:28.993)            java.vendor.url.bug [http://bugreport.sun.com/bugreport/]
    [                main] [ INFO] (18:05:28.994)                   java.version [1.8.0_211]
    [                main] [ INFO] (18:05:28.994)                   java.vm.info [mixed mode]
    [                main] [ INFO] (18:05:28.994)                   java.vm.name [Java HotSpot(TM) 64-Bit Server VM]
    [                main] [ INFO] (18:05:28.994)     java.vm.specification.name [Java Virtual Machine Specification]
    [                main] [ INFO] (18:05:28.994)   java.vm.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (18:05:28.995)  java.vm.specification.version [1.8]
    [                main] [ INFO] (18:05:28.995)                 java.vm.vendor [Oracle Corporation]
    [                main] [ INFO] (18:05:28.995)                java.vm.version [25.211-b12]
    [                main] [ INFO] (18:05:28.995)                 line.separator [
    ]
    [                main] [ INFO] (18:05:28.995)             od.service.address [http://127.0.0.1:8080/riskpro-web/res.svc]
    [                main] [ INFO] (18:05:28.995)                        os.arch [amd64]
    [                main] [ INFO] (18:05:28.996)                        os.name [Windows 10]
    [                main] [ INFO] (18:05:28.996)                     os.version [10.0]
    [                main] [ INFO] (18:05:28.996)                 path.separator [;]
    [                main] [ INFO] (18:05:28.996)                    rs.epr.base [http://127.0.0.1:8080/riskpro-web/api]
    [                main] [ INFO] (18:05:28.996)            sun.arch.data.model [64]
    [                main] [ INFO] (18:05:28.996)            sun.boot.class.path [C:\app\Java\jdk1.8.0_211\jre\lib\resources.jar;C:\app\Java\jdk1.8.0_211\jre\lib\rt.jar;C:\app\Java\jdk1.8.0_211\jre\lib\sunrsasign.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jsse.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jce.jar;C:\app\Java\jdk1.8.0_211\jre\lib\charsets.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jfr.jar;C:\app\Java\jdk1.8.0_211\jre\classes]
    [                main] [ INFO] (18:05:28.996)          sun.boot.library.path [C:\app\Java\jdk1.8.0_211\jre\bin]
    [                main] [ INFO] (18:05:28.996)                 sun.cpu.endian [little]
    [                main] [ INFO] (18:05:28.997)                sun.cpu.isalist [amd64]
    [                main] [ INFO] (18:05:28.997)                    sun.desktop [windows]
    [                main] [ INFO] (18:05:28.997)        sun.io.unicode.encoding [UnicodeLittle]
    [                main] [ INFO] (18:05:28.997)               sun.java.command [com.frsglobal.pub.batch.client.cli.AdministrationClient]
    [                main] [ INFO] (18:05:28.997)              sun.java.launcher [SUN_STANDARD]
    [                main] [ INFO] (18:05:28.997)               sun.jnu.encoding [Cp1252]
    [                main] [ INFO] (18:05:28.997)        sun.management.compiler [HotSpot 64-Bit Tiered Compilers]
    [                main] [ INFO] (18:05:28.997)             sun.os.patch.level []
    [                main] [ INFO] (18:05:28.997)            sun.stderr.encoding [cp437]
    [                main] [ INFO] (18:05:28.998)                   user.country [GB]
    [                main] [ INFO] (18:05:28.998)                       user.dir [C:\WKFS\Scripts\rp-deploy]
    [                main] [ INFO] (18:05:28.998)                      user.home [C:\Users\florian.carrier]
    [                main] [ INFO] (18:05:28.998)                  user.language [en]
    [                main] [ INFO] (18:05:28.998)                      user.name [Florian.Carrier]
    [                main] [ INFO] (18:05:28.999)                    user.script []
    [                main] [ INFO] (18:05:28.999)                  user.timezone [Europe/London]
    [                main] [ INFO] (18:05:28.999)                   user.variant []
    [                main] [ INFO] (18:05:28.999)                    ws.epr.base [http://127.0.0.1:8080/riskpro-web/batchapi]
    [                main] [ INFO] (18:05:28.999)                   ws.operation [setUserPassword]
    [                main] [ INFO] (18:05:28.999)                   ws.user.name [admin]
    [                main] [ INFO] (18:05:29.000)                   ws.user.pswd [********]
    [                main] [ INFO] (18:05:30.886) Synchronous mode = false
    2020-02-26 18:05:30	CHECK	"test" user has been successfully created
    ```
3.  Create test model from ALM template.
    ```
    2020-02-26 18:05:33	INFO	Creating test model "Test"
    DEBUG: & "C:\app\Java\jdk1.8.0_211\bin\java.exe" -classpath "C:\WKFS\RiskPro\rp-9.14.0\bin\riskpro-batch-client.jar" -D"ws.operation"="createModel" -D"ws.epr.base"="http://127.0.0.1:8080/riskpro-web/batchapi" -D"rs.epr.base"="http://127.0.0.1:8080/riskpro-web/api" -D"od.service.address"="http://127.0.0.1:8080/riskpro-web/res.svc" -D"ws.user.name"="admin" -D"ws.user.pswd"="*******" -D"ad.name"="Test" -D"ad.modelType"="PRODUCTION" -D"ad.description"="Test model" -D"ad.baseCurrency"="CHF" -D"ad.modelGroupName"="System models" -D"ad.factoryType"="ALM_TEMP_1_1_WITH_CONTRACTS" -D"java.io.tmpdir"="C:\WKFS\RiskPro\rp-tmp" -Xmx1G com.frsglobal.pub.batch.client.cli.AdministrationClient
    DEBUG: [                main] [ INFO] (18:05:43.554) Batch interface client successfully setup at [admin@http://127.0.0.1:8080/riskpro-web/batchapi?]
    [                main] [ INFO] (18:05:43.566)                ad.baseCurrency [CHF]
    [                main] [ INFO] (18:05:43.566)                 ad.description [Test model]
    [                main] [ INFO] (18:05:43.567)                 ad.factoryType [ALM_TEMP_1_1_WITH_CONTRACTS]
    [                main] [ INFO] (18:05:43.567)              ad.modelGroupName [System models]
    [                main] [ INFO] (18:05:43.568)                   ad.modelType [PRODUCTION]
    [                main] [ INFO] (18:05:43.568)                        ad.name [Test]
    [                main] [ INFO] (18:05:43.568)                    awt.toolkit [sun.awt.windows.WToolkit]
    [                main] [ INFO] (18:05:43.568)                  file.encoding [Cp1252]
    [                main] [ INFO] (18:05:43.569)              file.encoding.pkg [sun.io]
    [                main] [ INFO] (18:05:43.569)                 file.separator [\]
    [                main] [ INFO] (18:05:43.569)           java.awt.graphicsenv [sun.awt.Win32GraphicsEnvironment]
    [                main] [ INFO] (18:05:43.570)            java.awt.printerjob [sun.awt.windows.WPrinterJob]
    [                main] [ INFO] (18:05:43.570)             java.class.version [52.0]
    [                main] [ INFO] (18:05:43.570)             java.endorsed.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\endorsed]
    [                main] [ INFO] (18:05:43.571)                  java.ext.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\ext;C:\WINDOWS\Sun\Java\lib\ext]
    [                main] [ INFO] (18:05:43.571)                      java.home [C:\app\Java\jdk1.8.0_211\jre]
    [                main] [ INFO] (18:05:43.571)                 java.io.tmpdir [C:\WKFS\RiskPro\rp-tmp]
    [                main] [ INFO] (18:05:43.571)              java.runtime.name [Java(TM) SE Runtime Environment]
    [                main] [ INFO] (18:05:43.572)           java.runtime.version [1.8.0_211-b12]
    [                main] [ INFO] (18:05:43.572)        java.specification.name [Java Platform API Specification]
    [                main] [ INFO] (18:05:43.572)      java.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (18:05:43.573)     java.specification.version [1.8]
    [                main] [ INFO] (18:05:43.573)                    java.vendor [Oracle Corporation]
    [                main] [ INFO] (18:05:43.573)                java.vendor.url [http://java.oracle.com/]
    [                main] [ INFO] (18:05:43.573)            java.vendor.url.bug [http://bugreport.sun.com/bugreport/]
    [                main] [ INFO] (18:05:43.574)                   java.version [1.8.0_211]
    [                main] [ INFO] (18:05:43.574)                   java.vm.info [mixed mode]
    [                main] [ INFO] (18:05:43.574)                   java.vm.name [Java HotSpot(TM) 64-Bit Server VM]
    [                main] [ INFO] (18:05:43.575)     java.vm.specification.name [Java Virtual Machine Specification]
    [                main] [ INFO] (18:05:43.576)   java.vm.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (18:05:43.576)  java.vm.specification.version [1.8]
    [                main] [ INFO] (18:05:43.576)                 java.vm.vendor [Oracle Corporation]
    [                main] [ INFO] (18:05:43.576)                java.vm.version [25.211-b12]
    [                main] [ INFO] (18:05:43.577)                 line.separator [
    ]
    [                main] [ INFO] (18:05:43.577)             od.service.address [http://127.0.0.1:8080/riskpro-web/res.svc]
    [                main] [ INFO] (18:05:43.577)                        os.arch [amd64]
    [                main] [ INFO] (18:05:43.577)                        os.name [Windows 10]
    [                main] [ INFO] (18:05:43.578)                     os.version [10.0]
    [                main] [ INFO] (18:05:43.578)                 path.separator [;]
    [                main] [ INFO] (18:05:43.578)                    rs.epr.base [http://127.0.0.1:8080/riskpro-web/api]
    [                main] [ INFO] (18:05:43.578)            sun.arch.data.model [64]
    [                main] [ INFO] (18:05:43.578)            sun.boot.class.path [C:\app\Java\jdk1.8.0_211\jre\lib\resources.jar;C:\app\Java\jdk1.8.0_211\jre\lib\rt.jar;C:\app\Java\jdk1.8.0_211\jre\lib\sunrsasign.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jsse.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jce.jar;C:\app\Java\jdk1.8.0_211\jre\lib\charsets.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jfr.jar;C:\app\Java\jdk1.8.0_211\jre\classes]
    [                main] [ INFO] (18:05:43.579)          sun.boot.library.path [C:\app\Java\jdk1.8.0_211\jre\bin]
    [                main] [ INFO] (18:05:43.579)                 sun.cpu.endian [little]
    [                main] [ INFO] (18:05:43.579)                sun.cpu.isalist [amd64]
    [                main] [ INFO] (18:05:43.580)                    sun.desktop [windows]
    [                main] [ INFO] (18:05:43.580)        sun.io.unicode.encoding [UnicodeLittle]
    [                main] [ INFO] (18:05:43.580)               sun.java.command [com.frsglobal.pub.batch.client.cli.AdministrationClient]
    [                main] [ INFO] (18:05:43.580)              sun.java.launcher [SUN_STANDARD]
    [                main] [ INFO] (18:05:43.580)               sun.jnu.encoding [Cp1252]
    [                main] [ INFO] (18:05:43.581)        sun.management.compiler [HotSpot 64-Bit Tiered Compilers]
    [                main] [ INFO] (18:05:43.581)             sun.os.patch.level []
    [                main] [ INFO] (18:05:43.581)            sun.stderr.encoding [cp437]
    [                main] [ INFO] (18:05:43.582)                   user.country [GB]
    [                main] [ INFO] (18:05:43.582)                       user.dir [C:\WKFS\Scripts\rp-deploy]
    [                main] [ INFO] (18:05:43.582)                      user.home [C:\Users\florian.carrier]
    [                main] [ INFO] (18:05:43.582)                  user.language [en]
    [                main] [ INFO] (18:05:43.582)                      user.name [Florian.Carrier]
    [                main] [ INFO] (18:05:43.582)                    user.script []
    [                main] [ INFO] (18:05:43.583)                  user.timezone [Europe/London]
    [                main] [ INFO] (18:05:43.583)                   user.variant []
    [                main] [ INFO] (18:05:43.583)                    ws.epr.base [http://127.0.0.1:8080/riskpro-web/batchapi]
    [                main] [ INFO] (18:05:43.583)                   ws.operation [createModel]
    [                main] [ INFO] (18:05:43.583)                   ws.user.name [admin]
    [                main] [ INFO] (18:05:43.583)                   ws.user.pswd [********]
    [                main] [ INFO] (18:06:25.195) Synchronous mode = false
    2020-02-26 18:06:25	CHECK	"Test" model has been successfully created
    ```
4.  Run static solve.
    ```
    2020-02-26 18:06:25	INFO	Starting static analysis (Market Static)
    DEBUG: & "C:\app\Java\jdk1.8.0_211\bin\java.exe" -classpath "C:\WKFS\RiskPro\rp-9.14.0\bin\riskpro-batch-client.jar" -D"ws.operation"="startStaticSolve" -D"ws.epr.base"="http://127.0.0.1:8080/riskpro-web/batchapi" -D"rs.epr.base"="http://127.0.0.1:8080/riskpro-web/api" -D"od.service.address"="http://127.0.0.1:8080/riskpro-web/res.svc" -D"ws.user.name"="admin" -D"ws.user.pswd"="*******" -D"sv.modelName"="Test" -D"sv.resultSelectionName"="Market Static" -D"sv.accountStructureName"="WBR1" -D"sv.solveName"="Static Analysis" -D"sv.analysisDate"="01/04/2010 AM" -D"sv.dataGroupNames"="Current BS" -D"sv.dataFilters"="" -D"sv.deleteResults"="True" -D"sv.persistent"="" -D"ws.sync"="True" -D"java.io.tmpdir"="C:\WKFS\RiskPro\rp-tmp" -Xmx1G com.frsglobal.pub.batch.client.cli.SolveClient
    DEBUG: [                main] [ INFO] (18:06:25.598) Batch interface client successfully setup at [admin@http://127.0.0.1:8080/riskpro-web/batchapi?]
    [                main] [ INFO] (18:06:25.604)                    awt.toolkit [sun.awt.windows.WToolkit]
    [                main] [ INFO] (18:06:25.604)                  file.encoding [Cp1252]
    [                main] [ INFO] (18:06:25.604)              file.encoding.pkg [sun.io]
    [                main] [ INFO] (18:06:25.604)                 file.separator [\]
    [                main] [ INFO] (18:06:25.604)           java.awt.graphicsenv [sun.awt.Win32GraphicsEnvironment]
    [                main] [ INFO] (18:06:25.604)            java.awt.printerjob [sun.awt.windows.WPrinterJob]
    [                main] [ INFO] (18:06:25.605)             java.class.version [52.0]
    [                main] [ INFO] (18:06:25.605)             java.endorsed.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\endorsed]
    [                main] [ INFO] (18:06:25.605)                  java.ext.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\ext;C:\WINDOWS\Sun\Java\lib\ext]
    [                main] [ INFO] (18:06:25.605)                      java.home [C:\app\Java\jdk1.8.0_211\jre]
    [                main] [ INFO] (18:06:25.605)                 java.io.tmpdir [C:\WKFS\RiskPro\rp-tmp]
    [                main] [ INFO] (18:06:25.605)              java.runtime.name [Java(TM) SE Runtime Environment]
    [                main] [ INFO] (18:06:25.605)           java.runtime.version [1.8.0_211-b12]
    [                main] [ INFO] (18:06:25.605)        java.specification.name [Java Platform API Specification]
    [                main] [ INFO] (18:06:25.606)      java.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (18:06:25.606)     java.specification.version [1.8]
    [                main] [ INFO] (18:06:25.606)                    java.vendor [Oracle Corporation]
    [                main] [ INFO] (18:06:25.606)                java.vendor.url [http://java.oracle.com/]
    [                main] [ INFO] (18:06:25.606)            java.vendor.url.bug [http://bugreport.sun.com/bugreport/]
    [                main] [ INFO] (18:06:25.606)                   java.version [1.8.0_211]
    [                main] [ INFO] (18:06:25.606)                   java.vm.info [mixed mode]
    [                main] [ INFO] (18:06:25.606)                   java.vm.name [Java HotSpot(TM) 64-Bit Server VM]
    [                main] [ INFO] (18:06:25.606)     java.vm.specification.name [Java Virtual Machine Specification]
    [                main] [ INFO] (18:06:25.607)   java.vm.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (18:06:25.607)  java.vm.specification.version [1.8]
    [                main] [ INFO] (18:06:25.607)                 java.vm.vendor [Oracle Corporation]
    [                main] [ INFO] (18:06:25.607)                java.vm.version [25.211-b12]
    [                main] [ INFO] (18:06:25.607)                 line.separator [
    ]
    [                main] [ INFO] (18:06:25.607)             od.service.address [http://127.0.0.1:8080/riskpro-web/res.svc]
    [                main] [ INFO] (18:06:25.607)                        os.arch [amd64]
    [                main] [ INFO] (18:06:25.607)                        os.name [Windows 10]
    [                main] [ INFO] (18:06:25.607)                     os.version [10.0]
    [                main] [ INFO] (18:06:25.607)                 path.separator [;]
    [                main] [ INFO] (18:06:25.608)                    rs.epr.base [http://127.0.0.1:8080/riskpro-web/api]
    [                main] [ INFO] (18:06:25.608)            sun.arch.data.model [64]
    [                main] [ INFO] (18:06:25.608)            sun.boot.class.path [C:\app\Java\jdk1.8.0_211\jre\lib\resources.jar;C:\app\Java\jdk1.8.0_211\jre\lib\rt.jar;C:\app\Java\jdk1.8.0_211\jre\lib\sunrsasign.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jsse.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jce.jar;C:\app\Java\jdk1.8.0_211\jre\lib\charsets.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jfr.jar;C:\app\Java\jdk1.8.0_211\jre\classes]
    [                main] [ INFO] (18:06:25.608)          sun.boot.library.path [C:\app\Java\jdk1.8.0_211\jre\bin]
    [                main] [ INFO] (18:06:25.608)                 sun.cpu.endian [little]
    [                main] [ INFO] (18:06:25.608)                sun.cpu.isalist [amd64]
    [                main] [ INFO] (18:06:25.608)                    sun.desktop [windows]
    [                main] [ INFO] (18:06:25.608)        sun.io.unicode.encoding [UnicodeLittle]
    [                main] [ INFO] (18:06:25.608)               sun.java.command [com.frsglobal.pub.batch.client.cli.SolveClient]
    [                main] [ INFO] (18:06:25.608)              sun.java.launcher [SUN_STANDARD]
    [                main] [ INFO] (18:06:25.609)               sun.jnu.encoding [Cp1252]
    [                main] [ INFO] (18:06:25.609)        sun.management.compiler [HotSpot 64-Bit Tiered Compilers]
    [                main] [ INFO] (18:06:25.609)             sun.os.patch.level []
    [                main] [ INFO] (18:06:25.609)            sun.stderr.encoding [cp437]
    [                main] [ INFO] (18:06:25.609)        sv.accountStructureName [WBR1]
    [                main] [ INFO] (18:06:25.609)                sv.analysisDate [01/04/2010 AM]
    [                main] [ INFO] (18:06:25.609)                 sv.dataFilters []
    [                main] [ INFO] (18:06:25.609)              sv.dataGroupNames [Current BS]
    [                main] [ INFO] (18:06:25.609)               sv.deleteResults [True]
    [                main] [ INFO] (18:06:25.609)                   sv.modelName [Test]
    [                main] [ INFO] (18:06:25.610)                  sv.persistent []
    [                main] [ INFO] (18:06:25.610)         sv.resultSelectionName [Market Static]
    [                main] [ INFO] (18:06:25.610)                   sv.solveName [Static Analysis]
    [                main] [ INFO] (18:06:25.610)                   user.country [GB]
    [                main] [ INFO] (18:06:25.610)                       user.dir [C:\WKFS\Scripts\rp-deploy]
    [                main] [ INFO] (18:06:25.610)                      user.home [C:\Users\florian.carrier]
    [                main] [ INFO] (18:06:25.610)                  user.language [en]
    [                main] [ INFO] (18:06:25.610)                      user.name [Florian.Carrier]
    [                main] [ INFO] (18:06:25.611)                    user.script []
    [                main] [ INFO] (18:06:25.611)                  user.timezone [Europe/London]
    [                main] [ INFO] (18:06:25.611)                   user.variant []
    [                main] [ INFO] (18:06:25.611)                    ws.epr.base [http://127.0.0.1:8080/riskpro-web/batchapi]
    [                main] [ INFO] (18:06:25.611)                   ws.operation [startStaticSolve]
    [                main] [ INFO] (18:06:25.611)                        ws.sync [True]
    [                main] [ INFO] (18:06:25.611)                   ws.user.name [admin]
    [                main] [ INFO] (18:06:25.612)                   ws.user.pswd [********]
    [                main] [ INFO] (18:06:25.615) Deleting job [Static Analysis / STATIC]
    [                main] [ INFO] (18:06:27.840) Job [Static Analysis / STATIC] deleted
    [                main] [ INFO] (18:06:28.268) Synchronous mode = true
    [                main] [ INFO] (18:06:28.270) Initial wait of 10.00 seconds for the job to get processed.
    [                main] [ INFO] (18:06:38.271) Polling started without timeout set.
    [                main] [ INFO] (18:06:38.271) Requesting info for model 'Test', solve 'Static Analysis', kind 'STATIC'.
    [                main] [ INFO] (18:06:38.354) Solve job completed: 2020-02-26 18:06:35.027 (COMPLETED)
    2020-02-26 18:06:38	CHECK	Static analysis run successfully
    ```
5.  Run dynamic solve.
    ```
    2020-02-26 18:06:38	INFO	Starting dynamic analysis (Dynamic what-If)
    DEBUG: & "C:\app\Java\jdk1.8.0_211\bin\java.exe" -classpath "C:\WKFS\RiskPro\rp-9.14.0\bin\riskpro-batch-client.jar" -D"ws.operation"="startDynamicSolve" -D"ws.epr.base"="http://127.0.0.1:8080/riskpro-web/batchapi" -D"rs.epr.base"="http://127.0.0.1:8080/riskpro-web/api" -D"od.service.address"="http://127.0.0.1:8080/riskpro-web/res.svc" -D"ws.user.name"="admin" -D"ws.user.pswd"="*******" -D"sv.modelName"="Test" -D"sv.resultSelectionName"="Dynamic what-If" -D"sv.accountStructureName"="WBR1" -D"sv.solveName"="Dynamic Analysis" -D"sv.analysisDate"="01/04/2010 AM" -D"sv.dataGroupNames"="Current BS" -D"sv.dataFilters"="" -D"sv.deleteResults"="True" -D"sv.persistent"="" -D"ws.sync"="True" -D"java.io.tmpdir"="C:\WKFS\RiskPro\rp-tmp" -Xmx1G com.frsglobal.pub.batch.client.cli.SolveClient
    DEBUG: [                main] [ INFO] (18:06:38.658) Batch interface client successfully setup at [admin@http://127.0.0.1:8080/riskpro-web/batchapi?]
    [                main] [ INFO] (18:06:38.664)                    awt.toolkit [sun.awt.windows.WToolkit]
    [                main] [ INFO] (18:06:38.665)                  file.encoding [Cp1252]
    [                main] [ INFO] (18:06:38.665)              file.encoding.pkg [sun.io]
    [                main] [ INFO] (18:06:38.665)                 file.separator [\]
    [                main] [ INFO] (18:06:38.665)           java.awt.graphicsenv [sun.awt.Win32GraphicsEnvironment]
    [                main] [ INFO] (18:06:38.666)            java.awt.printerjob [sun.awt.windows.WPrinterJob]
    [                main] [ INFO] (18:06:38.666)             java.class.version [52.0]
    [                main] [ INFO] (18:06:38.666)             java.endorsed.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\endorsed]
    [                main] [ INFO] (18:06:38.666)                  java.ext.dirs [C:\app\Java\jdk1.8.0_211\jre\lib\ext;C:\WINDOWS\Sun\Java\lib\ext]
    [                main] [ INFO] (18:06:38.666)                      java.home [C:\app\Java\jdk1.8.0_211\jre]
    [                main] [ INFO] (18:06:38.667)                 java.io.tmpdir [C:\WKFS\RiskPro\rp-tmp]
    [                main] [ INFO] (18:06:38.667)              java.runtime.name [Java(TM) SE Runtime Environment]
    [                main] [ INFO] (18:06:38.667)           java.runtime.version [1.8.0_211-b12]
    [                main] [ INFO] (18:06:38.667)        java.specification.name [Java Platform API Specification]
    [                main] [ INFO] (18:06:38.667)      java.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (18:06:38.667)     java.specification.version [1.8]
    [                main] [ INFO] (18:06:38.668)                    java.vendor [Oracle Corporation]
    [                main] [ INFO] (18:06:38.668)                java.vendor.url [http://java.oracle.com/]
    [                main] [ INFO] (18:06:38.668)            java.vendor.url.bug [http://bugreport.sun.com/bugreport/]
    [                main] [ INFO] (18:06:38.668)                   java.version [1.8.0_211]
    [                main] [ INFO] (18:06:38.668)                   java.vm.info [mixed mode]
    [                main] [ INFO] (18:06:38.668)                   java.vm.name [Java HotSpot(TM) 64-Bit Server VM]
    [                main] [ INFO] (18:06:38.668)     java.vm.specification.name [Java Virtual Machine Specification]
    [                main] [ INFO] (18:06:38.668)   java.vm.specification.vendor [Oracle Corporation]
    [                main] [ INFO] (18:06:38.668)  java.vm.specification.version [1.8]
    [                main] [ INFO] (18:06:38.669)                 java.vm.vendor [Oracle Corporation]
    [                main] [ INFO] (18:06:38.669)                java.vm.version [25.211-b12]
    [                main] [ INFO] (18:06:38.669)                 line.separator [
    ]
    [                main] [ INFO] (18:06:38.669)             od.service.address [http://127.0.0.1:8080/riskpro-web/res.svc]
    [                main] [ INFO] (18:06:38.669)                        os.arch [amd64]
    [                main] [ INFO] (18:06:38.669)                        os.name [Windows 10]
    [                main] [ INFO] (18:06:38.669)                     os.version [10.0]
    [                main] [ INFO] (18:06:38.669)                 path.separator [;]
    [                main] [ INFO] (18:06:38.669)                    rs.epr.base [http://127.0.0.1:8080/riskpro-web/api]
    [                main] [ INFO] (18:06:38.670)            sun.arch.data.model [64]
    [                main] [ INFO] (18:06:38.670)            sun.boot.class.path [C:\app\Java\jdk1.8.0_211\jre\lib\resources.jar;C:\app\Java\jdk1.8.0_211\jre\lib\rt.jar;C:\app\Java\jdk1.8.0_211\jre\lib\sunrsasign.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jsse.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jce.jar;C:\app\Java\jdk1.8.0_211\jre\lib\charsets.jar;C:\app\Java\jdk1.8.0_211\jre\lib\jfr.jar;C:\app\Java\jdk1.8.0_211\jre\classes]
    [                main] [ INFO] (18:06:38.670)          sun.boot.library.path [C:\app\Java\jdk1.8.0_211\jre\bin]
    [                main] [ INFO] (18:06:38.670)                 sun.cpu.endian [little]
    [                main] [ INFO] (18:06:38.670)                sun.cpu.isalist [amd64]
    [                main] [ INFO] (18:06:38.670)                    sun.desktop [windows]
    [                main] [ INFO] (18:06:38.670)        sun.io.unicode.encoding [UnicodeLittle]
    [                main] [ INFO] (18:06:38.670)               sun.java.command [com.frsglobal.pub.batch.client.cli.SolveClient]
    [                main] [ INFO] (18:06:38.670)              sun.java.launcher [SUN_STANDARD]
    [                main] [ INFO] (18:06:38.671)               sun.jnu.encoding [Cp1252]
    [                main] [ INFO] (18:06:38.671)        sun.management.compiler [HotSpot 64-Bit Tiered Compilers]
    [                main] [ INFO] (18:06:38.671)             sun.os.patch.level []
    [                main] [ INFO] (18:06:38.671)            sun.stderr.encoding [cp437]
    [                main] [ INFO] (18:06:38.671)        sv.accountStructureName [WBR1]
    [                main] [ INFO] (18:06:38.671)                sv.analysisDate [01/04/2010 AM]
    [                main] [ INFO] (18:06:38.671)                 sv.dataFilters []
    [                main] [ INFO] (18:06:38.671)              sv.dataGroupNames [Current BS]
    [                main] [ INFO] (18:06:38.671)               sv.deleteResults [True]
    [                main] [ INFO] (18:06:38.671)                   sv.modelName [Test]
    [                main] [ INFO] (18:06:38.672)                  sv.persistent []
    [                main] [ INFO] (18:06:38.672)         sv.resultSelectionName [Dynamic what-If]
    [                main] [ INFO] (18:06:38.672)                   sv.solveName [Dynamic Analysis]
    [                main] [ INFO] (18:06:38.672)                   user.country [GB]
    [                main] [ INFO] (18:06:38.672)                       user.dir [C:\WKFS\Scripts\rp-deploy]
    [                main] [ INFO] (18:06:38.672)                      user.home [C:\Users\florian.carrier]
    [                main] [ INFO] (18:06:38.672)                  user.language [en]
    [                main] [ INFO] (18:06:38.672)                      user.name [Florian.Carrier]
    [                main] [ INFO] (18:06:38.673)                    user.script []
    [                main] [ INFO] (18:06:38.673)                  user.timezone [Europe/London]
    [                main] [ INFO] (18:06:38.673)                   user.variant []
    [                main] [ INFO] (18:06:38.673)                    ws.epr.base [http://127.0.0.1:8080/riskpro-web/batchapi]
    [                main] [ INFO] (18:06:38.673)                   ws.operation [startDynamicSolve]
    [                main] [ INFO] (18:06:38.673)                        ws.sync [True]
    [                main] [ INFO] (18:06:38.673)                   ws.user.name [admin]
    [                main] [ INFO] (18:06:38.673)                   ws.user.pswd [********]
    [                main] [ INFO] (18:06:38.676) Deleting job [Dynamic Analysis / DYNAMIC]
    [                main] [ INFO] (18:06:40.812) Job [Dynamic Analysis / DYNAMIC] deleted
    [                main] [ INFO] (18:06:41.067) Synchronous mode = true
    [                main] [ INFO] (18:06:41.068) Initial wait of 10.00 seconds for the job to get processed.
    [                main] [ INFO] (18:06:51.071) Polling started without timeout set.
    [                main] [ INFO] (18:06:51.071) Requesting info for model 'Test', solve 'Dynamic Analysis', kind 'DYNAMIC'.
    [                main] [ INFO] (18:06:52.376) Solve job is being processed: RUNNING
    [                main] [ INFO] (18:06:52.376) Waiting for 10.00 seconds until the next poll.
    [                main] [ INFO] (18:07:02.377) Requesting info for model 'Test', solve 'Dynamic Analysis', kind 'DYNAMIC'.
    [                main] [ INFO] (18:07:02.457) Solve job completed: 2020-02-26 18:06:58.077 (COMPLETED)
    2020-02-26 18:07:02	CHECK	Dynamic analysis run successfully
    ```
