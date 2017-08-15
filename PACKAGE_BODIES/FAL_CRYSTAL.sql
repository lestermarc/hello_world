--------------------------------------------------------
--  DDL for Package Body FAL_CRYSTAL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_CRYSTAL" 
is
  procedure UpdateFALPrint(Fal_id in number)
  is
  begin
    update FAL_TASK_LINK
       set TAL_SUBCONTRACT_PRINT = 1
         , TAL_SUB_PRINT_DATE = sysdate
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_SCHEDULE_STEP_ID = Fal_id;
  end;

  procedure UpdateEquiPrint(Equi_id in number)
  is
  begin
    update FAL_DOC_CONSULT
       set FDC_PRINT = 1
         , FDC_PRINT_DATE = sysdate
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_DOC_CONSULT_ID = Equi_id;
  end;
end;
