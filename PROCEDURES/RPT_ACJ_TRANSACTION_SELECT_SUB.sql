--------------------------------------------------------
--  DDL for Procedure RPT_ACJ_TRANSACTION_SELECT_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACJ_TRANSACTION_SELECT_SUB" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       VARCHAR2
)
IS

/**
*DESCRIPTION
Used for report ACJ_TRANSACTION_SELECT,the subreport of ACJ_CATALOGUE_TYPE
*author JLI
*lastUpdate 2009-7-29
*public
*@param PARAMETER_0:  ACJ_CATALOGUE_TYPE_ID
*/


BEGIN


OPEN arefcursor FOR

SELECT
CAT.CAT_DESCRIPTION,
CAT.CAT_KEY,
CTP.ACJ_CATALOGUE_TYPE_ID,
JTP.TYP_DESCRIPTION,
JTP.TYP_KEY
FROM
ACJ_CATALOGUE_DOCUMENT CAT,
ACJ_CATALOGUE_TYPE_SET CTP,
ACJ_JOB_TYPE JTP,
ACJ_JOB_TYPE_S_CATALOGUE TSC
WHERE
CTP.ACJ_CATALOGUE_TYPE_ID = parameter_0
AND CTP.ACJ_JOB_TYPE_S_CATALOGUE_ID = TSC.ACJ_JOB_TYPE_S_CATALOGUE_ID
AND TSC.ACJ_JOB_TYPE_ID = JTP.ACJ_JOB_TYPE_ID
AND TSC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
;
END RPT_ACJ_TRANSACTION_SELECT_SUB;