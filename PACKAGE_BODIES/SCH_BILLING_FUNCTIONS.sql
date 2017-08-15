--------------------------------------------------------
--  DDL for Package Body SCH_BILLING_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SCH_BILLING_FUNCTIONS" 
is
  /**
  * function GetAddressType
  * Description : Recherche du type de l'adresse de facturation
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iDocGaugeId : Gabarit
  */
  function GetAddressType(iDocGaugeId in number)
    return varchar2
  is
    result varchar2(10);
  begin
    select GAU.DIC_ADDRESS_TYPE_ID
      into result
      from DOC_GAUGE GAU
     where GAU.DOC_GAUGE_ID = iDocGaugeId;

    return result;
  exception
    when others then
      return '';
  end GetAddressType;

  /**
  * procedure GetCDAIndiv
  * Description : Recherche indiv du centre d'analyse pour facturation
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   lcSchPrcGetCdaIndiv : Procedure indiv
  * @param   iSCH_STUDENT_ID : Résident
  * @param   iSCH_OUTLAY_ID : Prestation
  * @param   iSCH_OUTLAY_CATEGORY : Catégorie de prestation
  * @param   iPAC_CUSTOM_PARTNER_ID : Client
  * @param   iValueDate : Date valeur
  * @param   iSCH_ENTERED_OUTLAY_ID : Lign de débours saisis
  * @param   ioACS_CDA_ACCOUNT_ID : Centre d'analyse
  * @param   ioExecStandard : Exécution standard
  */
  procedure GetCDAIndiv(
    lcSchPrcGetCdaIndiv     in     varchar2
  , iSCH_STUDENT_ID         in     number
  , iSCH_OUTLAY_ID          in     number
  , iSCH_OUTLAY_CATEGORY_ID in     number
  , iPAC_CUSTOM_PARTNER_ID  in     number
  , iValueDate              in     date
  , iSCH_ENTERED_OUTLAY_ID  in     number default null
  , ioACS_CDA_ACCOUNT_ID    in out number
  , ioExecStandard          in out integer
  )
  is
    lvPrcSql varchar2(2000);
  begin
    lvPrcSql  := ' begin ';
    lvPrcSql  :=
      lvPrcSql ||
      lcSchPrcGetCdaIndiv ||
      '(:iSCH_STUDENT_ID,' ||
      ' :iSCH_OUTLAY_ID,' ||
      ' :iSCH_OUTLAY_CATEGORY_ID,' ||
      ' :iPAC_CUSTOM_PARTNER_ID,' ||
      ' :iValueDate,' ||
      ' :iSCH_ENTERED_OUTLAY_ID,' ||
      ' :ioACS_CDA_ACCOUNT_ID,' ||
      ' :ioExecStandard);';
    lvPrcSql  := lvPrcSql || ' end; ';

    execute immediate lvPrcSql
                using in     iSCH_STUDENT_ID
                    , in     iSCH_OUTLAY_ID
                    , in     iSCH_OUTLAY_CATEGORY_ID
                    , in     iPAC_CUSTOM_PARTNER_ID
                    , in     iValueDate
                    , in     iSCH_ENTERED_OUTLAY_ID
                    , in out ioACS_CDA_ACCOUNT_ID
                    , in out ioExecStandard;
  end GetCDAIndiv;

  /**
  * procedure GetCDAIndiv
  * Description : Recherche indiv du centre d'analyse pour facturation
  *               pour le filtre de recherche
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   lcSchPrcGetCdaIndiv : Procedure indiv
  * @param   iLPM_ENTERED_OUTLAY_ID : Dépenses d'entrée
  * @param   iSCH_ENTERED_OUTLAY_ID : Ligne de débours saisies
  * @param   iSCH_BILL_HEADER_ID    : Entête facture d'écolage
  * @param   ioACS_CDA_ACCOUNT_ID : Centre d'analyse
  * @param   ioExecStandard : Exécution standard
  */
  procedure GetFilterCDAIndiv(
    lcSchPrcGetCdaIndiv    in     varchar2
  , iLPM_ENTERED_OUTLAY_ID in     number default null
  , iSCH_ENTERED_OUTLAY_ID in     number default null
  , iSCH_BILL_HEADER_ID    in     number default null
  , ioACS_CDA_ACCOUNT_ID   in out number
  , ioExecStandard         in out integer
  )
  is
    lvPrcSql varchar2(2000);
  begin
    lvPrcSql  := ' begin ';
    lvPrcSql  :=
      lvPrcSql ||
      lcSchPrcGetCdaIndiv ||
      '(:iLPM_ENTERED_OUTLAY_ID,' ||
      ' :iSCH_ENTERED_OUTLAY_ID,' ||
      ' :iSCH_BILL_HEADER_ID,' ||
      ' :ioACS_CDA_ACCOUNT_ID,' ||
      ' :ioExecStandard);';
    lvPrcSql  := lvPrcSql || ' end; ';

    execute immediate lvPrcSql
                using in iLPM_ENTERED_OUTLAY_ID, in iSCH_ENTERED_OUTLAY_ID, in iSCH_BILL_HEADER_ID, in out ioACS_CDA_ACCOUNT_ID, in out ioExecStandard;
  end GetFilterCDAIndiv;

  /**
  * function InsertBillHeader
  * Description : Génération d'une entête de facture
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aHEA_ECOLAGE  : 1 => Facture d'écolage; 0 => Facture de débours
  * @param   aSCH_STUDENT_ID : Elève
  * @param   aPAC_CUSTOM_PARTNER_ID : Débiteur
  * @param   aACS_VAT_DET_ACCOUNT_ID    : Décompte TVA
  * @param   aACS_FIN_ACC_S_PAYMENT_ID  : Compte
  * @param   aDIC_TYPE_SUBMISSION_ID    : Type soumission
  * @param   aACS_FINANCIAL_CURRENCY_ID : Monnaie
  * @param   aDOC_GAUGE_ID              : Gabarit
  * @param   aSCH_GROUP_YEAR_PERIOD_ID  : group de période
  * @param   aWithOtherAddress          : utilisation pour lr débiteur de l'adresse
  *          autre spécifiée sur la fiche élève.
  * @param   aPER_KEY1                  : Clef 1 débiteur
  * @param   aC_GROUPING_MODE           : un doc par débiteur ou pas débiteur / élève
  * @param   aPAC_PAYMENT_CONDITION_ID  : Condition de paiement
  * @param   iBillingdate               : date de facturation
  * @param   iValueDate                 : Date valeur
  */
  function InsertBillHeader(
    aHEA_ECOLAGE               in integer
  , aSCH_STUDENT_ID            in number
  , aSTU_ACCOUNT_NUMBER        in integer
  , aPAC_CUSTOM_PARTNER_ID     in number
  , aACS_VAT_DET_ACCOUNT_ID    in number
  , aACS_FIN_ACC_S_PAYMENT_ID  in number
  , aDIC_TYPE_SUBMISSION_ID    in varchar2
  , aACS_FINANCIAL_CURRENCY_ID in number
  , aDOC_GAUGE_ID              in number
  , aSCH_GROUP_YEAR_PERIOD_ID  in number
  , aWithOtherAddress          in integer
  , aPER_KEY1                  in varchar2
  , aC_GROUPING_MODE           in varchar2
  , aPAC_PAYMENT_CONDITION_ID  in number default null
  , iBillingdate               in date default sysdate
  , iValueDate                 in date default sysdate
  )
    return number
  is
    -- Curseur sur le PAC_ADDRESS
    cursor crPacAddress(aPAC_PERSON_ID number)
    is
      select PP.PER_NAME
           , PP.PER_FORENAME
           , PP.DIC_PERSON_POLITNESS_ID
           , PA.PAC_ADDRESS_ID
           , PA.ADD_ADDRESS1
           , PA.ADD_ZIPCODE
           , PA.ADD_CITY
           , PA.ADD_COMMENT
           , PCL.LANNAME
           , PCL.LANID
           , PCL.PC_LANG_ID
           , PA.ADD_STATE
           , PC.CNTNAME
           , PC.CNTID
           , PC.PC_CNTRY_ID
           , (SCH_TOOLS.GETDICODESCR('DIC_PERSON_POLITNESS', DIC_PERSON_POLITNESS_ID, PCS.PC_I_LIB_SESSION.GETUSERLANGID) ) DPO_DESCR
        from PAC_PERSON PP
           , PAC_ADDRESS PA
           , PCS.PC_CNTRY PC
           , PCS.PC_LANG PCL
       where (PP.PAC_PERSON_ID = PA.PAC_PERSON_ID(+))
         and (PA.PC_CNTRY_ID = PC.PC_CNTRY_ID(+))
         and (   PA.PAC_ADDRESS_ID is null
              or PA.DIC_ADDRESS_TYPE_ID = GetAddressType(aDOC_GAUGE_ID) )
         and (PP.PAC_PERSON_ID = aPAC_PERSON_ID)
         and (PA.PC_LANG_ID = PCL.PC_LANG_ID(+));

    -- Curseur sur la table adresse des étudiants.
    cursor crSchStudentAddress(aSCH_STUDENT_ID number)
    is
      select SS.*
           , L.LANNAME
           , L.LANID
           , C.CNTNAME
           , C.CNTID
           , (SCH_TOOLS.GETDICODESCR('DIC_PERSON_POLITNESS', DIC_PERSON_POLITNESS_ID, PCS.PC_I_LIB_SESSION.GETUSERLANGID) ) DPO_DESCR
        from SCH_STUDENT_ADDRESS SS
           , PCS.PC_LANG L
           , PCS.PC_CNTRY C
       where SCH_STUDENT_ID = aSCH_STUDENT_ID
         and SS.PC_LANG_ID = L.PC_LANG_ID(+)
         and SS.PC_CNTRY_ID = C.PC_CNTRY_ID(+);

    -- Variables
    VarPAC_ADDRESS_ID          number;
    VarDIC_PERSON_POLITNESS_ID varchar2(10);
    VarPC_LANG_ID              number;
    VarPC_CNTRY_ID             number;
    VarPERSON_POLITNESS        varchar2(50);
    VarNAME                    varchar2(60);
    VarFORENAME                varchar2(60);
    VarLANGID                  varchar2(2);
    VarCNTID                   varchar2(5);
    VarADDRESS                 varchar2(255);
    VarZIPCODE                 PAC_ADDRESS.ADD_ZIPCODE%type;
    VarCITY                    varchar2(30);
    VarSTATE                   varchar2(30);
    VarCOMMENT                 varchar2(2000);
    VarLANNAME                 varchar2(20);
    VarCNTNAME                 varchar2(30);
    VarHEA_NUMBER              varchar2(30);
    VarSCH_BILL_HEADER_ID      number;
  begin
    -- Situation de facturation "autre", la facture est adressée au débiteur,
    -- à l'adresse autre de la fiche élève
    if aWithOtherAddress = 1 then
      VarPAC_ADDRESS_ID  := null;

      for tplSchStudentAddress in crSchStudentAddress(aSCH_STUDENT_ID) loop
        VarDIC_PERSON_POLITNESS_ID  := tplSchStudentAddress.DIC_PERSON_POLITNESS_ID;
        VarPC_LANG_ID               := tplSchStudentAddress.PC_LANG_ID;
        VarPC_CNTRY_ID              := tplSchStudentAddress.PC_CNTRY_ID;
        VarPERSON_POLITNESS         := tplSchStudentAddress.DPO_DESCR;
        VarNAME                     := tplSchStudentAddress.ADD_NAME;
        VarFORENAME                 := tplSchStudentAddress.ADD_FORENAME;
        VarLANGID                   := tplSchStudentAddress.LANID;
        VarCNTID                    := tplSchStudentAddress.CNTID;
        VarLANNAME                  := tplSchStudentAddress.LANNAME;
        VarCNTNAME                  := tplSchStudentAddress.CNTNAME;
        VarADDRESS                  := tplSchStudentAddress.ADD_ADDRESS;
        VarZIPCODE                  := tplSchStudentAddress.ADD_ZIPCODE;
        VarCITY                     := tplSchStudentAddress.ADD_CITY;
        VarSTATE                    := tplSchStudentAddress.ADD_STATE;
        VarCOMMENT                  := '';
        exit;
      end loop;
    -- l'adresse de facturation est bien celle du débiteur
    else
      for tplPacAddress in crPacAddress(aPAC_CUSTOM_PARTNER_ID) loop
        VarPAC_ADDRESS_ID           := tplPacAddress.PAC_ADDRESS_ID;
        VarDIC_PERSON_POLITNESS_ID  := tplPacAddress.DIC_PERSON_POLITNESS_ID;
        VarPC_LANG_ID               := tplPacAddress.PC_LANG_ID;
        VarPC_CNTRY_ID              := tplPacAddress.PC_CNTRY_ID;
        VarPERSON_POLITNESS         := tplPacAddress.DPO_DESCR;
        VarNAME                     := tplPacAddress.PER_NAME;
        VarFORENAME                 := tplPacAddress.PER_FORENAME;
        VarLANGID                   := tplPacAddress.LANID;
        VarCNTID                    := tplPacAddress.CNTID;
        VarLANNAME                  := tplPacAddress.LANNAME;
        VarCNTNAME                  := tplPacAddress.CNTNAME;
        VarADDRESS                  := tplPacAddress.ADD_ADDRESS1;
        VarZIPCODE                  := tplPacAddress.ADD_ZIPCODE;
        VarCITY                     := tplPacAddress.ADD_CITY;
        VarSTATE                    := tplPacAddress.ADD_STATE;
        VarCOMMENT                  := tplPacAddress.ADD_COMMENT;
        exit;
      end loop;
    end if;

    -- Récupération nouveau numéro de facture
    VarHEA_NUMBER          := GetNewHeaNumber(aHEA_ECOLAGE, aSTU_ACCOUNT_NUMBER, aPER_KEY1, aSCH_GROUP_YEAR_PERIOD_ID, aSCH_STUDENT_ID);
    VarSCH_BILL_HEADER_ID  := GetNewId;

    insert into SCH_BILL_HEADER
                (SCH_BILL_HEADER_ID
               , PAC_CUSTOM_PARTNER_ID
               , SCH_GROUP_YEAR_PERIOD_ID
               , SCH_STUDENT_ID
               , DIC_PERSON_POLITNESS_ID
               , ACS_VAT_DET_ACCOUNT_ID
               , ACS_FIN_ACC_S_PAYMENT_ID
               , PAC_PAYMENT_CONDITION_ID
               , PAC_ADDRESS_ID
               , DIC_TYPE_SUBMISSION_ID
               , PC_LANG_ID
               , PC_CNTRY_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , DOC_GAUGE_ID
               , HEA_NUMBER
               , HEA_POLITNESSID
               , HEA_NAME
               , HEA_FORENAME
               , HEA_LANGID
               , HEA_CNTYID
               , HEA_ADDRESS
               , HEA_ZIPCODE
               , HEA_CITY
               , HEA_STATE
               , HEA_COMMENT
               , C_HEA_STATUS
               , HEA_VAT_DET_ACCOUNT_DESCR
               , HEA_CNTNAME
               , HEA_LANNAME
               , HEA_BILL_DATE
               , HEA_VALUE_DATE
               , HEA_TEXT_1
               , HEA_TEXT_2
               , HEA_TEXT_3
               , HEA_DECIMAL_1
               , HEA_DECIMAL_2
               , HEA_DECIMAL_3
               , HEA_FREE_DIC_TABLE_1
               , HEA_FREE_DIC_TABLE_2
               , HEA_FREE_DIC_TABLE_3
               , HEA_ECOLAGE
               , A_DATECRE
               , A_IDCRE
               , C_GROUPING_MODE
               , HEA_ORACLE_SESSION
                )
         values (VarSCH_BILL_HEADER_ID
               , aPAC_CUSTOM_PARTNER_ID
               , aSCH_GROUP_YEAR_PERIOD_ID
               , aSCH_STUDENT_ID
               , VarDIC_PERSON_POLITNESS_ID
               , aACS_VAT_DET_ACCOUNT_ID
               , aACS_FIN_ACC_S_PAYMENT_ID
               , aPAC_PAYMENT_CONDITION_ID
               , VarPAC_ADDRESS_ID
               , aDIC_TYPE_SUBMISSION_ID
               , VarPC_LANG_ID
               , VarPC_CNTRY_ID
               , aACS_FINANCIAL_CURRENCY_ID
               , aDOC_GAUGE_ID
               , VarHEA_NUMBER
               , VarPERSON_POLITNESS
               , VarNAME
               , VarFORENAME
               , VarLANGID
               , VarCNTID
               , VarADDRESS
               , VarZIPCODE
               , VarCITY
               , VarSTATE
               , VarCOMMENT
               , '20'
               , null
               , VarCNTNAME
               , VarLANNAME
               , nvl(iBillingDate, sysdate)
               , nvl(iValueDate, sysdate)
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , null
               , aHEA_ECOLAGE
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , aC_GROUPING_MODE
               , DBMS_SESSION.UNIQUE_SESSION_ID
                );

    return VarSCH_BILL_HEADER_ID;
  exception
    when others then
      raise;
  end InsertBillHeader;

  /**
  * function GetNewHeaNumber
  * Description : Génération d'un nouveau numéro de facture au format :
  *                --> Pour les écolages : E-[Année][Mois]-[Numéro de compte élève]-[Num à  deux chiffres]
  *                --> Pour les débours  : D-[Année][Mois]-[Numéro de compte élève]-[Num à  deux chiffres]
  *                --> Dans le cas de factures groupées par débiteur, [Numéro de compte élève] est remplacé
  *                    par le per_key1 du débiteur
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aHEA_ECOLAGE  : 1 => Facture d'écolage; 0 => Facture de débours
  * @param   aSTU_ACCOUNT_NUMBER : Numéro de compte élève
  * @param   aPER_KEY1 : Clef 1 partenaire
  * @param   aSCH_GROUP_YEAR_PERIOD_ID : Groupe de période facturé
  * @return  Nouveau numéro d'écolage
  */
  function GetNewHeaNumber(
    aHEA_ECOLAGE              in integer
  , aSTU_ACCOUNT_NUMBER       in integer
  , aPER_KEY1                 in PAC_PERSON.PER_KEY1%type
  , aSCH_GROUP_YEAR_PERIOD_ID in number
  , aSCH_STUDENT_ID           in number
  )
    return varchar2
  is
    -- Sur les numéros de facture
    cursor crStuHeaNumber
    is
      select nvl(to_number(max(substr(HEA_NUMBER, -2) ) ), 0) MAX_NUM
        from SCH_BILL_HEADER
       where SCH_STUDENT_ID = aSCH_STUDENT_ID
         and SCH_GROUP_YEAR_PERIOD_ID = aSCH_GROUP_YEAR_PERIOD_ID
         and HEA_ECOLAGE = aHEA_ECOLAGE;

    cursor crHeaNumber
    is
      select nvl(count(SCH_BILL_HEADER_ID), 0) MAX_NUM
        from SCH_BILL_HEADER
       where SCH_GROUP_YEAR_PERIOD_ID = aSCH_GROUP_YEAR_PERIOD_ID
         and HEA_ECOLAGE = aHEA_ECOLAGE;

    aNumFact       varchar2(5);
    aNewHEA_NUMBER SCH_BILL_HEADER.HEA_NUMBER%type;
  begin
    -- Récupération Année Mois
    select to_char(max(PER.PER_END_DATE), 'YYYYMM')
      into aNewHEA_NUMBER
      from SCH_YEAR_PERIOD PER
     where PER.SCH_YEAR_PERIOD_ID in(select COM_LIST_ID_TEMP_ID
                                       from COM_LIST_ID_TEMP
                                      where LID_CODE = 'SCH_YEAR_PERIOD_ID');

    -- L'élève de la facture est connu (facture par élève / débiteur)
    -- Formatage : X-YYYYMM-N°Compte elève-N°incrémentée de facture pour le groupe
    if aSCH_STUDENT_ID is not null then
      for tplHeaNumber in crStuHeaNumber loop
        if (tplHeaNumber.MAX_NUM + 1) < 10 then
          aNumFact  := '0' || to_char( (tplHeaNumber.MAX_NUM + 1) );
        else
          aNumFact  := to_char( (tplHeaNumber.MAX_NUM + 1) );
        end if;

        exit;
      end loop;

      -- S'il s'agit d'une facture d'écolage
      if aHEA_ECOLAGE = 1 then
        aNewHEA_NUMBER  := 'E-' || aNewHEA_NUMBER || '-' || aSTU_ACCOUNT_NUMBER || '-' || aNumFact;
      -- S'il s'agit d'une facture de débours
      else
        aNewHEA_NUMBER  := 'D-' || aNewHEA_NUMBER || '-' || aSTU_ACCOUNT_NUMBER || '-' || aNumFact;
      end if;
    -- Elève inconnu
    -- Formatage : X-YYYYMM-N°incrémenté de facture pour le groupe
    else
      for tplHeaNumber in crHeaNumber loop
        aNumFact  := lpad(to_char( (tplHeaNumber.MAX_NUM + 1) ), 4, '0');
        exit;
      end loop;

      -- S'il s'agit d'une facture d'écolage
      if aHEA_ECOLAGE = 1 then
        aNewHEA_NUMBER  := 'E-' || aNewHEA_NUMBER || '-' || aNumFact;
      -- S'il s'agit d'une facture de débours
      else
        aNewHEA_NUMBER  := 'D-' || aNewHEA_NUMBER || '-' || aNumFact;
      end if;
    end if;

    return aNewHEA_NUMBER;
  end GetNewHeaNumber;

  /**
  * function InsertBillPosition
  * Description : Insertion d'une position de facturation des débours ou écolage
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_BILL_HEADER_ID : entête facture
  * @param   aSCH_STUDENT_ID : élève
  * @param   aSCH_ECOLAGE_ID : écolage
  * @param   aSCH_ECOLAGE_CATEGORY_ID : catégorie d'écolage
  * @param   aSCH_DISCOUNT_ID : remise
  * @param   aSCH_OUTLAY_ID : Débours
  * @param   aSCH_OUTLAY_CATEGORY_ID : Catégorie de débours
  * @param   aSCH_YEAR_PERIOD_ID : Période
  * @param   aPAC_CUSTOM_PARTNER_ID : Débiteur
  * @param   aDOC_GAUGE_ID : Gabarit
  * @param   aGCO_GOOD_ID : Bien correspondant
  * @param   aBOP_DESCRIPTION : Description position
  * @param   aBOP_SHORT_DESCR : Description courte position
  * @param   aBOP_LONG_DESCR : Description longue position
  * @param   aBOP_MAJOR_REFERENCE : Ref principale position
  * @param   aBOP_SECONDARY_REFERENCE : Ref secondaire position
  * @param   aBOP_CATEGORY_DESCR : Description catégorie
  * @param   aBOP_FREE_DESCR : Description libre position
  * @param   aSTU_ACCOUNT_NUMBER : N° de compte élève
  * @param   aSTU_MIXED_BILLING : Facturation mixte
  * @param   aSTU_OTHER_ADDRESS : Facturation adresse autre
  * @param   aBOP_TTC_AMOUNT : Montant TTC
  * @param   aBOP_TTC_UNIT_AMOUNT : Montant TTC Unitaire
  * @param   aBOP_QTY : Qté
  * @param   aDIC_TYPE_SUBMISSION_ID : Type de soumission TVA
  * @param   aACS_VAT_DET_ACCOUNT_ID : Décompte TVA
  * @param   aBillDate : Date de référence
  * @param   aBOP_SEQ : Séquence position
  * @param   aSCH_ENTERED_OUTLAY_ID : Débours entré à l'origine de la position
  */
  function InsertBillPosition(
    aSCH_BILL_HEADER_ID      number
  , aSCH_STUDENT_ID          number
  , aSCH_ECOLAGE_ID          number
  , aSCH_ECOLAGE_CATEGORY_ID number
  , aSCH_DISCOUNT_ID         number
  , aSCH_OUTLAY_ID           number
  , aSCH_OUTLAY_CATEGORY_ID  number
  , aSCH_YEAR_PERIOD_ID      number
  , aPAC_CUSTOM_PARTNER_ID   number
  , aDOC_GAUGE_ID            number
  , aGCO_GOOD_ID             number
  , aBOP_MAJOR_REFERENCE     varchar2
  , aBOP_SECONDARY_REFERENCE varchar2
  , aBOP_DESCRIPTION         varchar2
  , aBOP_CATEGORY_DESCR      varchar2
  , aBOP_SHORT_DESCR         varchar2
  , aBOP_LONG_DESCR          varchar2
  , aBOP_FREE_DESCR          varchar2
  , aSTU_ACCOUNT_NUMBER      number
  , aSTU_MIXED_BILLING       integer
  , aSTU_OTHER_ADDRESS       integer
  , aBOP_TTC_AMOUNT          number
  , aBOP_TTC_UNIT_AMOUNT     number
  , aBOP_QTY                 number
  , aDIC_TYPE_SUBMISSION_ID  varchar2
  , aACS_VAT_DET_ACCOUNT_ID  number
  , aBillDate                date
  , aBOP_SEQ                 integer
  , aSCH_ENTERED_OUTLAY_ID   number default null
  , aUseCase                 integer default 0
  )
    return SCH_BILL_POSITION.SCH_BILL_POSITION_ID%type
  is
    -- Curseur sur les dossiers
    cursor crDocRecordId
    is
      select DOC_RECORD_ID
           , RCO_NUMBER
           , RCO_TITLE
        from DOC_RECORD
       where RCO_TITLE = to_char(aSTU_ACCOUNT_NUMBER);

    -- Variables
    tplDocRecordId             crDocRecordId%rowtype;
    VarDOC_RECORD_ID           number;
    VarRCO_NUMBER              number;
    VarRCO_TITLE               varchar2(30);
    result                     number;
    aBOP_VAT_AMOUNT            number;
    aBOP_HT_AMOUNT             number;
    VarBOP_TTC_AMOUNT          number;
    VarC_BOP_STATUS            varchar2(10);
    VarDIC_TYPE_VAT_GOOD_ID    varchar2(10);
    VarACS_TAX_CODE_ID         number;
    VarBOP_TYPE_VAT_GOOD_DESCR varchar2(100);
    VarBOP_TAX_CODE_DESCR      varchar2(60);
    lnACS_CDA_ACCOUNT_ID       number;
    liGAS_VAT                  integer;
    liGAP_INCLUDE_TAX_TARIFF   integer;
  begin
    -- Sélection d'informations sur le dossier lié à l'élève
    open crDocRecordId;

    fetch crDocRecordId
     into tplDocRecordId;

    if crDocRecordId%found then
      VarDOC_RECORD_ID  := tplDocRecordId.DOC_RECORD_ID;
      VarRCO_NUMBER     := tplDocRecordId.RCO_NUMBER;
      VarRCO_TITLE      := tplDocRecordId.RCO_TITLE;
    else
      VarDOC_RECORD_ID  := null;
      VarRCO_NUMBER     := null;
      VarRCO_TITLE      := null;
    end if;

    close crDocRecordId;

    -- Status de la position
    VarC_BOP_STATUS  := '20';

    -- Si écolage ou remise avec facturation mixte ou autre, status en préparation
    if     aSCH_OUTLAY_CATEGORY_ID is null
       and (    (aSTU_MIXED_BILLING = 1)
            or (aSTU_OTHER_ADDRESS = 1) ) then
      VarC_BOP_STATUS  := '10';
    end if;

    -- Recherche du CDA
    if     aUseCase = SCH_OUTLAY_BILLING.ucFundation
       and aSCH_OUTLAY_CATEGORY_ID is not null then
      lnACS_CDA_ACCOUNT_ID  := GetCDA(aSCH_STUDENT_ID, aSCH_OUTLAY_ID, aSCH_OUTLAY_CATEGORY_ID, aPAC_CUSTOM_PARTNER_ID, aBillDate, aSCH_ENTERED_OUTLAY_ID);
    else
      lnACS_CDA_ACCOUNT_ID  := null;
    end if;

    -- Calcul de la TVA

    -- Récupération mode de gestion TVA du gabarit
    begin
      select GAU.GAS_VAT
           , GPO.GAP_INCLUDE_TAX_TARIFF
        into liGAS_VAT
           , liGAP_INCLUDE_TAX_TARIFF
        from DOC_GAUGE_STRUCTURED GAU
           , DOC_GAUGE_POSITION GPO
       where GAU.DOC_GAUGE_ID = aDOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = GPO.DOC_GAUGE_ID
         and GPO.C_GAUGE_TYPE_POS = '1'
         and GPO.GAP_DEFAULT = 1;
    exception
      when no_data_found then
        begin
          liGAS_VAT                 := 1;
          liGAP_INCLUDE_TAX_TARIFF  := 0;
        end;
    end;

    -- Gestion TVA
    if liGAS_VAT = 1 then
      -- Gestion TTC
      if liGAP_INCLUDE_TAX_TARIFF = 1 then
        VarBOP_TTC_AMOUNT  := aBOP_TTC_AMOUNT;
        ACS_VAT_FCT.GetVatInformations(1   -- Position Bien
                                     , aDOC_GAUGE_ID
                                     , aPAC_CUSTOM_PARTNER_ID
                                     , aGCO_GOOD_ID
                                     , null
                                     , null
                                     , 'I'
                                     , nvl(aBillDate, sysdate)
                                     , VarACS_TAX_CODE_ID
                                     , VarBOP_TTC_AMOUNT
                                     , aBOP_VAT_AMOUNT
                                      );
        aBOP_HT_AMOUNT     := VarBOP_TTC_AMOUNT - aBOP_VAT_AMOUNT;
      -- Gestion HT
      else
        aBOP_HT_AMOUNT     := aBOP_TTC_AMOUNT;
        VarBOP_TTC_AMOUNT  := aBOP_TTC_AMOUNT;
        ACS_VAT_FCT.GetVatInformations(1   -- Position Bien
                                     , aDOC_GAUGE_ID
                                     , aPAC_CUSTOM_PARTNER_ID
                                     , aGCO_GOOD_ID
                                     , null
                                     , null
                                     , 'E'
                                     , nvl(aBillDate, sysdate)
                                     , VarACS_TAX_CODE_ID
                                     , VarBOP_TTC_AMOUNT
                                     , aBOP_VAT_AMOUNT
                                      );
        VarBOP_TTC_AMOUNT  := VarBOP_TTC_AMOUNT + aBOP_VAT_AMOUNT;
      end if;
    -- pas de gestion TVA
    else
      aBOP_HT_AMOUNT   := aBOP_TTC_AMOUNT;
      aBOP_VAT_AMOUNT  := 0;
    end if;

    -- Génération de la position
    result           := GetNewId;

    insert into SCH_BILL_POSITION
                (SCH_BILL_POSITION_ID
               , SCH_BILL_HEADER_ID
               , SCH_ECOLAGE_CATEGORY_ID
               , SCH_ECOLAGE_ID
               , SCH_DISCOUNT_ID
               , SCH_OUTLAY_ID
               , SCH_OUTLAY_CATEGORY_ID
               , SCH_STUDENT_ID
               , DOC_RECORD_ID
               , DIC_TYPE_VAT_GOOD_ID
               , SCH_YEAR_PERIOD_ID
               , DOC_GAUGE_ID
               , ACS_TAX_CODE_ID
               , BOP_DESCRIPTION
               , BOP_CATEGORY_DESCR
               , BOP_RCO_NUMBER
               , BOP_RCO_TITLE
               , BOP_MAJOR_REFERENCE
               , BOP_SECONDARY_REFERENCE
               , BOP_TYPE_VAT_GOOD_DESCR
               , BOP_SHORT_DESCR
               , BOP_LONG_DESCR
               , BOP_FREE_DESCR
               , BOP_TAX_CODE_DESCR
               , C_BOP_STATUS
               , BOP_GAUGE_NAME
               , BOP_TTC_AMOUNT
               , BOP_HT_AMOUNT
               , BOP_VAT_AMOUNT
               , A_DATECRE
               , A_IDCRE
               , BOP_QTY
               , BOP_TTC_UNIT_AMOUNT
               , SCH_ENTERED_OUTLAY_ID
               , BOP_SEQ
               , SCH_FATHER_POSITION_ID
               , ACS_CDA_ACCOUNT_ID
                )
         values (result
               , aSCH_BILL_HEADER_ID
               , aSCH_ECOLAGE_CATEGORY_ID
               , aSCH_ECOLAGE_ID
               , aSCH_DISCOUNT_ID
               , aSCH_OUTLAY_ID
               , aSCH_OUTLAY_CATEGORY_ID
               , aSCH_STUDENT_ID
               , VarDOC_RECORD_ID
               , null
               , aSCH_YEAR_PERIOD_ID
               , aDOC_GAUGE_ID
               , varACS_TAX_CODE_ID
               , aBOP_DESCRIPTION
               , aBOP_CATEGORY_DESCR
               , VarRCO_NUMBER
               , VarRCO_TITLE
               , aBOP_MAJOR_REFERENCE
               , aBOP_SECONDARY_REFERENCE
               , ''
               , aBOP_SHORT_DESCR
               , aBOP_LONG_DESCR
               , aBOP_FREE_DESCR
               , ''
               , VarC_BOP_STATUS
               , ''
               , nvl(VarBOP_TTC_AMOUNT, 0)
               , nvl(aBOP_HT_AMOUNT, 0)
               , nvl(aBOP_VAT_AMOUNT, 0)
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , nvl(aBOP_QTY, 0)
               , nvl(aBOP_TTC_UNIT_AMOUNT, 0)
               , aSCH_ENTERED_OUTLAY_ID
               , aBOP_SEQ
               , null
               , lnACS_CDA_ACCOUNT_ID
                );

    -- Transfert des données libres, écolages et catégories.
    if nvl(aSCH_ECOLAGE_CATEGORY_ID, 0) <> 0 then
      TransfertEcolageFreeData(result, aSCH_ECOLAGE_ID, aSCH_ECOLAGE_CATEGORY_ID);
    -- Transfert des données libres débours saisis.
    else
      TransfertOutlayFreeData(result, aSCH_ENTERED_OUTLAY_ID);
    end if;

    -- Si entrée d'un débours saisi, passage de son statut à "facturé"
    if aSCH_ENTERED_OUTLAY_ID is not null then
      update SCH_ENTERED_OUTLAY
         set EOU_STATUS = 2
       where SCH_ENTERED_OUTLAY_ID = aSCH_ENTERED_OUTLAY_ID;
    end if;

    -- Si facturation d'un écolage, et mise à jour des champs dépot de garantie
    -- ou frais d'inscription facturée
    if nvl(aSCH_ECOLAGE_ID, 0) <> 0 then
      -- Mise à jour du champ Dépot de garantie facturé
      update SCH_STUDENT
         set STU_GUARANTEE_BILLED = 1
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where SCH_STUDENT_ID = aSCH_STUDENT_ID
         and nvl(STU_GUARANTEE_BILLED, 0) <> 1
         and exists(select 1
                      from SCH_ECOLAGE ECO
                     where ECO.SCH_ECOLAGE_ID = aSCH_ECOLAGE_ID
                       and ECO.ECO_UPDT_GUARANT_BILLED = 1);

      -- Mise à jour du champ inscription facturée
      update SCH_STUDENT
         set STU_REGISTRATION_BILLED = 1
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where SCH_STUDENT_ID = aSCH_STUDENT_ID
         and nvl(STU_REGISTRATION_BILLED, 0) <> 1
         and exists(select 1
                      from SCH_ECOLAGE ECO
                     where ECO.SCH_ECOLAGE_ID = aSCH_ECOLAGE_ID
                       and ECO.ECO_UPDT_REGISTR_BILLED = 1);
    end if;

    return result;
  end InsertBillPosition;

  /**
  * Procedure DeleteBill
  * Description : Suppression des factures d'écolages et de débours
  *               Si certaines ne peuvent être supprimées car le doc logistique
  *               est déjà généré, alors ceci est indiqué dans aErrorMsg
  *               Dans le cas de facture de débours, la suppression change le
  *               status du débours en question afin de lui permettre d'etre
  *               refacturé.
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_GROUP_YEAR_PERIOD_ID : Group de période dont les factures sont à supprimer
  * @param   aErrorMsg : Message éventuel d'erreur
  */
  procedure DeleteBill(aSCH_GROUP_YEAR_PERIOD_ID in number, aHEA_ECOLAGE in integer default 0, aErrorMsg in out varchar2)
  is
    billExists integer;

    cursor crBillToDelete
    is
      select SCH_BILL_HEADER_ID
        from SCH_BILL_HEADER
       where SCH_GROUP_YEAR_PERIOD_ID = aSCH_GROUP_YEAR_PERIOD_ID
         and HEA_ECOLAGE = aHEA_ECOLAGE
         and DOC_DOCUMENT_ID is null
         and C_HEA_STATUS <> '30';
  begin
    -- Supressions des liens mère -> fille sur les positions concernées
    for tplBillToDelete in crBillToDelete loop
      update SCH_BILL_POSITION
         set SCH_FATHER_POSITION_ID = null
       where SCH_FATHER_POSITION_ID is not null
         and SCH_BILL_HEADER_ID = tplBillToDelete.SCH_BILL_HEADER_ID;
    end loop;

    -- la suppression des positions se fait en cascade
    for tplBillToDelete in crBillToDelete loop
      -- RAZ des champs sur les fiches élèves
      SCH_ECOLAGE_BILLING.ReinitStudentsFields(tplBillToDelete.SCH_BILL_HEADER_ID);

      -- Suppression
      delete from SCH_BILL_HEADER
            where SCH_BILL_HEADER_ID = tplBillToDelete.SCH_BILL_HEADER_ID;
    end loop;

    begin
      select 1
        into billExists
        from SCH_BILL_HEADER
       where SCH_GROUP_YEAR_PERIOD_ID = aSCH_GROUP_YEAR_PERIOD_ID
         and HEA_ECOLAGE = aHEA_ECOLAGE;

      aErrorMsg  :=
                  PCS.PC_FUNCTIONS.TranslateWord('Des documents ont déjà été générés pour ce groupe de périodes, certaines factures n''ont pu être supprimées!');
    exception
      when others then
        aErrorMsg  := null;
    end;
  end DeleteBill;

  /**
  * Procedure GenerateOneLogisticDoc
  * Description : Génération d'un document logistique à partir des factures d'écolages ou de
  *               débours sélectionnées (table COM_LIST_ID_TEMP).
  *
  * @created JFR
  * @lastUpdate
  * @public
  * @param   aSCH_BILL_HEADER_ID : Facture à générer en logistique
  * @param   aHEA_ECOLAGE : Facture d'écolage ou de débours
  */
  procedure GenerateOneLogisticDoc(aSCH_BILL_HEADER_ID in number, aHEA_ECOLAGE in integer)
  is
   aSuccessfulCount integer;
   aTotalCount      integer;
   vDebug           varchar2(4000);
  begin
    -- Initialisation pour indication du résultat
    aSuccessfulCount := 0;
    aTotalCount := 0;

    --Ajout de l'id dans COM_LIST_ID_TEMP
    insert into COM_LIST_ID_TEMP
              (COM_LIST_ID_TEMP_ID
             , LID_CODE
             , LID_FREE_NUMBER_1
              )
       values (aSCH_BILL_HEADER_ID
             , 'SCH_BILL_HEADER_ID'
             , 1
              );

    --Appel de la procédure pour la génération du document
    GenerateLogisticDoc(
        null
      , null
      , null
      , null
      , null
      , null
      , aHEA_ECOLAGE
      , aSuccessfulCount
      , aTotalCount
      , aSCH_BILL_HEADER_ID);

    if aSuccessfulCount = 0 then
      begin
        select LID_DESCRIPTION
          into vdebug
        from COM_LIST_ID_TEMP
             where COM_LIST_ID_TEMP_ID = aSCH_BILL_HEADER_ID
               and LID_CODE = 'SCH_BILL_HEADER_ID';
      exception
        when others then
          vDebug := null;
      end;
      raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('Une erreur est survenue lors de la génération du document.')
      || ' Erreur : ' || vDebug);
    end if;

    --Suppression de l'id dans COM_LIST_ID_TEMP
    delete from COM_LIST_ID_TEMP
      where COM_LIST_ID_TEMP_ID = aSCH_BILL_HEADER_ID and LID_CODE = 'SCH_BILL_HEADER_ID' and LID_FREE_NUMBER_1 = 1;
  end GenerateOneLogisticDoc;

  /**
  * Procedure GenerateLogisticDoc
  * Description : Génération des documents logistiques à partir des factures d'écolages ou de
  *               débours.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_BILL_HEADER_ID : Facture à générer en logistique
  */
  procedure GenerateLogisticDoc(aSCH_BILL_HEADER_ID number)
  is
    cursor crSchBillHeader
    is
      select DOC_GAUGE_ID
           , PAC_CUSTOM_PARTNER_ID
           , trunc(nvl(HEA_VALUE_DATE, sysdate) ) HEA_VALUE_DATE
           , SCH_BILL_HEADER_ID
           , (case
                when nvl(HEA_ECOLAGE, 0) = 0 then '121'
                else '122'
              end) aMode
           , C_GROUPING_MODE
        from SCH_BILL_HEADER
       where SCH_BILL_HEADER_ID = aSCH_BILL_HEADER_ID;

    cursor crSchBillPosition(aHeaderID number)
    is
      select POS.BOP_TTC_AMOUNT
           , POS.BOP_TTC_UNIT_AMOUNT
           , nvl(ECO.GCO_GOOD_ID, nvl(out.GCO_GOOD_ID, DIS.GCO_GOOD_ID) ) GCO_GOOD_ID
           , POS.SCH_BILL_POSITION_ID
           , POS.BOP_QTY
           , DOC_RECORD_ID
        from SCH_BILL_POSITION POS
           , SCH_ECOLAGE_CATEGORY ECO
           , SCH_OUTLAY_CATEGORY out
           , SCH_DISCOUNT DIS
       where POS.SCH_BILL_HEADER_ID = aHeaderID
         and POS.SCH_ECOLAGE_CATEGORY_ID = ECO.SCH_ECOLAGE_CATEGORY_ID(+)
         and POS.SCH_OUTLAY_CATEGORY_ID = out.SCH_OUTLAY_CATEGORY_ID(+)
         and POS.SCH_DISCOUNT_ID = DIS.SCH_DISCOUNT_ID(+)
         and (   nvl(POS.BOP_VAT_AMOUNT, 0) <> 0
              or nvl(BOP_TTC_AMOUNT, 0) <> 0
              or nvl(BOP_HT_AMOUNT, 0) <> 0);

    vDOC_ID              DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    vPOS_ID              DOC_POSITION.DOC_POSITION_ID%type;
    aBOP_TTC_UNIT_AMOUNT number;
  begin
    for tplSchBillHeader in crSchBillHeader loop
      -- Génération du document
      vDOC_ID  := null;
      DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID   => vDOC_ID
                                           , aMode            => tplSchBillHeader.aMode
                                           , aGaugeID         => tplSchBillHeader.DOC_GAUGE_ID
                                           , aThirdID         => tplSchBillHeader.PAC_CUSTOM_PARTNER_ID
                                           , aDocDate         => tplSchBillHeader.HEA_VALUE_DATE
                                           , aSrcDocumentID   => tplSchBillHeader.SCH_BILL_HEADER_ID
                                            );

      -- Génération de ses positions
      for tplSchBillPosition in crSchBillPosition(tplSchBillHeader.SCH_BILL_HEADER_ID) loop
        vPOS_ID  := null;
        -- Montant unitaire position
        if tplSchBillPosition.BOP_TTC_UNIT_AMOUNT is null then
          if nvl(tplSchBillPosition.BOP_QTY, 0) <> 0 then
            aBOP_TTC_UNIT_AMOUNT  := tplSchBillPosition.BOP_TTC_AMOUNT / tplSchBillPosition.BOP_QTY;
          else
            aBOP_TTC_UNIT_AMOUNT  := 0;
          end if;
        else
          aBOP_TTC_UNIT_AMOUNT  := tplSchBillPosition.BOP_TTC_UNIT_AMOUNT;
        end if;

        DOC_POSITION_GENERATE.GeneratePosition(aPositionID      => vPOS_ID
                                             , aDocumentID      => vDOC_ID
                                             , aPosCreateMode   => tplSchBillHeader.aMode
                                             , aBasisQuantity   => tplSchBillPosition.BOP_QTY
                                             , aGoodID          => tplSchBillPosition.GCO_GOOD_ID
                                             , aGoodPrice       => aBOP_TTC_UNIT_AMOUNT
                                             , aTypePos         => '1'
                                             , aRecordID        => tplSchBillPosition.DOC_RECORD_ID
                                             , aSrcPositionID   => tplSchBillPosition.SCH_BILL_POSITION_ID
                                              );

        -- Mise à jour de la position sur la facture concernée
        update SCH_BILL_POSITION
           set DOC_POSITION_ID = vPOS_ID
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where SCH_BILL_POSITION_ID = tplSchBillPosition.SCH_BILL_POSITION_ID;
      end loop;

      -- Finalisation du document
      DOC_FINALIZE.FinalizeDocument(vDOC_ID, 1, 1, 1);

      -- Mise à jour du document sur la facture concernée
      update SCH_BILL_HEADER
         set DOC_DOCUMENT_ID = vDOC_ID
           , C_HEA_STATUS = '30'
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where SCH_BILL_HEADER_ID = tplSchBillHeader.SCH_BILL_HEADER_ID;
    end loop;
  end GenerateLogisticDoc;

  /**
  * Procedure GenerateLogisticDoc
  * Description : Génération des documents logistiques à partir des factures d'écolages ou de
  *               débours sélectionnées (table COM_LIST_ID_TEMP).
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_OUT_BILL_GLOBAL_PROC : procedure globale avant traitement débours
  * @param   aSCH_OUT_BILL_DET_BEFORE_PROC : procedure détail avant traitement débours
  * @param   aSCH_OUT_BILL_DET_AFTER_PROC : procedure détail après traitement débours
  * @param   aSCH_ECO_BILL_GLOBAL_PROC : procedure globale avant traitement écolages
  * @param   aSCH_ECO_BILL_DET_BEFORE_PROC : procedure détail avant traitement écolages
  * @param   aSCH_ECO_BILL_DET_AFTER_PROC : procedure détail après traitement écolages
  * @param   aHEA_ECOLAGE : Facture d'écolage ou de débours
  * @return aSuccessfulCount : Doc générés avec succes
  * @return aTotalCount : Factures totales sélectionnées pour génération
  */
  procedure GenerateLogisticDoc(
    aSCH_OUT_BILL_GLOBAL_PROC     in     varchar2
  , aSCH_OUT_BILL_DET_BEFORE_PROC in     varchar2
  , aSCH_OUT_BILL_DET_AFTER_PROC  in     varchar2
  , aSCH_ECO_BILL_GLOBAL_PROC     in     varchar2
  , aSCH_ECO_BILL_DET_BEFORE_PROC in     varchar2
  , aSCH_ECO_BILL_DET_AFTER_PROC  in     varchar2
  , aHEA_ECOLAGE                  in     integer
  , aSuccessfulCount              out    integer
  , aTotalCount                   out    integer
  , aSCH_BILL_HEADER_ID           in     number default null
  )
  is
    cursor crSelectedBillHeader
    is
      select   HEA.SCH_BILL_HEADER_ID
             , (select count(*)
                  from sch_bill_position pos
                 where pos.sch_bill_header_id = hea.sch_bill_header_id
                   and bop_ttc_amount <> 0) has_billable_position
          from SCH_BILL_HEADER HEA
             , COM_LIST_ID_TEMP LID
         where HEA.SCH_BILL_HEADER_ID = LID.COM_LIST_ID_TEMP_ID
           and LID.LID_CODE = 'SCH_BILL_HEADER_ID'
           and LID.LID_FREE_NUMBER_1 = 1
           and (   nvl(aSCH_BILL_HEADER_ID, 0) = 0
                or HEA.SCH_BILL_HEADER_ID = aSCH_BILL_HEADER_ID)
      order by (select stu_name || stu_forename
                  from sch_student stu
                 where stu.sch_student_id = HEA.SCH_STUDENT_ID)
             , hea_name;

    vSqlMsg                   varchar2(4000);
    vSCH_BILL_GLOBAL_PROC     varchar2(255);
    vSCH_BILL_DET_BEFORE_PROC varchar2(255);
    vSCH_BILL_DET_AFTER_PROC  varchar2(255);
    vProcResult               integer        := 1;
  begin
    -- Initialisation pour indication du résultat
    aSuccessfulCount  := 0;
    aTotalCount       := 0;

    -- Récupération des procédures stockées
    if aHEA_ECOLAGE = 0 then
      vSCH_BILL_GLOBAL_PROC      := nvl(aSCH_OUT_BILL_GLOBAL_PROC, PCS.PC_CONFIG.GetConfig('SCH_OUT_BILL_GLOBAL_PROC') );
      vSCH_BILL_DET_BEFORE_PROC  := nvl(aSCH_OUT_BILL_DET_BEFORE_PROC, PCS.PC_CONFIG.GetConfig('SCH_OUT_BILL_DET_BEFORE_PROC') );
      vSCH_BILL_DET_AFTER_PROC   := nvl(aSCH_OUT_BILL_DET_AFTER_PROC, PCS.PC_CONFIG.GetConfig('SCH_OUT_BILL_DET_AFTER_PROC') );
    else
      vSCH_BILL_GLOBAL_PROC      := nvl(aSCH_ECO_BILL_GLOBAL_PROC, PCS.PC_CONFIG.GetConfig('SCH_ECO_BILL_GLOBAL_PROC') );
      vSCH_BILL_DET_BEFORE_PROC  := nvl(aSCH_ECO_BILL_DET_BEFORE_PROC, PCS.PC_CONFIG.GetConfig('SCH_ECO_BILL_DET_BEFORE_PROC') );
      vSCH_BILL_DET_AFTER_PROC   := nvl(aSCH_ECO_BILL_DET_AFTER_PROC, PCS.PC_CONFIG.GetConfig('SCH_ECO_BILL_DET_AFTER_PROC') );
    end if;

    -- Execution de la procédure stockée globale
    if vSCH_BILL_GLOBAL_PROC is not null then
      begin
        execute immediate 'begin :Result :=  ' || vSCH_BILL_GLOBAL_PROC || '; end;'
                    using out vProcResult;

        if vProcResult < 1 then
          vSqlMsg  :=
                    PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée globale a interrompu le traitement. Valeur retournée :') || ' '
                    || to_char(vProcResult);
        end if;
      exception
        when others then
          begin
            vSqlMsg  :=
                     PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée globale a généré une erreur :') || chr(13) || chr(10)
                     || DBMS_UTILITY.FORMAT_ERROR_STACK;
          end;
      end;
    end if;

    -- La procédure globale de pré-traitement à généré un message d'erreur
    if vSqlMsg is not null then
      -- Mise à jour des statuts et des détails de l'abandon dans la table temporaire
      update COM_LIST_ID_TEMP
         set LID_DESCRIPTION = vSqlMsg
       where LID_CODE = 'SCH_BILL_HEADER_ID'
         and LID_FREE_NUMBER_1 = 1;
    else
      -- Parcours des factures à traiter
      for tplSelectedBillHeader in crSelectedBillHeader loop
        vSqlMsg      := null;
        aTotalCount  := aTotalCount + 1;

        -- Execution de la procédure stockée de pré-traitement
        if vSCH_BILL_DET_BEFORE_PROC is not null then
          begin
            execute immediate 'begin :Result :=  ' || vSCH_BILL_DET_BEFORE_PROC || '(:SCH_BILL_HEADER_ID); end;'
                        using out vProcResult, in tplSelectedBillHeader.SCH_BILL_HEADER_ID;

            if vProcResult < 1 then
              vSqlMsg  :=
                PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de pré-traitement a interrompu le traitement. Valeur retournée :') ||
                ' ' ||
                to_char(vProcResult);
            end if;
          exception
            when others then
              begin
                vProcResult  := 0;
                vSqlMsg      :=
                  PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de pré-traitement a généré une erreur :') ||
                  chr(13) ||
                  chr(10) ||
                  DBMS_UTILITY.FORMAT_ERROR_STACK;
              end;
          end;
        end if;

        if vSqlMsg is null then
          savepoint SP_BeforeGenerate;

          begin
            -- Génération du document logistique si il y a au moins une position à facturer
            if tplSelectedBillHeader.Has_Billable_position > 0 then
              GenerateLogisticDoc(tplSelectedBillHeader.SCH_BILL_HEADER_ID);
            end if;

            -- Mise à jour du status de la facture
            update SCH_BILL_HEADER
               set C_HEA_STATUS = '30'
             where SCH_BILL_HEADER_ID = tplSelectedBillHeader.SCH_BILL_HEADER_ID;
          exception
            when others then
              vSqlMsg  := DBMS_UTILITY.FORMAT_ERROR_STACK || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
          end;

          -- Annulation du traitement de génération du document en cours s'il y a eu le moindre problème
          if vSqlMsg is not null then
            rollback to savepoint SP_BeforeGenerate;

            -- Mise à jour du status de la facture
            update SCH_BILL_HEADER
               set C_HEA_STATUS = '40'
             where SCH_BILL_HEADER_ID = tplSelectedBillHeader.SCH_BILL_HEADER_ID;

            -- Mise à jour de l'erreur
            update COM_LIST_ID_TEMP
               set LID_DESCRIPTION = vSqlMsg
             where COM_LIST_ID_TEMP_ID = tplSelectedBillHeader.SCH_BILL_HEADER_ID
               and LID_CODE = 'SCH_BILL_HEADER_ID';
          else
            -- Execution de la procédure stockée de post-traitement
            if vSqlMsg is null then
              begin
                -- Execution de la procédure stockée de post-traitement
                if vSCH_BILL_DET_AFTER_PROC is not null then
                  execute immediate 'begin :Result :=  ' || vSCH_BILL_DET_AFTER_PROC || '(:SCH_BILL_HEADER_ID); end;'
                              using out vProcResult, in tplSelectedBillHeader.SCH_BILL_HEADER_ID;

                  if vProcResult < 1 then
                    vSqlMsg  :=
                      PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de post-traitement a signalé un problème. Valeur retournée') ||
                      ' ' ||
                      to_char(vProcResult);
                  end if;
                end if;
              exception
                when others then
                  begin
                    vProcResult  := 0;
                    vSqlMsg      :=
                      PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de post-traitement a généré une erreur :') ||
                      chr(13) ||
                      chr(10) ||
                      DBMS_UTILITY.FORMAT_ERROR_STACK;
                  end;
              end;
            end if;

            if vSqlMsg is null then
              aSuccessfulCount  := aSuccessfulCount + 1;

              -- Suppression de la facture correctement traitée
              delete from COM_LIST_ID_TEMP LID
                    where LID.LID_CODE = 'SCH_BILL_HEADER_ID'
                      and LID.COM_LIST_ID_TEMP_ID = tplSelectedBillHeader.SCH_BILL_HEADER_ID;
            else
              -- Mise à jour du status de la facture
              update SCH_BILL_HEADER
                 set C_HEA_STATUS = '40'
               where SCH_BILL_HEADER_ID = tplSelectedBillHeader.SCH_BILL_HEADER_ID;

              -- Mise à jour de l'erreur
              update COM_LIST_ID_TEMP
                 set LID_DESCRIPTION = vSqlMsg
               where COM_LIST_ID_TEMP_ID = tplSelectedBillHeader.SCH_BILL_HEADER_ID
                 and LID_CODE = 'SCH_BILL_HEADER_ID';
            end if;
          end if;
        -- la proc de pré-traitement détail à provoqué une erreur
        else
          -- Mise à jour du status de la facture
          update SCH_BILL_HEADER
             set C_HEA_STATUS = '40'
           where SCH_BILL_HEADER_ID = tplSelectedBillHeader.SCH_BILL_HEADER_ID;

          -- Mise à jour de l'erreur
          update COM_LIST_ID_TEMP
             set LID_DESCRIPTION = vSqlMsg
           where COM_LIST_ID_TEMP_ID = tplSelectedBillHeader.SCH_BILL_HEADER_ID
             and LID_CODE = 'SCH_BILL_HEADER_ID';
        end if;
      end loop;
    end if;
  end GenerateLogisticDoc;

  /**
  * procedure SelectBill
  * Description : Sélection des factures encore à générer en logistique en tenant compte des filtres
  *               de présélections sur les périodes, débiteurs, et élèves.
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure SelectBill(aHEA_ECOLAGE integer)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'SCH_BILL_HEADER_ID';

    -- Sélection des ID de produits à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
               , LID_FREE_NUMBER_1
                )
      select distinct HEA.SCH_BILL_HEADER_ID
                    , 'SCH_BILL_HEADER_ID'
                    , 1
                 from SCH_BILL_HEADER HEA
                where HEA.SCH_GROUP_YEAR_PERIOD_ID in(select COM_LIST_ID_TEMP_ID
                                                        from COM_LIST_ID_TEMP
                                                       where LID_CODE = 'SCH_GROUP_YEAR_PERIOD_ID')
                  and HEA.PAC_CUSTOM_PARTNER_ID in(select COM_LIST_ID_TEMP_ID
                                                     from COM_LIST_ID_TEMP
                                                    where LID_CODE = 'PAC_CUSTOM_PARTNER_ID')
                  and (    (    HEA.SCH_STUDENT_ID is not null
                            and HEA.SCH_STUDENT_ID in(select COM_LIST_ID_TEMP_ID
                                                        from COM_LIST_ID_TEMP
                                                       where LID_CODE = 'SCH_STUDENT_ID') )
                       or (    HEA.SCH_STUDENT_ID is null
                           and exists(select 1
                                        from SCH_BILL_POSITION POS
                                       where POS.SCH_STUDENT_ID in(select COM_LIST_ID_TEMP_ID
                                                                     from COM_LIST_ID_TEMP
                                                                    where LID_CODE = 'SCH_STUDENT_ID')
                                         and POS.SCH_BILL_HEADER_ID = HEA.SCH_BILL_HEADER_ID)
                          )
                      )
                  and ((SCH_BILLING_FUNCTIONS.GetFilterCDA(null, null, HEA.SCH_BILL_HEADER_ID) in(select COM_LIST_ID_TEMP_ID
                                                                                                    from COM_LIST_ID_TEMP
                                                                                                   where LID_CODE = 'CDA_ACC_SCH'))
                        OR
                       (SCH_BILLING_FUNCTIONS.GetFilterCDA(null, null, HEA.SCH_BILL_HEADER_ID) is null))
                  and HEA.DOC_DOCUMENT_ID is null
                  and HEA.C_HEA_STATUS <> '30'
                  and HEA.HEA_ECOLAGE = aHEA_ECOLAGE
                  and HEA.PAC_CUSTOM_PARTNER_ID is not null;
  end SelectBill;

  /**
  * procedure TransfertEcolageFreeData
  * Description : transfert des données libres des écolages et ou cat. d'écolages
  *               sur les positions de facture.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_BILL_POSITION : Position
  * @param   aSCH_ECOLAGE_ID : Ecolage
  * @param   aSCH_ECOLAGE_CATEGORY_ID : Catégorie d'écolage
  */
  procedure TransfertEcolageFreeData(aSCH_BILL_POSITION_ID number, aSCH_ECOLAGE_ID number, aSCH_ECOLAGE_CATEGORY_ID number)
  is
    -- Sélection des données libres de premier niveau
    cursor crSchFreeData
    is
      select *
        from SCH_FREE_DATA SFD
       where SFD.SCH_ECOLAGE_ID = aSCH_ECOLAGE_ID
         and aSCH_ECOLAGE_ID is not null
         and SFD.SFD_TRANSFERT = 1;

    -- Sélection des données libres de la catégorie
    cursor crSchFreeDataCategory
    is
      select *
        from SCH_FREE_DATA SFD
       where SFD.SCH_ECOLAGE_CATEGORY_ID = aSCH_ECOLAGE_CATEGORY_ID
         and aSCH_ECOLAGE_CATEGORY_ID is not null
         and SFD.SFD_TRANSFERT = 1;

    aSCH_FREE_DATA_ID number;
  begin
    aSCH_FREE_DATA_ID  := null;

    -- Transfert données libres débours
    for tplSchFreeData in crSchFreeData loop
      aSCH_FREE_DATA_ID  := GetNewId;

      insert into SCH_FREE_DATA
                  (SCH_FREE_DATA_ID
                 , SCH_BILL_POSITION_ID
                 , DIC_SCH_FREE_TABLE1_ID
                 , DIC_SCH_FREE_TABLE2_ID
                 , DIC_SCH_FREE_TABLE3_ID
                 , DIC_SCH_FREE_TABLE4_ID
                 , DIC_SCH_FREE_TABLE5_ID
                 , SFD_ALPHA_SHORT_1
                 , SFD_ALPHA_SHORT_2
                 , SFD_ALPHA_SHORT_3
                 , SFD_ALPHA_SHORT_4
                 , SFD_ALPHA_SHORT_5
                 , SFD_ALPHA_LONG_1
                 , SFD_ALPHA_LONG_2
                 , SFD_ALPHA_LONG_3
                 , SFD_ALPHA_LONG_4
                 , SFD_ALPHA_LONG_5
                 , SFD_INTEGER_1
                 , SFD_INTEGER_2
                 , SFD_INTEGER_3
                 , SFD_INTEGER_4
                 , SFD_INTEGER_5
                 , SFD_BOOLEAN_1
                 , SFD_BOOLEAN_2
                 , SFD_BOOLEAN_3
                 , SFD_BOOLEAN_4
                 , SFD_BOOLEAN_5
                 , SFD_DECIMAL_1
                 , SFD_DECIMAL_2
                 , SFD_DECIMAL_3
                 , SFD_DECIMAL_4
                 , SFD_DECIMAL_5
                 , SFD_DATE_1
                 , SFD_DATE_2
                 , SFD_DATE_3
                 , SFD_DATE_4
                 , SFD_DATE_5
                 , A_DATECRE
                 , A_IDCRE
                 , SFD_CATEGORY_COPY
                 , SFD_TRANSFERT
                  )
        select aSCH_FREE_DATA_ID
             , aSCH_BILL_POSITION_ID
             , SFD.DIC_SCH_FREE_TABLE1_ID
             , SFD.DIC_SCH_FREE_TABLE2_ID
             , SFD.DIC_SCH_FREE_TABLE3_ID
             , SFD.DIC_SCH_FREE_TABLE4_ID
             , SFD.DIC_SCH_FREE_TABLE5_ID
             , SFD.SFD_ALPHA_SHORT_1
             , SFD.SFD_ALPHA_SHORT_2
             , SFD.SFD_ALPHA_SHORT_3
             , SFD.SFD_ALPHA_SHORT_4
             , SFD.SFD_ALPHA_SHORT_5
             , SFD.SFD_ALPHA_LONG_1
             , SFD.SFD_ALPHA_LONG_2
             , SFD.SFD_ALPHA_LONG_3
             , SFD.SFD_ALPHA_LONG_4
             , SFD.SFD_ALPHA_LONG_5
             , SFD.SFD_INTEGER_1
             , SFD.SFD_INTEGER_2
             , SFD.SFD_INTEGER_3
             , SFD.SFD_INTEGER_4
             , SFD.SFD_INTEGER_5
             , SFD.SFD_BOOLEAN_1
             , SFD.SFD_BOOLEAN_2
             , SFD.SFD_BOOLEAN_3
             , SFD.SFD_BOOLEAN_4
             , SFD.SFD_BOOLEAN_5
             , SFD.SFD_DECIMAL_1
             , SFD.SFD_DECIMAL_2
             , SFD.SFD_DECIMAL_3
             , SFD.SFD_DECIMAL_4
             , SFD.SFD_DECIMAL_5
             , SFD.SFD_DATE_1
             , SFD.SFD_DATE_2
             , SFD.SFD_DATE_3
             , SFD.SFD_DATE_4
             , SFD.SFD_DATE_5
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
             , 0
             , 0
          from SCH_FREE_DATA SFD
         where SCH_ECOLAGE_ID = aSCH_ECOLAGE_ID
           and aSCH_ECOLAGE_ID is not null
           and SFD.SFD_TRANSFERT = 1;

      exit;
    end loop;

    -- Si transfert effectué, on fusionne éventuellement celles de la catégorie,
    if aSCH_FREE_DATA_ID is not null then
      for tplSchFreeDataCategory in crSchFreeDataCategory loop
        update SCH_FREE_DATA SFD
           set SFD.DIC_SCH_FREE_TABLE1_ID = nvl(SFD.DIC_SCH_FREE_TABLE1_ID, tplSchFreeDataCategory.DIC_SCH_FREE_TABLE1_ID)
             , SFD.DIC_SCH_FREE_TABLE2_ID = nvl(SFD.DIC_SCH_FREE_TABLE2_ID, tplSchFreeDataCategory.DIC_SCH_FREE_TABLE2_ID)
             , SFD.DIC_SCH_FREE_TABLE3_ID = nvl(SFD.DIC_SCH_FREE_TABLE3_ID, tplSchFreeDataCategory.DIC_SCH_FREE_TABLE3_ID)
             , SFD.DIC_SCH_FREE_TABLE4_ID = nvl(SFD.DIC_SCH_FREE_TABLE4_ID, tplSchFreeDataCategory.DIC_SCH_FREE_TABLE4_ID)
             , SFD.DIC_SCH_FREE_TABLE5_ID = nvl(SFD.DIC_SCH_FREE_TABLE5_ID, tplSchFreeDataCategory.DIC_SCH_FREE_TABLE5_ID)
             , SFD.SFD_ALPHA_SHORT_1 = nvl(SFD.SFD_ALPHA_SHORT_1, tplSchFreeDataCategory.SFD_ALPHA_SHORT_1)
             , SFD.SFD_ALPHA_SHORT_2 = nvl(SFD.SFD_ALPHA_SHORT_2, tplSchFreeDataCategory.SFD_ALPHA_SHORT_2)
             , SFD.SFD_ALPHA_SHORT_3 = nvl(SFD.SFD_ALPHA_SHORT_3, tplSchFreeDataCategory.SFD_ALPHA_SHORT_3)
             , SFD.SFD_ALPHA_SHORT_4 = nvl(SFD.SFD_ALPHA_SHORT_4, tplSchFreeDataCategory.SFD_ALPHA_SHORT_4)
             , SFD.SFD_ALPHA_SHORT_5 = nvl(SFD.SFD_ALPHA_SHORT_5, tplSchFreeDataCategory.SFD_ALPHA_SHORT_5)
             , SFD.SFD_ALPHA_LONG_1 = nvl(SFD.SFD_ALPHA_LONG_1, tplSchFreeDataCategory.SFD_ALPHA_LONG_1)
             , SFD.SFD_ALPHA_LONG_2 = nvl(SFD.SFD_ALPHA_LONG_2, tplSchFreeDataCategory.SFD_ALPHA_LONG_2)
             , SFD.SFD_ALPHA_LONG_3 = nvl(SFD.SFD_ALPHA_LONG_3, tplSchFreeDataCategory.SFD_ALPHA_LONG_3)
             , SFD.SFD_ALPHA_LONG_4 = nvl(SFD.SFD_ALPHA_LONG_4, tplSchFreeDataCategory.SFD_ALPHA_LONG_4)
             , SFD.SFD_ALPHA_LONG_5 = nvl(SFD.SFD_ALPHA_LONG_5, tplSchFreeDataCategory.SFD_ALPHA_LONG_5)
             , SFD.SFD_INTEGER_1 = nvl(SFD.SFD_INTEGER_1, tplSchFreeDataCategory.SFD_INTEGER_1)
             , SFD.SFD_INTEGER_2 = nvl(SFD.SFD_INTEGER_2, tplSchFreeDataCategory.SFD_INTEGER_2)
             , SFD.SFD_INTEGER_3 = nvl(SFD.SFD_INTEGER_3, tplSchFreeDataCategory.SFD_INTEGER_3)
             , SFD.SFD_INTEGER_4 = nvl(SFD.SFD_INTEGER_4, tplSchFreeDataCategory.SFD_INTEGER_4)
             , SFD.SFD_INTEGER_5 = nvl(SFD.SFD_INTEGER_5, tplSchFreeDataCategory.SFD_INTEGER_5)
             , SFD.SFD_BOOLEAN_1 = nvl(SFD.SFD_BOOLEAN_1, tplSchFreeDataCategory.SFD_BOOLEAN_1)
             , SFD.SFD_BOOLEAN_2 = nvl(SFD.SFD_BOOLEAN_2, tplSchFreeDataCategory.SFD_BOOLEAN_2)
             , SFD.SFD_BOOLEAN_3 = nvl(SFD.SFD_BOOLEAN_3, tplSchFreeDataCategory.SFD_BOOLEAN_3)
             , SFD.SFD_BOOLEAN_4 = nvl(SFD.SFD_BOOLEAN_4, tplSchFreeDataCategory.SFD_BOOLEAN_4)
             , SFD.SFD_BOOLEAN_5 = nvl(SFD.SFD_BOOLEAN_5, tplSchFreeDataCategory.SFD_BOOLEAN_5)
             , SFD.SFD_DECIMAL_1 = nvl(SFD.SFD_DECIMAL_1, tplSchFreeDataCategory.SFD_DECIMAL_1)
             , SFD.SFD_DECIMAL_2 = nvl(SFD.SFD_DECIMAL_2, tplSchFreeDataCategory.SFD_DECIMAL_2)
             , SFD.SFD_DECIMAL_3 = nvl(SFD.SFD_DECIMAL_3, tplSchFreeDataCategory.SFD_DECIMAL_3)
             , SFD.SFD_DECIMAL_4 = nvl(SFD.SFD_DECIMAL_4, tplSchFreeDataCategory.SFD_DECIMAL_4)
             , SFD.SFD_DECIMAL_5 = nvl(SFD.SFD_DECIMAL_5, tplSchFreeDataCategory.SFD_DECIMAL_5)
             , SFD.SFD_DATE_1 = nvl(SFD.SFD_DATE_1, tplSchFreeDataCategory.SFD_DATE_1)
             , SFD.SFD_DATE_2 = nvl(SFD.SFD_DATE_2, tplSchFreeDataCategory.SFD_DATE_2)
             , SFD.SFD_DATE_3 = nvl(SFD.SFD_DATE_3, tplSchFreeDataCategory.SFD_DATE_3)
             , SFD.SFD_DATE_4 = nvl(SFD.SFD_DATE_4, tplSchFreeDataCategory.SFD_DATE_4)
             , SFD.SFD_DATE_5 = nvl(SFD.SFD_DATE_5, tplSchFreeDataCategory.SFD_DATE_5)
             , SFD.A_DATEMOD = sysdate
             , SFD.A_IDCRE = PCS.PC_I_LIB_SESSION.GetUserIni
         where SFD.SCH_FREE_DATA_ID = aSCH_FREE_DATA_ID;

        exit;
      end loop;
    -- Sinon on les transfert
    else
      insert into SCH_FREE_DATA
                  (SCH_FREE_DATA_ID
                 , SCH_BILL_POSITION_ID
                 , DIC_SCH_FREE_TABLE1_ID
                 , DIC_SCH_FREE_TABLE2_ID
                 , DIC_SCH_FREE_TABLE3_ID
                 , DIC_SCH_FREE_TABLE4_ID
                 , DIC_SCH_FREE_TABLE5_ID
                 , SFD_ALPHA_SHORT_1
                 , SFD_ALPHA_SHORT_2
                 , SFD_ALPHA_SHORT_3
                 , SFD_ALPHA_SHORT_4
                 , SFD_ALPHA_SHORT_5
                 , SFD_ALPHA_LONG_1
                 , SFD_ALPHA_LONG_2
                 , SFD_ALPHA_LONG_3
                 , SFD_ALPHA_LONG_4
                 , SFD_ALPHA_LONG_5
                 , SFD_INTEGER_1
                 , SFD_INTEGER_2
                 , SFD_INTEGER_3
                 , SFD_INTEGER_4
                 , SFD_INTEGER_5
                 , SFD_BOOLEAN_1
                 , SFD_BOOLEAN_2
                 , SFD_BOOLEAN_3
                 , SFD_BOOLEAN_4
                 , SFD_BOOLEAN_5
                 , SFD_DECIMAL_1
                 , SFD_DECIMAL_2
                 , SFD_DECIMAL_3
                 , SFD_DECIMAL_4
                 , SFD_DECIMAL_5
                 , SFD_DATE_1
                 , SFD_DATE_2
                 , SFD_DATE_3
                 , SFD_DATE_4
                 , SFD_DATE_5
                 , A_DATECRE
                 , A_IDCRE
                 , SFD_CATEGORY_COPY
                 , SFD_TRANSFERT
                  )
        select GetNewId
             , aSCH_BILL_POSITION_ID
             , SFD.DIC_SCH_FREE_TABLE1_ID
             , SFD.DIC_SCH_FREE_TABLE2_ID
             , SFD.DIC_SCH_FREE_TABLE3_ID
             , SFD.DIC_SCH_FREE_TABLE4_ID
             , SFD.DIC_SCH_FREE_TABLE5_ID
             , SFD.SFD_ALPHA_SHORT_1
             , SFD.SFD_ALPHA_SHORT_2
             , SFD.SFD_ALPHA_SHORT_3
             , SFD.SFD_ALPHA_SHORT_4
             , SFD.SFD_ALPHA_SHORT_5
             , SFD.SFD_ALPHA_LONG_1
             , SFD.SFD_ALPHA_LONG_2
             , SFD.SFD_ALPHA_LONG_3
             , SFD.SFD_ALPHA_LONG_4
             , SFD.SFD_ALPHA_LONG_5
             , SFD.SFD_INTEGER_1
             , SFD.SFD_INTEGER_2
             , SFD.SFD_INTEGER_3
             , SFD.SFD_INTEGER_4
             , SFD.SFD_INTEGER_5
             , SFD.SFD_BOOLEAN_1
             , SFD.SFD_BOOLEAN_2
             , SFD.SFD_BOOLEAN_3
             , SFD.SFD_BOOLEAN_4
             , SFD.SFD_BOOLEAN_5
             , SFD.SFD_DECIMAL_1
             , SFD.SFD_DECIMAL_2
             , SFD.SFD_DECIMAL_3
             , SFD.SFD_DECIMAL_4
             , SFD.SFD_DECIMAL_5
             , SFD.SFD_DATE_1
             , SFD.SFD_DATE_2
             , SFD.SFD_DATE_3
             , SFD.SFD_DATE_4
             , SFD.SFD_DATE_5
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
             , 0
             , 0
          from SCH_FREE_DATA SFD
         where SCH_ECOLAGE_CATEGORY_ID = aSCH_ECOLAGE_CATEGORY_ID
           and aSCH_ECOLAGE_CATEGORY_ID is not null
           and SFD.SFD_TRANSFERT = 1;
    end if;
  end TransfertEcolageFreeData;

  /**
  * procedure TransfertOutlayFreeData
  * Description : transfert des données libres des débours saisis sur les
  *               positions de facture.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_BILL_POSITION_ID : Position
  * @param   aSCH_ENTERED_OUTLAY_ID : Débours saisis
  */
  procedure TransfertOutlayFreeData(aSCH_BILL_POSITION_ID number, aSCH_ENTERED_OUTLAY_ID number)
  is
  begin
    insert into SCH_FREE_DATA
                (SCH_FREE_DATA_ID
               , SCH_BILL_POSITION_ID
               , DIC_SCH_FREE_TABLE1_ID
               , DIC_SCH_FREE_TABLE2_ID
               , DIC_SCH_FREE_TABLE3_ID
               , DIC_SCH_FREE_TABLE4_ID
               , DIC_SCH_FREE_TABLE5_ID
               , SFD_ALPHA_SHORT_1
               , SFD_ALPHA_SHORT_2
               , SFD_ALPHA_SHORT_3
               , SFD_ALPHA_SHORT_4
               , SFD_ALPHA_SHORT_5
               , SFD_ALPHA_LONG_1
               , SFD_ALPHA_LONG_2
               , SFD_ALPHA_LONG_3
               , SFD_ALPHA_LONG_4
               , SFD_ALPHA_LONG_5
               , SFD_INTEGER_1
               , SFD_INTEGER_2
               , SFD_INTEGER_3
               , SFD_INTEGER_4
               , SFD_INTEGER_5
               , SFD_BOOLEAN_1
               , SFD_BOOLEAN_2
               , SFD_BOOLEAN_3
               , SFD_BOOLEAN_4
               , SFD_BOOLEAN_5
               , SFD_DECIMAL_1
               , SFD_DECIMAL_2
               , SFD_DECIMAL_3
               , SFD_DECIMAL_4
               , SFD_DECIMAL_5
               , SFD_DATE_1
               , SFD_DATE_2
               , SFD_DATE_3
               , SFD_DATE_4
               , SFD_DATE_5
               , A_DATECRE
               , A_IDCRE
               , SFD_CATEGORY_COPY
               , SFD_TRANSFERT
                )
      select GetNewId
           , aSCH_BILL_POSITION_ID
           , SFD.DIC_SCH_FREE_TABLE1_ID
           , SFD.DIC_SCH_FREE_TABLE2_ID
           , SFD.DIC_SCH_FREE_TABLE3_ID
           , SFD.DIC_SCH_FREE_TABLE4_ID
           , SFD.DIC_SCH_FREE_TABLE5_ID
           , SFD.SFD_ALPHA_SHORT_1
           , SFD.SFD_ALPHA_SHORT_2
           , SFD.SFD_ALPHA_SHORT_3
           , SFD.SFD_ALPHA_SHORT_4
           , SFD.SFD_ALPHA_SHORT_5
           , SFD.SFD_ALPHA_LONG_1
           , SFD.SFD_ALPHA_LONG_2
           , SFD.SFD_ALPHA_LONG_3
           , SFD.SFD_ALPHA_LONG_4
           , SFD.SFD_ALPHA_LONG_5
           , SFD.SFD_INTEGER_1
           , SFD.SFD_INTEGER_2
           , SFD.SFD_INTEGER_3
           , SFD.SFD_INTEGER_4
           , SFD.SFD_INTEGER_5
           , SFD.SFD_BOOLEAN_1
           , SFD.SFD_BOOLEAN_2
           , SFD.SFD_BOOLEAN_3
           , SFD.SFD_BOOLEAN_4
           , SFD.SFD_BOOLEAN_5
           , SFD.SFD_DECIMAL_1
           , SFD.SFD_DECIMAL_2
           , SFD.SFD_DECIMAL_3
           , SFD.SFD_DECIMAL_4
           , SFD.SFD_DECIMAL_5
           , SFD.SFD_DATE_1
           , SFD.SFD_DATE_2
           , SFD.SFD_DATE_3
           , SFD.SFD_DATE_4
           , SFD.SFD_DATE_5
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , 0
           , 0
        from SCH_FREE_DATA SFD
       where (    aSCH_ENTERED_OUTLAY_ID is not null
              and SFD.SCH_ENTERED_OUTLAY_ID = aSCH_ENTERED_OUTLAY_ID)
         and SFD.SFD_TRANSFERT = 1;
  end TransfertOutlayFreeData;

  /**
  * procedure CallStoredProc
  * Description : Exécution de procédure stockées
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_BILL_POSITION : Position
  * @param   aSCH_OUTLAY_ID : débours
  * @param   aSCH_OUTLAY_CATEGORY_ID : Catégorie de débours
  * @param   aSCH_ECOLAGE_ID : Ecolage
  * @param   aSCH_ECOLAGE_CATEGORY_ID : Catégorie d'écolage
  */
  procedure CallStoredProc(
    aHeaderProc           in     integer
  , aSCH_BILL_HEADER_ID   in     number
  , aSCH_BILL_POSITION_ID in     number
  , aSTORED_PROC_NAME     in     varchar2
  , aErrorMsg             in out varchar2
  )
  is
  begin
    aErrorMsg  := null;

    if aHeaderProc = 1 then
      execute immediate ' begin ' || '   :Result :=  ' || aSTORED_PROC_NAME || '(:aSCH_BILL_HEADER_ID);' || ' end;'
                  using out aErrorMsg, in aSCH_BILL_HEADER_ID;
    else
      execute immediate ' begin ' || '   :Result :=  ' || aSTORED_PROC_NAME || '(:aSCH_BILL_HEADER_ID, :aSCH_BILL_POSITION_ID);' || ' end;'
                  using out aErrorMsg, in aSCH_BILL_HEADER_ID, in aSCH_BILL_POSITION_ID;
    end if;
  exception
    when others then
      aErrorMsg  := DBMS_UTILITY.FORMAT_ERROR_STACK;
  end CallStoredProc;

  /**
  * procedure DuplicateBill
  * Description : Exécution de procédure stockées
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSCH_BILL_HEADER_ID : Facture à duppliquer
  */
  function DuplicateBill(iSCH_BILL_HEADER_ID in number)
    return number
  is
    lnNewSchBillHeaderId       number;
    lnIDBuffer                 number;
    lnIDBuffer2                number;
    lvNewHeaNumber             SCH_BILL_HEADER.HEA_NUMBER%type;
    liHEA_ECOLAGE              integer;
    liSTU_ACCOUNT_NUMBER       integer;
    lvPER_KEY1                 PAC_PERSON.PER_KEY1%type;
    lnSCH_GROUP_YEAR_PERIOD_ID number;
    lnSCH_STUDENT_ID           number;
  begin
    -- Récupération d'un nouveau numéro de facture
    select HEA.HEA_ECOLAGE
         , STU.STU_ACCOUNT_NUMBER
         , PER.PER_KEY1
         , HEA.SCH_GROUP_YEAR_PERIOD_ID
         , HEA.SCH_STUDENT_ID
      into liHEA_ECOLAGE
         , liSTU_ACCOUNT_NUMBER
         , lvPER_KEY1
         , lnSCH_GROUP_YEAR_PERIOD_ID
         , lnSCH_STUDENT_ID
      from SCH_BILL_HEADER HEA
         , SCH_STUDENT STU
         , PAC_PERSON PER
     where HEA.SCH_BILL_HEADER_ID = iSCH_BILL_HEADER_ID
       and HEA.SCH_STUDENT_ID = STU.SCH_STUDENT_ID(+)
       and HEA.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID(+);

    SCH_OUTLAY_BILLING.SelectPeriods(lnSCH_GROUP_YEAR_PERIOD_ID);
    lvNewHeaNumber  := GetNewHeaNumber(liHEA_ECOLAGE, liSTU_ACCOUNT_NUMBER, lvPER_KEY1, lnSCH_GROUP_YEAR_PERIOD_ID, lnSCH_STUDENT_ID);

    -- Réservation de l'ID
    select INIT_ID_SEQ.nextval
      into lnNewSchBillHeaderId
      from dual;

    -- Chargement de l'entête à copier
    declare
      ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    begin
      FWK_I_MGT_ENTITY.new(FWK_TYP_SCH_ENTITY.gcschbillheader, ltCRUD_DEF, true);
      FWK_I_MGT_ENTITY.load(ltCRUD_DEF, iSCH_BILL_HEADER_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_BILL_HEADER_ID', lnNewSchBillHeaderId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATECRE', sysdate);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATEMOD', cast(null as date) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDCRE', PCS.PC_I_LIB_SESSION.GetUserIni);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDMOD', cast(null as varchar2) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'HEA_NUMBER', lvNewHeaNumber);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'HEA_ORACLE_SESSION', cast(null as varchar2) );
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_HEA_STATUS', '20');
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_DOCUMENT_ID', cast(null as number) );
      FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end;

    -- Copie données libres d'entête
    for tplHeaderFreeData in (select SCH_FREE_DATA_ID
                                from SCH_FREE_DATA
                               where SCH_BILL_HEADER_ID = iSCH_BILL_HEADER_ID) loop
      select INIT_ID_SEQ.nextval
        into lnIDBuffer
        from dual;

      declare
        ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
      begin
        FWK_I_MGT_ENTITY.new(FWK_TYP_SCH_ENTITY.gcschfreedata, ltCRUD_DEF, true);
        FWK_I_MGT_ENTITY.load(ltCRUD_DEF, tplHeaderFreeData.SCH_FREE_DATA_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_FREE_DATA_ID', lnIDBuffer);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_BILL_HEADER_ID', lnNewSchBillHeaderId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATECRE', sysdate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATEMOD', cast(null as date) );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDCRE', PCS.PC_I_LIB_SESSION.GetUserIni);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDMOD', cast(null as varchar2) );
        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end;

      exit;
    end loop;

    -- Copie des positions
    for tplPosition in (select SCH_BILL_POSITION_ID
                          from SCH_BILL_POSITION
                         where SCH_BILL_HEADER_ID = iSCH_BILL_HEADER_ID) loop
      select INIT_ID_SEQ.nextval
        into lnIDBuffer
        from dual;

      declare
        ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
      begin
        FWK_I_MGT_ENTITY.new(FWK_TYP_SCH_ENTITY.gcschbillposition, ltCRUD_DEF, true);
        FWK_I_MGT_ENTITY.load(ltCRUD_DEF, tplPosition.SCH_BILL_POSITION_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_BILL_POSITION_ID', lnIDBuffer);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_BILL_HEADER_ID', lnNewSchBillHeaderId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATECRE', sysdate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATEMOD', cast(null as date) );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDCRE', PCS.PC_I_LIB_SESSION.GetUserIni);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDMOD', cast(null as varchar2) );
        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end;

      -- Copie données libres de positions
      for tplPositionFreeData in (select SFD.SCH_FREE_DATA_ID
                                       , SFD.SCH_BILL_POSITION_ID
                                    from SCH_FREE_DATA SFD
                                   where SFD.SCH_BILL_POSITION_ID = tplPosition.SCH_BILL_POSITION_ID) loop
        select INIT_ID_SEQ.nextval
          into lnIDBuffer2
          from dual;

        declare
          ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
        begin
          FWK_I_MGT_ENTITY.new(FWK_TYP_SCH_ENTITY.gcschfreedata, ltCRUD_DEF, true);
          FWK_I_MGT_ENTITY.load(ltCRUD_DEF, tplPositionFreeData.SCH_FREE_DATA_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_FREE_DATA_ID', lnIDBuffer2);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_BILL_POSITION_ID', lnIDBuffer);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATECRE', sysdate);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATEMOD', cast(null as date) );
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDCRE', PCS.PC_I_LIB_SESSION.GetUserIni);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDMOD', cast(null as varchar2) );
          FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
          FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
        end;

        exit;
      end loop;
    end loop;

    -- Retour facture copiée
    return lnNewSchBillHeaderId;
  end DuplicateBill;

  /**
  * procedure GetCDA
  * Description : Recherche du centre d'analyse pour facturation
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSCH_STUDENT_ID : Résident
  * @param   iSCH_OUTLAY_ID : Prestation
  * @param   iSCH_OUTLAY_CATEGORY_ID : Catégorie de prestation
  * @param   iPAC_CUSTOM_PARTNER_ID : Client
  * @param   iValueDate : Date Valeur
  * @param   iSCH_ENTERED_OUTLAY_ID : Ligne de débours saisis
  */
  function GetCDA(
    iSCH_STUDENT_ID         in number
  , iSCH_OUTLAY_ID          in number
  , iSCH_OUTLAY_CATEGORY_ID in number
  , iPAC_CUSTOM_PARTNER_ID  in number
  , iValueDate              in date
  , iSCH_ENTERED_OUTLAY_ID  in number default null
  )
    return number
  is
    liExecStandard       integer;
    lcSchPrcGetCDAIndiv  varchar2(255);
    lnACS_CDA_ACCOUNT_ID number;
    blnContinue          boolean;
  begin
    liExecStandard       := 1;
    lcSchPrcGetCDAIndiv  := PCS.PC_CONFIG.GetConfig('SCH_PRC_BILLING_GET_CDA');

    if not lcSchPrcGetCDAIndiv is null then
      GetCDAIndiv(lcSchPrcGetCDAIndiv
                , iSCH_STUDENT_ID
                , iSCH_OUTLAY_ID
                , iSCH_OUTLAY_CATEGORY_ID
                , iPAC_CUSTOM_PARTNER_ID
                , iValueDate
                , iSCH_ENTERED_OUTLAY_ID
                , lnACS_CDA_ACCOUNT_ID
                , liExecStandard
                 );
    end if;

    if liExecStandard = 1 then
      lnACS_CDA_ACCOUNT_ID  := null;

      -- Recherche dans la matrice
      begin
        select max(CAS.ACS_CDA_ACCOUNT_ID)
          into lnACS_CDA_ACCOUNT_ID
          from SCH_CUSTOMERS_ASSOCIATION CAS
         where (   CAS.CAS_VALIDITY_DATE is null
                or (    CAS.CAS_VALIDITY_DATE is not null
                    and nvl(iValueDate, sysdate) >= CAS.CAS_VALIDITY_DATE
                    and CAS.CAS_VALIDITY_DATE =
                          (select min(CAS2.CAS_VALIDITY_DATE)
                             from SCH_CUSTOMERS_ASSOCIATION CAS2
                            where CAS2.SCH_OUTLAY_ID = iSCH_OUTLAY_ID
                              and (   iSCH_STUDENT_ID is null
                                   or CAS2.SCH_STUDENT_ID = iSCH_STUDENT_ID)
                              and (   iSCH_OUTLAY_CATEGORY_ID is null
                                   or CAS2.SCH_OUTLAY_CATEGORY_ID = iSCH_OUTLAY_CATEGORY_ID)
                              and (   iPAC_CUSTOM_PARTNER_ID is null
                                   or CAS2.PAC_CUSTOM_PARTNER_ID = iPAC_CUSTOM_PARTNER_ID)
                              and nvl(CAS2.ACS_CDA_ACCOUNT_ID, 0) <> 0)
                   )
               )
           and CAS.SCH_OUTLAY_ID = iSCH_OUTLAY_ID
           and (   iSCH_STUDENT_ID is null
                or CAS.SCH_STUDENT_ID = iSCH_STUDENT_ID)
           and (   iSCH_OUTLAY_CATEGORY_ID is null
                or CAS.SCH_OUTLAY_CATEGORY_ID = iSCH_OUTLAY_CATEGORY_ID)
           and (   iPAC_CUSTOM_PARTNER_ID is null
                or CAS.PAC_CUSTOM_PARTNER_ID = iPAC_CUSTOM_PARTNER_ID)
           and nvl(CAS.ACS_CDA_ACCOUNT_ID, 0) <> 0;

        blnContinue  := lnACS_CDA_ACCOUNT_ID is null;
      exception
        when no_data_found then
          blnContinue  := true;
      end;
    end if;

    if blnContinue then
      -- Recherche sur l'élève
      begin
        select ACS_CDA_ACCOUNT_ID
          into lnACS_CDA_ACCOUNT_ID
          from SCH_STUDENT
         where SCH_STUDENT_ID = iSCH_STUDENT_ID
           and ACS_CDA_ACCOUNT_ID is not null;

        blnContinue  := lnACS_CDA_ACCOUNT_ID is null;
      exception
        when no_data_found then
          blnContinue  := true;
      end;
    end if;

    if blnContinue then
      -- Recherche sur le service lié
      begin
        select GID.ACS_CDA_ACCOUNT_ID
          into lnACS_CDA_ACCOUNT_ID
          from SCH_OUTLAY_CATEGORY COU
             , GCO_IMPUT_DOC GID
         where COU.SCH_OUTLAY_CATEGORY_ID = iSCH_OUTLAY_CATEGORY_ID
           and GID.GCO_GOOD_ID = COU.GCO_GOOD_ID
           and GID.ACS_CDA_ACCOUNT_ID is not null;
      exception
        when no_data_found then
          lnACS_CDA_ACCOUNT_ID  := null;
      end;
    end if;

    return lnACS_CDA_ACCOUNT_ID;
  end GetCDA;

  /**
  * procedure GetFilterCDA
  * Description : Recherche du centre d'analyse pour le filtre
  *               d'import des prestations, de pré-facturation
  *
  * @created RBA
  * @lastUpdate
  * @public
  * @param   iLPM_ENTERED_OUTLAY_ID : Dépenses d'entrée
  * @param   iSCH_ENTERED_OUTLAY_ID : Ligne de débours saisies
  * @param   iSCH_BILL_HEADER_ID    : Entête facture d'écolage
  */
  function GetFilterCDA(iLPM_ENTERED_OUTLAY_ID in number default null, iSCH_ENTERED_OUTLAY_ID in number default null, iSCH_BILL_HEADER_ID in number default null)
    return number
  is
    liExecStandard       integer;
    lcSchPrcGetCDAIndiv  varchar2(255);
    lnACS_CDA_ACCOUNT_ID number;
  begin
    liExecStandard       := 1;
    lcSchPrcGetCDAIndiv  := PCS.PC_CONFIG.GetConfig('SCH_PRC_BILLING_GET_FILTER_CDA');

    if not lcSchPrcGetCDAIndiv is null then
      GetFilterCDAIndiv(lcSchPrcGetCDAIndiv, iLPM_ENTERED_OUTLAY_ID, iSCH_ENTERED_OUTLAY_ID, iSCH_BILL_HEADER_ID, lnACS_CDA_ACCOUNT_ID, liExecStandard);
    end if;

    if liExecStandard = 1 then
      lnACS_CDA_ACCOUNT_ID  := null;

      -- Recherche sur l'élève en fonction de l'id de la dépense d'entrée
      if not iLPM_ENTERED_OUTLAY_ID is null then
        begin
          select SCH.ACS_CDA_ACCOUNT_ID
            into lnACS_CDA_ACCOUNT_ID
            from LPM_ENTERED_OUTLAY EOU
               , SCH_STUDENT SCH
           where EOU.LPM_ENTERED_OUTLAY_ID = iLPM_ENTERED_OUTLAY_ID
             and EOU.SCH_STUDENT_ID = SCH.SCH_STUDENT_ID
             and ACS_CDA_ACCOUNT_ID is not null;
        exception
          when no_data_found then
            lnACS_CDA_ACCOUNT_ID  := null;
        end;
      -- Recherche sur l'élève en fonction de l'id de la ligne de débours saisies
      elsif not iSCH_ENTERED_OUTLAY_ID is null then
        begin
          select SCH.ACS_CDA_ACCOUNT_ID
            into lnACS_CDA_ACCOUNT_ID
            from SCH_ENTERED_OUTLAY EOU
               , SCH_STUDENT SCH
           where EOU.SCH_ENTERED_OUTLAY_ID = iSCH_ENTERED_OUTLAY_ID
             and EOU.SCH_STUDENT_ID = SCH.SCH_STUDENT_ID
             and SCH.ACS_CDA_ACCOUNT_ID is not null;
        exception
          when no_data_found then
            lnACS_CDA_ACCOUNT_ID  := null;
        end;
      -- Recherche sur l'élève en fonction de l'id de l'entête facture d'écolage
      elsif not iSCH_BILL_HEADER_ID is null then
        begin
          select SCH.ACS_CDA_ACCOUNT_ID
            into lnACS_CDA_ACCOUNT_ID
            from SCH_BILL_HEADER HEA
               , SCH_STUDENT SCH
           where HEA.SCH_BILL_HEADER_ID = iSCH_BILL_HEADER_ID
             and HEA.SCH_STUDENT_ID = SCH.SCH_STUDENT_ID
             and SCH.ACS_CDA_ACCOUNT_ID is not null;
        exception
          when no_data_found then
            lnACS_CDA_ACCOUNT_ID  := null;
        end;
      end if;
    end if;

    return lnACS_CDA_ACCOUNT_ID;
  end GetFilterCDA;

  /**
  * procedure SetExpenseNote
  * Description : Procédure déclenchée par la création d'une note de frais
  *                - Initialise le champ "Note de frais" sur la facture de prestation liée au document
  *                - Réinitialise les prestations en "à facturer"
  * @created CLG
  * @lastUpdate
  * @public
  * @param   aDocDocumentId  : ID du document d'origine
  * @param   aDocDocument2Id : ID de la note de frais
  */
  procedure SetExpenseNote(aDocDocumentId number, aDocDocument2Id number)
  is
  begin
    -- Initialisation du champ "Note de frais" sur la facture de prestation liée au document
    update SCH_BILL_HEADER
       set DOC_DOCUMENT2_ID = aDocDocument2Id
     where DOC_DOCUMENT_ID = aDocDocumentId;

    -- Réinitialisation des prestations en "à facturer"
    update SCH_ENTERED_OUTLAY SEO
       set EOU_STATUS = 1
     where SEO.SCH_ENTERED_OUTLAY_ID in(select POS.SCH_ENTERED_OUTLAY_ID
                                          from SCH_BILL_HEADER HEAD
                                             , SCH_BILL_POSITION POS
                                         where HEAD.SCH_BILL_HEADER_ID = POS.SCH_BILL_HEADER_ID
                                           and HEAD.DOC_DOCUMENT_ID = aDocDocumentId);

    -- Suppression des clés étrangère afin de permettre la suppression de ces prestations.
    update SCH_BILL_POSITION
       set SCH_ENTERED_OUTLAY_ID = null
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where SCH_BILL_HEADER_ID in(select SCH_BILL_HEADER_ID
                                   from SCH_BILL_HEADER
                                  where DOC_DOCUMENT_ID = aDocDocumentId
                                    and DOC_DOCUMENT2_ID = aDocDocument2Id);
  end SetExpenseNote;
end SCH_BILLING_FUNCTIONS;
