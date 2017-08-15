--------------------------------------------------------
--  DDL for Procedure RPT_PPS_NOMENCLATURE_VAL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PPS_NOMENCLATURE_VAL" (
  AREFCURSOR      in out CRYSTAL_CURSOR_TYPES.DUALCURSORTYP
, PROCUSER_LANID  in     PCS.PC_LANG.LANID%type
, NOMENCLATURE_ID in     PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
, PARAMETER_0     in     varchar2
, PARAMETER_1     in     varchar2
, PARAMETER_2     in     varchar2
)
is
/**Description - used for report PPS_NOMENCLATURE_VAL
* @author VHA 30.08.2011
* @lastUpdate VHA 11.09.2012
* @public
* PARAMETER_0:  Mode de valorisation (0:Mode de gestion / 1:PRCS / 2:PRC / 3:PRF / 4:Dernier Prix)
* PARAMETER_1:  Include higher level (0:No / 1:Yes)
* PARAMETER_2:  Purchased product details  (0:No / 1:Yes)
*/
  VPC_LANG_ID PCS.PC_LANG.PC_LANG_ID%type;   --user language id
begin
  PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);

  open AREFCURSOR for
    select     GOO0.GOO_MAJOR_REFERENCE MAJOR_0
             , GOO0.NOM_REF_QTY MAJOR_REF_QTY
             , HGOO.GOO_MAJOR_REFERENCE HEAD_SORT
             , HPRO.C_SUPPLY_MODE HEAD_SUPPLY_MODE
             , (select DES_SHORT_DESCRIPTION
                  from GCO_DESCRIPTION DES
                     , PCS.PC_LANG LAN
                 where DES.GCO_GOOD_ID = HGOO.GCO_GOOD_ID
                   and DES.PC_LANG_ID = LAN.PC_LANG_ID
                   and LAN.LANID = PROCUSER_LANID
                   and DES.C_DESCRIPTION_TYPE = '01') HGOO_DESCRIPTION
             , (select     nvl(sum(NBO2.COM_UTIL_COEFF), 1)
                      from PPS_NOM_BOND NBO2
                     where NBO2.GCO_GOOD_ID =
                             (select NOM.GCO_GOOD_ID
                                from PPS_NOM_BOND COM
                                   , PPS_NOMENCLATURE NOM
                               where COM.PPS_NOMENCLATURE_ID = NOM.PPS_NOMENCLATURE_ID
                                 and COM.PPS_PPS_NOMENCLATURE_ID = NBO.PPS_NOMENCLATURE_ID
                                 and COM.PPS_NOMENCLATURE_ID in(select max(COM2.PPS_PPS_NOMENCLATURE_ID)
                                                                      from PPS_NOM_BOND COM2
                                                                start with COM2.PPS_NOMENCLATURE_ID = NOMENCLATURE_ID
                                                                connect by prior COM2.PPS_PPS_NOMENCLATURE_ID = COM2.PPS_NOMENCLATURE_ID) )
                start with NBO2.PPS_NOMENCLATURE_ID = NOMENCLATURE_ID
                connect by prior NBO2.PPS_PPS_NOMENCLATURE_ID = NBO2.PPS_NOMENCLATURE_ID) PREV_HEAD_COEFFICIENT
             , (select     sum(NBO.COM_UTIL_COEFF)
                      from PPS_NOM_BOND NBO
                     where NBO.GCO_GOOD_ID = HGOO.GCO_GOOD_ID
                start with NBO.PPS_NOMENCLATURE_ID = NOMENCLATURE_ID
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
             , decode(PRO.C_SUPPLY_MODE, 2, 0, GCO_FUNCTIONS.GETCOSTPRICEWITHMANAGEMENTMODE(NBO.GCO_GOOD_ID, PARAMETER_0) ) PRF
             , PRO.C_SUPPLY_MODE
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
                   and LAN.LANID = PROCUSER_LANID
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
                           and LAN.LANID = PROCUSER_LANID
                           and DES.C_DESCRIPTION_TYPE = '01') DESCRIPTION
                 where NOM.GCO_GOOD_ID = HGOO.GCO_GOOD_ID
                   and DESCRIPTION.GCO_GOOD_ID(+) = HGOO.GCO_GOOD_ID
                   and NOM.PPS_NOMENCLATURE_ID = NOMENCLATURE_ID) H_DESCRIPTION
             , (select   STM.GCO_GOOD_ID
                       , sum(STM.SPO_AVAILABLE_QUANTITY) AVAILABLE_QUANTITY
                    from STM_STOCK_POSITION STM
                group by STM.GCO_GOOD_ID) STMQTY
             , (select GOO1.GOO_MAJOR_REFERENCE
                     , NOM1.NOM_REF_QTY
                  from PPS_NOMENCLATURE NOM1
                     , GCO_GOOD GOO1
                 where NOM1.GCO_GOOD_ID = GOO1.GCO_GOOD_ID
                   and NOM1.PPS_NOMENCLATURE_ID = NOMENCLATURE_ID) GOO0
         where NOM.PPS_NOMENCLATURE_ID = NBO.PPS_NOMENCLATURE_ID
           and GOO.GCO_GOOD_ID = NBO.GCO_GOOD_ID
           and GOO.GCO_GOOD_ID = PRO.GCO_GOOD_ID
           and NOM.GCO_GOOD_ID = HGOO.GCO_GOOD_ID
           and HPRO.GCO_GOOD_ID = HGOO.GCO_GOOD_ID
           and D_DESCRIPTION.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
           and STMQTY.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
    start with NBO.PPS_NOMENCLATURE_ID = NOMENCLATURE_ID
    connect by prior NBO.PPS_PPS_NOMENCLATURE_ID = NBO.PPS_NOMENCLATURE_ID
           and ((PARAMETER_2 = '0' and HPRO.C_SUPPLY_MODE <> '1')  or (PARAMETER_2 = '1'))
      order siblings by NBO.COM_SEQ;
end RPT_PPS_NOMENCLATURE_VAL;
