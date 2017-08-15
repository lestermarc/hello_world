--------------------------------------------------------
--  DDL for Procedure RPT_FAM_DIFF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_DIFF" (
      aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
    , parameter_1    in     varchar2
    , parameter_2    in     varchar2
    , parameter_3    in     varchar2
    , parameter_4    in     varchar2
    , parameter_6    in     varchar2
    , parameter_8    in     number
    , parameter_9    in     number
    , parameter_10   in     number
    , parameter_11   in     number
    , parameter_12   in     number
    , parameter_13   in     number
    , parameter_14   in     number
    , parameter_15   in     number
    , parameter_16   in     number
    , parameter_17   in     number
    , parameter_18   in     number
    , parameter_19   in     number
    , parameter_20   in     number
    , parameter_21   in     number
    , parameter_22   in     number
    , parameter_23   in     number
    , parameter_24   in     number
    , parameter_25   in     number
    , parameter_26   in     number
    , parameter_27   in     number
    , parameter_28   in     number
    , parameter_29   in     number
    , parameter_30   in     varchar2
    , procuser_lanid in  PCS.PC_LANG.LANID%type
)
is
    /**
    * Description - used for the report FAM_DIFFERENCE

    * @CREATED IN PROCONCEPT CHINA
    * @AUTHOR JLIU 12 MAY 2009
    * @LASTUPDATE VHA 24 OCT 2011
    * @VERSION
    * @PUBLIC
    * @param parameter_1    FIX_NUMBER
    * @param parameter_2    FIX_NUMBER
    * @param parameter_3    CAT_DESCR
    * @param parameter_4    CAT_DESCR
    * @param parameter_6    LISTE DES C_FIXED_ASSETS_STATUS
    * @param parameter_8    Période
    * @param parameter_9    ID de la valeur gérée.
    * @param parameter_10   Elément de structure 1.
    * @param parameter_11   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
    * @param parameter_12   Elément de structure 2
    * @param parameter_13   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
    * @param parameter_14   Elément de structure 3
    * @param parameter_15   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
    * @param parameter_16   Elément de structure 4
    * @param parameter_17   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
    * @param parameter_18   Elément de structure 5
    * @param parameter_19   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
    * @param parameter_20   Elément de structure 6
    * @param parameter_21   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
    * @param parameter_22   Elément de structure 7.
    * @param parameter_23   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
    * @param parameter_24   Elément de structure 8.
    * @param parameter_25   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
    * @param parameter_26   Elément de structure 9.
    * @param parameter_27   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
    * @param parameter_28   Liste des statuts séparés par une virgule / 00 = Crée, 01 = Active, 02 = Inactive, 03 = Bouclé
    * @param parameter_29   Acquisitions / Cessions: 0 = Toutes les fiches immos / 1= Etat des acquisitions / 2= Etat des cessions
    * @param parameter_30   Type d' immobilisation (0: principale / 1: tous)
    */

    vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type;
    v_mb   PCS.PC_CURR.CURRENCY%type;

begin

    PCS.PC_I_LIB_SESSION.setLanId (procuser_lanid);
    vpc_lang_id := PCS.PC_I_LIB_SESSION.GetUserLangId;

    select ACS_FUNCTION.GetLocalCurrencyName into v_mb from DUAL;

    open aRefCursor for
        select
            FAM.FAM_FIXED_ASSETS_ID,
            FAM.FIX_NUMBER,
            FAM.FIX_SHORT_DESCR,
            FAM.C_FIXED_ASSETS_STATUS,
            CAT.CAT_DESCR,
            (select decode(TRA.TRA_DESCRIPTION,null,STR.ELE_DESCRIPTION,TRA.TRA_DESCRIPTION)
                          from FAM_STRUCTURE_ELEMENT STR
                              ,FAM_TRADUCTION TRA
                         where STR.FAM_STRUCTURE_ELEMENT_ID = parameter_13
                           and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID
                           and TRA.PC_LANG_ID = vpc_lang_id) DESCR_ES0,
            (select decode(TRA.TRA_DESCRIPTION,null,STR.ELE_DESCRIPTION,TRA.TRA_DESCRIPTION)
                          from FAM_STRUCTURE_ELEMENT STR
                              ,FAM_TRADUCTION TRA
                         where STR.FAM_STRUCTURE_ELEMENT_ID = parameter_14
                           and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID
                           and TRA.PC_LANG_ID = vpc_lang_id) DESCR_ES1,
            (select decode(TRA.TRA_DESCRIPTION,null,STR.ELE_DESCRIPTION,TRA.TRA_DESCRIPTION)
                          from FAM_STRUCTURE_ELEMENT STR
                              ,FAM_TRADUCTION TRA
                         where STR.FAM_STRUCTURE_ELEMENT_ID = parameter_15
                           and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID
                           and TRA.PC_LANG_ID = vpc_lang_id) DESCR_ES2,
            (select decode(TRA.TRA_DESCRIPTION,null,STR.ELE_DESCRIPTION,TRA.TRA_DESCRIPTION)
                          from FAM_STRUCTURE_ELEMENT STR
                              ,FAM_TRADUCTION TRA
                         where STR.FAM_STRUCTURE_ELEMENT_ID = parameter_16
                           and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID
                           and TRA.PC_LANG_ID = vpc_lang_id) DESCR_ES3,
            (select decode(TRA.TRA_DESCRIPTION,null,STR.ELE_DESCRIPTION,TRA.TRA_DESCRIPTION)
                          from FAM_STRUCTURE_ELEMENT STR
                              ,FAM_TRADUCTION TRA
                         where STR.FAM_STRUCTURE_ELEMENT_ID = parameter_17
                           and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID
                           and TRA.PC_LANG_ID = vpc_lang_id) DESCR_ES4,
            (select DECODE(TRA.TRA_DESCRIPTION,null,STR.ELE_DESCRIPTION,TRA.TRA_DESCRIPTION)
                          from FAM_STRUCTURE_ELEMENT STR
                              ,FAM_TRADUCTION TRA
                         where STR.FAM_STRUCTURE_ELEMENT_ID = parameter_18
                           and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID
                           and TRA.PC_LANG_ID = vpc_lang_id) DESCR_ES5,
            (select decode(TRA.TRA_DESCRIPTION,null,STR.ELE_DESCRIPTION,TRA.TRA_DESCRIPTION)
                          from FAM_STRUCTURE_ELEMENT STR
                              ,FAM_TRADUCTION TRA
                         where STR.FAM_STRUCTURE_ELEMENT_ID = parameter_24
                           and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID
                           and TRA.PC_LANG_ID = vpc_lang_id) DESCR_ES6,
            (select decode(TRA.TRA_DESCRIPTION,null,STR.ELE_DESCRIPTION,TRA.TRA_DESCRIPTION)
                          from FAM_STRUCTURE_ELEMENT STR
                              ,FAM_TRADUCTION TRA
                         where STR.FAM_STRUCTURE_ELEMENT_ID = parameter_25
                           and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID
                           and TRA.PC_LANG_ID = vpc_lang_id) DESCR_ES7,
            (select decode(TRA.TRA_DESCRIPTION,null,STR.ELE_DESCRIPTION,TRA.TRA_DESCRIPTION)
                          from FAM_STRUCTURE_ELEMENT STR
                              ,FAM_TRADUCTION TRA
                         where STR.FAM_STRUCTURE_ELEMENT_ID = parameter_26
                           and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID
                           and TRA.PC_LANG_ID = vpc_lang_id) DESCR_ES8,
            (select decode(TRA.TRA_DESCRIPTION,null,STR.ELE_DESCRIPTION,TRA.TRA_DESCRIPTION)
                          from FAM_STRUCTURE_ELEMENT STR
                              ,FAM_TRADUCTION TRA
                         where STR.FAM_STRUCTURE_ELEMENT_ID = parameter_27
                           and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID
                           and TRA.PC_LANG_ID = vpc_lang_id) DESCR_ES9,
            (select decode(TRA.TRA_DESCRIPTION,null,STR.ELE_DESCRIPTION,TRA.TRA_DESCRIPTION)
                          from FAM_STRUCTURE_ELEMENT STR
                              ,FAM_TRADUCTION TRA
                         where STR.FAM_STRUCTURE_ELEMENT_ID = parameter_28
                           and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID
                           and TRA.PC_LANG_ID = vpc_lang_id) DESCR_ES10,
            (select DECODE(TRA.TRA_DESCRIPTION,null,STR.ELE_DESCRIPTION,TRA.TRA_DESCRIPTION)
                          from FAM_STRUCTURE_ELEMENT STR
                              ,FAM_TRADUCTION TRA
                         where STR.FAM_STRUCTURE_ELEMENT_ID = parameter_29
                           and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID
                           and TRA.PC_LANG_ID = vpc_lang_id) DESCR_ES11,
            (select DES_FIN.DES_DESCRIPTION_SUMMARY
                          from ACS_DESCRIPTION DES_FIN
                         where DES_FIN.ACS_ACCOUNT_ID = FAM_FUNCTIONS.GetFixedAssetFinAccId(FAM.FAM_FIXED_ASSETS_ID,to_char(parameter_8),'10')
                           and DES_FIN.PC_LANG_ID = vpc_lang_id ) FIN_DES,
            (select DES_CDA.DES_DESCRIPTION_SUMMARY
                          from ACS_DESCRIPTION DES_CDA
                         where DES_CDA.ACS_ACCOUNT_ID = FAM_FUNCTIONS.GetFixedAssetCDAAccId(FAM.FAM_FIXED_ASSETS_ID,to_char(parameter_8),'61')
                           and DES_CDA.PC_LANG_ID = vpc_lang_id ) CDA_DES,
            (select DES_DIV.DES_DESCRIPTION_SUMMARY
                          from ACS_DESCRIPTION DES_DIV
                         where DES_DIV.ACS_ACCOUNT_ID = FAM_FUNCTIONS.GetFixedAssetDivAccId(FAM.FAM_FIXED_ASSETS_ID,to_char(parameter_8),'10')
                           and DES_DIV.PC_LANG_ID = vpc_lang_id ) DIV_DES,
            FAM_FUNCTIONS.StructureElementAmount(0
                                                           , parameter_9
                                                           , FAM.FAM_FIXED_ASSETS_ID
                                                           , parameter_8
                                                           , parameter_13
                                                           , parameter_10
                                                           , parameter_11
                                                           , parameter_12
                                                            ) C_IMMO_ES11,
            FAM_FUNCTIONS.StructureElementAmount(0
                                                           , parameter_9
                                                           , FAM.FAM_FIXED_ASSETS_ID
                                                           , parameter_8
                                                           , parameter_14
                                                           , parameter_10
                                                           , parameter_11
                                                           , parameter_12
                                                            ) C_IMMO_ES12,
            FAM_FUNCTIONS.StructureElementAmount(0
                                                           , parameter_9
                                                           , FAM.FAM_FIXED_ASSETS_ID
                                                           , parameter_8
                                                           , parameter_15
                                                           , parameter_10
                                                           , parameter_11
                                                           , parameter_12
                                                            ) C_IMMO_ES13,
            FAM_FUNCTIONS.StructureElementAmount(0
                                                           , parameter_9
                                                           , FAM.FAM_FIXED_ASSETS_ID
                                                           , parameter_8
                                                           , parameter_16
                                                           , parameter_10
                                                           , parameter_11
                                                           , parameter_12
                                                            ) C_IMMO_ES14,
            FAM_FUNCTIONS.StructureElementAmount(0
                                                           , parameter_9
                                                           , FAM.FAM_FIXED_ASSETS_ID
                                                           , parameter_8
                                                           , parameter_17
                                                           , parameter_10
                                                           , parameter_11
                                                           , parameter_12
                                                            ) C_IMMO_ES15,
            FAM_FUNCTIONS.StructureElementAmount(0
                                                           , parameter_9
                                                           , FAM.FAM_FIXED_ASSETS_ID
                                                           , parameter_8
                                                           , parameter_18
                                                           , parameter_10
                                                           , parameter_11
                                                           , parameter_12
                                                            ) C_IMMO_ES16,
            FAM_FUNCTIONS.StructureElementAmount(0
                                                           , parameter_20
                                                           , FAM.FAM_FIXED_ASSETS_ID
                                                           , parameter_19
                                                           , parameter_24
                                                           , parameter_21
                                                           , parameter_22
                                                           , parameter_23
                                                            ) C_IMMO_ES21,
            FAM_FUNCTIONS.StructureElementAmount(0
                                                           , parameter_20
                                                           , FAM.FAM_FIXED_ASSETS_ID
                                                           , parameter_19
                                                           , parameter_25
                                                           , parameter_21
                                                           , parameter_22
                                                           , parameter_23
                                                            ) C_IMMO_ES22,
            FAM_FUNCTIONS.StructureElementAmount(0
                                                           , parameter_20
                                                           , FAM.FAM_FIXED_ASSETS_ID
                                                           , parameter_19
                                                           , parameter_26
                                                           , parameter_21
                                                           , parameter_22
                                                           , parameter_23
                                                            ) C_IMMO_ES23,
            FAM_FUNCTIONS.StructureElementAmount(0
                                                           , parameter_20
                                                           , FAM.FAM_FIXED_ASSETS_ID
                                                           , parameter_19
                                                           , parameter_27
                                                           , parameter_21
                                                           , parameter_22
                                                           , parameter_23
                                                            ) C_IMMO_ES24,
            FAM_FUNCTIONS.StructureElementAmount(0
                                                           , parameter_20
                                                           , FAM.FAM_FIXED_ASSETS_ID
                                                           , parameter_19
                                                           , parameter_28
                                                           , parameter_21
                                                           , parameter_22
                                                           , parameter_23
                                                            ) C_IMMO_ES25,
            FAM_FUNCTIONS.StructureElementAmount(0
                                                           , parameter_20
                                                           , FAM.FAM_FIXED_ASSETS_ID
                                                           , parameter_19
                                                           , parameter_29
                                                           , parameter_21
                                                           , parameter_22
                                                           , parameter_23
                                                            ) C_IMMO_ES26,
            acs_function.getaccountnumber
                            (fam_functions.getfixedassetfinaccid (fam.fam_fixed_assets_id,
                                                                  to_number (parameter_8),
                                                                  '10'
                                                                 )
                            ) ACC_NUMBER,
            acs_function.getaccountnumber
                            (fam_functions.getfixedassetcdaaccid (fam.fam_fixed_assets_id,
                                                                  to_number (parameter_8),
                                                                  '61'
                                                                 )
                            ) CDA_NUMBER,
            acs_function.getaccountnumber
                            (fam_functions.getfixedassetdivaccid (fam.fam_fixed_assets_id,
                                                                  to_number (parameter_8),
                                                                  '10'
                                                                 )
                            ) DIV_NUMBER,
            v_mb LOCAL_CURRENCY
        from
            FAM_FIXED_ASSETS FAM,
            FAM_FIXED_ASSETS_CATEG CAT
        where
            FAM.FAM_FIXED_ASSETS_CATEG_ID = CAT.FAM_FIXED_ASSETS_CATEG_ID
            and (parameter_1 is null or FAM.FIX_NUMBER >= parameter_1)
            and (parameter_2 is null or FAM.FIX_NUMBER <= parameter_2)
            and (parameter_3 is null or CAT.CAT_DESCR  >= parameter_3)
            and (parameter_4 is null or CAT.CAT_DESCR  <= parameter_4)
            and instr( ',' || parameter_6 || ',' , ',' || FAM.C_FIXED_ASSETS_STATUS ||',' ) > 0
            and (   (parameter_30 = '0' and  FAM.C_FIXED_ASSETS_TYP = '1')
                    or (parameter_30 = '1' )
                   );

end RPT_FAM_DIFF;
