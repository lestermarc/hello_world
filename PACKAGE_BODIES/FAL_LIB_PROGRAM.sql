--------------------------------------------------------
--  DDL for Package Body FAL_LIB_PROGRAM
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_PROGRAM" 
is

  /**
  * Description
  *   look for FAL_JOB_PROGRAM_ID with given job reference
  */
  function GetJobProgramId(iProgramReference in FAL_JOB_PROGRAM.JOP_REFERENCE%type)
    return FAL_JOB_PROGRAM.FAL_JOB_PROGRAM_ID%type
  is
    lResult FAL_JOB_PROGRAM.FAL_JOB_PROGRAM_ID%type;
  begin
    select FAL_JOB_PROGRAM_ID
      into lResult
      from FAL_JOB_PROGRAM
     where JOP_REFERENCE = iProgramReference;
    return lResult;
  exception
    when NO_DATA_FOUND then
      return null;
  end;

  /**
  * function GetJobProgramRef
  * Description
  *   look for job reference with given FAL_JOB_PROGRAM_ID
  * @created fp 11.01.2011
  * @lastUpdate
  * @public
  * @param iProgramID : ID du program
  * @return
  */
  function GetJobProgramRef(iProgramID in number)
    return FAL_JOB_PROGRAM.JOP_REFERENCE%type
  is
    lResult FAL_JOB_PROGRAM.JOP_REFERENCE%type;
  begin
    select JOP_REFERENCE
      into lResult
      from FAL_JOB_PROGRAM
     where FAL_JOB_PROGRAM_ID = iProgramID;
    return lResult;
  exception
    when NO_DATA_FOUND then
      return null;
  end;

end FAL_LIB_PROGRAM;
