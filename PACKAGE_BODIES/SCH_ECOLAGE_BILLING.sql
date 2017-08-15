--------------------------------------------------------
--  DDL for Package Body SCH_ECOLAGE_BILLING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SCH_ECOLAGE_BILLING" 
is
  /**
  * procedure SelectGroupYeadPeriods
  * Description : Sélection des groupes de facturation via la table COM_LIST_ID_TEMP pour les
  *               traitements de génération des documents logistique de débours et d'écolages
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_GROUP_YEAR_PERIOD_ID : Groupe de période
  */
  procedure SelectGroupYeadPeriods(aSCH_GROUP_YEAR_PERIOD_ID in number)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'SCH_GROUP_YEAR_PERIOD_ID';

    -- Sélection des ID de produits à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct GRP.SCH_GROUP_YEAR_PERIOD_ID
                    , 'SCH_GROUP_YEAR_PERIOD_ID'
                 from SCH_GROUP_YEAR_PERIOD GRP
                where GRP.SCH_GROUP_YEAR_PERIOD_ID = aSCH_GROUP_YEAR_PERIOD_ID;
  end SelectGroupYeadPeriods;

  /**
  * procedure MovePosition
  * Description : Procedure de déplacement de position d'une facture source vers
  *               une facture destination
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aSrcBillHeader : Facture Source
  * @param   aDestBillHeader : Facture destination
  * @param   aPosition : Position à déplacer
  * @param   aDOC_GAUGE_ID : Gabarit Facture dest
  * @param   aPAC_CUSTOM_PARTNER_ID : Client Facture Dest
  * @param   aGCO_GOOD_ID : Bine de la position
  * @param   aBOP_TTC_AMOUNT : Montant TTC position.
  */
  procedure MovePosition(
    aSrcBillHeader         in number
  , aDestBillHeader        in number
  , aPosition              in number
  , aDOC_GAUGE_ID          in number
  , aPAC_CUSTOM_PARTNER_ID in number
  , aGCO_GOOD_ID           in number
  , aBOP_TTC_AMOUNT        in number
  )
  is
    aNewPosSeq        integer;
    aACS_TAX_CODE_ID  number;
    aBOP_VAT_AMOUNT   number;
    aBOP_HT_AMOUNT    number;
    VarBOP_TTC_AMOUNT number;
  begin
    -- Récupération de la prochaine séquence
    select nvl(max(BOP_SEQ), 0) + aSEQInterval
      into aNewPosSeq
      from SCH_BILL_POSITION
     where SCH_BILL_HEADER_ID = aDestBillHeader;

    -- Recalcul des montants
    VarBOP_TTC_AMOUNT  := aBOP_TTC_AMOUNT;
    ACS_VAT_FCT.GetVatInformations(1   -- Position Bien
                                 , aDOC_GAUGE_ID
                                 , aPAC_CUSTOM_PARTNER_ID
                                 , aGCO_GOOD_ID
                                 , null
                                 , null
                                 , 'I'
                                 , sysdate
                                 , aACS_TAX_CODE_ID
                                 , VarBOP_TTC_AMOUNT
                                 , aBOP_VAT_AMOUNT
                                  );
    aBOP_HT_AMOUNT     := aBOP_TTC_AMOUNT - aBOP_VAT_AMOUNT;

    -- Déplacement de la position
    update SCH_BILL_POSITION
       set SCH_BILL_HEADER_ID = aDestBillHeader
         , BOP_SEQ = aNewPosSeq
         , BOP_TTC_AMOUNT = VarBOP_TTC_AMOUNT
         , BOP_VAT_AMOUNT = aBOP_VAT_AMOUNT
         , BOP_HT_AMOUNT = aBOP_HT_AMOUNT
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where SCH_BILL_POSITION_ID = aPosition;
  end MovePosition;

  /**
  * procedure SelectEcolages
  * Description : Sélection des écolages via la table COM_LIST_ID_TEMP pour les
  *               traitements de génération des factures de d'écolages
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aECO_MAJOR_REFERENCE_FROM : Référence principale de
  * @param   aECO_MAJOR_REFERENCE_TO : Référence principale à
  * @param   aECO_SECONDARY_REFERENCE_FROM : Référence secondaire de
  * @param   aECO_SECONDARY_REFERENCE_TO : Référence secondaire à
  */
  procedure SelectEcolages(
    aECO_MAJOR_REFERENCE_FROM     varchar2
  , aECO_MAJOR_REFERENCE_TO       varchar2
  , aECO_SECONDARY_REFERENCE_FROM varchar2
  , aECO_SECONDARY_REFERENCE_TO   varchar2
  )
  is
  begin
    SCH_ECOLAGE_FUNCTIONS.SelectEcolage(aECO_MAJOR_REFERENCE_FROM, aECO_MAJOR_REFERENCE_TO, aECO_SECONDARY_REFERENCE_FROM, aECO_SECONDARY_REFERENCE_TO);
  end SelectEcolages;

  /**
  * procedure SelectEcolageCategory
  * Description : Sélection des catégories d'écolages via la table COM_LIST_ID_TEMP pour les
  *               traitements de génération des factures d'écolages
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aCAT_MAJOR_REFERENCE_FROM : Référence principale de
  * @param   aCAT_MAJOR_REFERENCE_TO : Référence principale à
  * @param   aCAT_SECONDARY_REFERENCE_FROM : Référence secondaire de
  * @param   aCAT_SECONDARY_REFERENCE_TO : Référence secondaire à
  */
  procedure SelectEcolagesCategory(
    aCAT_MAJOR_REFERENCE_FROM     varchar2
  , aCAT_MAJOR_REFERENCE_TO       varchar2
  , aCAT_SECONDARY_REFERENCE_FROM varchar2
  , aCAT_SECONDARY_REFERENCE_TO   varchar2
  )
  is
  begin
    SCH_ECOLAGE_FUNCTIONS.SelectEcolageCategory(aCAT_MAJOR_REFERENCE_FROM, aCAT_MAJOR_REFERENCE_TO, aCAT_SECONDARY_REFERENCE_FROM, aCAT_SECONDARY_REFERENCE_TO);
  end SelectEcolagesCategory;

  /**
  * function UpdateStudentFields
  * Description : Mise à jour des champs inscription facturée, et dépot de
  *               garantie facturé, sur la table élèves.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_STUDENT_ID  : Elève
  * @param   aFIELD varchar2  : Champs à mettre à jour
  * @param   aFIELD_VALUE     : Valeur du champ
  */
  procedure UpdateStudentFields(aSCH_STUDENT_ID number, aFIELD varchar2, aFIELD_VALUE integer)
  is
    vSQLUpdtQuery varchar2(255);
  begin
    vSQLUpdtQuery  :=
      ' update SCH_STUDENT ' ||
      '    set ' ||
      aFIELD ||
      ' = :aFIELD_VALUE ' ||
      '      , A_DATEMOD = sysdate ' ||
      '      , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni ' ||
      '  where SCH_STUDENT_ID = :aSCH_STUDENT_ID ';

    execute immediate vSQLUpdtQuery
                using aFIELD_VALUE, aSCH_STUDENT_ID;
  end;

  /**
  * function ReinitStudentsFields
  * Description : Si la position de facture porte sur un écolage avec MAJ de champs sur la fiche élève
  *               et qu'il n'existe pas d'autres positions dans ce cas, alors remise à 0 du champs sur
  *               la fiche élève (e.g : Frais d'inscription, dépot de garantie.)
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_BILL_HEADER_ID : Ecolage
  */
  procedure ReinitStudentsFields(aSCH_BILL_HEADER_ID number)
  is
    cursor crEcolage
    is
      select POS.SCH_ECOLAGE_ID
           , POS.SCH_STUDENT_ID
           , ECO.ECO_UPDT_REGISTR_BILLED
           , ECO.ECO_UPDT_GUARANT_BILLED
        from SCH_BILL_POSITION POS
           , SCH_ECOLAGE ECO
       where POS.SCH_BILL_HEADER_ID = aSCH_BILL_HEADER_ID
         and POS.SCH_ECOLAGE_ID = ECO.SCH_ECOLAGE_ID
         and (   ECO.ECO_UPDT_REGISTR_BILLED = 1
              or ECO.ECO_UPDT_GUARANT_BILLED = 1);
  begin
    for tplEcolage in crEcolage loop
      update SCH_STUDENT
         set STU_REGISTRATION_BILLED =(case
                                         when tplEcolage.ECO_UPDT_REGISTR_BILLED = 1 then 0
                                         else STU_REGISTRATION_BILLED
                                       end)
           , STU_GUARANTEE_BILLED =(case
                                      when tplEcolage.ECO_UPDT_GUARANT_BILLED = 1 then 0
                                      else STU_GUARANTEE_BILLED
                                    end)
       where SCH_STUDENT_ID = tplEcolage.SCH_STUDENT_ID
         and not exists(
                   select 1
                     from SCH_BILL_POSITION
                    where SCH_STUDENT_ID = tplEcolage.SCH_STUDENT_ID
                      and SCH_BILL_HEADER_ID <> aSCH_BILL_HEADER_ID
                      and SCH_ECOLAGE_ID = tplEcolage.SCH_ECOLAGE_ID);
    end loop;
  end;

  /**
  * procedure UpdateStudentAge
  * Description : Mise à jour de l'age des élèves au premier jour de la période concernée
  *               par la facturation.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_YEAR_PERIOD_ID : Période facturée.
  */
  procedure UpdateStudentAge(aSCH_YEAR_PERIOD_ID SCH_YEAR_PERIOD.SCH_YEAR_PERIOD_ID%type)
  is
    -- Curseur sur les élèves
    cursor CUR_SCH_STUDENT
    is
      select STU.SCH_STUDENT_ID
           , STU.STU_BIRTH_DATE
        from SCH_STUDENT STU
           , COM_LIST_ID_TEMP LID
       where LID.COM_LIST_ID_TEMP_ID = STU.SCH_STUDENT_ID
         and LID.LID_CODE = 'SCH_STUDENT_ID';

    -- Variables
    CurSchStudent     CUR_SCH_STUDENT%rowtype;
    Age               integer;
    VarPER_BEGIN_DATE date;
    VarDay            integer;
    VarMonth          integer;
    VarYear           integer;
  begin
    begin
      /* On recupére les jours, mois et année de la date du début de facturation */
      select to_number(to_char(PER_BEGIN_DATE, 'DD') )
           , to_number(to_char(PER_BEGIN_DATE, 'MM') )
           , to_number(to_char(PER_BEGIN_DATE, 'YYYY') )
        into VarDay
           , VarMonth
           , VarYear
        from SCH_YEAR_PERIOD
       where SCH_YEAR_PERIOD_ID = aSCH_YEAR_PERIOD_ID;

      -- Ouverture du curseur sur les étudiants
      for CurSchStudent in CUR_SCH_STUDENT loop
        -- Age au premier jour de la période facturée
        Age  := 0;
        Age  :=(VarYear - to_number(to_char(CurSchStudent.STU_BIRTH_DATE, 'YYYY') ) );

        if (VarMonth - to_number(to_char(CurSchStudent.STU_BIRTH_DATE, 'MM') ) ) < 0 then
          Age  := Age - 1;
        elsif     ( (VarMonth - to_number(to_char(CurSchStudent.STU_BIRTH_DATE, 'MM') ) ) = 0)
              and (VarDay - to_number(to_char(CurSchStudent.STU_BIRTH_DATE, 'DD') ) ) < 0 then
          Age  := Age - 1;
        end if;

        update SCH_STUDENT
           set STU_BEGIN_TERM_AGE = Age
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where SCH_STUDENT_ID = CurSchStudent.SCH_STUDENT_ID;

        -- Age au début de l'Année de la période facturée
        Age  := 0;
        Age  :=(VarYear - to_number(to_char(CurSchStudent.STU_BIRTH_DATE, 'YYYY') ) );

        update SCH_STUDENT
           set STU_BEGIN_YEAR_AGE = Age
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where SCH_STUDENT_ID = CurSchStudent.SCH_STUDENT_ID;
      end loop;
    exception
      when others then
        raise;
    end;
  end UpdateStudentAge;

  /**
  * function GetEcolagePositions
  * Description : Récupération des positions d'écolage à facture, préparées préalablement.
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param
  */
  function GetEcolagePositions
    return TabBillPositionRec pipelined
  is
  begin
    if aTabBillPositionRec.count > 0 then
      for i in aTabBillPositionRec.first .. aTabBillPositionRec.last loop
        pipe row(aTabBillPositionRec(i) );
      end loop;
    end if;
  end;

  /***
  * function GetDiscountAmount
  * Description : Récupération remises en cours pour une période et un élève
  *               (notion de priorité dans l'application des remises)
  * @created ECA
  * @lastUpdate
  * @private
  * @param   iSCH_STUDENT_ID : Eleve
  * @param   iSCH_YEAR_PERIOD_ID : Période
  */
  function GetDiscountAmount(iSCH_STUDENT_ID in number, iSCH_YEAR_PERIOD_ID in number)
    return number
  is
    lntotalAmount number;
  begin
    if aTabBillPositionRec.count > 0 then
      for i in aTabBillPositionRec.first .. aTabBillPositionRec.last loop
        if     aTabBillPositionRec(i).aSCH_DISCOUNT_ID is not null
           and aTabBillPositionRec(i).aSCH_STUDENT_ID = iSCH_STUDENT_ID
           and aTabBillPositionRec(i).aSCH_YEAR_PERIOD_ID = iSCH_YEAR_PERIOD_ID then
          lntotalAmount  := nvl(lntotalAmount, 0) + aTabBillPositionRec(i).aBOP_TTC_AMOUNT;
        end if;
      end loop;

      return lntotalAmount;
    else
      return 0;
    end if;
  end GetDiscountAmount;

  /**
  * function ProrateCalculation
  * Description : Calcul des montants au prorata
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aSCH_STUDENT_ID : Elève
  * @param   aSCH_YEAR_PERIOD_ID : Période facturée
  * @param   aFullAmount : Montant TTC
  * @param   aC_PRORATE_TYPE : Type de prorata (au jour, mois, semaine)
  * @return  Montant au prorata
  */
  function ProrateCalculation(aSCH_STUDENT_ID number, aSCH_YEAR_PERIOD_ID number, aFullAmount number, aC_PRORATE_TYPE varchar2)
    return number
  is
    -- Variables
    Jour_Debut_Periode        number;   -- Date du debut de la période convertie en nombre de jours
    Jour_Fin_Periode          number;   -- Date de fin de la période convertie en nombre de jours
    Date_Debut_Periode        date;   -- Date de début de la période concernée
    Date_Fin_Periode          date;   -- Date de fin de la période concernée
    Date_Entree               date;   -- Date d'entrée de l'élève à l'école
    Date_Sortie               date;   -- Date de sortie de l'élève de l'école
    Nb_Jour_Periode           number;   -- Nombre de jours couverts par la période concernée
    Nb_Jour_A_Facturer        number;   -- Nombre de jours à facturer pour cette période
    Debut_Periode_Non_Facture number;   -- Nombre de jours à ne pas facturer en début de période
    Fin_Periode_Non_Facture   number;   -- Nombre de jours à ne pas facturer en fin de période
    DateDebutFacturation      date;
    DateFinFacturation        date;
  begin
    -- On récupère les dates de début et de fin du groupe de périodes qui va être facturé
    select min(nvl(trunc(YEA.PER_BEGIN_DATE), to_date('01/01/1901', 'DD/MM/YYYY') ) )
         , max(nvl(trunc(YEA.PER_END_DATE), to_date('01/01/2899', 'DD/MM/YYYY') ) )
      into Date_Debut_Periode
         , Date_Fin_Periode
      from SCH_YEAR_PERIOD YEA
     where YEA.SCH_YEAR_PERIOD_ID = aSCH_YEAR_PERIOD_ID;

    -- Puis les dates d'entrée et de sortie de l'étudiant
    select nvl(trunc(STU_ENTRY_DATE), to_date('01/01/1900', 'DD/MM/YYYY') )
         , nvl(trunc(STU_EXIT_DATE), to_date('01/01/2899', 'DD/MM/YYYY') )
      into Date_Entree
         , Date_sortie
      from SCH_STUDENT
     where SCH_STUDENT_ID = aSCH_STUDENT_ID;

    /* Si Prorata au mois */
    if aC_PRORATE_TYPE = 2 then
      if     Date_Entree <= Date_Debut_Periode
         and Date_Sortie >= Date_Fin_Periode then
        return aFullAmount;
      else
        /* Recherche de la date de début de facturation */
        DateDebutFacturation  := Date_Entree;

        if to_char(DateDebutFacturation, 'YYYY-MM') <= to_char(Date_Debut_Periode, 'YYYY-MM') then
          DateDebutFacturation  := Date_Debut_Periode;
        elsif to_char(DateDebutFacturation, 'YYYY-MM') > to_char(Date_Debut_Periode, 'YYYY-MM') then
          if DateDebutFacturation <= Date_Fin_Periode then
            DateDebutFacturation  := to_date('01.' ||(to_char(DateDebutFacturation, 'MM') ) || '.' ||(to_char(DateDebutFacturation, 'YYYY') ), 'DD.MM.YYYY');
          else
            return 0;
          end if;

          if DateDebutFacturation < Date_Debut_Periode then
            DateDebutFacturation  := Date_Debut_Periode;
          end if;

          if DateDebutFacturation > Date_Fin_Periode then
            DateDebutFacturation  := Date_Fin_Periode;
          end if;
        end if;

        /* Recherche de la date de Fin de facturation */
        DateFinFacturation    := Date_Sortie;

        if to_char(DateFinFacturation, 'YYYY-MM') >= to_char(Date_Fin_Periode, 'YYYY-MM') then
          DateFinFacturation  := Date_Fin_Periode;
        elsif to_char(DateFinFacturation, 'YYYY-MM') < to_char(Date_Fin_Periode, 'YYYY-MM') then
          if to_char(DateFinFacturation, 'YYYY-MM') >= to_char(Date_Debut_Periode, 'YYYY-MM') then
            DateFinFacturation  := to_date('01.' ||(to_char(DateFinFacturation, 'MM') ) || '.' ||(to_char(DateFinFacturation, 'YYYY') ), 'DD.MM.YYYY');
            DateFinFacturation  := add_months(DateFinFacturation, 1) - 1;
          else
            return 0;
          end if;

          if DateFinFacturation > Date_Fin_Periode then
            DateFinFacturation  := Date_Fin_Periode;
          end if;

          if DateFinFacturation < Date_Debut_Periode then
            DateFinFacturation  := Date_Debut_Periode;
          end if;
        end if;
      end if;
    /* Calcul prorata à la semaine près */
    elsif aC_PRORATE_TYPE = 1 then
      if     DOC_DELAY_FUNCTIONS.DATETOWEEK(Date_Entree) <= DOC_DELAY_FUNCTIONS.DATETOWEEK(Date_Debut_Periode)
         and DOC_DELAY_FUNCTIONS.DATETOWEEK(Date_Sortie) >= DOC_DELAY_FUNCTIONS.DATETOWEEK(Date_Fin_Periode) then
        return aFullAmount;
      else
        /* Recherche de la date de début de facturation */
        DateDebutFacturation  := Date_Entree;

        if DOC_DELAY_FUNCTIONS.DATETOWEEK(DateDebutFacturation) <= DOC_DELAY_FUNCTIONS.DATETOWEEK(Date_Debut_Periode) then
          DateDebutFacturation  := Date_Debut_Periode;
        elsif DOC_DELAY_FUNCTIONS.DATETOWEEK(DateDebutFacturation) > DOC_DELAY_FUNCTIONS.DATETOWEEK(Date_Debut_Periode) then
          if DOC_DELAY_FUNCTIONS.DATETOWEEK(DateDebutFacturation) <= DOC_DELAY_FUNCTIONS.DATETOWEEK(Date_Fin_Periode) then
            DateDebutFacturation  := DOC_DELAY_FUNCTIONS.WEEKTODATE(DOC_DELAY_FUNCTIONS.DATETOWEEK(DateDebutFacturation), 1);
          else
            return 0;
          end if;
        end if;

        /* Recherche de la date de Fin de facturation */
        DateFinFacturation    := Date_Sortie;

        if DOC_DELAY_FUNCTIONS.DATETOWEEK(DateFinFacturation) >= DOC_DELAY_FUNCTIONS.DATETOWEEK(Date_Fin_Periode) then
          DateFinFacturation  := Date_Fin_Periode;
        elsif DOC_DELAY_FUNCTIONS.DATETOWEEK(DateFinFacturation) < DOC_DELAY_FUNCTIONS.DATETOWEEK(Date_Fin_Periode) then
          if DOC_DELAY_FUNCTIONS.DATETOWEEK(DateFinFacturation) >= DOC_DELAY_FUNCTIONS.DATETOWEEK(Date_Debut_Periode) then
            DateFinFacturation  := DOC_DELAY_FUNCTIONS.WEEKTODATE(DOC_DELAY_FUNCTIONS.DATETOWEEK(DateFinFacturation), 7);
          else
            return 0;
          end if;
        end if;
      end if;
    /* Calcul prorata au Jour près */
    elsif aC_PRORATE_TYPE = 0 then
      if     Date_Entree <= Date_Debut_Periode
         and Date_Sortie >= Date_Fin_Periode then
        return aFullAmount;
      else
        /* Recherche de la date de début de facturation */
        DateDebutFacturation  := Date_Entree;

        if DateDebutFacturation <= Date_Debut_Periode then
          DateDebutFacturation  := Date_Debut_Periode;
        elsif DateDebutFacturation > Date_Debut_Periode then
          if DateDebutFacturation <= Date_Fin_Periode then
            null;
          else
            return 0;
          end if;
        end if;

        /* Recherche de la date de Fin de facturation */
        DateFinFacturation    := Date_Sortie;

        if DateFinFacturation >= Date_Fin_Periode then
          DateFinFacturation  := Date_Fin_Periode;
        elsif DateFinFacturation < Date_Fin_Periode then
          if DateFinFacturation >= Date_Debut_Periode then
            null;
          else
            return 0;
          end if;
        end if;
      end if;
    end if;

    /* Calcul du nb de jour couvert par la période comcernée */
    select (to_number(to_char(Date_Fin_Periode, 'J') ) - to_number(to_char(Date_Debut_Periode, 'J') ) ) + 1
      into Nb_Jour_Periode
      from dual;

    /* Calcul du nombre de jours couverts par les dates de facturation de l'élève */
    select (to_number(to_char(DateFinFacturation, 'J') ) - to_number(to_char(DateDebutFacturation, 'J') ) ) + 1
      into Nb_Jour_A_Facturer
      from dual;

    /* Calcul du montant au prorata */
    if Nb_Jour_Periode <> 0 then
      return round( (aFullAmount / Nb_Jour_Periode) * Nb_Jour_A_Facturer, 0);
    else
      return 0;
    end if;
  end ProrateCalculation;

  /**
  * function CalcContractualAmount
  * Description :
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aSCH_ECOLAGE_CATEGORY_ID : Catégorie concernée
  * @param   aSCH_STUDENT_ID : Eleve
  * @return  montant forfaitaire de l'écolage
  */
  function CalcContractualAmount(aSCH_ECOLAGE_CATEGORY_ID number, aSCH_STUDENT_ID number)
    return number
  is
    -- Curseur sur les montants forfaitaires
    cursor CUR_CONTRACTUAL_AMOUNT
    is
      select SEC.C_ECOLAGE_TYPE_AMOUNT
           , CONFIG.CON_NAME
           , field.FIT_TABLE_NAME
           , field.FIT_NAME
           , CARACT.SCH_FREE_CHARACT_TYPE_ID
        from SCH_ECOLAGE_CATEGORY SEC
           , SCH_DISCOUNT_CONFIG_TYPE CONFIG
           , SCH_DISCOUNT_FIELD_TYPE field
           , SCH_FREE_CHARACT_TYPE CARACT
       where SEC.SCH_ECOLAGE_CATEGORY_ID = aSCH_ECOLAGE_CATEGORY_ID
         and SEC.SCH_DISCOUNT_CONFIG_TYPE_ID = CONFIG.SCH_DISCOUNT_CONFIG_TYPE_ID(+)
         and SEC.SCH_DISCOUNT_FIELD_TYPE_ID = field.SCH_DISCOUNT_FIELD_TYPE_ID(+)
         and SEC.SCH_FREE_CHARACT_TYPE_ID = CARACT.SCH_FREE_CHARACT_TYPE_ID(+);

    --Variables
    CurContractualAmount CUR_CONTRACTUAL_AMOUNT%rowtype;
    VarTTC_AMOUNT        number;
  begin
    -- On récupère les caractéristiques de ce montant forfaitaire
    open CUR_CONTRACTUAL_AMOUNT;

    fetch CUR_CONTRACTUAL_AMOUNT
     into CurContractualAmount;

    -- Montant sur un champ
    if CurContractualAmount.C_ECOLAGE_TYPE_AMOUNT = '0' then
      if CurContractualAmount.FIT_NAME = 'STU_GUARANTEE_AMOUNT' then
        begin
          select nvl(STU_GUARANTEE_AMOUNT, 0)
            into VarTTC_AMOUNT
            from SCH_STUDENT
           where SCH_STUDENT_ID = aSCH_STUDENT_ID;
        exception
          when no_data_found then
            VarTTC_AMOUNT  := 0;
        end;
      -- Sinon, montant nul
      else
        VarTTC_AMOUNT  := 0;
      end if;
    -- Montant sur une config
    elsif CurContractualAmount.C_ECOLAGE_TYPE_AMOUNT = '1' then
      VarTTC_AMOUNT  := to_number(PCS.PC_CONFIG.GETCONFIG(CurContractualAmount.CON_NAME) );
    -- Montant sur un une caractéristique libre
    elsif CurContractualAmount.C_ECOLAGE_TYPE_AMOUNT = '2' then
      begin
        select nvl(FRC_NUMERIC_VAL, 0)
          into VarTTC_AMOUNT
          from SCH_FREE_CHARACTERISTIC
         where SCH_STUDENT_ID = aSCH_STUDENT_ID
           and SCH_FREE_CHARACT_TYPE_ID = CurContractualAmount.SCH_FREE_CHARACT_TYPE_ID;
      exception
        when no_data_found then
          VarTTC_AMOUNT  := 0;
      end;
    else
      VarTTC_AMOUNT  := 0;
    end if;

    close CUR_CONTRACTUAL_AMOUNT;

    return VarTTC_AMOUNT;
  end CalcContractualAmount;

  /**
  * function CalcRoundedEcolageAmount
  * Description : Calcul des montants d'écolages
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aSCH_YEAR_PERIOD_ID : période
  * @param   aSCH_STUDENT_ID : élève
  * @param   aSCH_ECOLAGE_CATEGORY_ID : catégorie
  * @param   aCAT_CONTRACTUAL_AMOUNT : montant forfaitaire
  * @param   aSTU_PRORATE_PAIMENT : élève avec paiement au prorata
  * @param   aECO_PRORATE_PAIMENT : Ecolage avec paiement au prorata
  * @param   aC_PRORATE_TYPE : Typde prorata
  * @param   aBOP_TTC_AMOUNT : Montant TTC
  */
  procedure CalcRoundedEcolageAmount(
    aSCH_YEAR_PERIOD_ID      in     number
  , aSCH_STUDENT_ID          in     number
  , aSCH_ECOLAGE_CATEGORY_ID in     number
  , aCAT_CONTRACTUAL_AMOUNT  in     integer
  , aSTU_PRORATE_PAIMENT     in     integer
  , aECO_PRORATE_PAIMENT     in     integer
  , aC_PRORATE_TYPE          in     varchar2
  , aBOP_TTC_AMOUNT          in out number
  )
  is
    NbPeriodInGroup integer;
  begin
    -- Cas des montants par période
    if aCAT_CONTRACTUAL_AMOUNT = 0 then
      select nvl(sum(AMO_AMOUNT_HT), 0)
        into aBOP_TTC_AMOUNT
        from SCH_AMOUNT_HT AHT
       where AHT.SCH_YEAR_PERIOD_ID = aSCH_YEAR_PERIOD_ID
         and AHT.SCH_ECOLAGE_CATEGORY_ID = aSCH_ECOLAGE_CATEGORY_ID;
    -- Cas des montants au forfait
    else
      -- Montant par période
      aBOP_TTC_AMOUNT  := CalcContractualAmount(aSCH_ECOLAGE_CATEGORY_ID, aSCH_STUDENT_ID);
    end if;

    -- Calcul du montant au Pro - rata du temps passé si nécessaire
    if     aSTU_PRORATE_PAIMENT = 1
       and aECO_PRORATE_PAIMENT = 1 then
      aBOP_TTC_AMOUNT  := ProrateCalculation(aSCH_STUDENT_ID, aSCH_YEAR_PERIOD_ID, aBOP_TTC_AMOUNT, aC_PRORATE_TYPE);
    end if;

    aBOP_TTC_AMOUNT  := SCH_TOOLS.ROUNDAMOUNT(aBOP_TTC_AMOUNT);
  end CalcRoundedEcolageAmount;

  /**
  * procedure PrepareEcolagePositionTable
  * Description : Préparation des écolages à facturer
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aPAC_PAYMENT_CONDITION_ID : Conditions de paiement
  * @param   aC_GROUPING_MODE : Mode de regroupement
  * @param   aDMT_DATE_VALUE : Date valeur document
  * @param   aDOC_GAUGE_ID : Gabarit
  * @param   aSCH_YEAR_PERIOD_ID : Période facturée
  * @param   aSCH_GROUP_YEAR_PERIOD_ID : Groupe facturé
  * @param   aDicCustomerTypeId : Type de tiers
  */
  procedure PrepareEcolagePositionTable(
    aPAC_PAYMENT_CONDITION_ID in number
  , aC_GROUPING_MODE          in varchar2
  , aDMT_DATE_VALUE           in date
  , aDOC_GAUGE_ID             in number
  , aSCH_YEAR_PERIOD_ID       in number
  , aSCH_GROUP_YEAR_PERIOD_ID in number
  , aDicCustomerTypeId        in varchar2
  )
  is
    -- Curseur sur les catégories d'écolages actifs sélectionnés
    cursor crSchEcolageCategory
    is
      select   ECO.SCH_ECOLAGE_ID
             , ECO.ECO_MAJOR_REFERENCE
             , ECO.ECO_SECONDARY_REFERENCE
             , ECO.ECO_SHORT_DESCR
             , ECO.ECO_LONG_DESCR
             , ECO.ECO_FREE_DESCR
             , nvl(ECO.ECO_UPDT_REGISTR_BILLED, 0) ECO_UPDT_REGISTR_BILLED
             , nvl(ECO.ECO_UPDT_GUARANT_BILLED, 0) ECO_UPDT_GUARANT_BILLED
             , ECO.ECO_PRORATE_ALLOWED
             , ECO.C_PRORATE_TYPE
             , CAT.SCH_ECOLAGE_CATEGORY_ID
             , CAT.GCO_GOOD_ID
             , CAT.CAT_MAJOR_REFERENCE
             , CAT.CAT_SECONDARY_REFERENCE
             , CAT.CAT_SHORT_DESCR
             , CAT.CAT_LONG_DESCR
             , CAT.CAT_FREE_DESCR
             , CAT.CAT_CONTRACTUAL_AMOUNT
             , CAT.C_ECOLAGE_TYPE_AMOUNT
             , CAT.SCH_DISCOUNT_CONFIG_TYPE_ID
             , CAT.SCH_DISCOUNT_FIELD_TYPE_ID
             , CAT.SCH_FREE_CHARACT_TYPE_ID
          from SCH_ECOLAGE ECO
             , SCH_ECOLAGE_CATEGORY CAT
         where ECO.ECO_ACTIVE = 1
           and ECO.SCH_ECOLAGE_ID = CAT.SCH_ECOLAGE_ID
           and ECO.SCH_ECOLAGE_ID in(select COM_LIST_ID_TEMP_ID
                                       from COM_LIST_ID_TEMP
                                      where LID_CODE = 'SCH_ECOLAGE_ID')
           and CAT.SCH_ECOLAGE_CATEGORY_ID in(select COM_LIST_ID_TEMP_ID
                                                from COM_LIST_ID_TEMP
                                               where LID_CODE = 'SCH_ECOLAGE_CATEGORY_ID')
      order by ECO_MAJOR_REFERENCE asc;

    vSQLStudentSelection      varchar2(32000);
    aPAC_CUSTOM_PARTNER_ID    number;
    aACS_VAT_DET_ACCOUNT_ID   number;
    aACS_FIN_ACC_S_PAYMENT_ID number;
    aDIC_TYPE_SUBMISSION_ID   varchar2(10);
    aPER_KEY1                 varchar2(20);
    iPAC_PAYMENT_CONDITION_ID number;
    aYetInserted              number;
    aTempTabBillPositionRec   TabBillPositionRec;
  begin
    -- Pour chaque catégorie d'écolages actifs
    for tplSchEcolageCategory in crSchEcolageCategory loop
      -- Construction de la requête de sélection des élèves concernés par la catégorie
      vSQLStudentSelection  := BuildStudentSelectionQuery(tplSchEcolageCategory.SCH_ECOLAGE_CATEGORY_ID, aSCH_YEAR_PERIOD_ID);

      -- Récupération des enregistrements dans une table mémoire
      execute immediate vSQLStudentSelection
      bulk collect into aTempTabBillPositionRec;

      -- Completion de la table des écolages groupés
      if aTempTabBillPositionRec.count > 0 then
        for i in aTempTabBillPositionRec.first .. aTempTabBillPositionRec.last loop
          aYetInserted  := 0;

          if tplSchEcolageCategory.ECO_UPDT_REGISTR_BILLED = 1 then
            begin
              select nvl(max(SCH_DEPENDENCY_ID), 0)
                into aYetInserted
                from SCH_GROUP_DEPENDENCY SGD
                   , SCH_DEPENDENCY SD
               where SGD.SCH_ECOLAGE_CATEGORY_ID = tplSchEcolageCategory.SCH_ECOLAGE_CATEGORY_ID
                 and SGD.SCH_GROUP_DEPENDENCY_ID = SD.SCH_GROUP_DEPENDENCY_ID(+)
                 and SD.DEP_REGISTRATION_BILLED = 1
                 and SD.DEP_REGISTRATION_BILLED_VAL = 0
                 and exists(
                       select 1
                         from table(SCH_ECOLAGE_BILLING.GetEcolagePositions) tab
                            , SCH_ECOLAGE ECO
                        where tab.aSCH_ECOLAGE_ID = tplSchEcolageCategory.SCH_ECOLAGE_ID
                          and tab.aSCH_STUDENT_ID = aTempTabBillPositionRec(i).aSCH_STUDENT_ID
                          and tab.aSCH_GROUP_YEAR_PERIOD_ID = aSCH_GROUP_YEAR_PERIOD_ID
                          and ECO.SCH_ECOLAGE_ID = tab.aSCH_ECOLAGE_ID
                          and ECO.ECO_UPDT_REGISTR_BILLED = 1);
            exception
              when others then
                begin
                  aYetInserted  := 0;
                end;
            end;
          elsif tplSchEcolageCategory.ECO_UPDT_GUARANT_BILLED = 1 then
            begin
              select nvl(max(SCH_DEPENDENCY_ID), 0)
                into aYetInserted
                from SCH_GROUP_DEPENDENCY SGD
                   , SCH_DEPENDENCY SD
               where SGD.SCH_ECOLAGE_CATEGORY_ID = tplSchEcolageCategory.SCH_ECOLAGE_CATEGORY_ID
                 and SGD.SCH_GROUP_DEPENDENCY_ID = SD.SCH_GROUP_DEPENDENCY_ID(+)
                 and SD.DEP_GUARANTEE_BILLED = 1
                 and SD.DEP_GUARANTEE_BILLED_VAL = 0
                 and exists(
                       select 1
                         from table(SCH_ECOLAGE_BILLING.GetEcolagePositions) tab
                            , SCH_ECOLAGE ECO
                        where tab.aSCH_ECOLAGE_ID = tplSchEcolageCategory.SCH_ECOLAGE_ID
                          and tab.aSCH_STUDENT_ID = aTempTabBillPositionRec(i).aSCH_STUDENT_ID
                          and tab.aSCH_GROUP_YEAR_PERIOD_ID = aSCH_GROUP_YEAR_PERIOD_ID
                          and ECO.SCH_ECOLAGE_ID = tab.aSCH_ECOLAGE_ID
                          and ECO.ECO_UPDT_GUARANT_BILLED = 1);
            exception
              when others then
                begin
                  aYetInserted  := 0;
                end;
            end;
          end if;

          if aYetInserted = 0 then
            aTabBillPositionRec.extend;
            -- information de l'èlève
            aTabBillPositionRec(aTabBillPositionRec.last).aSCH_STUDENT_ID             := aTempTabBillPositionRec(i).aSCH_STUDENT_ID;
            aTabBillPositionRec(aTabBillPositionRec.last).aSTU_ACCOUNT_NUMBER         := aTempTabBillPositionRec(i).aSTU_ACCOUNT_NUMBER;
            aTabBillPositionRec(aTabBillPositionRec.last).aSTU_PRORATE_PAYMENT        := aTempTabBillPositionRec(i).aSTU_PRORATE_PAYMENT;
            aTabBillPositionRec(aTabBillPositionRec.last).aSTU_ECO_MIXED_BILLING      := aTempTabBillPositionRec(i).aSTU_ECO_MIXED_BILLING;
            aTabBillPositionRec(aTabBillPositionRec.last).aDefltPAC_CUSTOM_PARTNER    := aTempTabBillPositionRec(i).aDefltPAC_CUSTOM_PARTNER;
            -- Paramètres de la facturation
            aTabBillPositionRec(aTabBillPositionRec.last).aSCH_GROUP_YEAR_PERIOD_ID   := aSCH_GROUP_YEAR_PERIOD_ID;
            aTabBillPositionRec(aTabBillPositionRec.last).aSCH_YEAR_PERIOD_ID         := aSCH_YEAR_PERIOD_ID;
            aTabBillPositionRec(aTabBillPositionRec.last).aDOC_GAUGE_ID               := aDOC_GAUGE_ID;
            aTabBillPositionRec(aTabBillPositionRec.last).aBillDate                   := aDMT_DATE_VALUE;
            aTabBillPositionRec(aTabBillPositionRec.last).aC_GROUPING_MODE            := aC_GROUPING_MODE;
            aTabBillPositionRec(aTabBillPositionRec.last).aSTU_ECO_OTHER_ADDRESS      := aTempTabBillPositionRec(i).aSTU_ECO_OTHER_ADDRESS;
            -- informations sur les écolages et catégories
            aTabBillPositionRec(aTabBillPositionRec.last).aSCH_ECOLAGE_ID             := tplSchEcolageCategory.SCH_ECOLAGE_ID;
            aTabBillPositionRec(aTabBillPositionRec.last).aSCH_ECOLAGE_CATEGORY_ID    := tplSchEcolageCategory.SCH_ECOLAGE_CATEGORY_ID;
            aTabBillPositionRec(aTabBillPositionRec.last).aBOP_MAJOR_REFERENCE        := tplSchEcolageCategory.ECO_MAJOR_REFERENCE;
            aTabBillPositionRec(aTabBillPositionRec.last).aBOP_SECONDARY_REFERENCE    := tplSchEcolageCategory.CAT_MAJOR_REFERENCE;
            aTabBillPositionRec(aTabBillPositionRec.last).aBOP_DESCRIPTION            := tplSchEcolageCategory.ECO_SECONDARY_REFERENCE;
            aTabBillPositionRec(aTabBillPositionRec.last).aBOP_CATEGORY_DESCR         := tplSchEcolageCategory.CAT_SECONDARY_REFERENCE;
            aTabBillPositionRec(aTabBillPositionRec.last).aBOP_SHORT_DESCR            := tplSchEcolageCategory.CAT_SHORT_DESCR;
            aTabBillPositionRec(aTabBillPositionRec.last).aBOP_LONG_DESCR             := tplSchEcolageCategory.CAT_LONG_DESCR;
            aTabBillPositionRec(aTabBillPositionRec.last).aBOP_FREE_DESCR             := tplSchEcolageCategory.CAT_FREE_DESCR;
            aTabBillPositionRec(aTabBillPositionRec.last).aGCO_GOOD_ID                := tplSchEcolageCategory.GCO_GOOD_ID;
            -- Informations de montant, qté
            CalcRoundedEcolageAmount(aSCH_YEAR_PERIOD_ID
                                   , aTabBillPositionRec(aTabBillPositionRec.last).aSCH_STUDENT_ID
                                   , tplSchEcolageCategory.SCH_ECOLAGE_CATEGORY_ID
                                   , tplSchEcolageCategory.CAT_CONTRACTUAL_AMOUNT
                                   , aTabBillPositionRec(aTabBillPositionRec.last).aSTU_PRORATE_PAYMENT
                                   , tplSchEcolageCategory.ECO_PRORATE_ALLOWED
                                   , tplSchEcolageCategory.C_PRORATE_TYPE
                                   , aTabBillPositionRec(aTabBillPositionRec.last).aBOP_TTC_AMOUNT
                                    );
            aTabBillPositionRec(aTabBillPositionRec.last).aBOP_TTC_UNIT_AMOUNT        := aTabBillPositionRec(aTabBillPositionRec.last).aBOP_TTC_AMOUNT;
            aTabBillPositionRec(aTabBillPositionRec.last).aBOP_QTY                    := 1;
            aPAC_CUSTOM_PARTNER_ID                                                    := null;

            -- Recherche du débiteur par défaut
            if aDicCustomerTypeId is not null then
              aPAC_CUSTOM_PARTNER_ID  := SCH_TOOLS.GetCustomer(aTabBillPositionRec(aTabBillPositionRec.last).aSCH_STUDENT_ID, aDicCustomerTypeId);
            end if;

            -- Situation de facturation mixte , autre, ou non précisée -> Recherche par association.
            if nvl(aPAC_CUSTOM_PARTNER_ID, 0) = 0 then
              SCH_OUTLAY_FUNCTIONS.GetCustomerByAssociation(aTabBillPositionRec(aTabBillPositionRec.last).aSCH_STUDENT_ID
                                                          , null
                                                          , null
                                                          , tplSchEcolageCategory.SCH_ECOLAGE_ID
                                                          , tplSchEcolageCategory.SCH_ECOLAGE_CATEGORY_ID
                                                          , aDMT_DATE_VALUE
                                                          , 0
                                                          , aPAC_CUSTOM_PARTNER_ID
                                                           );

              if nvl(aPAC_CUSTOM_PARTNER_ID, 0) = 0 then
                aPAC_CUSTOM_PARTNER_ID  := aTabBillPositionRec(aTabBillPositionRec.last).aDefltPAC_CUSTOM_PARTNER;
              end if;
            end if;

            aTabBillPositionRec(aTabBillPositionRec.last).aPAC_CUSTOM_PARTNER_ID      := aPAC_CUSTOM_PARTNER_ID;

            begin
              aACS_VAT_DET_ACCOUNT_ID                                                  := null;
              aACS_FIN_ACC_S_PAYMENT_ID                                                := null;
              aDIC_TYPE_SUBMISSION_ID                                                  := null;
              aPER_KEY1                                                                := null;
              iPAC_PAYMENT_CONDITION_ID                                                := null;

              select distinct PAC.ACS_VAT_DET_ACCOUNT_ID
                            , PAC.ACS_FIN_ACC_S_PAYMENT_ID
                            , PAC.DIC_TYPE_SUBMISSION_ID
                            , PER.PER_KEY1
                            , PAC.PAC_PAYMENT_CONDITION_ID
                         into aACS_VAT_DET_ACCOUNT_ID
                            , aACS_FIN_ACC_S_PAYMENT_ID
                            , aDIC_TYPE_SUBMISSION_ID
                            , aPER_KEY1
                            , iPAC_PAYMENT_CONDITION_ID
                         from COM_LIST_ID_TEMP LID
                            , ACS_AUX_ACCOUNT_S_FIN_CURR AAA
                            , PAC_CUSTOM_PARTNER PAC
                            , PAC_PERSON PER
                        where PAC.ACS_AUXILIARY_ACCOUNT_ID = AAA.ACS_AUXILIARY_ACCOUNT_ID(+)
                          and PAC.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
                          and PAC.PAC_CUSTOM_PARTNER_ID = LID.COM_LIST_ID_TEMP_ID
                          and LID.LID_CODE = 'PAC_CUSTOM_PARTNER_ID'
                          and PAC.PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID;

              aTabBillPositionRec(aTabBillPositionRec.last).aACS_VAT_DET_ACCOUNT_ID    := aACS_VAT_DET_ACCOUNT_ID;
              aTabBillPositionRec(aTabBillPositionRec.last).aACS_FIN_ACC_S_PAYMENT_ID  := aACS_FIN_ACC_S_PAYMENT_ID;
              aTabBillPositionRec(aTabBillPositionRec.last).aDIC_TYPE_SUBMISSION_ID    := aDIC_TYPE_SUBMISSION_ID;
              aTabBillPositionRec(aTabBillPositionRec.last).aPER_KEY1                  := aPER_KEY1;
            exception
              when others then
                begin
                  aTabBillPositionRec(aTabBillPositionRec.last).aACS_VAT_DET_ACCOUNT_ID    := null;
                  aTabBillPositionRec(aTabBillPositionRec.last).aACS_FIN_ACC_S_PAYMENT_ID  := null;
                  aTabBillPositionRec(aTabBillPositionRec.last).aDIC_TYPE_SUBMISSION_ID    := null;
                  aTabBillPositionRec(aTabBillPositionRec.last).aPER_KEY1                  := null;
                end;
            end;

            aTabBillPositionRec(aTabBillPositionRec.last).aACS_FINANCIAL_CURRENCY_ID  := SCH_TOOLS.GetBaseMoney;
            aTabBillPositionRec(aTabBillPositionRec.last).aPAC_PAYMENT_CONDITION_ID   :=
                                                         case
                                                           when nvl(aPAC_PAYMENT_CONDITION_ID, 0) = 0 then iPAC_PAYMENT_CONDITION_ID
                                                           else aPAC_PAYMENT_CONDITION_ID
                                                         end;
            -- Divers
            aTabBillPositionRec(aTabBillPositionRec.last).aSCH_DISCOUNT_ID            := null;
            aTabBillPositionRec(aTabBillPositionRec.last).aBOP_SEQ                    := null;
          end if;
        end loop;
      end if;
    end loop;
  end PrepareEcolagePositionTable;

  /**
  * procedure ProcessEcolageBilling
  * Description : Génération des factures d'écolage
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aPAC_PAYMENT_CONDITION_ID : Conditions de paiement
  * @param   aC_GROUPING_MODE : Mode de regroupement
  * @param   aDMT_DATE_VALUE : Date valeur document
  * @param   aDOC_GAUGE_ID : Gabarit
  * @param   aSCH_GROUP_YEAR_PERIOD_ID : Groupe de périodes facturées
  * @param   aGroupPeriodAmount : Regrouper les périodes facturées
  * @return  aSuccessfulCount : Doc générés avec succes
  * @return  aTotalCount : Factures totales sélectionnées pour génération
  * @param   aDicCustomerTypeId : Type de Partenaire facturé par défaut. Parent1,2,société,Cours vacances...etc
  */
  procedure ProcessEcolageBilling(
    aPAC_PAYMENT_CONDITION_ID in     number
  , aC_GROUPING_MODE          in     varchar2
  , aDMT_DATE_VALUE           in     date
  , aDOC_GAUGE_ID             in     number
  , aSCH_GROUP_YEAR_PERIOD_ID in     number
  , aGroupPeriodAmount        in     integer
  , aSuccessfulCount          in out integer
  , aTotalCount               in out integer
  , aDicCustomerTypeId        in     varchar2
  , iDateDocument             in     date default null
  )
  is
    -- Curseur sur les périodes du groupe facturé
    cursor crSchGroupYearPeriod
    is
      select distinct SCH_YEAR_PERIOD_ID
                 from SCH_PERIOD_GRP_PERIOD_LINK LNK
                where LNK.SCH_GROUP_YEAR_PERIOD_ID = aSCH_GROUP_YEAR_PERIOD_ID;

    -- Curseur sur les positions pré-préparée, par clients
    cursor crProcessByCustomer
    is
      select distinct aPAC_CUSTOM_PARTNER_ID
                    , null
                    , null
                    , aACS_VAT_DET_ACCOUNT_ID
                    , aACS_FIN_ACC_S_PAYMENT_ID
                    , aDIC_TYPE_SUBMISSION_ID
                    , nvl(aSTU_ECO_OTHER_ADDRESS, 0) aSTU_ECO_OTHER_ADDRESS
                    , aPER_KEY1
                    , aACS_FINANCIAL_CURRENCY_ID
                    , aPAC_PAYMENT_CONDITION_ID
                 from table(SCH_ECOLAGE_BILLING.GetEcolagePositions)
                where (   aPAC_CUSTOM_PARTNER_ID is null
                       or (    aPAC_CUSTOM_PARTNER_ID is not null
                           and aPAC_CUSTOM_PARTNER_ID in(select COM_LIST_ID_TEMP_ID
                                                           from COM_LIST_ID_TEMP
                                                          where LID_CODE = 'PAC_CUSTOM_PARTNER_ID') )
                      );

    -- Curseur sur les positions pré-préparée, par clients
    cursor crProcessByCustAndStudent
    is
      select distinct aPAC_CUSTOM_PARTNER_ID
                    , aSCH_STUDENT_ID
                    , aSTU_ACCOUNT_NUMBER
                    , aACS_VAT_DET_ACCOUNT_ID
                    , aACS_FIN_ACC_S_PAYMENT_ID
                    , aDIC_TYPE_SUBMISSION_ID
                    , nvl(aSTU_ECO_OTHER_ADDRESS, 0) aSTU_ECO_OTHER_ADDRESS
                    , aPER_KEY1
                    , aACS_FINANCIAL_CURRENCY_ID
                    , aPAC_PAYMENT_CONDITION_ID
                 from table(SCH_ECOLAGE_BILLING.GetEcolagePositions)
                where (   aPAC_CUSTOM_PARTNER_ID is null
                       or (    aPAC_CUSTOM_PARTNER_ID is not null
                           and aPAC_CUSTOM_PARTNER_ID in(select COM_LIST_ID_TEMP_ID
                                                           from COM_LIST_ID_TEMP
                                                          where LID_CODE = 'PAC_CUSTOM_PARTNER_ID') )
                      );

    cursor crAllEcolage(aPacCustomPartnerId number, aSchStudentId number)
    is
      select   aSCH_STUDENT_ID
             , aSTU_ACCOUNT_NUMBER
             , aSTU_PRORATE_PAYMENT
             , aSCH_ECOLAGE_ID
             , aSCH_ECOLAGE_CATEGORY_ID
             , aSCH_DISCOUNT_ID
             , aPAC_CUSTOM_PARTNER_ID
             , aSCH_GROUP_YEAR_PERIOD_ID
             , aACS_VAT_DET_ACCOUNT_ID
             , aACS_FIN_ACC_S_PAYMENT_ID
             , aDIC_TYPE_SUBMISSION_ID
             , aACS_FINANCIAL_CURRENCY_ID
             , aDOC_GAUGE_ID
             , nvl(aSTU_ECO_OTHER_ADDRESS, 0) aSTU_ECO_OTHER_ADDRESS
             , aPER_KEY1
             , aC_GROUPING_MODE
             , aBOP_DESCRIPTION
             , aBOP_SHORT_DESCR
             , aBOP_LONG_DESCR
             , aBOP_MAJOR_REFERENCE
             , aBOP_SECONDARY_REFERENCE
             , aBOP_CATEGORY_DESCR
             , aBOP_FREE_DESCR
             , aBOP_TTC_AMOUNT
             , aBOP_TTC_UNIT_AMOUNT
             , aBOP_QTY
             , aBillDate
             , aBOP_SEQ
             , aSCH_YEAR_PERIOD_ID
             , aGCO_GOOD_ID
          from table(SCH_ECOLAGE_BILLING.GetEcolagePositions)
         where (    (    aPacCustomPartnerId is null
                     and aPAC_CUSTOM_PARTNER_ID is null)
                or (    aPacCustomPartnerId is not null
                    and aPAC_CUSTOM_PARTNER_ID = aPacCustomPartnerId)
               )
           and (   aSchStudentId is null
                or aSCH_STUDENT_ID = aSchStudentId)
      order by aSCh_ECOLAGE_ID
             , aSCH_ECOLAGE_CATEGORY_ID;

    cursor crAllEcolageGrouped(aPacCustomPartnerId number, aSchStudentId number)
    is
      select   aSCH_STUDENT_ID
             , aSTU_ACCOUNT_NUMBER
             , aSTU_PRORATE_PAYMENT
             , aSCH_ECOLAGE_ID
             , aSCH_ECOLAGE_CATEGORY_ID
             , aSCH_DISCOUNT_ID
             , aPAC_CUSTOM_PARTNER_ID
             , aSCH_GROUP_YEAR_PERIOD_ID
             , aACS_VAT_DET_ACCOUNT_ID
             , aACS_FIN_ACC_S_PAYMENT_ID
             , aDIC_TYPE_SUBMISSION_ID
             , aACS_FINANCIAL_CURRENCY_ID
             , aDOC_GAUGE_ID
             , nvl(aSTU_ECO_OTHER_ADDRESS, 0) aSTU_ECO_OTHER_ADDRESS
             , aPER_KEY1
             , aC_GROUPING_MODE
             , aBOP_DESCRIPTION
             , aBOP_SHORT_DESCR
             , aBOP_LONG_DESCR
             , aBOP_MAJOR_REFERENCE
             , aBOP_SECONDARY_REFERENCE
             , aBOP_CATEGORY_DESCR
             , aBOP_FREE_DESCR
             , sum(aBOP_TTC_AMOUNT) aBOP_TTC_AMOUNT
             , sum(aBOP_TTC_UNIT_AMOUNT) aBOP_TTC_UNIT_AMOUNT
             , sum(aBOP_QTY) aBOP_QTY
             , aBillDate
             , null aSCH_YEAR_PERIOD_ID
             , aGCO_GOOD_ID
          from table(SCH_ECOLAGE_BILLING.GetEcolagePositions)
         where (    (    aPacCustomPartnerId is null
                     and aPAC_CUSTOM_PARTNER_ID is null)
                or (    aPacCustomPartnerId is not null
                    and aPAC_CUSTOM_PARTNER_ID = aPacCustomPartnerId)
               )
           and (   aSchStudentId is null
                or aSCH_STUDENT_ID = aSchStudentId)
      group by aSCH_STUDENT_ID
             , aSTU_ACCOUNT_NUMBER
             , aSTU_PRORATE_PAYMENT
             , aSCH_ECOLAGE_ID
             , aSCH_ECOLAGE_CATEGORY_ID
             , aSCH_DISCOUNT_ID
             , aPAC_CUSTOM_PARTNER_ID
             , aSCH_GROUP_YEAR_PERIOD_ID
             , aACS_VAT_DET_ACCOUNT_ID
             , aACS_FIN_ACC_S_PAYMENT_ID
             , aDIC_TYPE_SUBMISSION_ID
             , aACS_FINANCIAL_CURRENCY_ID
             , aDOC_GAUGE_ID
             , nvl(aSTU_ECO_OTHER_ADDRESS, 0)
             , aPER_KEY1
             , aC_GROUPING_MODE
             , aBOP_DESCRIPTION
             , aBOP_SHORT_DESCR
             , aBOP_LONG_DESCR
             , aBOP_MAJOR_REFERENCE
             , aBOP_SECONDARY_REFERENCE
             , aBOP_CATEGORY_DESCR
             , aBOP_FREE_DESCR
             , aBillDate
             , aGCO_GOOD_ID
      order by aSCh_ECOLAGE_ID
             , aSCH_ECOLAGE_CATEGORY_ID;

    type TCustomers is table of crProcessByCustAndStudent%rowtype;

    vCustomers                  TCustomers;
    aBOP_SEQ                    integer;
    vSqlMsg                     varchar2(4000);
    aSCH_BILL_HEADER_ID         number;
    aSCH_BILL_POSITION_ID       number;
    vIndex                      integer;
    vSCH_PREBILL_GLOBAL_PROC    varchar2(255);
    vSCH_PREBILL_DET_AFTER_PROC varchar2(255);
    vProcResult                 integer        := 1;
  begin
    -- initialisation des tables mémoires utilisées
    aTabBillPositionRec          := TabBillPositionRec();
    -- Génération des factures.
    -- initialisation de l'indication du résultat
    aSuccessfulCount             := 0;
    aTotalCount                  := 0;

    -- Suppression des erreurs éventuellement persistantes
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'BILLING_ECOLAGE_ERRORS';

    -- Récupération des procédures stockées
    vSCH_PREBILL_GLOBAL_PROC     := PCS.PC_CONFIG.GetConfig('SCH_ECO_PREBILL_GLOBAL_PROC');
    vSCH_PREBILL_DET_AFTER_PROC  := PCS.PC_CONFIG.GetConfig('SCH_ECO_PREBILL_DET_AFTER_PROC');

    -- Execution de la procédure stockée globale
    if vSCH_PREBILL_GLOBAL_PROC is not null then
      begin
        execute immediate 'begin :Result :=  ' || vSCH_PREBILL_GLOBAL_PROC || '; end;'
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

    if vSqlMsg is not null then
      -- Génération d'une erreur pour affichage
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_DESCRIPTION
                 , LID_CODE
                  )
           values (GetNewId
                 , vSqlMsg
                 , 'BILLING_ECOLAGE_ERRORS'
                  );
    else
      -- Préparation des écolages à facturer pour chacune des périodes
      for tplSchGroupYearPeriod in crSchGroupYearPeriod loop
        -- Mise à jour des âges des élèves en début de période
        UpdateStudentAge(tplSchGroupYearPeriod.SCH_YEAR_PERIOD_ID);
        -- Calcul des écolages
        PrepareEcolagePositionTable(aPAC_PAYMENT_CONDITION_ID
                                  , aC_GROUPING_MODE
                                  , aDMT_DATE_VALUE
                                  , aDOC_GAUGE_ID
                                  , tplSchGroupYearPeriod.SCH_YEAR_PERIOD_ID
                                  , aSCH_GROUP_YEAR_PERIOD_ID
                                  , aDicCustomerTypeId
                                   );

        -- Application des remises si des lignes de factures ont été générées
        if aTabBillPositionRec.count > 0 then
          ApplyDiscount(aSCH_GROUP_YEAR_PERIOD_ID
                      , tplSchGroupYearPeriod.SCH_YEAR_PERIOD_ID
                      , aDMT_DATE_VALUE
                      , aDOC_GAUGE_ID
                      , aC_GROUPING_MODE
                      , aPAC_PAYMENT_CONDITION_ID
                       );
        end if;
      end loop;

      -- Un document par débiteur
      if aC_GROUPING_MODE = '0' then
        open crProcessByCustomer;

        fetch crProcessByCustomer
        bulk collect into vCustomers;
      -- Un document par débiteur et par élève
      else
        open crProcessByCustAndStudent;

        fetch crProcessByCustAndStudent
        bulk collect into vCustomers;
      end if;

      -- Pour chaque tuple de regroupement sélectionné, génération d'une facture
      if vCustomers.count > 0 then
        for vIndex in vCustomers.first .. vCustomers.last loop
          vSqlMsg      := null;
          aTotalCount  := aTotalCount + 1;
          savepoint SP_BeforeGenerate;

          begin
            -- Génération de l'entête du document
            aSCH_BILL_HEADER_ID  := null;
            aSCH_BILL_HEADER_ID  :=
              SCH_BILLING_FUNCTIONS.InsertBillHeader(1
                                                   , vCustomers(vIndex).aSCH_STUDENT_ID
                                                   , vCustomers(vIndex).aSTU_ACCOUNT_NUMBER
                                                   , vCustomers(vIndex).aPAC_CUSTOM_PARTNER_ID
                                                   , vCustomers(vIndex).aACS_VAT_DET_ACCOUNT_ID
                                                   , vCustomers(vIndex).aACS_FIN_ACC_S_PAYMENT_ID
                                                   , vCustomers(vIndex).aDIC_TYPE_SUBMISSION_ID
                                                   , vCustomers(vIndex).aACS_FINANCIAL_CURRENCY_ID
                                                   , aDOC_GAUGE_ID
                                                   , aSCH_GROUP_YEAR_PERIOD_ID
                                                   , vCustomers(vIndex).aSTU_ECO_OTHER_ADDRESS
                                                   , vCustomers(vIndex).aPER_KEY1
                                                   , aC_GROUPING_MODE
                                                   , vCustomers(vIndex).aPAC_PAYMENT_CONDITION_ID
                                                   , iDateDocument
                                                   , aDMT_DATE_VALUE
                                                    );
            aBOP_SEQ             := aSEQInterval;

            -- Sélection des écolages correspondants
            if aGroupPeriodAmount = 0 then
              for tplAllEcolage in crAllEcolage(vCustomers(vIndex).aPAC_CUSTOM_PARTNER_ID, vCustomers(vIndex).aSCH_STUDENT_ID) loop
                -- Génération des positions
                aSCH_BILL_POSITION_ID  := null;
                aSCH_BILL_POSITION_ID  :=
                  SCH_BILLING_FUNCTIONS.InsertBillPosition(aSCH_BILL_HEADER_ID
                                                         , tplAllEcolage.aSCH_STUDENT_ID
                                                         , tplAllEcolage.aSCH_ECOLAGE_ID
                                                         , tplAllEcolage.aSCH_ECOLAGE_CATEGORY_ID
                                                         , tplAllEcolage.aSCH_DISCOUNT_ID
                                                         , null
                                                         , null
                                                         , tplAllEcolage.aSCH_YEAR_PERIOD_ID
                                                         , tplAllEcolage.aPAC_CUSTOM_PARTNER_ID
                                                         , aDOC_GAUGE_ID
                                                         , tplAllEcolage.aGCO_GOOD_ID
                                                         , tplAllEcolage.aBOP_MAJOR_REFERENCE
                                                         , tplAllEcolage.aBOP_SECONDARY_REFERENCE
                                                         , tplAllEcolage.aBOP_DESCRIPTION
                                                         , tplAllEcolage.aBOP_CATEGORY_DESCR
                                                         , tplAllEcolage.aBOP_SHORT_DESCR
                                                         , tplAllEcolage.aBOP_LONG_DESCR
                                                         , tplAllEcolage.aBOP_FREE_DESCR
                                                         , tplAllEcolage.aSTU_ACCOUNT_NUMBER
                                                         , 0
                                                         , 0
                                                         , tplAllEcolage.aBOP_TTC_AMOUNT
                                                         , tplAllEcolage.aBOP_TTC_UNIT_AMOUNT
                                                         , 1   -- Quantité
                                                         , vCustomers(vIndex).aDIC_TYPE_SUBMISSION_ID
                                                         , vCustomers(vIndex).aACS_VAT_DET_ACCOUNT_ID
                                                         , aDMT_DATE_VALUE
                                                         , aBOP_SEQ
                                                         , null
                                                          );
                aBOP_SEQ               := aBOP_SEQ + aSEQInterval;
              end loop;
            else
              for tplAllEcolage in crAllEcolageGrouped(vCustomers(vIndex).aPAC_CUSTOM_PARTNER_ID, vCustomers(vIndex).aSCH_STUDENT_ID) loop
                -- Génération des positions
                aSCH_BILL_POSITION_ID  := null;
                aSCH_BILL_POSITION_ID  :=
                  SCH_BILLING_FUNCTIONS.InsertBillPosition(aSCH_BILL_HEADER_ID
                                                         , tplAllEcolage.aSCH_STUDENT_ID
                                                         , tplAllEcolage.aSCH_ECOLAGE_ID
                                                         , tplAllEcolage.aSCH_ECOLAGE_CATEGORY_ID
                                                         , tplAllEcolage.aSCH_DISCOUNT_ID
                                                         , null
                                                         , null
                                                         , tplAllEcolage.aSCH_YEAR_PERIOD_ID
                                                         , tplAllEcolage.aPAC_CUSTOM_PARTNER_ID
                                                         , aDOC_GAUGE_ID
                                                         , tplAllEcolage.aGCO_GOOD_ID
                                                         , tplAllEcolage.aBOP_MAJOR_REFERENCE
                                                         , tplAllEcolage.aBOP_SECONDARY_REFERENCE
                                                         , tplAllEcolage.aBOP_DESCRIPTION
                                                         , tplAllEcolage.aBOP_CATEGORY_DESCR
                                                         , tplAllEcolage.aBOP_SHORT_DESCR
                                                         , tplAllEcolage.aBOP_LONG_DESCR
                                                         , tplAllEcolage.aBOP_FREE_DESCR
                                                         , tplAllEcolage.aSTU_ACCOUNT_NUMBER
                                                         , 0
                                                         , 0
                                                         , tplAllEcolage.aBOP_TTC_AMOUNT
                                                         , tplAllEcolage.aBOP_TTC_UNIT_AMOUNT
                                                         , 1   -- Quantité
                                                         , vCustomers(vIndex).aDIC_TYPE_SUBMISSION_ID
                                                         , vCustomers(vIndex).aACS_VAT_DET_ACCOUNT_ID
                                                         , aDMT_DATE_VALUE
                                                         , aBOP_SEQ
                                                         , null
                                                          );
                aBOP_SEQ               := aBOP_SEQ + aSEQInterval;
              end loop;
            end if;
          exception
            when others then
              vSqlMsg  :=
                PCS.PC_FUNCTIONS.TranslateWord('Erreur lors de la génération de la facture : ') ||
                chr(13) ||
                '(' ||
                PCS.PC_FUNCTIONS.TranslateWord('Elève : ') ||
                vCustomers(vIndex).aSCH_STUDENT_ID ||
                PCS.PC_FUNCTIONS.TranslateWord('Débiteur : ') ||
                vCustomers(vIndex).aPAC_CUSTOM_PARTNER_ID ||
                PCS.PC_FUNCTIONS.TranslateWord(')') ||
                chr(13) ||
                'détail : ' ||
                DBMS_UTILITY.FORMAT_ERROR_STACK ||
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
          end;

          -- Annulation du traitement de génération de la facture en cours s'il y a eu le moindre problème
          if vSqlMsg is not null then
            rollback to savepoint SP_BeforeGenerate;

            -- Génération d'une erreur pour affichage
            insert into COM_LIST_ID_TEMP
                        (COM_LIST_ID_TEMP_ID
                       , LID_DESCRIPTION
                       , LID_CODE
                        )
                 values (GetNewId
                       , vSqlMsg
                       , 'BILLING_ECOLAGE_ERRORS'
                        );
          else
            begin
              -- Execution de la procédure stockée de post-traitement
              if vSCH_PREBILL_DET_AFTER_PROC is not null then
                execute immediate 'begin :Result :=  ' || vSCH_PREBILL_DET_AFTER_PROC || '(:SCH_BILL_HEADER_ID); end;'
                            using out vProcResult, in aSCH_BILL_HEADER_ID;

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

          -- Insertions d'éventuels messages d'erreur dans la table
          if vSqlMsg is not null then
            rollback to savepoint SP_BeforeGenerate;

            -- Génération d'une erreur pour affichage
            insert into COM_LIST_ID_TEMP
                        (COM_LIST_ID_TEMP_ID
                       , LID_DESCRIPTION
                       , LID_CODE
                        )
                 values (GetNewId
                       , vSqlMsg
                       , 'BILLING_ECOLAGE_ERRORS'
                        );
          else
            aSuccessfulCount  := aSuccessfulCount + 1;
          end if;
        end loop;
      end if;

      -- Un document par débiteur
      if aC_GROUPING_MODE = '0' then
        close crProcessByCustomer;
      -- Un document par débiteur et par élève
      else
        close crProcessByCustAndStudent;
      end if;
    end if;
  end ProcessEcolageBilling;

  /**
  * Function BuildStudentSelectionQuery
  * Description : Construction de la requête des élèves concernés par une catégorie
  *               d'écolage donnée.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_ECOLAGE_CATEGORY_ID : Catégorie d'écolage
  * @param   aSCH_YEAR_PERIOD_ID : Période
  */
  function BuildStudentSelectionQuery(aSCH_ECOLAGE_CATEGORY_ID number, aSCH_YEAR_PERIOD_ID number, aSCH_DISCOUNT_ID number default null)
    return varchar2
  is
    -- Curseur sur les groupes de dépendances
    cursor crSchGroupDependency
    is
      select   SGD.SCH_GROUP_DEPENDENCY_ID
             , SD.SCH_DEPENDENCY_ID
             , SFD.SCH_FREE_DEPENDENCY_ID
             , SFD.SCH_FREE_CHARACT_TYPE_ID
             , SD.C_GUARANTEE_AMOUNT_VAL
             , SD.C_SCOLARSHIP_AMOUNT_VAL
             , SD.SCH_EDUCATION_DEGREE_ID
             , SD.SCH_STUDENT_STATUS_ID
             , SD.DEP_STATUS
             , SD.DEP_EDUCATION_DEGREE
             , SD.DEP_NEW_TERM_AGE
             , SD.DEP_NEW_YEAR_AGE
             , SD.DEP_SCHOOL_YEAR
             , SD.DEP_REGISTRATION_BILLED
             , SD.DEP_REGISTRATION_PAID
             , SD.DEP_GUARANTEE_BILLED
             , SD.DEP_GUARANTEE_PAID
             , SD.DEP_DISCOUNT_RELATION
             , SD.DEP_TEACHER_CHILD
             , SD.DEP_SCOLARSHIP_AMOUNT
             , SD.DEP_GUARANTEE_AMOUNT
             , SD.DEP_MIN_YEAR_VAL
             , SD.DEP_MAX_YEAR_VAL
             , SD.DEP_MIN_SCHOOL_YEAR_VAL
             , SD.DEP_MAX_SCHOOL_YEAR_VAL
             , SD.DEP_REGISTRATION_BILLED_VAL
             , SD.DEP_REGISTRATION_PAID_VAL
             , SD.DEP_GUARANTEE_BILLED_VAL
             , SD.DEP_GUARANTEE_PAID_VAL
             , SD.DEP_DISCOUNT_RELATION_VAL
             , SD.DEP_TEACHER_CHILD_VAL
             , SD.C_SCOLARSHIP_RATE_VAL
             , SD.DEP_PRORATE_PAYMENT
             , SD.DEP_SCOLARSHIP_RATE
             , SD.DEP_PRORATE_PAYMENT_VAL
             , SFD.C_NUMERIC_VAL
             , nvl(SFD.FRD_BOOLEAN_VAL, 0) FRD_BOOLEAN_VAL
             , SFCT.C_FREE_CHARACT_DATA_TYPE
          from SCH_GROUP_DEPENDENCY SGD
             , SCH_DEPENDENCY SD
             , SCH_FREE_DEPENDENCY SFD
             , SCH_FREE_CHARACT_TYPE SFCT
         where (    (    nvl(aSCH_ECOLAGE_CATEGORY_ID, 0) <> 0
                     and SGD.SCH_ECOLAGE_CATEGORY_ID = aSCH_ECOLAGE_CATEGORY_ID)
                or (    nvl(aSCH_DISCOUNT_ID, 0) <> 0
                    and SGD.SCH_DISCOUNT_ID = aSCH_DISCOUNT_ID)
               )
           and SGD.SCH_GROUP_DEPENDENCY_ID = SD.SCH_GROUP_DEPENDENCY_ID(+)
           and SGD.SCH_GROUP_DEPENDENCY_ID = SFD.SCH_GROUP_DEPENDENCY_ID(+)
           and SFD.SCH_FREE_CHARACT_TYPE_ID = SFCT.SCH_FREE_CHARACT_TYPE_ID(+)
      order by SGD.SCH_GROUP_DEPENDENCY_ID;

    -- Variables
    vSQLQuerySelect          varchar2(1000);
    vSQLQueryWhere           varchar2(31000);
    Save_Group_Dependency_Id number;
  begin
    if nvl(aSCH_DISCOUNT_ID, 0) = 0 then
      -- initialisation de la requête (les champs vont être insérés dans un record de type, d'ou la présence des nulls)
      vSQLQuerySelect  :=
        ' select distinct ' ||
        '        STU.SCH_STUDENT_ID ' ||
        '      , STU.STU_ACCOUNT_NUMBER ' ||
        '      , STU.STU_PRORATE_PAYMENT' ||
        '      , STU.STU_ECO_OTHER_ADDRESS' ||
        '      , STU.STU_ECO_MIXED_BILLING' ||
        '      , null, null, null, null, null, null, null, null, null, null'   -- null * 10
                                                                            ||
        '      , null, null, null, null, null, null, null, null, null, null'   -- null * 10
                                                                            ||
        '      , null, null, null, null, null, null, null'   -- null * 7
                                                          ||
        '      , PAC_CUSTOM_PARTNER1_ID ' ||
        '   from SCH_STUDENT STU ' ||
        '      , COM_LIST_ID_TEMP LID ' ||
        '  where LID.COM_LIST_ID_TEMP_ID = STU.SCH_STUDENT_ID ' ||
        '    and LID.LID_CODE = ''SCH_STUDENT_ID'' ' ||
        '    and SCH_ECOLAGE_BILLING.StudentToBill(STU.SCH_STUDENT_ID, ' ||
        aSCH_YEAR_PERIOD_ID ||
        ' ) = 1 ' ||
        '    and SCH_ECOLAGE_BILLING.PositionExists( ' ||
        aSCH_YEAR_PERIOD_ID ||
        '                                          , ' ||
        aSCH_ECOLAGE_CATEGORY_ID ||
        '                                          , STU.SCH_STUDENT_ID) = 0 ';
    -- requête particulière à l'application des remises
    else
      vSQLQuerySelect  :=
        ' select distinct ' ||
        '        STU.SCH_STUDENT_ID ' ||
        '   from SCH_STUDENT STU ' ||
        '      , COM_LIST_ID_TEMP LID ' ||
        '  where LID.COM_LIST_ID_TEMP_ID = STU.SCH_STUDENT_ID ' ||
        '    and LID.LID_CODE = ''SCH_STUDENT_ID'' ' ||
        '    and SCH_ECOLAGE_BILLING.StudentToBill(STU.SCH_STUDENT_ID, ' ||
        aSCH_YEAR_PERIOD_ID ||
        ' ) = 1 ' ||
        '    and SCH_ECOLAGE_BILLING.PositionExists( ' ||
        aSCH_YEAR_PERIOD_ID ||
        '                                          , null' ||
        '                                          , STU.SCH_STUDENT_ID ' ||
        '                                          , ' ||
        aSCH_DISCOUNT_ID ||
        ') = 0 ';
    end if;

    Save_Group_Dependency_Id  := 0;

    -- Parcours des dépendances
    for tplSchGroupDependency in crSchGroupDependency loop
      -- Premier groupe ou groupe OR
      if Save_Group_Dependency_Id = 0 then
        vSQLQueryWhere  := vSQLQueryWhere || 'and ((STU.SCH_STUDENT_ID is not null';
      elsif Save_Group_Dependency_Id <> tplSchGroupDependency.SCH_GROUP_DEPENDENCY_ID then
        vSQLQueryWhere  := vSQLQueryWhere || ' ) OR (STU.SCH_STUDENT_ID is not null';
      end if;

      -- Dépendances sur champs fixes
      if     tplSchGroupDependency.SCH_DEPENDENCY_ID is not null
         and Save_Group_Dependency_Id <> tplSchGroupDependency.SCH_GROUP_DEPENDENCY_ID then
        -- Statut de l'élève
        if tplSchGroupDependency.DEP_STATUS = 1 then
          vSQLQueryWhere  := vSQLQueryWhere || ' AND STU.SCH_STUDENT_STATUS_ID = ' || tplSchGroupDependency.SCH_STUDENT_STATUS_ID;
        end if;

        -- Degré d'enseignement
        if tplSchGroupDependency.DEP_EDUCATION_DEGREE = 1 then
          vSQLQueryWhere  := vSQLQueryWhere || ' AND STU.SCH_EDUCATION_DEGREE_ID = ' || tplSchGroupDependency.SCH_EDUCATION_DEGREE_ID;
        end if;

        -- Année de scolarité
        if tplSchGroupDependency.DEP_SCHOOL_YEAR = 1 then
          vSQLQueryWhere  :=
            vSQLQueryWhere ||
            ' AND STU.STU_SCHOOL_YEAR > ' ||
            tplSchGroupDependency.DEP_MIN_SCHOOL_YEAR_VAL ||
            ' AND STU.STU_SCHOOL_YEAR < ' ||
            tplSchGroupDependency.DEP_MAX_SCHOOL_YEAR_VAL;
        end if;

        -- Inscription facturée
        if tplSchGroupDependency.DEP_REGISTRATION_BILLED = 1 then
          vSQLQueryWhere  := vSQLQueryWhere || ' AND STU.STU_REGISTRATION_BILLED = ' || tplSchGroupDependency.DEP_REGISTRATION_BILLED_VAL;
        end if;

        -- Inscription payée
        if tplSchGroupDependency.DEP_REGISTRATION_PAID = 1 then
          vSQLQueryWhere  := vSQLQueryWhere || ' AND STU.STU_REGISTRATION_PAID = ' || tplSchGroupDependency.DEP_REGISTRATION_PAID_VAL;
        end if;

        -- Dépot de garantie facturé
        if tplSchGroupDependency.DEP_GUARANTEE_BILLED = 1 then
          vSQLQueryWhere  := vSQLQueryWhere || ' AND STU.STU_GUARANTEE_BILLED = ' || tplSchGroupDependency.DEP_GUARANTEE_BILLED_VAL;
        end if;

        -- Dépot de garantie payé
        if tplSchGroupDependency.DEP_GUARANTEE_PAID = 1 then
          vSQLQueryWhere  := vSQLQueryWhere || ' AND STU.STU_GUARANTEE_PAID = ' || tplSchGroupDependency.DEP_GUARANTEE_PAID_VAL;
        end if;

        -- Réduction famille
        if tplSchGroupDependency.DEP_DISCOUNT_RELATION = 1 then
          vSQLQueryWhere  := vSQLQueryWhere || ' AND STU.STU_DISCOUNT_RELATION = ' || tplSchGroupDependency.DEP_DISCOUNT_RELATION_VAL;
        end if;

        -- Enfant d'employé
        if tplSchGroupDependency.DEP_TEACHER_CHILD = 1 then
          vSQLQueryWhere  := vSQLQueryWhere || ' AND STU.STU_TEACHER_CHILD = ' || tplSchGroupDependency.DEP_TEACHER_CHILD_VAL;
        end if;

        -- Montant de la bourse
        if tplSchGroupDependency.DEP_SCOLARSHIP_AMOUNT = 1 then
          -- Montant null
          if tplSchGroupDependency.C_SCOLARSHIP_AMOUNT_VAL = 0 then
            vSQLQueryWhere  := vSQLQueryWhere || ' AND NVL(STU.STU_SCOLARSHIP_AMOUNT, 0) = 0';
          -- Montant non null
          else
            vSQLQueryWhere  := vSQLQueryWhere || ' AND NVL(STU.STU_SCOLARSHIP_AMOUNT, 0) <> 0';
          end if;
        end if;

        -- Taux de la bourse
        if tplSchGroupDependency.DEP_SCOLARSHIP_RATE = 1 then
          -- Taux null
          if tplSchGroupDependency.C_SCOLARSHIP_RATE_VAL = 0 then
            vSQLQueryWhere  := vSQLQueryWhere || ' AND NVL(STU.STU_SCOLARSHIP_RATE, 0) = 0';
          -- Taux non null
          else
            vSQLQueryWhere  := vSQLQueryWhere || ' AND NVL(STU.STU_SCOLARSHIP_RATE, 0) <> 0';
          end if;
        end if;

        -- Montant de la garantie
        if tplSchGroupDependency.DEP_GUARANTEE_AMOUNT = 1 then
          -- Montant null
          if tplSchGroupDependency.C_GUARANTEE_AMOUNT_VAL = 0 then
            vSQLQueryWhere  := vSQLQueryWhere || ' AND NVL(STU.STU_GUARANTEE_AMOUNT, 0) = 0';
          -- Montant non null
          else
            vSQLQueryWhere  := vSQLQueryWhere || ' AND NVL(STU.STU_GUARANTEE_AMOUNT, 0) <> 0';
          end if;
        end if;

        -- Paiement au prorata
        if tplSchGroupDependency.DEP_PRORATE_PAYMENT = 1 then
          vSQLQueryWhere  := vSQLQueryWhere || ' AND STU.STU_PRORATE_PAYMENT = ' || tplSchGroupDependency.DEP_PRORATE_PAYMENT_VAL;
        end if;

        -- Age au début de la période
        if tplSchGroupDependency.DEP_NEW_TERM_AGE = 1 then
          vSQLQueryWhere  :=
            vSQLQueryWhere ||
            ' AND STU.STU_BEGIN_TERM_AGE >= ' ||
            tplSchGroupDependency.DEP_MIN_YEAR_VAL ||
            ' AND STU.STU_BEGIN_TERM_AGE <= ' ||
            tplSchGroupDependency.DEP_MAX_YEAR_VAL;
        end if;

        -- Age au début de l'année scolaire
        if tplSchGroupDependency.DEP_NEW_YEAR_AGE = 1 then
          vSQLQueryWhere  :=
            vSQLQueryWhere ||
            ' AND STU.STU_BEGIN_YEAR_AGE >= ' ||
            tplSchGroupDependency.DEP_MIN_YEAR_VAL ||
            ' AND STU.STU_BEGIN_YEAR_AGE <= ' ||
            tplSchGroupDependency.DEP_MAX_YEAR_VAL;
        end if;
      end if;

      -- Traitement des caractéristiques libres
      if     tplSchGroupDependency.SCH_FREE_DEPENDENCY_ID is not null
         and tplSchGroupDependency.SCH_FREE_CHARACT_TYPE_ID is not null then
        vSQLQueryWhere  :=
          vSQLQueryWhere ||
          ' and exists (select 1 ' ||
          '               from SCH_FREE_CHARACTERISTIC SFC  ' ||
          '              where SFC.SCH_STUDENT_ID = STU.SCH_STUDENT_ID ' ||
          '                and SFC.SCH_FREE_CHARACT_TYPE_ID = ' ||
          tplSchGroupDependency.SCH_FREE_CHARACT_TYPE_ID;

        -- Caractéristique booléenne
        if tplSchGroupDependency.C_FREE_CHARACT_DATA_TYPE = 0 then
          vSQLQueryWhere  := vSQLQueryWhere || '                and SFC.FRC_BOOLEAN_VAL =' || tplSchGroupDependency.FRD_BOOLEAN_VAL;
        -- Caractéristique numérique
        else
          vSQLQueryWhere  :=
            vSQLQueryWhere ||
            '                and ((' ||
            nvl(tplSchGroupDependency.C_NUMERIC_VAL, 0) ||
            ' =  0  and NVL(SFC.FRC_NUMERIC_VAL, 0) = 0)' ||
            '                        or (' ||
            nvl(tplSchGroupDependency.C_NUMERIC_VAL, 0) ||
            ' = 1  and NVL(SFC.FRC_NUMERIC_VAL, 0) <> 0))';
        end if;

        vSQLQueryWhere  := vSQLQueryWhere || ')';
      end if;

      Save_Group_Dependency_Id  := tplSchGroupDependency.SCH_GROUP_DEPENDENCY_ID;
    end loop;

    -- Au moins un critère a été trouvé
    if Save_Group_Dependency_Id <> 0 then
      vSQLQueryWhere  := vSQLQueryWhere || '))';
    end if;

    return vSQLQuerySelect || vSQLQueryWhere;
  exception
    when no_data_found then
      return '';
    when others then
      begin
        raise;
        return '';
      end;
  end BuildStudentSelectionQuery;

  /**
  * procedure SetSessionToNull
  * Description : Mise à null du champs session oracle des factures d'écolage
  *               qui indique les factures en cours de génération
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aHEA_ORACLE_SESSION : Session oracle
  */
  procedure SetSessionToNull(aHEA_ORACLE_SESSION varchar2)
  is
  begin
    update SCH_BILL_HEADER
       set HEA_ORACLE_SESSION = null
     where HEA_ORACLE_SESSION = aHEA_ORACLE_SESSION;
  end SetSessionToNull;

  /**
  * function PositionExists
  * Description : Recherche de l'existance d'une position dans une facture, pour
  *               une période donnée
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_YEAR_PERIOD_ID : période
  * @param   aSCH_ECOLAGE_CATEGORY_ID : Catégorie d'écolage
  * @param   aSCH_STUDENT_ID : Elève
  */
  function PositionExists(aSCH_YEAR_PERIOD_ID number, aSCH_ECOLAGE_CATEGORY_ID number, aSCH_STUDENT_ID number, aSCH_DISCOUNT_ID number default null)
    return integer
  is
    result integer := 0;
  begin
    select count(*)
      into result
      from SCH_BILL_POSITION BOP
         , SCH_BILL_HEADER HEA
         , SCH_PERIOD_GRP_PERIOD_LINK LNK
     where BOP.SCH_STUDENT_ID = aSCH_STUDENT_ID
       and (    (    nvl(aSCH_DISCOUNT_ID, 0) = 0
                 and BOP.SCH_ECOLAGE_CATEGORY_ID = aSCH_ECOLAGE_CATEGORY_ID)
            or (    nvl(aSCH_DISCOUNT_ID, 0) <> 0
                and BOP.SCH_DISCOUNT_ID = aSCH_DISCOUNT_ID)
           )
       and BOP.SCH_BILL_HEADER_ID = HEA.SCH_BILL_HEADER_ID
       and HEA.SCH_GROUP_YEAR_PERIOD_ID = LNK.SCH_GROUP_YEAR_PERIOD_ID
       and LNK.SCH_YEAR_PERIOD_ID = aSCH_YEAR_PERIOD_ID;

    return result;
  exception
    when others then
      return 0;
  end PositionExists;

  /**
  * procedure SelectEcolageBill
  * Description : Sélection des factures encore à générer en logistique en tenant compte des filtres
  *               de présélections sur les périodes, débiteurs, et élèves.
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure SelectEcolageBill
  is
  begin
    SCH_BILLING_FUNCTIONS.SelectBill(1);
  end SelectEcolageBill;

  /**
  * procedure AffectCustomer
  * Description : Affectation des positions sans débiteur nommé
  *               Insertion dans une facture existante ou génération d'une nouvelle facture
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSrcBillHeaderID   : Entête facture source
  * @param   aSrcBillPositionId : Position à déplacer
  * @param   aCustomerToAffect  : Client à affecter à la position
  *
  */
  procedure AffectCustomer(aSrcBillHeaderID in number, aSrcBillPositionId in number, aCustomerToAffect in number)
  is
    -- Info document source
    cursor CrSrcBillHeader
    is
      select HEA.SCH_STUDENT_ID
           , HEA.SCH_GROUP_YEAR_PERIOD_ID
           , HEA.DOC_GAUGE_ID
           , STU.STU_ACCOUNT_NUMBER
           , nvl(STU.STU_ECO_OTHER_ADDRESS, 0) STU_ECO_OTHER_ADDRESS
           , BOP.BOP_TTC_AMOUNT
           , nvl(CAT.GCO_GOOD_ID, DIS.GCO_GOOD_ID) GCO_GOOD_ID
           , HEA.PAC_PAYMENT_CONDITION_ID
           , HEA.C_GROUPING_MODE
        from SCH_BILL_HEADER HEA
           , SCH_BILL_POSITION BOP
           , SCH_STUDENT STU
           , SCH_ECOLAGE_CATEGORY CAT
           , SCH_DISCOUNT DIS
       where HEA.SCH_BILL_HEADER_ID = aSrcBillHeaderID
         and BOP.SCH_BILL_POSITION_ID = aSrcBillPositionId
         and HEA.SCH_BILL_HEADER_ID = BOP.SCH_BILL_HEADER_ID
         and BOP.SCH_STUDENT_ID = STU.SCH_STUDENT_ID
         and BOP.SCH_ECOLAGE_CATEGORY_ID = CAT.SCH_ECOLAGE_CATEGORY_ID(+)
         and BOP.SCH_DISCOUNT_ID = DIS.SCH_DISCOUNT_ID(+);

    -- info débiteur destination
    cursor crCustomerDest
    is
      select PAC.ACS_VAT_DET_ACCOUNT_ID
           , PAC.ACS_FIN_ACC_S_PAYMENT_ID
           , PAC.DIC_TYPE_SUBMISSION_ID
           , PER.PER_KEY1
           , PAC.PAC_PAYMENT_CONDITION_ID
        from PAC_CUSTOM_PARTNER PAC
           , PAC_PERSON PER
       where PAC.PAC_CUSTOM_PARTNER_ID = aCustomerToAffect
         and PAC.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID;

    tplSrcBillHeader crSrcBillHeader%rowtype;
    tplCustomerDest  crCustomerDest%rowtype;
    aDestBillHeader  number;
  begin
    -- Recherche info facture source
    open crSrcBillHeader;

    fetch crSrcBillHeader
     into tplSrcBillHeader;

    if crSrcBillHeader%found then
      -- Recherche existance facture destination non validée
      begin
        select max(SCH_BILL_HEADER_ID)
          into aDestBillHeader
          from SCH_BILL_HEADER
         where PAC_CUSTOM_PARTNER_ID = aCustomerToAffect
           and (    (    tplSrcBillHeader.C_GROUPING_MODE = 1
                     and SCH_STUDENT_ID = tplSrcBillHeader.SCH_STUDENT_ID)
                or (    tplSrcBillHeader.C_GROUPING_MODE = 0
                    and C_GROUPING_MODE = 0)
               )
           and DOC_DOCUMENT_ID is null
           and SCH_GROUP_YEAR_PERIOD_ID = tplSrcBillHeader.SCH_GROUP_YEAR_PERIOD_ID
           and DOC_GAUGE_ID = tplSrcBillHeader.DOC_GAUGE_ID
           and HEA_ECOLAGE = 1;
      exception
        when others then
          aDestBillHeader  := null;
      end;

      -- La facture existe
      if aDestBillHeader is not null then
        -- -> Déplacement de la position
        MovePosition(aSrcBillHeaderID
                   , aDestBillHeader
                   , aSrcBillPositionID
                   , tplSrcBillHeader.DOC_GAUGE_ID
                   , aCustomerToAffect
                   , tplSrcBillHeader.GCO_GOOD_ID
                   , tplSrcBillHeader.BOP_TTC_AMOUNT
                    );
      -- La facture n'existe pas
      else
        -- -> génération de la facture
        open crCustomerDest;

        fetch crCustomerDest
         into TplCustomerDest;

        if crCustomerDest%found then
          aDestBillHeader  :=
            SCH_BILLING_FUNCTIONS.InsertBillHeader(1
                                                 , tplSrcBillHeader.SCH_STUDENT_ID
                                                 , tplSrcBillHeader.STU_ACCOUNT_NUMBER
                                                 , aCustomerToAffect
                                                 , TplCustomerDest.ACS_VAT_DET_ACCOUNT_ID
                                                 , TplCustomerDest.ACS_FIN_ACC_S_PAYMENT_ID
                                                 , TplCustomerDest.DIC_TYPE_SUBMISSION_ID
                                                 , SCH_TOOLS.GetBaseMoney
                                                 , tplSrcBillHeader.DOC_GAUGE_ID
                                                 , tplSrcBillHeader.SCH_GROUP_YEAR_PERIOD_ID
                                                 , tplSrcBillHeader.STU_ECO_OTHER_ADDRESS
                                                 , TplCustomerDest.PER_KEY1
                                                 , tplSrcBillHeader.C_GROUPING_MODE
                                                 , nvl(tplSrcBillHeader.PAC_PAYMENT_CONDITION_ID, TplCustomerDest.PAC_PAYMENT_CONDITION_ID)
                                                  );

          -- -> déplacement de la position
          if aDestBillHeader is not null then
            MovePosition(aSrcBillHeaderID
                       , aDestBillHeader
                       , aSrcBillPositionID
                       , tplSrcBillHeader.DOC_GAUGE_ID
                       , aCustomerToAffect
                       , tplSrcBillHeader.GCO_GOOD_ID
                       , tplSrcBillHeader.BOP_TTC_AMOUNT
                        );
          end if;
        end if;

        close crCustomerDest;
      end if;

      -- Suppression de la facture source si elle ne possède plus de position
      delete from SCH_BILL_HEADER
            where SCH_BILL_HEADER_ID = aSrcBillHeaderID
              and not exists(select 1
                               from SCH_BILL_POSITION
                              where SCH_BILL_HEADER_ID = aSrcBillHeaderID);
    end if;

    close crSrcBillHeader;
  end AffectCustomer;

  /**
  * function StudentToBill
  * Description : Elève à facturer
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   aSCH_STUDENT_ID : Elève
  * @param   aSCH_YEAR_PERIOD_ID : période de facturation
  * @param   aSCH_YEAR_GROUP_PERIOD_ID : groupe de périodes de facturation
  * @return  1 / 0
  */
  function StudentToBill(aSCH_STUDENT_ID number, aSCH_YEAR_PERIOD_ID number, aSCH_GROUP_YEAR_PERIOD_ID number default null)
    return integer
  is
    cursor crGroupPeriod
    is
      select SCH_YEAR_PERIOD_ID
        from SCH_PERIOD_GRP_PERIOD_LINK LNK
       where SCH_GROUP_YEAR_PERIOD_ID = aSCH_GROUP_YEAR_PERIOD_ID;

    aResult integer;
  begin
    aresult  := 0;

    if nvl(aSCH_GROUP_YEAR_PERIOD_ID, 0) = 0 then
      select 1
        into aResult
        from SCH_STUDENT STU
           , SCH_YEAR_PERIOD PER_BEGIN
           , SCH_YEAR_PERIOD PER_END
           , SCH_YEAR_PERIOD BILLED_PERIOD
       where STU.SCH_STUDENT_ID = aSCH_STUDENT_ID
         and BILLED_PERIOD.SCH_YEAR_PERIOD_ID = aSCH_YEAR_PERIOD_ID
         and STU.SCH_YEAR_PERIOD1_ID = PER_BEGIN.SCH_YEAR_PERIOD_ID(+)
         and STU.SCH_YEAR_PERIOD2_ID = PER_END.SCH_YEAR_PERIOD_ID(+)
         and (   STU.SCH_YEAR_PERIOD1_ID is not null
              or STU.SCH_YEAR_PERIOD2_ID is not null)
         and (   STU.SCH_YEAR_PERIOD1_ID is null
              or (    STU.SCH_YEAR_PERIOD1_ID is not null
                  and PER_BEGIN.PER_BEGIN_DATE <= BILLED_PERIOD.PER_END_DATE) )
         and (   STU.SCH_YEAR_PERIOD2_ID is null
              or (    STU.SCH_YEAR_PERIOD2_ID is not null
                  and PER_END.PER_END_DATE >= BILLED_PERIOD.PER_BEGIN_DATE) );
    else
      for tplGroupPeriod in crGroupPeriod loop
        begin
          select 1
            into aResult
            from SCH_STUDENT STU
               , SCH_YEAR_PERIOD PER_BEGIN
               , SCH_YEAR_PERIOD PER_END
               , SCH_YEAR_PERIOD BILLED_PERIOD
           where STU.SCH_STUDENT_ID = aSCH_STUDENT_ID
             and BILLED_PERIOD.SCH_YEAR_PERIOD_ID = tplGroupPeriod.SCH_YEAR_PERIOD_ID
             and STU.SCH_YEAR_PERIOD1_ID = PER_BEGIN.SCH_YEAR_PERIOD_ID(+)
             and STU.SCH_YEAR_PERIOD2_ID = PER_END.SCH_YEAR_PERIOD_ID(+)
             and (   STU.SCH_YEAR_PERIOD1_ID is not null
                  or STU.SCH_YEAR_PERIOD2_ID is not null)
             and (   STU.SCH_YEAR_PERIOD1_ID is null
                  or (    STU.SCH_YEAR_PERIOD1_ID is not null
                      and PER_BEGIN.PER_BEGIN_DATE <= BILLED_PERIOD.PER_END_DATE) )
             and (   STU.SCH_YEAR_PERIOD2_ID is null
                  or (    STU.SCH_YEAR_PERIOD2_ID is not null
                      and PER_END.PER_END_DATE >= BILLED_PERIOD.PER_BEGIN_DATE) );
        exception
          when others then
            aresult  := 0;
        end;

        exit when aresult = 1;
      end loop;
    end if;

    return aResult;
  exception
    when others then
      return 0;
  end;

  /**
  * function GetCaractValue
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  function GetCaractValue(iSchFreeCaractType in number, iSchStudentId in number)
    return number
  is
    vSelectFieldValue varchar2(4000);
    lnFieldValue      number;
  begin
    if iSchFreeCaractType is not null then
      vSelectFieldValue  :=
        ' select NVL(MAX(FRC_NUMERIC_VAL), 0) as FIELDVALUE' ||
        '  from SCH_FREE_CHARACTERISTIC ' ||
        ' where SCH_STUDENT_ID = :iSchStudentId' ||
        '   and SCH_FREE_CHARACT_TYPE_ID = :iSchFreeCaractType';

      execute immediate vSelectFieldValue
                   into lnFieldValue
                  using iSchStudentId, iSchFreeCaractType;

      return lnFieldValue;
    else
      return 0;
    end if;
  exception
    when others then
      return 0;
  end GetCaractValue;

  /**
  * function GetConfigValue
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  function GetConfigValue(iCfgName in varchar2)
    return number
  is
  begin
    return to_number(PCS.PC_CONFIG.GetConfig(iCfgName) );
  exception
    when others then
      return 0;
  end GetConfigValue;

  /**
  * function GetFieldValue
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  function GetFieldValue(iSchStudentId in number, iFieldName in varchar2)
    return number
  is
    vSelectFieldValue varchar2(4000);
    lnFieldValue      number;
  begin
    if iFieldName is not null then
      vSelectFieldValue  := ' select NVL(' || iFieldName || ', 0) as FIELDVALUE' || '  from SCH_STUDENT' || ' where SCH_STUDENT_ID = :iSchStudentId';

      execute immediate vSelectFieldValue
                   into lnFieldValue
                  using iSchStudentId;

      return lnFieldValue;
    else
      return 0;
    end if;
  exception
    when others then
      return 0;
  end GetFieldValue;

  /**
  * Procedure CalcDiscountAmount
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure CalcDiscountAmount(iSchDiscountId in number, iBasisAmount in number, iDiscountAmount in out number, iSchStudentId in number)
  is
    cursor crDiscount
    is
      select DIS.C_DISCOUNT_TYPE_AMOUNT
           , DIS.DIS_AMOUNT_OR_RATE
           , DIS.DIS_TTC_AMOUNT
           , DIF.FIT_NAME
           , DCT.CON_NAME
           , DIS.SCH_FREE_CHARACT_TYPE_ID
        from SCH_DISCOUNT DIS
           , SCH_DISCOUNT_FIELD_TYPE DIF
           , SCH_DISCOUNT_CONFIG_TYPE DCT
       where DIS.SCH_DISCOUNT_ID = iSchDiscountId
         and DIS.SCH_DISCOUNT_FIELD_TYPE_ID = DIF.SCH_DISCOUNT_FIELD_TYPE_ID(+)
         and DIS.SCH_DISCOUNT_CONFIG_TYPE_ID = DCT.SCH_DISCOUNT_CONFIG_TYPE_ID(+);

    lnRateOrAmount number;
  begin
    -- Recherches caractéristiques du montant
    for tplDiscount in crDiscount loop
      -- Remise sur champs
      if tplDiscount.C_DISCOUNT_TYPE_AMOUNT = '0' then
        if    tplDiscount.FIT_NAME = 'DIS_TTC_AMOUNT'
           or tplDiscount.FIT_NAME is null then
          lnRateOrAmount  := tplDiscount.DIS_TTC_AMOUNT;
        else
          lnRateOrAmount  := GetFieldValue(iSchStudentId, tplDiscount.FIT_NAME);
        end if;
      -- Remise sur configuration
      elsif tplDiscount.C_DISCOUNT_TYPE_AMOUNT = '1' then
        lnRateOrAmount  := GetConfigValue(tplDiscount.CON_NAME);
      -- Remise sur Caractéristique libre
      elsif tplDiscount.C_DISCOUNT_TYPE_AMOUNT = '2' then
        lnRateOrAmount  := GetCaractValue(tplDiscount.SCH_FREE_CHARACT_TYPE_ID, iSchStudentId);
      end if;

      -- Remise de type taux
      if tplDiscount.DIS_AMOUNT_OR_RATE = 1 then
        iDiscountAmount  := -1 *(iBasisAmount * lnRateOrAmount / 100);
      -- Remise de type montant
      else
        iDiscountAmount  := -1 *(lnRateOrAmount);
      end if;

      exit;
    end loop;
  end CalcDiscountAmount;

  /**
  * Procedure ApplyDiscount
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSCH_GROUP_YEAR_PERIOD_ID : Groupe de périodes
  * @param   iDMT_DATE_VALUE : Date valeur
  * @param   iDOC_GAUGE_ID : Gabarit
  * @param   iC_GROUPING_MODE : MOde de regoupement
  * @param   aPAC_PAYMENT_CONDITION_ID : Condition de paiment (prioritaire)
  */
  procedure ApplyDiscount(
    iSCH_GROUP_YEAR_PERIOD_ID in number
  , iSCH_YEAR_PERIOD_ID       in number
  , iDMT_DATE_VALUE           in date
  , iDOC_GAUGE_ID             in number
  , iC_GROUPING_MODE          in varchar2
  , aPAC_PAYMENT_CONDITION_ID in number
  )
  is
    type T_STUDENT is table of number
      index by binary_integer;

    cursor crActiveDiscount
    is
      select   *
          from SCH_DISCOUNT
         where DIS_ACTIVE = 1
      order by DIS_PRIORITY_NUMBER;

    cursor crEcolageLinked(aSchDiscountId number)
    is
      select distinct ECO.*
                 from SCH_ECOLAGE_DISCOUNT_LINK SED
                    , SCH_ECOLAGE ECO
                where SED.SCH_DISCOUNT_ID = aSchDiscountId
                  and SED.SCH_ECOLAGE_ID = ECO.SCH_ECOLAGE_ID
                  and ECO.ECO_ACTIVE = 1;

    cursor crBilledEcolage(aSchEcolageId number, aSchStudentId number)
    is
      select BILLED_ECO.*
        from table(SCH_ECOLAGE_BILLING.GetEcolagePositions) BILLED_ECO
       where BILLED_ECO.aSCH_ECOLAGE_ID = aSchEcolageId
         and BILLED_ECO.aSCH_STUDENT_ID = aSchStudentId
         and BILLED_ECO.aSCH_YEAR_PERIOD_ID = iSCH_YEAR_PERIOD_ID;

    cursor crBilledPeriods
    is
      select   PER.*
          from SCH_PERIOD_GRP_PERIOD_LINK GRP
             , SCH_YEAR_PERIOD PER
         where GRP.SCH_GROUP_YEAR_PERIOD_ID = iSCH_GROUP_YEAR_PERIOD_ID
           and GRP.SCH_YEAR_PERIOD_ID = PER.SCH_YEAR_PERIOD_ID
      order by PER_BEGIN_DATE;

    cursor crTotalOfPeriod(aSchYearPeriodId number, aSchStudentId number)
    is
      select   sum(aBOP_TTC_AMOUNT) SUM_AMOUNT
             , aPAC_CUSTOM_PARTNER_ID
          from table(SCH_ECOLAGE_BILLING.GetEcolagePositions) BILLED_ECO
         where aSCH_YEAR_PERIOD_ID = aSchYearPeriodId
           and aSCH_STUDENT_ID = aSchStudentId
           and nvl(aSCH_DISCOUNT_ID, 0) = 0
      group by aPAC_CUSTOM_PARTNER_ID;

    vSQLStudentSelection      varchar2(32000);
    TStudents                 T_STUDENT;
    lnDiscountAmount          number;
    lnTotalDiscountAmount     number;
    aACS_VAT_DET_ACCOUNT_ID   number;
    aACS_FIN_ACC_S_PAYMENT_ID number;
    aDIC_TYPE_SUBMISSION_ID   varchar2(10);
    aPER_KEY1                 varchar2(20);
    iPAC_PAYMENT_CONDITION_ID number;
    aSTU_ACCOUNT_NUMBER       SCH_STUDENT.STU_ACCOUNT_NUMBER%type;
    aSTU_PRORATE_PAYMENT      SCH_STUDENT.STU_PRORATE_PAYMENT%type;
    aSTU_ECO_MIXED_BILLING    SCH_STUDENT.STU_ECO_MIXED_BILLING%type;
    aSTU_ECO_OTHER_ADDRESS    SCH_STUDENT.STU_ECO_OTHER_ADDRESS%type;
    lnPAC_CUSTOM_PARTNER_ID   number;
    lbLinkedEcolageFounded    boolean;
  begin
    -- Parcours des remises actives
    for tplDiscount in crActiveDiscount loop
      -- Construction de la requête de sélection des élèves concernés par la remise
      vSQLStudentSelection  := BuildStudentSelectionQuery(null, iSCH_YEAR_PERIOD_ID, tplDiscount.SCH_DISCOUNT_ID);

      -- Récupération des enregistrements dans une table mémoire
      execute immediate vSQLStudentSelection
      bulk collect into TStudents;

      -- Pour chaque élève concerné par la remise
      if TStudents.count > 0 then
        for i in TStudents.first .. TStudents.last loop
          -- Remise sur écolage
          if tplDiscount.DIS_ECOLAGE_DISCOUNT = 1 then
            lbLinkedEcolageFounded   := false;
            lnPAC_CUSTOM_PARTNER_ID  := 0;
            lnTotalDiscountAmount    := 0;

            -- Pour chaque écolage lié
            for tplEcolageLinked in crEcolageLinked(tplDiscount.SCH_DISCOUNT_ID) loop
              -- Pour chaque écolage facturé
              for tplBilledEcolage in crBilledEcolage(tplEcolageLinked.SCH_ECOLAGE_ID, TStudents(i) ) loop
                lnPAC_CUSTOM_PARTNER_ID  := tplBilledEcolage.aPAC_CUSTOM_PARTNER_ID;
                -- Calcul du montant à facturer
                CalcDiscountAmount(tplDiscount.SCH_DISCOUNT_ID, tplBilledEcolage.aBOP_TTC_AMOUNT, lnDiscountAmount, TStudents(i) );
                lnTotalDiscountAmount    := nvl(lnTotalDiscountAmount, 0) + lnDiscountAmount;
                lbLinkedEcolageFounded   := true;
              end loop;
            end loop;

            -- Insertion de la position correspondante dans la table temporaire
            if lbLinkedEcolageFounded then
              aTabBillPositionRec.extend;

              begin
                select STU_ACCOUNT_NUMBER
                     , STU_PRORATE_PAYMENT
                     , STU_ECO_MIXED_BILLING
                     , STU_ECO_OTHER_ADDRESS
                  into aSTU_ACCOUNT_NUMBER
                     , aSTU_PRORATE_PAYMENT
                     , aSTU_ECO_MIXED_BILLING
                     , aSTU_ECO_OTHER_ADDRESS
                  from SCH_STUDENT
                 where SCH_STUDENT_ID = TStudents(i);
              exception
                when others then
                  begin
                    aSTU_ACCOUNT_NUMBER     := null;
                    aSTU_PRORATE_PAYMENT    := null;
                    aSTU_ECO_MIXED_BILLING  := null;
                    aSTU_ECO_OTHER_ADDRESS  := null;
                  end;
              end;

              -- information de l'èlève
              aTabBillPositionRec(aTabBillPositionRec.last).aSCH_STUDENT_ID             := TStudents(i);
              aTabBillPositionRec(aTabBillPositionRec.last).aSTU_ACCOUNT_NUMBER         := aSTU_ACCOUNT_NUMBER;
              aTabBillPositionRec(aTabBillPositionRec.last).aSTU_PRORATE_PAYMENT        := aSTU_PRORATE_PAYMENT;
              aTabBillPositionRec(aTabBillPositionRec.last).aSTU_ECO_MIXED_BILLING      := aSTU_ECO_MIXED_BILLING;
              -- Paramètres de la facturation
              aTabBillPositionRec(aTabBillPositionRec.last).aSCH_GROUP_YEAR_PERIOD_ID   := iSCH_GROUP_YEAR_PERIOD_ID;
              aTabBillPositionRec(aTabBillPositionRec.last).aSCH_YEAR_PERIOD_ID         := iSCH_YEAR_PERIOD_ID;
              aTabBillPositionRec(aTabBillPositionRec.last).aDOC_GAUGE_ID               := iDOC_GAUGE_ID;
              aTabBillPositionRec(aTabBillPositionRec.last).aBillDate                   := iDMT_DATE_VALUE;
              aTabBillPositionRec(aTabBillPositionRec.last).aC_GROUPING_MODE            := iC_GROUPING_MODE;
              aTabBillPositionRec(aTabBillPositionRec.last).aSTU_ECO_OTHER_ADDRESS      := aSTU_ECO_OTHER_ADDRESS;
              -- informations sur les écolages et catégories
              aTabBillPositionRec(aTabBillPositionRec.last).aSCH_ECOLAGE_ID             := null;
              aTabBillPositionRec(aTabBillPositionRec.last).aSCH_ECOLAGE_CATEGORY_ID    := null;
              aTabBillPositionRec(aTabBillPositionRec.last).aSCH_DISCOUNT_ID            := tplDiscount.SCH_DISCOUNT_ID;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_MAJOR_REFERENCE        := tplDiscount.DIS_MAJOR_REFERENCE;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_SECONDARY_REFERENCE    := tplDiscount.DIS_SECONDARY_REFERENCE;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_DESCRIPTION            := tplDiscount.DIS_SECONDARY_REFERENCE;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_CATEGORY_DESCR         := tplDiscount.DIS_SECONDARY_REFERENCE;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_SHORT_DESCR            := tplDiscount.DIS_SHORT_DESCR;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_LONG_DESCR             := tplDiscount.DIS_LONG_DESCR;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_FREE_DESCR             := null;
              aTabBillPositionRec(aTabBillPositionRec.last).aGCO_GOOD_ID                := tplDiscount.GCO_GOOD_ID;
              -- Informations de montant, qté
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_TTC_UNIT_AMOUNT        := lnTotalDiscountAmount;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_TTC_AMOUNT             := lnTotalDiscountAmount;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_QTY                    := 1;
              -- Recherche du débiteur par défaut
              aTabBillPositionRec(aTabBillPositionRec.last).aDefltPAC_CUSTOM_PARTNER    := lnPAC_CUSTOM_PARTNER_ID;
              aTabBillPositionRec(aTabBillPositionRec.last).aPAC_CUSTOM_PARTNER_ID      := lnPAC_CUSTOM_PARTNER_ID;

              begin
                aACS_VAT_DET_ACCOUNT_ID                                                  := null;
                aACS_FIN_ACC_S_PAYMENT_ID                                                := null;
                aDIC_TYPE_SUBMISSION_ID                                                  := null;
                aPER_KEY1                                                                := null;
                iPAC_PAYMENT_CONDITION_ID                                                := null;

                select distinct PAC.ACS_VAT_DET_ACCOUNT_ID
                              , PAC.ACS_FIN_ACC_S_PAYMENT_ID
                              , PAC.DIC_TYPE_SUBMISSION_ID
                              , PER.PER_KEY1
                              , PAC.PAC_PAYMENT_CONDITION_ID
                           into aACS_VAT_DET_ACCOUNT_ID
                              , aACS_FIN_ACC_S_PAYMENT_ID
                              , aDIC_TYPE_SUBMISSION_ID
                              , aPER_KEY1
                              , iPAC_PAYMENT_CONDITION_ID
                           from COM_LIST_ID_TEMP LID
                              , ACS_AUX_ACCOUNT_S_FIN_CURR AAA
                              , PAC_CUSTOM_PARTNER PAC
                              , PAC_PERSON PER
                          where PAC.ACS_AUXILIARY_ACCOUNT_ID = AAA.ACS_AUXILIARY_ACCOUNT_ID(+)
                            and PAC.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
                            and PAC.PAC_CUSTOM_PARTNER_ID = LID.COM_LIST_ID_TEMP_ID
                            and LID.LID_CODE = 'PAC_CUSTOM_PARTNER_ID'
                            and PAC.PAC_CUSTOM_PARTNER_ID = lnPAC_CUSTOM_PARTNER_ID;

                aTabBillPositionRec(aTabBillPositionRec.last).aACS_VAT_DET_ACCOUNT_ID    := aACS_VAT_DET_ACCOUNT_ID;
                aTabBillPositionRec(aTabBillPositionRec.last).aACS_FIN_ACC_S_PAYMENT_ID  := aACS_FIN_ACC_S_PAYMENT_ID;
                aTabBillPositionRec(aTabBillPositionRec.last).aDIC_TYPE_SUBMISSION_ID    := aDIC_TYPE_SUBMISSION_ID;
                aTabBillPositionRec(aTabBillPositionRec.last).aPER_KEY1                  := aPER_KEY1;
              exception
                when others then
                  begin
                    aTabBillPositionRec(aTabBillPositionRec.last).aACS_VAT_DET_ACCOUNT_ID    := null;
                    aTabBillPositionRec(aTabBillPositionRec.last).aACS_FIN_ACC_S_PAYMENT_ID  := null;
                    aTabBillPositionRec(aTabBillPositionRec.last).aDIC_TYPE_SUBMISSION_ID    := null;
                    aTabBillPositionRec(aTabBillPositionRec.last).aPER_KEY1                  := null;
                  end;
              end;

              aTabBillPositionRec(aTabBillPositionRec.last).aACS_FINANCIAL_CURRENCY_ID  := SCH_TOOLS.GetBaseMoney;
              aTabBillPositionRec(aTabBillPositionRec.last).aPAC_PAYMENT_CONDITION_ID   :=
                                                         case
                                                           when nvl(aPAC_PAYMENT_CONDITION_ID, 0) = 0 then iPAC_PAYMENT_CONDITION_ID
                                                           else aPAC_PAYMENT_CONDITION_ID
                                                         end;
              -- Divers
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_SEQ                    := null;
            end if;
          -- Remise sur période
          else
            -- Montant total facturé, pour la période, et pour l'élève
            for tplTotalAmount in crTotalOfPeriod(iSCH_YEAR_PERIOD_ID, TStudents(i) ) loop
              -- Calcul du montant à facturer
              CalcDiscountAmount(tplDiscount.SCH_DISCOUNT_ID
                               , tplTotalAmount.SUM_AMOUNT + GetDiscountAmount(TStudents(i), iSCH_YEAR_PERIOD_ID)
                               , lnDiscountAmount
                               , TStudents(i)
                                );
              -- Insertion de la position correspondante dans la table temporaire
              aTabBillPositionRec.extend;

              begin
                select STU_ACCOUNT_NUMBER
                     , STU_PRORATE_PAYMENT
                     , STU_ECO_MIXED_BILLING
                     , STU_ECO_OTHER_ADDRESS
                  into aSTU_ACCOUNT_NUMBER
                     , aSTU_PRORATE_PAYMENT
                     , aSTU_ECO_MIXED_BILLING
                     , aSTU_ECO_OTHER_ADDRESS
                  from SCH_STUDENT
                 where SCH_STUDENT_ID = TStudents(i);
              exception
                when others then
                  begin
                    aSTU_ACCOUNT_NUMBER     := null;
                    aSTU_PRORATE_PAYMENT    := null;
                    aSTU_ECO_MIXED_BILLING  := null;
                    aSTU_ECO_OTHER_ADDRESS  := null;
                  end;
              end;

              -- information de l'èlève
              aTabBillPositionRec(aTabBillPositionRec.last).aSCH_STUDENT_ID             := TStudents(i);
              aTabBillPositionRec(aTabBillPositionRec.last).aSTU_ACCOUNT_NUMBER         := aSTU_ACCOUNT_NUMBER;
              aTabBillPositionRec(aTabBillPositionRec.last).aSTU_PRORATE_PAYMENT        := aSTU_PRORATE_PAYMENT;
              aTabBillPositionRec(aTabBillPositionRec.last).aSTU_ECO_MIXED_BILLING      := aSTU_ECO_MIXED_BILLING;
              -- Paramètres de la facturation
              aTabBillPositionRec(aTabBillPositionRec.last).aSCH_GROUP_YEAR_PERIOD_ID   := iSCH_GROUP_YEAR_PERIOD_ID;
              aTabBillPositionRec(aTabBillPositionRec.last).aSCH_YEAR_PERIOD_ID         := iSCH_YEAR_PERIOD_ID;
              aTabBillPositionRec(aTabBillPositionRec.last).aDOC_GAUGE_ID               := iDOC_GAUGE_ID;
              aTabBillPositionRec(aTabBillPositionRec.last).aBillDate                   := iDMT_DATE_VALUE;
              aTabBillPositionRec(aTabBillPositionRec.last).aC_GROUPING_MODE            := iC_GROUPING_MODE;
              aTabBillPositionRec(aTabBillPositionRec.last).aSTU_ECO_OTHER_ADDRESS      := aSTU_ECO_OTHER_ADDRESS;
              -- informations sur les écolages et catégories
              aTabBillPositionRec(aTabBillPositionRec.last).aSCH_ECOLAGE_ID             := null;
              aTabBillPositionRec(aTabBillPositionRec.last).aSCH_ECOLAGE_CATEGORY_ID    := null;
              aTabBillPositionRec(aTabBillPositionRec.last).aSCH_DISCOUNT_ID            := tplDiscount.SCH_DISCOUNT_ID;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_MAJOR_REFERENCE        := tplDiscount.DIS_MAJOR_REFERENCE;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_SECONDARY_REFERENCE    := tplDiscount.DIS_SECONDARY_REFERENCE;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_DESCRIPTION            := tplDiscount.DIS_SECONDARY_REFERENCE;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_CATEGORY_DESCR         := tplDiscount.DIS_SECONDARY_REFERENCE;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_SHORT_DESCR            := tplDiscount.DIS_SHORT_DESCR;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_LONG_DESCR             := tplDiscount.DIS_LONG_DESCR;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_FREE_DESCR             := null;
              aTabBillPositionRec(aTabBillPositionRec.last).aGCO_GOOD_ID                := tplDiscount.GCO_GOOD_ID;
              -- Informations de montant, qté
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_TTC_UNIT_AMOUNT        := lnDiscountAmount;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_TTC_AMOUNT             := lnDiscountAmount;
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_QTY                    := 1;
              -- Recherche du débiteur par défaut
              aTabBillPositionRec(aTabBillPositionRec.last).aDefltPAC_CUSTOM_PARTNER    := tplTotalAmount.aPAC_CUSTOM_PARTNER_ID;
              aTabBillPositionRec(aTabBillPositionRec.last).aPAC_CUSTOM_PARTNER_ID      := tplTotalAmount.aPAC_CUSTOM_PARTNER_ID;

              begin
                aACS_VAT_DET_ACCOUNT_ID                                                  := null;
                aACS_FIN_ACC_S_PAYMENT_ID                                                := null;
                aDIC_TYPE_SUBMISSION_ID                                                  := null;
                aPER_KEY1                                                                := null;
                iPAC_PAYMENT_CONDITION_ID                                                := null;

                select distinct PAC.ACS_VAT_DET_ACCOUNT_ID
                              , PAC.ACS_FIN_ACC_S_PAYMENT_ID
                              , PAC.DIC_TYPE_SUBMISSION_ID
                              , PER.PER_KEY1
                              , PAC.PAC_PAYMENT_CONDITION_ID
                           into aACS_VAT_DET_ACCOUNT_ID
                              , aACS_FIN_ACC_S_PAYMENT_ID
                              , aDIC_TYPE_SUBMISSION_ID
                              , aPER_KEY1
                              , iPAC_PAYMENT_CONDITION_ID
                           from COM_LIST_ID_TEMP LID
                              , ACS_AUX_ACCOUNT_S_FIN_CURR AAA
                              , PAC_CUSTOM_PARTNER PAC
                              , PAC_PERSON PER
                          where PAC.ACS_AUXILIARY_ACCOUNT_ID = AAA.ACS_AUXILIARY_ACCOUNT_ID(+)
                            and PAC.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
                            and PAC.PAC_CUSTOM_PARTNER_ID = LID.COM_LIST_ID_TEMP_ID
                            and LID.LID_CODE = 'PAC_CUSTOM_PARTNER_ID'
                            and PAC.PAC_CUSTOM_PARTNER_ID = tplTotalAmount.aPAC_CUSTOM_PARTNER_ID;

                aTabBillPositionRec(aTabBillPositionRec.last).aACS_VAT_DET_ACCOUNT_ID    := aACS_VAT_DET_ACCOUNT_ID;
                aTabBillPositionRec(aTabBillPositionRec.last).aACS_FIN_ACC_S_PAYMENT_ID  := aACS_FIN_ACC_S_PAYMENT_ID;
                aTabBillPositionRec(aTabBillPositionRec.last).aDIC_TYPE_SUBMISSION_ID    := aDIC_TYPE_SUBMISSION_ID;
                aTabBillPositionRec(aTabBillPositionRec.last).aPER_KEY1                  := aPER_KEY1;
              exception
                when others then
                  begin
                    aTabBillPositionRec(aTabBillPositionRec.last).aACS_VAT_DET_ACCOUNT_ID    := null;
                    aTabBillPositionRec(aTabBillPositionRec.last).aACS_FIN_ACC_S_PAYMENT_ID  := null;
                    aTabBillPositionRec(aTabBillPositionRec.last).aDIC_TYPE_SUBMISSION_ID    := null;
                    aTabBillPositionRec(aTabBillPositionRec.last).aPER_KEY1                  := null;
                  end;
              end;

              aTabBillPositionRec(aTabBillPositionRec.last).aACS_FINANCIAL_CURRENCY_ID  := SCH_TOOLS.GetBaseMoney;
              aTabBillPositionRec(aTabBillPositionRec.last).aPAC_PAYMENT_CONDITION_ID   :=
                                                         case
                                                           when nvl(aPAC_PAYMENT_CONDITION_ID, 0) = 0 then iPAC_PAYMENT_CONDITION_ID
                                                           else aPAC_PAYMENT_CONDITION_ID
                                                         end;
              -- Divers
              aTabBillPositionRec(aTabBillPositionRec.last).aBOP_SEQ                    := null;
              exit;
            end loop;
          end if;
        end loop;
      end if;
    end loop;
  end ApplyDiscount;
end;
