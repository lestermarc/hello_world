--------------------------------------------------------
--  DDL for Procedure RPT_FAL_LOT_LINK
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_LOT_LINK" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   user_lanid    IN       pcs.pc_lang.lanid%TYPE,
   PARAMETER_0   IN   DOC_DOCUMENT.DMT_NUMBER%TYPE,
   PARAMETER_1   IN   DOC_DOCUMENT.DMT_NUMBER%TYPE,
   PARAMETER_2   IN   PAC_PERSON.PER_NAME%TYPE,
   PARAMETER_3   IN   PAC_PERSON.PER_NAME%TYPE
)
IS
/**
*Description Used for report FAL_LOT_LINK,FAL_LOT_LINK_BATCH. This one is used only since SP6

*@created CLIU 20 APR 2010
*@lastUpdate  19.MAY.2010
*@Published VHA 20 Sept 2011
*@public
*@param USER_LANID  : user language
* PARAMETER_0 PARAMETER_1 DMT_NUMBER
* PARAMETER_2 PARAMETER_3 PER_NAME
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (user_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
        SELECT DOC.DMT_NUMBER, PER.PER_NAME, PER.PER_KEY1,
        DET.DOC_POSITION_DETAIL_ID, GCO.GOO_MAJOR_REFERENCE REF_ART,
        GCO.GCO_GOOD_ID ART_ID, GCO.GOO_NUMBER_OF_DECIMAL DIG, DET.PDE_FINAL_DELAY DELAI,
        DET.PDE_FINAL_QUANTITY QTE, DET.PDE_BALANCE_QUANTITY SOLDE,
        CAS_1.DESCRIPTION DEC1,
        CAS_1.GOO_MAJOR_REFERENCE REF_ART_1,
        CAS_1.GCO_GOOD_ID ART_ID_1,
        CAS_1.GOO_NUMBER_OF_DECIMAL DIG_1,
        CAS_1.TOTAL_QTY QTE_1,
        CAS_1.END_DELAY DELAY_1,
        CAS_1.FLN_QTY QTN_1,
        CAS_1.STM_STOCK_POSITION_ID STK_1,
        CAS_2.DESCRIPTION DEC2,
        CAS_2.GOO_MAJOR_REFERENCE REF_ART_2,
        CAS_2.GCO_GOOD_ID ART_ID_2,
        CAS_2.GOO_NUMBER_OF_DECIMAL DIG_2,
        CAS_2.TOTAL_QTY QTE_2,
        CAS_2.END_DELAY DELAY_2,
        CAS_2.FLN_QTY QTN_2,
        CAS_2.STM_STOCK_POSITION_ID STK_2,
        CAS_3.DESCRIPTION DEC3,
        CAS_3.GOO_MAJOR_REFERENCE REF_ART_3,
        CAS_3.GCO_GOOD_ID ART_ID_3,
        CAS_3.GOO_NUMBER_OF_DECIMAL DIG_3,
        CAS_3.TOTAL_QTY QTE_3,
        CAS_3.END_DELAY DELAY_3,
        CAS_3.FLN_QTY QTN_3,
        CAS_3.STM_STOCK_POSITION_ID STK_3,
        CAS_4.DESCRIPTION DEC4,
        CAS_4.GOO_MAJOR_REFERENCE REF_ART_4,
        CAS_4.GCO_GOOD_ID ART_ID_4,
        CAS_4.GOO_NUMBER_OF_DECIMAL DIG_4,
        CAS_4.TOTAL_QTY QTE_4,
        CAS_4.END_DELAY DELAY_4,
        CAS_4.FLN_QTY QTN_4,
        CAS_4.STM_STOCK_POSITION_ID STK_4,
        CAS_5.DESCRIPTION DEC5,
        CAS_5.GOO_MAJOR_REFERENCE REF_ART_5,
        CAS_5.GCO_GOOD_ID ART_ID_5,
        CAS_5.GOO_NUMBER_OF_DECIMAL DIG_5,
        CAS_5.TOTAL_QTY QTE_5,
        CAS_5.END_DELAY DELAY_5,
        CAS_5.FLN_QTY QTN_5,
        CAS_5.STM_STOCK_POSITION_ID STK_5,
        CAS_6.DESCRIPTION DEC6,
        CAS_6.GOO_MAJOR_REFERENCE REF_ART_6,
        CAS_6.GCO_GOOD_ID ART_ID_6,
        CAS_6.GOO_NUMBER_OF_DECIMAL DIG_6,
        CAS_6.TOTAL_QTY QTE_6,
        CAS_6.END_DELAY DELAY_6,
        CAS_6.FLN_QTY QTN_6,
        CAS_6.STM_STOCK_POSITION_ID STK_6
        FROM DOC_DOCUMENT DOC,
        DOC_POSITION POS,
        DOC_POSITION_DETAIL DET,
        PAC_THIRD THI,
        PAC_PERSON PER,
        DOC_GAUGE_STRUCTURED GST,
        GCO_GOOD GCO,
        FAL_NETWORK_NEED NEED,
        V_FAL_CASCADE CAS_1,
        V_FAL_CASCADE CAS_2,
        V_FAL_CASCADE CAS_3,
        V_FAL_CASCADE CAS_4,
        V_FAL_CASCADE CAS_5,
        V_FAL_CASCADE CAS_6
        WHERE DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
        AND POS.DOC_POSITION_ID = DET.DOC_POSITION_ID
        AND POS.GCO_GOOD_ID = GCO.GCO_GOOD_ID
        AND DOC.DOC_GAUGE_ID = GST.DOC_GAUGE_ID
        AND DET.DOC_POSITION_DETAIL_ID = NEED.DOC_POSITION_DETAIL_ID(+)
        AND DOC.PAC_THIRD_ID = THI.PAC_THIRD_ID
        AND THI.PAC_THIRD_ID = PER.PAC_PERSON_ID
        AND NEED.FAL_NETWORK_NEED_ID = CAS_1.NEED_ID_IN(+)
        AND CAS_1.NEED_ID_OUT = CAS_2.NEED_ID_IN(+)
        AND CAS_2.NEED_ID_OUT = CAS_3.NEED_ID_IN(+)
        AND CAS_3.NEED_ID_OUT = CAS_4.NEED_ID_IN(+)
        AND CAS_4.NEED_ID_OUT = CAS_5.NEED_ID_IN(+)
        AND CAS_5.NEED_ID_OUT = CAS_6.NEED_ID_IN(+)
        AND GST.C_GAUGE_TITLE = '6'
        AND (DOC.C_DOCUMENT_STATUS = '03' OR DOC.C_DOCUMENT_STATUS = '02')
        AND (   POS.C_GAUGE_TYPE_POS = '10'
        OR POS.C_GAUGE_TYPE_POS = '91'
        OR POS.C_GAUGE_TYPE_POS = '8'
        OR POS.C_GAUGE_TYPE_POS = '7'
        OR POS.C_GAUGE_TYPE_POS = '1'
        )
        AND (NVL(PARAMETER_0,'%') = '%' OR DOC.DMT_NUMBER >= PARAMETER_0)
        AND (NVL(PARAMETER_1,'%') = '%' OR DOC.DMT_NUMBER<= PARAMETER_1)
        AND (NVL(PARAMETER_2,'%') = '%' OR PER.PER_NAME >= PARAMETER_2)
        AND (NVL(PARAMETER_3,'%') = '%' OR PER.PER_NAME <= PARAMETER_3);

END RPT_FAL_LOT_LINK;