--------------------------------------------------------
--  DDL for Function HRM_GET_RDV_SUMMARY
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "HRM_GET_RDV_SUMMARY" (DayDate IN DATE) RETURN VARCHAR2
/**
* Function HRM_Get_Rdv_Summary
 * @version 1.0
 * @date 11/2005
 * @author spfister
 *
 * Copyright 1997-2005 Pro-Concept SA. Tous droits réservés.
 *
 * Retourne le résumé des rendez-vous pour une date.
 *
 * Modifications:
 */
is
  result VARCHAR2(4000);
begin
  for tplSchedule in (
      select to_char(Sci_Start_Time,'HH24:MI')||'-'||to_char(Sci_End_Time,'HH24:MI')||Chr(10)||Scp_Comment rdv
      from pac_schedule_interro
      where scp_date = DayDate and hrm_person_id is not null and Sci_Start_Time is not null
      order by Sci_Start_Time) loop
    result := result || tplSchedule.rdv ||Chr(10);
  end loop;
  return result;
end;
