-- General settings
UPDATE	SLV_CONFIGURATION_DESC
SET			MAX_SIMULTANEOUS_JOB		= #{MaxSimultaneousJob},
				INITIAL_PORT						= #{InitialPort},
				test							= -1
WHERE	SLV_CONFIGURATION_DESC_ID	= #{ConfigurationID}
