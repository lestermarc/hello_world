--------------------------------------------------------
--  DDL for Package Body PPS_PRC_OPERATION_PROCEDURE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PPS_PRC_OPERATION_PROCEDURE" 
is
  /**
  * Description
  *    Duplique la procédure opératoire dont l'ID est transmis en paramètre et retourne
  *    l'ID de la nouvelle procédure opératoire.
  */
  function duplicateOperProc(iOperationProcedureID in PPS_OPERATION_PROCEDURE.PPS_OPERATION_PROCEDURE_ID%type)
    return PPS_OPERATION_PROCEDURE.PPS_OPERATION_PROCEDURE_ID%type
  as
    ltCRUD_Def           FWK_I_TYP_DEFINITION.t_crud_def;
    lnNewOperationProcID PPS_OPERATION_PROCEDURE.PPS_OPERATION_PROCEDURE_ID%type;
    lNewOppReference     PPS_OPERATION_PROCEDURE.OPP_REFERENCE%type;
  begin
    lnNewOperationProcID  := getNewId;
    FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_PPS_ENTITY.gcPpsOperationProcedure, iot_crud_definition => ltCRUD_Def);
    /* Copie de l'opération standard */
    FWK_I_MGT_ENTITY.prepareDuplicate(iot_crud_definition => ltCRUD_Def, ib_initialize => true, in_main_id => iOperationProcedureID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Def, 'PPS_OPERATION_PROCEDURE_ID', lnNewOperationProcID);
    lNewOppReference      := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCRUD_Def, 'OPP_REFERENCE');
    lNewOppReference      :=
              FWK_I_LIB_ENTITY.getDuplicateValPk2(iv_entity_name   => 'PPS_OPERATION_PROCEDURE', iv_column_name => 'OPP_REFERENCE'
                                                , iv_value         => lNewOppReference);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Def, 'OPP_REFERENCE', lNewOppReference);
    /* Insertion de la nouvelle opération standard */
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_Def);
    FWK_I_MGT_ENTITY.Release(ltCRUD_Def);
    return lnNewOperationProcID;
  end duplicateOperProc;

  /**
  * Description
  *    Duplique la procédure opératoire dont l'ID est transmis en paramètre et retourne
  *    l'ID de la nouvelle procédure opératoire.
  */
  procedure duplicateOperProc(
    iOldOperationProcedureID in     PPS_OPERATION_PROCEDURE.PPS_OPERATION_PROCEDURE_ID%type
  , oNewOperationProcedureID out    PPS_OPERATION_PROCEDURE.PPS_OPERATION_PROCEDURE_ID%type
  )
  as
  begin
    oNewOperationProcedureID  := duplicateOperProc(iOperationProcedureID => iOldOperationProcedureID);
  end duplicateOperProc;
end PPS_PRC_OPERATION_PROCEDURE;
