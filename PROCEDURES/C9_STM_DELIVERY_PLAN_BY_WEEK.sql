--------------------------------------------------------
--  DDL for Procedure C9_STM_DELIVERY_PLAN_BY_WEEK
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "C9_STM_DELIVERY_PLAN_BY_WEEK" (
  aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PROCPARAM_0 in     varchar2
, PROCPARAM_1 in     varchar2
)

is
/**
* Procédure stockée utilisée pour le rapport STM_DELIVERY_PLAN_BY_WEEK_RPT (Liste des cours de matières premières)
*
* @author TDY
* @lastUpdate
* @version 2003
* @public
* @param PROCPARAM_0	Date de début de 1ere semaine 'yyyyMMdd' à analyser
* @param PROCPARAM_0	Date de fin de dernière semaine 'yyyyMMdd'
*/
begin

open aRefCursor for
 SELECT DPL_YEAR,
        DIU_NAME,
		DED_DATE,
		DED_CODE
 FROM   STM_DELIVERY_S_DIU S,
        STM_DELIVERY_PLAN  P,
		STM_DISTRIBUTION_UNIT U,
        (select *
		 from   STM_DELIVERY_DAY
		 where (DED_DATE >=TO_DATE (PROCPARAM_0, 'YYYYMMDD') AND DED_DATE<=TO_DATE (PROCPARAM_1, 'YYYYMMDD'))) D
 WHERE  S.STM_DELIVERY_PLAN_ID = P.STM_DELIVERY_PLAN_ID AND
        S.STM_DISTRIBUTION_UNIT_ID= U.STM_DISTRIBUTION_UNIT_ID AND
	    S.STM_DELIVERY_S_DIU_ID   = D.STM_DELIVERY_S_DIU_ID(+);

end C9_STM_DELIVERY_PLAN_BY_WEEK;
