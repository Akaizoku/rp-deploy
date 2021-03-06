-- -----------------------------------------------------------------------------
-- Calculation configuration
-- SLV_CONFIGURATION_DESC
-- -----------------------------------------------------------------------------

-- Enable identity insert
SET IDENTITY_INSERT SLV_CONFIGURATION_DESC ON

-- Check if configuration exists
IF EXISTS (
	SELECT	1
	FROM		SLV_CONFIGURATION_DESC
	WHERE		SLV_CONFIGURATION_DESC_ID	= #{SLV_CONFIGURATION_DESC_ID}
)
BEGIN
	-- Update existing configuration
	UPDATE	SLV_CONFIGURATION_DESC
	SET			NAME												= '#{NAME}',
					DESCRIPTION									= '#{DESCRIPTION}',
					SLV_STAGING_AREA_DESC_ID		= #{SLV_STAGING_AREA_DESC_ID},
					SLV_JOB_CONTROLLER_DESC_ID	= #{SLV_JOB_CONTROLLER_DESC_ID},
					SLV_ENVIRONMENT_DESC_ID			= #{SLV_ENVIRONMENT_DESC_ID},
					MAX_SIMULTANEOUS_JOB				= #{MAX_SIMULTANEOUS_JOB},
					INITIAL_PORT								= #{INITIAL_PORT},
					LAST_UPDATE									= CURRENT_TIMESTAMP,
					USER_UPDATE									= CURRENT_USER,
					VERSION_KEY									= -1
	WHERE		SLV_CONFIGURATION_DESC_ID		= #{SLV_CONFIGURATION_DESC_ID}
END
ELSE
BEGIN
	-- Create new configuration
	INSERT INTO SLV_CONFIGURATION_DESC (SLV_CONFIGURATION_DESC_ID, NAME, DESCRIPTION, SLV_STAGING_AREA_DESC_ID, SLV_JOB_CONTROLLER_DESC_ID, SLV_ENVIRONMENT_DESC_ID, LAST_UPDATE, USER_UPDATE, VERSION_KEY, MAX_SIMULTANEOUS_JOB, INITIAL_PORT)
	VALUES (
		#{SLV_CONFIGURATION_DESC_ID},
		'#{NAME}',
		'#{DESCRIPTION}',
		#{SLV_STAGING_AREA_DESC_ID},
		#{SLV_JOB_CONTROLLER_DESC_ID},
		#{SLV_ENVIRONMENT_DESC_ID},
		CURRENT_TIMESTAMP,
		CURRENT_USER,
		-1,
		#{MAX_SIMULTANEOUS_JOB},
		#{INITIAL_PORT}
	)
END

-- Disable identity insert
SET IDENTITY_INSERT SLV_CONFIGURATION_DESC OFF
