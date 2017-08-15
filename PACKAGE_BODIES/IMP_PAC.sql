--------------------------------------------------------
--  DDL for Package Body IMP_PAC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IMP_PAC" 
as
  lcDomain constant varchar2(15) := 'PAC';

  /**
  * Description
  *    importation des données d'Excel dans la table temporaire IMP_PAC_ADDRESS. Cette procédure est appelée depuis Excel
  */
  procedure IMP_TMP_PAC_ADDRESS(
    pDIC_PERSON_POLITNESS             varchar2
  , pPER_NAME                         varchar2
  , pPER_FORENAME                     varchar2
  , pPER_SHORT_NAME                   varchar2
  , pPER_CONTACT                      varchar2
  , pPER_KEY2                         varchar2
  , pCLIENT                           varchar2
  , pFOURNISSEUR                      varchar2
  , pC_PARTNER_STATUS                 varchar2
  , pCUS_SUB_SET_ID                   varchar2
  , pSUP_SUB_SET_ID                   varchar2
  , pPC_LANG_DESCRIPTION              varchar2
  , pACS_FINANCIAL_CURRENCY_DESC      varchar2
  , pDIC_TYPE_SUBMISSION_DESCRI       varchar2
  , pTHI_NO_TVA                       varchar2
  , pTHI_NO_INTRA                     varchar2
  , pCUSTOM_PAYMENT_CONDITION         varchar2
  , pSUPPLIER_PAYMENT_CONDITION       varchar2
  , pCUSTOM_PARTNER_DIC_TARIFF_ID     varchar2
  , pSUPPLIER_PARTN_DIC_TARIFF_ID     varchar2
  , pCOM_AREA_CODE_TEL                varchar2
  , pCOM_EXT_NUMBER_TEL               varchar2
  , pCOM_AREA_CODE_NATEL              varchar2
  , pCOM_EXT_NUMBER_NATEL             varchar2
  , pCOM_AREA_CODE_FAX                varchar2
  , pCOM_EXT_NUMBER_FAX               varchar2
  , pCOM_EXT_NUMBER_EMAIL             varchar2
  , pDIC_ADDRESS_TYPE_DESC_1          varchar2
  , pADD_PRINCIPAL_1                  varchar2
  , pADD_CARE_OF_1                    varchar2
  , pADD_ADDRESS1_1                   varchar2
  , pADD_PO_BOX_1                     varchar2
  , pADD_PO_BOX_NBR_1                 varchar2
  , pADD_ZIPCODE_1                    varchar2
  , ADD_CITY_1                        varchar2
  , pADD_COUNTY_1                     varchar2
  , pPC_CNTRY_DESC_1                  varchar2
  , pDIC_ADDRESS_TYPE_DESC_2          varchar2
  , pADD_PRINCIPAL_2                  varchar2
  , pADD_CARE_OF_2                    varchar2
  , pADD_ADDRESS1_2                   varchar2
  , pADD_PO_BOX_2                     varchar2
  , pADD_PO_BOX_NBR_2                 varchar2
  , pADD_ZIPCODE_2                    varchar2
  , pADD_CITY_2                       varchar2
  , pADD_COUNTY_2                     varchar2
  , pPC_CNTRY_DESC_2                  varchar2
  , pDIC_ADDRESS_TYPE_DESC_3          varchar2
  , pADD_PRINCIPAL_3                  varchar2
  , pADD_CARE_OF_3                    varchar2
  , pADD_ADDRESS1_3                   varchar2
  , pADD_PO_BOX_3                     varchar2
  , pADD_PO_BOX_NBR_3                 varchar2
  , pADD_ZIPCODE_3                    varchar2
  , pADD_CITY_3                       varchar2
  , pADD_COUNTY_3                     varchar2
  , pPC_CNTRY_DESC_3                  varchar2
  , pCCP                              varchar2
  , pIBAN                             varchar2
  , pBVR                              varchar2
  , pFREE_ZONE1                       varchar2
  , pFREE_ZONE2                       varchar2
  , pFREE_ZONE3                       varchar2
  , pFREE_ZONE4                       varchar2
  , pFREE_ZONE5                       varchar2
  , pFREE_ZONE6                       varchar2
  , pFREE_ZONE7                       varchar2
  , pFREE_ZONE8                       varchar2
  , pFREE_ZONE9                       varchar2
  , pFREE_ZONE10                      varchar2
  , pPER_FILE_NUMBER                  varchar2
  , pPER_SOC_STAT_1                   varchar2
  , pPER_SOC_STAT_2                   varchar2
  , pPER_SOC_STAT_3                   varchar2
  , pPER_SOC_STAT_4                   varchar2
  , pPER_SOC_STAT_5                   varchar2
  , pPER_SOC_STAT_6                   varchar2
  , pPER_SOC_STAT_7                   varchar2
  , pPER_SOC_STAT_8                   varchar2
  , pPER_SOC_STAT_9                   varchar2
  , pPER_SOC_STAT_10                  varchar2
  , pC_EDO_CANTON                     varchar2
  , pDIC_SOC_WORKER_ID                varchar2
  , pDIC_CIVIL_STATUS_ID              varchar2
  , pPER_SOC_BREAKDOWN                varchar2
  , pA_DATECRE                        varchar2
  , pA_IDCRE                          varchar2
  , pLINE                             varchar2
  , pRESULT                       out integer
  )
  is
    newVal integer;
  begin
    insert into IMP_PAC_ADDRESS
                (id
               , PAC_ADDRESS_ID
               , PAC_PERSON_ID
               , DIC_PERSON_POLITNESS
               , PER_NAME
               , PER_FORENAME
               , PER_SHORT_NAME
               , PER_CONTACT
               , PER_KEY2
               , CLIENT
               , FOURNISSEUR
               , C_PARTNER_STATUS
               , CUS_SUB_SET_ID
               , SUP_SUB_SET_ID
               , PC_LANG_DESCRIPTION
               , ACS_FINANCIAL_CURRENCY_DESC
               , DIC_TYPE_SUBMISSION_DESCRI
               , THI_NO_TVA
               , THI_NO_INTRA
               , CUSTOM_PAYMENT_CONDITION_DESC
               , SUPPLIER_PAYMENT_CONDITION_DES
               , CUSTOM_PARTNER_DIC_TARIFF_ID
               , SUPPLIER_PARTNER_DIC_TARIFF_ID
               , COM_AREA_CODE_TEL
               , COM_EXT_NUMBER_TEL
               , COM_AREA_CODE_NATEL
               , COM_EXT_NUMBER_NATEL
               , COM_AREA_CODE_FAX
               , COM_EXT_NUMBER_FAX
               , COM_EXT_NUMBER_EMAIL
               , DIC_ADDRESS_TYPE_DESC_1
               , ADD_PRINCIPAL_1
               , ADD_CARE_OF_1
               , ADD_ADDRESS1_1
               , ADD_PO_BOX_1
               , ADD_PO_BOX_NBR_1
               , ADD_ZIPCODE_1
               , ADD_CITY_1
               , ADD_COUNTY_1
               , PC_CNTRY_DESC_1
               , DIC_ADDRESS_TYPE_DESC_2
               , ADD_PRINCIPAL_2
               , ADD_CARE_OF_2
               , ADD_ADDRESS1_2
               , ADD_PO_BOX_2
               , ADD_PO_BOX_NBR_2
               , ADD_ZIPCODE_2
               , ADD_CITY_2
               , ADD_COUNTY_2
               , PC_CNTRY_DESC_2
               , DIC_ADDRESS_TYPE_DESC_3
               , ADD_PRINCIPAL_3
               , ADD_CARE_OF_3
               , ADD_ADDRESS1_3
               , ADD_PO_BOX_3
               , ADD_PO_BOX_NBR_3
               , ADD_ZIPCODE_3
               , ADD_CITY_3
               , ADD_COUNTY_3
               , PC_CNTRY_DESC_3
               , CCP
               , IBAN
               , BVR
               , FREE1
               , FREE2
               , FREE3
               , FREE4
               , FREE5
               , FREE6
               , FREE7
               , FREE8
               , FREE9
               , FREE10
               , PER_FILE_NUMBER
               , PER_SOC_STAT_1
               , PER_SOC_STAT_2
               , PER_SOC_STAT_3
               , PER_SOC_STAT_4
               , PER_SOC_STAT_5
               , PER_SOC_STAT_6
               , PER_SOC_STAT_7
               , PER_SOC_STAT_8
               , PER_SOC_STAT_9
               , PER_SOC_STAT_10
               , C_EDO_CANTON
               , DIC_SOC_WORKER_ID
               , DIC_CIVIL_STATUS_ID
               , PER_SOC_BREAKDOWN
               , A_DATECRE
               , A_IDCRE
                )
         values (pLINE
               , null
               , null
               , trim(pDIC_PERSON_POLITNESS)
               , trim(pPER_NAME)
               , trim(pPER_FORENAME)
               , trim(pPER_SHORT_NAME)
               , trim(pPER_CONTACT)
               , trim(pPER_KEY2)
               , trim(pCLIENT)
               , trim(pFOURNISSEUR)
               , trim(pC_PARTNER_STATUS)
               , trim(pCUS_SUB_SET_ID)
               , trim(pSUP_SUB_SET_ID)
               , trim(pPC_LANG_DESCRIPTION)
               , trim(pACS_FINANCIAL_CURRENCY_DESC)
               , trim(pDIC_TYPE_SUBMISSION_DESCRI)
               , trim(pTHI_NO_TVA)
               , trim(pTHI_NO_INTRA)
               , trim(pCUSTOM_PAYMENT_CONDITION)
               , trim(pSUPPLIER_PAYMENT_CONDITION)
               , trim(pCUSTOM_PARTNER_DIC_TARIFF_ID)
               , trim(pSUPPLIER_PARTN_DIC_TARIFF_ID)
               , trim(pCOM_AREA_CODE_TEL)
               , trim(pCOM_EXT_NUMBER_TEL)
               , trim(pCOM_AREA_CODE_NATEL)
               , trim(pCOM_EXT_NUMBER_NATEL)
               , trim(pCOM_AREA_CODE_FAX)
               , trim(pCOM_EXT_NUMBER_FAX)
               , trim(pCOM_EXT_NUMBER_EMAIL)
               , trim(pDIC_ADDRESS_TYPE_DESC_1)
               , trim(pADD_PRINCIPAL_1)
               , trim(pADD_CARE_OF_1)
               , trim(pADD_ADDRESS1_1)
               , trim(pADD_PO_BOX_1)
               , trim(pADD_PO_BOX_NBR_1)
               , trim(pADD_ZIPCODE_1)
               , trim(ADD_CITY_1)
               , trim(pADD_COUNTY_1)
               , trim(pPC_CNTRY_DESC_1)
               , trim(pDIC_ADDRESS_TYPE_DESC_2)
               , trim(pADD_PRINCIPAL_2)
               , trim(pADD_CARE_OF_2)
               , trim(pADD_ADDRESS1_2)
               , trim(pADD_PO_BOX_2)
               , trim(pADD_PO_BOX_NBR_2)
               , trim(pADD_ZIPCODE_2)
               , trim(pADD_CITY_2)
               , trim(pADD_COUNTY_2)
               , trim(pPC_CNTRY_DESC_2)
               , trim(pDIC_ADDRESS_TYPE_DESC_3)
               , trim(pADD_PRINCIPAL_3)
               , trim(pADD_CARE_OF_3)
               , trim(pADD_ADDRESS1_3)
               , trim(pADD_PO_BOX_3)
               , trim(pADD_PO_BOX_NBR_3)
               , trim(pADD_ZIPCODE_3)
               , trim(pADD_CITY_3)
               , trim(pADD_COUNTY_3)
               , trim(pPC_CNTRY_DESC_3)
               , trim(pCCP)
               , trim(pIBAN)
               , trim(pBVR)
               , trim(pFREE_ZONE1)
               , trim(pFREE_ZONE2)
               , trim(pFREE_ZONE3)
               , trim(pFREE_ZONE4)
               , trim(pFREE_ZONE5)
               , trim(pFREE_ZONE6)
               , trim(pFREE_ZONE7)
               , trim(pFREE_ZONE8)
               , trim(pFREE_ZONE9)
               , trim(pFREE_ZONE10)
               , trim(pPER_FILE_NUMBER)
               , trim(pPER_SOC_STAT_1)
               , trim(pPER_SOC_STAT_2)
               , trim(pPER_SOC_STAT_3)
               , trim(pPER_SOC_STAT_4)
               , trim(pPER_SOC_STAT_5)
               , trim(pPER_SOC_STAT_6)
               , trim(pPER_SOC_STAT_7)
               , trim(pPER_SOC_STAT_8)
               , trim(pPER_SOC_STAT_9)
               , trim(pPER_SOC_STAT_10)
               , trim(pC_EDO_CANTON)
               , trim(pDIC_SOC_WORKER_ID)
               , trim(pDIC_CIVIL_STATUS_ID)
               , trim(pPER_SOC_BREAKDOWN)
               , sysdate
               , IMP_LIB_TOOLS.getImportUserIni
                );

    commit;
--Nombre de ligne insérées
    pResult  := 1;
  end IMP_TMP_PAC_ADDRESS;

  /**
  * Description
  *    Contrôle des données de la table IMP_PAC_ADDRESS avant importation.
  */
  procedure IMP_PAC_CTRL
  is
    tmp_int integer;
    tmp     varchar2(200);
  begin
    --Effacement des tables d'erreurs
    IMP_PRC_TOOLS.deleteErrors(lcDomain);

    for tdata in (select *
                    from imp_pac_address) loop
      --CONTROLE UNICITE CLE2 - ERROR 002
      select count(PER_KEY2)
        into tmp_int
        from IMP_PAC_ADDRESS
       where PER_KEY2 = tdata.PER_KEY2;

      if tmp_int > 1 then
        IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_002'), '002', tdata.PER_KEY2);
      else
        --CONTROLE UNICITE CLE2 - ERROR 001
        select count(PER_KEY2)
          into tmp_int
          from PAC_PERSON
         where PER_KEY2 = tdata.PER_KEY2;

        if tmp_int > 0 then
          IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_001'), '001', tdata.PER_KEY2);
        end if;
      end if;

      --CONTROLE CHAMPS OBLIGATOIRES

      --PER_NAME - ERROR 003
      if tdata.PER_NAME is null then
        IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_003'), '003');
      end if;

      --PER_SHORT_NAME - ERROR 004
      if tdata.per_SHORT_NAME is null then
        IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_004'), '004');
      end if;

      --PER_SHORT_NAME - ERROR 005
      if tdata.PER_KEY2 is null then
        IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_005'), '005');
      end if;

      --> nature du thiers TVA
      if tdata.DIC_TYPE_SUBMISSION_DESCRI is null then
        IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_006'), '006');
      else
        IMP_PRC_TOOLS.checkDicoValue('DIC_TYPE_SUBMISSION', tdata.DIC_TYPE_SUBMISSION_DESCRI, lcDomain, 0, tdata.id);
      end if;

      --LANGUE - ERROR 008
      if tdata.PC_LANG_DESCRIPTION is null then
        IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_008'), '008');
      end if;

      --CONTRÔLE MONNAIE - ERROR 009
      select count(PC_CURR_ID)
        into tmp_int
        from pcs.PC_CURR
       where upper(CURRENCY) = upper(tdata.ACS_FINANCIAL_CURRENCY_DESC);

      if tmp_int = 0 then
        IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_009'), '009', tdata.ACS_FINANCIAL_CURRENCY_DESC);
      end if;

      --> Code de politesse
      if tdata.DIC_PERSON_POLITNESS is not null then
        IMP_PRC_TOOLS.checkDicoValue('DIC_PERSON_POLITNESS', tdata.DIC_PERSON_POLITNESS, lcDomain, 0, tdata.id);
      end if;

      --> Langue
      if tdata.PC_LANG_DESCRIPTION is not null then
        IMP_PRC_TOOLS.checkLanguage(tdata.PC_LANG_DESCRIPTION, lcDomain, 0, tdata.id);
      end if;

      --CONTROLE CONDITION DE PAIEMENT CLIENT
      if tdata.CLIENT = 1 then
        if tdata.CUSTOM_PAYMENT_CONDITION_DESC is not null then
          select count(PAC_PAYMENT_CONDITION_ID)
            into tmp_int
            from PAC_PAYMENT_CONDITION
           where trim(upper(PCO_DESCR) ) = trim(upper(tdata.CUSTOM_PAYMENT_CONDITION_DESC) );

          if tmp_int = 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_012'), '012', tdata.CUSTOM_PAYMENT_CONDITION_DESC);
          end if;
        else
          select count(PAC_PAYMENT_CONDITION_ID)
            into tmp_int
            from PAC_PAYMENT_CONDITION
           where PCO_DEFAULT = 1;

          if tmp_int = 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_013'), '013', tdata.CUSTOM_PAYMENT_CONDITION_DESC);
          end if;
        end if;
      end if;

      --CONTROLE CONDITION DE PAIEMENT FOURNISSEUR
      if tdata.FOURNISSEUR = 1 then
        if tdata.SUPPLIER_PAYMENT_CONDITION_DES is not null then
          select count(PAC_PAYMENT_CONDITION_ID)
            into tmp_int
            from PAC_PAYMENT_CONDITION
           where trim(upper(PCO_DESCR) ) = trim(upper(tdata.SUPPLIER_PAYMENT_CONDITION_DES) );

          if tmp_int = 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_012'), '012', tdata.SUPPLIER_PAYMENT_CONDITION_DES);
          end if;
        else
          select count(PAC_PAYMENT_CONDITION_ID)
            into tmp_int
            from PAC_PAYMENT_CONDITION
           where PCO_DEFAULT_PAY = 1;

          if tmp_int = 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_014'), '014', tdata.SUPPLIER_PAYMENT_CONDITION_DES);
          end if;
        end if;
      end if;

      --> Contrôle du sous-ensemble client
      if tdata.CLIENT = 1 then
        if tdata.CUS_SUB_SET_ID is not null then
          -- Contrôle de l'existance du sous-ensemble transmis
          select count(*)
            into tmp_int
            from dual
           where exists(
                   select acs.ACS_SUB_SET_ID
                     from ACS_SUB_SET acs
                        , ACS_DESCRIPTION des
                    where acs.ACS_SUB_SET_ID = des.ACS_SUB_SET_ID
                      and acs.C_TYPE_SUB_SET = 'AUX'
                      and acs.C_SUB_SET = 'REC'
                      and upper(des.DES_DESCRIPTION_SUMMARY) = upper(tdata.CUS_SUB_SET_ID) );

          if tmp_int = 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_015'), '015', tdata.CUS_SUB_SET_ID);
          end if;
        else   -- Contrôle de l'existance du sous-ensemble client par défaut
          select count(*)
            into tmp_int
            from dual
           where exists(select ACS_SUB_SET_ID
                          from ACS_SUB_SET
                         where C_TYPE_SUB_SET = 'AUX'
                           and C_SUB_SET = 'REC'
                           and ACS_SUB_SET.SSE_DEFAULT = 1);

          if tmp_int = 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_016'), '016', tdata.CUS_SUB_SET_ID);
          end if;
        end if;
      end if;

      --> Contrôle du sous-ensemble fournisseur
      if tdata.FOURNISSEUR = 1 then
        if tdata.SUP_SUB_SET_ID is not null then
          -- Contrôle de l'existance du sous-ensemble transmis
          select count(*)
            into tmp_int
            from dual
           where exists(
                   select acs.ACS_SUB_SET_ID
                     from ACS_SUB_SET acs
                        , ACS_DESCRIPTION des
                    where acs.ACS_SUB_SET_ID = des.ACS_SUB_SET_ID
                      and acs.C_TYPE_SUB_SET = 'AUX'
                      and acs.C_SUB_SET = 'PAY'
                      and upper(des.DES_DESCRIPTION_SUMMARY) = upper(tdata.SUP_SUB_SET_ID) );

          if tmp_int = 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_015'), '015', tdata.SUP_SUB_SET_ID);
          end if;
        else   -- Contrôle de l'existance du sous-ensemble fournisseur par défaut
          select count(*)
            into tmp_int
            from dual
           where exists(select ACS_SUB_SET_ID
                          from ACS_SUB_SET
                         where C_TYPE_SUB_SET = 'AUX'
                           and C_SUB_SET = 'PAY'
                           and ACS_SUB_SET.SSE_DEFAULT = 1);

          if tmp_int = 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_017'), '017', tdata.SUP_SUB_SET_ID);
          end if;
        end if;
      end if;

      --> Status du partenaire
      if tdata.C_PARTNER_STATUS is not null then
        IMP_PRC_TOOLS.checkDescodeValue('C_PARTNER_STATUS', tdata.C_PARTNER_STATUS, null, lcDomain, 0, tdata.id);
      else
        IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_019'), '019', tdata.C_PARTNER_STATUS);
      end if;

      --CONTROLE CODE PAYS ADDRESSE 1
      if tdata.DIC_ADDRESS_TYPE_DESC_1 is not null then
        if tdata.PC_CNTRY_DESC_1 is not null then
          select count(PC_CNTRY_ID)
            into tmp_int
            from pcs.PC_CNTRY
           where upper(CNTID) = upper(tdata.PC_CNTRY_DESC_1);

          if tmp_int = 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_020'), '020', tdata.PC_CNTRY_DESC_1);
          end if;
        else
          IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_021'), '021', tdata.PC_CNTRY_DESC_1);
        end if;
      end if;

      --CONTROLE CODE PAYS ADDRESSE 2
      if tdata.DIC_ADDRESS_TYPE_DESC_2 is not null then
        if tdata.PC_CNTRY_DESC_2 is not null then
          select count(PC_CNTRY_ID)
            into tmp_int
            from pcs.PC_CNTRY
           where upper(CNTID) = upper(tdata.PC_CNTRY_DESC_2);

          if tmp_int = 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_020'), '020', tdata.PC_CNTRY_DESC_2);
          end if;
        else
          IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_021'), '021', tdata.PC_CNTRY_DESC_2);
        end if;
      end if;

      --CONTROLE CODE PAYS ADDRESSE 3
      if tdata.DIC_ADDRESS_TYPE_DESC_3 is not null then
        if tdata.pc_cntry_desc_3 is not null then
          select count(pc_cntry_id)
            into tmp_int
            from pcs.pc_cntry
           where upper(cntid) = upper(tdata.pc_cntry_desc_3);

          if tmp_int = 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_020'), '020', tdata.PC_CNTRY_DESC_3);
          end if;
        else
          IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_021'), '021', tdata.PC_CNTRY_DESC_3);
        end if;
      end if;

      tmp_int  := tdata.ADD_PRINCIPAL_1 + tdata.ADD_PRINCIPAL_2 + tdata.ADD_PRINCIPAL_3;

      --CONTROLE ADRESSE PRINCIPALE (UNE SEULE ADRESSE PRINCIPALE AUTORIISEE)
      if tmp_int = 0 then
        IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_022'), '022');
      else
        if tmp_int > 1 then
          IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_023'), '023');
        end if;
      end if;

      --> Type d'adresse 1
      if tdata.DIC_ADDRESS_TYPE_DESC_1 is not null then
        IMP_PRC_TOOLS.checkDicoValue('DIC_ADDRESS_TYPE', tdata.DIC_ADDRESS_TYPE_DESC_1, lcDomain, 0, tdata.id);
      else
        if    tdata.ADD_ADDRESS1_1 is not null
           or tdata.ADD_CITY_1 is not null then
          IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_025'), '025', tdata.DIC_ADDRESS_TYPE_DESC_1);
        end if;
      end if;

      --> Type d'adresse 2
      if tdata.DIC_ADDRESS_TYPE_DESC_2 is not null then
        IMP_PRC_TOOLS.checkDicoValue('DIC_ADDRESS_TYPE', tdata.DIC_ADDRESS_TYPE_DESC_2, lcDomain, 0, tdata.id);
      else
        if    tdata.ADD_ADDRESS1_2 is not null
           or tdata.ADD_CITY_2 is not null then
          IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_025'), '025', tdata.DIC_ADDRESS_TYPE_DESC_2);
        end if;
      end if;

      --> Type d'adresse 3
      if tdata.DIC_ADDRESS_TYPE_DESC_3 is not null then
        IMP_PRC_TOOLS.checkDicoValue('DIC_ADDRESS_TYPE', tdata.DIC_ADDRESS_TYPE_DESC_3, lcDomain, 0, tdata.id);
      else
        if    tdata.ADD_ADDRESS1_3 is not null
           or tdata.ADD_CITY_3 is not null then
          IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_025'), '025', tdata.DIC_ADDRESS_TYPE_DESC_3);
        end if;
      end if;

      /* contrôle numéro CCP - ERROR 026*/
      if (    tdata.ccp is not null
          and IMP_PUBLIC.imp_CheckCCP(tdata.ccp) = 0) then
        IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_026'), '026', tdata.CCP);
      end if;

      /* contrôle numéro IBAN - ERROR 027*/
      if (    tdata.IBAN is not null
          and PAC_PARTNER_MANAGEMENT.CheckIBANNumber(replace(tdata.IBAN, ' ') ) = 0) then
        IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_027'), '027', tdata.IBAN);
      end if;

      /* contrôle numéro BVR - ERROR 028*/
      if (    tdata.BVR is not null
          and IMP_PUBLIC.imp_CheckCCP(tdata.BVR) = 0) then
        IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_028'), '028', tdata.BVR);
      end if;

      /* contrôle ADD_PO_BOX_NBR_1 champ doit être un number(9) - ERROR 029*/
      if tdata.ADD_PO_BOX_NBR_1 is not null then
        if (   pcs.pcstonumber(tdata.ADD_PO_BOX_NBR_1) is null
            or length(tdata.ADD_PO_BOX_NBR_1) > 9) then
          IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_029'), '029', tdata.ADD_PO_BOX_NBR_1);
        end if;
      end if;

      /* contrôle ADD_PO_BOX_NBR_2 champ doit être un number(9) - ERROR 030*/
      if tdata.ADD_PO_BOX_NBR_2 is not null then
        if (   pcs.pcstonumber(tdata.ADD_PO_BOX_NBR_2) is null
            or length(tdata.ADD_PO_BOX_NBR_2) > 9) then
          IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_030'), '030', tdata.ADD_PO_BOX_NBR_2);
        end if;
      end if;

      /* contrôle ADD_PO_BOX_NBR_3 champ doit être un number(9) - ERROR 031*/
      if tdata.ADD_PO_BOX_NBR_3 is not null then
        if (   pcs.pcstonumber(tdata.ADD_PO_BOX_NBR_3) is null
            or length(tdata.ADD_PO_BOX_NBR_3) > 9) then
          IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_031'), '031', tdata.ADD_PO_BOX_NBR_3);
        end if;
      end if;

      --CONTROLE TARIF CLIENT - ERROR 032
      if     tdata.CLIENT = 1
         and tdata.CUSTOM_PARTNER_DIC_TARIFF_ID is not null then
        --Controler si c'est un nouveau DIC_TARIFF
        select count(DIC_TARIFF_ID)
          into tmp_int
          from DIC_TARIFF
         where DIC_TARIFF_ID = tdata.CUSTOM_PARTNER_DIC_TARIFF_ID;

        if tmp_int = 0 then
          IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_032'), '032', tdata.CUSTOM_PARTNER_DIC_TARIFF_ID);
        end if;
      end if;

      --CONTROLE TARIF fournisseur - ERROR 033
      if     tdata.FOURNISSEUR = 1
         and tdata.SUPPLIER_PARTNER_DIC_TARIFF_ID is not null then
        --Controler si c'est un nouveau DIC_TARIFF
        select count(DIC_TARIFF_ID)
          into tmp_int
          from DIC_TARIFF
         where DIC_TARIFF_ID = tdata.SUPPLIER_PARTNER_DIC_TARIFF_ID;

        if tmp_int = 0 then
          IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_033'), '033', tdata.SUPPLIER_PARTNER_DIC_TARIFF_ID);
        end if;
      end if;

      -- Ctrl ERROR 037 - Doit correspondre à un nombre de mois sur l'année, de 0 à 12
      if nvl(tData.PER_SOC_STAT_8, 0) not between 0 and 12 then
        IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_037'), '037', tdata.PER_SOC_STAT_8);
      end if;

      -- Ctrl ERROR 038 - Si la personne est extraite pour décompte, le nombre de dossier est toujours 1
      if     (nvl(tData.PER_SOC_BREAKDOWN, 0) = 1)
         and (nvl(tData.PER_SOC_STAT_6, 0) <> 1) then
        IMP_PRC_TOOLS.insertError(lcDomain, 0, tdata.id, pcs.pc_functions.TranslateWord('IMP_PAC_038'), '038', tdata.PER_SOC_STAT_6);
      end if;

      --> Canton
      if tdata.C_EDO_CANTON is not null then
        IMP_PRC_TOOLS.checkDescodeValue('C_EDO_CANTON', tdata.C_EDO_CANTON, null, lcDomain, 0, tdata.id);
      end if;

      --> Assistant social
      if tdata.DIC_SOC_WORKER_ID is not null then
        IMP_PRC_TOOLS.checkDicoValue('DIC_SOC_WORKER', tdata.DIC_SOC_WORKER_ID, lcDomain, 0, tdata.id);
      end if;

      --> Etat civil
      if tdata.DIC_CIVIL_STATUS_ID is not null then
        IMP_PRC_TOOLS.checkDicoValue('DIC_CIVIL_STATUS', tdata.DIC_CIVIL_STATUS_ID, lcDomain, 0, tdata.id);
      end if;

      --> Extrait pour décompte social
      IMP_PRC_TOOLS.checkBooleanValue('PER_SOC_BREAKDOWN', nvl(tdata.PER_SOC_BREAKDOWN, '1'), lcDomain, 0, tdata.id);
      commit;
    end loop;

    --Si la table d'erreurs est vide, alors on insère le message repris par le pilotage de contrôle disant qu'il n'y a pas d'erreur
    IMP_PRC_TOOLS.checkErrors(lcDomain);
    commit;
  end IMP_PAC_CTRL;

  /**
  * Description
  *    Importation des données de base des partenaires
  */
  procedure IMP_PAC_IMPORT
  is
    vl_pac_payment_condition      number(12);
    vl_pac_person_id              number(12);
    vl_lang_id                    number(12);
    vl_pac_address_id             number(12);
    vl_pac_address_id_1           number(12);
    vl_pac_address_id_2           number(12);
    vl_pac_address_id_3           number(12);
    vl_dic_address_type_id_1      varchar2(10);
    vl_dic_address_type_id_2      varchar2(10);
    vl_dic_address_type_id_3      varchar2(10);
    vl_pc_cntry_id_1              number(12);
    vl_pc_cntry_id_2              number(12);
    vl_pc_cntry_id_3              number(12);
    vl_per_key1                   varchar2(20);
    vl_acs_auxiliary_account_id   number(12);
    vl_acs_sub_set_id             ACS_SUB_SET.ACS_SUB_SET_ID%type;
    VL_FIN_LOCAL_CURRENCY         number(12);
    vl_job_hist                   number(12);
    vl_pac_financial_reference_id number(12);
  begin
    --Contrôle que la table d'erreurs soit vide
    IMP_PRC_TOOLS.checkErrorsBeforeImport(lcDomain);

    select nvl(max(JOB_HIST), 0) + 1
      into vl_job_hist
      from IMP_HIST_PAC_ADDRESS;

    for tdata in (select *
                    from imp_pac_address) loop
      vl_pac_person_id  := GetNewId;

      --GENERATION CLE1
      select PCS.PC_FUNCTIONS.PCSLPAD(nvl( (select max(PER_KEY1)
                                              from PAC_PERSON), 0) + 1, length(PIC.PIC_PICTURE), 0)
        into VL_PER_KEY1
        from PAC_KEY_FORMAT F
           , ACS_PICTURE PIC
       where F.C_KEY_TYPE = 'KEY1'
         and PIC.ACS_PICTURE_ID = F.ACS_PICTURE_ID;

      --Inserer dans la table pac_person
      insert into PAC_PERSON
                  (PAC_PERSON_ID
                 , PER_SHORT_NAME
                 , DIC_PERSON_POLITNESS_ID
                 , PER_NAME
                 , PER_FORENAME
                 , PER_KEY1
                 , PER_KEY2
                 , PER_CONTACT
                 , C_PARTNER_STATUS
                 , PER_FILE_NUMBER
                 , PER_SOC_STAT_1
                 , PER_SOC_STAT_2
                 , PER_SOC_STAT_3
                 , PER_SOC_STAT_4
                 , PER_SOC_STAT_5
                 , PER_SOC_STAT_6
                 , PER_SOC_STAT_7
                 , PER_SOC_STAT_8
                 , PER_SOC_STAT_9
                 , PER_SOC_STAT_10
                 , C_EDO_CANTON
                 , DIC_SOC_WORKER_ID
                 , DIC_CIVIL_STATUS_ID
                 , PER_SOC_BREAKDOWN
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (VL_PAC_PERSON_ID
                 , upper(tdata.PER_SHORT_NAME)
                 , tdata.DIC_PERSON_POLITNESS
                 , tdata.PER_NAME
                 , tdata.PER_FORENAME
                 , VL_PER_KEY1
                 , tdata.PER_KEY2
                 , tdata.PER_CONTACT
                 , tdata.C_PARTNER_STATUS
                 , tdata.PER_FILE_NUMBER
                 , tdata.PER_SOC_STAT_1
                 , tdata.PER_SOC_STAT_2
                 , tdata.PER_SOC_STAT_3
                 , tdata.PER_SOC_STAT_4
                 , tdata.PER_SOC_STAT_5
                 , tdata.PER_SOC_STAT_6
                 , tdata.PER_SOC_STAT_7
                 , tdata.PER_SOC_STAT_8
                 , tdata.PER_SOC_STAT_9
                 , tdata.PER_SOC_STAT_10
                 , tdata.C_EDO_CANTON
                 , tdata.DIC_SOC_WORKER_ID
                 , tdata.DIC_CIVIL_STATUS_ID
                 , tdata.PER_SOC_BREAKDOWN
                 , sysdate
                 , IMP_LIB_TOOLS.getImportUserIni
                  );

      -- Langue
      select pc_lang_id
        into vl_lang_id
        from pcs.pc_lang
       where upper(lanid) = upper(tdata.pc_lang_description);

      --Type d'adresse  1
      select max(dic_address_type_id)
        into vl_dic_address_type_id_1
        from dic_address_type
       where upper(dic_address_type_id) = upper(tdata.dic_address_type_desc_1);

      if vl_dic_address_type_id_1 is not null then
        --Code pays 1
        select pc_cntry_id
          into vl_pc_cntry_id_1
          from pcs.pc_cntry
         where upper(cntid) = upper(tdata.pc_cntry_desc_1);

        --Inserer dans la table pac_person la premiere adresse
        --Récuperer ID de LA nouvelle adresse dans  vl_PAC_ADDRESS_ID
        vl_pac_address_id_1  := GetNewId;

        insert into pac_address
                    (pac_address_id
                   , pac_person_id
                   , pc_cntry_id
                   , add_address1
                   , add_zipcode
                   , add_city
                   , pc_lang_id
                   , dic_address_type_id
                   , add_principal
                   , add_care_of
                   , add_po_box
                   , add_po_box_nbr
                   , C_PARTNER_STATUS
                   , a_datecre
                   , a_idcre
                    )
             values (vl_pac_address_id_1
                   , vl_pac_person_id
                   , vl_pc_cntry_id_1
                   , tdata.add_address1_1
                   , tdata.add_zipcode_1
                   , tdata.add_city_1
                   , vl_lang_id
                   , vl_dic_address_type_id_1
                   , tdata.add_principal_1
                   , tdata.add_care_of_1
                   , tdata.add_po_box_1
                   , tdata.add_po_box_nbr_1
                   , 1
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Type d'adresse  2
      select max(dic_address_type_id)
        into vl_dic_address_type_id_2
        from dic_address_type
       where upper(dic_address_type_id) = upper(tdata.dic_address_type_desc_2);

      if vl_dic_address_type_id_2 is not null then
        --Code pays 2
        select pc_cntry_id
          into vl_pc_cntry_id_2
          from pcs.pc_cntry
         where upper(cntid) = upper(tdata.pc_cntry_desc_2);

        --Inserer la deuxième adresse
        --Récuperer ID de LA nouvelle adresse dans  vl_PAC_ADDRESS_ID
        vl_pac_address_id_2  := GetNewId;

        insert into pac_address
                    (pac_address_id
                   , pac_person_id
                   , pc_cntry_id
                   , add_address1
                   , add_zipcode
                   , add_city
                   , pc_lang_id
                   , dic_address_type_id
                   , add_principal
                   , add_care_of
                   , add_po_box
                   , add_po_box_nbr
                   , C_PARTNER_STATUS
                   , a_datecre
                   , a_idcre
                    )
             values (vl_pac_address_id_2
                   , vl_pac_person_id
                   , vl_pc_cntry_id_2
                   , tdata.add_address1_2
                   , tdata.add_zipcode_2
                   , tdata.add_city_2
                   , vl_lang_id
                   , vl_dic_address_type_id_2
                   , tdata.add_principal_2
                   , tdata.add_care_of_2
                   , tdata.add_po_box_2
                   , tdata.add_po_box_nbr_2
                   , 1
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Type d'adresse  3
      select max(dic_address_type_id)
        into vl_dic_address_type_id_3
        from dic_address_type
       where upper(dic_address_type_id) = upper(tdata.dic_address_type_desc_3);

      if vl_dic_address_type_id_3 is not null then
        --Code pays 3
        select pc_cntry_id
          into vl_pc_cntry_id_3
          from pcs.pc_cntry
         where upper(cntid) = upper(tdata.pc_cntry_desc_3);

        --Inserer la deuxième adresse
        --Récuperer ID de LA nouvelle adresse dans  vl_PAC_ADDRESS_ID
        vl_pac_address_id_3  := GetNewId;

        insert into pac_address
                    (pac_address_id
                   , pac_person_id
                   , pc_cntry_id
                   , add_address1
                   , add_zipcode
                   , add_city
                   , pc_lang_id
                   , dic_address_type_id
                   , add_principal
                   , add_care_of
                   , add_po_box
                   , add_po_box_nbr
                   , C_PARTNER_STATUS
                   , a_datecre
                   , a_idcre
                    )
             values (vl_pac_address_id_3
                   , vl_pac_person_id
                   , vl_pc_cntry_id_3
                   , tdata.add_address1_3
                   , tdata.add_zipcode_3
                   , tdata.add_city_3
                   , vl_lang_id
                   , vl_dic_address_type_id_3
                   , tdata.add_principal_3
                   , tdata.add_care_of_3
                   , tdata.add_po_box_3
                   , tdata.add_po_box_nbr_3
                   , 1
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --COMMUNICATIONS LIEES A L'ADRESSE PRINCIPALE
      if tdata.add_principal_1 = 1 then
        vl_pac_address_id  := vl_pac_address_id_1;
      elsif     tdata.add_principal_2 = 1
            and tdata.add_principal_1 <> 1 then
        vl_pac_address_id  := vl_pac_address_id_2;
      else
        vl_pac_address_id  := vl_pac_address_id_3;
      end if;

      --Communication TEL
      if tdata.com_ext_number_tel is not null then
        insert into pac_communication
                    (pac_communication_id
                   , pac_person_id
                   , pac_address_id
                   , dic_communication_type_id
                   , com_ext_number
                   , COM_AREA_CODE
                   , a_datecre
                   , a_idcre
                    )
             values (GetNewId
                   , vl_pac_person_id
                   , vl_pac_address_id
                   , 'Tel.'
                   , tdata.com_ext_number_tel
                   , tdata.COM_AREA_CODE_TEL
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Communication Natel
      if tdata.COM_EXT_NUMBER_NATEL is not null then
        insert into pac_communication
                    (pac_communication_id
                   , pac_person_id
                   , pac_address_id
                   , dic_communication_type_id
                   , com_ext_number
                   , COM_AREA_CODE
                   , a_datecre
                   , a_idcre
                    )
             values (GetNewId
                   , vl_pac_person_id
                   , vl_pac_address_id
                   , 'Natel'
                   , tdata.COM_EXT_NUMBER_NATEL
                   , tdata.COM_AREA_CODE_NATEL
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --communication Fax
      if tdata.com_ext_number_fax is not null then
        insert into pac_communication
                    (pac_communication_id
                   , pac_person_id
                   , pac_address_id
                   , dic_communication_type_id
                   , com_ext_number
                   , COM_AREA_CODE
                   , a_datecre
                   , a_idcre
                    )
             values (GetNewId
                   , vl_pac_person_id
                   , vl_pac_address_id
                   , 'Fax'
                   , tdata.com_ext_number_fax
                   , tdata.COM_AREA_CODE_FAX
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --communication  E-MAIL
      if tdata.com_ext_number_email is not null then
        insert into pac_communication
                    (pac_communication_id
                   , pac_person_id
                   , pac_address_id
                   , dic_communication_type_id
                   , com_ext_number
                   , a_datecre
                   , a_idcre
                    )
             values (GetNewId
                   , vl_pac_person_id
                   , vl_pac_address_id
                   , 'E-Mail'
                   , tdata.com_ext_number_email
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Création du pac_third si client ou fournisseur
      if (   tdata.client = 1
          or tdata.fournisseur = 1) then
        insert into PAC_THIRD
                    (PAC_THIRD_ID
                   , THI_NO_TVA
                   , THI_NO_INTRA
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (vl_pac_person_id
                   , tdata.THI_NO_TVA
                   , tdata.THI_NO_INTRA
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );

        --MONNAIE DE BASE
        select ACS_FINANCIAL_CURRENCY_ID
          into VL_FIN_LOCAL_CURRENCY
          from acs_financial_currency
         where FIN_LOCAL_CURRENCY = 1;

        if tdata.CLIENT = 1 then
          if tdata.CUSTOM_PAYMENT_CONDITION_DESC is not null then
            select PAC_PAYMENT_CONDITION_ID
              into VL_PAC_PAYMENT_CONDITION
              from PAC_PAYMENT_CONDITION
             where trim(upper(PCO_DESCR) ) = trim(upper(tdata.CUSTOM_PAYMENT_CONDITION_DESC) );
          else
            select PAC_PAYMENT_CONDITION_ID
              into VL_PAC_PAYMENT_CONDITION
              from PAC_PAYMENT_CONDITION
             where PCO_DEFAULT = 1;
          end if;

          --RECHERCHE SUB_SET_ID
          if tdata.CUS_SUB_SET_ID is not null then
            select   ACS_SUB_SET.ACS_SUB_SET_ID
                into vl_acs_sub_set_id
                from ACS_SUB_SET
                   , ACS_DESCRIPTION
               where ACS_SUB_SET.ACS_SUB_SET_ID = ACS_DESCRIPTION.ACS_SUB_SET_ID
                 and C_TYPE_SUB_SET = 'AUX'
                 and C_SUB_SET = 'REC'
                 and upper(DES_DESCRIPTION_SUMMARY) = trim(upper(tdata.CUS_SUB_SET_ID) )
            group by ACS_SUB_SET.ACS_SUB_SET_ID;
          else
            select ACS_SUB_SET.ACS_SUB_SET_ID
              into vl_acs_sub_set_id
              from ACS_SUB_SET
             where C_TYPE_SUB_SET = 'AUX'
               and C_SUB_SET = 'REC'
               and ACS_SUB_SET.SSE_DEFAULT = 1;
          end if;

          VL_ACS_AUXILIARY_ACCOUNT_ID  := 0;
          PAC_PARTNER_MANAGEMENT.CreateAuxiliaryAccount(vl_pac_person_id, vl_acs_sub_set_id, 2, VL_FIN_LOCAL_CURRENCY, null, vl_acs_auxiliary_account_id);

          update ACS_AUXILIARY_ACCOUNT
             set C_TYPE_ACCOUNT = 'PRI'
           where ACS_AUXILIARY_ACCOUNT_ID = vl_acs_auxiliary_account_id;

          -- MONNAIES ETRANGERES
          insert into ACS_AUX_ACCOUNT_S_FIN_CURR
                      (ACS_AUXILIARY_ACCOUNT_ID
                     , ACS_FINANCIAL_CURRENCY_ID
                      )
            (select VL_ACS_AUXILIARY_ACCOUNT_ID
                  , ACS_FINANCIAL_CURRENCY_ID
               from ACS_FINANCIAL_CURRENCY
              where (    FIN_LOCAL_CURRENCY <> 1
                     and PC_CURR_ID = (select PC_CURR_ID
                                         from PCS.PC_CURR
                                        where CURRENCY = tdata.ACS_FINANCIAL_CURRENCY_DESC) ) );

          insert into pac_custom_partner
                      (pac_custom_partner_id
                     , DIC_TYPE_SUBMISSION_ID
                     , pac_payment_condition_id
                     , c_remainder_launching
                     , acs_vat_det_account_id
                     , C_TARIFFICATION_MODE
                     , C_PARTNER_CATEGORY
                     , C_PARTNER_STATUS
                     , C_TYPE_EDI
                     , A_CONFIRM
                     , a_datecre
                     , a_idcre
                     , CUS_SUP_COPY1
                     , CUS_SUP_COPY2
                     , CUS_SUP_COPY3
                     , CUS_SUP_COPY4
                     , CUS_SUP_COPY5
                     , CUS_SUP_COPY6
                     , CUS_SUP_COPY7
                     , CUS_SUP_COPY8
                     , CUS_SUP_COPY9
                     , CUS_SUP_COPY10
                     , CUS_PERIODIC_INVOICING
                     , CUS_PERIODIC_DELIVERY
                     , C_RESERVATION_TYP
                     , CUS_ADV_MATERIAL_MGNT
                     , CUS_TARIFF_BY_SET
                     , CUS_METAL_ACCOUNT
                     , CUS_NO_REM_CHARGE
                     , CUS_NO_MORATORIUM_INTEREST
                     , C_BVR_GENERATION_METHOD
                     , acs_auxiliary_account_id
                     , pac_remainder_category_id
                     , pac_schedule_id
                     , DIC_TARIFF_ID
                      )
               values (vl_pac_person_id
                     , tdata.DIC_TYPE_SUBMISSION_DESCRI
                     , vl_pac_payment_condition
                     , 'AUTO'
                     , (select acs_vat_det_account_id
                          from acs_vat_det_account
                         where vde_default = 1)
                     , 1
                     , 1
                     , tdata.C_PARTNER_STATUS
                     , 0
                     , 0
                     , sysdate
                     , IMP_LIB_TOOLS.getImportUserIni
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , '03'
                     , vl_acs_auxiliary_account_id
                     , (select pac_remainder_category_id
                          from pac_remainder_category
                         where pac_remainder_category.rca_default = 1)
                     , ( (select pac_schedule_id
                            from pac_schedule
                           where sce_default = 1) )
                     , tdata.CUSTOM_PARTNER_DIC_TARIFF_ID
                      );

          /*Référence financière - CCP*/
          if tdata.CCP is not null then
            insert into PAC_FINANCIAL_REFERENCE
                        (C_TYPE_REFERENCE
                       , FRE_ACCOUNT_NUMBER
                       , C_PARTNER_STATUS
                       , FRE_DEFAULT
                       , FRE_REF_CONTROL
                       , PC_CNTRY_ID
                       , A_IDCRE
                       , A_DATECRE
                       , PAC_CUSTOM_PARTNER_ID
                       , PAC_FINANCIAL_REFERENCE_ID
                        )
                 values (2
                       , tdata.CCP
                       , 1
                       , 0
                       , 0
                       , 1
                       ,   -- à CHANGER
                         IMP_LIB_TOOLS.getImportUserIni
                       , sysdate
                       , vl_pac_person_id
                       , GetNewId
                        );
          end if;

          if tdata.BVR is not null then
            insert into PAC_FINANCIAL_REFERENCE
                        (C_TYPE_REFERENCE
                       , FRE_ACCOUNT_NUMBER
                       , C_PARTNER_STATUS
                       , FRE_DEFAULT
                       , FRE_REF_CONTROL
                       , A_IDCRE
                       , A_DATECRE
                       , PAC_CUSTOM_PARTNER_ID   -- pac_custom_partner_id
                       , PAC_FINANCIAL_REFERENCE_ID
                        )
                 values (3
                       , tdata.BVR
                       , 1
                       , 0
                       , 0
                       , IMP_LIB_TOOLS.getImportUserIni
                       , sysdate
                       , vl_pac_person_id
                       , GetNewId
                        );
          end if;

          --IBAN
          if tdata.IBAN is not null then
            insert into PAC_FINANCIAL_REFERENCE
                        (C_TYPE_REFERENCE
                       , FRE_ACCOUNT_NUMBER
                       , C_PARTNER_STATUS
                       , FRE_DEFAULT
                       , FRE_REF_CONTROL
                       , PC_CNTRY_ID
                       , A_IDCRE
                       , A_DATECRE
                       , PAC_CUSTOM_PARTNER_ID
                       , PAC_FINANCIAL_REFERENCE_ID
                        )
                 values (5
                       , replace(tdata.IBAN, ' ')
                       , 1
                       , 0
                       , 0
                       , 1
                       , IMP_LIB_TOOLS.getImportUserIni
                       , sysdate
                       , vl_pac_person_id
                       , GetNewId
                        );
          end if;
        end if;

        if tdata.fournisseur = 1 then
          if tdata.SUPPLIER_PAYMENT_CONDITION_DES is not null then
            select PAC_PAYMENT_CONDITION_ID
              into VL_PAC_PAYMENT_CONDITION
              from PAC_PAYMENT_CONDITION
             where trim(upper(PCO_DESCR) ) = trim(upper(tdata.SUPPLIER_PAYMENT_CONDITION_DES) );
          else
            select PAC_PAYMENT_CONDITION_ID
              into VL_PAC_PAYMENT_CONDITION
              from PAC_PAYMENT_CONDITION
             where PCO_DEFAULT_PAY = 1;
          end if;

          --recherche sub_set_id
          if tdata.SUP_SUB_SET_ID is not null then
            select   ACS_SUB_SET.ACS_SUB_SET_ID
                into vl_acs_sub_set_id
                from ACS_SUB_SET
                   , ACS_DESCRIPTION
               where ACS_SUB_SET.ACS_SUB_SET_ID = ACS_DESCRIPTION.ACS_SUB_SET_ID
                 and C_TYPE_SUB_SET = 'AUX'
                 and C_SUB_SET = 'PAY'
                 and upper(DES_DESCRIPTION_SUMMARY) = trim(upper(tdata.SUP_SUB_SET_ID) )
            group by ACS_SUB_SET.ACS_SUB_SET_ID;
          else
            select ACS_SUB_SET.ACS_SUB_SET_ID
              into vl_acs_sub_set_id
              from ACS_SUB_SET
             where C_TYPE_SUB_SET = 'AUX'
               and C_SUB_SET = 'PAY'
               and ACS_SUB_SET.SSE_DEFAULT = 1;
          end if;

          vl_acs_auxiliary_account_id  := 0;
          PAC_PARTNER_MANAGEMENT.CreateAuxiliaryAccount(vl_pac_person_id, vl_acs_sub_set_id, 2, VL_FIN_LOCAL_CURRENCY, null, vl_acs_auxiliary_account_id);

          update ACS_AUXILIARY_ACCOUNT
             set C_TYPE_ACCOUNT = 'PRI'
           where ACS_AUXILIARY_ACCOUNT_ID = vl_acs_auxiliary_account_id;

          -- CREATION MONNAIES ETRANGERES
          insert into acs_aux_account_s_fin_curr
                      (acs_auxiliary_account_id
                     , acs_financial_currency_id
                      )
            (select vl_acs_auxiliary_account_id
                  , acs_financial_currency_id
               from acs_financial_currency
              where (    fin_local_currency <> 1
                     and pc_curr_id = (select pc_curr_id
                                         from pcs.pc_curr
                                        where currency = tdata.acs_financial_currency_desc) ) );

          --Inserer les données dans la table PAC_SUPPLIER_PARTNER
          insert into pac_supplier_partner
                      (pac_supplier_partner_id
                     , DIC_TYPE_SUBMISSION_ID
                     , PAC_REMAINDER_CATEGORY_ID
                     , pac_payment_condition_id
                     , acs_auxiliary_account_id
                     , c_remainder_launching
                     , acs_vat_det_account_id
                     , C_TARIFFICATION_MODE
                     , C_PARTNER_CATEGORY
                     , C_TYPE_EDI
                     , A_CONFIRM
                     , CRE_SUP_COPY1
                     , CRE_SUP_COPY2
                     , CRE_SUP_COPY3
                     , CRE_SUP_COPY4
                     , CRE_SUP_COPY5
                     , C_STATUS_SETTLEMENT
                     , C_PARTNER_STATUS
                     , CRE_SUP_COPY6
                     , CRE_SUP_COPY7
                     , CRE_SUP_COPY8
                     , CRE_SUP_COPY9
                     , CRE_SUP_COPY10
                     , CRE_MANUFACTURER
                     , CRE_ADV_MATERIAL_MGNT
                     , CRE_TARIFF_BY_SET
                     , CRE_METAL_ACCOUNT
                     , a_datecre
                     , a_idcre
                     , pac_schedule_id
                     , DIC_TARIFF_ID
                      )
               values (vl_pac_person_id
                     , tdata.DIC_TYPE_SUBMISSION_DESCRI
                     , (select pac_remainder_category_id
                          from pac_remainder_category
                         where pac_remainder_category.rca_default = 1)
                     , vl_pac_payment_condition
                     , vl_acs_auxiliary_account_id
                     , 'AUTO'
                     , (select acs_vat_det_account_id
                          from acs_vat_det_account
                         where vde_default = 1)
                     , 1
                     , 1
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , tdata.C_PARTNER_STATUS
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , 0
                     , sysdate
                     , IMP_LIB_TOOLS.getImportUserIni
                     , (select pac_schedule_id
                          from pac_schedule
                         where sce_default = 1)
                     , tdata.SUPPLIER_PARTNER_DIC_TARIFF_ID
                      );

          /*Référence financière - CCP*/
          if tdata.CCP is not null then
            insert into PAC_FINANCIAL_REFERENCE
                        (C_TYPE_REFERENCE
                       , FRE_ACCOUNT_NUMBER
                       , C_PARTNER_STATUS
                       , FRE_DEFAULT
                       , FRE_REF_CONTROL
                       , PC_CNTRY_ID
                       , A_IDCRE
                       , A_DATECRE
                       , PAC_SUPPLIER_PARTNER_ID
                       , PAC_FINANCIAL_REFERENCE_ID
                        )
                 values (2
                       , tdata.CCP
                       , 1
                       , 0
                       , 0
                       , 1
                       ,   -- à CHANGER
                         IMP_LIB_TOOLS.getImportUserIni
                       , sysdate
                       , vl_pac_person_id
                       , GetNewId
                        );
          end if;

          if tdata.BVR is not null then
            insert into PAC_FINANCIAL_REFERENCE
                        (C_TYPE_REFERENCE
                       , FRE_ACCOUNT_NUMBER
                       , C_PARTNER_STATUS
                       , FRE_DEFAULT
                       , FRE_REF_CONTROL
                       , A_IDCRE
                       , A_DATECRE
                       , PAC_SUPPLIER_PARTNER_ID   -- pac_custom_partner_id
                       , PAC_FINANCIAL_REFERENCE_ID
                        )
                 values (3
                       , tdata.BVR
                       , 1
                       , 0
                       , 0
                       , IMP_LIB_TOOLS.getImportUserIni
                       , sysdate
                       , vl_pac_person_id
                       , GetNewId
                        );
          end if;

          --IBAN
          if tdata.IBAN is not null then
            insert into PAC_FINANCIAL_REFERENCE
                        (C_TYPE_REFERENCE
                       , FRE_ACCOUNT_NUMBER
                       , C_PARTNER_STATUS
                       , FRE_DEFAULT
                       , FRE_REF_CONTROL
                       , PC_CNTRY_ID
                       , A_IDCRE
                       , A_DATECRE
                       , PAC_SUPPLIER_PARTNER_ID
                       , PAC_FINANCIAL_REFERENCE_ID
                        )
                 values (5
                       , replace(tdata.IBAN, ' ')
                       , 1
                       , 0
                       , 0
                       , 1
                       , IMP_LIB_TOOLS.getImportUserIni
                       , sysdate
                       , vl_pac_person_id
                       , GetNewId
                        );
          end if;
        end if;
      end if;

      /*INSERTION DANS TABLE HISTORIQUE*/
      insert into IMP_HIST_PAC_ADDRESS
                  (ID_HIST
                 , DATE_HIST
                 , JOB_HIST
                 , EXCEL_LINE
                 , PAC_ADDRESS_ID
                 , PAC_PERSON_ID
                 , DIC_PERSON_POLITNESS
                 , PER_NAME
                 , PER_FORENAME
                 , PER_SHORT_NAME
                 , PER_CONTACT
                 , PER_KEY2
                 , CLIENT
                 , FOURNISSEUR
                 , C_PARTNER_STATUS
                 , CUS_SUB_SET_ID
                 , SUP_SUB_SET_ID
                 , PC_LANG_DESCRIPTION
                 , ACS_FINANCIAL_CURRENCY_DESC
                 , DIC_TYPE_SUBMISSION_DESCRI
                 , THI_NO_TVA
                 , THI_NO_INTRA
                 , CUSTOM_PAYMENT_CONDITION_DESC
                 , SUPPLIER_PAYMENT_CONDITION_DES
                 , CUSTOM_PARTNER_DIC_TARIFF_ID
                 , SUPPLIER_PARTNER_DIC_TARIFF_ID
                 , COM_AREA_CODE_TEL
                 , COM_EXT_NUMBER_TEL
                 , COM_AREA_CODE_NATEL
                 , COM_EXT_NUMBER_NATEL
                 , COM_AREA_CODE_FAX
                 , COM_EXT_NUMBER_FAX
                 , COM_EXT_NUMBER_EMAIL
                 , DIC_ADDRESS_TYPE_DESC_1
                 , ADD_PRINCIPAL_1
                 , ADD_CARE_OF_1
                 , ADD_ADDRESS1_1
                 , ADD_PO_BOX_1
                 , ADD_PO_BOX_NBR_1
                 , ADD_ZIPCODE_1
                 , ADD_CITY_1
                 , ADD_COUNTY_1
                 , PC_CNTRY_DESC_1
                 , DIC_ADDRESS_TYPE_DESC_2
                 , ADD_PRINCIPAL_2
                 , ADD_CARE_OF_2
                 , ADD_ADDRESS1_2
                 , ADD_PO_BOX_2
                 , ADD_PO_BOX_NBR_2
                 , ADD_ZIPCODE_2
                 , ADD_CITY_2
                 , ADD_COUNTY_2
                 , PC_CNTRY_DESC_2
                 , DIC_ADDRESS_TYPE_DESC_3
                 , ADD_PRINCIPAL_3
                 , ADD_CARE_OF_3
                 , ADD_ADDRESS1_3
                 , ADD_PO_BOX_3
                 , ADD_PO_BOX_NBR_3
                 , ADD_ZIPCODE_3
                 , ADD_CITY_3
                 , ADD_COUNTY_3
                 , PC_CNTRY_DESC_3
                 , FREE1
                 , FREE2
                 , FREE3
                 , FREE4
                 , FREE5
                 , FREE6
                 , FREE7
                 , FREE8
                 , FREE9
                 , FREE10
                 , PER_FILE_NUMBER
                 , PER_SOC_STAT_1
                 , PER_SOC_STAT_2
                 , PER_SOC_STAT_3
                 , PER_SOC_STAT_4
                 , PER_SOC_STAT_5
                 , PER_SOC_STAT_6
                 , PER_SOC_STAT_7
                 , PER_SOC_STAT_8
                 , PER_SOC_STAT_9
                 , PER_SOC_STAT_10
                 , C_EDO_CANTON
                 , DIC_SOC_WORKER_ID
                 , DIC_CIVIL_STATUS_ID
                 , PER_SOC_BREAKDOWN
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , sysdate
                 , vl_job_hist
                 , tdata.id
                 , tdata.PAC_ADDRESS_ID
                 , VL_PAC_PERSON_ID
                 , tdata.DIC_PERSON_POLITNESS
                 , tdata.PER_NAME
                 , tdata.PER_FORENAME
                 , tdata.PER_SHORT_NAME
                 , tdata.PER_CONTACT
                 , tdata.PER_KEY2
                 , tdata.CLIENT
                 , tdata.FOURNISSEUR
                 , tdata.C_PARTNER_STATUS
                 , tdata.CUS_SUB_SET_ID
                 , tdata.SUP_SUB_SET_ID
                 , tdata.PC_LANG_DESCRIPTION
                 , tdata.ACS_FINANCIAL_CURRENCY_DESC
                 , tdata.DIC_TYPE_SUBMISSION_DESCRI
                 , tdata.THI_NO_TVA
                 , tdata.THI_NO_INTRA
                 , tdata.CUSTOM_PAYMENT_CONDITION_DESC
                 , tdata.SUPPLIER_PAYMENT_CONDITION_DES
                 , tdata.CUSTOM_PARTNER_DIC_TARIFF_ID
                 , tdata.SUPPLIER_PARTNER_DIC_TARIFF_ID
                 , tdata.COM_AREA_CODE_TEL
                 , tdata.COM_EXT_NUMBER_TEL
                 , tdata.COM_AREA_CODE_NATEL
                 , tdata.COM_EXT_NUMBER_NATEL
                 , tdata.COM_AREA_CODE_FAX
                 , tdata.COM_EXT_NUMBER_FAX
                 , tdata.COM_EXT_NUMBER_EMAIL
                 , tdata.DIC_ADDRESS_TYPE_DESC_1
                 , tdata.ADD_PRINCIPAL_1
                 , tdata.ADD_CARE_OF_1
                 , tdata.ADD_ADDRESS1_1
                 , tdata.ADD_PO_BOX_1
                 , tdata.ADD_PO_BOX_NBR_1
                 , tdata.ADD_ZIPCODE_1
                 , tdata.ADD_CITY_1
                 , tdata.ADD_COUNTY_1
                 , tdata.PC_CNTRY_DESC_1
                 , tdata.DIC_ADDRESS_TYPE_DESC_2
                 , tdata.ADD_PRINCIPAL_2
                 , tdata.ADD_CARE_OF_2
                 , tdata.ADD_ADDRESS1_2
                 , tdata.ADD_PO_BOX_2
                 , tdata.ADD_PO_BOX_NBR_2
                 , tdata.ADD_ZIPCODE_2
                 , tdata.ADD_CITY_2
                 , tdata.ADD_COUNTY_2
                 , tdata.PC_CNTRY_DESC_2
                 , tdata.DIC_ADDRESS_TYPE_DESC_3
                 , tdata.ADD_PRINCIPAL_3
                 , tdata.ADD_CARE_OF_3
                 , tdata.ADD_ADDRESS1_3
                 , tdata.ADD_PO_BOX_3
                 , tdata.ADD_PO_BOX_NBR_3
                 , tdata.ADD_ZIPCODE_3
                 , tdata.ADD_CITY_3
                 , tdata.ADD_COUNTY_3
                 , tdata.PC_CNTRY_DESC_3
                 , tdata.FREE1
                 , tdata.FREE2
                 , tdata.FREE3
                 , tdata.FREE4
                 , tdata.FREE5
                 , tdata.FREE6
                 , tdata.FREE7
                 , tdata.FREE8
                 , tdata.FREE9
                 , tdata.FREE10
                 , tdata.PER_FILE_NUMBER
                 , tdata.PER_SOC_STAT_1
                 , tdata.PER_SOC_STAT_2
                 , tdata.PER_SOC_STAT_3
                 , tdata.PER_SOC_STAT_4
                 , tdata.PER_SOC_STAT_5
                 , tdata.PER_SOC_STAT_6
                 , tdata.PER_SOC_STAT_7
                 , tdata.PER_SOC_STAT_8
                 , tdata.PER_SOC_STAT_9
                 , tdata.PER_SOC_STAT_10
                 , tdata.C_EDO_CANTON
                 , tdata.DIC_SOC_WORKER_ID
                 , tdata.DIC_CIVIL_STATUS_ID
                 , tdata.PER_SOC_BREAKDOWN
                 , sysdate
                 , pcs.PC_I_LIB_SESSION.GetUserIni
                  );
    end loop;
  end IMP_PAC_IMPORT;
end IMP_PAC;
