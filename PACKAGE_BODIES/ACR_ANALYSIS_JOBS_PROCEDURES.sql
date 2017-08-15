--------------------------------------------------------
--  DDL for Package Body ACR_ANALYSIS_JOBS_PROCEDURES
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_ANALYSIS_JOBS_PROCEDURES" 

is
  procedure ACR_ACTION_JOB_PROCEDURE
  is
    vCommentText  ACR_ANALYSIS.AAN_COMMENT%type;
  begin
    update ACR_ANALYSIS
    set AAN_COMMENT = 'UPDATED BY JOB ON ' || TO_CHAR(SYSDATE, 'DD.MM.YY') || CHR(13) || AAN_COMMENT
    where AAN_COMMENT is null;
  end;

end ACR_ANALYSIS_JOBS_PROCEDURES;
