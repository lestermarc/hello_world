--------------------------------------------------------
--  DDL for Procedure RPT_GCO_PRODUCT_FORM_NOM_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_GCO_PRODUCT_FORM_NOM_SUB" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, procuser_lanid in     pcs.pc_lang.lanid%type
, parameter_0    in     number
)
is
/**Description - used for report GCO_PRODUCT_FORM_FULL
* @author SMA 16.03.2015
* @lastUpdate
* @public
* parameter_0:  Id de nomenclature
*/
  vpc_lang_id pcs.pc_lang.pc_lang_id%type;   --user language id
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  open arefcursor for
    select     GOO0.GOO_MAJOR_REFERENCE MAJOR_0
             , GOO0.NOM_REF_QTY MAJOR_REF_QTY
             , HGOO.GOO_MAJOR_REFERENCE HEAD_SORT
             , HPRO.C_SUPPLY_MODE HEAD_SUPPLY_MODE
             , (select DES_SHORT_DESCRIPTION
                  from GCO_DESCRIPTION DES
                     , PCS.PC_LANG LAN
                 where DES.GCO_GOOD_ID = HGOO.GCO_GOOD_ID
                   and DES.PC_LANG_ID = LAN.PC_LANG_ID
                   and LAN.LANID = procuser_lanid
                   and DES.C_DESCRIPTION_TYPE = '01') HGOO_DESCRIPTION
             , (select     nvl(sum(NBO2.COM_UTIL_COEFF), 1)
                      from PPS_NOM_BOND NBO2
                     where NBO2.GCO_GOOD_ID =
                             (select NOM.GCO_GOOD_ID
                                from PPS_NOM_BOND COM
                                   , PPS_NOMENCLATURE NOM
                               where COM.PPS_NOMENCLATURE_ID = NOM.PPS_NOMENCLATURE_ID
                                 and COM.PPS_PPS_NOMENCLATURE_ID = NBO.PPS_NOMENCLATURE_ID
                                 and COM.PPS_NOMENCLATURE_ID in(select     max(COM2.PPS_PPS_NOMENCLATURE_ID)
                                                                      from PPS_NOM_BOND COM2
                                                                start with COM2.PPS_NOMENCLATURE_ID = parameter_0
                                                                connect by prior COM2.PPS_PPS_NOMENCLATURE_ID = COM2.PPS_NOMENCLATURE_ID) )
                start with NBO2.PPS_NOMENCLATURE_ID = parameter_0
                connect by prior NBO2.PPS_PPS_NOMENCLATURE_ID = NBO2.PPS_NOMENCLATURE_ID) PREV_HEAD_COEFFICIENT
             , (select     sum(NBO.COM_UTIL_COEFF)
                      from PPS_NOM_BOND NBO
                     where NBO.GCO_GOOD_ID = HGOO.GCO_GOOD_ID
                start with NBO.PPS_NOMENCLATURE_ID = parameter_0
                connect by prior NBO.PPS_PPS_NOMENCLATURE_ID = NBO.PPS_NOMENCLATURE_ID) HEAD_COEFFICIENT
             , H_DESCRIPTION.DES_SHORT_DESCRIPTION H_DES_SHORT_DESCRIPTION
             , H_DESCRIPTION.DES_LONG_DESCRIPTION H_DES_LONG_DESCRIPTION
             , level
             , GOO.GOO_MAJOR_REFERENCE MAJOR
             , nvl(STMQTY.AVAILABLE_QUANTITY, 0) AVAILABLE_QUANTITY
             , D_DESCRIPTION.DES_SHORT_DESCRIPTION DES_SHORT_DESCRIPTION
             , D_DESCRIPTION.DES_LONG_DESCRIPTION DES_LONG_DESCRIPTION
             , NBO.COM_UTIL_COEFF
             , NBO.COM_PDIR_COEFF
             , NBO.COM_REC_PCENT
             , NBO.COM_POS
             , NBO.COM_REMPLACEMENT
             , NBO.COM_INTERVAL
             , NBO.COM_SEQ
             , NOM.NOM_VERSION
             , NOM.C_TYPE_NOM
             , NOM.NOM_REF_QTY
             , PRO.C_SUPPLY_MODE
             , COM_FUNCTIONS.GETDESCODEDESCR('C_TYPE_COM', NBO.C_TYPE_COM, vpc_lang_id) C_TYPE_COM
             , COM_FUNCTIONS.GETDESCODEDESCR('C_KIND_COM', NBO.C_KIND_COM, vpc_lang_id) C_KIND_COM
             , COM_FUNCTIONS.GETDESCODEDESCR('C_REMPLACEMENT_NOM', NBO.C_REMPLACEMENT_NOM, vpc_lang_id) C_REMPLACEMENT_NOM
             , COM_FUNCTIONS.GETDESCODEDESCR('C_DISCHARGE_COM', NBO.C_DISCHARGE_COM, vpc_lang_id) C_DISCHARGE_COM
             , NBO.COM_VAL
             , NBO.COM_BEG_VALID
             , NBO.COM_END_VALID
          from PPS_NOM_BOND NBO
             , GCO_GOOD GOO
             , GCO_PRODUCT PRO
             , GCO_GOOD HGOO
             , GCO_PRODUCT HPRO
             , PPS_NOMENCLATURE NOM
             , (select GCO_GOOD_ID
                     , DES.DES_SHORT_DESCRIPTION
                     , DES.DES_LONG_DESCRIPTION
                  from GCO_DESCRIPTION DES
                     , PCS.PC_LANG LAN
                 where DES.PC_LANG_ID = LAN.PC_LANG_ID
                   and LAN.LANID = procuser_lanid
                   and DES.C_DESCRIPTION_TYPE = '01') D_DESCRIPTION
             , (select HGOO.GOO_MAJOR_REFERENCE
                     , DESCRIPTION.DES_SHORT_DESCRIPTION
                     , DESCRIPTION.DES_LONG_DESCRIPTION
                  from GCO_GOOD HGOO
                     , PPS_NOMENCLATURE NOM
                     , (select GCO_GOOD_ID
                             , DES.DES_SHORT_DESCRIPTION
                             , DES.DES_LONG_DESCRIPTION
                          from GCO_DESCRIPTION DES
                             , PCS.PC_LANG LAN
                         where DES.PC_LANG_ID = LAN.PC_LANG_ID
                           and LAN.LANID = procuser_lanid
                           and DES.C_DESCRIPTION_TYPE = '01') DESCRIPTION
                 where NOM.GCO_GOOD_ID = HGOO.GCO_GOOD_ID
                   and DESCRIPTION.GCO_GOOD_ID(+) = HGOO.GCO_GOOD_ID
                   and NOM.PPS_NOMENCLATURE_ID = parameter_0) H_DESCRIPTION
             , (select   STM.GCO_GOOD_ID
                       , sum(STM.SPO_AVAILABLE_QUANTITY) AVAILABLE_QUANTITY
                    from STM_STOCK_POSITION STM
                group by STM.GCO_GOOD_ID) STMQTY
             , (select GOO1.GOO_MAJOR_REFERENCE
                     , NOM1.NOM_REF_QTY
                  from PPS_NOMENCLATURE NOM1
                     , GCO_GOOD GOO1
                 where NOM1.GCO_GOOD_ID = GOO1.GCO_GOOD_ID
                   and NOM1.PPS_NOMENCLATURE_ID = parameter_0) GOO0
         where NOM.PPS_NOMENCLATURE_ID = NBO.PPS_NOMENCLATURE_ID
           and GOO.GCO_GOOD_ID = NBO.GCO_GOOD_ID
           and GOO.GCO_GOOD_ID = PRO.GCO_GOOD_ID
           and NOM.GCO_GOOD_ID = HGOO.GCO_GOOD_ID
           and HPRO.GCO_GOOD_ID = HGOO.GCO_GOOD_ID
           and D_DESCRIPTION.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
           and STMQTY.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
    start with NBO.PPS_NOMENCLATURE_ID = parameter_0
    connect by prior NBO.PPS_PPS_NOMENCLATURE_ID = NBO.PPS_NOMENCLATURE_ID
      order siblings by NBO.COM_SEQ;
end rpt_gco_product_form_nom_sub;
