-- -----------------------------------------------------------------------------
-- Staging area configuration
-- SLV_STAGING_AREA_DESC
-- -----------------------------------------------------------------------------

-- Enable identity insert
SET IDENTITY_INSERT SLV_STAGING_AREA_DESC ON

-- Check if configuration exists
IF EXISTS (
	SELECT	1
	FROM		SLV_STAGING_AREA_DESC
	WHERE		SLV_STAGING_AREA_DESC_ID				= #{SLV_STAGING_AREA_DESC_ID}
)
BEGIN
	-- Update existing configuration
	UPDATE	SLV_STAGING_AREA_DESC
	SET			HOSTNAME												= '#{HOSTNAME}',
					NAME														= '#{NAME}',
					OLAP_CELL_EVAL_THREAD_COUNT			= #{OLAP_CELL_EVAL_THREAD_COUNT},
					OLAP_CELL_EVAL_QUEUE_SIZE				= #{OLAP_CELL_EVAL_QUEUE_SIZE},
					TRANSIENT_RES_MGR_QUEUE_SIZE		= #{TRANSIENT_RES_MGR_QUEUE_SIZE},
					PERSISTENT_RES_MGR_QUEUE_SIZE		= #{PERSISTENT_RES_MGR_QUEUE_SIZE},
					MAX_TRANSIENT_RESULT_SIZE				= #{MAX_TRANSIENT_RESULT_SIZE},
					MAX_ERR_COUNT_BY_TYPE						= #{MAX_ERR_COUNT_BY_TYPE},
					MAX_CELL_COUNT									= #{MAX_CELL_COUNT},
					RESULT_AGGREG_THREAD_COUNT			= #{RESULT_AGGREG_THREAD_COUNT},
					PERSISTNT_RES_MGR_THREAD_COUNT	= #{PERSISTNT_RES_MGR_THREAD_COUNT},
					OLAP_TIMEOUT_INTERVAL						= #{OLAP_TIMEOUT_INTERVAL},
					CT_LVL_CUBE_TIMEOUT							= #{CT_LVL_CUBE_TIMEOUT},
					VERSION_KEY											= -1,
					LAST_UPDATE											=	CURRENT_TIMESTAMP,
					USER_UPDATE											= CURRENT_USER
	WHERE		SLV_STAGING_AREA_DESC_ID				= #{SLV_STAGING_AREA_DESC_ID}
END
ELSE
BEGIN
	-- Create new configuration
	INSERT INTO	SLV_STAGING_AREA_DESC (SLV_STAGING_AREA_DESC_ID, USER_UPDATE, LAST_UPDATE, VERSION_KEY, HOSTNAME, NAME, OLAP_CELL_EVAL_THREAD_COUNT, OLAP_CELL_EVAL_QUEUE_SIZE, TRANSIENT_RES_MGR_QUEUE_SIZE, PERSISTENT_RES_MGR_QUEUE_SIZE, MAX_TRANSIENT_RESULT_SIZE, MAX_ERR_COUNT_BY_TYPE, MAX_CELL_COUNT, RESULT_AGGREG_THREAD_COUNT, PERSISTNT_RES_MGR_THREAD_COUNT, OLAP_TIMEOUT_INTERVAL, CT_LVL_CUBE_TIMEOUT)
	VALUES (
		#{SLV_STAGING_AREA_DESC_ID},
		CURRENT_USER,
		CURRENT_TIMESTAMP,
		-1,
		'#{HOSTNAME}',
		'#{NAME}',
		#{OLAP_CELL_EVAL_THREAD_COUNT},
		#{OLAP_CELL_EVAL_QUEUE_SIZE},
		#{TRANSIENT_RES_MGR_QUEUE_SIZE},
		#{PERSISTENT_RES_MGR_QUEUE_SIZE},
		#{MAX_TRANSIENT_RESULT_SIZE},
		#{MAX_ERR_COUNT_BY_TYPE},
		#{MAX_CELL_COUNT},
		#{RESULT_AGGREG_THREAD_COUNT},
		#{PERSISTNT_RES_MGR_THREAD_COUNT},
		#{OLAP_TIMEOUT_INTERVAL},
		#{CT_LVL_CUBE_TIMEOUT}
	)
END

-- Disable identity insert
SET IDENTITY_INSERT SLV_STAGING_AREA_DESC OFF
