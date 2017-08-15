--------------------------------------------------------
--  DDL for Package Body FAL_LIB_MASTER_PLAN
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_MASTER_PLAN" 
is
  /**
  * Description
  *   Vérifie l'existence d'enregistrements dans la table FAL_PIC_LINE_TEMP pour l'utilisateur concerné.
  **/
  function hasTmpLines(iFalPicID in FAL_PIC.FAL_PIC_ID%type, iPitUserCode in FAL_PIC_LINE_TEMP.PIT_USER_CODE%type)
    return number
  is
    lnCounter number;
  begin
    select count(*)
      into lnCounter
      from dual
     where exists(select FAL_PIC_LINE_ID
                    from FAL_PIC_LINE_TEMP
                   where FAL_PIC_ID = iFalPicID
                     and PIT_USER_CODE = iPitUserCode);

    return lnCounter;
  end hasTmpLines;

end FAL_LIB_MASTER_PLAN;
