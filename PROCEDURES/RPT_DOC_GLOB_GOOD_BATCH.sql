--------------------------------------------------------
--  DDL for Procedure RPT_DOC_GLOB_GOOD_BATCH
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_GLOB_GOOD_BATCH" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, parameter_0    in     varchar2
, parameter_1    in     varchar2
, parameter_6    in     varchar2
, parameter_7    in     varchar2
, parameter_9    in     varchar2
, parameter_14   in     varchar2
, parameter_15   in     varchar2
, procuser_lanid in     pcs.pc_lang.lanid%type
)
is
/**
*Description
        Used for report DOC_GLOB_ECHEANCIER_GOOD_BATCH

*@created
*@lastUpdate  sma 30.10.2013
*@public
*/
  vpc_lang_id             pcs.pc_lang.pc_lang_id%type;
  nDocDelayWeekstart      number;
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  -- Premier jour de la semaine
  nDocDelayWeekstart := to_number(nvl(PCS.PC_CONFIG.GetConfig('DOC_DELAY_WEEKSTART'), '2') );

  open arefcursor for
    select nDocDelayWeekstart DOC_DELAY_WEEKSTART_CONFIG
         , DDO.C_DOCUMENT_STATUS
         , DGA.C_GAUGE_TITLE
         , DPO.C_GAUGE_TYPE_POS
         , DPO.GCO_GOOD_ID P_GCO_GOOD_ID
         , DPD.PDE_FINAL_DELAY
         , DPD.PDE_BALANCE_QUANTITY
         , GGO.GCO_GOOD_ID G_GCO_GOOD_ID
         , GGO.DIC_GOOD_LINE_ID
         , GGO.DIC_GOOD_FAMILY_ID
         , GGO.DIC_GOOD_MODEL_ID
         , GGO.DIC_GOOD_GROUP_ID
         , GCO_FUNCTIONS.GetDescription2(GGO.GCO_GOOD_ID, vpc_lang_id, 1, '01') DES_SHORT_DESCRIPTION
         , nvl( (select DIT_DESCR
                   from DICO_DESCRIPTION DIT
                  where DIT.DIT_TABLE = 'DIC_GOOD_LINE'
                    and DIT_CODE = GGO.DIC_GOOD_LINE_ID
                    and DIT.PC_LANG_Id = 3)
             , PCS.PC_FUNCTIONS.translateword2('Pas de ligne produit', vpc_lang_id)
              ) DIC_GOOD_LINE_DESCR
         ,
           --used to differentiate between lines which are null or not in crystal
           nvl( (select DIT_DESCR
                   from DICO_DESCRIPTION DIT
                  where DIT.DIT_TABLE = 'DIC_GOOD_FAMILY'
                    and DIT_CODE = GGO.DIC_GOOD_FAMILY_ID
                    and DIT.PC_LANG_ID = 3)
             , PCS.PC_FUNCTIONS.translateword2('Pas de famille produit', vpc_lang_id)
              ) DIC_GOOD_FAMILY_DESCR
         ,
           --used to differentiate between families which are null or not in crystal
           nvl( (select DIT_DESCR
                   from DICO_DESCRIPTION DIT
                  where DIT.DIT_TABLE = 'DIC_GOOD_MODEL'
                    and DIT_CODE = GGO.DIC_GOOD_MODEL_ID
                    and DIT.PC_LANG_Id = 3)
             , PCS.PC_FUNCTIONS.translateword2('Pas de modèle produit', vpc_lang_id)
              ) DIC_GOOD_MODEL_DESCR
         ,
           --used to differentiate between models which are null or not in crystal
           nvl( (select DIT_DESCR
                   from DICO_DESCRIPTION DIT
                  where DIT.DIT_TABLE = 'DIC_GOOD_GROUP'
                    and DIT_CODE = GGO.DIC_GOOD_GROUP_ID
                    and DIT.PC_LANG_ID = 3)
             , PCS.PC_FUNCTIONS.translateword2('Pas de group produit', vpc_lang_id)
              ) DIC_GOOD_GROUP_DESCR
         , GGO.GOO_MAJOR_REFERENCE
         , GGO.GOO_SECONDARY_REFERENCE
         , GGO.GOO_NUMBER_OF_DECIMAL
         , PPE.PER_NAME
         , PPE.PER_KEY1
         , PTH.PAC_THIRD_ID
         , GCO_FUNCTIONS.getcostpricewithmanagementmode(GGO.GCO_GOOD_ID) COSTPRICE
      from DOC_DOCUMENT DDO
         , DOC_POSITION DPO
         , DOC_GAUGE_STRUCTURED DGA
         , ACS_FINANCIAL_CURRENCY AFI
         , PAC_THIRD PTH
         , DOC_POSITION_DETAIL DPD
         , GCO_GOOD GGO
         , PCS.PC_CURR PCU
         , PAC_PERSON PPE
         , FAL_NETWORK_NEED FNE
         , V_STM_GCO_GOOD_QTY V_STM
     where DDO.DOC_DOCUMENT_ID = DPO.DOC_DOCUMENT_ID
       and DPO.DOC_POSITION_ID = DPD.DOC_POSITION_ID
       and DPD.DOC_POSITION_DETAIL_ID = FNE.DOC_POSITION_DETAIL_ID(+)
       and DPO.GCO_GOOD_ID = GGO.GCO_GOOD_ID
       and GGO.GCO_GOOD_ID = V_STM.GCO_GOOD_ID(+)
       and DDO.DOC_GAUGE_ID = DGA.DOC_GAUGE_ID
       and DDO.ACS_FINANCIAL_CURRENCY_ID = AFI.ACS_FINANCIAL_CURRENCY_ID
       and AFI.PC_CURR_ID = PCU.PC_CURR_ID
       and DDO.PAC_THIRD_ID = PTH.PAC_THIRD_ID
       and PTH.PAC_THIRD_ID = PPE.PAC_PERSON_ID
       and DDO.dmt_date_document >= decode(parameter_14, '0', to_date('19800101', 'YYYYMMDD'), to_date(parameter_14, 'YYYYMMDD') )
       and DDO.dmt_date_document <= decode(parameter_15, '0', to_date('30001231', 'YYYYMMDD'), to_date(parameter_15, 'YYYYMMDD') )
       and (   DGA.C_GAUGE_TITLE = decode(parameter_9, '0', '6', '1', '6', '30')
            or DGA.C_GAUGE_TITLE = decode(parameter_9, '0', '30', '2', '30', '6')
            or DGA.C_GAUGE_TITLE = decode(parameter_7, '0', '1', '1', '1', '5')
            or DGA.C_GAUGE_TITLE = decode(parameter_7, '0', '5', '2', '5', '1')
           )
       and (   DGA.C_GAUGE_TITLE = '30'
            or DPD.PDE_FINAL_DELAY <= decode(parameter_6, '0', to_date('30001231', 'YYYYMMDD'), to_date(parameter_6, 'YYYYMMDD') ) )
       and DDO.C_DOCUMENT_STATUS in('01', '02', '03')
       and DPO.C_GAUGE_TYPE_POS in('1', '7', '8', '91', '10')
       and GGO.GOO_MAJOR_REFERENCE >= parameter_0
       and GGO.GOO_MAJOR_REFERENCE <= parameter_1;
end RPT_DOC_GLOB_GOOD_BATCH;
