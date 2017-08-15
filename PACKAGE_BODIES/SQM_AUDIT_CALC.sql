--------------------------------------------------------
--  DDL for Package Body SQM_AUDIT_CALC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SQM_AUDIT_CALC" 
is
/*--------------------------------------------------------------------------------------------------------------------*/
  procedure ChapterWeightAvg(
    aAuditID   in     SQM_AUDIT.SQM_AUDIT_ID%type
  , aChapterID in     SQM_AUDIT_CHAPTER.SQM_AUDIT_CHAPTER_ID%type
  , aValue     out    SQM_AUDIT_DETAIL.ADE_POINTS%type
  )
  is
  begin
    select sum(AQU.AQU_WEIGHT * ADE.ADE_POINTS) / sum(AQU.AQU_WEIGHT)
      into aValue
      from SQM_AUDIT_DETAIL ADE
         , SQM_AUDIT_QUESTION AQU
     where ADE.SQM_AUDIT_ID = aAuditID
       and ADE.SQM_AUDIT_CHAPTER_ID = aChapterID
       and AQU.SQM_AUDIT_QUESTION_ID = ADE.SQM_AUDIT_QUESTION_ID;
  end ChapterWeightAvg;

/*--------------------------------------------------------------------------------------------------------------------*/
  procedure AuditWeightAvg(aAuditID in SQM_AUDIT.SQM_AUDIT_ID%type, aValue out SQM_AUDIT.AUD_RESULT%type)
  is
  begin
    select ltrim(to_char(sum(ADE.ADE_POINTS * CSM.CSM_WEIGHT) / sum(CSM.CSM_WEIGHT), '999999D9999') )
      into aValue
      from SQM_AUDIT_DETAIL ADE
         , SQM_AUDIT AUD
         , SQM_AUDIT_CHAP_S_MODEL CSM
     where ADE.SQM_AUDIT_ID = aAuditID
       and ADE.SQM_AUDIT_ID = AUD.SQM_AUDIT_ID
       and AUD.SQM_AUDIT_MODEL_ID = CSM.SQM_AUDIT_MODEL_ID
       and ADE.SQM_AUDIT_CHAPTER_ID = CSM.SQM_AUDIT_CHAPTER_ID
       and ADE.SQM_AUDIT_QUESTION_ID is null;
  end AuditWeightAvg;
end SQM_AUDIT_CALC;
