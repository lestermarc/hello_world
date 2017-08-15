--------------------------------------------------------
--  DDL for Procedure RPT_FAL_LOT_MP_BALANCE_SHEET
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_LOT_MP_BALANCE_SHEET" (
  arefcursor       in out crystal_cursor_types.dualcursortyp
, parameter_0      in     varchar2
, procuser_lanid   in     pcs.pc_lang.lanid%type
, proccompany_name in     pcs.pc_comp.com_name%type
)
is
/**
*Description
        Used for report FAL_LOT_MATERIAL_EXIT_SCP

*@created VHA 26 JUNE 2013
*@lastUpdate
*@public
*@param parameter_0    FAL_LOT_ID
*@param PROCUSER_LANID : user language
*/
  vpc_lang_id     pcs.pc_lang.pc_lang_id%type := null;
  vcom_logo_large pcs.pc_comp.com_logo_large%type := null;
  vcom_descr      pcs.pc_comp.com_descr%type := null;
  vcom_adr        varchar2(4000);
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  if (proccompany_name is not null) then
      select com.com_logo_large
           , com.com_descr
           , com.com_adr || chr(13) || com.com_zip || ' - ' || com.com_city
        into vcom_logo_large
           , vcom_descr
           , vcom_adr
        from pcs.pc_comp com
       where com.com_name = proccompany_name;
  end if;

  open arefcursor for
    select '1' INFO
         , LOT.FAL_LOT_ID
         , LOT.LOT_REF
         , LOT.LOT_REFCOMPL
         , vcom_logo_large COM_LOGO_LARGE
         , vcom_descr COM_DESCR
         , vcom_adr COM_ADR
         , (select count(*)
              from FAL_LOT LOT
                 , DOC_DOCUMENT DOC
                 , DOC_GAUGE_STRUCTURED GAS
             where DOC.DOC_RECORD_ID = LOT.DOC_RECORD_ID
               and GAS.DOC_GAUGE_ID = DOC.DOC_GAUGE_ID
               and instr(',' || parameter_0 || ',', ',' || LOT.FAL_LOT_ID || ',') > 0
               and GAS.C_GAUGE_TITLE = '6') LOT_DOC_NB
         , DOC.DOC_DOCUMENT_ID
         , PER.PER_NAME
         , DOC.DMT_NUMBER
         , DOC.DMT_DATE_DOCUMENT
         , GOO.GOO_MAJOR_REFERENCE
         , GOO.GOO_SECONDARY_REFERENCE
         , LOT.LOT_PLAN_NUMBER
         , GAL.GCO_ALLOY_ID
         , nvl(GAL.GAL_ALLOY_DESCR, GAL.GAL_ALLOY_REF) GAL_ALLOY_REF
         , GAC.DIC_BASIS_MATERIAL_ID
         , (select DIC_BASIS_MATERIAL_WORDING
              from DIC_BASIS_MATERIAL DIC
             where DIC.DIC_BASIS_MATERIAL_ID = GAC.DIC_BASIS_MATERIAL_ID) BASIS_MAT_DESC
         , GAC.GAC_RATE
         , nvl(DFA.DFA_RATE_DATE, DOC.DMT_DATE_DOCUMENT) VALUE_DATE
         , nvl(DFA.DFA_RATE, DFA.DFA_RATE_TH) RATE
         , PCS.PC_FUNCTIONS.GetDescodeDescr('C_THIRD_MATERIAL_RELATION_TYPE', DOC.C_THIRD_MATERIAL_RELATION_TYPE, vpc_lang_id) THIRD_MAT_REL_TYPE_DESC
         , null FAL_WEIGH_ID
         , null FWE_DATE
         , null FWE_WEIGHT_MAT
         , null WEIGH_TYPE_DESCR
         , null WEIGHING_TYPE
      from FAL_LOT LOT
         , DOC_DOCUMENT DOC
         , DOC_FOOT_ALLOY DFA
         , GCO_GOOD GOO
         , PAC_PERSON PER
         , FAL_WEIGH FWE
         , GCO_ALLOY GAL
         , GCO_ALLOY_COMPONENT GAC
     where DOC.DOC_RECORD_ID(+) = LOT.DOC_RECORD_ID
       and GOO.GCO_GOOD_ID = LOT.GCO_GOOD_ID
       and PER.PAC_PERSON_ID(+) = DOC.PAC_THIRD_ID
       and DFA.DOC_FOOT_ID(+) = DOC.DOC_DOCUMENT_ID
       and FWE.FAL_LOT_ID(+) = LOT.FAL_LOT_ID
       and GAL.GCO_ALLOY_ID(+) = FWE.GCO_ALLOY_ID
       and GAC.GCO_ALLOY_ID(+) = GAL.GCO_ALLOY_ID
       and instr(',' || parameter_0 || ',', ',' || LOT.FAL_LOT_ID || ',') > 0
    union all
    select '2' INFO
         , LOT.FAL_LOT_ID
         , LOT.LOT_REF
         , LOT.LOT_REFCOMPL
         , vcom_logo_large COM_LOGO_LARGE
         , vcom_descr COM_DESCR
         , vcom_adr COM_ADR
         , (select count(*)
              from FAL_LOT LOT
                 , DOC_DOCUMENT DOC
                 , DOC_GAUGE_STRUCTURED GAS
             where DOC.DOC_RECORD_ID = LOT.DOC_RECORD_ID
               and GAS.DOC_GAUGE_ID = DOC.DOC_GAUGE_ID
               and instr(',' || parameter_0 || ',', ',' || LOT.FAL_LOT_ID || ',') > 0
               and GAS.C_GAUGE_TITLE = '6') LOT_DOC_NB
         , DOC.DOC_DOCUMENT_ID
         , PER.PER_NAME
         , DOC.DMT_NUMBER
         , DOC.DMT_DATE_DOCUMENT
         , GOO.GOO_MAJOR_REFERENCE
         , GOO.GOO_SECONDARY_REFERENCE
         , LOT.LOT_PLAN_NUMBER
         , WGH.GCO_ALLOY_ID
         , WGH.GAL_ALLOY_REF
         , null DIC_BASIS_MATERIAL_ID
         , null BASIS_MAT_DESC
         , null GAC_RATE
         , null VALUE_DATE
         , null RATE
         , null THIRD_MAT_REL_TYPE_DESC
         , WGH.FAL_WEIGH_ID
         , WGH.FWE_DATE
         , WGH.FWE_WEIGHT_MAT
         , WGH.WEIGH_TYPE_DESCR
         , WGH.WEIGHING_TYPE
      from (select   FWE.FAL_LOT_ID
                   , FWE.FAL_WEIGH_ID
                   , FWE.FWE_DATE
                   , FWE.FWE_WEIGHT_MAT
                   , PCS.PC_FUNCTIONS.GetDescodeDescr('C_WEIGH_TYPE', FWE.C_WEIGH_TYPE, vpc_lang_id) WEIGH_TYPE_DESCR
                   , GAL.GCO_ALLOY_ID
                   , GAL.GAL_ALLOY_REF
                   , 'SORTIE (en atelier)' WEIGHING_TYPE
                from fal_weigh fwe
                   , gco_alloy gal
               where fwe.gco_alloy_id = gal.gco_alloy_id
                 and FWE_TURNINGS = 0
                 and FWE_IN = 1
                 and (    (C_WEIGH_TYPE in('1', '6', '10') )
                      or (    C_WEIGH_TYPE = '8'
                          and (   FAL_POSITION1_ID =
                                     FAL_LIB_POSITION.getPositionIDByStockID(inStmStockID   => FAL_TOOLS.GetConfig_StockID(ConfigWord   => 'PPS_DefltSTOCK_FLOOR') )
                               or FAL_POSITION1_ID in(
                                    select FPO.FAL_POSITION_ID
                                      from FAL_LOT_MATERIAL_LINK FLM
                                         , FAL_TASK_LINK TAL
                                         , FAL_POSITION FPO
                                     where FLM.FAL_LOT_MATERIAL_LINK_ID = FWE.FAL_LOT_MATERIAL_LINK_ID
                                       and FLM.FAL_LOT_ID = TAL.FAL_LOT_ID
                                       and TAL.FAL_FACTORY_FLOOR_ID = FPO.FAL_FACTORY_FLOOR_ID)
                              )
                         )
                     )
            union
            select   FWE.FAL_LOT_ID
                   , FWE.FAL_WEIGH_ID
                   , FWE.FWE_DATE
                   , FWE.FWE_WEIGHT_MAT
                   , PCS.PC_FUNCTIONS.GetDescodeDescr('C_WEIGH_TYPE', FWE.C_WEIGH_TYPE, vpc_lang_id) WEIGH_TYPE_DESCR
                   , GAL.GCO_ALLOY_ID
                   , GAL.GAL_ALLOY_REF
                   , 'ENTREE (sortie d’atelier)' WEIGHING_TYPE
                from fal_weigh fwe
                   , gco_alloy gal
               where fwe.gco_alloy_id = gal.gco_alloy_id
                 and FWE_IN = 0
                 and (    (C_WEIGH_TYPE = '7')
                      or (C_WEIGH_TYPE = '9')
                      or (C_WEIGH_TYPE = '11')
                      or (    C_WEIGH_TYPE = '8'
                          and FAL_POSITION2_ID =
                                     FAL_LIB_POSITION.getPositionIDByStockID(inStmStockID   => FAL_TOOLS.GetConfig_StockID(ConfigWord   => 'PPS_DefltSTOCK_FLOOR') )
                         )
                     )
            union
            select   FWE.FAL_LOT_ID
                   , FWE.FAL_WEIGH_ID
                   , FWE.FWE_DATE
                   , FWE.FWE_WEIGHT_MAT
                   , PCS.PC_FUNCTIONS.GetDescodeDescr('C_WEIGH_TYPE', FWE.C_WEIGH_TYPE, vpc_lang_id) WEIGH_TYPE_DESCR
                   , GAL.GCO_ALLOY_ID
                   , GAL.GAL_ALLOY_REF
                   , 'SORTIE (réception)' WEIGHING_TYPE
                from fal_weigh fwe
                   , gco_alloy gal
               where fwe.gco_alloy_id = gal.gco_alloy_id
                 and FWE_IN = 1
                 and C_WEIGH_TYPE = '4'
            union
            select   LOT.FAL_LOT_ID
                   , FWE.FAL_WEIGH_ID
                   , FWE.FWE_DATE
                   , FWE.FWE_WEIGHT_MAT
                   , PCS.PC_FUNCTIONS.GetDescodeDescr('C_WEIGH_TYPE', FWE.C_WEIGH_TYPE, vpc_lang_id) WEIGH_TYPE_DESCR
                   , GAL.GCO_ALLOY_ID
                   , GAL.GAL_ALLOY_REF
                   , 'Livraison' WEIGHING_TYPE
                from fal_weigh fwe
                   , gco_alloy gal
                   , doc_document doc
                   , fal_lot lot
               where fwe.doc_document_id = doc.doc_document_id
                 and fwe.gco_alloy_id = gal.gco_alloy_id
                 and LOT.DOC_RECORD_ID = DOC.DOC_RECORD_ID
                 and FWE_IN = 0
                 and C_WEIGH_TYPE = '3'
            order by 1) WGH
         , FAL_LOT LOT
         , DOC_DOCUMENT DOC
         , GCO_GOOD GOO
         , PAC_PERSON PER
     where LOT.FAL_LOT_ID = WGH.FAL_LOT_ID
       and DOC.DOC_RECORD_ID(+) = LOT.DOC_RECORD_ID
       and GOO.GCO_GOOD_ID = LOT.GCO_GOOD_ID
       and PER.PAC_PERSON_ID(+) = DOC.PAC_THIRD_ID
       and instr(',' || parameter_0 || ',', ',' || WGH.FAL_LOT_ID || ',') > 0;
end RPT_FAL_LOT_MP_BALANCE_SHEET;
