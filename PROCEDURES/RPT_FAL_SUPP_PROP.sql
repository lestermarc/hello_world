--------------------------------------------------------
--  DDL for Procedure RPT_FAL_SUPP_PROP
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_SUPP_PROP" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   user_lanid    IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
*Description Used for report FAL_SUPP_PROP, FAL_SUPP_PROP_BATCH This one is used only since SP6

*@created CLIU 20 Mar 2010
*@lastUpdate
*@Published VHA 20 Sept 2011
*@public
*@param USER_LANID  : user language
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
   vno_accountable_group   VARCHAR2 (4000 CHAR);
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (user_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;
   vno_accountable_group :=
      pcs.pc_functions.translateword2 ('Pas de groupe responsable',
                                       vpc_lang_id
                                      );

   OPEN arefcursor FOR
        SELECT GD.C_DESCRIPTION_TYPE, nvl(goo.dic_accountable_group_id,vno_ACCOUNTABLE_GROUP) DIC_ACCOUNTABLE_GROUP_ID,
        PER.PER_KEY1, GOO.GOO_MAJOR_REFERENCE,
        FDP.FDP_FINAL_QTY, PER.PER_NAME,
        PER.PER_FORENAME, PER.PER_ACTIVITY,
        GD.DES_SHORT_DESCRIPTION, GD.DES_LONG_DESCRIPTION,
        GD.DES_FREE_DESCRIPTION, FNS.FAN_BEG_PLAN,
        FNS.FAN_END_PLAN, FDP.GCO_GOOD_ID, FDP.PAC_SUPPLIER_PARTNER_ID,
        CDA.DIC_UNIT_OF_MEASURE_ID, FNN.FAN_BALANCE_QTY, FNN.FAN_BEG_PLAN FNN_BEG_PLAN,
        FNN.FAN_END_PLAN FNN_END_PLAN, FNS.FAN_DESCRIPTION FNS_DESCRIPTION, GOO.DIC_UNIT_OF_MEASURE_ID,
        FSR.FSR_TEXTE, FSR.FSR_NUMBER, PAC.DIC_TARIFF_ID,
        FDP.FDP_BASIS_QTY, FDP.FDP_INTERMEDIATE_QTY, FNL.FLN_QTY,
        FNL.FLN_NEED_DELAY, FSR.FSR_DELAY, FSR.FSR_TOTAL_QTY,
        FDP.FAL_DOC_PROP_ID, GOO.GOO_NUMBER_OF_DECIMAL, FNL.FAL_NETWORK_NEED_ID,
        FDP.FAL_SUPPLY_REQUEST_ID, STO.STO_DESCRIPTION, FNN.FAL_LOT_ID, FNN.FAN_DESCRIPTION,LOT.LOT_REFCOMPL,
        GCO_FUNCTIONS.GetCostPriceWithManagementMode(GOO.GCO_GOOD_ID) COST_PRICE
        FROM FAL_DOC_PROP FDP,
        FAL_NETWORK_SUPPLY FNS,
        PAC_SUPPLIER_PARTNER PAC,
        PAC_PERSON PER,
        GCO_GOOD GOO,
        FAL_SUPPLY_REQUEST FSR,
        FAL_NETWORK_LINK FNL,
        FAL_NETWORK_NEED FNN,
        GCO_COMPL_DATA_PURCHASE CDA,
        GCO_DESCRIPTION GD,
        STM_LOCATION LOC,
        STM_STOCK STO,
        FAL_LOT LOT
        WHERE GOO.GCO_GOOD_ID = FDP.GCO_GOOD_ID
        AND GD.PC_LANG_ID = vpc_lang_id
        AND GD.GCO_GOOD_ID = GOO.GCO_GOOD_ID
        AND GD.C_DESCRIPTION_TYPE='01'
        AND CDA.GCO_GOOD_ID = FDP.GCO_GOOD_ID
        AND FDP.PAC_SUPPLIER_PARTNER_ID=CDA.PAC_SUPPLIER_PARTNER_ID
        AND FDP.FAL_DOC_PROP_ID >= 0
        AND FDP.FAL_DOC_PROP_ID=FNS.FAL_DOC_PROP_ID (+)
        AND FNL.FAL_NETWORK_SUPPLY_ID(+) = FNS.FAL_NETWORK_SUPPLY_ID
        AND FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID(+)
        AND LOC.STM_LOCATION_ID(+) = FNL.STM_LOCATION_ID
        AND STO.STM_STOCK_ID(+) = LOC.STM_STOCK_ID
        AND FDP.FAL_SUPPLY_REQUEST_ID = FSR.FAL_SUPPLY_REQUEST_ID(+)
        AND FDP.PAC_SUPPLIER_PARTNER_ID=PAC.PAC_SUPPLIER_PARTNER_ID
        AND PAC.PAC_SUPPLIER_PARTNER_ID=PER.PAC_PERSON_ID
        AND LOT.FAL_LOT_ID(+) = FNN.FAL_LOT_ID;
END RPT_FAL_SUPP_PROP;
