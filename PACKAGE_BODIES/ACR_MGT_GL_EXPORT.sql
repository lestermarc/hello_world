--------------------------------------------------------
--  DDL for Package Body ACR_MGT_GL_EXPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_MGT_GL_EXPORT" 
is
  gtAcrGLExport     ACR_GL_EXPORT%rowtype;
  gtAcrGLExportFile ACR_GL_EXPORT_FILE%rowtype;

  /**
  * Description
  *     Initialisation interne de l'export
  **/
  procedure InitGLExport(inGLExportId in ACR_GL_EXPORT.ACR_GL_EXPORT_ID%type)
  is
  begin
    select *
      into gtAcrGLExport
      from ACR_GL_EXPORT
     where ACR_GL_EXPORT_ID = inGLExportId;

    ACR_FUNCTIONS.ACC_NUMBER1  := '0';
    ACR_FUNCTIONS.ACC_NUMBER2  := 'zzzzzzzzzz';
    ACR_FUNCTIONS.FIN_YEAR_ID  := gtAcrGLExport.ACS_FINANCIAL_YEAR_ID;
  end InitGLExport;

  /**
  * Description
  *     Initialisation interne de l'export du fichier d'export
  **/
  procedure InitGLExportFile(inGLExportFileId in ACR_GL_EXPORT_FILE.ACR_GL_EXPORT_FILE_ID%type)
  is
  begin
    select *
      into gtAcrGLExportFile
      from ACR_GL_EXPORT_FILE
     where ACR_GL_EXPORT_FILE_ID = inGLExportFileId;

    select *
      into gtAcrGLExport
      from ACR_GL_EXPORT
     where ACR_GL_EXPORT_ID = gtAcrGLExportFile.ACR_GL_EXPORT_ID;

    ACR_FUNCTIONS.ACC_NUMBER1  := '0';
    ACR_FUNCTIONS.ACC_NUMBER2  := 'zzzzzzzzzz';
    ACR_FUNCTIONS.FIN_YEAR_ID  := gtAcrGLExportFile.ACS_FINANCIAL_YEAR_ID;
  end InitGLExportFile;

  /**
  * Description
  *   Enregistrement des fichiers d'exports de l'enregistrement actif de la table donnée
  */
  procedure GenerateGLExportFiles(inGLExportId in ACR_GL_EXPORT.ACR_GL_EXPORT_ID%type)
  is
    lnPeriodNumFrom   ACS_PERIOD.PER_NO_PERIOD%type;
    ldPeriodDateFrom  ACS_PERIOD.PER_START_DATE%type;
    lvPeriodIdFromTmp ACS_PERIOD.ACS_PERIOD_ID%type;
    lvPeriodIdToTmp   ACS_PERIOD.ACS_PERIOD_ID%type;
    lnNbMonth         number;
    lnMaxLoop         number                           := 1;
  begin
    InitGLExport(inGLExportId);

    if ACR_LIB_GL_EXPORT.CheckGranularity(gtAcrGLExport.ACR_GL_EXPORT_ID) then
      if gtAcrGLExport.C_FILE_GRANULARITY = '1' then
        select decode(gtAcrGLExport.AGE_WITH_TRANSFER
                    , 1, ACS_PERIOD_FCT.GetFirstYearPeriod(gtAcrGLExport.ACS_FINANCIAL_YEAR_ID, '1')
                    , gtAcrGLExport.AGE_PERIOD_FROM_ID
                     )   --AGF_PERIOD_FROM_ID
             , gtAcrGLExport.AGE_PERIOD_TO_ID   --AGF_PERIOD_TO_ID
          into lvPeriodIdFromTmp
             , lvPeriodIdToTmp
          from dual;

        ACR_PRC_GL_EXPORT.CreateGLExportFile(gtAcrGLExport.ACR_GL_EXPORT_ID
                                           , gtAcrGLExport.ACS_FINANCIAL_YEAR_ID   --ACS_FINANCIAL_YEAR_ID
                                           , lvPeriodIdFromTmp   --AGF_PERIOD_FROM_ID
                                           , lvPeriodIdToTmp   --AGF_PERIOD_TO_ID
                                           , '1E'   --AGF_PART_NUM
                                           , ''   --AGF_XML
                                           , ''   --AGF_XML_PATH
                                            );
      else
        begin
          lnNbMonth  := ACS_PERIOD_FCT.GetNbMonthBetweenPer(gtAcrGLExport.AGE_PERIOD_FROM_ID, gtAcrGLExport.AGE_PERIOD_TO_ID);

          select PER_START_DATE
            into ldPeriodDateFrom
            from ACS_PERIOD
           where ACS_PERIOD_ID = gtAcrGLExport.AGE_PERIOD_FROM_ID;
        exception
          when no_data_found then
            null;
        end;

        if gtAcrGLExport.C_FILE_GRANULARITY = '2' then
          lnMaxLoop  := lnNbMonth / 6;

          for i in 1 .. lnMaxLoop loop
            select decode(i
                        , 1, decode(gtAcrGLExport.AGE_WITH_TRANSFER
                                  , 1, ACS_PERIOD_FCT.GetFirstYearPeriod(gtAcrGLExport.ACS_FINANCIAL_YEAR_ID, '1')
                                  , gtAcrGLExport.AGE_PERIOD_FROM_ID
                                   )
                        , ACS_FUNCTION.GetPeriodID(add_months(ldPeriodDateFrom, 6), '')
                         )
                 , decode(i, lnMaxLoop, gtAcrGLExport.AGE_PERIOD_TO_ID, ACS_FUNCTION.GetPeriodID(add_months(ldPeriodDateFrom, 5), '') )
              into lvPeriodIdFromTmp
                 , lvPeriodIdToTmp
              from dual;

            ACR_PRC_GL_EXPORT.CreateGLExportFile(gtAcrGLExport.ACR_GL_EXPORT_ID
                                               , gtAcrGLExport.ACS_FINANCIAL_YEAR_ID   --ACS_FINANCIAL_YEAR_ID
                                               , lvPeriodIdFromTmp   --AGF_PERIOD_FROM_ID
                                               , lvPeriodIdToTmp   --AGF_PERIOD_TO_ID
                                               , i || 'S'   --AGF_PART_NUM
                                               , ''   --AGF_XML
                                               , ''   --AGF_XML_PATH
                                                );
          end loop;
        end if;

        if gtAcrGLExport.C_FILE_GRANULARITY = '3' then
          lnMaxLoop  := lnNbMonth / 3;

          for i in 1 .. lnMaxLoop loop
            select decode(i
                        , 1, decode(gtAcrGLExport.AGE_WITH_TRANSFER
                                  , 1, ACS_PERIOD_FCT.GetFirstYearPeriod(gtAcrGLExport.ACS_FINANCIAL_YEAR_ID, '1')
                                  , gtAcrGLExport.AGE_PERIOD_FROM_ID
                                   )
                        , ACS_FUNCTION.GetPeriodID(add_months(ldPeriodDateFrom, 3 *(i - 1) ), '')
                         )
                 , decode(i, lnMaxLoop, gtAcrGLExport.AGE_PERIOD_TO_ID, ACS_FUNCTION.GetPeriodID(add_months(ldPeriodDateFrom,(3 *(i - 1) ) + 2), '') )
              into lvPeriodIdFromTmp
                 , lvPeriodIdToTmp
              from dual;

            ACR_PRC_GL_EXPORT.CreateGLExportFile(gtAcrGLExport.ACR_GL_EXPORT_ID
                                               , gtAcrGLExport.ACS_FINANCIAL_YEAR_ID   --ACS_FINANCIAL_YEAR_ID
                                               , lvPeriodIdFromTmp   --AGF_PERIOD_FROM_ID
                                               , lvPeriodIdToTmp   --AGF_PERIOD_TO_ID
                                               , i || 'T'   --AGF_PART_NUM
                                               , ''   --AGF_XML
                                               , ''   --AGF_XML_PATH
                                                );
          end loop;
        end if;

        if gtAcrGLExport.C_FILE_GRANULARITY = '4' then
          lnMaxLoop  := lnNbMonth;

          for i in 1 .. lnMaxLoop loop
            select decode(i
                      , 1, decode(gtAcrGLExport.AGE_WITH_TRANSFER
                                  , 1, ACS_PERIOD_FCT.GetFirstYearPeriod(gtAcrGLExport.ACS_FINANCIAL_YEAR_ID, '1')
                                  , gtAcrGLExport.AGE_PERIOD_FROM_ID
                                   )
                        , ACS_FUNCTION.GetPeriodID(add_months(ldPeriodDateFrom, i - 1), '')
                         )
                 , decode(i, lnMaxLoop, gtAcrGLExport.AGE_PERIOD_TO_ID, ACS_FUNCTION.GetPeriodID(add_months(ldPeriodDateFrom, i - 1), '')  )
              into lvPeriodIdFromTmp
                 , lvPeriodIdToTmp
              from dual;

            ACR_PRC_GL_EXPORT.CreateGLExportFile(gtAcrGLExport.ACR_GL_EXPORT_ID
                                               , gtAcrGLExport.ACS_FINANCIAL_YEAR_ID   --ACS_FINANCIAL_YEAR_ID
                                               , lvPeriodIdFromTmp   --AGF_PERIOD_FROM_ID
                                               , lvPeriodIdToTmp   --AGF_PERIOD_TO_ID
                                               , i || 'M'   --AGF_PART_NUM
                                               , ''   --AGF_XML
                                               , ''   --AGF_XML_PATH
                                                );
          end loop;
        end if;
      end if;
    end if;
  end GenerateGLExportFiles;

  /**
  * Description :
  *   Insertion des données d'export dans le champ XML
  * @param id de l'export courant
  */
  procedure GenerateXmlData(inGLExportId in number)
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    for tplGLExportFile in (select ACR_GL_EXPORT_FILE_ID
                              from ACR_GL_EXPORT_FILE
                             where ACR_GL_EXPORT_ID = inGLExportId) loop
      ACR_PRC_GL_EXPORT.SetXmlData(tplGLExportFile.ACR_GL_EXPORT_FILE_ID, GetGLXML(tplGLExportFile.ACR_GL_EXPORT_FILE_ID) );
    end loop;
  end GenerateXmlData;

  /**
  * Description  Retourne les données relatives au noeud "ligne"
  * @param inFinYearID   Id de l'exercice
  **/
  function GetRowDatas(inDocumentID in ACT_DOCUMENT.ACT_DOCUMENT_ID%type)
    return xmltype
  is
    lxmldata xmltype;
    lcur     integer;
  begin
    select   XMLAgg(XMLElement("ligne"
                             , XMLForest(CompteNum as "CompteNum")
                             , XMLForest(nvl(CompteLib, '') as "CompteLib")
                             , XMLForest(nvl(CompteAuxNum,'') as "CompteAuxNum")
                             , XMLForest(nvl(CompteAuxLib,'') as "CompteAuxLib")
                             , XMLForest(Montantdevise as "Montantdevise")
                             , XMLForest(nvl(Idevise,'') as "Idevise")
                             , XMLForest(Debit as "Debit")
                             , XMLForest(Credit as "Credit")
                             , XMLForest(abs(Debit - Credit) as "Montant")
                             , XMLForest(decode(sign(Debit - Credit), -1, '-1', '+1') as "Sens")
                              )
                   )
        into lxmldata
        from (select V_IMP.ACC_NUMBER as CompteNum
                   , ACS_FUNCTION.GetAccountDescriptionSummary(V_IMP.ACS_FINANCIAL_ACCOUNT_ID) as CompteLib
                   , ACS_FUNCTION.GetAccountNumber(IMP.ACS_AUXILIARY_ACCOUNT_ID) as CompteAuxNum
                   , ACS_FUNCTION.GetAccountDescriptionSummary(IMP.ACS_AUXILIARY_ACCOUNT_ID) as CompteAuxLib
                   , (V_IMP.IMF_AMOUNT_FC_D - V_IMP.IMF_AMOUNT_FC_C) as Montantdevise
                   , (select CURRNAME
                        from PCS.PC_CURR PC_CUR
                           , ACS_FINANCIAL_CURRENCY CUR
                       where CUR.ACS_FINANCIAL_CURRENCY_ID = V_IMP.ACS_FINANCIAL_CURRENCY_ID
                         and PC_CUR.PC_CURR_ID = CUR.PC_CURR_ID) as Idevise
                   , V_IMP.IMF_AMOUNT_LC_D as Debit
                   , V_IMP.IMF_AMOUNT_LC_C as Credit
                   , V_IMP.ACT_DOCUMENT_ID
                   , PER.ACS_PERIOD_ID
                   , PER.C_TYPE_PERIOD
                   , PER.ACS_FINANCIAL_YEAR_ID
                   , V_IMP.C_TYPE_CUMUL
                   , V_IMP.C_ETAT_JOURNAL
                from V_ACT_ACC_IMPUTATION V_IMP
                   , ACS_PERIOD PER
                   , ACT_DOCUMENT DOC
                   , ACT_FINANCIAL_IMPUTATION IMP
                   , ACT_DET_PAYMENT PAY
               where PER.ACS_PERIOD_ID = V_IMP.ACS_PERIOD_ID
                 and DOC.ACT_DOCUMENT_ID = V_IMP.ACT_DOCUMENT_ID
                 and IMP.ACT_FINANCIAL_IMPUTATION_ID = V_IMP.ACT_FINANCIAL_IMPUTATION_ID
                 and PAY.ACT_DET_PAYMENT_ID(+) = V_IMP.ACT_DET_PAYMENT_ID
                 and V_IMP.IMF_TYPE in('MAN', 'VAT')
                 and (     (    (     (gtAcrGLExport.AGE_ACR_REC = 1)
                                 and not exists(select 1
                                                  from V_ACT_REC_IMPUTATION V_REC
                                                 where V_REC.ACT_FINANCIAL_IMPUTATION_ID = V_IMP.ACT_FINANCIAL_IMPUTATION_ID) )
                            or (gtAcrGLExport.AGE_ACR_REC = 0)
                           )
                      and (    (     (gtAcrGLExport.AGE_ACR_PAY = 1)
                                and not exists(select 1
                                                 from V_ACT_PAY_IMPUTATION V_PAY
                                                where V_PAY.ACT_FINANCIAL_IMPUTATION_ID = V_IMP.ACT_FINANCIAL_IMPUTATION_ID) )
                           or (gtAcrGLExport.AGE_ACR_PAY = 0)
                          )
                     )
              union all
              select ACS_FUNCTION.GetAccountNumber(V_IMP.ACS_FINANCIAL_ACCOUNT_ID) as CompteNum
                   , ACS_FUNCTION.GetAccountDescriptionSummary(V_IMP.ACS_FINANCIAL_ACCOUNT_ID) as CompteLib
                   , ACS_FUNCTION.GetAccountNumber(IMP.ACS_AUXILIARY_ACCOUNT_ID) as CompteAuxNum
                   , ACS_FUNCTION.GetAccountDescriptionSummary(IMP.ACS_AUXILIARY_ACCOUNT_ID) as CompteAuxLib
                   , (V_IMP.IMF_AMOUNT_FC_D - V_IMP.IMF_AMOUNT_FC_C) as Montantdevise
                   , (select CURRNAME
                        from PCS.PC_CURR PC_CUR
                           , ACS_FINANCIAL_CURRENCY CUR
                       where CUR.ACS_FINANCIAL_CURRENCY_ID = V_IMP.ACS_FINANCIAL_CURRENCY_ID
                         and PC_CUR.PC_CURR_ID = CUR.PC_CURR_ID) as Idevise
                   , V_IMP.IMF_AMOUNT_LC_D as Debit
                   , V_IMP.IMF_AMOUNT_LC_C as Credit
                   , V_IMP.ACT_DOCUMENT_ID
                   , PER.ACS_PERIOD_ID
                   , PER.C_TYPE_PERIOD
                   , PER.ACS_FINANCIAL_YEAR_ID
                   , V_IMP.C_TYPE_CUMUL
                   , V_IMP.C_ETAT_JOURNAL
                from V_ACT_REC_IMPUTATION V_IMP
                   , ACS_PERIOD PER
                   , ACT_DOCUMENT DOC
                   , ACT_PART_IMPUTATION PAR
                   , ACT_FINANCIAL_IMPUTATION IMP
                   , ACT_DET_PAYMENT PAY
               where PER.ACS_PERIOD_ID = V_IMP.ACS_PERIOD_ID
                 and DOC.ACT_DOCUMENT_ID = V_IMP.ACT_DOCUMENT_ID
                 and IMP.ACT_FINANCIAL_IMPUTATION_ID = V_IMP.ACT_FINANCIAL_IMPUTATION_ID
                 and PAR.ACT_PART_IMPUTATION_ID(+) = V_IMP.ACT_PART_IMPUTATION_ID
                 and PAY.ACT_DET_PAYMENT_ID(+) = V_IMP.ACT_DET_PAYMENT_ID
                 and gtAcrGLExport.AGE_ACR_REC = 1
                 and V_IMP.IMF_TYPE in('MAN', 'VAT', 'AUX')
                 and (    (     (V_IMP.C_TYPE_PERIOD <> '1')
                           and (PAR.PAC_CUSTOM_PARTNER_ID is not null) )
                      or (V_IMP.C_TYPE_PERIOD = '1') )
              union all
              select ACS_FUNCTION.GetAccountNumber(V_IMP.ACS_FINANCIAL_ACCOUNT_ID) as CompteNum
                   , ACS_FUNCTION.GetAccountDescriptionSummary(V_IMP.ACS_FINANCIAL_ACCOUNT_ID) as CompteLib
                   , ACS_FUNCTION.GetAccountNumber(IMP.ACS_AUXILIARY_ACCOUNT_ID) as CompteAuxNum
                   , ACS_FUNCTION.GetAccountDescriptionSummary(IMP.ACS_AUXILIARY_ACCOUNT_ID) as CompteAuxLib
                   , (V_IMP.IMF_AMOUNT_FC_D - V_IMP.IMF_AMOUNT_FC_C) as Montantdevise
                   , (select CURRNAME
                        from PCS.PC_CURR PC_CUR
                           , ACS_FINANCIAL_CURRENCY CUR
                       where CUR.ACS_FINANCIAL_CURRENCY_ID = V_IMP.ACS_FINANCIAL_CURRENCY_ID
                         and PC_CUR.PC_CURR_ID = CUR.PC_CURR_ID) as Idevise
                   , V_IMP.IMF_AMOUNT_LC_D as Debit
                   , V_IMP.IMF_AMOUNT_LC_C as Credit
                   , V_IMP.ACT_DOCUMENT_ID
                   , PER.ACS_PERIOD_ID
                   , PER.C_TYPE_PERIOD
                   , PER.ACS_FINANCIAL_YEAR_ID
                   , V_IMP.C_TYPE_CUMUL
                   , V_IMP.C_ETAT_JOURNAL
                from V_ACT_PAY_IMPUTATION V_IMP
                   , ACS_PERIOD PER
                   , ACT_DOCUMENT DOC
                   , ACT_PART_IMPUTATION PAR
                   , ACT_FINANCIAL_IMPUTATION IMP
                   , ACT_DET_PAYMENT PAY
               where PER.ACS_PERIOD_ID = V_IMP.ACS_PERIOD_ID
                 and DOC.ACT_DOCUMENT_ID = V_IMP.ACT_DOCUMENT_ID
                 and IMP.ACT_FINANCIAL_IMPUTATION_ID = V_IMP.ACT_FINANCIAL_IMPUTATION_ID
                 and PAR.ACT_PART_IMPUTATION_ID(+) = V_IMP.ACT_PART_IMPUTATION_ID
                 and PAY.ACT_DET_PAYMENT_ID(+) = V_IMP.ACT_DET_PAYMENT_ID
                 and gtAcrGLExport.AGE_ACR_PAY = 1
                 and V_IMP.IMF_TYPE in('MAN', 'VAT', 'AUX')
                 and (    (     (V_IMP.C_TYPE_PERIOD <> '1')
                           and (PAR.PAC_SUPPLIER_PARTNER_ID is not null) )
                      or (V_IMP.C_TYPE_PERIOD = '1') ) )
       where (    (     (gtAcrGLExport.AGE_WITH_TRANSFER = 0)
                   and (C_TYPE_PERIOD in(2, 3) )
                   and (     (ACS_PERIOD_ID >= gtAcrGLExportFile.AGF_PERIOD_FROM_ID)
                        and (ACS_PERIOD_ID <= gtAcrGLExportFile.AGF_PERIOD_TO_ID) )
                  )
              or (     (gtAcrGLExport.AGE_WITH_TRANSFER = 1)
                  and (     (ACS_PERIOD_ID >= gtAcrGLExportFile.AGF_PERIOD_FROM_ID)
                       and (ACS_PERIOD_ID <= gtAcrGLExportFile.AGF_PERIOD_TO_ID) )
                 )
             )
         and (    (     (gtAcrGLExport.AGE_JOURNAL_BRO = 0)
                   and (C_ETAT_JOURNAL <> 'BRO') )
              or (gtAcrGLExport.AGE_JOURNAL_BRO = 1) )
         and (    (    gtAcrGLExport.AGE_TYPE_CUMUL_EXT = '1'
                   and C_TYPE_CUMUL = 'EXT')
              or (    gtAcrGLExport.AGE_TYPE_CUMUL_INT = '1'
                  and C_TYPE_CUMUL = 'INT')
              or (    gtAcrGLExport.AGE_TYPE_CUMUL_PRE = '1'
                  and C_TYPE_CUMUL = 'PRE')
              or (    gtAcrGLExport.AGE_TYPE_CUMUL_ENG = '1'
                  and C_TYPE_CUMUL = 'ENG')
             )
         and ACT_DOCUMENT_ID = inDocumentID
    order by CompteNum asc;

    return lxmldata;
  end GetRowDatas;

  /**
  * Description  Retourne les données relatives au noeud "ecriture"
  * @param inJournal   Concaténation du numéro et de la description du journal
  **/
  function GetEntryDatas(inJournal in varchar2)
    return xmltype
  is
    lxmldata xmltype;
    lcpt     integer;
  begin
    select XMLAgg(XMLElement("ecriture"
                           , XMLForest(to_char(rownum) as "EcritureNum")
                           , XMLForest(EcritureDate as "EcritureDate")
                           , XMLForest(nvl(EcritureLib,'') as "EcritureLib")
                           , XMLForest(nvl(PieceRef,'') as "PieceRef")
                           , XMLForest(PieceDate as "PieceDate")
--                             , XMLForest(EcritureLet as "EcritureLet")
--                             , XMLForest(DateLet as "DateLet")
                  ,          XMLForest(ValidDate as "ValidDate")
                           , GetRowDatas(ACT_DOCUMENT_ID)
                            )
                 )
      into lxmldata
      from (select V_IMP.IMF_TRANSACTION_DATE as EcritureDate
                 , V_IMP.IMF_DESCRIPTION as EcritureLib
                 , DOC.DOC_NUMBER as PieceRef
                 , DOC.DOC_DOCUMENT_DATE as PieceDate
--                   , nvl(LET.ACT_LETTERING_ID, PAY.ACT_EXPIRY_ID) as EcritureLet
--                   , nvl(LET.LET_DATE, DOC.DOC_DOCUMENT_DATE) as DateLet
            ,      nvl(IMP.A_DATEMOD, IMP.A_DATECRE) as ValidDate
                 , V_IMP.ACT_FINANCIAL_IMPUTATION_ID
                 , V_IMP.ACT_DOCUMENT_ID
                 , V_IMP.ACJ_CATALOGUE_DOCUMENT_ID
                 , PER.ACS_PERIOD_ID
                 , PER.C_TYPE_PERIOD
                 , PER.ACS_FINANCIAL_YEAR_ID
                 , V_IMP.C_ETAT_JOURNAL
                 , V_IMP.C_TYPE_CUMUL
                 , IMP.IMF_PRIMARY
                 , (JOU.JOU_NUMBER || '_' || JOU.JOU_DESCRIPTION) JOURNAL
              from V_ACT_ACC_IMPUTATION V_IMP
                 , ACS_PERIOD PER
                 , ACT_DOCUMENT DOC
                 , ACT_JOURNAL JOU
                 , ACT_FINANCIAL_IMPUTATION IMP
--                   , ACT_LETTERING LET
            ,      ACT_DET_PAYMENT PAY
             where PER.ACS_PERIOD_ID = V_IMP.ACS_PERIOD_ID
               and DOC.ACT_DOCUMENT_ID = V_IMP.ACT_DOCUMENT_ID
               and JOU.ACT_JOURNAL_ID = V_IMP.ACT_JOURNAL_ID
               and IMP.ACT_FINANCIAL_IMPUTATION_ID = V_IMP.ACT_FINANCIAL_IMPUTATION_ID
--                 and LET.ACT_LETTERING_ID(+) = IMP.ACT_LETTERING_ID
               and PAY.ACT_DET_PAYMENT_ID(+) = V_IMP.ACT_DET_PAYMENT_ID
               and V_IMP.IMF_TYPE in('MAN', 'VAT')
            union
            select V_IMP.IMF_TRANSACTION_DATE as EcritureDate
                 , V_IMP.IMF_DESCRIPTION as EcritureLib
                 , DOC.DOC_NUMBER as PieceRef
                 , DOC.DOC_DOCUMENT_DATE as PieceDate
--                   , nvl(LET.ACT_LETTERING_ID, PAY.ACT_EXPIRY_ID) as EcritureLet
--                   , nvl(LET.LET_DATE, DOC.DOC_DOCUMENT_DATE) as DateLet
            ,      nvl(IMP.A_DATEMOD, IMP.A_DATECRE) as ValidDate
                 , V_IMP.ACT_FINANCIAL_IMPUTATION_ID
                 , V_IMP.ACT_DOCUMENT_ID
                 , V_IMP.ACJ_CATALOGUE_DOCUMENT_ID
                 , PER.ACS_PERIOD_ID
                 , PER.C_TYPE_PERIOD
                 , PER.ACS_FINANCIAL_YEAR_ID
                 , V_IMP.C_ETAT_JOURNAL
                 , V_IMP.C_TYPE_CUMUL
                 , IMP.IMF_PRIMARY
                 , (JOU.JOU_NUMBER || '_' || JOU.JOU_DESCRIPTION) JOURNAL
              from V_ACT_REC_IMPUTATION V_IMP
                 , ACS_PERIOD PER
                 , ACT_DOCUMENT DOC
                 , ACT_JOURNAL JOU
                 , ACT_PART_IMPUTATION PAR
                 , ACT_FINANCIAL_IMPUTATION IMP
--                   , ACT_LETTERING LET
            ,      ACT_DET_PAYMENT PAY
             where PER.ACS_PERIOD_ID = V_IMP.ACS_PERIOD_ID
               and DOC.ACT_DOCUMENT_ID = V_IMP.ACT_DOCUMENT_ID
               and JOU.ACT_JOURNAL_ID = V_IMP.ACT_JOURNAL_ID
               and IMP.ACT_FINANCIAL_IMPUTATION_ID = V_IMP.ACT_FINANCIAL_IMPUTATION_ID
               and PAR.ACT_PART_IMPUTATION_ID(+) = V_IMP.ACT_PART_IMPUTATION_ID
--                 and LET.ACT_LETTERING_ID(+) = IMP.ACT_LETTERING_ID
               and PAY.ACT_DET_PAYMENT_ID(+) = V_IMP.ACT_DET_PAYMENT_ID
               and gtAcrGLExport.AGE_ACR_REC = 1
               and V_IMP.IMF_TYPE in('MAN', 'VAT', 'AUX')
               and PAR.PAC_CUSTOM_PARTNER_ID is not null
            union
            select V_IMP.IMF_TRANSACTION_DATE as EcritureDate
                 , V_IMP.IMF_DESCRIPTION as EcritureLib
                 , DOC.DOC_NUMBER as PieceRef
                 , DOC.DOC_DOCUMENT_DATE as PieceDate
--                   , nvl(LET.ACT_LETTERING_ID, PAY.ACT_EXPIRY_ID) as EcritureLet
--                   , nvl(LET.LET_DATE, DOC.DOC_DOCUMENT_DATE) as DateLet
            ,      nvl(IMP.A_DATEMOD, IMP.A_DATECRE) as ValidDate
                 , V_IMP.ACT_FINANCIAL_IMPUTATION_ID
                 , V_IMP.ACT_DOCUMENT_ID
                 , V_IMP.ACJ_CATALOGUE_DOCUMENT_ID
                 , PER.ACS_PERIOD_ID
                 , PER.C_TYPE_PERIOD
                 , PER.ACS_FINANCIAL_YEAR_ID
                 , V_IMP.C_ETAT_JOURNAL
                 , V_IMP.C_TYPE_CUMUL
                 , IMP.IMF_PRIMARY
                 , (JOU.JOU_NUMBER || '_' || JOU.JOU_DESCRIPTION) JOURNAL
              from V_ACT_PAY_IMPUTATION V_IMP
                 , ACS_PERIOD PER
                 , ACT_DOCUMENT DOC
                 , ACT_JOURNAL JOU
                 , ACT_PART_IMPUTATION PAR
                 , ACT_FINANCIAL_IMPUTATION IMP
--                   , ACT_LETTERING LET
            ,      ACT_DET_PAYMENT PAY
             where PER.ACS_PERIOD_ID = V_IMP.ACS_PERIOD_ID
               and DOC.ACT_DOCUMENT_ID = V_IMP.ACT_DOCUMENT_ID
               and JOU.ACT_JOURNAL_ID = V_IMP.ACT_JOURNAL_ID
               and IMP.ACT_FINANCIAL_IMPUTATION_ID = V_IMP.ACT_FINANCIAL_IMPUTATION_ID
               and PAR.ACT_PART_IMPUTATION_ID(+) = V_IMP.ACT_PART_IMPUTATION_ID
--                 and LET.ACT_LETTERING_ID(+) = IMP.ACT_LETTERING_ID
               and PAY.ACT_DET_PAYMENT_ID(+) = V_IMP.ACT_DET_PAYMENT_ID
               and gtAcrGLExport.AGE_ACR_PAY = 1
               and V_IMP.IMF_TYPE in('MAN', 'VAT', 'AUX')
               and PAR.PAC_SUPPLIER_PARTNER_ID is not null)
     where IMF_PRIMARY = 1
       and (    (     (gtAcrGLExport.AGE_WITH_TRANSFER = 0)
                 and (C_TYPE_PERIOD in(2, 3) )
                 and (     (ACS_PERIOD_ID >= gtAcrGLExportFile.AGF_PERIOD_FROM_ID)
                      and (ACS_PERIOD_ID <= gtAcrGLExportFile.AGF_PERIOD_TO_ID) )
                )
            or (     (gtAcrGLExport.AGE_WITH_TRANSFER = 1)
                and (     (ACS_PERIOD_ID >= gtAcrGLExportFile.AGF_PERIOD_FROM_ID)
                     and (ACS_PERIOD_ID <= gtAcrGLExportFile.AGF_PERIOD_TO_ID) )
               )
           )
       and (    (     (gtAcrGLExport.AGE_JOURNAL_BRO = 0)
                 and (C_ETAT_JOURNAL <> 'BRO') )
            or (gtAcrGLExport.AGE_JOURNAL_BRO = 1) )
       and (    (    gtAcrGLExport.AGE_TYPE_CUMUL_EXT = '1'
                 and C_TYPE_CUMUL = 'EXT')
            or (    gtAcrGLExport.AGE_TYPE_CUMUL_INT = '1'
                and C_TYPE_CUMUL = 'INT')
            or (    gtAcrGLExport.AGE_TYPE_CUMUL_PRE = '1'
                and C_TYPE_CUMUL = 'PRE')
            or (    gtAcrGLExport.AGE_TYPE_CUMUL_ENG = '1'
                and C_TYPE_CUMUL = 'ENG')
           )
       and JOURNAL = inJournal;

    return lxmldata;
  end GetEntryDatas;

  /**
  * Description  Retourne les données relatives au noeud "journal"
  * @param inFinYearID   Id de l'exercice
  **/
  function GetJournalDatas(inFinYearID in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
    return xmltype
  is
    lxmldata xmltype;
  begin
    select   XMLAgg(XMLElement("journal"
                             , XMLForest(nvl(JOU.JOU_NUMBER,'') as "JournalCode")
                             , XMLForest(nvl(JOU.JOU_DESCRIPTION,'') as "JournalLib")
                             , GetEntryDatas(JOU.JOU_NUMBER || '_' || JOU.JOU_DESCRIPTION)
                              )
                   )
        into lxmldata
        from ACT_JOURNAL JOU
           , (select distinct (DOC.ACT_JOURNAL_ID)
                         from ACT_DOCUMENT DOC
                            , ACJ_CATALOGUE_DOCUMENT CAT
                            , ACJ_SUB_SET_CAT SUB
                        where CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
                          and SUB.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                          and SUB.C_SUB_SET in('ACC', 'PAY', 'REC')
                          and (    (     (gtAcrGLExport.AGE_WITH_TRANSFER = 1)
                                    and (CAT.C_TYPE_CATALOGUE = '7') )
                               or (     (gtAcrGLExport.AGE_ACR_CG = 1)
                                   and (CAT.C_TYPE_CATALOGUE = '1') )
                               or (     (    (gtAcrGLExport.AGE_ACR_REC = 1)
                                         or (gtAcrGLExport.AGE_ACR_PAY = 1) )
                                   and (CAT.C_TYPE_CATALOGUE in('2', '3', '4', '5', '6') ) )
                              ) ) DOC
       where DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and JOU.ACS_FINANCIAL_YEAR_ID = inFinYearID
    order by JOU.JOU_NUMBER asc;

    return lxmldata;
  end GetJournalDatas;

  /**
  * Description  Retourne les données relative au noeud "exercice"
  * @param inFinYearID   Id de l'exercice
  **/
  function GetExerciceDatas(inFinYearID in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLAgg(XMLElement("exercice"
                                            , XMLForest(FYE_END_DATE as "DateCloture")
                                            , GetJournalDatas(ACS_FINANCIAL_YEAR_ID)
    ) )
      into lxmldata
      from ACS_FINANCIAL_YEAR
     where ACS_FINANCIAL_YEAR_ID = inFinYearID;

    return lxmldata;
  end GetExerciceDatas;

  /**
  * Description  Retour des données complètes d'exportation
  **/
  function GetGLExportation
    return xmltype
  is
    lxmldata xmltype;
  begin
    select XMLElement("comptabilite"
                    , XMLAttributes('formatA47A-I-VII-1.xsd' as "xsi:noNamespaceSchemaLocation",
                                    'http://www.w3.org/2001/XMLSchema-instance' as "xmlns:xsi")
                    , GetExerciceDatas(gtAcrGLExportFile.ACS_FINANCIAL_YEAR_ID)
                     )
      into lxmldata
      from dual;

    return lxmldata;
  end GetGLExportation;

  /**
  * Description  Retour des données complètes d'exportation
  **/
  function GetGLXML(inGLExportFileId in number)
    return clob
  is
    lxmldata xmltype;
  begin
    InitGLExportFile(inGLExportFileId);
    lxmldata  := GetGLExportation;

    if lxmldata is not null then
      return pc_jutils.get_XmlPrologDefault || chr(10) || lxmldata.GetClobVal();
    else
      return null;
    end if;
  end GetGLXML;

      /**
  * Description :
  *   Retourne le document XSD de validation
  */
  function GetXsdSchema
    return clob
  is
    vResult ACR_EDO.EDO_XML%type;
  begin
    select XSD_SCHEMA
      into vResult
      from PCS.PC_XSD_SCHEMA
     where XSD_NAME = 'XSD_ACR_GL_EXPORT';

    return vResult;
  end GetXsdSchema;
end ACR_MGT_GL_EXPORT;
