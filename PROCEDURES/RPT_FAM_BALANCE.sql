--------------------------------------------------------
--  DDL for Procedure RPT_FAM_BALANCE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_BALANCE" (
   arefcursor       in out   CRYSTAL_CURSOR_TYPES.DualCursorTyp,
   procuser_lanid   in       PCS.PC_LANG.LANID%type,
   parameter_1      in       varchar2,
   parameter_2      in       varchar2,
   parameter_3      in       varchar2,
   parameter_4      in       varchar2,
   parameter_6      in       varchar2,
   parameter_7      in       varchar2,
   parameter_8      in       varchar2,
   parameter_9      in       varchar2,
   parameter_10     in       varchar2,
   parameter_11     in       varchar2,
   parameter_12     in       varchar2,
   parameter_13     in       varchar2,
   parameter_14     in       varchar2,
   parameter_15     in       varchar2,
   parameter_16     in       varchar2,
   parameter_17     in       varchar2,
   parameter_18     in       varchar2,
   parameter_19     in       varchar2,
   parameter_20     in       varchar2,
   parameter_22      in       varchar2
)
is
    /**
    *Description - Used for the report FAM_BALANCE

    * @CREATED IN PROCONCEPT CHINA
    * @AUTHOR JLIU 12 JAN 2009
    * @LASTUPDATE VHA 24 OCT 2011
    * @VERSION
    * @PUBLIC
    * @param parameter_1:  fixed assets from
    * @param parameter_2:  fixed assets to
    * @param parameter_3:  category from
    * @param parameter_4:  category t0
    * @param parameter_6:  critere de cumul
    * @param parameter_7:  exercice
    * @param parameter_8:  period beginning
    * @param parameter_9:  period end
    * @param parameter_10: managed value
    * @param parameter_11: structure element 1
    * @param parameter_12: structure element 2
    * @param parameter_13: structure element 3
    * @param parameter_14: structure element 4
    * @param parameter_15: structure element 5
    * @param parameter_16: structure element 6
    * @param parameter_17: structure element 7
    * @param parameter_18: structure element 8
    * @param parameter_19: structure element 9
    * @param parameter_20: liste des stauts des immob
    * @param parameter_22: type d' immobilisation (0: principale / 1: tous)
    */
   vpc_lang_id   PCS.PC_LANG.PC_LANG_ID%type;              --user language id

begin

   PCS.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := PCS.PC_I_LIB_SESSION.getuserlangid;

   open arefcursor for
      select  FIX.FAM_FIXED_ASSETS_ID,
                FIX.FIX_NUMBER,
                FIX.FIX_SHORT_DESCR,
                FIX.C_FIXED_ASSETS_STATUS,
                CAT.CAT_DESCR,
                ACS_FUNCTION.getaccountnumber
                        (   FAM_FUNCTIONS.getfixedassetfinaccid (
                            FIX.FAM_FIXED_ASSETS_ID,
                            to_number (parameter_10),
                            '10'
                        )
                ) ACC_NUMBER,
                ACS_FUNCTION.getaccountnumber
                        (   FAM_FUNCTIONS.getfixedassetcdaaccid
                                (FIX.FAM_FIXED_ASSETS_ID,
                                to_number (parameter_10),
                                '61'
                                 )
                        ) CDA_NUMBER,
                ACS_FUNCTION.getaccountnumber
                        (   FAM_FUNCTIONS.getfixedassetdivaccid
                                (FIX.FAM_FIXED_ASSETS_ID,
                                to_number (parameter_10),
                                '10'
                                )
                        ) DIV_NUMBER,
                ACS_FUNCTION.getlocalcurrencyname LOCAL_CUR_NAME,
                FAM_FUNCTIONS.structureelementamount
                        (   0,
                             to_number (parameter_6),
                             FIX.FAM_FIXED_ASSETS_ID,
                             to_number (parameter_10),
                             to_number (parameter_11),
                             to_number (parameter_7),
                             to_number (parameter_8),
                             to_number (parameter_9)
                        ) C_IMMO_ES1,
                FAM_FUNCTIONS.structureelementamount
                        (   0,
                             to_number (parameter_6),
                             FIX.FAM_FIXED_ASSETS_ID,
                             to_number (parameter_10),
                             to_number (parameter_12),
                             to_number (parameter_7),
                             to_number (parameter_8),
                             to_number (parameter_9)
                        ) C_IMMO_ES2,
                FAM_FUNCTIONS.structureelementamount
                        (   0,
                             to_number (parameter_6),
                             FIX.FAM_FIXED_ASSETS_ID,
                             to_number (parameter_10),
                             to_number (parameter_13),
                             to_number (parameter_7),
                             to_number (parameter_8),
                             to_number (parameter_9)
                        ) C_IMMO_ES3,
                FAM_FUNCTIONS.structureelementamount
                        (   0,
                             to_number (parameter_6),
                             FIX.FAM_FIXED_ASSETS_ID,
                             to_number (parameter_10),
                             to_number (parameter_14),
                             to_number (parameter_7),
                             to_number (parameter_8),
                              to_number (parameter_9)
                        ) C_IMMO_ES4,
                FAM_FUNCTIONS.structureelementamount
                        (   0,
                             to_number (parameter_6),
                             FIX.FAM_FIXED_ASSETS_ID,
                             to_number (parameter_10),
                             to_number (parameter_15),
                             to_number (parameter_7),
                             to_number (parameter_8),
                             to_number (parameter_9)
                        ) C_IMMO_ES5,
                FAM_FUNCTIONS.structureelementamount
                        (   0,
                             to_number (parameter_6),
                             FIX.FAM_FIXED_ASSETS_ID,
                             to_number (parameter_10),
                             to_number (parameter_16),
                             to_number (parameter_7),
                             to_number (parameter_8),
                             to_number (parameter_9)
                        ) C_IMMO_ES6,
                FAM_FUNCTIONS.structureelementamount
                        (   0,
                             to_number (parameter_6),
                             FIX.FAM_FIXED_ASSETS_ID,
                             to_number (parameter_10),
                             to_number (parameter_17),
                             to_number (parameter_7),
                             to_number (parameter_8),
                             to_number (parameter_9)
                        ) C_IMMO_ES7,
                FAM_FUNCTIONS.structureelementamount
                        (   0,
                             to_number (parameter_6),
                             FIX.FAM_FIXED_ASSETS_ID,
                             to_number (parameter_10),
                             to_number (parameter_18),
                             to_number (parameter_7),
                             to_number (parameter_8),
                              to_number (parameter_9)
                        ) C_IMMO_ES8,
                FAM_FUNCTIONS.structureelementamount
                        (   0,
                             to_number (parameter_6),
                             FIX.FAM_FIXED_ASSETS_ID,
                             to_number (parameter_10),
                             to_number (parameter_19),
                             to_number (parameter_7),
                             to_number (parameter_8),
                             to_number (parameter_9)
                        ) C_IMMO_ES9,
                (   select  decode (TRA.TRA_DESCRIPTION,
                                            null,
                                            STR.ELE_DESCRIPTION,
                                            TRA.TRA_DESCRIPTION
                                        )
                     from   FAM_STRUCTURE_ELEMENT STR,
                               FAM_TRADUCTION TRA
                   where   STR.FAM_STRUCTURE_ELEMENT_ID = to_number (parameter_11)
                       and   STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                       and   (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null)
                ) DESCR_ES1,
                (   select  decode (TRA.TRA_DESCRIPTION,
                                            null,
                                            STR.ELE_DESCRIPTION,
                                            TRA.TRA_DESCRIPTION
                                        )
                     from  FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where  STR.FAM_STRUCTURE_ELEMENT_ID = to_number (parameter_12)
                       and  STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                       and  (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null)
             ) DESCR_ES2,
                (   select  decode (TRA.TRA_DESCRIPTION,
                                            null,
                                            STR.ELE_DESCRIPTION,
                                            TRA.TRA_DESCRIPTION
                                        )
                     from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number (parameter_13)
                       and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                       and (TRA.PC_LANG_ID = VPC_LANG_ID or TRA.PC_LANG_ID is null)
                 ) DESCR_ES3,
                (   select  decode (TRA.TRA_DESCRIPTION,
                                            null,
                                            STR.ELE_DESCRIPTION,
                                            TRA.TRA_DESCRIPTION
                                        )
                     from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number (parameter_14)
                       and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                       and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null)
                 ) DESCR_ES4,
                (   select  decode (TRA.TRA_DESCRIPTION,
                                            null, STR.ELE_DESCRIPTION,
                                            TRA.TRA_DESCRIPTION
                                        )
                     from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number (parameter_15)
                       and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                       and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null)
                 ) DESCR_ES5,
                (   select  decode (TRA.TRA_DESCRIPTION,
                                            null, STR.ELE_DESCRIPTION,
                                            TRA.TRA_DESCRIPTION
                                        )
                     from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number (parameter_16)
                       and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                       and (TRA.PC_LANG_ID = VPC_LANG_ID OR TRA.PC_LANG_ID is null)
                 ) DESCR_ES6,
                (   select  decode (TRA.TRA_DESCRIPTION,
                                            null, STR.ELE_DESCRIPTION,
                                            TRA.TRA_DESCRIPTION
                                        )
                     from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number (parameter_17)
                       and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                       and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null)
                 ) DESCR_ES7,
                (   select  decode (TRA.TRA_DESCRIPTION,
                                            null, STR.ELE_DESCRIPTION,
                                            TRA.TRA_DESCRIPTION
                                        )
                     from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number (parameter_18)
                       and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                       and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null)
                 ) DESCR_ES8,
                (   select  decode (TRA.TRA_DESCRIPTION,
                                            null, STR.ELE_DESCRIPTION,
                                            TRA.TRA_DESCRIPTION
                                        )
                     from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number (parameter_19)
                       and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                       and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null)
                 ) DESCR_ES9,
                (   select DES.DES_DESCRIPTION_SUMMARY
                     from ACS_DESCRIPTION DES
                   where DES.ACS_ACCOUNT_ID = FAM_FUNCTIONS.getfixedassetfinaccid
                                (FIX.FAM_FIXED_ASSETS_ID,
                                    to_number (parameter_10),
                                    '10'
                                )
                       and DES.PC_LANG_ID = vpc_lang_id) ACS_DESCRIPTION_FIN,
                (   select DES.DES_DESCRIPTION_SUMMARY
                     from ACS_DESCRIPTION DES
                   where DES.ACS_ACCOUNT_ID =
                        FAM_FUNCTIONS.getfixedassetdivaccid
                                (FIX.FAM_FIXED_ASSETS_ID,
                                 to_number (parameter_10),
                                 '10'
                                )
                       and DES.PC_LANG_ID = vpc_lang_id) ACS_DESCRIPTION_DIV,
                (   select DES.DES_DESCRIPTION_SUMMARY
                     from ACS_DESCRIPTION DES
                   where DES.ACS_ACCOUNT_ID = FAM_FUNCTIONS.getfixedassetcdaaccid
                                (FIX.FAM_FIXED_ASSETS_ID,
                                    to_number (parameter_10),
                                    '61'
                                )
                       and DES.PC_LANG_ID = vpc_lang_id) ACS_DESCRIPTION_CDA
      from   FAM_FIXED_ASSETS FIX,
                FAM_FIXED_ASSETS_CATEG CAT
      where FIX.FAM_FIXED_ASSETS_CATEG_ID = CAT.FAM_FIXED_ASSETS_CATEG_ID
         and  (  (   parameter_1 is not null
                        and parameter_2 is not null
                        and FIX.FIX_NUMBER >= parameter_1
                        and FIX.FIX_NUMBER <= parameter_2
                   )
                or    (parameter_1 is null and FIX.FIX_NUMBER <= parameter_2)
                or    (parameter_2 is null and FIX.FIX_NUMBER >= parameter_1)
                or    (parameter_1 is null and parameter_2 is null)
               )
         and (   (   parameter_3 is not null
                and  parameter_4 is not null
                and  CAT.CAT_DESCR >= parameter_3
                and  CAT.CAT_DESCR <= parameter_4
                  )
                or (parameter_3 is null and CAT.CAT_DESCR <= parameter_4)
                or (parameter_4 is null and CAT.CAT_DESCR >= parameter_3)
                or (parameter_3 is null and parameter_4 is null)
               )
         and instr(',' || parameter_20 || ',' , ',' || FIX.C_FIXED_ASSETS_STATUS ||',' ) > 0
         and (   (parameter_22 = '0' and  FIX.C_FIXED_ASSETS_TYP = '1')
                or (parameter_22 = '1' )
               );
end RPT_FAM_BALANCE;
