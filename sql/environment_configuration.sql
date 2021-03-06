-- -----------------------------------------------------------------------------
-- Environment configuration
-- SLV_ENVIRONMENT_DESC
-- -----------------------------------------------------------------------------

-- Enable identity insert
SET IDENTITY_INSERT SLV_ENVIRONMENT_DESC ON

-- Check if configuration exists
IF EXISTS (
	SELECT	1
	FROM		SLV_ENVIRONMENT_DESC
	WHERE		SLV_ENVIRONMENT_DESC_ID	= #{SLV_ENVIRONMENT_DESC_ID}
)
BEGIN
	-- Update existing configuration
	UPDATE	SLV_ENVIRONMENT_DESC
	SET			NAME													= '#{NAME}',
					DESCRIPTION										= '#{DESCRIPTION}',
					DEFAULT_SLV_CONF_DESC_ID			= #{DEFAULT_SLV_CONF_DESC_ID},
					SLV_TESS_DESC_ID							= #{SLV_TESS_DESC_ID},
					REF_CUSTOMIZATIONS_MGNT_ID		= #{REF_CUSTOMIZATIONS_MGNT_ID},
					IS_PROD												= #{IS_PROD},
					CONTRACT_FK_READER_CACHE_SIZE	= #{CONTRACT_FK_READER_CACHE_SIZE},
					CONTRACT_WRITER_BATCH_SIZE		= #{CONTRACT_WRITER_BATCH_SIZE},
					RESULT_WRITER_BATCH_SIZE			= #{RESULT_WRITER_BATCH_SIZE},
					SAVE_RESULTS_TO_CSV						= #{SAVE_RESULTS_TO_CSV},
					IS_AUDIT_ACTIVATED						= #{IS_AUDIT_ACTIVATED},
					MAINTENANCE_TIME_FRAME				= #{MAINTENANCE_TIME_FRAME},
					NO_ACTIVITY_TIME_FRAME				= #{NO_ACTIVITY_TIME_FRAME},
					IS_MAINTENANCE_ACTIVATED			= #{IS_MAINTENANCE_ACTIVATED},
					IS_NO_ACTIVITY_ACTIVATED			= #{IS_NO_ACTIVITY_ACTIVATED},
					NR_OF_DAYS_FOR_ERRORS					= #{NR_OF_DAYS_FOR_ERRORS},
					MAINTENANCE_TO_BE_CANCELLED		= #{MAINTENANCE_TO_BE_CANCELLED},
					NO_ACTIVITY_TO_BE_CANCELLED		= #{NO_ACTIVITY_TO_BE_CANCELLED},
					MAINTENANCE_SKIP_FLAG					= #{MAINTENANCE_SKIP_FLAG},
					MERGE_CANDIDATE_MAX_ROWS			= #{MERGE_CANDIDATE_MAX_ROWS},
					MERGED_PARTITION_MAX_ROWS			= #{MERGED_PARTITION_MAX_ROWS},
					LICENSE_SIGNATURE							= '#{LICENSE_SIGNATURE}',
					LICENSE												= '#{LICENSE}',
					IS_MANUAL_MAINTENANCE					= #{IS_MANUAL_MAINTENANCE},
					ALTERNATIVE_DATA_SOURCE				= #{ALTERNATIVE_DATA_SOURCE},
					IS_WKS_MNG_ACTIVATED					= #{IS_WKS_MNG_ACTIVATED},
					WKS_MNG_USER_PREFIX						= #{WKS_MNG_USER_PREFIX},
					LAST_UPDATE										= CURRENT_TIMESTAMP,
					USER_UPDATE										= CURRENT_USER,
					VERSION_KEY										= -1
	WHERE		SLV_ENVIRONMENT_DESC_ID				= #{SLV_ENVIRONMENT_DESC_ID}
END
ELSE
BEGIN
	-- Create new configuration
	INSERT INTO SLV_ENVIRONMENT_DESC (SLV_ENVIRONMENT_DESC_ID, NAME, DESCRIPTION, DEFAULT_SLV_CONF_DESC_ID, SLV_TESS_DESC_ID, REF_CUSTOMIZATIONS_MGNT_ID, LAST_UPDATE, USER_UPDATE, VERSION_KEY, IS_PROD, CONTRACT_FK_READER_CACHE_SIZE, CONTRACT_WRITER_BATCH_SIZE, RESULT_WRITER_BATCH_SIZE, SAVE_RESULTS_TO_CSV, IS_AUDIT_ACTIVATED, MAINTENANCE_TIME_FRAME, NO_ACTIVITY_TIME_FRAME, IS_MAINTENANCE_ACTIVATED, IS_NO_ACTIVITY_ACTIVATED, NR_OF_DAYS_FOR_ERRORS, MAINTENANCE_TO_BE_CANCELLED, NO_ACTIVITY_TO_BE_CANCELLED, MAINTENANCE_SKIP_FLAG, MERGE_CANDIDATE_MAX_ROWS, MERGED_PARTITION_MAX_ROWS, LICENSE_SIGNATURE, LICENSE, IS_MANUAL_MAINTENANCE, ALTERNATIVE_DATA_SOURCE, IS_WKS_MNG_ACTIVATED, WKS_MNG_USER_PREFIX)
	VALUES (
		#{SLV_ENVIRONMENT_DESC_ID},
		'#{NAME}',
		'#{DESCRIPTION}',
		#{DEFAULT_SLV_CONF_DESC_ID},
		#{SLV_TESS_DESC_ID},
		#{REF_CUSTOMIZATIONS_MGNT_ID},
		CURRENT_TIMESTAMP,
		CURRENT_USER,
		-1,
		#{IS_PROD},
		#{CONTRACT_FK_READER_CACHE_SIZE},
		#{CONTRACT_WRITER_BATCH_SIZE},
		#{RESULT_WRITER_BATCH_SIZE},
		#{SAVE_RESULTS_TO_CSV},
		#{IS_AUDIT_ACTIVATED},
		#{MAINTENANCE_TIME_FRAME},
		#{NO_ACTIVITY_TIME_FRAME},
		#{IS_MAINTENANCE_ACTIVATED},
		#{IS_NO_ACTIVITY_ACTIVATED},
		#{NR_OF_DAYS_FOR_ERRORS},
		#{MAINTENANCE_TO_BE_CANCELLED},
		#{NO_ACTIVITY_TO_BE_CANCELLED},
		#{MAINTENANCE_SKIP_FLAG},
		#{MERGE_CANDIDATE_MAX_ROWS},
		#{MERGED_PARTITION_MAX_ROWS},
		'#{LICENSE_SIGNATURE}',
		'#{LICENSE}',
		#{IS_MANUAL_MAINTENANCE},
		#{ALTERNATIVE_DATA_SOURCE},
		#{IS_WKS_MNG_ACTIVATED},
		#{WKS_MNG_USER_PREFIX}
	)
END

-- Disable identity insert
SET IDENTITY_INSERT SLV_ENVIRONMENT_DESC OFF
