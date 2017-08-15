--------------------------------------------------------
--  DDL for Package Body FAL_LIB_TASK_LINK_PROP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_TASK_LINK_PROP" 
is
  /**
  * Description
  *    Cette function retourne la clef primaire de la proposition de lot de l'opération
  *    dont la clef primaire est transmise en paramètre.
  */
  function getLotPropID(inFalTaskLinkPropID in FAL_TASK_LINK_PROP.FAL_TASK_LINK_PROP_ID%type)
    return FAL_LOT_PROP.FAL_LOT_PROP_ID%type
  as
  begin
    return FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name   => 'FAL_TASK_LINK_PROP'
                                               , iv_column_name   => 'FAL_LOT_PROP_ID'
                                               , it_pk_value      => inFalTaskLinkPropID
                                                );
  end getLotPropID;

  /**
  * Description
  *    Cette function retourne La date de fin planifiée de l'opération de la
  *    proposition de lot transmise en paramètre.
  */
  function getEndDate(iTaskLinkPropID in FAL_TASK_LINK_PROP.FAL_TASK_LINK_PROP_ID%type)
    return FAL_TASK_LINK_PROP.TAL_END_PLAN_DATE%type
  as
  begin
    return FWK_I_LIB_ENTITY.getDateFieldFromPk(iv_entity_name => 'FAL_TASK_LINK_PROP', iv_column_name => 'TAL_END_PLAN_DATE', it_pk_value => iTaskLinkPropID);
  end getEndDate;

  /**
  * Description
  *    Portefeuille : Retourne 1 si au moins une opération a été sélectionné pour un fournisseur
  */
  function TaskIsSelectionned(iPacSuplierPartnerID in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type)
    return number
  as
    lnTaskSelectionned number;
  begin
    select sign(nvl(max(FTL.FAL_TASK_LINK_PROP_ID), 0) )
      into lnTaskSelectionned
      from FAL_TASK_LINK_PROP FTL
     where FTL.PAC_SUPPLIER_PARTNER_ID = iPacSuplierPartnerID
       and FTL.TAL_SUBCONTRACT_SELECT = 1;

    return lnTaskSelectionned;
  end TaskIsSelectionned;

  /**
  * Description
  *    Portefeuille : Retourne 1 si au moins une opération avec PCST a été sélectionné
  */
  function TaskWithPcstIsSelectionned
    return number
  as
    lnTaskSelectionned number;
  begin
    select sign(nvl(max(FTL.FAL_TASK_LINK_PROP_ID), 0) )
      into lnTaskSelectionned
      from FAL_TASK_LINK_PROP FTL
         , COM_LIST_ID_TEMP LID
     where LID.COM_LIST_ID_TEMP_ID = FTL.FAL_TASK_LINK_PROP_ID
       and LID.LID_CODE = 'PCST_PROP'
       and FTL.TAL_PCST_NUMBER is not null
       and LID.LID_SELECTION = 1;

    return lnTaskSelectionned;
  end TaskWithPcstIsSelectionned;
end FAL_LIB_TASK_LINK_PROP;
