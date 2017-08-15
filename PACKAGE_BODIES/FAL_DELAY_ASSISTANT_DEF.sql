--------------------------------------------------------
--  DDL for Package Body FAL_DELAY_ASSISTANT_DEF
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_DELAY_ASSISTANT_DEF" 
is
------------------------------------------------------------------------------------
-- Recherche de la date fin selon la condition de fabrication par d�faut d'un poduit,
-- la quantit� demand�e et la date de d�but de recherche
-- De plus, la m�thode retourne la dur�e totale de la planification et la dur�e cumul�e des OPS
------------------------------------------------------------------------------------
  procedure SearchPrevisionalEndDate(
    aGoodID           in     number
  , aQty              in     number
  , aBeginDate        in     date
  , aEndDate          in out date
  , aOPDuration       in out number
  , aPlanifDuration   in out number
  , aAllInInfiniteCap        number default 1
  )
  is
    cursor GetOPRecord(aSchedulePlanID in number)
    is
      select   *
          from FAL_LIST_STEP_LINK LSL
         where LSL.FAL_SCHEDULE_PLAN_ID = aSchedulePlanID
      order by LSL.SCS_STEP_NUMBER;

    vOP              GetOPRecord%rowtype;
    SchedulePlanID   number;
    SchedulePlanning FAL_LOT.C_LOT_STATUS%type;
    bFound           boolean;
    LotQuantity      number;
    ManufDelay       GCO_COMPL_DATA_MANUFACTURE.CMA_MANUFACTURING_DELAY%type;
    BeginStartDate   date;
    TmpDate          date;
    InfiniteFloor    integer;
    OPDuration       number;
    FloorCapacity    integer;
    RessourceNumber  integer;
    TypeCal          integer;
    CmaFixDelay      GCO_COMPL_DATA_MANUFACTURE.CMA_FIX_DELAY%type;
  begin
    bFound           := false;

    begin
      select FAL_SCHEDULE_PLAN_ID
           , nvl(CMA_LOT_QUANTITY, 1)
           , nvl(CMA_MANUFACTURING_DELAY, 0)
           , nvl(CMA_FIX_DELAY, 0)
        into SchedulePlanID
           , LotQuantity
           , ManufDelay
           , CmaFixDelay
        from GCO_COMPL_DATA_MANUFACTURE
       where GCO_GOOD_ID = aGoodID
         and CMA_DEFAULT = 1;

      bFound  := true;
    exception
      when no_data_found then
        bFound  := false;
    end;

    if SchedulePlanID is not null then
      begin
        select nvl(C_SCHEDULE_PLANNING, '1')
          into SchedulePlanning
          from FAL_SCHEDULE_PLAN
         where FAL_SCHEDULE_PLAN_ID = SchedulePlanID;
      exception
        when no_data_found then
          SchedulePlanning  := '1';
      end;
    else
      SchedulePlanning  := '1';
    end if;

    aOPDuration      := 0;
    aPlanifDuration  := 0;

    -- Si une condition de fabrication a �t� trouv�
    if bFound then
      -- Planification selon produit
      if SchedulePlanning = '1' then
        BeginStartDate   :=
                   trunc(aBeginDate) +
                   (to_number(PCS.PC_CONFIG.GetConfig('PPS_BEGIN_Hour') ) / 24) +
                   (to_number(PCS.PC_CONFIG.GetConfig('PPS_BEGIN_Minut') ) / 1440);
        aEndDate         := BeginStartDate;

        if CmaFixDelay = 1 then
          aOPDuration  := ManufDelay;
        else
          aOPDuration  := (aQty / LotQuantity) * ManufDelay;
        end if;

        aPlanifDuration  := aOPDuration;
        -- D�termination de la date fin par rapport au calcul de la dur�e de la donn�e compl�mentaire de fabrication
        aEndDate         :=
          FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(aFal_factory_floor_id      => null
                                                      , aPac_supplier_partner_id   => null
                                                      , aPac_custom_partner_id     => null
                                                      , aPAC_DEPARTMENT_ID         => null
                                                      , aHrm_person_id             => null
                                                      , aCalendarId                => null
                                                      , aFromDate                  => BeginStartDate
                                                      , aDecalage                  => aOPDuration
                                                       );
      elsif(   SchedulePlanning = '2'
            or SchedulePlanning = '3') then
        -- Initialisation
        BeginStartDate   := aBeginDate;
        aEndDate         := BeginStartDate;
        -- Nouvelle planif
        FAL_PLANIF.GeneralPlanning(aLotPropOrGammeId    => SchedulePlanID
                                 , aGcoGoodId           => null
                                 , aDicFabConditionId   => null
                                 , aBeginDate           => BeginStartDate
                                 , aEndDate             => aEndDate
                                 , aCSchedulePlanning   => 2   -- selon op�rations
                                 , aLotTolerance        => null
                                 , UpdateBatchFields    => 0
                                 , aDatePlanification   => null
                                 , PlanificationType    => FAL_PLANIF.ctDateDebut
                                 , aQty                 => aQty
                                 , aAllInInfiniteCap    => aAllInInfiniteCap
                                 , FLotBeginDate        => BeginStartDate   -- in out
                                 , FLotEndDate          => aEndDate   -- in out
                                 , FLotDuration         => aOPDuration   -- in out
                                  );
        aPlanifDuration  := aOPDuration;
      else
-----------------------------------------
-- Si aucune condition n'est remplie alors la dur�e est de 0
-----------------------------------------
        aEndDate  := BeginStartDate;
      end if;
    else
-----------------------------------------
-- Si aucune condition de fabrication n'a �t� trouv� alors la dur�e est de 0
-----------------------------------------
      aEndDate  := BeginStartDate;
    end if;
  end;

  function GetDicComplDataOfSupp(aThirdID number)
    return PAC_SUPPLIER_PARTNER.Dic_Complementary_Data_ID%type
  is
    aDIC_COMPLEMENTARY_DATA_ID PAC_SUPPLIER_PARTNER.Dic_Complementary_Data_ID%type;
  begin
    select DIC_COMPLEMENTARY_DATA_ID
      into aDic_Complementary_Data_ID
      from PAC_SUPPLIER_PARTNER
     where PAC_SUPPLIER_PARTNER_ID = aThirdID;

    return aDic_Complementary_Data_ID;
  exception
    when no_data_found then
      return null;
  end;

  function GetDonnneesCompVente(aGoodID in number, aThirdID in number, aCSA_DISPATCHING_DELAY in out integer, aCSA_DELIVERY_DELAY in out integer)
    return boolean
  is
    -- Curseur pour les d�calages des 3 d�lais des donn�es compl. de vente
    cursor GetComplSale(GoodID GCO_GOOD.GCO_GOOD_ID%type, ThirdID PAC_THIRD.PAC_THIRD_ID%type)
    is
      select   rpad(decode(PAC_CUSTOM_PARTNER_ID, null, '1            ', '0' || to_char(PAC_CUSTOM_PARTNER_ID, '000000000000') ), 13, ' ') order1
             , '1          ' order2
             , nvl(CSA_DISPATCHING_DELAY, 0) INTER_DECALAGE
             , nvl(CSA_DELIVERY_DELAY, -1) FINAL_DECALAGE
          from GCO_COMPL_DATA_SALE
         where GCO_GOOD_ID = GoodID
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_CUSTOM_PARTNER_ID = ThirdID
                or PAC_CUSTOM_PARTNER_ID is null)
      union
      select   '1            ' order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, '1          ', '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , nvl(A.CSA_DISPATCHING_DELAY, 0) INTER_DECALAGE
             , nvl(A.CSA_DELIVERY_DELAY, -1) FINAL_DECALAGE
          from GCO_COMPL_DATA_SALE A
             , PAC_CUSTOM_PARTNER B
         where GCO_GOOD_ID = GoodID
           and A.PAC_CUSTOM_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_CUSTOM_PARTNER_ID = ThirdID
      order by 1
             , 2;

    Tuple_ComplSale GetComplSale%rowtype;
  begin
    aCSA_DISPATCHING_DELAY  := null;
    aCSA_DELIVERY_DELAY     := null;

    -- Curseur sur les donn�es compl de vente pour les d�calages des 3 d�lais
    open GetComplSale(aGoodID, aThirdID);

    fetch GetComplSale
     into Tuple_ComplSale;

    if GetComplSale%found then
      aCSA_DISPATCHING_DELAY  := Tuple_ComplSale.INTER_DECALAGE;
      aCSA_DELIVERY_DELAY     := Tuple_ComplSale.FINAL_DECALAGE;
      return true;
    else
      return true;
    end if;

    close GetComplSale;
  end;

  function GetDonnneesCompAchat(
    aGoodID                      in     number
  , aGoodID2                     in     number
  , aThirdID                     in     number
  , aThirdID2                    in     number
  , aCPU_CONTROL_DELAY           in out integer
  , aCPU_SUPPLY_DELAY            in out integer
  , aCDA_Complementary_Reference in out GCO_COMPL_DATA_PURCHASE.CDA_Complementary_Reference%type
  , aCDA_Short_Description       in out GCO_COMPL_DATA_PURCHASE.CDA_Short_Description%type
  , aCDA_Long_Description        in out GCO_COMPL_DATA_PURCHASE.CDA_Long_Description%type
  , aCDA_Free_Description        in out GCO_COMPL_DATA_PURCHASE.CDA_Free_Description%type
  , aCDA_Complementary_EAN_Code  in out GCO_COMPL_DATA_PURCHASE.CDA_Complementary_EAN_Code%type
  )
    return boolean
  is
    aDic_Complementary_DataOfSupp Dic_Complementary_Data.Dic_Complementary_Data_ID%type;
  begin
    aCPU_CONTROL_DELAY            := null;
    aCPU_SUPPLY_DELAY             := null;
    aCDA_Complementary_Reference  := null;
    aCDA_Short_Description        := null;
    aCDA_Long_Description         := null;
    aCDA_Free_Description         := null;
    aCDA_Complementary_EAN_Code   := null;

    if aThirdID is not null then
      begin
        select CPU_CONTROL_DELAY
             , CPU_SUPPLY_DELAY
             , CDA_Complementary_Reference
             , CDA_Short_Description
             , CDA_Long_Description
             , CDA_Free_Description
             , CDA_Complementary_EAN_Code
          into aCPU_CONTROL_DELAY
             , aCPU_SUPPLY_DELAY
             , aCDA_Complementary_Reference
             , aCDA_Short_Description
             , aCDA_Long_Description
             , aCDA_Free_Description
             , aCDA_Complementary_EAN_Code
          from GCO_COMPL_DATA_PURCHASE
         where Gco_Good_id = aGoodID
           and GCO_GCO_GOOD_ID = aGoodID2
           and PAC_SUPPLIER_PARTNER_ID = aThirdID
           and (    (     (nvl(aThirdID2, 0) <> 0)
                     and (PAC_PAC_SUPPLIER_PARTNER_ID = aThirdID2) )
                or (nvl(aThirdID2, 0) = 0) );

        aCPU_CONTROL_DELAY  := nvl(aCPU_CONTROL_DELAY, 0);
        aCPU_SUPPLY_DELAY   := nvl(aCPU_SUPPLY_DELAY, 0);
        return true;
      -- Exception 1
      exception
        when no_data_found then
          aDic_Complementary_DataOfSupp  := GetDicComplDataOfSupp(aThirdID);

          if aDic_Complementary_DataOfSupp is not null then
            begin
              select CPU_CONTROL_DELAY
                   , CPU_SUPPLY_DELAY
                   , CDA_Complementary_Reference
                   , CDA_Short_Description
                   , CDA_Long_Description
                   , CDA_Free_Description
                   , CDA_Complementary_EAN_Code
                into aCPU_CONTROL_DELAY
                   , aCPU_SUPPLY_DELAY
                   , aCDA_Complementary_Reference
                   , aCDA_Short_Description
                   , aCDA_Long_Description
                   , aCDA_Free_Description
                   , aCDA_Complementary_EAN_Code
                from GCO_COMPL_DATA_PURCHASE
               where Gco_Good_id = aGoodID
                 and DIC_COMPLEMENTARY_DATA_ID = aDic_Complementary_DataOfSupp;

              aCPU_CONTROL_DELAY  := nvl(aCPU_CONTROL_DELAY, 0);
              aCPU_SUPPLY_DELAY   := nvl(aCPU_SUPPLY_DELAY, 0);
              return true;
            -- Exception 2
            exception
              when no_data_found then
                return false;
            -- Fin Exception 2
            end;
          else
            return false;
          end if;
      -- Fin Exception 1
      end;
    else
      return false;
    end if;
  end;

-- G�n�ration des positions de stocks et des approvisionnements pour l'assistant de d�finition des d�lais
  procedure AssistantGeneration(aGoodID in number, aQty in number, aDate in date, aThirdID in number, alstStocksID in varchar2)
  is
    QT                        number;
    TmpQty                    number;
    CmdSQL                    varchar2(32767);
    SQLCursor                 integer;
    Ignore                    integer;
    CurSTM_STOCK_POSITION_ID  number;
    CurSPO_AVAILABLE_QUANTITY number;
    CurSTM_STOCK_ID           number;
    CurSTM_LOCATION_ID        number;
    CurFAL_NETWORK_SUPPLY_ID  number;
    CurFAN_FREE_QTY           number;
    CurFAN_DESCRIPTION        varchar2(50);
    CurFAN_END_PLAN           date;
    X                         integer;
    tmpDate                   date;
    cfgFAL_AST_INIT_QTY       boolean;
    FindDCV                   boolean;
    aCSA_DISPATCHING_DELAY    integer;
    aCSA_DELIVERY_DELAY       integer;
    aDelaiDisponibilite       date;
    aDelaiExpedition          date;
    aDelaiLivraison           date;
    aNewCalendar              integer;
  begin
    -- Initialisation de QT
    QT                   := aQty;
    -- R�cup�ration configuration
    cfgFAL_AST_INIT_QTY  := upper(PCS.PC_CONFIG.GetConfig('FAL_AST_INIT_QTY') ) = 'TRUE';
    FindDCV              := GetDonnneesCompVente(aGoodID, aThirdID, aCSA_DISPATCHING_DELAY, aCSA_DELIVERY_DELAY);
    -- D�termination du d�lai de disponibilit�
    aDelaiDisponibilite  := sysdate;

    -- D�termination du d�lai d''exp�dition
    if FindDCV then
      X                 := aCSA_DISPATCHING_DELAY;
      aDelaiExpedition  :=
        FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(aFal_factory_floor_id      => null
                                                    , aPac_supplier_partner_id   => null
                                                    , aPac_custom_partner_id     => aThirdID
                                                    , aPAC_DEPARTMENT_ID         => null
                                                    , aHrm_person_id             => null
                                                    , aCalendarId                => null
                                                    , aFromDate                  => sysdate
                                                    , aDecalage                  => X
                                                     );
    else
      aDelaiExpedition  := sysdate;
    end if;

    -- D�termination du d�lai de livraison
    if FindDCV then
      X                := aCSA_DELIVERY_DELAY;
      aDelaiLivraison  :=
        FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(aFal_factory_floor_id      => null
                                                    , aPac_supplier_partner_id   => null
                                                    , aPac_custom_partner_id     => aThirdID
                                                    , aPAC_DEPARTMENT_ID         => null
                                                    , aHrm_person_id             => null
                                                    , aCalendarId                => null
                                                    , aFromDate                  => aDelaiExpedition
                                                    , aDecalage                  => X
                                                     );
    else
      if nvl(aThirdId, 0) <> 0 then
        select CUS_DELIVERY_DELAY
          into X
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = aThirdId;

        if nvl(X, 0) <> 0 then
          aDelaiLivraison  :=
            FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(aFal_factory_floor_id      => null
                                                        , aPac_supplier_partner_id   => null
                                                        , aPac_custom_partner_id     => aThirdID
                                                        , aPAC_DEPARTMENT_ID         => null
                                                        , aHrm_person_id             => null
                                                        , aCalendarId                => null
                                                        , aFromDate                  => aDelaiExpedition
                                                        , aDecalage                  => X
                                                         );
        else
          aDelaiLivraison  := aDelaiExpedition;
        end if;
      else
        aDelaiLivraison  := sysdate;
      end if;
    end if;

    ---------------------------------------------------------------------------------------
-- G�n�ration pour les positions de stocks
---------------------------------------------------------------------------------------
    CmdSQL               := ' SELECT STM_STOCK_POSITION_ID,SPO_AVAILABLE_QUANTITY,STM_STOCK_ID,STM_LOCATION_ID';
    CmdSQL               := CmdSQL || ' FROM   STM_STOCK_POSITION';
    CmdSQL               := CmdSQL || ' WHERE  GCO_GOOD_ID = ' || to_char(aGoodID);
    CmdSQL               := CmdSQL || ' AND    SPO_AVAILABLE_QUANTITY > 0';
    CmdSQL               := CmdSQL || ' AND ' || alstStocksID;
    SQLCursor            := DBMS_SQL.Open_Cursor;
    DBMS_SQL.Parse(SQLCursor, CmdSQL, DBMS_SQL.Native);
    DBMS_SQL.Define_Column(SQLCursor, 1, CurSTM_STOCK_POSITION_ID);
    DBMS_SQL.Define_Column(SQLCursor, 2, CurSPO_AVAILABLE_QUANTITY);
    DBMS_SQL.Define_Column(SQLCursor, 3, CurSTM_STOCK_ID);
    DBMS_SQL.Define_Column(SQLCursor, 4, CurSTM_LOCATION_ID);
    Ignore               := DBMS_SQL.execute(SQLCursor);

    begin
      loop
        if (DBMS_SQL.Fetch_Rows(SQLCursor) > 0) then
          DBMS_SQL.column_value(SQLCursor, 1, CurSTM_STOCK_POSITION_ID);
          DBMS_SQL.column_value(SQLCursor, 2, CurSPO_AVAILABLE_QUANTITY);
          DBMS_SQL.column_value(SQLCursor, 3, CurSTM_STOCK_ID);
          DBMS_SQL.column_value(SQLCursor, 4, CurSTM_LOCATION_ID);

          -- D�termination de la quantit� command�e
          if     cfgFAL_AST_INIT_QTY
             and (QT > 0) then
            if QT >= CurSPO_AVAILABLE_QUANTITY then
              TmpQty  := CurSPO_AVAILABLE_QUANTITY;
              QT      := QT - CurSPO_AVAILABLE_QUANTITY;
            else
              TmpQty  := QT;
              QT      := 0;
            end if;
          else
            TmpQty  := 0;
          end if;

          -- Cr�ation de l'enregistrement stock
          insert into FAL_DAD_STOCK
                      (FAL_DAD_STOCK_ID
                     , FST_USER_CODE
                     , FST_SESSION
                     , STM_STOCK_POSITION_ID
                     , STM_STOCK_ID
                     , STM_LOCATION_ID
                     , FST_AVAILABLE_QTY
                     , FST_ORDERED_QTY
                     , FST_DISPATCH_DELAY   -- D�lai de livraison
                     , FST_EXPEDITION_DELAY   -- D�lai d'exp�dition
                     , FST_AVALAIBLE_DELAY   -- D�lai de disponibilit�
                      )
               values (GetNewId
                     , 0
                     , DBMS_SESSION.unique_session_id
                     , CurSTM_STOCK_POSITION_ID
                     , CurSTM_STOCK_ID
                     , CurSTM_LOCATION_ID
                     , CurSPO_AVAILABLE_QUANTITY
                     , TmpQty
                     , aDelaiLivraison   -- D�lai de livraison
                     , aDelaiExpedition   -- D�lai d'exp�dition
                     , aDelaiDisponibilite   -- D�lai de disponibilit�
                      );
        else
          exit;
        end if;
      end loop;

      DBMS_SQL.Close_Cursor(SQLCursor);
    exception
      when others then
        DBMS_SQL.Close_Cursor(SQLCursor);
        raise;
    end;

---------------------------------------------------------------------------------------
-- G�n�ration pour les appros
---------------------------------------------------------------------------------------
    CmdSQL               := ' SELECT FAL_NETWORK_SUPPLY_ID,FAN_FREE_QTY,FAN_DESCRIPTION,STM_STOCK_ID,STM_LOCATION_ID,FAN_END_PLAN';
    CmdSQL               := CmdSQL || ' FROM   FAL_NETWORK_SUPPLY';
    CmdSQL               := CmdSQL || ' WHERE  GCO_GOOD_ID = ' || to_char(aGoodID);
    CmdSQL               := CmdSQL || ' AND    FAN_FREE_QTY > 0';
    CmdSQL               := CmdSQL || ' AND ' || alstStocksID;
    SQLCursor            := DBMS_SQL.Open_Cursor;
    DBMS_SQL.Parse(SQLCursor, CmdSQL, DBMS_SQL.Native);
    DBMS_SQL.Define_Column(SQLCursor, 1, CurFAL_NETWORK_SUPPLY_ID);
    DBMS_SQL.Define_Column(SQLCursor, 2, CurFAN_FREE_QTY);
    DBMS_SQL.Define_Column(SQLCursor, 3, CurFAN_DESCRIPTION, 50);
    DBMS_SQL.Define_Column(SQLCursor, 4, CurSTM_STOCK_ID);
    DBMS_SQL.Define_Column(SQLCursor, 5, CurSTM_LOCATION_ID);
    DBMS_SQL.Define_Column(SQLCursor, 6, CurFAN_END_PLAN);
    Ignore               := DBMS_SQL.execute(SQLCursor);

    begin
      loop
        if (DBMS_SQL.Fetch_Rows(SQLCursor) > 0) then
          DBMS_SQL.column_value(SQLCursor, 1, CurFAL_NETWORK_SUPPLY_ID);
          DBMS_SQL.column_value(SQLCursor, 2, CurFAN_FREE_QTY);
          DBMS_SQL.column_value(SQLCursor, 3, CurFAN_DESCRIPTION);
          DBMS_SQL.column_value(SQLCursor, 4, CurSTM_STOCK_ID);
          DBMS_SQL.column_value(SQLCursor, 5, CurSTM_LOCATION_ID);
          DBMS_SQL.column_value(SQLCursor, 6, CurFAN_END_PLAN);

          -- D�termination de la quantit� command�e
          if     cfgFAL_AST_INIT_QTY
             and (QT > 0) then
            if QT >= CurFAN_FREE_QTY then
              TmpQty  := CurFAN_FREE_QTY;
              QT      := QT - CurFAN_FREE_QTY;
            else
              TmpQty  := QT;
              QT      := 0;
            end if;
          else
            TmpQty  := 0;
          end if;

          -- V�rification que la date de dispo n'est pas inf�rieur � la date du jour
          if trunc(CurFAN_END_PLAN) < trunc(sysdate) then
            tmpDate  := trunc(sysdate);
          else
            tmpDate  := trunc(CurFAN_END_PLAN);
          end if;

          -- D�termination du d�lai de disponibilit�
          aDelaiDisponibilite  := greatest(CurFAN_END_PLAN, sysdate);

          -- D�termination du d�lai d''exp�dition
          if FindDCV then
            X                 := aCSA_DISPATCHING_DELAY;
            aDelaiExpedition  :=
              FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(aFal_factory_floor_id      => null
                                                          , aPac_supplier_partner_id   => null
                                                          , aPac_custom_partner_id     => aThirdID
                                                          , aPAC_DEPARTMENT_ID         => null
                                                          , aHrm_person_id             => null
                                                          , aCalendarId                => null
                                                          , aFromDate                  => greatest(aDelaiDisponibilite, sysdate)
                                                          , aDecalage                  => X
                                                           );
          else
            aDelaiExpedition  := greatest(aDelaiDisponibilite, sysdate);
          end if;

          -- D�termination du d�lai de livraison
          if FindDCV then
            X                := aCSA_DELIVERY_DELAY;
            aDelaiLivraison  :=
              FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(aFal_factory_floor_id      => null
                                                          , aPac_supplier_partner_id   => null
                                                          , aPac_custom_partner_id     => aThirdID
                                                          , aPAC_DEPARTMENT_ID         => null
                                                          , aHrm_person_id             => null
                                                          , aCalendarId                => null
                                                          , aFromDate                  => aDelaiExpedition
                                                          , aDecalage                  => X
                                                           );
          else
            if nvl(aThirdId, 0) <> 0 then
              select CUS_DELIVERY_DELAY
                into X
                from PAC_CUSTOM_PARTNER
               where PAC_CUSTOM_PARTNER_ID = aThirdId;

              if nvl(X, 0) <> 0 then
                aDelaiLivraison  :=
                  FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(aFal_factory_floor_id      => null
                                                              , aPac_supplier_partner_id   => null
                                                              , aPac_custom_partner_id     => aThirdID
                                                              , aPAC_DEPARTMENT_ID         => null
                                                              , aHrm_person_id             => null
                                                              , aCalendarId                => null
                                                              , aFromDate                  => aDelaiExpedition
                                                              , aDecalage                  => X
                                                               );
              else
                aDelaiLivraison  := aDelaiExpedition;
              end if;
            else
              aDelaiLivraison  := aDelaiDisponibilite;
            end if;
          end if;

          -- Cr�ation de l'enregistrement appro
          insert into FAL_DAD_SUPPLY
                      (FAL_DAD_SUPPLY_ID
                     , FSU_USER_CODE
                     , FSU_SESSION
                     , FAL_NETWORK_SUPPLY_ID
                     , STM_STOCK_ID
                     , STM_LOCATION_ID
                     , FSU_AVAILABLE_QTY
                     , FSU_ORDERED_QTY
                     , FSU_AVAILABLE_DELAY   -- D�lai de disponibilit�
                     , FSU_DISPATCH_DELAY   -- D�lai de livraison
                     , FSU_EXPEDITION_DELAY   -- D�lai d'exp�dition
                     , FSU_DESCRIPTION
                      )
               values (GetNewId
                     , 0
                     , DBMS_SESSION.unique_session_id
                     , CurFAL_NETWORK_SUPPLY_ID
                     , CurSTM_STOCK_ID
                     , CurSTM_LOCATION_ID
                     , CurFAN_FREE_QTY
                     , TmpQty
                     , aDelaiDisponibilite   -- D�lai de disponibilit�
                     , aDelaiLivraison   -- D�lai de livraison
                     , aDelaiExpedition   -- D�lai d'exp�dition
                     , CurFAN_DESCRIPTION
                      );
        else
          exit;
        end if;
      end loop;

      DBMS_SQL.Close_Cursor(SQLCursor);
    exception
      when others then
        DBMS_SQL.Close_Cursor(SQLCursor);
        raise;
    end;
  end;

  /**
  * proc�dure PurgeComponentLink
  * Description
  *   Suppression des enregistrements des tables FAL_DAD_STOCK et FAL_DAD_SUPPLY
  * @created CLE
  * @lastUpdate
  * @public
  */
  procedure ResetDelayAssistantTables
  is
    cursor crOracleSession
    is
      select distinct FST_SESSION
                 from FAL_DAD_STOCK
      union
      select distinct FSU_SESSION
                 from FAL_DAD_SUPPLY;
  begin
    -- Suppression des enregistrements de la session active
    delete from FAL_DAD_STOCK
          where FST_SESSION = DBMS_SESSION.unique_session_id;

    delete from FAL_DAD_SUPPLY
          where FSU_SESSION = DBMS_SESSION.unique_session_id;

    -- Suppression des enregistrements de sessions obsol�tes
    for tplOracleSession in crOracleSession loop
      if COM_FUNCTIONS.Is_Session_Alive(tplOracleSession.FST_SESSION) = 0 then
        delete from FAL_DAD_STOCK
              where FST_SESSION = tplOracleSession.FST_SESSION;

        delete from FAL_DAD_SUPPLY
              where FSU_SESSION = tplOracleSession.FST_SESSION;
      end if;
    end loop;
  end;
end;
