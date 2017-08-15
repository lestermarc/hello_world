--------------------------------------------------------
--  DDL for Package Body GAL_BDG_PERIOD_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_BDG_PERIOD_FUNCTIONS" 
is
  /**
  * procedure CreateBudgetPeriods
  * Description
  *    Cr�ation des p�riodes budg�taires dans la table GAL_BUDGET_PERIOD
  */
  procedure CreateBudgetPeriods(aPeriodType in varchar2, aBeginPeriod in date, aEndPeriod in date)
  is
    vStartDate date;
    vEndDate   date;
    vReference GAL_BUDGET_PERIOD.GBP_REFERENCE%type;
  begin
    -- V�rifier la valeur du descode du type de p�riode
    if lpad(aPeriodType, 2, '0') not in('12', '06', '03', '01') then
      pcs.ra(PCS.PC_FUNCTIONS.TranslateWord('Le type de p�riode n''est pas valide !') ||
             chr(10) ||
             PCS.PC_FUNCTIONS.TranslateWord('Valeurs autoris�es : 12, 06, 03 ou 01')
            );
    end if;

    -- V�rifier que la date de d�but soit <= � la date de fin
    if (aBeginPeriod > aEndPeriod) then
      pcs.ra(PCS.PC_FUNCTIONS.TranslateWord('La date de d�but est sup�rieure � la date de fin de p�riode !') );
    end if;

    -- Contr�le des ann�es dans les limites autoris�es
    if    (aBeginPeriod < to_date('01.01.2000', 'dd.mm.yyyy') )
       or (aEndPeriod > to_date('31.12.2100', 'dd.mm.yyyy') ) then
      pcs.ra(PCS.PC_FUNCTIONS.TranslateWord('Les dates sont en dehors des limites autoris�es (01.01.2000 -> 31.12.2100) !') );
    end if;

    -- D�finition de la date de d�but de la 1ere p�riode � cr�er
    vStartDate  := trunc(aBeginPeriod);

    -- Cr�ation des p�riodes pour les ann�es pass�es en param
    while vStartDate < trunc(aEndPeriod) loop
      -- Ajouter N mois pour trouver la date de fin de la p�riode
      vEndDate    := add_months(vStartDate, aPeriodType) - 1;

      -- R�f�rence p�riode
      -- Si type = Ann�e et que l'ann�e de d�but = l'ann�e de fin
      if     (aPeriodType = '12')
         and (to_char(vStartDate, 'yyyy') = to_char(vEndDate, 'yyyy') ) then
        -- format = 2010
        vReference  := to_char(vStartDate, 'yyyy');
      else
        -- format = 2010.01-2011.03
        vReference  := to_char(vStartDate, 'yyyy') || '.' || to_char(vStartDate, 'mm') || '-' || to_char(vEndDate, 'yyyy') || '.' || to_char(vEndDate, 'mm');
      end if;

      begin
        -- Insertion de la p�riode
        insert into GAL_BUDGET_PERIOD
                    (GAL_BUDGET_PERIOD_ID
                   , C_BUDGET_PERIOD
                   , GBP_REFERENCE
                   , GBP_START_DATE
                   , GBP_END_DATE
                   , GBP_DESCRIPTION
                   , A_DATECRE
                   , A_IDCRE
                    )
          select init_id_seq.nextval
               , lpad(aPeriodType, 2, '0') as C_BUDGET_PERIOD
               , vReference as GBP_REFERENCE
               , vStartDate as GBP_START_DATE
               , vEndDate as GBP_END_DATE
               , to_char(vStartDate, 'dd.mm.yyyy') || ' - ' || to_char(vEndDate, 'dd.mm.yyyy') as GBP_DESCRIPTION
               , sysdate as A_DATECRE
               , PCS.PC_I_LIB_SESSION.GetUserIni as A_IDCRE
            from dual;
      exception
        -- A FAIRE : Gestion des erreurs et affichage de celles-ci
        when others then
          null;
      end;

      -- D�finition de la date de d�but de la prochaine p�riode
      vStartDate  := vEndDate + 1;
    end loop;
  end CreateBudgetPeriods;

  /**
  * procedure CreateNextPeriod
  * Description
  *    Cr�ation de la prochaine p�riode budg�taire dans la table GAL_BUDGET_PERIOD
  */
  procedure CreateNextPeriod
  is
    vStartDate    GAL_BUDGET_PERIOD.GBP_START_DATE%type;
    vBudgetPeriod GAL_BUDGET_PERIOD.C_BUDGET_PERIOD%type;
  begin
    begin
      select GBP.GBP_END_DATE + 1
           , GBP.C_BUDGET_PERIOD
        into vStartDate
           , vBudgetPeriod
        from GAL_BUDGET_PERIOD GBP
           , (select max(GBP_END_DATE) as GBP_END_DATE
                from GAL_BUDGET_PERIOD) MAX_DATE
       where GBP.GBP_END_DATE = MAX_DATE.GBP_END_DATE;

      GAL_BDG_PERIOD_FUNCTIONS.CreateBudgetPeriods(aPeriodType => vBudgetPeriod, aBeginPeriod => vStartDate, aEndPeriod => vStartDate + 1);
    exception
      when no_data_found then
        null;
    end;
  end CreateNextPeriod;

  /**
  * function GetPeriod
  * Description
  *   Retourne l'id de la p�riode correspondant � la date pass�e en param
  */
  function GetPeriod(aDate in date default sysdate)
    return GAL_BUDGET_PERIOD.GAL_BUDGET_PERIOD_ID%type
  is
    vPeriodID GAL_BUDGET_PERIOD.GAL_BUDGET_PERIOD_ID%type   default null;
  begin
    select max(GAL_BUDGET_PERIOD_ID)
      into vPeriodID
      from GAL_BUDGET_PERIOD
     where aDate between GBP_START_DATE and GBP_END_DATE;

    return vPeriodID;
  end GetPeriod;

  /**
  * function GetNextPeriod
  * Description
  *   Retourne l'id de la prochaine p�riode (recherche par id de p�riode ou par date)
  */
  function GetNextPeriod(aPeriodID in GAL_BUDGET_PERIOD.GAL_BUDGET_PERIOD_ID%type default null, aDate in date default null)
    return GAL_BUDGET_PERIOD.GAL_BUDGET_PERIOD_ID%type
  is
    -- Liste des p�riodes suivantes par rapport la date
    cursor crPeriod(cDate in date)
    is
      select   GAL_BUDGET_PERIOD_ID
          from GAL_BUDGET_PERIOD
         where GBP_START_DATE > cDate
      order by GBP_START_DATE;

    vPeriodID GAL_BUDGET_PERIOD.GAL_BUDGET_PERIOD_ID%type   default null;
    vDate     date;
  begin
    -- Id de p�riode pass� en param, chercher la date de fin de la p�riode
    if aPeriodID is not null then
      select GBP_END_DATE
        into vDate
        from GAL_BUDGET_PERIOD
       where GAL_BUDGET_PERIOD_ID = aPeriodID;
    else
      -- Date pass�e en param
      vDate  := aDate;
    end if;

    -- Rechercher la p�riode suivante par rapport � la date
    open crPeriod(nvl(vDate, trunc(sysdate) ) );

    fetch crPeriod
     into vPeriodID;

    close crPeriod;

    return vPeriodID;
  end GetNextPeriod;

  /**
  * function GetBudgetNextPeriod
  * Description
  *   Retourne l'id de la prochaine p�riode pour un budget/nature analytique
  */
  function GetBudgetNextPeriod(aBudgetID in GAL_BUDGET.GAL_BUDGET_ID%type, aCostCenterID in GAL_COST_CENTER.GAL_COST_CENTER_ID%type)
    return GAL_BUDGET_PERIOD.GAL_BUDGET_PERIOD_ID%type
  is
    -- Retrouve la derni�re p�riode d'un budget/nature analytique
    cursor crBudgetPeriods(cBudgetID in GAL_BUDGET.GAL_BUDGET_ID%type, cCostCenterID in GAL_COST_CENTER.GAL_COST_CENTER_ID%type)
    is
      select   GBP.GBP_END_DATE
          from GAL_BUDGET_LINE BLI
             , GAL_BUDGET_PERIOD GBP
         where BLI.GAL_BUDGET_ID = cBudgetID
           and BLI.GAL_COST_CENTER_ID = cCostCenterID
           and BLI.GAL_BUDGET_PERIOD_ID = GBP.GAL_BUDGET_PERIOD_ID
      order by GBP.GBP_END_DATE desc;

    vPeriodID GAL_BUDGET_PERIOD.GAL_BUDGET_PERIOD_ID%type   default null;
    vDate     date;
  begin
    open crBudgetPeriods(aBudgetID, aCostCenterID);

    fetch crBudgetPeriods
     into vDate;

    close crBudgetPeriods;

    -- Rechercher la prochaine p�riode
    if vDate is not null then
      vPeriodID  := GAL_BDG_PERIOD_FUNCTIONS.GetNextPeriod(aDate => vDate);
    end if;

    return vPeriodID;
  end GetBudgetNextPeriod;

  /**
  * function GetFirstOpenPeriod
  * Description
  *   Retourne l'id de la premi�re p�riode ouverte de l'affaire (chronologique)
  */
  function GetFirstOpenPeriod(aProjectID in GAL_PROJECT.GAL_PROJECT_ID%type)
    return GAL_BUDGET_PERIOD.GAL_BUDGET_PERIOD_ID%type
  is
    cursor crOpenPeriod(cProjectID in number)
    is
      select   GBP.GAL_BUDGET_PERIOD_ID
          from GAL_BUDGET BDG
             , GAL_BUDGET_LINE BLI
             , GAL_BUDGET_PERIOD GBP
         where BDG.GAL_PROJECT_ID = cProjectID
           and BDG.GAL_BUDGET_ID = BLI.GAL_BUDGET_ID
           and BLI.GAL_BUDGET_PERIOD_ID = GBP.GAL_BUDGET_PERIOD_ID
           and BLI.BLI_CLOTURED = 0
      group by GBP.GBP_START_DATE
             , GBP.GAL_BUDGET_PERIOD_ID
      order by GBP.GBP_START_DATE asc;

    vPeriodID GAL_BUDGET_PERIOD.GAL_BUDGET_PERIOD_ID%type   default null;
  begin
    open crOpenPeriod(aProjectID);

    fetch crOpenPeriod
     into vPeriodID;

    close crOpenPeriod;

    return vPeriodID;
  end GetFirstOpenPeriod;

  /**
  * procedure UpdateProjectPeriod
  * Description
  *   M�j du champ de la p�riode ouverte de l'affaire
  */
  procedure UpdateProjectPeriod(aProjectID in GAL_PROJECT.GAL_PROJECT_ID%type)
  is
    vPeriodID GAL_BUDGET_PERIOD.GAL_BUDGET_PERIOD_ID%type;
  begin
    vPeriodID  := GAL_BDG_PERIOD_FUNCTIONS.GetFirstOpenPeriod(aProjectID);

    update GAL_PROJECT
       set GAL_BUDGET_PERIOD_ID = vPeriodID
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , A_DATEMOD = sysdate
     where GAL_PROJECT_ID = aProjectID;
  end UpdateProjectPeriod;

  /**
  * procedure UpdateBudgetPeriodDates
  * Description
  *   M�j de la date de la premi�re et derni�re p�riode budgetaire
  */
  procedure UpdateBudgetPeriodDates(aBudgetID in GAL_BUDGET.GAL_BUDGET_ID%type)
  is
    vStartDate date;
    vEndDate   date;
  begin
    select min(GBP.GBP_START_DATE) START_DATE
         , max(GBP.GBP_END_DATE) END_DATE
      into vStartDate
         , vEndDate
      from GAL_BUDGET_LINE BLI
         , GAL_BUDGET_PERIOD GBP
     where BLI.GAL_BUDGET_ID = aBudgetID
       and BLI.GAL_BUDGET_PERIOD_ID = GBP.GAL_BUDGET_PERIOD_ID;

    update GAL_BUDGET
       set BDG_START_DATE = vStartDate
         , BDG_END_DATE = vEndDate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , A_DATEMOD = sysdate
     where GAL_BUDGET_ID = aBudgetID;
  end UpdateBudgetPeriodDates;

  /**
  * procedure CreateMissingBdgLinePeriods
  * Description
  *   Cr�ation des lignes de budget dans les intervalles ou elles sont manquantes
  * @created NGV Sept. 2010
  * @lastUpdate
  * @public
  * @param  aBudgetID     : Id du budget
  * @param  aCostCenterID : Id de la nature analytique
  */
  procedure CreateMissingBdgLinePeriods(aBudgetID in GAL_BUDGET.GAL_BUDGET_ID%type, aCostCenterID in GAL_COST_CENTER.GAL_COST_CENTER_ID%type)
  is
    vBudgetLines     integer;
    vMinDate         date;
    vMaxDate         date;
    vSrcBudgetLineID GAL_BUDGET_LINE.GAL_BUDGET_LINE_ID%type;
    vNewBudgetLineID GAL_BUDGET_LINE.GAL_BUDGET_LINE_ID%type;
  begin
    -- R�cuperer le nbre de lignes budget, la date min et max des p�riodes
    select count(BLI.GAL_BUDGET_LINE_ID)
         , min(GBP.GBP_START_DATE)
         , max(GBP.GBP_START_DATE)
      into vBudgetLines
         , vMinDate
         , vMaxDate
      from GAL_BUDGET_LINE BLI
         , GAL_BUDGET BDG
         , GAL_PROJECT PRJ
         , GAL_BUDGET_PERIOD GBP
     where BLI.GAL_BUDGET_ID = aBudgetID
       and BLI.GAL_COST_CENTER_ID = aCostCenterID
       and BLI.GAL_BUDGET_ID = BDG.GAL_BUDGET_ID
       and BDG.GAL_PROJECT_ID = PRJ.GAL_PROJECT_ID
       and BLI.GAL_BUDGET_PERIOD_ID = GBP.GAL_BUDGET_PERIOD_ID;

    -- Si plusieurs lignes de budget, v�rifier s'il y a des intervalles sans p�riode
    if vBudgetLines > 1 then
      -- R�cuperer la derni�re ligne de budget
      select BLI.GAL_BUDGET_LINE_ID
        into vSrcBudgetLineID
        from GAL_BUDGET_LINE BLI
           , GAL_BUDGET_PERIOD GBP
       where BLI.GAL_BUDGET_ID = aBudgetID
         and BLI.GAL_COST_CENTER_ID = aCostCenterID
         and BLI.GAL_BUDGET_PERIOD_ID = GBP.GAL_BUDGET_PERIOD_ID
         and GBP.GBP_START_DATE = vMaxDate;

      -- Pour les p�riodes absentes dans le budget/nature analytiques
      for tplPeriod in (select   GBP.GAL_BUDGET_PERIOD_ID
                               , GBP.GBP_START_DATE
                            from GAL_BUDGET_PERIOD GBP
                           where GBP.GBP_START_DATE between vMinDate and vMaxDate
                        minus
                        select   GBP.GAL_BUDGET_PERIOD_ID
                               , GBP.GBP_START_DATE
                            from GAL_BUDGET_LINE BLI
                               , GAL_BUDGET_PERIOD GBP
                           where BLI.GAL_BUDGET_ID = aBudgetID
                             and BLI.GAL_COST_CENTER_ID = aCostCenterID
                             and BLI.GAL_BUDGET_PERIOD_ID = GBP.GAL_BUDGET_PERIOD_ID
                        order by 2 asc) loop
        vNewBudgetLineID  := null;
        -- Cr�ation d'une nouvelle ligne de budget
        DuplicateBudgetLine(aSrcBudgetLineID => vSrcBudgetLineID, aNewPeriodID => tplPeriod.GAL_BUDGET_PERIOD_ID, aNewBudgetLineID => vNewBudgetLineID);
      end loop;
    end if;
  end CreateMissingBdgLinePeriods;

  /**
  * procedure DuplicateBudgetLine
  * Description
  *   Copie une ligne de budget
  */
  procedure DuplicateBudgetLine(
    aSrcBudgetLineID in     GAL_BUDGET_LINE.GAL_BUDGET_LINE_ID%type
  , aNewPeriodID     in     GAL_BUDGET_PERIOD.GAL_BUDGET_PERIOD_ID%type
  , aNewBudgetLineID in out GAL_BUDGET_LINE.GAL_BUDGET_LINE_ID%type
  )
  is
    vDate        date;
    vPrice       GAL_BUDGET_LINE.BLI_BUDGET_PRICE%type;
    vNewPeriodID GAL_BUDGET_PERIOD.GAL_BUDGET_PERIOD_ID%type   default null;
    vSrcLine     GAL_BUDGET_LINE%rowtype;
    lnProjectID  GAL_PROJECT.GAL_PROJECT_ID%type;
  begin
    -- Init de l'ID de la nouvelle ligne si pas pass� en param
    if aNewBudgetLineID is null then
      select INIT_ID_SEQ.nextval
        into aNewBudgetLineID
        from dual;
    end if;

    -- R�cup�rer les donn�es de la ligne source
    select *
      into vSrcLine
      from GAL_BUDGET_LINE
     where GAL_BUDGET_LINE_ID = aSrcBudgetLineID;

    -- P�riode budg�taire renseign�e sur la ligne source
    if vSrcLine.GAL_BUDGET_PERIOD_ID is not null then
      -- si la p�riode n'est pas pass�e en param, rechercher la p�riode suivante
      -- � la p�riode de la ligne source
      if aNewPeriodID is null then
        vNewPeriodID  := GAL_BDG_PERIOD_FUNCTIONS.GetNextPeriod(aPeriodID => vSrcLine.GAL_BUDGET_PERIOD_ID, aDate => null);
      else
        vNewPeriodID  := aNewPeriodID;
      end if;

      -- Init de la date � utiliser pour la recherche du prix en fonction de la nature analytique.
      -- date utilis�e = date d�but de p�riode
      begin
        select GBP_START_DATE
          into vDate
          from GAL_BUDGET_PERIOD
         where GAL_BUDGET_PERIOD_ID = vNewPeriodID;
      exception
        when no_data_found then
          vDate  := sysdate;
      end;
    else
      -- Pas de p�riode budg�taire pour l'affaire
      -- Init de la date � utiliser pour la recherche du prix en fonction de la nature analytique.
      vDate  := sysdate;
    end if;

    -- Rechercher l'id de l'affaire, utilis� pour la rechercher des taux horaires
    select max(GAL_PROJECT_ID)
      into lnProjectID
      from GAL_BUDGET
     where GAL_BUDGET_ID = vSrcLine.GAL_BUDGET_ID;

    -- Recherche le prix en fonction de la nature analytique.
    vPrice  := GAL_PROJECT_SPENDING.GET_HOURLY_RATE_FROM_NAT_ANA(vSrcLine.GAL_COST_CENTER_ID, vDate, '00', lnProjectID);

    insert into GAL_BUDGET_LINE
                (GAL_BUDGET_LINE_ID
               , GAL_BUDGET_ID
               , GAL_COST_CENTER_ID
               , GAL_BUDGET_PERIOD_ID
               , BLI_SEQUENCE
               , BLI_WORDING
               , BLI_BUDGET_PRICE
               , BLI_DESCRIPTION
               , BLI_COMMENT
               , BLI_CLOTURED
               , A_DATECRE
               , A_IDCRE
                )
      select aNewBudgetLineID as GAL_BUDGET_LINE_ID
           , vSrcLine.GAL_BUDGET_ID
           , vSrcLine.GAL_COST_CENTER_ID
           , vNewPeriodID as GAL_BUDGET_PERIOD_ID
           , vSrcLine.BLI_SEQUENCE
           , vSrcLine.BLI_WORDING
           , vPrice as BLI_BUDGET_PRICE
           , vSrcLine.BLI_DESCRIPTION
           , vSrcLine.BLI_COMMENT
           , 0 as BLI_CLOTURED
           , sysdate as A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni as A_IDCRE
        from dual;

    -- M�j de la date de la premi�re et derni�re p�riode budgetaire
    UpdateBudgetPeriodDates(aBudgetID => vSrcLine.GAL_BUDGET_ID);
  end DuplicateBudgetLine;
end GAL_BDG_PERIOD_FUNCTIONS;
