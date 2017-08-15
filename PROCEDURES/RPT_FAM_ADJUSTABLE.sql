--------------------------------------------------------
--  DDL for Procedure RPT_FAM_ADJUSTABLE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_ADJUSTABLE" (
      aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
    , procparam_0    in     varchar2
    , procparam_1    in     varchar2
    , procparam_2    in     varchar2
    , procparam_3    in     varchar2
    , procparam_4    in     varchar2
    , procparam_5    in     number
    , procparam_6    in     number
    , procparam_7    in     number
    , procparam_8    in     number
    , procparam_9    in     number
    , procparam_10   in     number
    , procparam_11   in     number
    , procparam_12   in     number
    , procparam_13   in     number
    , procparam_14   in     number
    , procparam_15   in     number
    , procparam_16   in     number
    , procparam_17   in     number
    , procparam_18   in     number
    , procparam_19   in     number
    , procparam_20   in     number
    , procparam_21   in     number
    , procparam_22   in     number
    , procparam_23   in     number
    , procparam_24   in     number
    , procparam_25   in     number
    , procparam_26   in     number
    , procparam_27   in     number
    , procparam_28   in     varchar2
    , procparam_29   in     number
    , procparam_30   in     number
    , procparam_31   in     number
    , procparam_32   in     varchar2
    , procuser_lanid in     PCS.PC_LANG.LANID%type
)
is
    /**
    *Description - used for the report FAM_ADJUSTABLE

      @author OJO
      @lastUpdate VHA 26 JUNE 2013
      @version 2003.
      @public
      @param procparam_0    Titre de la liste.
      @param procparam_1    Immobilisation de :
      @param procparam_2    Immobilisation à
      @param procparam_3    Catégorie de :
      @param procparam_4    Catégorie à
      @param procparam_5    Regroupement : 0 = Par immobilisation, 1 = Par catégorie, 2 = Par compte financier, 3 = Par division, 4 = Par centre d'analyse
      @param procparam_6    ID de l'exercice
      @param procparam_7    Période de :
      @param procparam_8    Période à
      @param procparam_9    ID de la valeur gérée.
      @param procparam_10   Elément de structure 1.
      @param procparam_11   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
      @param procparam_12   Elément de structure 2
      @param procparam_13   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
      @param procparam_14   Elément de structure 3
      @param procparam_15   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
      @param procparam_16   Elément de structure 4
      @param procparam_17   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
      @param procparam_18   Elément de structure 5
      @param procparam_19   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
      @param procparam_20   Elément de structure 6
      @param procparam_21   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
      @param procparam_22   Elément de structure 7.
      @param procparam_23   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
      @param procparam_24   Elément de structure 8.
      @param procparam_25   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
      @param procparam_26   Elément de structure 9.
      @param procparam_27   Critères du cumul 1 : 0 = Solde de l'exercice, 1 = Solde fin de l'exercice, 2 = Solde début de l'exercice
      @param procparam_28   Liste des statuts séparés par une virgule / 00 = Crée, 01 = Active, 02 = Inactive, 03 = Bouclé
      @param procparam_29   Acquisitions / Cessions: 0 = Toutes les fiches immos / 1= Etat des acquisitions / 2= Etat des cessions
      @param procparam_30   Regroupement selon catalogue: 0= Non-coché 1= coché
      @param procparam_31   Impression : 0= Cumulé 1 = Détaillé
      @param procparam_32   Type d' immobilisation (0: principale / 1: tous)
    */
      vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type := null;
      vCatFrom    FAM_FIXED_ASSETS_CATEG.CAT_DESCR%type := null;
      vCatTo      FAM_FIXED_ASSETS_CATEG.CAT_DESCR%type := null;
      vFixFrom    FAM_FIXED_ASSETS.FIX_NUMBER%type := null;
      vFixTo      FAM_FIXED_ASSETS.FIX_NUMBER%type := null;
      vDateFrom   date;
      vDateTo     date;
begin
  PCS.PC_I_LIB_SESSION.setLanId(procuser_lanid);
  vpc_lang_id  := PCS.PC_I_LIB_SESSION.GetUserLangId;

  if ((procparam_6 is not null) and (procparam_7 is not null) and (procparam_8 is not null)) then
      select PER_START.PER_START_DATE
           , PER_END.PER_END_DATE
        into vDateFrom
           , vDateTo
        from ACS_PERIOD PER_START
           , ACS_PERIOD PER_END
       where PER_START.ACS_FINANCIAL_YEAR_ID = procparam_6
         and PER_END.ACS_FINANCIAL_YEAR_ID = procparam_6
         and PER_START.PER_NO_PERIOD = procparam_7
         and PER_END.PER_NO_PERIOD = procparam_8;
  end if;

  if    procparam_3 is null
     or procparam_3 = '' then
    select min(CAT_DESCR)
      into vCatFrom
      from FAM_FIXED_ASSETS_CATEG CAT;
  else
    vCatFrom  := procparam_3;
  end if;

  if    procparam_4 is null
     or procparam_4 = '' then
    select max(CAT_DESCR)
      into vCatTo
      from FAM_FIXED_ASSETS_CATEG CAT;
  else
    vCatTo  := procparam_4;
  end if;

  if    procparam_1 is null
     or procparam_1 = '' then
    select min(FIX_NUMBER)
      into vFixFrom
      from FAM_FIXED_ASSETS FIX;
  else
    vFixFrom  := procparam_1;
  end if;

  if    procparam_2 is null
     or procparam_2 = '' then
    select max(FIX_NUMBER)
      into vFixTo
      from FAM_FIXED_ASSETS FIX;
  else
    vFixTo  := procparam_2;
  end if;

  open aRefCursor for
     select FIX.FAM_FIXED_ASSETS_ID
          , FIX.FIX_NUMBER
          , FIX.FIX_SHORT_DESCR
          , FIX.C_FIXED_ASSETS_STATUS
          , CAT.CAT_DESCR
          , FAM_FUNCTIONS.StructureElementAmount(0
                                               , procparam_11
                                               , FIX.FAM_FIXED_ASSETS_ID
                                               , procparam_9
                                               , procparam_10
                                               , procparam_6
                                               , procparam_7
                                               , procparam_8
                                                ) IMMO_ES1
          , FAM_FUNCTIONS.StructureElementAmount(0
                                               , procparam_13
                                               , FIX.FAM_FIXED_ASSETS_ID
                                               , procparam_9
                                               , procparam_12
                                               , procparam_6
                                               , procparam_7
                                               , procparam_8
                                                ) IMMO_ES2
          , FAM_FUNCTIONS.StructureElementAmount(0
                                               , procparam_15
                                               , FIX.FAM_FIXED_ASSETS_ID
                                               , procparam_9
                                               , procparam_14
                                               , procparam_6
                                               , procparam_7
                                               , procparam_8
                                                ) IMMO_ES3
          , FAM_FUNCTIONS.StructureElementAmount(0
                                               , procparam_17
                                               , FIX.FAM_FIXED_ASSETS_ID
                                               , procparam_9
                                               , procparam_16
                                               , procparam_6
                                               , procparam_7
                                               , procparam_8
                                                ) IMMO_ES4
          , FAM_FUNCTIONS.StructureElementAmount(0
                                               , procparam_19
                                               , FIX.FAM_FIXED_ASSETS_ID
                                               , procparam_9
                                               , procparam_18
                                               , procparam_6
                                               , procparam_7
                                               , procparam_8
                                                ) IMMO_ES5
          , FAM_FUNCTIONS.StructureElementAmount(0
                                               , procparam_21
                                               , FIX.FAM_FIXED_ASSETS_ID
                                               , procparam_9
                                               , procparam_20
                                               , procparam_6
                                               , procparam_7
                                               , procparam_8
                                                ) IMMO_ES6
          , FAM_FUNCTIONS.StructureElementAmount(0
                                               , procparam_23
                                               , FIX.FAM_FIXED_ASSETS_ID
                                               , procparam_9
                                               , procparam_22
                                               , procparam_6
                                               , procparam_7
                                               , procparam_8
                                                ) IMMO_ES7
          , FAM_FUNCTIONS.StructureElementAmount(0
                                               , procparam_25
                                               , FIX.FAM_FIXED_ASSETS_ID
                                               , procparam_9
                                               , procparam_24
                                               , procparam_6
                                               , procparam_7
                                               , procparam_8
                                                ) IMMO_ES8
          , FAM_FUNCTIONS.StructureElementAmount(0
                                               , procparam_27
                                               , FIX.FAM_FIXED_ASSETS_ID
                                               , procparam_9
                                               , procparam_26
                                               , procparam_6
                                               , procparam_7
                                               , procparam_8
                                                ) IMMO_ES9

                    ,(   select  decode (TRA.TRA_DESCRIPTION,
                                                    null,
                                                    STR.ELE_DESCRIPTION,
                                                    TRA.TRA_DESCRIPTION
                                                )
                             from   FAM_STRUCTURE_ELEMENT STR,
                                       FAM_TRADUCTION TRA
                           where   STR.FAM_STRUCTURE_ELEMENT_ID = to_number (procparam_10)
                               and   STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                               and   (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null)
                        ) DESCR_ES1
                    ,(   select  decode (TRA.TRA_DESCRIPTION,
                                                null,
                                                STR.ELE_DESCRIPTION,
                                                TRA.TRA_DESCRIPTION
                                            )
                         from  FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                       where  STR.FAM_STRUCTURE_ELEMENT_ID = to_number (procparam_12)
                           and  STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                           and  (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null)
                 ) DESCR_ES2
                ,(   select  decode (TRA.TRA_DESCRIPTION,
                                            null,
                                            STR.ELE_DESCRIPTION,
                                            TRA.TRA_DESCRIPTION
                                        )
                     from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number (procparam_14)
                       and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                       and (TRA.PC_LANG_ID = VPC_LANG_ID or TRA.PC_LANG_ID is null)
                 ) DESCR_ES3
                ,(   select  decode (TRA.TRA_DESCRIPTION,
                                            null,
                                            STR.ELE_DESCRIPTION,
                                            TRA.TRA_DESCRIPTION
                                        )
                     from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number (procparam_16)
                       and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                       and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null)
                 ) DESCR_ES4
                ,(   select  decode (TRA.TRA_DESCRIPTION,
                                            null, STR.ELE_DESCRIPTION,
                                            TRA.TRA_DESCRIPTION
                                        )
                     from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number (procparam_18)
                       and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                       and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null)
                 ) DESCR_ES5
                ,(   select  decode (TRA.TRA_DESCRIPTION,
                                            null, STR.ELE_DESCRIPTION,
                                            TRA.TRA_DESCRIPTION
                                        )
                     from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number (procparam_20)
                       and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                       and (TRA.PC_LANG_ID = VPC_LANG_ID OR TRA.PC_LANG_ID is null)
                 ) DESCR_ES6
                ,(   select  decode (TRA.TRA_DESCRIPTION,
                                            null, STR.ELE_DESCRIPTION,
                                            TRA.TRA_DESCRIPTION
                                        )
                     from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number (procparam_22)
                       and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                       and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null)
                 ) DESCR_ES7
                ,(   select  decode (TRA.TRA_DESCRIPTION,
                                            null, STR.ELE_DESCRIPTION,
                                            TRA.TRA_DESCRIPTION
                                        )
                     from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number (procparam_24)
                       and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                       and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null)
                 ) DESCR_ES8
                ,(   select  decode (TRA.TRA_DESCRIPTION,
                                            null, STR.ELE_DESCRIPTION,
                                            TRA.TRA_DESCRIPTION
                                        )
                     from FAM_STRUCTURE_ELEMENT STR, FAM_TRADUCTION TRA
                   where STR.FAM_STRUCTURE_ELEMENT_ID = to_number (procparam_26)
                       and STR.FAM_STRUCTURE_ELEMENT_ID = TRA.FAM_STRUCTURE_ELEMENT_ID(+)
                       and (TRA.PC_LANG_ID = vpc_lang_id or TRA.PC_LANG_ID is null)
                 ) DESCR_ES9
                ,(   select DES.DES_DESCRIPTION_SUMMARY
                     from ACS_DESCRIPTION DES
                   where DES.ACS_ACCOUNT_ID = FAM_FUNCTIONS.getfixedassetfinaccid
                                (FIX.FAM_FIXED_ASSETS_ID,
                                    to_number (procparam_10),
                                    '10'
                                )
                       and DES.PC_LANG_ID = vpc_lang_id) ACS_DESCRIPTION_FIN
                ,(   select DES.DES_DESCRIPTION_SUMMARY
                     from ACS_DESCRIPTION DES
                   where DES.ACS_ACCOUNT_ID =
                        FAM_FUNCTIONS.getfixedassetdivaccid
                                (FIX.FAM_FIXED_ASSETS_ID,
                                 to_number (procparam_10),
                                 '10'
                                )
                       and DES.PC_LANG_ID = vpc_lang_id) ACS_DESCRIPTION_DIV
                ,(   select DES.DES_DESCRIPTION_SUMMARY
                     from ACS_DESCRIPTION DES
                   where DES.ACS_ACCOUNT_ID = FAM_FUNCTIONS.getfixedassetcdaaccid
                                (FIX.FAM_FIXED_ASSETS_ID,
                                    to_number (procparam_10),
                                    '61'
                                )
                       and DES.PC_LANG_ID = vpc_lang_id) ACS_DESCRIPTION_CDA
          , (select min(IMP.FIM_TRANSACTION_DATE)
               from FAM_IMPUTATION IMP
                  , FAM_VAL_IMPUTATION VAL
              where IMP.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
                and IMP.FAM_IMPUTATION_ID = VAL.FAM_IMPUTATION_ID
                and VAL.FAM_MANAGED_VALUE_ID = procparam_9
                and substr(IMP.C_FAM_TRANSACTION_TYP, 1, 1) = '1'
                and (    (procparam_29 <> 1)
                     or (    IMP.FIM_TRANSACTION_DATE >= vDateFrom
                         and IMP.FIM_TRANSACTION_DATE <= vDateTo)
                    ) ) DATE_IN
          , (select max(IMP.FIM_TRANSACTION_DATE)
               from FAM_IMPUTATION IMP
                  , FAM_VAL_IMPUTATION VAL
              where IMP.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
                and IMP.FAM_IMPUTATION_ID = VAL.FAM_IMPUTATION_ID
                and VAL.FAM_MANAGED_VALUE_ID = procparam_9
                and IMP.C_FAM_TRANSACTION_TYP >= '800'
                and IMP.C_FAM_TRANSACTION_TYP <= '890'
                and (    (procparam_29 <> 2)
                     or (    IMP.FIM_TRANSACTION_DATE >= vDateFrom
                         and IMP.FIM_TRANSACTION_DATE <= vDateTo)
                    ) ) DATE_OUT
          , case
              when procparam_29 = 1
              and procparam_30 = 1 then (select max(FCA_DESCR)
                                           from FAM_IMPUTATION IMP
                                              , FAM_VAL_IMPUTATION VAL
                                              , FAM_DOCUMENT DOC
                                              , FAM_CATALOGUE CAT
                                          where DOC.FAM_DOCUMENT_ID = IMP.FAM_DOCUMENT_ID
                                            and DOC.FAM_CATALOGUE_ID = CAT.FAM_CATALOGUE_ID
                                            and IMP.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
                                            and IMP.FAM_IMPUTATION_ID = VAL.FAM_IMPUTATION_ID
                                            and VAL.FAM_MANAGED_VALUE_ID = procparam_9
                                            and substr(IMP.C_FAM_TRANSACTION_TYP, 1, 1) = '1'
                                            and IMP.FIM_TRANSACTION_DATE =
                                                  (select min(IMP.FIM_TRANSACTION_DATE)
                                                     from FAM_IMPUTATION IMP
                                                        , FAM_VAL_IMPUTATION VAL
                                                    where IMP.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
                                                      and IMP.FAM_IMPUTATION_ID = VAL.FAM_IMPUTATION_ID
                                                      and VAL.FAM_MANAGED_VALUE_ID = procparam_9
                                                      and substr(IMP.C_FAM_TRANSACTION_TYP, 1, 1) = '1'
                                                      and (    IMP.FIM_TRANSACTION_DATE >= vDateFrom
                                                           and IMP.FIM_TRANSACTION_DATE <= vDateTo
                                                          ) ) )
              when procparam_29 = 2
              and procparam_30 = 1 then (select max(FCA_DESCR)
                                           from FAM_IMPUTATION IMP
                                              , FAM_VAL_IMPUTATION VAL
                                              , FAM_DOCUMENT DOC
                                              , FAM_CATALOGUE CAT
                                          where DOC.FAM_DOCUMENT_ID = IMP.FAM_DOCUMENT_ID
                                            and DOC.FAM_CATALOGUE_ID = CAT.FAM_CATALOGUE_ID
                                            and IMP.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
                                            and IMP.FAM_IMPUTATION_ID = VAL.FAM_IMPUTATION_ID
                                            and VAL.FAM_MANAGED_VALUE_ID = procparam_9
                                            and IMP.C_FAM_TRANSACTION_TYP >= '800'
                                            and IMP.C_FAM_TRANSACTION_TYP <= '890'
                                            and IMP.FIM_TRANSACTION_DATE =
                                                  (select max(IMP.FIM_TRANSACTION_DATE)
                                                     from FAM_IMPUTATION IMP
                                                        , FAM_VAL_IMPUTATION VAL
                                                    where IMP.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
                                                      and IMP.FAM_IMPUTATION_ID = VAL.FAM_IMPUTATION_ID
                                                      and VAL.FAM_MANAGED_VALUE_ID = procparam_9
                                                      and IMP.C_FAM_TRANSACTION_TYP >= '800'
                                                      and IMP.C_FAM_TRANSACTION_TYP <= '890'
                                                      and (    IMP.FIM_TRANSACTION_DATE >= vDateFrom
                                                           and IMP.FIM_TRANSACTION_DATE <= vDateTo
                                                          ) ) )
              else ''
            end FCA_DESCR
       from FAM_FIXED_ASSETS FIX
          , FAM_FIXED_ASSETS_CATEG CAT
      where FIX.FAM_FIXED_ASSETS_CATEG_ID = CAT.FAM_FIXED_ASSETS_CATEG_ID
        and (instr(',' || procparam_28 || ',', ',' || FIX.C_FIXED_ASSETS_STATUS || ',') > 0)
        and CAT.CAT_DESCR >= vCatFrom
        and CAT.CAT_DESCR <= vCatTo
        and FIX.FIX_NUMBER >= vFixFrom
        and FIX.FIX_NUMBER <= vFixTo
        and (    (procparam_29 <> 1)
             or exists(
                  select 1
                    from FAM_IMPUTATION IMP
                       , FAM_VAL_IMPUTATION VAL
                   where IMP.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
                     and IMP.FAM_IMPUTATION_ID = VAL.FAM_IMPUTATION_ID
                     and VAL.FAM_MANAGED_VALUE_ID = procparam_9
                     and substr(IMP.C_FAM_TRANSACTION_TYP, 1, 1) = '1'
                     and IMP.FIM_TRANSACTION_DATE >= vDateFrom
                     and IMP.FIM_TRANSACTION_DATE <= vDateTo)
            )
        and   -- Acquisitions --
            (    (procparam_29 <> 2)
             or exists(
                  select 1
                    from fAM_IMPUTATION IMP
                       , FAM_VAL_IMPUTATION VAL
                   where IMP.FAM_FIXED_ASSETS_ID = FIX.FAM_FIXED_ASSETS_ID
                     and IMP.FAM_IMPUTATION_ID = VAL.FAM_IMPUTATION_ID
                     and VAL.FAM_MANAGED_VALUE_ID = procparam_9
                     and IMP.C_FAM_TRANSACTION_TYP >= '800'
                     and IMP.C_FAM_TRANSACTION_TYP <= '890'
                     and IMP.FIM_TRANSACTION_DATE >= vDateFrom
                     and IMP.FIM_TRANSACTION_DATE <= vDateTo)
            )   -- Cessions --

        and
            (   (procparam_32 = '0' and  FIX.C_FIXED_ASSETS_TYP = '1')
             or (procparam_32 = '1')
            );
end RPT_FAM_ADJUSTABLE;
