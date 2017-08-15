--------------------------------------------------------
--  DDL for Procedure RPT_DOC_STD_3_REMINDER_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_STD_3_REMINDER_SUB" (
  arefcursor in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, parameter_0 in varchar2
)
is
/**
*Description - Used for report DOC_STD_3

*@created MZHU 17 MAY 2009
*@lastUpdate VHA 14.05.2014
*@public
*@param PARAMETER_0 DMT_NUMBER
*/
begin
  open arefcursor for
    select distinct '1' GROUP_STRING
                  ,   --USED FOR DISPLAY OF HEADER IN SUBREPORT,
                    PERE.CDE
                  , LANG.LANID
                  , GAU.C_ADMIN_DOMAIN
                  , POS.C_DOC_POS_STATUS
                  , POS.DIC_UNIT_OF_MEASURE_ID
                  , decode(GAU.C_ADMIN_DOMAIN
                         , '1', GCO_FUNCTIONS.getcdadecimal(POS.GCO_GOOD_ID, 'PURCHASE', DMT.PAC_THIRD_ID)
                         , '2', GCO_FUNCTIONS.getcdadecimal(POS.GCO_GOOD_ID, 'SALE', DMT.PAC_THIRD_DELIVERY_ID)
                         , GCO_FUNCTIONS.getcdadecimal(POS.GCO_GOOD_ID, ' ', DMT.PAC_THIRD_ID)
                          ) GOO_NUMBER_OF_DECIMAL
                  , POS.POS_REFERENCE
                  , POS.POS_SHORT_DESCRIPTION
                  , POS.POS_LONG_DESCRIPTION
                  , POS.POS_FREE_DESCRIPTION
                  , POS.POS_BODY_TEXT
                  , PDE.PDE_FINAL_DELAY
                  , PDE.PDE_INTERMEDIATE_DELAY
                  , PDT.DIC_DEL_TYP_EXPLAIN_ID
                  , sum(PDE.PDE_BALANCE_QUANTITY) BALANCE_FATHER
                  , sum(PDE.PDE_FINAL_QUANTITY) FINAL_FATHER
                  , sum(DOC_FUNCTIONS.docsituationfinalqtyson(PDE.DOC_POSITION_DETAIL_ID) ) FINAL_SON
                  , DOC_FUNCTIONS.docsituationbalanceparent(PDE.DOC_POSITION_DETAIL_ID) PDE_BALANCE_QUANTITY_PARENT
                  , substr(GCO_FUNCTIONS.getcharacdescr(PDE.GCO_CHARACTERIZATION_ID, DMT.PC_LANG_ID), 1, 30) GCO1_CHARAC_DESCR
                  , substr(GCO_FUNCTIONS.getcharacdescr(PDE.GCO_GCO_CHARACTERIZATION_ID, DMT.PC_LANG_ID), 1, 30) GCO2_CHARAC_DESCR
                  , substr(GCO_FUNCTIONS.getcharacdescr(PDE.GCO2_GCO_CHARACTERIZATION_ID, DMT.PC_LANG_ID), 1, 30) GCO3_CHARAC_DESCR
                  , substr(GCO_FUNCTIONS.getcharacdescr(PDE.GCO3_GCO_CHARACTERIZATION_ID, DMT.PC_LANG_ID), 1, 30) GCO4_CHARAC_DESCR
                  , substr(GCO_FUNCTIONS.getcharacdescr(PDE.GCO4_GCO_CHARACTERIZATION_ID, DMT.PC_LANG_ID), 1, 30) GCO5_CHARAC_DESCR
                  , PDE.PDE_CHARACTERIZATION_VALUE_1
                  , PDE.PDE_CHARACTERIZATION_VALUE_2
                  , PDE.PDE_CHARACTERIZATION_VALUE_3
                  , PDE.PDE_CHARACTERIZATION_VALUE_4
                  , PDE.PDE_CHARACTERIZATION_VALUE_5
               from PCS.PC_LANG LANG
                  , DOC_GAUGE GAU
                  , DOC_GAUGE_STRUCTURED GST
                  , DOC_GAUGE_POSITION DGP
                  , GCO_GOOD GOO
                  , GCO_PRODUCT PDT
                  , DOC_POSITION_DETAIL PDE
                  , DOC_POSITION POS
                  , DOC_DOCUMENT DMT
                  , (select distinct FILS.DMT_NUMBER SON
                                   , PERE.DMT_NUMBER FATHER
                                   , decode(P_GAU.C_GAUGE_TITLE
                                          , '1', PERE.DMT_NUMBER
                                          , '6', PERE.DMT_NUMBER
                                          , decode(ARP_GAU.C_GAUGE_TITLE, '1', ARPE.DMT_NUMBER, '6', ARPE.DMT_NUMBER, null)
                                           ) CDE
                                from DOC_POSITION_DETAIL PDE_FILS
                                   , DOC_POSITION_DETAIL PDE_PERE
                                   , DOC_POSITION_DETAIL PDE_ARPE
                                   , DOC_GAUGE_STRUCTURED P_GAU
                                   , DOC_GAUGE_STRUCTURED ARP_GAU
                                   , DOC_DOCUMENT PERE
                                   , DOC_DOCUMENT ARPE
                                   , DOC_DOCUMENT FILS
                               where FILS.DOC_DOCUMENT_ID = PDE_FILS.DOC_DOCUMENT_ID
                                 and PDE_FILS.DOC_DOC_POSITION_DETAIL_ID = PDE_PERE.DOC_POSITION_DETAIL_ID
                                 and PDE_PERE.DOC_DOCUMENT_ID = PERE.DOC_DOCUMENT_ID
                                 and PERE.DOC_GAUGE_ID = P_GAU.DOC_GAUGE_ID
                                 and PDE_ARPE.DOC_POSITION_DETAIL_ID(+) = PDE_PERE.DOC_DOC_POSITION_DETAIL_ID
                                 and ARPE.DOC_DOCUMENT_ID(+) = PDE_ARPE.DOC_DOCUMENT_ID
                                 and ARP_GAU.DOC_GAUGE_ID(+) = ARPE.DOC_GAUGE_ID
                            group by FILS.DMT_NUMBER
                                   , PERE.DMT_NUMBER
                                   , decode(P_GAU.C_GAUGE_TITLE
                                          , '1', PERE.DMT_NUMBER
                                          , '6', PERE.DMT_NUMBER
                                          , decode(ARP_GAU.C_GAUGE_TITLE, '1', ARPE.DMT_NUMBER, '6', ARPE.DMT_NUMBER, null)
                                           ) ) PERE
              where PERE.CDE = DMT.DMT_NUMBER
                and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                and POS.DOC_GAUGE_POSITION_ID = DGP.DOC_GAUGE_POSITION_ID
                and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                and GAU.DOC_GAUGE_ID = GST.DOC_GAUGE_ID
                and DMT.PC_LANG_ID = LANG.PC_LANG_ID
                and POS.C_GAUGE_TYPE_POS in('1', '3', '7', '8', '9', '10')
                and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
                and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
                and PERE.SON = parameter_0
           group by PERE.FATHER
                  , PERE.SON
                  , PERE.CDE
                  , DMT.DMT_NUMBER
                  , DMT.DMT_DATE_DOCUMENT
                  , DMT.C_DOCUMENT_STATUS
                  , DMT.PC_LANG_ID
                  , LANG.LANID
                  , POS.POS_NUMBER
                  , POS.C_DOC_POS_STATUS
                  , POS.C_GAUGE_TYPE_POS
                  , GAU.C_GAUGE_TYPE
                  , GST.C_GAUGE_TITLE
                  , GAU.C_ADMIN_DOMAIN
                  , DGP.C_GAUGE_SHOW_DELAY
                  , DGP.GAP_POS_DELAY
                  , POS.DIC_UNIT_OF_MEASURE_ID
                  , GOO.GOO_MAJOR_REFERENCE
                  , GOO.GOO_SECONDARY_REFERENCE
                  , GOO.GOO_NUMBER_OF_DECIMAL
                  , DECODE(GAU.C_ADMIN_DOMAIN
                         , '1', GCO_FUNCTIONS.getcdadecimal(POS.GCO_GOOD_ID, 'PURCHASE', DMT.PAC_THIRD_ID)
                         , '2', GCO_FUNCTIONS.getcdadecimal(POS.GCO_GOOD_ID, 'SALE', DMT.PAC_THIRD_DELIVERY_ID)
                         , GCO_FUNCTIONS.getcdadecimal(POS.GCO_GOOD_ID, ' ', DMT.PAC_THIRD_ID)
                          )
                  , GOO.DIC_GOOD_LINE_ID
                  , GOO.DIC_GOOD_FAMILY_ID
                  , GOO.DIC_GOOD_MODEL_ID
                  , GOO.DIC_GOOD_GROUP_ID
                  , POS.POS_REFERENCE
                  , POS.POS_SHORT_DESCRIPTION
                  , POS.POS_LONG_DESCRIPTION
                  , POS.POS_FREE_DESCRIPTION
                  , POS.POS_BODY_TEXT
                  , POS.POS_BALANCE_QUANTITY
                  , POS.POS_FINAL_QUANTITY
                  , PDE.PDE_FINAL_DELAY
                  , PDE.PDE_INTERMEDIATE_DELAY
                  , PDE.PDE_BASIS_DELAY
                  , PDT.C_PRODUCT_DELIVERY_TYP
                  , PDT.DIC_DEL_TYP_EXPLAIN_ID
                  , DOC_FUNCTIONS.docsituationfinalqtyson(PDE.DOC_POSITION_DETAIL_ID)
                  , DOC_FUNCTIONS.docsituationbalanceparent(PDE.DOC_POSITION_DETAIL_ID)
                  , PDE.GCO_CHARACTERIZATION_ID
                  , PDE.GCO_GCO_CHARACTERIZATION_ID
                  , PDE.GCO2_GCO_CHARACTERIZATION_ID
                  , PDE.GCO3_GCO_CHARACTERIZATION_ID
                  , PDE.GCO4_GCO_CHARACTERIZATION_ID
                  , substr(GCO_FUNCTIONS.getcharacdescr(PDE.GCO_CHARACTERIZATION_ID, DMT.PC_LANG_ID), 1, 30)
                  , substr(GCO_FUNCTIONS.getcharacdescr(PDE.GCO_GCO_CHARACTERIZATION_ID, DMT.PC_LANG_ID), 1, 30)
                  , substr(GCO_FUNCTIONS.getcharacdescr(PDE.GCO2_GCO_CHARACTERIZATION_ID, DMT.PC_LANG_ID), 1, 30)
                  , substr(GCO_FUNCTIONS.getcharacdescr(PDE.GCO3_GCO_CHARACTERIZATION_ID, DMT.PC_LANG_ID), 1, 30)
                  , substr(GCO_FUNCTIONS.getcharacdescr(PDE.GCO4_GCO_CHARACTERIZATION_ID, DMT.PC_LANG_ID), 1, 30)
                  , PDE.PDE_CHARACTERIZATION_VALUE_1
                  , PDE.PDE_CHARACTERIZATION_VALUE_2
                  , PDE.PDE_CHARACTERIZATION_VALUE_3
                  , PDE.PDE_CHARACTERIZATION_VALUE_4
                  , PDE.PDE_CHARACTERIZATION_VALUE_5;
end RPT_DOC_STD_3_REMINDER_SUB;
