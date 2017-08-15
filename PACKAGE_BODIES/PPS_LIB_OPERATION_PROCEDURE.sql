--------------------------------------------------------
--  DDL for Package Body PPS_LIB_OPERATION_PROCEDURE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PPS_LIB_OPERATION_PROCEDURE" 
is
  /**
  * Description
  *    Retourne 1 si la référence transmise est unique, sinon 0
  */
  function isRefUnique(
    iOperationProcedureID in PPS_OPERATION_PROCEDURE.PPS_OPERATION_PROCEDURE_ID%type
  , iReference            in PPS_OPERATION_PROCEDURE.OPP_REFERENCE%type default null
  )
    return integer
  as
    lOperationProcID PPS_OPERATION_PROCEDURE.PPS_OPERATION_PROCEDURE_ID%type;
    lReference       PPS_OPERATION_PROCEDURE.OPP_REFERENCE%type;
  begin
    lReference  := nvl(iReference, FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('PPS_OPERATION_PROCEDURE', 'OPP_REFERENCE', iOperationProcedureID) );

    select PPS_OPERATION_PROCEDURE_ID
      into lOperationProcID
      from PPS_OPERATION_PROCEDURE
     where PPS_OPERATION_PROCEDURE_ID <> iOperationProcedureId
       and upper(OPP_REFERENCE) = upper(lReference);

    return 0;
  exception
    when no_data_found then
      return 1;
  end isRefUnique;
end PPS_LIB_OPERATION_PROCEDURE;
