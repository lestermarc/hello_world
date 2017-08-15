--------------------------------------------------------
--  DDL for Package Body SCH_TOOLS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SCH_TOOLS" 
is
  /***
  *  Fonction qui renvoie la description pour un élément d'un DICO, correspondant
  *  à la langue de l'utilisateur
  */
  function GetDicoDescr(aTable varchar2, aCode varchar2, LangId in pcs.pc_lang.pc_lang_id%type default pcs.PC_I_LIB_SESSION.GetUserLangId)
    return DICO_DESCRIPTION.DIT_DESCR%type
  is
    tmp DICO_DESCRIPTION.dit_descr%type;
  begin
    select DIT_DESCR
      into tmp
      from DICO_DESCRIPTION
     where DIT_TABLE = aTable
       and DIT_CODE = aCode
       and PC_LANG_ID = LangId;

    return tmp;
  exception
    when no_data_found then
      return '';
    when others then
      return '';
  end GetDicoDescr;

  /***
  *   Procedure d'insertion d'un nouvelle ligne dans la table de référence sch_Discount_Field_Type
  *
  */
  procedure New_Discount_Field_Type(FieldName varchar2, FieldDescr varchar2, TableName varchar2)
  is
  begin
    insert into SCH_DISCOUNT_FIELD_TYPE
                (SCH_DISCOUNT_FIELD_TYPE_ID
               , FIT_NAME
               , FIT_DESCR
               , FIT_TABLE_NAME
               , A_DATECRE
               , A_IDCRE
                )
         values (INIT_ID_SEQ.nextval
               , FieldName
               , FieldDescr
               , TableName
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    commit;
  end New_Discount_Field_Type;

  /***
  *   Procedure d'insertion d'un nouvelle ligne dans la table de référence sch_Discount_Field_Type
  *
  */
  procedure New_Discount_Config_Type(ConfName varchar2, ConfDescr varchar2)
  is
  begin
    insert into SCH_DISCOUNT_CONFIG_TYPE
                (SCH_DISCOUNT_CONFIG_TYPE_ID
               , CON_NAME
               , CON_DESCR
               , A_DATECRE
               , A_IDCRE
                )
         values (INIT_ID_SEQ.nextval
               , ConfName
               , ConfDescr
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    commit;
  end New_Discount_Config_Type;

  /***
  * Fonction qui renvoie True si une période à déjà fait l'objet d'une facturation
  * et qui renvoie false sinon.
  */
  function Is_Billed_Period(PrmSCH_YEAR_PERIOD_ID SCH_YEAR_PERIOD.SCH_YEAR_PERIOD_ID%type)
    return boolean
  is
    Nb_Lignes_Facturees integer;
  begin
    /*
     Sélection d'une Nb de lignes dans la table de facturation correspondant au groupe
     de la période concernée
    */
    Nb_Lignes_Facturees  := 0;

    select nvl(count(PLINK.SCH_PERIOD_GRP_PERIOD_LINK_ID), 0) NB_PERIOD_LINKED
      into Nb_Lignes_Facturees
      from SCH_PERIOD_GRP_PERIOD_LINK PLINK
         , SCH_BILLING_HISTORY HIS
     where PLINK.SCH_YEAR_PERIOD_ID = PrmSCH_YEAR_PERIOD_ID
       and PLINK.SCH_GROUP_YEAR_PERIOD_ID = HIS.SCH_GROUP_YEAR_PERIOD_ID(+);

    if Nb_Lignes_Facturees <> 0 then
      return true;
    else
      return false;
    end if;
  exception
    when no_data_found then
      return false;
  end Is_Billed_Period;

  /***
  *  Procedure qui retourne les caractéristiques d'une catégorie de débours
  *
  */
  procedure GetOutlayCategoryInformations(
    PrmOUT_MAJOR_REFERENCE in     SCH_OUTLAY.OUT_MAJOR_REFERENCE%type
  , PrmCOU_MAJOR_REFERENCE in     SCH_OUTLAY_CATEGORY.COU_MAJOR_REFERENCE%type
  , PrmCOU_DEFAULT_QTY     in out integer
  , PrmCOU_QTY             in out SCH_OUTLAY_CATEGORY.COU_QTY%type
  , PrmCOU_UNIT_AMOUNT     in out SCH_OUTLAY_CATEGORY.COU_UNIT_AMOUNT%type
  )
  is
    -- Curseur
    cursor CUR_SCH_OUTLAY_CATEGORY
    is
      select 1 COU_DEFAULT_QTY
           , SOC.COU_QTY
           , SOC.COU_UNIT_AMOUNT
        from SCH_OUTLAY SO
           , SCH_OUTLAY_CATEGORY SOC
       where SO.OUT_MAJOR_REFERENCE = PrmOUT_MAJOR_REFERENCE
         and SOC.COU_MAJOR_REFERENCE = PrmCOU_MAJOR_REFERENCE
         and SO.SCH_OUTLAY_ID = SOC.SCH_OUTLAY_ID;

    -- Variables
    CurSchOutlayCategory CUR_SCH_OUTLAY_CATEGORY%rowtype;
  begin
    open CUR_SCH_OUTLAY_CATEGORY;

    fetch CUR_SCH_OUTLAY_CATEGORY
     into CurSchOutlayCategory;

    PrmCOU_DEFAULT_QTY  := CurSchOutlayCategory.COU_DEFAULT_QTY;
    PrmCOU_QTY          := CurSchOutlayCategory.COU_QTY;
    PrmCOU_UNIT_AMOUNT  := CurSchOutlayCategory.COU_UNIT_AMOUNT;

    close CUR_SCH_OUTLAY_CATEGORY;
  end GetOutlayCategoryInformations;

  /***
  * Procedure qui renvoie l'année (sa Short Descr) d'une période donnée
  *
  */
  function GetPeriodYear(PrmSCH_YEAR_PERIOD_ID SCH_YEAR_PERIOD.SCH_YEAR_PERIOD_ID%type)
    return varchar2
  is
    -- Curseurs
    cursor CUR_SCHOOL_YEAR
    is
      select SCO.SCO_SHORT_DESCR
        from SCH_SCHOOL_YEAR SCO
           , SCH_YEAR_PERIOD PER
       where PER.SCH_YEAR_PERIOD_ID = PrmSCH_YEAR_PERIOD_ID
         and PER.SCH_SCHOOL_YEAR_ID = SCO.SCH_SCHOOL_YEAR_ID;

    -- Variables
    CurSchoolYear CUR_SCHOOL_YEAR%rowtype;
    Annee         varchar2(200);
  begin
    Annee  := '';

    for CurSchoolYear in CUR_SCHOOL_YEAR loop
      Annee  := CurSchoolYear.SCO_SHORT_DESCR;
    end loop;

    return Annee;
  end GetPeriodYear;

  /***
  *   Procedure qui renvoi les infos du dossier llié à l'élève
  *
  */
  procedure GetDocRecordFromStudent(
    PrmSTU_ACCOUNT_NUMBER in     SCH_STUDENT.STU_ACCOUNT_NUMBER%type
  , PrmDOC_RECORD_ID      in out DOC_RECORD.DOC_RECORD_ID%type
  , PrmRCO_NUMBER         in out DOC_RECORD.RCO_NUMBER%type
  , PrmRCO_TITLE          in out DOC_RECORD.RCO_TITLE%type
  )
  is
    -- Curseur sur les dossiers
    cursor CUR_DOC_RECORD_ID
    is
      select DOC_RECORD_ID
           , RCO_NUMBER
           , RCO_TITLE
        from DOC_RECORD
       where RCO_TITLE = to_char(PrmSTU_ACCOUNT_NUMBER);

    -- Variables
    CurDocRecordId CUR_DOC_RECORD_ID%rowtype;
  begin
    -- sélection d'informations sur le dossier lié à l'élève
    open CUR_DOC_RECORD_ID;

    fetch CUR_DOC_RECORD_ID
     into CurDocRecordId;

    if CUR_DOC_RECORD_ID%found then
      PrmDOC_RECORD_ID  := CurDocRecordId.DOC_RECORD_ID;
      PrmRCO_NUMBER     := CurDocRecordId.RCO_NUMBER;
      PrmRCO_TITLE      := CurDocRecordId.RCO_TITLE;
    else
      PrmDOC_RECORD_ID  := null;
      PrmRCO_NUMBER     := null;
      PrmRCO_TITLE      := null;
    end if;

    close CUR_DOC_RECORD_ID;
  end GetDocRecordFromStudent;

  /***
  * Procedure qui renvoie les informations sur la TVA pour une position donnée
  *
  */
  procedure GetVatInfo(
    PrmSCH_ECOLAGE_ID       in     SCH_ECOLAGE.SCH_ECOLAGE_ID%type
  , PrmSCH_DISCOUNT_ID      in     SCH_DISCOUNT.SCH_DISCOUNT_ID%type
  , PrmSCH_OUTLAY_ID        in     SCH_OUTLAY.SCH_OUTLAY_ID%type
  , PrmSCH_BILL_HEADER_ID   in     SCH_BILL_HEADER.SCH_BILL_HEADER_ID%type
  , PrmACS_TAX_CODE_ID      in out ACS_TAX_CODE.ACS_TAX_CODE_ID%type
  , PrmDIC_TYPE_VAT_GOOD_ID in out DIC_TYPE_VAT_GOOD.DIC_TYPE_VAT_GOOD_ID%type
  , PrmBOP_TTC_AMOUNT       in out SCH_BILL_POSITION.BOP_TTC_AMOUNT%type
  , PrmBOP_HT_AMOUNT        in out SCH_BILL_POSITION.BOP_HT_AMOUNT%type
  , PrmBOP_VAT_AMOUNT       in out SCH_BILL_POSITION.BOP_VAT_AMOUNT%type
  )
  is
    -- Curseur pour TVA
    cursor CUR_SCH_POSITION_VAT
    is
      select distinct SBH.PAC_CUSTOM_PARTNER_ID
                    , SBH.DIC_TYPE_SUBMISSION_ID
                    , SBH.ACS_VAT_DET_ACCOUNT_ID
                    , SBH.HEA_BILL_DATE
                    , DGS.DIC_TYPE_MOVEMENT_ID
                 from SCH_BILL_HEADER SBH
                    , DOC_GAUGE_STRUCTURED DGS
                where SBH.SCH_BILL_HEADER_ID = PrmSCH_BILL_HEADER_ID
                  and SBH.DOC_GAUGE_ID = DGS.DOC_GAUGE_ID;

    -- Variables :
    CurSchPositionVat         CUR_SCH_POSITION_VAT%rowtype;
    VarPAC_CUSTOM_PARTNER_ID  number;
    VarDIC_TYPE_SUBMISSION_ID DIC_TYPE_SUBMISSION.DIC_TYPE_SUBMISSION_ID%type;
    VarACS_VAT_DET_ACCOUNT_ID number;
    VarHEA_BILL_DATE          date;
    VarDIC_TYPE_MOVEMENT_ID   DIC_TYPE_MOVEMENT.DIC_TYPE_MOVEMENT_ID%type;
    VarGCO_GOOD_ID            number;
  begin
    open CUR_SCH_POSITION_VAT;

    fetch CUR_SCH_POSITION_VAT
     into CurSchPositionVat;

    VarPAC_CUSTOM_PARTNER_ID   := CurSchPositionVat.PAC_CUSTOM_PARTNER_ID;
    VarDIC_TYPE_SUBMISSION_ID  := CurSchPositionVat.DIC_TYPE_SUBMISSION_ID;
    VarACS_VAT_DET_ACCOUNT_ID  := CurSchPositionVat.ACS_VAT_DET_ACCOUNT_ID;
    VarHEA_BILL_DATE           := CurSchPositionVat.HEA_BILL_DATE;
    VarDIC_TYPE_MOVEMENT_ID    := CurSchPositionVat.DIC_TYPE_MOVEMENT_ID;

    close CUR_SCH_POSITION_VAT;

    if PrmSCH_ECOLAGE_ID <> 0 then
      select GCO_GOOD_ID
        into VarGCO_GOOD_ID
        from SCH_ECOLAGE
       where SCH_ECOLAGE_ID = PrmSCH_ECOLAGE_ID;
    elsif PrmSCH_DISCOUNT_ID <> 0 then
      select GCO_GOOD_ID
        into VarGCO_GOOD_ID
        from SCH_DISCOUNT
       where SCH_DISCOUNT_ID = PrmSCH_DISCOUNT_ID;
    elsif PrmSCH_OUTLAY_ID <> 0 then
      select GCO_GOOD_ID
        into VarGCO_GOOD_ID
        from SCH_OUTLAY
       where SCH_OUTLAY_ID = PrmSCH_OUTLAY_ID;
    end if;

    PrmACS_TAX_CODE_ID         :=
      nvl
        (ACS_I_LIB_LOGISTIC_FINANCIAL.GetVatCode
                                           (1
                                          ,   -- 1 position bien
                                            VarPAC_CUSTOM_PARTNER_ID
                                          ,   -- Id du tiers
                                            VarGCO_GOOD_ID
                                          ,   -- Id du bien
                                            null
                                          ,   -- Id de la remise
                                            null
                                          ,   -- Id de la taxe
                                            '2'
                                          ,   -- Code domaine : Domaine des ventes
                                            VarDIC_TYPE_SUBMISSION_ID
                                          ,   -- valeur de DIC_TYPE_SUBMISSION_ID du document
                                            VarDIC_TYPE_MOVEMENT_ID
                                          ,   -- valeur de DIC_TYPE_MOVEMENT_ID du gabarit structuré
                                            VarACS_VAT_DET_ACCOUNT_ID
                                           )   -- DOC_DOCUMENT.ACS_VAT_DET_ACCOUNT_ID
       , 0
        );

    select nvl(max(DIC_TYPE_VAT_GOOD_ID), PCS.PC_CONFIG.GetConfig('GCO_DefltTYPE_VAT_GOOD') )
      into PrmDIC_TYPE_VAT_GOOD_ID
      from GCO_VAT_GOOD
     where GCO_GOOD_ID = VarGCO_GOOD_ID
       and ACS_VAT_DET_ACCOUNT_ID = VarACS_VAT_DET_ACCOUNT_ID;

    /* Calcul du montant de la TVA */
    if PrmACS_TAX_CODE_ID <> 0 then
      PrmBOP_VAT_AMOUNT  :=
        ACS_FUNCTION.CALCVATAMOUNT(PrmBOP_TTC_AMOUNT,   -- montant soumis à la taxe
                                   PrmACS_TAX_CODE_ID,   -- id du code taxe
                                   'I',   -- include/exclude
                                   VarHEA_BILL_DATE,   -- date de référence
                                   0);   -- Pas d'arrondit ;
    else
      PrmBOP_VAT_AMOUNT  := 0;
    end if;

    PrmBOP_HT_AMOUNT           := round( (PrmBOP_TTC_AMOUNT - PrmBOP_VAT_AMOUNT), 2);
  end GetVatInfo;

  /***
  * Fonction qui renvoie le nom du débiteur
  *
  */
  function GetCustomerNames(PrmPAC_CUSTOM_PARTNER_ID PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type)
    return varchar2
  is
    Customer_Names varchar2(150);
  begin
    select (PER_NAME || ' ' || PER_FORENAME)
      into Customer_Names
      from PAC_PERSON
     where PAC_PERSON_ID = PrmPAC_CUSTOM_PARTNER_ID;

    return Customer_Names;
  end GetCustomerNames;

  /***
  *  Function qui renvoie l'ID de la monnaie de base de la société
  *
  */
  function GetBaseMoney
    return ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  is
    VarBASE_MONEY ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    select ACS_FINANCIAL_CURRENCY_ID
      into VarBASE_MONEY
      from ACS_FINANCIAL_CURRENCY
     where FIN_LOCAL_CURRENCY = 1;

    return VarBASE_MONEY;
  end GetBaseMoney;

  /***
   Function qui renvoie la description de la période numéro PrmNum_Periode de l'année
   passée en paramètre. Cette fonction est utilisée en Crystal (Rapport SCH_ECOLAGE_AMOUNT)
  */
  function GetPeriodeDescr(PrmSCH_SCHOOL_YEAR_ID SCH_SCHOOL_YEAR.SCH_SCHOOL_YEAR_ID%type, PrmNum_Periode integer)
    return varchar2
  is
    -- Curseurs
    cursor CUR_SCH_PERIODE
    is
      select   PER_SHORT_DESCR
          from SCH_YEAR_PERIOD
         where SCH_SCHOOL_YEAR_ID = PrmSCH_SCHOOL_YEAR_ID
      order by PER_BEGIN_DATE asc;

    --Variables
    CurSchPeriode CUR_SCH_PERIODE%rowtype;
    LoopCounter   integer;
    Resultat      varchar2(50);
  begin
    LoopCounter  := 0;
    Resultat     := '';

    for CurSchPeriode in CUR_SCH_PERIODE loop
      LoopCounter  := LoopCounter + 1;

      if LoopCounter = PrmNum_Periode then
        Resultat  := CurSchPeriode.PER_SHORT_DESCR;
      end if;
    end loop;

    return Resultat;
  end GetPeriodeDescr;

  /***
  * Function qui renvoie le montant (Ou une description du montant) d'un écolage.
  * Utilisée dans crystal
  *
  */
  function GetEcolageAmount(
    PrmSCH_SCHOOL_YEAR_ID      SCH_SCHOOL_YEAR.SCH_SCHOOL_YEAR_ID%type
  , PrmNum_Periode             integer
  , PrmSCH_ECOLAGE_CATEGORY_ID SCH_ECOLAGE_CATEGORY.SCH_ECOLAGE_CATEGORY_ID%type
  , PrmSCH_DISCOUNT_ID         SCH_DISCOUNT.SCH_DISCOUNT_ID%type
  )
    return varchar2
  is
    -- Curseurs
    cursor CUR_SCH_PERIODE
    is
      select   SCH_YEAR_PERIOD_ID
          from SCH_YEAR_PERIOD
         where SCH_SCHOOL_YEAR_ID = PrmSCH_SCHOOL_YEAR_ID
      order by PER_BEGIN_DATE asc;

    -- Sur les écolages
    cursor CUR_SCH_ECOLAGE
    is
      select CAT.C_ECOLAGE_TYPE_AMOUNT
           , nvl(CAT.CAT_CONTRACTUAL_AMOUNT, 0) CAT_CONTRACTUAL_AMOUNT
           , CONFIG.CON_NAME
           , CONFIG.CON_DESCR
           , field.FIT_NAME
           , field.FIT_DESCR
           , field.FIT_TABLE_NAME
           , CARACT.CHT_SHORT_DESCR
        from SCH_ECOLAGE_CATEGORY CAT
           , SCH_DISCOUNT_CONFIG_TYPE CONFIG
           , SCH_DISCOUNT_FIELD_TYPE field
           , SCH_FREE_CHARACT_TYPE CARACT
       where CAT.SCH_DISCOUNT_CONFIG_TYPE_ID = CONFIG.SCH_DISCOUNT_CONFIG_TYPE_ID(+)
         and CAT.SCH_DISCOUNT_FIELD_TYPE_ID = field.SCH_DISCOUNT_FIELD_TYPE_ID(+)
         and CAT.SCH_FREE_CHARACT_TYPE_ID = CARACT.SCH_FREE_CHARACT_TYPE_ID(+)
         and CAT.SCH_ECOLAGE_CATEGORY_ID = PrmSCH_ECOLAGE_CATEGORY_ID;

    -- Sur les remises
    cursor CUR_SCH_DISCOUNT
    is
      select nvl(DIS.DIS_AMOUNT_OR_RATE, 0) DIS_AMOUNT_OR_RATE
           , nvl(DIS.SCH_DISCOUNT_CONFIG_TYPE_ID, 0) SCH_DISCOUNT_CONFIG_TYPE_ID
           , nvl(DIS.SCH_DISCOUNT_FIELD_TYPE_ID, 0) SCH_DISCOUNT_FIELD_TYPE_ID
           , nvl(DIS.SCH_FREE_CHARACT_TYPE_ID, 0) SCH_FREE_CHARACT_TYPE_ID
           , DIS.C_DISCOUNT_TYPE_AMOUNT
           , nvl(DIS.DIS_TTC_AMOUNT, 0) DIS_TTC_AMOUNT
           , CONFIG.CON_NAME
           , CONFIG.CON_DESCR
           , field.FIT_NAME
           , field.FIT_DESCR
           , field.FIT_TABLE_NAME
           , CARACT.CHT_SHORT_DESCR
        from SCH_DISCOUNT DIS
           , SCH_DISCOUNT_CONFIG_TYPE CONFIG
           , SCH_DISCOUNT_FIELD_TYPE field
           , SCH_FREE_CHARACT_TYPE CARACT
       where DIS.SCH_DISCOUNT_CONFIG_TYPE_ID = CONFIG.SCH_DISCOUNT_CONFIG_TYPE_ID(+)
         and DIS.SCH_DISCOUNT_FIELD_TYPE_ID = field.SCH_DISCOUNT_FIELD_TYPE_ID(+)
         and DIS.SCH_FREE_CHARACT_TYPE_ID = CARACT.SCH_FREE_CHARACT_TYPE_ID(+)
         and SCH_DISCOUNT_ID = PrmSCH_DISCOUNT_ID;

    -- Sur les montant
    cursor CUR_SCH_ECOLAGE_AMOUNT(PrmSCH_YEAR_PERIOD_ID SCH_YEAR_PERIOD.SCH_YEAR_PERIOD_ID%type)
    is
      select AMO_AMOUNT_HT
        from SCH_AMOUNT_HT
       where SCH_YEAR_PERIOD_ID = PrmSCH_YEAR_PERIOD_ID
         and SCH_ECOLAGE_CATEGORY_ID = PrmSCH_ECOLAGE_CATEGORY_ID;

    --Variables
    CurSchPeriode         CUR_SCH_PERIODE%rowtype;
    CurSchEcolage         CUR_SCH_ECOLAGE%rowtype;
    CurSchDiscount        CUR_SCH_DISCOUNT%rowtype;
    CurSchEcolageAmount   CUR_SCH_ECOLAGE_AMOUNT%rowtype;
    LoopCounter           integer;
    VarSCH_YEAR_PERIOD_ID SCH_YEAR_PERIOD.SCH_YEAR_PERIOD_ID%type;
    Resultat              varchar2(200);
  begin
    Resultat  := '';

    -- S'il s'agit d'une catégorie d'écolage
    if PrmSCH_ECOLAGE_CATEGORY_ID <> 0 then
      for CurSchEcolage in CUR_SCH_ECOLAGE loop
        -- Si montant par période
        if CurSchEcolage.CAT_CONTRACTUAL_AMOUNT = 0 then
          -- Récupération de la période concernée
          LoopCounter            := 0;
          VarSCH_YEAR_PERIOD_ID  := 0;

          for CurSchPeriode in CUR_SCH_PERIODE loop
            LoopCounter  := LoopCounter + 1;

            if LoopCounter = PrmNum_Periode then
              VarSCH_YEAR_PERIOD_ID  := CurSchPeriode.SCH_YEAR_PERIOD_ID;
            end if;
          end loop;

          -- Si la période existe
          if VarSCH_YEAR_PERIOD_ID <> 0 then
            for CurSchEcolageAmount in CUR_SCH_ECOLAGE_AMOUNT(VarSCH_YEAR_PERIOD_ID) loop
              Resultat  := to_char(CurSchEcolageAmount.AMO_AMOUNT_HT * 100, '999999999999,99');
            end loop;
          end if;
        -- sinon, si montant forfaitaire
        else
          -- Montant sur champ
          if CurSchEcolage.C_ECOLAGE_TYPE_AMOUNT = '0' then
            Resultat  := PCS.PC_PUBLIC.TRANSLATEWORD('Montant sur le champ') || ' : ' || CurSchEcolage.FIT_DESCR;
          -- Montant sur "config"
          elsif CurSchEcolage.C_ECOLAGE_TYPE_AMOUNT = '1' then
            Resultat  :=
              PCS.PC_PUBLIC.TRANSLATEWORD('Montant sur la configuration') ||
              ' : ' ||
              CurSchEcolage.CON_DESCR ||
              ' = ' ||
              to_char(to_number(PCS.PC_CONFIG.GETCONFIG(CurSchEcolage.CON_NAME) ) * 100, '999999999999,99');
          -- Montant sur caractéristique libre
          elsif CurSchEcolage.C_ECOLAGE_TYPE_AMOUNT = '2' then
            Resultat  := PCS.PC_PUBLIC.TRANSLATEWORD('Montant sur la caractéristique') || ' : ' || CurSchEcolage.CHT_SHORT_DESCR;
          end if;
        end if;
      end loop;
    elsif PrmSCH_DISCOUNT_ID <> 0 then
      for CurSchDiscount in CUR_SCH_DISCOUNT loop
        -- S'il s'agit d'un montant
        if CurSchDiscount.DIS_AMOUNT_OR_RATE = 0 then
          -- Sur Champ...
          if CurSchDiscount.C_DISCOUNT_TYPE_AMOUNT = '0' then
            if CurSchDiscount.DIS_TTC_AMOUNT <> 0 then
              Resultat  :=
                PCS.PC_PUBLIC.TRANSLATEWORD('Montant sur le champ') ||
                ' : ' ||
                CurSchDiscount.FIT_DESCR ||
                to_char(CurSchDiscount.DIS_TTC_AMOUNT * 100, '999999999999,99');
            elsif CurSchDiscount.SCH_DISCOUNT_FIELD_TYPE_ID <> 0 then
              Resultat  := PCS.PC_PUBLIC.TRANSLATEWORD('Montant sur le champ') || ' : ' || CurSchDiscount.FIT_DESCR;
            else
              Resultat  := '';
            end if;
          -- Sur config...
          elsif CurSchDiscount.C_DISCOUNT_TYPE_AMOUNT = '1' then
            if CurSchDiscount.SCH_DISCOUNT_CONFIG_TYPE_ID <> 0 then
              Resultat  :=
                PCS.PC_PUBLIC.TRANSLATEWORD('Montant sur la configuration') ||
                ' : ' ||
                CurSchDiscount.CON_DESCR ||
                ' = ' ||
                to_char(to_number(PCS.PC_CONFIG.GETCONFIG(CurSchDiscount.CON_NAME) ) * 100, '999999999999,99');
            else
              Resultat  := '';
            end if;
          -- Sur Caractéristique libre...
          elsif CurSchDiscount.C_DISCOUNT_TYPE_AMOUNT = '2' then
            if CurSchDiscount.SCH_FREE_CHARACT_TYPE_ID <> 0 then
              Resultat  := PCS.PC_PUBLIC.TRANSLATEWORD('Montant sur la caractéristique') || ' : ' || CurSchDiscount.CHT_SHORT_DESCR;
            else
              Resultat  := '';
            end if;
          end if;
        -- S'il s'agit d'un taux
        else
          -- Sur Champ...
          if CurSchDiscount.C_DISCOUNT_TYPE_AMOUNT = '0' then
            if CurSchDiscount.DIS_TTC_AMOUNT <> 0 then
              Resultat  :=
                PCS.PC_PUBLIC.TRANSLATEWORD('Taux sur le champ') ||
                ' : ' ||
                CurSchDiscount.FIT_DESCR ||
                to_char(CurSchDiscount.DIS_TTC_AMOUNT * 100, '999999999999,99') ||
                ' %';
            elsif CurSchDiscount.SCH_DISCOUNT_FIELD_TYPE_ID <> 0 then
              Resultat  := PCS.PC_PUBLIC.TRANSLATEWORD('Taux sur le champ') || ' : ' || CurSchDiscount.FIT_DESCR;
            else
              Resultat  := '';
            end if;
          -- Sur Config...
          elsif CurSchDiscount.C_DISCOUNT_TYPE_AMOUNT = '1' then
            if CurSchDiscount.SCH_DISCOUNT_CONFIG_TYPE_ID <> 0 then
              Resultat  :=
                PCS.PC_PUBLIC.TRANSLATEWORD('Taux sur la configuration') ||
                ' : ' ||
                CurSchDiscount.CON_DESCR ||
                ' = ' ||
                to_char(to_number(PCS.PC_CONFIG.GETCONFIG(CurSchDiscount.CON_NAME) ) * 100, '999999999999,99') ||
                ' %';
            else
              Resultat  := '';
            end if;
          -- Sur Caractéristique libre...
          elsif CurSchDiscount.C_DISCOUNT_TYPE_AMOUNT = '2' then
            if CurSchDiscount.SCH_FREE_CHARACT_TYPE_ID <> 0 then
              Resultat  := PCS.PC_PUBLIC.TRANSLATEWORD('Taux sur la caractéristique') || ' : ' || CurSchDiscount.CHT_SHORT_DESCR;
            else
              Resultat  := '';
            end if;
          end if;
        end if;
      end loop;
    end if;

    -- Si montant Inconnu, alors
    if Resultat = '' then
      Resultat  := '?';
    end if;

    return Resultat;
  end GetEcolageAmount;

  /***
  * Function qui renvoie le montant (Ou une description du montant) d'un écolage.
  * dans le cas d'écolages liés
  *
  */
  function GetEcolageLinkedAmount(
    PrmSCH_ECOLAGE_ID     SCH_ECOLAGE_CATEGORY.SCH_ECOLAGE_CATEGORY_ID%type
  , PrmSCH_BILL_HEADER_ID SCH_BILL_HEADER.SCH_BILL_HEADER_ID%type
  , PrmTYPE_AMOUNT        integer
  )
    return varchar2
  is
    cursor CUR_SCH_ECOLAGE_LINKED
    is
      select sum(nvl(BOP.BOP_HT_AMOUNT, 0) ) HT_AMOUNT
           , sum(nvl(BOP.BOP_VAT_AMOUNT, 0) ) VAT_AMOUNT
           , sum(nvl(BOP.BOP_TTC_AMOUNT, 0) ) TTC_AMOUNT
        from SCH_BILL_HEADER HEA
           , SCH_BILL_POSITION BOP
           , SCH_ECOLAGE ECO
           , GCO_GOOD GCO
           , GCO_FREE_CODE COD
       where HEA.SCH_BILL_HEADER_ID = PrmSCH_BILL_HEADER_ID
         and HEA.SCH_BILL_HEADER_ID = BOP.SCH_BILL_HEADER_ID
         and BOP.SCH_ECOLAGE_ID = ECO.SCH_ECOLAGE_ID
         and ECO.GCO_GOOD_ID = GCO.GCO_GOOD_ID
         and GCO.GCO_GOOD_ID = COD.GCO_GOOD_ID;

    -- Variables
    CurSchEcolageLinked CUR_SCH_ECOLAGE_LINKED%rowtype;
  begin
    open CUR_SCH_ECOLAGE_LINKED;

    fetch CUR_SCH_ECOLAGE_LINKED
     into CurSchEcolageLinked;

    if CUR_SCH_ECOLAGE_LINKED%found then
      if PrmTYPE_AMOUNT = 1 then
        return to_char(CurSchEcolageLinked.HT_AMOUNT * 100, '999999999999,99');
      elsif PrmTYPE_AMOUNT = 2 then
        return to_char(CurSchEcolageLinked.VAT_AMOUNT * 100, '999999999999,99');
      elsif PrmTYPE_AMOUNT = 3 then
        return to_char(CurSchEcolageLinked.TTC_AMOUNT * 100, '999999999999,99');
      else
        return 0;
      end if;
    else
      return 0;
    end if;

    close CUR_SCH_ECOLAGE_LINKED;
  end GetEcolageLinkedAmount;

  /***
  * Function similaire à la précédente, mais basée sur les tables DOC_DOCUMENT et DOC_POSITION
  *
  */
  function GetPositionLinkedAmount(
    PrmDOC_DOCUMENT_ID      DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , PrmDIC_GCO_BOOLEAN_CODE DIC_GCO_BOOLEAN_CODE_TYPE.DIC_GCO_BOOLEAN_CODE_TYPE_ID%type
  , PrmTYPE_AMOUNT          integer
  )
    return number
  is
    cursor CUR_SCH_ECOLAGE_LINKED
    is
      select sum(nvl(POS.POS_NET_VALUE_EXCL, 0) ) HT_AMOUNT
           , sum(nvl(POS.POS_VAT_AMOUNT, 0) ) VAT_AMOUNT
           , sum(nvl(POS.POS_NET_VALUE_INCL, 0) ) TTC_AMOUNT
        from DOC_DOCUMENT DOC
           , DOC_POSITION POS
           , GCO_GOOD GCO
           , GCO_FREE_CODE COD
       where DOC.DOC_DOCUMENT_ID = PrmDOC_DOCUMENT_ID
         and DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and POS.GCO_GOOD_ID = GCO.GCO_GOOD_ID
         and GCO.GCO_GOOD_ID = COD.GCO_GOOD_ID
         and COD.DIC_GCO_BOOLEAN_CODE_TYPE_ID = PrmDIC_GCO_BOOLEAN_CODE;

    -- Variables
    CurSchEcolageLinked CUR_SCH_ECOLAGE_LINKED%rowtype;
  begin
    open CUR_SCH_ECOLAGE_LINKED;

    fetch CUR_SCH_ECOLAGE_LINKED
     into CurSchEcolageLinked;

    if CUR_SCH_ECOLAGE_LINKED%found then
      if PrmTYPE_AMOUNT = 1 then
        return CurSchEcolageLinked.HT_AMOUNT;
      elsif PrmTYPE_AMOUNT = 2 then
        return CurSchEcolageLinked.VAT_AMOUNT;
      elsif PrmTYPE_AMOUNT = 3 then
        return CurSchEcolageLinked.TTC_AMOUNT;
      else
        return 0;
      end if;
    else
      return 0;
    end if;

    close CUR_SCH_ECOLAGE_LINKED;
  end GetPositionLinkedAmount;

  /***
  * Function qui permet d'orrondir le montant passé en paramètre à 0.05 près
  *
  */
  function RoundAmount(PrmAMOUNT number)
    return number
  is
    VarRoundedToOneDec number;
    VarDifference      number;
  begin
    VarRoundedToOneDec  := trunc(PrmAMOUNT, 1);
    VarDifference       := PrmAMOUNT - VarRoundedToOneDec;

    if VarDifference = 0 then
      return PrmAMOUNT;
    elsif VarDifference < 0.03 then
      return VarRoundedToOneDec;
    else
      return(VarRoundedToOneDec + 0.05);
    end if;
  end RoundAmount;

  /***
  * Function qui renvoie Prénom + Nom de l'étudiant dont le numéro de compte est passé en paramètre
  *
  */
  function GetStudentName(PrmSTU_ACCOUNT_NUMBER varchar2)
    return varchar2
  is
    VarSTUDENT_DESCR varchar2(100);
  begin
    select STU_NAME || ' ' || STU_FORENAME
      into VarSTUDENT_DESCR
      from SCH_STUDENT
     where STU_ACCOUNT_NUMBER = to_number(PrmSTU_ACCOUNT_NUMBER);

    return VarSTUDENT_DESCR;
  end GetStudentName;

  /***
  * Function qui renvoie la description des périodes de la facture d'écolage
  *
  */
  function GetTermsDescr(PrmSCH_GROUP_YEAR_PERIOD_ID SCH_GROUP_YEAR_PERIOD.SCH_GROUP_YEAR_PERIOD_ID%type)
    return varchar2
  is
    -- Curseurs
    cursor CUR_TERMS_DESCR
    is
      select   PER.PER_SHORT_DESCR
             , SCO.SCO_SHORT_DESCR
          from SCH_YEAR_PERIOD PER
             , SCH_SCHOOL_YEAR SCO
             , SCH_PERIOD_GRP_PERIOD_LINK GRP
         where GRP.SCH_GROUP_YEAR_PERIOD_ID = PrmSCH_GROUP_YEAR_PERIOD_ID
           and GRP.SCH_YEAR_PERIOD_ID = PER.SCH_YEAR_PERIOD_ID
           and PER.SCH_SCHOOL_YEAR_ID = SCO.SCH_SCHOOL_YEAR_ID
      order by PER.PER_BEGIN_DATE asc;

    -- Variables
    CurTermsDescr   CUR_TERMS_DESCR%rowtype;
    ResultDescr     varchar2(2000);
    SchoolYearDescr varchar2(50);
  begin
    ResultDescr  := '';

    for CurTermsDescr in CUR_TERMS_DESCR loop
      if CUR_TERMS_DESCR%found then
        ResultDescr      := ResultDescr || CurTermsDescr.PER_SHORT_DESCR || ' / ';
        SchoolYearDescr  := CurTermsDescr.SCO_SHORT_DESCR;
      end if;
    end loop;

    ResultDescr  := substr(ResultDescr, 1, length(ResultDescr) - 2);
    return(ResultDescr || ' - ' || SchoolYearDescr);
  end GetTermsDescr;

  /***
  *  Fonction utilisée par crystal et qui renvoie le montant des écolages
  *
  */
  function CR_GetEcolageAmount(
    PrmSCH_SCHOOL_YEAR_ID      SCH_SCHOOL_YEAR.SCH_SCHOOL_YEAR_ID%type
  , PrmSCH_YEAR_PERIOD_ID      SCH_YEAR_PERIOD.SCH_YEAR_PERIOD_ID%type
  , PrmSCH_ECOLAGE_CATEGORY_ID SCH_ECOLAGE_CATEGORY.SCH_ECOLAGE_CATEGORY_ID%type
  )
    return varchar2
  is
    -- Curseurs
    cursor CUR_SCH_PERIODE
    is
      select   SCH_YEAR_PERIOD_ID
          from SCH_YEAR_PERIOD
         where SCH_SCHOOL_YEAR_ID = PrmSCH_SCHOOL_YEAR_ID
      order by PER_BEGIN_DATE asc;

    -- Sur les écolages
    cursor CUR_SCH_ECOLAGE
    is
      select CAT.C_ECOLAGE_TYPE_AMOUNT
           , nvl(CAT.CAT_CONTRACTUAL_AMOUNT, 0) CAT_CONTRACTUAL_AMOUNT
           , CONFIG.CON_NAME
           , CONFIG.CON_DESCR
           , field.FIT_NAME
           , field.FIT_DESCR
           , field.FIT_TABLE_NAME
           , CARACT.CHT_SHORT_DESCR
        from SCH_ECOLAGE_CATEGORY CAT
           , SCH_DISCOUNT_CONFIG_TYPE CONFIG
           , SCH_DISCOUNT_FIELD_TYPE field
           , SCH_FREE_CHARACT_TYPE CARACT
       where CAT.SCH_DISCOUNT_CONFIG_TYPE_ID = CONFIG.SCH_DISCOUNT_CONFIG_TYPE_ID(+)
         and CAT.SCH_DISCOUNT_FIELD_TYPE_ID = field.SCH_DISCOUNT_FIELD_TYPE_ID(+)
         and CAT.SCH_FREE_CHARACT_TYPE_ID = CARACT.SCH_FREE_CHARACT_TYPE_ID(+)
         and CAT.SCH_ECOLAGE_CATEGORY_ID = PrmSCH_ECOLAGE_CATEGORY_ID;

    -- Sur les montant
    cursor CUR_SCH_ECOLAGE_AMOUNT(PrmSCH_YEAR_PERIOD_ID SCH_YEAR_PERIOD.SCH_YEAR_PERIOD_ID%type)
    is
      select AMO_AMOUNT_HT
        from SCH_AMOUNT_HT
       where SCH_YEAR_PERIOD_ID = PrmSCH_YEAR_PERIOD_ID
         and SCH_ECOLAGE_CATEGORY_ID = PrmSCH_ECOLAGE_CATEGORY_ID;

    --Variables
    CurSchPeriode         CUR_SCH_PERIODE%rowtype;
    CurSchEcolage         CUR_SCH_ECOLAGE%rowtype;
    CurSchEcolageAmount   CUR_SCH_ECOLAGE_AMOUNT%rowtype;
    LoopCounter           integer;
    VarSCH_YEAR_PERIOD_ID SCH_YEAR_PERIOD.SCH_YEAR_PERIOD_ID%type;
    Resultat              varchar2(200);
  begin
    Resultat  := '';

    -- S'il s'agit d'une catégorie d'écolage
    if PrmSCH_ECOLAGE_CATEGORY_ID <> 0 then
      for CurSchEcolage in CUR_SCH_ECOLAGE loop
        -- Si montant par période
        if CurSchEcolage.CAT_CONTRACTUAL_AMOUNT = 0 then
          for CurSchEcolageAmount in CUR_SCH_ECOLAGE_AMOUNT(PrmSCH_YEAR_PERIOD_ID) loop
            Resultat  := to_char(CurSchEcolageAmount.AMO_AMOUNT_HT * 100, '999999999999,99');
          end loop;
        -- sinon, si montant forfaitaire
        else
          -- Montant sur champ
          if CurSchEcolage.C_ECOLAGE_TYPE_AMOUNT = '0' then
            Resultat  := PCS.PC_PUBLIC.TRANSLATEWORD('Montant sur le champ') || ' : ' || CurSchEcolage.FIT_DESCR;
          -- Montant sur "config"
          elsif CurSchEcolage.C_ECOLAGE_TYPE_AMOUNT = '1' then
            Resultat  :=
              PCS.PC_PUBLIC.TRANSLATEWORD('Montant sur la configuration') ||
              ' : ' ||
              CurSchEcolage.CON_DESCR ||
              ' = ' ||
              to_char(to_number(PCS.PC_CONFIG.GETCONFIG(CurSchEcolage.CON_NAME) ) * 100, '999999999999,99');
          -- Montant sur caractéristique libre
          elsif CurSchEcolage.C_ECOLAGE_TYPE_AMOUNT = '2' then
            Resultat  := PCS.PC_PUBLIC.TRANSLATEWORD('Montant sur la caractéristique') || ' : ' || CurSchEcolage.CHT_SHORT_DESCR;
          end if;
        end if;
      end loop;
    end if;

    -- Si montant Inconnu, alors
    if Resultat = '' then
      Resultat  := '?';
    end if;

    return Resultat;
  end CR_GetEcolageAmount;

  /***
  *  Fonction utilisée par crystal et qui renvoie le montant des écolages
  *
  */
  function CR_GetOutlayAmount(PrmSCH_ENTERED_OUTLAY_ID SCH_ENTERED_OUTLAY.SCH_ENTERED_OUTLAY_ID%type)
    return number
  is
    cursor CUR_SCH_ENTERED_OUTLAY
    is
      select SEO.SCH_ENTERED_OUTLAY_ID
           , SEO.SCH_OUTLAY_ID
           , SEO.SCH_OUTLAY_CATEGORY_ID
           , nvl(SEO.EOU_QTY, 0) EOU_QTY
           , nvl(SEO.EOU_TTC_AMOUNT, 0) EOU_TTC_AMOUNT
           , nvl(SOC.COU_UNIT_MARGIN, 0) COU_UNIT_MARGIN
           , nvl(SOC.COU_NULL_MARGIN, 0) COU_NULL_MARGIN
           , nvl(SOC.COU_MARGIN_TYPE, 0) COU_MARGIN_TYPE
           , nvl(SOC.COU_MARGIN_AMOUNT, 0) COU_MARGIN_AMOUNT
           , nvl(SOC.COU_MARGIN_RATE, 0) COU_MARGIN_RATE
        from SCH_ENTERED_OUTLAY SEO
           , SCH_OUTLAY SO
           , SCH_OUTLAY_CATEGORY SOC
       where SEO.SCH_OUTLAY_ID = SO.SCH_OUTLAY_ID(+)
         and SEO.SCH_OUTLAY_CATEGORY_ID = SOC.SCH_OUTLAY_CATEGORY_ID(+)
         and SEO.SCH_OUTLAY_ID = SOC.SCH_OUTLAY_ID(+)
         and SEO.SCH_ENTERED_OUTLAY_ID = PrmSCH_ENTERED_OUTLAY_ID;

    CurSchEnteredOutlay CUR_SCH_ENTERED_OUTLAY%rowtype;
    VarPositionAmount   number;
    VarMarginAmount     number;
  begin
    VarMarginAmount  := 0;

    for CurSchEnteredOutlay in CUR_SCH_ENTERED_OUTLAY loop
      /* Calcul du montant */
      VarPositionAmount  := CurSchEnteredOutlay.EOU_QTY * CurSchEnteredOutlay.EOU_TTC_AMOUNT;

      -- Montant null
      if VarPositionAmount = 0 then
        -- Marge non applicable sur montant null
        if CurSchEnteredOutlay.COU_NULL_MARGIN = 0 then
          VarMarginAmount  := 0;
        -- Marge applicable sur montant null
        else
          -- Type de marge  = Montant
          if CurSchEnteredOutlay.COU_MARGIN_TYPE = 1 then
            -- Marge unitaire
            if CurSchEnteredOutlay.COU_UNIT_MARGIN = 1 then
              VarMarginAmount  := CurSchEnteredOutlay.EOU_QTY * CurSchEnteredOutlay.COU_MARGIN_AMOUNT;
            -- Marge globale
            else
              VarMarginAmount  := CurSchEnteredOutlay.COU_MARGIN_AMOUNT;
            end if;
          -- Type de marge  = Taux (Un taux n'est pas applicable sur montant null --> = 0
          else
            VarMarginAmount  := 0;
          end if;
        end if;
      -- Montant non null
      elsif VarPositionAmount <> 0 then
        -- Type de marge  = Montant
        if CurSchEnteredOutlay.COU_MARGIN_TYPE = 1 then
          -- Marge unitaire
          if CurSchEnteredOutlay.COU_UNIT_MARGIN = 1 then
            VarMarginAmount  := CurSchEnteredOutlay.EOU_QTY * CurSchEnteredOutlay.COU_MARGIN_AMOUNT;
          -- Marge globale
          else
            VarMarginAmount  := CurSchEnteredOutlay.COU_MARGIN_AMOUNT;
          end if;
        -- Type de marge  = Taux (Un taux n'est pas applicable sur montant null --> = 0
        else
          if CurSchEnteredOutlay.COU_UNIT_MARGIN = 1 then
            VarMarginAmount  := (CurSchEnteredOutlay.EOU_TTC_AMOUNT *(CurSchEnteredOutlay.COU_MARGIN_RATE / 100) ) * CurSchEnteredOutlay.EOU_QTY;
          -- Marge globale
          else
            VarMarginAmount  := VarPositionAmount *(CurSchEnteredOutlay.COU_MARGIN_RATE / 100);
          end if;
        end if;
      end if;
    end loop;

    return VarMarginAmount;
  end CR_GetOutlayAmount;

  /***
  *  Duplique une année scolaire ainsi que les grilles de tarifs associées
  *
  */
  procedure DuplicateSchoolYear(
    aSCH_SCHOOL_YEAR_ID SCH_SCHOOL_YEAR.SCH_SCHOOL_YEAR_ID%type
  , aSCO_SHORT_DESCR    SCH_SCHOOL_YEAR.SCO_SHORT_DESCR%type
  , aSCO_LONG_DESCR     SCH_SCHOOL_YEAR.SCO_LONG_DESCR%type
  , aYear               number
  )
  is
    cursor CUR_SCH_SCHOOL_YEAR
    is
      select SCO_BEGIN_DATE
           , SCO_END_DATE
        from SCH_SCHOOL_YEAR
       where SCH_SCHOOL_YEAR_ID = aSCH_SCHOOL_YEAR_ID;

    cursor CUR_SCH_YEAR_PERIOD
    is
      select   SCH_YEAR_PERIOD_ID
             , PER_SHORT_DESCR
             , PER_LONG_DESCR
             , PER_BEGIN_DATE
             , PER_END_DATE
          from SCH_YEAR_PERIOD
         where SCH_SCHOOL_YEAR_ID = aSCH_SCHOOL_YEAR_ID
      order by PER_BEGIN_DATE;

    CurSchYearPeriod CUR_SCH_YEAR_PERIOD%rowtype;
    CurSchSchoolYear CUR_SCH_SCHOOL_YEAR%rowtype;
    nNewYearId       SCH_SCHOOL_YEAR.SCH_SCHOOL_YEAR_ID%type;
    nNewPeriodId     SCH_YEAR_PERIOD.SCH_YEAR_PERIOD_ID%type;
    nSrcYear         number;
    iDiffYear        integer;
  begin
    nSrcYear   := 0;
    iDiffYear  := 0;

    for CurSchSchoolYear in CUR_SCH_SCHOOL_YEAR loop
      nNewYearId  := GetNewId;
      nSrcYear    := to_number(to_char(CurSchSchoolYear.SCO_BEGIN_DATE, 'YYYY') );
      iDiffYear   := aYear - nSrcYear;

      -- Insertion de l'année
      insert into SCH_SCHOOL_YEAR
                  (SCH_SCHOOL_YEAR_ID
                 , SCO_SHORT_DESCR
                 , SCO_LONG_DESCR
                 , SCO_BEGIN_DATE
                 , SCO_END_DATE
                 , A_DATECRE
                 , A_IDCRE
                 , SCO_CURRENT_YEAR
                  )
           values (nNewYearId
                 , aSCO_SHORT_DESCR
                 , aSCO_LONG_DESCR
                 , add_months(CurSchSchoolYear.SCO_BEGIN_DATE, iDiffYear * 12)
                 , add_months(CurSchSchoolYear.SCO_END_DATE, iDiffYear * 12)
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , 0
                  );

      for CurSchYearPeriod in CUR_SCH_YEAR_PERIOD loop
        /* Insertion de chaque période */
        nNewPeriodId  := GetNewId;

        insert into SCH_YEAR_PERIOD
                    (SCH_YEAR_PERIOD_ID
                   , SCH_SCHOOL_YEAR_ID
                   , PER_SHORT_DESCR
                   , PER_LONG_DESCR
                   , PER_BEGIN_DATE
                   , PER_END_DATE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (nNewPeriodId
                   , nNewYearId
                   , '<Nouvelle Période>'
                   , '<Nouvelle Période> ' || aSCO_SHORT_DESCR
                   , add_months(CurSchYearPeriod.PER_BEGIN_DATE, iDiffYear * 12)
                   , add_months(CurSchYearPeriod.PER_END_DATE, iDiffYear * 12)
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );

        -- Et des montants par catégorie d'écolages associés
        insert into SCH_AMOUNT_HT
                    (SCH_AMOUNT_HT_ID
                   , SCH_YEAR_PERIOD_ID
                   , SCH_ECOLAGE_CATEGORY_ID
                   , AMO_AMOUNT_HT
                   , A_DATECRE
                   , A_IDCRE
                    )
          select GetNewId
               , nNewPeriodId
               , SCH_ECOLAGE_CATEGORY_ID
               , AMO_AMOUNT_HT
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from SCH_AMOUNT_HT
           where SCH_YEAR_PERIOD_ID = CurSchYearPeriod.SCH_YEAR_PERIOD_ID;
      end loop;
    end loop;
  end DuplicateSchoolYear;

  /***
  *  Ajout de la caractéristique libre Cours de vacanes uniquement de manière Auto $
  *
  */
  procedure AddFreeCharacteristique(
    aSCH_FREE_CHARACTERISTIC_ID SCH_FREE_CHARACTERISTIC.SCH_FREE_CHARACTERISTIC_ID%type
  , aSCH_STUDENT_ID             SCH_STUDENT.SCH_STUDENT_ID%type
  )
  is
    cursor NEW_CHARACTERISTIC(aCHARACTERISTIC_DESCR varchar2)
    is
      select nvl(CHA.SCH_FREE_CHARACT_TYPE_ID, 0) SCH_FREE_CHARACT_TYPE_ID
        from SCH_FREE_CHARACTERISTIC FRC
           , SCH_FREE_CHARACT_TYPE CHA
       where FRC.SCH_FREE_CHARACT_TYPE_ID = CHA.SCH_FREE_CHARACT_TYPE_ID
         and CHA.CHT_SHORT_DESCR = aCHARACTERISTIC_DESCR;

    sSCH_HOLIDAY_BILLING  varchar2(50);
    sSCH_ONLY_HOLIDAY     varchar2(50);
    aoldCHT_SHORT_DESCR   varchar2(50);
    anewCHARACTERISTIC_ID number;
    NewCharacteristic     NEW_CHARACTERISTIC%rowtype;
  begin
/*  SELECT CHA.CHT_SHORT_DESCR
    into aoldCHT_SHORT_DESCR
    FROM SCH_FREE_CHARACTERISTIC FRC,
       SCH_FREE_CHARACT_TYPE CHA
   WHERE FRC.SCH_FREE_CHARACT_TYPE_ID = CHA.SCH_FREE_CHARACT_TYPE_ID AND
         FRC.SCH_FREE_CHARACTERISTIC_ID = aSCH_FREE_CHARACTERISTIC_ID;

  sSCH_HOLIDAY_BILLING := PCS.PC_CONFIG.GETCONFIG('SCH_HOLIDAY_CHARACT');
  sSCH_ONLY_HOLIDAY := PCS.PC_CONFIG.GETCONFIG('SCH_ONLY_HOLIDAY');

  if aoldCHT_SHORT_DESCR = sSCH_HOLIDAY_BILLING then
  if sSCH_HOLIDAY_BILLING <> '' then
    OPEN NEW_CHARACTERISTIC('Cours de vacances uniquement');
    raise_application_error(-20000,sSCH_HOLIDAY_BILLING);
    FETCH NEW_CHARACTERISTIC into NewCharacteristic;

    if NEW_CHARACTERISTIC%found and NewCharacteristic.SCH_FREE_CHARACT_TYPE_ID <> 0 then
      INSERT INTO SCH_FREE_CHARACTERISTIC(SCH_FREE_CHARACTERISTIC_ID,
                                        SCH_STUDENT_ID,
                      FRC_BOOLEAN_VAL,
                      FRC_NUMERIC_VAL,
                      A_DATECRE,
                      A_IDCRE,
                      SCH_FREE_CHARACT_TYPE_ID)
        VALUES(GetNewId,
           aSCH_STUDENT_ID,
         1,
         null,
         sysdate,
         PCS.PC_I_LIB_SESSION.GETUSERINI,
         NewCharacteristic.SCH_FREE_CHARACT_TYPE_ID);
    end if;
    CLOSE NEW_CHARACTERISTIC;
  end if;

  end if;

  exception
    when others then raise; */
    null;
  end AddFreeCharacteristique;

  /***
  *  function GetCustomer
  *  Description : Renvoie un débiteur en fonction de son type
  *
  */
  function GetCustomer(iSCH_STUDENT_ID in number, iDIC_CUSTOMER_TYPE_ID in varchar2)
    return number
  is
    result number;
  begin
    select max(SSC.PAC_CUSTOM_PARTNER_ID)
      into result
      from SCH_STUDENT_S_CUSTOMER SSC
     where SSC.SCH_STUDENT_ID = iSCH_STUDENT_ID
       and SSC.DIC_CUSTOMER_TYPE_ID = iDIC_CUSTOMER_TYPE_ID;

    return result;
  exception
    when no_data_found then
      return null;
  end GetCustomer;

  /***
  *  function GetCustomerName
  *  Description : Renvoie un débiteur en fonction de son type
  *
  */
  function GetCustomerName(iSCH_STUDENT_ID in number, iDIC_CUSTOMER_TYPE_ID in varchar2)
    return varchar2
  is
    result varchar2(120);
  begin
    select max(PER.PER_NAME || ' ' || PER.PER_FORENAME)
      into result
      from SCH_STUDENT_S_CUSTOMER SSC
         , PAC_PERSON PER
     where SSC.SCH_STUDENT_ID = iSCH_STUDENT_ID
       and SSC.DIC_CUSTOMER_TYPE_ID = iDIC_CUSTOMER_TYPE_ID
       and SSC.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID;

    return result;
  exception
    when no_data_found then
      return null;
  end GetCustomerName;

  /***
  * function GetFamilyLink
  * Description : Renvoie les liens familiaux entre élèves
  *
  */
  function GetFamilyLink(iSCH_STUDENT_ID number)
    return varchar2
  is
    cursor crSelectBrothers(aSCH_STUDENT_ID number, aParentList varchar2)
    is
      select distinct STU.STU_NAME
                    , STU.STU_FORENAME
                    , nvl(STU.STU_DISCOUNT_RELATION, 0) STU_DISCOUNT_RELATION
                    , STU.STU_ACCOUNT_NUMBER
                 from SCH_STUDENT STU
                    , SCH_STUDENT_S_CUSTOMER SSC1
                    , (select PAC_CUSTOM_PARTNER_ID
                         from SCH_STUDENT_S_CUSTOMER SSC2
                        where SCH_STUDENT_ID = iSCH_STUDENT_ID
                          and instr(aParentList, SSC2.DIC_CUSTOMER_TYPE_ID) > 0) CURRENT_STUDENT
                where (    (     (STU.STU_ENTRY_DATE <= (select SCO_BEGIN_DATE
                                                           from SCH_SCHOOL_YEAR
                                                          where SCO_CURRENT_YEAR = 1) )
                            and (   STU.STU_EXIT_DATE is null
                                 or STU.STU_EXIT_DATE >= (select SCO_BEGIN_DATE
                                                            from SCH_SCHOOL_YEAR
                                                           where SCO_CURRENT_YEAR = 1) )
                           )
                       or (     (STU.STU_ENTRY_DATE >= (select SCO_BEGIN_DATE
                                                          from SCH_SCHOOL_YEAR
                                                         where SCO_CURRENT_YEAR = 1) )
                           and (STU.STU_ENTRY_DATE <= (select SCO_END_DATE
                                                         from SCH_SCHOOL_YEAR
                                                        where SCO_CURRENT_YEAR = 1) ) )
                      )
                  and STU.SCH_STUDENT_ID <> aSCH_STUDENT_ID
                  and STU.SCH_STUDENT_ID = SSC1.SCH_STUDENT_ID
                  and instr(aParentList, SSC1.DIC_CUSTOMER_TYPE_ID) > 0
                  and SSC1.PAC_CUSTOM_PARTNER_ID = CURRENT_STUDENT.PAC_CUSTOM_PARTNER_ID
             order by STU_ACCOUNT_NUMBER asc;

    lvcfgParentList varchar2(255);
    lsResult        varchar2(4000);
  begin
    lvcfgParentList  := PCS.PC_CONFIG.GetConfig('SCH_CONTROL_RELATIONSHIP');
    lsResult         := '';

    if lvcfgParentList is null then
      return '';
    else
      for tplBrothers in crSelectBrothers(iSCH_STUDENT_ID, lvcfgParentList) loop
        lsResult  := ' . ' || tplBrothers.STU_ACCOUNT_NUMBER || '  ' || tplBrothers.STU_NAME || '  ' || tplBrothers.STU_FORENAME || '  ';

        if tplBrothers.STU_DISCOUNT_RELATION = 1 then
          lsResult  := lsResult || PCS.PC_FUNCTIONS.TranslateWord('bénéficie de la réduction');
        else
          lsResult  := lsResult || PCS.PC_FUNCTIONS.TranslateWord('Ne bénéficie pas de la réduction');
        end if;

        lsResult  := lsResult || chr(13);
      end loop;

      return lsResult;
    end if;
  end GetFamilyLink;

  /***
  * function GetPeriodStartDate
  * Description : Renvoie les liens familiaux entre élèves
  *
  * @param iSCH_YEAR_PERIOD_ID : Période
  */
  function GetPeriodStartDate(iSCH_YEAR_PERIOD_ID number)
    return date
  is
    ldresult date;
  begin
    select nvl(PER_BEGIN_DATE, sysdate) + 1
      into ldresult
      from SCH_YEAR_PERIOD YEA
     where YEA.SCH_YEAR_PERIOD_ID = iSCH_YEAR_PERIOD_ID;

    return ldResult;
  exception
    when no_data_found then
      return sysdate;
  end GetPeriodStartDate;

  /***
  * procedure InsertOrUpdateFreeData
  * Description : Insertion ou Update des données libres
  *
  * @params   XXXX : Données libres
  */
  procedure InsertOrUpdateFreeData(
    iSCH_FREE_DATA_ID       in number default null
  , iSCH_ENTERED_OUTLAY_ID  in number default null
  , iDIC_SCH_FREE_TABLE1_ID in varchar2 default null
  , iDIC_SCH_FREE_TABLE2_ID in varchar2 default null
  , iDIC_SCH_FREE_TABLE3_ID in varchar2 default null
  , iDIC_SCH_FREE_TABLE4_ID in varchar2 default null
  , iDIC_SCH_FREE_TABLE5_ID in varchar2 default null
  , iSFD_ALPHA_SHORT_1      in varchar2 default null
  , iSFD_ALPHA_SHORT_2      in varchar2 default null
  , iSFD_ALPHA_SHORT_3      in varchar2 default null
  , iSFD_ALPHA_SHORT_4      in varchar2 default null
  , iSFD_ALPHA_SHORT_5      in varchar2 default null
  , iSFD_ALPHA_LONG_1       in varchar2 default null
  , iSFD_ALPHA_LONG_2       in varchar2 default null
  , iSFD_ALPHA_LONG_3       in varchar2 default null
  , iSFD_ALPHA_LONG_4       in varchar2 default null
  , iSFD_ALPHA_LONG_5       in varchar2 default null
  , iSFD_INTEGER_1          in integer default null
  , iSFD_INTEGER_2          in integer default null
  , iSFD_INTEGER_3          in integer default null
  , iSFD_INTEGER_4          in integer default null
  , iSFD_INTEGER_5          in integer default null
  , iSFD_BOOLEAN_1          in integer default null
  , iSFD_BOOLEAN_2          in integer default null
  , iSFD_BOOLEAN_3          in integer default null
  , iSFD_BOOLEAN_4          in integer default null
  , iSFD_BOOLEAN_5          in integer default null
  , iSFD_DECIMAL_1          in number default null
  , iSFD_DECIMAL_2          in number default null
  , iSFD_DECIMAL_3          in number default null
  , iSFD_DECIMAL_4          in number default null
  , iSFD_DECIMAL_5          in number default null
  , iSFD_DATE_1             in date default null
  , iSFD_DATE_2             in date default null
  , iSFD_DATE_3             in date default null
  , iSFD_DATE_4             in date default null
  , iSFD_DATE_5             in date default null
  , iSFD_TRANSFERT          in integer default null
  )
  is
    ltCRUD_DEF         FWK_I_TYP_DEFINITION.t_crud_def;
    lnSCH_FREE_DATA_ID number;
  begin
    -- Donnée libre doit être rattachée à un élément
    if     nvl(iSCH_ENTERED_OUTLAY_ID, 0) = 0
       and nvl(iSCH_FREE_DATA_ID, 0) = 0 then
      return;
    end if;

    -- ID Insertion ou modification
    if nvl(iSCH_FREE_DATA_ID, 0) = 0 then
      select Init_Id_Seq.nextval
        into lnSCH_FREE_DATA_ID
        from dual;
    else
      lnSCH_FREE_DATA_ID  := iSCH_FREE_DATA_ID;
    end if;

    FWK_I_MGT_ENTITY.new(FWK_I_TYP_SCH_ENTITY.gcSchFreeData, ltCRUD_DEF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_FREE_DATA_ID', lnSCH_FREE_DATA_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_ENTERED_OUTLAY_ID', iSCH_ENTERED_OUTLAY_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_SCH_FREE_TABLE1_ID', iDIC_SCH_FREE_TABLE1_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_SCH_FREE_TABLE2_ID', iDIC_SCH_FREE_TABLE2_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_SCH_FREE_TABLE3_ID', iDIC_SCH_FREE_TABLE3_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_SCH_FREE_TABLE4_ID', iDIC_SCH_FREE_TABLE4_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_SCH_FREE_TABLE5_ID', iDIC_SCH_FREE_TABLE5_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_ALPHA_SHORT_1', iSFD_ALPHA_SHORT_1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_ALPHA_SHORT_2', iSFD_ALPHA_SHORT_2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_ALPHA_SHORT_3', iSFD_ALPHA_SHORT_3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_ALPHA_SHORT_4', iSFD_ALPHA_SHORT_4);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_ALPHA_SHORT_5', iSFD_ALPHA_SHORT_5);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_ALPHA_LONG_1', iSFD_ALPHA_LONG_1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_ALPHA_LONG_2', iSFD_ALPHA_LONG_2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_ALPHA_LONG_3', iSFD_ALPHA_LONG_3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_ALPHA_LONG_4', iSFD_ALPHA_LONG_4);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_ALPHA_LONG_5', iSFD_ALPHA_LONG_5);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_INTEGER_1', iSFD_INTEGER_1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_INTEGER_2', iSFD_INTEGER_2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_INTEGER_3', iSFD_INTEGER_3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_INTEGER_4', iSFD_INTEGER_4);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_INTEGER_5', iSFD_INTEGER_5);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_BOOLEAN_1', iSFD_BOOLEAN_1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_BOOLEAN_2', iSFD_BOOLEAN_2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_BOOLEAN_3', iSFD_BOOLEAN_3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_BOOLEAN_4', iSFD_BOOLEAN_4);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_BOOLEAN_5', iSFD_BOOLEAN_5);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_DECIMAL_1', iSFD_DECIMAL_1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_DECIMAL_2', iSFD_DECIMAL_2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_DECIMAL_3', iSFD_DECIMAL_3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_DECIMAL_4', iSFD_DECIMAL_4);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_DECIMAL_5', iSFD_DECIMAL_5);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_DATE_1', iSFD_DATE_1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_DATE_2', iSFD_DATE_2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_DATE_3', iSFD_DATE_3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_DATE_4', iSFD_DATE_4);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_DATE_5', iSFD_DATE_5);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_TRANSFERT', iSFD_TRANSFERT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SFD_CATEGORY_COPY', 0);

    if nvl(iSCH_FREE_DATA_ID, 0) = 0 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATECRE', sysdate);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDCRE', PCS.PC_I_LIB_SESSION.GetUserIni);
      FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    else
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATEMOD', sysdate);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDMOD', PCS.PC_I_LIB_SESSION.GetUserIni);
      FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    end if;

    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end InsertOrUpdateFreeData;

  /***
  * function GetNewID_WINDEV_SEQ
  * Description : Renvoie le prochaine id de la séquence WINDEV_SEQ
  *
  * @return : Le nouvel ID de la séquence WINDEV_SEQ
  */
  function GetNewID_WINDEV_SEQ
    return LPM_REFERENTS.LPM_REFERENTS_ID%type
  is
    IDResult LPM_REFERENTS.LPM_REFERENTS_ID%type;
  begin
    select WINDEV_SEQ.nextval
    into IDResult
    from dual;

    return IDResult;
  end GetNewID_WINDEV_SEQ;
end;
