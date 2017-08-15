--------------------------------------------------------
--  DDL for Package Body GCO_LIB_CDA_MANUFACTURE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_LIB_CDA_MANUFACTURE" 
is
  /*
  * function isProductAskWeigh
  * Description
  *   Retourne 1 si une pesée des matières précieuses est demandée pour ce produit,
  *   il est possible de spécifier si la pesée est obligatoire
  */
  function isProductAskWeigh(iGoodId GCO_GOOD.GCO_GOOD_ID%type
  , iMandatory number default 0
  , iDicFabConditionId varchar2 default null)
    return number
  is
    lnWeigh GCO_COMPL_DATA_MANUFACTURE.CMA_WEIGH%type;
  begin
    if PCS.PC_CONFIG.GetConfig('FAL_WEIGH_RECEPT') = '1' then
      if iMandatory = 1 then
        lnWeigh  := 0;
      else
        lnWeigh  := 1;
      end if;
    else
      select nvl(max(CMA.CMA_WEIGH), 0)
        into lnWeigh
        from GCO_COMPL_DATA_MANUFACTURE CMA
       where CMA.GCO_GOOD_ID = iGoodId
         and ((iDicFabConditionId is null and CMA.CMA_DEFAULT = 1)
               or CMA.DIC_FAB_CONDITION_ID = iDicFabConditionId)
         and GCO_LIB_PRECIOUS_MAT.hasPreciousMatWithWeight(CMA.GCO_GOOD_ID) = 1
         and (   iMandatory = 0
              or CMA_WEIGH_MANDATORY = iMandatory);
    end if;

    return lnWeigh;
  end isProductAskWeigh;
end GCO_LIB_CDA_MANUFACTURE;
