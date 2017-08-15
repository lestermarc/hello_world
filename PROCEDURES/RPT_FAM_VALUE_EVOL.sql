--------------------------------------------------------
--  DDL for Procedure RPT_FAM_VALUE_EVOL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_VALUE_EVOL" (
   arefcursor        in out   CRYSTAL_CURSOR_TYPES.DualCursorTyp,
   procuser_lanid    in       PCS.PC_LANG.LANID%type,
   parameter_1       in       varchar2,
   parameter_2       in       varchar2,
   parameter_3       in       varchar2,
   parameter_4       in       varchar2,
   parameter_6       in       varchar2,
   parameter_7       in       varchar2,
   parameter_8       in       varchar2,
   parameter_9       in       varchar2,
   parameter_10     in       varchar2,
   parameter_12     in       varchar2,
   parameter_13     in       varchar2,
   parameter_14     in       varchar2,
   parameter_15     in       varchar2,
   parameter_16     in       varchar2,
   parameter_17     in       varchar2,
   parameter_18     in       varchar2,
   parameter_19     in       varchar2,
   parameter_20     in       varchar2,
   parameter_21     in       varchar2,
   parameter_22     in       varchar2,
   parameter_23     in       varchar2,
   parameter_24     in       varchar2,
   parameter_25     in       varchar2,
   parameter_26     in       varchar2,
   parameter_27     in       varchar2,
   parameter_28     in       varchar2,
   parameter_29     in       varchar2,
   parameter_30     in       varchar2
)
is
    /**
    *Description - Used for report FAM_VALUE_EVOL

    *@created JLIU 12 JAN 2009
    *@lastUpdate VHA 24 OCT 2011
    *@public
    *@param parameter_1:  Fixed assets from
    *@param parameter_2:  Fixed assets to
    *@param parameter_3:  Category from
    *@param parameter_4:  Category t0
    *@param parameter_6:  Managed value
    *@param parameter_7:  Exercice
    *@param parameter_8:  Period beginning
    *@param parameter_9:  Period end
    *@param parameter_10: Liste des Status
    *@param parameter_11: Impression(0: Cumulated;1: Detailed)--Part of structure 1
    *@param parameter_12: Structure element D1
    *@param parameter_13: Structure element D2
    *@param parameter_14: Structure element D3
    *@param parameter_15: Structure element D4
    *@param parameter_16: Structure element D5
    *@param parameter_17: Structure element D6
    *@param parameter_18: Structure element E1
    *@param parameter_19: Structure element E2
    *@param parameter_20: Structure element E3
    *@param parameter_21: Structure element E4
    *@param parameter_22: Structure element E5
    *@param parameter_23: Structure element E6
    *@param parameter_24: Structure element F1
    *@param parameter_25: Structure element F2
    *@param parameter_26: Structure element F3
    *@param parameter_27: Structure element F4
    *@param parameter_28: Structure element F5
    *@param parameter_29: Structure element F6
    *@param parameter_30: Type d' immobilisation (0: principale / 1: tous)
    */
    vpc_lang_id   PCS.PC_LANG.PC_LANG_ID%type;              --user language id
begin
   PCS.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := PCS.PC_I_LIB_SESSION.getuserlangid;

   open arefcursor for
      select   FIX.FAM_FIXED_ASSETS_ID,
                 FIX.FIX_NUMBER,
                 FIX.FIX_SHORT_DESCR,
                 FIX.C_FIXED_ASSETS_STATUS,
                 PCS.PC_FUNCTIONS.getdescodedescr
                          ('C_FIXED_ASSETS_STATUS',
                           FIX.C_FIXED_ASSETS_STATUS,
                           vpc_lang_id
                          ) C_FIXED_ASSETS_STATUS_DESCR,
                 CAT.CAT_DESCR,
                 ACS_FUNCTION.getaccountnumber
                    (FAM_FUNCTIONS.getfixedassetfinaccid (FIX.FAM_FIXED_ASSETS_ID,
                                                          to_number  (parameter_6),
                                                          '10'
                                                         )
                    ) ACC_NUMBER,
                 ACS_FUNCTION.getaccountnumber
                    (FAM_FUNCTIONS.getfixedassetcdaaccid (FIX.fam_fixed_assets_id,
                                                          to_number  (parameter_6),
                                                          '61'
                                                         )
                    ) CDA_NUMBER,
                 ACS_FUNCTION.getaccountnumber
                    (FAM_FUNCTIONS.getfixedassetdivaccid (FIX.fam_fixed_assets_id,
                                                          to_number  (parameter_6),
                                                          '10'
                                                         )
                    ) DIV_NUMBER,
                 ACS_FUNCTION.getlocalcurrencyname LOCAL_CUR_NAME,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            2,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_12),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_D1,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            2,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_13),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_D2,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            2,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_14),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_D3,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            2,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_15),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_D4,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            2,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_16),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_D5,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            2,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_17),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) c_immo_es_d6,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            0,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_18),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_E1,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            0,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_19),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_E2,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            0,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_20),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_E3,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            0,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_21),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_E4,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            0,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_22),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_E5,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            0,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_23),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_E6,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            1,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_24),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_F1,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            1,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_25),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_F2,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            1,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_26),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_F3,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            1,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_27),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_F4,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            1,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_28),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_F5,
                 FAM_FUNCTIONS.structureelementamount
                                           (0,
                                            1,
                                            FIX.FAM_FIXED_ASSETS_ID,
                                            to_number  (parameter_6),
                                            to_number  (parameter_29),
                                            to_number  (parameter_7),
                                            to_number  (parameter_8),
                                            to_number  (parameter_9)
                                           ) C_IMMO_ES_F6,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_12)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_D1,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_13)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_D2,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_14)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_D3,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_15)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_D4,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_16)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_D5,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_17)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_D6,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_18)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_E1,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_19)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_E2,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_20)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_E3,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_21)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_E4,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_22)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_E5,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_23)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_E6,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_24)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_F1,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_25)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_F2,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_26)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_F3,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_27)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_F4,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_28)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_F5,
                 (select decode (TRA.TRA_DESCRIPTION,
                                 null, STR.ELE_DESCRIPTION,
                                 TRA.TRA_DESCRIPTION
                                )
                    from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number  (parameter_29)
                     and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                     and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null
                         )) DESCR_ES_F6,
                 (select DES.DES_DESCRIPTION_SUMMARY
                    from ACS_DESCRIPTION DES
                   where DES.ACS_ACCOUNT_ID =
                            FAM_FUNCTIONS.getfixedassetfinaccid
                                    (FIX.FAM_FIXED_ASSETS_ID,
                                     to_number  (parameter_6),
                                     '10'
                                    )
                     and DES.PC_LANG_ID = vpc_lang_id) ACS_DESCRIPTION_FIN,
                 (select DES.DES_DESCRIPTION_SUMMARY
                    from ACS_DESCRIPTION DES
                   where DES.ACS_ACCOUNT_ID =
                            FAM_FUNCTIONS.getfixedassetdivaccid
                                    (FIX.FAM_FIXED_ASSETS_ID,
                                     to_number  (parameter_6),
                                     '10'
                                    )
                     and DES.PC_LANG_ID = vpc_lang_id) ACS_DESCRIPTION_DIV,
                 (select DES.DES_DESCRIPTION_SUMMARY
                    from ACS_DESCRIPTION DES
                   where DES.ACS_ACCOUNT_ID =
                            FAM_FUNCTIONS.getfixedassetcdaaccid
                                    (FIX.FAM_FIXED_ASSETS_ID,
                                     to_number  (parameter_6),
                                     '61'
                                    )
                     and DES.PC_LANG_ID = vpc_lang_id) ACS_DESCRIPTION_CDA
        from FAM_FIXED_ASSETS FIX,
             FAM_FIXED_ASSETS_CATEG CAT
        where FIX.FAM_FIXED_ASSETS_CATEG_ID = CAT.FAM_FIXED_ASSETS_CATEG_ID
         and (   (    parameter_1 is not null
                  and parameter_2 is not null
                  and FIX.FIX_NUMBER >= parameter_1
                  and FIX.FIX_NUMBER <= parameter_2
                 )
              or (parameter_1 is null and FIX.FIX_NUMBER <= parameter_2)
              or (parameter_2 is null and FIX.FIX_NUMBER >= parameter_1)
              or (parameter_1 is null and parameter_2 is null)
             )
         and (   (    parameter_3 is not null
                  and parameter_4 is not null
                  and CAT.CAT_DESCR >= parameter_3
                  and CAT.CAT_DESCR <= parameter_4
                 )
              or (parameter_3 is null and CAT.CAT_DESCR <= parameter_4)
              or (parameter_4 is null and CAT.CAT_DESCR >= parameter_3)
              or (parameter_3 is null and parameter_4 is null)
             )

         and instr(',' ||parameter_10 ||',' , ',' || FIX.C_FIXED_ASSETS_STATUS || ',' ) > 0
         and (   (parameter_30 = '0' and  FIX.C_FIXED_ASSETS_TYP = '1')
                or (parameter_30 = '1' )
               );
end RPT_FAM_VALUE_EVOL;
