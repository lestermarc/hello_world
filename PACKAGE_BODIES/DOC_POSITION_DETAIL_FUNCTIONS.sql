--------------------------------------------------------
--  DDL for Package Body DOC_POSITION_DETAIL_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_POSITION_DETAIL_FUNCTIONS" 
is
  /**
  * Description : Initialise les 3 délais du détail de position
  */
  procedure InitializePDEDelay(
    aShowDelay           in     integer
  , aPosDelay            in     integer
  , aCopyPrevDelay       in     integer
  , aThirdID             in     PAC_THIRD.PAC_THIRD_ID%type
  , aGoodID              in     GCO_GOOD.GCO_GOOD_ID%type
  , aStockID             in     DOC_POSITION.STM_STOCK_ID%type
  , aTargetStockID       in     DOC_POSITION.STM_STM_STOCK_ID%type
  , aAdminDomain         in     integer
  , aGaugeType           in     integer
  , aTransfertProprietor in     DOC_GAUGE_POSITION.GAP_TRANSFERT_PROPRIETOR%type
  , aBasisDelay          in out DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type
  , aInterDelay          in out DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type
  , aFinalDelay          in out DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type
  , iComplDataId         in     GCO_COMPL_DATA_SUBCONTRACT.GCO_COMPL_DATA_SUBCONTRACT_ID%type default null
  , iQuantity            in     DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type default null
  , iScheduleStepId      in     DOC_POSITION_DETAIL.FAL_SCHEDULE_STEP_ID%type default null
  )
  is
    -- Curseur pour les décalages des 3 délais des données compl. d'achat
    cursor crCDAPurchase(cGoodID GCO_GOOD.GCO_GOOD_ID%type, cThirdID PAC_THIRD.PAC_THIRD_ID%type)
    is
      select   rpad(decode(PAC_SUPPLIER_PARTNER_ID, null, rpad('1', 13, ' '), '0' || to_char(PAC_SUPPLIER_PARTNER_ID, '000000000000') ), 13, ' ') order1
             , rpad('1', 11, ' ') order2
             , 0 BASIS_DECALAGE
             , CPU_SUPPLY_DELAY INTER_DECALAGE
             , CPU_CONTROL_DELAY FINAL_DECALAGE
          from GCO_COMPL_DATA_PURCHASE
         where GCO_GOOD_ID = cGoodID
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_SUPPLIER_PARTNER_ID = cThirdID
                or PAC_SUPPLIER_PARTNER_ID is null)
      union
      select   rpad('1', 13, ' ') order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, rpad('1', 11, ' '), '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , 0 BASIS_DECALAGE
             , A.CPU_SUPPLY_DELAY INTER_DECALAGE
             , A.CPU_CONTROL_DELAY FINAL_DECALAGE
          from GCO_COMPL_DATA_PURCHASE A
             , PAC_SUPPLIER_PARTNER B
         where GCO_GOOD_ID = cGoodID
           and A.PAC_SUPPLIER_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_SUPPLIER_PARTNER_ID = cThirdID
      order by 1
             , 2;

    -- Curseur pour les décalages des 3 délais des données compl. de vente
    cursor crCDASale(cGoodID GCO_GOOD.GCO_GOOD_ID%type, cThirdID PAC_THIRD.PAC_THIRD_ID%type)
    is
      select   rpad(decode(PAC_CUSTOM_PARTNER_ID, null, rpad('1', 13, ' '), '0' || to_char(PAC_CUSTOM_PARTNER_ID, '000000000000') ), 13, ' ') order1
             , rpad('1', 11, ' ') order2
             , CSA_TH_SUPPLY_DELAY BASIS_DECALAGE
             , CSA_DISPATCHING_DELAY INTER_DECALAGE
             , CSA_DELIVERY_DELAY FINAL_DECALAGE
          from GCO_COMPL_DATA_SALE
         where GCO_GOOD_ID = cGoodID
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_CUSTOM_PARTNER_ID = cThirdID
                or PAC_CUSTOM_PARTNER_ID is null)
      union
      select   rpad('1', 13, ' ') order1
             , decode(CSA.DIC_COMPLEMENTARY_DATA_ID, null, rpad('1', 11, ' '), '0' || rpad(CSA.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , CSA.CSA_TH_SUPPLY_DELAY BASIS_DECALAGE
             , CSA.CSA_DISPATCHING_DELAY INTER_DECALAGE
             , CSA.CSA_DELIVERY_DELAY FINAL_DECALAGE
          from GCO_COMPL_DATA_SALE CSA
             , PAC_CUSTOM_PARTNER CUS
         where GCO_GOOD_ID = cGoodID
           and CSA.PAC_CUSTOM_PARTNER_ID is null
           and CSA.DIC_COMPLEMENTARY_DATA_ID = CUS.DIC_COMPLEMENTARY_DATA_ID
           and CUS.PAC_CUSTOM_PARTNER_ID = cThirdID
      order by 1
             , 2;

    -- Curseur pour les décalages des 3 délais des données compl. de sous-traitance
    cursor crCDASubcontract(
      cComplDataId GCO_COMPL_DATA_SUBCONTRACT.GCO_COMPL_DATA_SUBCONTRACT_ID%type
    , cQuantity    DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type
    )
    is
      select 0 BASIS_DECALAGE
           , CSU_CONTROL_DELAY
           , CSU_SUBCONTRACTING_DELAY
           , CSU_ECONOMICAL_QUANTITY
           , CSU_FIX_DELAY
           , CSU_LOT_QUANTITY
        from GCO_COMPL_DATA_SUBCONTRACT
       where GCO_COMPL_DATA_SUBCONTRACT_ID = cComplDataId;

    tplCDAPurchase            crCDAPurchase%rowtype;
    tplCDASale                crCDASale%rowtype;
    tplCDASubcontract         crCDASubcontract%rowtype;
    --
    vCfg_DOC_THREE_DELAY      integer;
    vCfg_DOC_DELAY_WEEKSTART  integer;
    vCfg_PAC_USE_PAC_SCHEDULE integer;
    vCfg_STM_PROPRIETOR       integer;
    --
    vBasisDecalage            integer;
    vInterDecalage            integer;
    vFinalDecalage            integer;
    --
    vDelay                    date;
    vDelayMW                  varchar2(7);
    --
    vBasisDelayMW             varchar2(7);
    vInterDelayMW             varchar2(7);
    vFinalDelayMW             varchar2(7);
    --
    vSearchThirdCalendar      integer;
    vSearchFinalThirdCalendar integer;
    vScheduleID               PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    vThirdScheduleID          PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    vDefaultScheduleID        PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    vThirdFilter              varchar(30);
    vThirdFilterID            PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    vScheduleFilter           varchar(30);
    vScheduleFilterID         PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
  begin
    -- Recherche des configs
    select to_number(nvl(PCS.PC_CONFIG.GetConfig('DOC_THREE_DELAY'), '0') )
         , to_number(nvl(PCS.PC_CONFIG.GetConfig('DOC_DELAY_WEEKSTART'), '2') )
         , to_number(nvl(PCS.PC_CONFIG.GetConfig('PAC_USE_PAC_SCHEDULE'), '0') )
         , to_number(nvl(PCS.PC_CONFIG.GETCONFIG('STM_PROPRIETOR'), '0') )
      into vCfg_DOC_THREE_DELAY
         , vCfg_DOC_DELAY_WEEKSTART
         , vCfg_PAC_USE_PAC_SCHEDULE
         , vCfg_STM_PROPRIETOR
      from dual;

    -- Reprendre les délais de la position précédente si existants
    if     (aCopyPrevDelay = 1)
       and (aBasisDelay is not null) then
      aInterDelay  := nvl(aInterDelay, aBasisDelay);
      aFinalDelay  := nvl(aFinalDelay, aInterDelay);
    else
      -- Nouvelle Gestion des calendriers = oui
      if vCfg_PAC_USE_PAC_SCHEDULE = 1 then
        -- Rechercher le calendrier par défaut
        vDefaultScheduleID  := PAC_I_LIB_SCHEDULE.GetDefaultSchedule;
        -- Calendrier du tiers
        PAC_I_LIB_SCHEDULE.GetLogisticThirdSchedule(iThirdID       => aThirdID
                                                  , iAdminDomain   => aAdminDomain
                                                  , oScheduleID    => vThirdScheduleID
                                                  , oFilter        => vThirdFilter
                                                  , oFilterID      => vThirdFilterID
                                                   );

        -- Si pas trouvé de calendrier au niveau du tiers, utiliser le calendrier par défaut
        if vThirdScheduleID is null then
          vThirdScheduleID  := vDefaultScheduleID;
        end if;

        -- Message d'erreur, si pas trouvé de calendrier
        if nvl(vThirdScheduleID, vDefaultScheduleID) is null then
          raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('Il n''y a pas de calendrier par défaut!') );
        end if;
      end if;

      -- Gestion des 3 délais de façon DISTINCTE
      if vCfg_DOC_THREE_DELAY = 1 then
        -- Recherche des 3 délais

        -- Domaine "Stock" ET "Transfert stock propr." ET config "Stock propriétaire" = 1
        -- Ne pas utiliser le calendrier du tiers
        -- Domaine "Vente" et type "Besoin", Ne pas utiliser le calendrier du tiers pour le délai de base
        if    (     (aAdminDomain = 2)
               and (aGaugeType = 1) )
           or (     (aAdminDomain = 3)
               and (aTransfertProprietor = 1)
               and (vCfg_STM_PROPRIETOR = 1) ) then
          vSearchThirdCalendar  := 0;
          vScheduleID           := vDefaultScheduleID;
          vScheduleFilter       := null;
          vScheduleFilterID     := null;
        else
          vSearchThirdCalendar  := 1;
          vScheduleID           := vThirdScheduleID;
          vScheduleFilter       := vThirdFilter;
          vScheduleFilterID     := vThirdFilterID;
        end if;

        -- Recherche de tous les décalages
        -- Domaine "Achat" et Type "Appro" hors sous-traitance opératoire
        if     (aAdminDomain = 1)
           and (aGaugeType = 2)
           and (iScheduleStepId is null) then
          -- Curseur sur les données compl d'achat pour les décalages des 3 délais
          open crCDAPurchase(aGoodID, aThirdID);

          fetch crCDAPurchase
           into tplCDAPurchase;

          close crCDAPurchase;

          vBasisDecalage  := nvl(tplCDAPurchase.BASIS_DECALAGE, 0);
          vInterDecalage  := nvl(tplCDAPurchase.INTER_DECALAGE, 0);
          vFinalDecalage  := nvl(tplCDAPurchase.FINAL_DECALAGE, 0);

          -- Recherche de la durée d'appro au niveau du fournisseur si pas existant au niveau compl. du bien
          if tplCDAPurchase.INTER_DECALAGE is null then
            select nvl(max(CRE_SUPPLY_DELAY), 0)
              into vInterDecalage
              from PAC_SUPPLIER_PARTNER
             where PAC_SUPPLIER_PARTNER_ID = aThirdID;
          end if;
        -- Domaine "Achat" et type "Besoin" pour commande sous-traitance opératoire
        elsif     (aAdminDomain = 1)
              and (aGaugeType = 2)
              and (iScheduleStepId is not null) then
          vBasisDecalage  := 0;
          vInterDecalage  := FAL_I_LIB_SUBCONTRACTO.getTaskDuration(iScheduleStepId);
          vFinalDecalage  := 0;
        -- Domaine "Vente" et type "Besoin"
        elsif     (aAdminDomain = 2)
              and (aGaugeType = 1) then
          -- Curseur sur les données compl de vente pour les décalages des 3 délais
          open crCDASale(aGoodID, aThirdID);

          fetch crCDASale
           into tplCDASale;

          close crCDASale;

          vBasisDecalage  := nvl(tplCDASale.BASIS_DECALAGE, 0);
          vInterDecalage  := nvl(tplCDASale.INTER_DECALAGE, 0);
          vFinalDecalage  := nvl(tplCDASale.FINAL_DECALAGE, 0);

          -- Recherche de la durée de livraison au niveau du client si pas existant au niveau compl. du bien
          if tplCDASale.FINAL_DECALAGE is null then
            select nvl(max(CUS_DELIVERY_DELAY), 0)
              into vFinalDecalage
              from PAC_CUSTOM_PARTNER
             where PAC_CUSTOM_PARTNER_ID = aThirdID;
          end if;
        -- Recherche de tous les décalages
        -- Domaine "Sous-traitance" et Type "Appro"
        elsif     (aAdminDomain = cAdminDomainSubContract)
              and (aGaugeType = 2)
              and iComplDataId is not null then
          -- Curseur sur les données compl de sous-traitance pour les décalages des 3 délais
          open crCDASubcontract(iComplDataId, iQuantity);

          fetch crCDASubcontract
           into tplCDASubcontract;

          -- Calcul les déclalages des 3 délais en fonction des données complémentaires de sous-traitance (sous-traitance d'achat).
          DOC_LIB_SUBCONTRACTP.getSUPOLags(tplCDASubcontract.CSU_CONTROL_DELAY
                                         , tplCDASubcontract.CSU_SUBCONTRACTING_DELAY
                                         , tplCDASubcontract.CSU_ECONOMICAL_QUANTITY
                                         , tplCDASubcontract.CSU_FIX_DELAY
                                         , tplCDASubcontract.CSU_LOT_QUANTITY
                                         , iQuantity
                                         , vBasisDecalage
                                         , vInterDecalage
                                         , vFinalDecalage
                                          );

          close crCDASubcontract;
        -- Domaine "Stock" ET "Transfert stock propr." ET config "Stock propriétaire" = 1
        elsif     (aAdminDomain = cAdminDomainStock)
              and (aTransfertProprietor = 1)
              and (vCfg_STM_PROPRIETOR = 1) then
          vBasisDecalage  := 0;
          vInterDecalage  := 0;

          -- Recherche le décalage pour le délai final sur la
          -- donnée compl. de stock du stock propriétaire
          select nvl(nvl(CST_1.CST_TRANSFERT_DELAY, CST_2.CST_TRANSFERT_DELAY), 0) FINAL_DECALAGE
            into vFinalDecalage
            from (select max(CST_TRANSFERT_DELAY) CST_TRANSFERT_DELAY
                    from GCO_COMPL_DATA_STOCK
                   where GCO_GOOD_ID = aGoodID
                     and STM_STOCK_ID = aTargetStockID) CST_1
               , (select max(CST_TRANSFERT_DELAY) CST_TRANSFERT_DELAY
                    from GCO_COMPL_DATA_STOCK
                   where GCO_GOOD_ID = aGoodID
                     and STM_STOCK_ID = aStockID) CST_2;
        -- Autre domaine
        else
          vBasisDecalage  := 0;
          vInterDecalage  := 0;
          vFinalDecalage  := 0;
        end if;

        -- Délai de base
        aBasisDelay  :=
          DOC_DELAY_FUNCTIONS.GetShiftOpenDate(aDate                  => trunc(sysdate)
                                             , aCalcDays              => vBasisDecalage
                                             , aCfgUsePacSchedule     => vCfg_PAC_USE_PAC_SCHEDULE
                                             , aAdminDomain           => aAdminDomain
                                             , aThirdID               => aThirdID
                                             , aForward               => 1
                                             , aSearchThirdCalendar   => vSearchThirdCalendar
                                             , aScheduleID            => vScheduleID
                                             , aScheduleFilter        => vScheduleFilter
                                             , aScheduleFilterID      => vScheduleFilterID
                                              );

        -- Présentation des délais en semaines
        if aShowDelay = 2 then
          -- Ajustement au bon jour de la semaine du Délai de base
          vDelayMW     := DOC_DELAY_FUNCTIONS.DateToWeekNumber(aDate => aBasisDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
          aBasisDelay  := DOC_DELAY_FUNCTIONS.WeekNumberToDate(aWeek => vDelayMW, aDay => aPosDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);

          -- On ne permet pas qu' à l'initilaisation le délai soit inférieur à la date du jour
          if aBasisDelay < trunc(sysdate) then
            -- Délai de base
            aBasisDelay  :=
              DOC_DELAY_FUNCTIONS.GetShiftOpenDate(aDate                  => aBasisDelay + 7
                                                 , aCalcDays              => 0
                                                 , aCfgUsePacSchedule     => vCfg_PAC_USE_PAC_SCHEDULE
                                                 , aAdminDomain           => aAdminDomain
                                                 , aThirdID               => aThirdID
                                                 , aForward               => 1
                                                 , aSearchThirdCalendar   => vSearchThirdCalendar
                                                 , aScheduleID            => vScheduleID
                                                 , aScheduleFilter        => vScheduleFilter
                                                 , aScheduleFilterID      => vScheduleFilterID
                                                  );
            -- Ajustement au bon jour de la semaine du Délai de base
            vDelayMW     := DOC_DELAY_FUNCTIONS.DateToWeekNumber(aDate => aBasisDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
            aBasisDelay  := DOC_DELAY_FUNCTIONS.WeekNumberToDate(aWeek => vDelayMW, aDay => aPosDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
          end if;
        -- Présentation des délais en mois
        elsif aShowDelay = 3 then
          vDelayMW     := DOC_DELAY_FUNCTIONS.DateToMonth(aDate => aBasisDelay);
          aBasisDelay  :=
            DOC_DELAY_FUNCTIONS.MonthToDate(aMonthDate            => vDelayMW
                                          , aPosDelay             => aPosDelay
                                          , aThirdID              => aThirdID
                                          , aAdminDomain          => aAdminDomain
                                          , SearchThirdCalendar   => vSearchThirdCalendar
                                           );
        end if;

        -- Domaine "Stock" ET "Transfert stock propr." ET config "Stock propriétaire" = 1
        -- Ne pas utiliser le calendrier du tiers
        if     (aAdminDomain = 3)
           and (aTransfertProprietor = 1)
           and (vCfg_STM_PROPRIETOR = 1) then
          vSearchThirdCalendar  := 0;
          vScheduleID           := vDefaultScheduleID;
          vScheduleFilter       := null;
          vScheduleFilterID     := null;
        else
          vSearchThirdCalendar  := 1;
          vScheduleID           := vThirdScheduleID;
          vScheduleFilter       := vThirdFilter;
          vScheduleFilterID     := vThirdFilterID;
        end if;

        -- Délai intermédiaire
        aInterDelay  :=
          DOC_DELAY_FUNCTIONS.GetShiftOpenDate(aDate                  => aBasisDelay
                                             , aCalcDays              => vInterDecalage
                                             , aCfgUsePacSchedule     => vCfg_PAC_USE_PAC_SCHEDULE
                                             , aAdminDomain           => aAdminDomain
                                             , aThirdID               => aThirdID
                                             , aForward               => 1
                                             , aSearchThirdCalendar   => vSearchThirdCalendar
                                             , aScheduleID            => vScheduleID
                                             , aScheduleFilter        => vScheduleFilter
                                             , aScheduleFilterID      => vScheduleFilterID
                                              );

        ----
        -- Délai final
        -- Dans le domaine achat, il ne faut pas utiliser le calendrier du tiers pour calculer le délai de disponibilité (final) mais
        -- mais le calendrier par défaut.
        --
        -- Situation avant correction
        --
        --   * En achat, les délais suivants sont gérés :
        --     o Délai de commande
        --     o Délai de réception : délai de commande + durée d'approvisionnement selon calendrier du fournisseur ou calendrier par défaut
        --     o Délai de disponibilité : délai de réception + durée de contrôle selon calendrier du fournisseur ou calendrier par défaut
        --
        -- Problème
        --
        --   * Le contrôle étant généralement effectué par l'entreprise et non par le fournisseur, il est faux de tenir compte du
        --     calendrier du fournisseur pour calculer le délai de disponibilité.
        --   * Exemple :
        --     Si le fournisseur me livre aujourd'hui un article nécessitant un contrôle de 5 jours et que le fournisseur est en vacances
        --     dès demain, partant du principe que mon entreprise est ouverte, je ne pourrai disposer de la marchandise que dans 10 jours
        --     (5 jours fermé du fournisseur selon son calendrier + 5 jours de contrôle).
        --
        -- Conclusion
        --
        --   * Utiliser le calendrier du fournisseur pour le calcul du délai de réception
        --   * Utiliser le calendrier par défaut pour le calcul du délai de disponbilité
        --   * SAUF pour les commandes de sous-traitance opératoire où la notion de disponibilité n'est pas gérée.
        --
        if    (aAdminDomain = 1)
           or     (aAdminDomain = cAdminDomainSubContract)
              and not(     (aAdminDomain = 1)
                      and (aGaugeType = 2)
                      and (iScheduleStepId is not null) ) then
          -- Domaine "Achat" et type "Besoin" pour commande sous-traitance opératoire
          vSearchFinalThirdCalendar  := 0;
          vScheduleID                := vDefaultScheduleID;
          vScheduleFilter            := null;
          vScheduleFilterID          := null;
        else
          vSearchFinalThirdCalendar  := vSearchThirdCalendar;
        end if;

        aFinalDelay  :=
          DOC_DELAY_FUNCTIONS.GetShiftOpenDate(aDate                  => aInterDelay
                                             , aCalcDays              => vFinalDecalage
                                             , aCfgUsePacSchedule     => vCfg_PAC_USE_PAC_SCHEDULE
                                             , aAdminDomain           => aAdminDomain
                                             , aThirdID               => aThirdID
                                             , aForward               => 1
                                             , aSearchThirdCalendar   => vSearchFinalThirdCalendar
                                             , aScheduleID            => vScheduleID
                                             , aScheduleFilter        => vScheduleFilter
                                             , aScheduleFilterID      => vScheduleFilterID
                                              );

        -- Présentation des délais en semaines
        if aShowDelay = 2 then
          -- Ajustement au bon jour de la semaine du délai
          -- Délai intermédiaire
          vDelayMW     := DOC_DELAY_FUNCTIONS.DateToWeekNumber(aDate => aInterDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
          aInterDelay  := DOC_DELAY_FUNCTIONS.WeekNumberToDate(aWeek => vDelayMW, aDay => aPosDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
          -- Délai final
          vDelayMW     := DOC_DELAY_FUNCTIONS.DateToWeekNumber(aDate => aFinalDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
          aFinalDelay  := DOC_DELAY_FUNCTIONS.WeekNumberToDate(aWeek => vDelayMW, aDay => aPosDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
        -- Présentation des délais en mois
        elsif aShowDelay = 3 then
          -- Délai intermédiaire
          vDelayMW     := DOC_DELAY_FUNCTIONS.DateToMonth(aDate => aInterDelay);
          aInterDelay  :=
            DOC_DELAY_FUNCTIONS.MonthToDate(aMonthDate            => vDelayMW
                                          , aPosDelay             => aPosDelay
                                          , aThirdID              => aThirdID
                                          , aAdminDomain          => aAdminDomain
                                          , SearchThirdCalendar   => vSearchThirdCalendar
                                           );
          -- Délai final
          vDelayMW     := DOC_DELAY_FUNCTIONS.DateToMonth(aDate => aFinalDelay);
          aFinalDelay  :=
            DOC_DELAY_FUNCTIONS.MonthToDate(aMonthDate            => vDelayMW
                                          , aPosDelay             => aPosDelay
                                          , aThirdID              => aThirdID
                                          , aAdminDomain          => aAdminDomain
                                          , SearchThirdCalendar   => vSearchFinalThirdCalendar
                                           );
        end if;
      else
        -- Gestion des 3 délais de façon UNIQUE -> DOC_THREE_DELAY = 0

        -- Domaine "Achat"
        if aAdminDomain = 1 then
          -- Curseur sur les données compl d'achat pour les décalages
          open crCDAPurchase(aGoodID, aThirdID);

          fetch crCDAPurchase
           into tplCDAPurchase;

          close crCDAPurchase;

          -- Paramètres pour la rechercher des délais
          vBasisDecalage        := nvl(tplCDAPurchase.INTER_DECALAGE, 0) + nvl(tplCDAPurchase.FINAL_DECALAGE, 0);
          vSearchThirdCalendar  := 1;
          vScheduleID           := vThirdScheduleID;
          vScheduleFilter       := vThirdFilter;
          vScheduleFilterID     := vThirdFilterID;
        -- Domaine "Vente"
        elsif aAdminDomain = 2 then
          -- Curseur sur les données compl de vente pour les décalages des 3 délais
          open crCDASale(aGoodID, aThirdID);

          fetch crCDASale
           into tplCDASale;

          close crCDASale;

          -- Paramètres pour la rechercher des délais
          vBasisDecalage        := nvl(tplCDASale.FINAL_DECALAGE, 0);
          vSearchThirdCalendar  := 0;
          vScheduleID           := vDefaultScheduleID;
          vScheduleFilter       := null;
          vScheduleFilterID     := null;
        -- Autre domaine
        else
          -- Paramètres pour la rechercher des délais
          vBasisDecalage        := 0;
          vSearchThirdCalendar  := 0;
          vScheduleID           := vThirdScheduleID;
          vScheduleFilter       := vThirdFilter;
          vScheduleFilterID     := vThirdFilterID;
        end if;

        -- Délai de base
        vDelay       :=
          DOC_DELAY_FUNCTIONS.GetShiftOpenDate(aDate                  => trunc(sysdate)
                                             , aCalcDays              => vBasisDecalage
                                             , aCfgUsePacSchedule     => vCfg_PAC_USE_PAC_SCHEDULE
                                             , aAdminDomain           => aAdminDomain
                                             , aThirdID               => aThirdID
                                             , aForward               => 1
                                             , aSearchThirdCalendar   => vSearchThirdCalendar
                                             , aScheduleID            => vDefaultScheduleID
                                             , aScheduleFilter        => vScheduleFilter
                                             , aScheduleFilterID      => vScheduleFilterID
                                              );

        -- Présentation des délais en semaines
        if aShowDelay = 2 then
          -- Ajustement au bon jour de la semaine du Délai de base
          vDelayMW  := DOC_DELAY_FUNCTIONS.DateToWeekNumber(aDate => vDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
          vDelay    := DOC_DELAY_FUNCTIONS.WeekNumberToDate(aWeek => vDelayMW, aDay => aPosDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);

          -- On ne permet pas qu' à l'initilaisation le délai soit inférieur à la date du jour
          if vDelay < trunc(sysdate) then
            -- Délai de base
            vDelay    :=
              DOC_DELAY_FUNCTIONS.GetShiftOpenDate(aDate                  => vDelay + 7
                                                 , aCalcDays              => 0
                                                 , aCfgUsePacSchedule     => vCfg_PAC_USE_PAC_SCHEDULE
                                                 , aAdminDomain           => aAdminDomain
                                                 , aThirdID               => aThirdID
                                                 , aForward               => 1
                                                 , aSearchThirdCalendar   => vSearchThirdCalendar
                                                 , aScheduleID            => vScheduleID
                                                 , aScheduleFilter        => vScheduleFilter
                                                 , aScheduleFilterID      => vScheduleFilterID
                                                  );
            -- Ajustement au bon jour de la semaine du Délai de base
            vDelayMW  := DOC_DELAY_FUNCTIONS.DateToWeekNumber(aDate => vDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
            vDelay    := DOC_DELAY_FUNCTIONS.WeekNumberToDate(aWeek => vDelayMW, aDay => aPosDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
          end if;
        -- Présentation des délais en mois
        elsif aShowDelay = 3 then
          vDelayMW  := DOC_DELAY_FUNCTIONS.DateToMonth(aDate => vDelay);
          vDelay    :=
            DOC_DELAY_FUNCTIONS.MonthToDate(aMonthDate            => vDelayMW
                                          , aPosDelay             => aPosDelay
                                          , aThirdID              => aThirdID
                                          , aAdminDomain          => aAdminDomain
                                          , SearchThirdCalendar   => vSearchThirdCalendar
                                           );
        end if;

        -- Délai de base, intermédiaire et final sont égaux
        aBasisDelay  := vDelay;
        aInterDelay  := vDelay;
        aFinalDelay  := vDelay;
      end if;
    end if;
  end InitializePDEDelay;

  /**
  *  Calcule les délais intermédiaire et final selon le délai de base
  */
  procedure GetPDEDelay(
    aShowDelay           in     integer
  , aPosDelay            in     integer
  , aUpdatedDelay        in     varchar2
  , aForward             in     integer
  , aThirdID             in     PAC_THIRD.PAC_THIRD_ID%type
  , aGoodID              in     GCO_GOOD.GCO_GOOD_ID%type
  , aStockID             in     DOC_POSITION.STM_STOCK_ID%type
  , aTargetStockID       in     DOC_POSITION.STM_STM_STOCK_ID%type
  , aAdminDomain         in     integer
  , aGaugeType           in     integer
  , aTransfertProprietor in     DOC_GAUGE_POSITION.GAP_TRANSFERT_PROPRIETOR%type
  , aBasisDelayMW        in out varchar2
  , aInterDelayMW        in out varchar2
  , aFinalDelayMW        in out varchar2
  , aBasisDelay          in out DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type
  , aInterDelay          in out DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type
  , aFinalDelay          in out DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type
  , iComplDataId         in     GCO_COMPL_DATA_SUBCONTRACT.GCO_COMPL_DATA_SUBCONTRACT_ID%type default null
  , iQuantity            in     DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type default null
  , iScheduleStepId      in     DOC_POSITION_DETAIL.FAL_SCHEDULE_STEP_ID%type default null
  )
  is
    -- Curseur pour les décalages des 3 délais des données compl. d'achat
    cursor crCDAPurchase(cGoodID GCO_GOOD.GCO_GOOD_ID%type, cThirdID PAC_THIRD.PAC_THIRD_ID%type)
    is
      select   rpad(decode(PAC_SUPPLIER_PARTNER_ID, null, rpad('1', 13, ' '), '0' || to_char(PAC_SUPPLIER_PARTNER_ID, '000000000000') ), 13, ' ') order1
             , rpad('1', 11, ' ') order2
             , 0 BASIS_DECALAGE
             , CPU_SUPPLY_DELAY INTER_DECALAGE
             , CPU_CONTROL_DELAY FINAL_DECALAGE
          from GCO_COMPL_DATA_PURCHASE
         where GCO_GOOD_ID = cGoodID
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_SUPPLIER_PARTNER_ID = cThirdID
                or PAC_SUPPLIER_PARTNER_ID is null)
      union
      select   rpad('1', 13, ' ') order1
             , decode(A.DIC_COMPLEMENTARY_DATA_ID, null, rpad('1', 11, ' '), '0' || rpad(A.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , 0 BASIS_DECALAGE
             , A.CPU_SUPPLY_DELAY INTER_DECALAGE
             , A.CPU_CONTROL_DELAY FINAL_DECALAGE
          from GCO_COMPL_DATA_PURCHASE A
             , PAC_SUPPLIER_PARTNER B
         where GCO_GOOD_ID = cGoodID
           and A.PAC_SUPPLIER_PARTNER_ID is null
           and A.DIC_COMPLEMENTARY_DATA_ID = B.DIC_COMPLEMENTARY_DATA_ID
           and B.PAC_SUPPLIER_PARTNER_ID = cThirdID
      order by 1
             , 2;

    -- Curseur pour les décalages des 3 délais des données compl. de vente
    cursor crCDASale(cGoodID GCO_GOOD.GCO_GOOD_ID%type, cThirdID PAC_THIRD.PAC_THIRD_ID%type)
    is
      select   rpad(decode(PAC_CUSTOM_PARTNER_ID, null, rpad('1', 13, ' '), '0' || to_char(PAC_CUSTOM_PARTNER_ID, '000000000000') ), 13, ' ') order1
             , rpad('1', 11, ' ') order2
             , CSA_TH_SUPPLY_DELAY BASIS_DECALAGE
             , CSA_DISPATCHING_DELAY INTER_DECALAGE
             , CSA_DELIVERY_DELAY FINAL_DECALAGE
          from GCO_COMPL_DATA_SALE
         where GCO_GOOD_ID = cGoodID
           and DIC_COMPLEMENTARY_DATA_ID is null
           and (   PAC_CUSTOM_PARTNER_ID = cThirdID
                or PAC_CUSTOM_PARTNER_ID is null)
      union
      select   rpad('1', 13, ' ') order1
             , decode(CSA.DIC_COMPLEMENTARY_DATA_ID, null, rpad('1', 11, ' '), '0' || rpad(CSA.DIC_COMPLEMENTARY_DATA_ID, 10) ) order2
             , CSA.CSA_TH_SUPPLY_DELAY BASIS_DECALAGE
             , CSA.CSA_DISPATCHING_DELAY INTER_DECALAGE
             , CSA.CSA_DELIVERY_DELAY FINAL_DECALAGE
          from GCO_COMPL_DATA_SALE CSA
             , PAC_CUSTOM_PARTNER CUS
         where GCO_GOOD_ID = cGoodID
           and CSA.PAC_CUSTOM_PARTNER_ID is null
           and CSA.DIC_COMPLEMENTARY_DATA_ID = CUS.DIC_COMPLEMENTARY_DATA_ID
           and CUS.PAC_CUSTOM_PARTNER_ID = cThirdID
      order by 1
             , 2;

    -- Curseur pour les décalages des 3 délais des données compl. de sous-traitance
    cursor crCDASubcontract(
      cComplDataId GCO_COMPL_DATA_SUBCONTRACT.GCO_COMPL_DATA_SUBCONTRACT_ID%type
    , cQuantity    DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY%type
    )
    is
      select 0 BASIS_DECALAGE
           , CSU_CONTROL_DELAY
           , CSU_SUBCONTRACTING_DELAY
           , CSU_ECONOMICAL_QUANTITY
           , CSU_FIX_DELAY
           , CSU_LOT_QUANTITY
        from GCO_COMPL_DATA_SUBCONTRACT
       where GCO_COMPL_DATA_SUBCONTRACT_ID = cComplDataId;

    tplCDAPurchase            crCDAPurchase%rowtype;
    tplCDASale                crCDASale%rowtype;
    tplCDASubcontract         crCDASubcontract%rowtype;
    --
    vCfg_DOC_THREE_DELAY      integer;
    vCfg_DOC_DELAY_WEEKSTART  integer;
    vCfg_PAC_USE_PAC_SCHEDULE integer;
    vCfg_STM_PROPRIETOR       integer;
    --
    vBasisDecalage            integer;
    vInterDecalage            integer;
    vFinalDecalage            integer;
    --
    vDelay                    date;
    vDelayMW                  varchar2(7);
    --
    vBasisDelayMW             varchar2(7);
    vInterDelayMW             varchar2(7);
    vFinalDelayMW             varchar2(7);
    --
    vSearchThirdCalendar      integer;
    vSearchFinalThirdCalendar integer;
    vScheduleID               PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    vFinalScheduleID          PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    vThirdScheduleID          PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    vDefaultScheduleID        PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    vThirdFilter              varchar(30);
    vThirdFilterID            PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    vScheduleFilter           varchar(30);
    vFinalScheduleFilter      varchar(30);
    vScheduleFilterID         PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    vFinalScheduleFilterID    PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
    lnDuration                GCO_COMPL_DATA_SUBCONTRACT.CSU_SUBCONTRACTING_DELAY%type;
  begin
    -- Recherche des configs
    select to_number(nvl(PCS.PC_CONFIG.GetConfig('DOC_THREE_DELAY'), '0') )
         , to_number(nvl(PCS.PC_CONFIG.GetConfig('DOC_DELAY_WEEKSTART'), '2') )
         , to_number(nvl(PCS.PC_CONFIG.GetConfig('PAC_USE_PAC_SCHEDULE'), '0') )
         , to_number(nvl(PCS.PC_CONFIG.GETCONFIG('STM_PROPRIETOR'), '0') )
      into vCfg_DOC_THREE_DELAY
         , vCfg_DOC_DELAY_WEEKSTART
         , vCfg_PAC_USE_PAC_SCHEDULE
         , vCfg_STM_PROPRIETOR
      from dual;

    -- Modif du délai de base
    if aUpdatedDelay = 'BASIS' then
      vDelay    := aBasisDelay;
      vDelayMW  := aBasisDelayMW;
    -- Modif du délai intermédiaire
    elsif(aUpdatedDelay = 'INTER') then
      vDelay    := aInterDelay;
      vDelayMW  := aInterDelayMW;
    -- Modif du délai final
    elsif(aUpdatedDelay = 'FINAL') then
      vDelay    := aFinalDelay;
      vDelayMW  := aFinalDelayMW;
    end if;

    -- Présentation des délais en jours
    if aShowDelay = 1 then
      vDelay    := nvl(vDelay, trunc(sysdate) );
      vDelayMW  := null;
    -- Présentation des délais en semaines
    elsif aShowDelay = 2 then
      -- Délai en semaine passé en param
      if vDelayMW is not null then
        vDelay  := DOC_DELAY_FUNCTIONS.WeekNumberToDate(aWeek => vDelayMW, aDay => aPosDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
      else
        -- Délai en date passé en param
        -- Si pas de délai passé en param, utilisation de la date du jour
        vDelay    := nvl(vDelay, trunc(sysdate) );
        vDelayMW  := DOC_DELAY_FUNCTIONS.DateToWeekNumber(aDate => vDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
        vDelay    := DOC_DELAY_FUNCTIONS.WeekNumberToDate(aWeek => vDelayMW, aDay => aPosDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
      end if;
    -- Présentation des délais en mois
    elsif aShowDelay = 3 then
      vSearchThirdCalendar  := 1;

      -- Délai en mois passé en param
      if vDelayMW is not null then
        vDelay  :=
          DOC_DELAY_FUNCTIONS.MonthToDate(aMonthDate            => vDelayMW
                                        , aPosDelay             => aPosDelay
                                        , aThirdID              => aThirdID
                                        , aAdminDomain          => aAdminDomain
                                        , SearchThirdCalendar   => vSearchThirdCalendar
                                         );
      else
        -- Délai en date passé en param
        -- Si pas de délai passé en param, utilisation de la date du jour
        vDelay    := nvl(vDelay, trunc(sysdate) );
        vDelayMW  := DOC_DELAY_FUNCTIONS.DateToMonth(aDate => vDelay);
        vDelay    :=
          DOC_DELAY_FUNCTIONS.MonthToDate(aMonthDate            => vDelayMW
                                        , aPosDelay             => aPosDelay
                                        , aThirdID              => aThirdID
                                        , aAdminDomain          => aAdminDomain
                                        , SearchThirdCalendar   => vSearchThirdCalendar
                                         );
      end if;
    end if;

    -- Modif du délai de base
    if aUpdatedDelay = 'BASIS' then
      aBasisDelay    := vDelay;
      aBasisDelayMW  := vDelayMW;
    -- Modif du délai intermédiaire
    elsif(aUpdatedDelay = 'INTER') then
      aInterDelay    := vDelay;
      aInterDelayMW  := vDelayMW;
    -- Modif du délai final
    elsif(aUpdatedDelay = 'FINAL') then
      aFinalDelay    := vDelay;
      aFinalDelayMW  := vDelayMW;
    end if;

    -- Gestion des 3 délais de façon DISTINCTE
    if vCfg_DOC_THREE_DELAY = 1 then
      -- Recherche des 3 délais

      -- Nouvelle Gestion des calendriers = oui
      if vCfg_PAC_USE_PAC_SCHEDULE = 1 then
        -- Rechercher le calendrier par défaut
        vDefaultScheduleID  := PAC_I_LIB_SCHEDULE.GetDefaultSchedule;
        -- Calendrier du tiers
        PAC_I_LIB_SCHEDULE.GetLogisticThirdSchedule(iThirdID       => aThirdID
                                                  , iAdminDomain   => aAdminDomain
                                                  , oScheduleID    => vThirdScheduleID
                                                  , oFilter        => vThirdFilter
                                                  , oFilterID      => vThirdFilterID
                                                   );

        -- Si pas trouvé de calendrier au niveau du tiers, utiliser le calendrier par défaut
        if vThirdScheduleID is null then
          vThirdScheduleID  := vDefaultScheduleID;
        end if;

        -- Message d'erreur, si pas trouvé de calendrier
        if nvl(vThirdScheduleID, vDefaultScheduleID) is null then
          raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('Il n''y a pas de calendrier par défaut!') );
        end if;
      end if;

      -- définition du calendrier à utiliser
      vSearchThirdCalendar  := 1;
      vScheduleID           := vThirdScheduleID;
      vScheduleFilter       := vThirdFilter;
      vScheduleFilterID     := vThirdFilterID;

      ----
      -- Définition du calendrier à utiliser pour le délai final
      -- Dans le domaine achat, il ne faut pas utiliser le calendrier du tiers pour calculer le délai de disponibilité (final) mais
      -- mais le calendrier par défaut.
      --
      -- Situation avant correction
      --
      --   * En achat, les délais suivants sont gérés :
      --     o Délai de commande
      --     o Délai de réception : délai de commande + durée d'approvisionnement selon calendrier du fournisseur ou calendrier par défaut
      --     o Délai de disponibilité : délai de réception + durée de contrôle selon calendrier du fournisseur ou calendrier par défaut
      --
      -- Problème
      --
      --   * Le contrôle étant généralement effectué par l'entreprise et non par le fournisseur, il est faux de tenir compte du
      --     calendrier du fournisseur pour calculer le délai de disponibilité.
      --   * Exemple :
      --     Si le fournisseur me livre aujourd'hui un article nécessitant un contrôle de 5 jours et que le fournisseur est en vacances
      --     dès demain, partant du principe que mon entreprise est ouverte, je ne pourrai disposer de la marchandise que dans 10 jours
      --     (5 jours fermé du fournisseur selon son calendrier + 5 jours de contrôle).
      --
      -- Conclusion
      --
      --   * Utiliser le calendrier du fournisseur pour le calcul du délai de réception
      --   * Utiliser le calendrier par défaut pour le calcul du délai de disponbilité
      --   * SAUF pour les commandes de sous-traitance opératoire où la notion de disponibilité n'est pas gérée.
      --
      if    (aAdminDomain = 1)
         or     (aAdminDomain = cAdminDomainSubContract)
            and not(     (aAdminDomain = 1)
                    and (aGaugeType = 2)
                    and (iScheduleStepId is not null) ) then
        -- Domaine "Achat" et type "Besoin" pour commande sous-traitance opératoire
        vSearchFinalThirdCalendar  := 0;
        vFinalScheduleID           := vDefaultScheduleID;
        vFinalScheduleFilter       := null;
        vFinalScheduleFilterID     := null;
      else
        vSearchFinalThirdCalendar  := 1;
        vFinalScheduleID           := vThirdScheduleID;
        vFinalScheduleFilter       := vThirdFilter;
        vFinalScheduleFilterID     := vThirdFilterID;
      end if;

      -- Recherche de tous les décalages
      -- Domaine "Achat" et Type "Appro" hors sous-traitance opératoire
      if     (aAdminDomain = 1)
         and (aGaugeType = 2)
         and (iScheduleStepId is null) then
        -- Curseur sur les données compl d'achat pour les décalages des 3 délais
        open crCDAPurchase(aGoodID, aThirdID);

        fetch crCDAPurchase
         into tplCDAPurchase;

        close crCDAPurchase;

        vBasisDecalage  := nvl(tplCDAPurchase.BASIS_DECALAGE, 0);
        vInterDecalage  := nvl(tplCDAPurchase.INTER_DECALAGE, 0);
        vFinalDecalage  := nvl(tplCDAPurchase.FINAL_DECALAGE, 0);

        -- Recherche de la durée d'appro au niveau du fournisseur si pas existant au niveau compl. du bien
        if tplCDAPurchase.INTER_DECALAGE is null then
          select nvl(max(CRE_SUPPLY_DELAY), 0)
            into vInterDecalage
            from PAC_SUPPLIER_PARTNER
           where PAC_SUPPLIER_PARTNER_ID = aThirdID;
        end if;
      -- Domaine "Achat" et type "Besoin" pour commande sous-traitance opératoire
      elsif     (aAdminDomain = 1)
            and (aGaugeType = 2)
            and (iScheduleStepId is not null) then
        vBasisDecalage  := 0;
        vInterDecalage  := FAL_I_LIB_SUBCONTRACTO.getTaskDuration(iScheduleStepId);
        vFinalDecalage  := 0;
      -- Domaine "Vente" et Type "Besoin"
      elsif     (aAdminDomain = 2)
            and (aGaugeType = 1) then
        -- Curseur sur les données compl de vente pour les décalages des 3 délais
        open crCDASale(aGoodID, aThirdID);

        fetch crCDASale
         into tplCDASale;

        close crCDASale;

        vBasisDecalage  := nvl(tplCDASale.BASIS_DECALAGE, 0);
        vInterDecalage  := nvl(tplCDASale.INTER_DECALAGE, 0);
        vFinalDecalage  := nvl(tplCDASale.FINAL_DECALAGE, 0);

        -- Recherche de la durée de livraison au niveau du client si pas existant au niveau compl. du bien
        if tplCDASale.FINAL_DECALAGE is null then
          select nvl(max(CUS_DELIVERY_DELAY), 0)
            into vFinalDecalage
            from PAC_CUSTOM_PARTNER
           where PAC_CUSTOM_PARTNER_ID = aThirdID;
        end if;
      -- Recherche de tous les décalages
      -- Domaine "Sous-traitance" et Type "Appro"
      elsif     (aAdminDomain = cAdminDomainSubContract)
            and (aGaugeType = 2)
            and iComplDataId is not null then
        -- Curseur sur les données compl de sous-traitance pour les décalages des 3 délais
        open crCDASubcontract(iComplDataId, iQuantity);

        fetch crCDASubcontract
         into tplCDASubcontract;

        -- Calcul les déclalages des 3 délais en fonction des données complémentaires de sous-traitance (sous-traitance d'achat).
        DOC_LIB_SUBCONTRACTP.getSUPOLags(tplCDASubcontract.CSU_CONTROL_DELAY
                                       , tplCDASubcontract.CSU_SUBCONTRACTING_DELAY
                                       , tplCDASubcontract.CSU_ECONOMICAL_QUANTITY
                                       , tplCDASubcontract.CSU_FIX_DELAY
                                       , tplCDASubcontract.CSU_LOT_QUANTITY
                                       , iQuantity
                                       , vBasisDecalage
                                       , vInterDecalage
                                       , vFinalDecalage
                                        );

        close crCDASubcontract;
      -- Domaine "Stock" ET "Transfert stock propr." ET config "Stock propriétaire" = 1
      elsif     (aAdminDomain = 3)
            and (aTransfertProprietor = 1)
            and (vCfg_STM_PROPRIETOR = 1) then
        -- Ne pas utiliser le calendrier du tiers
        vSearchThirdCalendar       := 0;
        vScheduleID                := vDefaultScheduleID;
        vScheduleFilter            := null;
        vScheduleFilterID          := null;
        vSearchFinalThirdCalendar  := 0;
        vFinalScheduleID           := vDefaultScheduleID;
        vFinalScheduleFilter       := null;
        vFinalScheduleFilterID     := null;
        vBasisDecalage             := 0;
        vInterDecalage             := 0;

        -- Recherche le décalage pour le délai final sur la
        -- donnée compl. de stock du stock propriétaire
        select nvl(nvl(CST_1.CST_TRANSFERT_DELAY, CST_2.CST_TRANSFERT_DELAY), 0) FINAL_DECALAGE
          into vFinalDecalage
          from (select max(CST_TRANSFERT_DELAY) CST_TRANSFERT_DELAY
                  from GCO_COMPL_DATA_STOCK
                 where GCO_GOOD_ID = aGoodID
                   and STM_STOCK_ID = aTargetStockID) CST_1
             , (select max(CST_TRANSFERT_DELAY) CST_TRANSFERT_DELAY
                  from GCO_COMPL_DATA_STOCK
                 where GCO_GOOD_ID = aGoodID
                   and STM_STOCK_ID = aStockID) CST_2;
      -- Autres domaines
      else
        vBasisDecalage  := 0;
        vInterDecalage  := 0;
        vFinalDecalage  := 0;
      end if;

      -- Recherche des délais en avant
      if aForward = 1 then
        -- Modif du délai de base -> Calcul du délai intermédiaire
        if (aUpdatedDelay = 'BASIS') then
          aInterDelay  :=
            DOC_DELAY_FUNCTIONS.GetShiftOpenDate(aDate                  => aBasisDelay
                                               , aCalcDays              => vInterDecalage
                                               , aCfgUsePacSchedule     => vCfg_PAC_USE_PAC_SCHEDULE
                                               , aAdminDomain           => aAdminDomain
                                               , aThirdID               => aThirdID
                                               , aForward               => 1
                                               , aSearchThirdCalendar   => vSearchThirdCalendar
                                               , aScheduleID            => vScheduleID
                                               , aScheduleFilter        => vScheduleFilter
                                               , aScheduleFilterID      => vScheduleFilterID
                                                );
        end if;

        -- Modif du délai de base ou intermédiaire -> Calcul du délai final
        if    (aUpdatedDelay = 'BASIS')
           or (aUpdatedDelay = 'INTER') then
          aFinalDelay  :=
            DOC_DELAY_FUNCTIONS.GetShiftOpenDate(aDate                  => aInterDelay
                                               , aCalcDays              => vFinalDecalage
                                               , aCfgUsePacSchedule     => vCfg_PAC_USE_PAC_SCHEDULE
                                               , aAdminDomain           => aAdminDomain
                                               , aThirdID               => aThirdID
                                               , aForward               => 1
                                               , aSearchThirdCalendar   => vSearchFinalThirdCalendar
                                               , aScheduleID            => vFinalScheduleID
                                               , aScheduleFilter        => vFinalScheduleFilter
                                               , aScheduleFilterID      => vFinalScheduleFilterID
                                                );
        end if;

        -- Présentation des délais en jours
        if aShowDelay = 1 then
          aInterDelayMW  := null;
          aFinalDelayMW  := null;
        -- Présentation des délais en semaines
        elsif aShowDelay = 2 then
          -- Modif du délai de base -> Calcul du délai intermédiaire
          if (aUpdatedDelay = 'BASIS') then
            aInterDelayMW  := DOC_DELAY_FUNCTIONS.DateToWeekNumber(aDate => aInterDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
            aInterDelay    := DOC_DELAY_FUNCTIONS.WeekNumberToDate(aWeek => aInterDelayMW, aDay => aPosDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
          end if;

          -- Modif du délai de base ou intermédiaire -> Calcul du délai final
          if    (aUpdatedDelay = 'BASIS')
             or (aUpdatedDelay = 'INTER') then
            aFinalDelayMW  := DOC_DELAY_FUNCTIONS.DateToWeekNumber(aDate => aFinalDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
            aFinalDelay    := DOC_DELAY_FUNCTIONS.WeekNumberToDate(aWeek => aFinalDelayMW, aDay => aPosDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
          end if;
        -- Présentation des délais en mois
        elsif aShowDelay = 3 then
          -- Modif du délai de base -> Calcul du délai intermédiaire
          if (aUpdatedDelay = 'BASIS') then
            aInterDelayMW  := DOC_DELAY_FUNCTIONS.DateToMonth(aDate => aInterDelay);
            aInterDelay    :=
              DOC_DELAY_FUNCTIONS.MonthToDate(aMonthDate            => aInterDelayMW
                                            , aPosDelay             => aPosDelay
                                            , aThirdID              => aThirdID
                                            , aAdminDomain          => aAdminDomain
                                            , SearchThirdCalendar   => vSearchThirdCalendar
                                             );
          end if;

          -- Modif du délai de base ou intermédiaire -> Calcul du délai final
          if    (aUpdatedDelay = 'BASIS')
             or (aUpdatedDelay = 'INTER') then
            aFinalDelayMW  := DOC_DELAY_FUNCTIONS.DateToMonth(aDate => aFinalDelay);
            aFinalDelay    :=
              DOC_DELAY_FUNCTIONS.MonthToDate(aMonthDate            => aFinalDelayMW
                                            , aPosDelay             => aPosDelay
                                            , aThirdID              => aThirdID
                                            , aAdminDomain          => aAdminDomain
                                            , SearchThirdCalendar   => vSearchFinalThirdCalendar
                                             );
          end if;
        end if;
      else
        -- Recherche des délais en arrière

        -- Modif du délai final -> Calcul du délai intermédiaire
        if (aUpdatedDelay = 'FINAL') then
          aInterDelay  :=
            DOC_DELAY_FUNCTIONS.GetShiftOpenDate(aDate                  => aFinalDelay
                                               , aCalcDays              => vFinalDecalage
                                               , aCfgUsePacSchedule     => vCfg_PAC_USE_PAC_SCHEDULE
                                               , aAdminDomain           => aAdminDomain
                                               , aThirdID               => aThirdID
                                               , aForward               => 0
                                               , aSearchThirdCalendar   => vSearchThirdCalendar
                                               , aScheduleID            => vScheduleID
                                               , aScheduleFilter        => vScheduleFilter
                                               , aScheduleFilterID      => vScheduleFilterID
                                                );
        end if;

        -- Modif du délai final ou intermédiaire -> Calcul du délai final
        if (aUpdatedDelay = 'INTER') then
          aFinalDelay  :=
            DOC_DELAY_FUNCTIONS.GetShiftOpenDate(aDate                  => aInterDelay
                                               , aCalcDays              => vFinalDecalage
                                               , aCfgUsePacSchedule     => vCfg_PAC_USE_PAC_SCHEDULE
                                               , aAdminDomain           => aAdminDomain
                                               , aThirdID               => aThirdID
                                               , aForward               => 1
                                               , aSearchThirdCalendar   => vSearchFinalThirdCalendar
                                               , aScheduleID            => vFinalScheduleID
                                               , aScheduleFilter        => vFinalScheduleFilter
                                               , aScheduleFilterID      => vFinalScheduleFilterID
                                                );
        end if;

        -- Modif du délai final ou intermédiaire -> Calcul du délai de base
        if    (aUpdatedDelay = 'FINAL')
           or (aUpdatedDelay = 'INTER') then
          -- Pour le délai de base en Vente on doit utiliser uniquement le calendrier par défaut (société)
          if     (aAdminDomain = 2)
             and (aGaugeType = 1) then
            aBasisDelay  :=
              DOC_DELAY_FUNCTIONS.GetShiftOpenDate(aDate                  => aInterDelay
                                                 , aCalcDays              => vInterDecalage
                                                 , aCfgUsePacSchedule     => vCfg_PAC_USE_PAC_SCHEDULE
                                                 , aAdminDomain           => aAdminDomain
                                                 , aThirdID               => aThirdID
                                                 , aForward               => 0
                                                 , aSearchThirdCalendar   => 0
                                                 , aScheduleID            => vDefaultScheduleID
                                                 , aScheduleFilter        => null
                                                 , aScheduleFilterID      => null
                                                  );
          else
            aBasisDelay  :=
              DOC_DELAY_FUNCTIONS.GetShiftOpenDate(aDate                  => aInterDelay
                                                 , aCalcDays              => vInterDecalage
                                                 , aCfgUsePacSchedule     => vCfg_PAC_USE_PAC_SCHEDULE
                                                 , aAdminDomain           => aAdminDomain
                                                 , aThirdID               => aThirdID
                                                 , aForward               => 0
                                                 , aSearchThirdCalendar   => vSearchThirdCalendar
                                                 , aScheduleID            => vScheduleID
                                                 , aScheduleFilter        => vScheduleFilter
                                                 , aScheduleFilterID      => vScheduleFilterID
                                                  );
          end if;
        end if;

        -- Présentation des délais en jours
        if aShowDelay = 1 then
          aBasisDelayMW  := null;
          aInterDelayMW  := null;
          aFinalDelayMW  := null;
        -- Présentation des délais en semaines
        elsif aShowDelay = 2 then
          -- Modif du délai final -> Calcul du délai intermédiaire
          if (aUpdatedDelay = 'FINAL') then
            aInterDelayMW  := DOC_DELAY_FUNCTIONS.DateToWeekNumber(aDate => aInterDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
            aInterDelay    := DOC_DELAY_FUNCTIONS.WeekNumberToDate(aWeek => aInterDelayMW, aDay => aPosDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
          end if;

          -- Modif du délai intermédiaire -> Calcul du délai final
          if (aUpdatedDelay = 'INTER') then
            aFinalDelayMW  := DOC_DELAY_FUNCTIONS.DateToWeekNumber(aDate => aFinalDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
            aFinalDelay    := DOC_DELAY_FUNCTIONS.WeekNumberToDate(aWeek => aFinalDelayMW, aDay => aPosDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
          end if;

          -- Modif du délai final ou intermédiaire -> Calcul du délai de base
          if    (aUpdatedDelay = 'FINAL')
             or (aUpdatedDelay = 'INTER') then
            aBasisDelayMW  := DOC_DELAY_FUNCTIONS.DateToWeekNumber(aDate => aBasisDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
            aBasisDelay    := DOC_DELAY_FUNCTIONS.WeekNumberToDate(aWeek => aBasisDelayMW, aDay => aPosDelay, aWeekStart => vCfg_DOC_DELAY_WEEKSTART);
          end if;
        -- Présentation des délais en mois
        elsif aShowDelay = 3 then
          -- Modif du délai final -> Calcul du délai intermédiaire
          if (aUpdatedDelay = 'FINAL') then
            aInterDelayMW  := DOC_DELAY_FUNCTIONS.DateToMonth(aDate => aInterDelay);
            aInterDelay    :=
              DOC_DELAY_FUNCTIONS.MonthToDate(aMonthDate            => aInterDelayMW
                                            , aPosDelay             => aPosDelay
                                            , aThirdID              => aThirdID
                                            , aAdminDomain          => aAdminDomain
                                            , SearchThirdCalendar   => vSearchThirdCalendar
                                             );
          end if;

          -- Modif du délai intermédiaire -> Calcul du délai final
          if (aUpdatedDelay = 'INTER') then
            aFinalDelayMW  := DOC_DELAY_FUNCTIONS.DateToMonth(aDate => aFinalDelay);
            aFinalDelay    :=
              DOC_DELAY_FUNCTIONS.MonthToDate(aMonthDate            => aFinalDelayMW
                                            , aPosDelay             => aPosDelay
                                            , aThirdID              => aThirdID
                                            , aAdminDomain          => aAdminDomain
                                            , SearchThirdCalendar   => vSearchFinalThirdCalendar
                                             );
          end if;

          -- Modif du délai final ou intermédiaire -> Calcul du délai de base
          if    (aUpdatedDelay = 'FINAL')
             or (aUpdatedDelay = 'INTER') then
            -- Pour le délai de base en Vente on doit utiliser uniquement le calendrier par défaut (société)
            if     (aAdminDomain = 2)
               and (aGaugeType = 1) then
              vSearchThirdCalendar  := 0;
            else
              vSearchThirdCalendar  := 1;
            end if;

            aBasisDelayMW  := DOC_DELAY_FUNCTIONS.DateToMonth(aDate => aBasisDelay);
            aBasisDelay    :=
              DOC_DELAY_FUNCTIONS.MonthToDate(aMonthDate            => aBasisDelayMW
                                            , aPosDelay             => aPosDelay
                                            , aThirdID              => aThirdID
                                            , aAdminDomain          => aAdminDomain
                                            , SearchThirdCalendar   => vSearchThirdCalendar
                                             );
          end if;
        end if;
      end if;
    else
      -- Gestion des 3 délais de façon UNIQUE -> DOC_THREE_DELAY = 0

      -- Modif du délai de base
      if aUpdatedDelay = 'BASIS' then
        -- Si recalcul des délais en avant, maj le délai intermédiaire et final
        if aForward = 1 then
          -- Délai intermédiaire
          aInterDelay    := aBasisDelay;
          aInterDelayMW  := aBasisDelayMW;
          -- Délai Final
          aFinalDelay    := aBasisDelay;
          aFinalDelayMW  := aBasisDelayMW;
        end if;
      end if;

      -- Modif du délai intermédiaire
      if (aUpdatedDelay = 'INTER') then
        -- Si recalcul des délais en arrière, maj le délai de base
        if aForward = 0 then
          -- Délai de base
          aBasisDelay    := aInterDelay;
          aBasisDelayMW  := aInterDelayMW;
        end if;

        -- Délai Final
        aFinalDelay    := aInterDelay;
        aFinalDelayMW  := aInterDelayMW;
      end if;

      -- Modif du délai final
      if (aUpdatedDelay = 'FINAL') then
        -- Si recalcul des délais en arrière, maj le délai de base et intermédiaire
        if aForward = 0 then
          -- Délai de base
          aBasisDelay    := aFinalDelay;
          aBasisDelayMW  := aFinalDelayMW;
          -- Délai intermédiaire
          aInterDelay    := aFinalDelay;
          aInterDelayMW  := aFinalDelayMW;
        end if;
      end if;
    end if;
  end GetPDEDelay;

  /**
  * Effectue la mise à jour de la quantité solde du détail de position parent
  * lors la modification de la qté du détail fils. Retourne la quantité soldé
  * sur le parent qui sera mise à jour sur le fils.
  *
  * Voir graphe d'événement EVTS MAJ Quantité Solde Détail Position Parent.vsd
  */
  procedure MajBalanceQtyDetailParent(
    aParentDetailID in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , aNewQty         in     DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type
  , aOldQty         in     DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type
  , aBalanceParent  in     DOC_POSITION_DETAIL.PDE_BALANCE_PARENT%type
  , aBalancedQty    in out DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY_PARENT%type
  )
  is
    cursor crPositionDetailFather(aPositionDetailID in number)
    is
      select PDE.PDE_BALANCE_QUANTITY
           , PDE.PDE_BASIS_QUANTITY
           , GAU.C_ADMIN_DOMAIN
           , GAS.C_GAUGE_TITLE
           , case
               when POS.C_GAUGE_TYPE_POS in('71', '81', '91', '101') then case
                                                                           when POS_PT.C_POS_DELIVERY_TYP is not null then POS_PT.C_POS_DELIVERY_TYP
                                                                           when DMT.C_DMT_DELIVERY_TYP is not null then DMT.C_DMT_DELIVERY_TYP
                                                                           when nvl(PDT_PT.C_PRODUCT_DELIVERY_TYP, '0') <> '0' then PDT_PT.C_PRODUCT_DELIVERY_TYP
                                                                           else nvl(CUS.C_DELIVERY_TYP, '0')
                                                                         end
               else(case
                      when POS.C_POS_DELIVERY_TYP is not null then POS.C_POS_DELIVERY_TYP
                      when DMT.C_DMT_DELIVERY_TYP is not null then DMT.C_DMT_DELIVERY_TYP
                      when nvl(PDT.C_PRODUCT_DELIVERY_TYP, '0') <> '0' then PDT.C_PRODUCT_DELIVERY_TYP
                      else nvl(CUS.C_DELIVERY_TYP, '0')
                    end
                   )
             end BALANCE_CODE
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
           , DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
           , GCO_PRODUCT PDT
           , PAC_CUSTOM_PARTNER CUS
           , DOC_POSITION POS_PT
           , GCO_PRODUCT PDT_PT
       where PDE.DOC_POSITION_DETAIL_ID = aPositionDetailID
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and GAU.DOC_GAUGE_ID = PDE.DOC_GAUGE_ID
         and GAS.DOC_GAUGE_ID = PDE.DOC_GAUGE_ID
         and POS.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
         and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
         and POS.DOC_DOC_POSITION_ID = POS_PT.DOC_POSITION_ID(+)
         and POS_PT.GCO_GOOD_ID = PDT_PT.GCO_GOOD_ID(+);

    tplPositionDetailFather crPositionDetailFather%rowtype;
    nBalanceQty             DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type;
    nParentQty              DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type;
    nNewQty                 DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type;
    nOldQty                 DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type;
    cAdminDomain            DOC_GAUGE.C_ADMIN_DOMAIN%type;
    cGaugeTitle             DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE%type;
    cBalanceCode            GCO_PRODUCT.C_PRODUCT_DELIVERY_TYP%type;
    bContinue               boolean;
    bNegativQty             boolean;
    cMessage                varchar2(255);
  begin
    bContinue    := false;
    bNegativQty  := false;
    nBalanceQty  := 0;
    nParentQty   := 0;
    nNewQty      := aNewQty;
    nOldQty      := aOldQty;

    open crPositionDetailFather(aParentDetailID);

    ----
    -- Recherche les informations du parent. Le code reliquat, la quantité solde
    -- parent et la quantité de base du détail parent
    --
    fetch crPositionDetailFather
     into tplPositionDetailFather;

    if crPositionDetailFather%found then
      -- Quantité négative ?
      if (tplPositionDetailFather.PDE_BASIS_QUANTITY < 0) then
        ----
        -- Contrôle du signe. La quantité modifiée est du même signe que la
        -- quantité du père.
        --
        if (nNewQty <= 0) then
          nNewQty       := nNewQty * -1;
          nOldQty       := nOldQty * -1;
          aBalancedQty  := aBalancedQty * -1;
          nBalanceQty   := tplPositionDetailFather.PDE_BALANCE_QUANTITY * -1;
          nParentQty    := tplPositionDetailFather.PDE_BASIS_QUANTITY * -1;
          bNegativQty   := true;
          bContinue     := true;
        else
          nParentQty  := tplPositionDetailFather.PDE_BASIS_QUANTITY;
          bContinue   := false;
        end if;
      else
        ----
        -- Contrôle du signe. La quantité modifiée est du même signe que la
        -- quantité du père.
        --
        if (nNewQty >= 0) then
          nBalanceQty  := tplPositionDetailFather.PDE_BALANCE_QUANTITY;
          nParentQty   := tplPositionDetailFather.PDE_BASIS_QUANTITY;
          bNegativQty  := false;
          bContinue    := true;
        else
          nParentQty  := tplPositionDetailFather.PDE_BASIS_QUANTITY;
          bContinue   := false;
        end if;
      end if;

      cAdminDomain  := tplPositionDetailFather.C_ADMIN_DOMAIN;
      cGaugeTitle   := tplPositionDetailFather.C_GAUGE_TITLE;
      cBalanceCode  := tplPositionDetailFather.BALANCE_CODE;
    end if;

    if bContinue then
      if (nOldQty < nNewQty) then   -- Augmentation de la quantité
        if (aBalancedQty = 0) then   -- Quantité soldé sur parent = 0
          if (nBalanceQty = 0) then   -- Quantité solde = 0
            aBalancedQty  := nOldQty - nNewQty + aBalancedQty;
          else   -- Quantité solde <> 0
            if (nBalanceQty + nOldQty - nNewQty < 0) then   -- Dépassement de quantité
              aBalancedQty  := nOldQty - nNewQty + nBalanceQty;
              nBalanceQty   := 0;
            else   -- Pas de dépassement de quantité
              if     (cAdminDomain = cAdminDomainSale)   -- Vente
                 and (cGaugeTitle = '6') then   -- Commande client
                -- Pas de mise à jour de la quantité solde (pas de reliquat)
                if    (cBalanceCode = cAdminDomainSale)   -- Pas de reliquat
                   or (cBalanceCode = '4')   -- Reliquat complet détail de position
                   or (cBalanceCode = '6') then   -- Reliquat complet position
                  aBalancedQty  := nBalanceQty + nOldQty - nNewQty + aBalancedQty;
                  nBalanceQty   := 0;   -- Solde le détail courant.
                else   -- Mise à jour du parent (reliquat)
                  nBalanceQty  := nBalanceQty + nOldQty - nNewQty;
                end if;
              else   -- Différent de vente et différent de commande client
                nBalanceQty  := nBalanceQty + nOldQty - nNewQty;
              end if;
            end if;

            if (bNegativQty) then
              update DOC_POSITION_DETAIL
                 set PDE_BALANCE_QUANTITY = nBalanceQty * -1
                   , A_DATEMOD = sysdate
                   , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
               where DOC_POSITION_DETAIL_ID = aParentDetailID;
            else
              update DOC_POSITION_DETAIL
                 set PDE_BALANCE_QUANTITY = nBalanceQty
                   , A_DATEMOD = sysdate
                   , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
               where DOC_POSITION_DETAIL_ID = aParentDetailID;
            end if;
          end if;
        else   -- Quantité soldé sur parent <> 0
          aBalancedQty  := nOldQty - nNewQty + aBalancedQty;
        end if;
      elsif(nOldQty > nNewQty) then   -- Diminution de la quantité
        if (aBalancedQty < 0) then   -- Quantité soldé sur parent < 0
          ----
          -- Le détail courant est actuellement en état de dépassement de quantité
          -- pour une quantité de base positive, mais en état de décharge partiel
          -- avec solde pour une quantité de base négative. Revoir éventuellement
          -- les implications.
          --
          if (nOldQty - nNewQty + aBalancedQty <= 0) then   -- Dépassement de quantité ou solde total
            aBalancedQty  := nOldQty - nNewQty + aBalancedQty;
          else   -- Décharge partiel avec solde avec quantité de base négative
            if aBalanceParent = 1 then   -- Solde du parent demandé
              aBalancedQty  := nOldQty - nNewQty + aBalancedQty;
            else
              if     (cAdminDomain = cAdminDomainSale)   -- Vente
                 and (cGaugeTitle = '6') then   -- Commande client
                -- Pas de mise à jour de la quantité solde (pas de reliquat).
                if    (cBalanceCode = '2')   -- Pas de reliquat
                   or (cBalanceCode = '4')   -- Reliquat complet détail de position
                   or (cBalanceCode = '6') then   -- Reliquat complet position
                  aBalancedQty  := nBalanceQty + nOldQty - nNewQty + aBalancedQty;
                  nBalanceQty   := 0;   -- Solde le détail courant.
                else   -- Mise à jour du parent (reliquat)
                  nBalanceQty   := nBalanceQty + nOldQty - nNewQty + aBalancedQty;
                  aBalancedQty  := 0;
                end if;
              else   -- Différent de vente et différent de commande client
                nBalanceQty   := nBalanceQty + nOldQty - nNewQty + aBalancedQty;
                aBalancedQty  := 0;
              end if;

              if (bNegativQty) then
                update DOC_POSITION_DETAIL
                   set PDE_BALANCE_QUANTITY = nBalanceQty * -1
                     , A_DATEMOD = sysdate
                     , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 where DOC_POSITION_DETAIL_ID = aParentDetailID;
              else
                update DOC_POSITION_DETAIL
                   set PDE_BALANCE_QUANTITY = nBalanceQty
                     , A_DATEMOD = sysdate
                     , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 where DOC_POSITION_DETAIL_ID = aParentDetailID;
              end if;
            end if;
          end if;
        elsif(aBalancedQty = 0) then   -- Quantité soldé sur parent = 0
          if aBalanceParent = 1 then   -- Solde du parent demandé
            aBalancedQty  := nOldQty - nNewQty + aBalancedQty;
          else
            if     (cAdminDomain = cAdminDomainSale)   -- Vente
               and (cGaugeTitle = '6') then   -- Commande client
              -- Pas de mise à jour de la quantité solde (pas de reliquat).
              if    (cBalanceCode = '2')   -- Pas de reliquat
                 or (cBalanceCode = '4')   -- Reliquat complet détail de position
                 or (cBalanceCode = '6') then   -- Reliquat complet position
                aBalancedQty  := nBalanceQty + nOldQty - nNewQty + aBalancedQty;
                nBalanceQty   := 0;   -- Solde le détail courant.
              else   -- Mise à jour du parent (reliquat)
                nBalanceQty  := nBalanceQty + nOldQty - nNewQty + aBalancedQty;
              end if;
            else   -- Différent de vente et différent de commande client
              nBalanceQty  := nBalanceQty + nOldQty - nNewQty + aBalancedQty;
            end if;

            if (bNegativQty) then
              update DOC_POSITION_DETAIL
                 set PDE_BALANCE_QUANTITY = nBalanceQty * -1
                   , A_DATEMOD = sysdate
                   , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
               where DOC_POSITION_DETAIL_ID = aParentDetailID;
            else
              update DOC_POSITION_DETAIL
                 set PDE_BALANCE_QUANTITY = nBalanceQty
                   , A_DATEMOD = sysdate
                   , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
               where DOC_POSITION_DETAIL_ID = aParentDetailID;
            end if;
          end if;
        elsif(aBalancedQty > 0) then   -- Quantité soldé sur parent > 0
          ----
          -- Le détail courant est actuellement en état de décharge partiel avec
          -- solde pour une quantité de base positive, mais en état de dépassement
          -- de quantité pour une quantité de base négative. Revoir éventuellement
          -- les implications.
          --
          if (nNewQty > nOldQty + aBalancedQty) then
            aBalancedQty  := nOldQty - nNewQty + aBalancedQty;
          elsif(nNewQty = nOldQty + aBalancedQty) then
            aBalancedQty  := 0;
          else   -- nNewQty < nOldQty + aBalancedQty
            if aBalanceParent = 1 then   -- Solde du parent demandé
              aBalancedQty  := nOldQty - nNewQty + aBalancedQty;
            else
              if     (cAdminDomain = cAdminDomainSale)   -- Vente
                 and (cGaugeTitle = '6') then   -- Commande client
                -- Pas de mise à jour de la quantité solde (pas de reliquat).
                if    (cBalanceCode = '2')   -- Pas de reliquat
                   or (cBalanceCode = '4')   -- Reliquat complet détail de position
                   or (cBalanceCode = '6') then   -- Reliquat complet position
                  aBalancedQty  := nOldQty - nNewQty + aBalancedQty;
                else   -- Mise à jour du parent (reliquat)
                  nBalanceQty  := nBalanceQty + nOldQty - nNewQty + aBalancedQty;

                  if (bNegativQty) then
                    update DOC_POSITION_DETAIL
                       set PDE_BALANCE_QUANTITY = nBalanceQty * -1
                         , A_DATEMOD = sysdate
                         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                     where DOC_POSITION_DETAIL_ID = aParentDetailID;
                  else
                    update DOC_POSITION_DETAIL
                       set PDE_BALANCE_QUANTITY = nBalanceQty
                         , A_DATEMOD = sysdate
                         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                     where DOC_POSITION_DETAIL_ID = aParentDetailID;
                  end if;
                end if;
              else   -- Différent de vente et différent de commande client
                nBalanceQty   := nBalanceQty + nOldQty - nNewQty + aBalancedQty;
                aBalancedQty  := 0;

                if (bNegativQty) then
                  update DOC_POSITION_DETAIL
                     set PDE_BALANCE_QUANTITY = nBalanceQty * -1
                       , A_DATEMOD = sysdate
                       , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                   where DOC_POSITION_DETAIL_ID = aParentDetailID;
                else
                  update DOC_POSITION_DETAIL
                     set PDE_BALANCE_QUANTITY = nBalanceQty
                       , A_DATEMOD = sysdate
                       , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                   where DOC_POSITION_DETAIL_ID = aParentDetailID;
                end if;
              end if;
            end if;
          end if;
        end if;
      end if;

      -- Quantité négative ?
      if (bNegativQty) then
        aBalancedQty  := aBalancedQty * -1;
      end if;
    else
      cMessage  := PCS.PC_FUNCTIONS.TranslateWord('La nouvelle quantité doit être de même signe que celle du détail parent.');
      raise_application_error(-20100, cMessage);
    end if;

    close crPositionDetailFather;
  end MajBalanceQtyDetailParent;

  /**
  * Description
  *   Calcule et retourne la valeur du mouvement du détail de position dont l'ID
  *   est passé en paramètre (en monnaie de base).
  */
  function CalcPdeMvtValue(aPositionDetailId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    return number
  is
    cursor crPositionDetails(aPositionDetailId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
    is
      select PDE.DOC_POSITION_DETAIL_ID
           , PDE.DOC_POSITION_ID
           , PDE.DOC_GAUGE_ID
           , PDE.DOC_DOC_POSITION_DETAIL_ID
           , PDE.DOC2_DOC_POSITION_DETAIL_ID
           , PDE.PDE_MOVEMENT_QUANTITY
           , PDE.PDE_FINAL_QUANTITY
           , PDE.PDE_FINAL_QUANTITY_SU
           , PDE.DOC_RECORD_ID
           , PDE.C_PDE_CREATE_MODE
           , POS.STM_MOVEMENT_KIND_ID
           , MOK.C_MOVEMENT_SORT
           , MOK.STM_STM_MOVEMENT_KIND_ID
           , POS.POS_FINAL_QUANTITY
           , POS.POS_UNIT_COST_PRICE
           , POS.POS_NET_UNIT_VALUE
           , POS.POS_NET_VALUE_EXCL
           , POS.DOC_DOC_POSITION_ID
           , POS.C_GAUGE_TYPE_POS
           , DMT.ACS_FINANCIAL_CURRENCY_ID
           , DMT.DMT_DATE_DOCUMENT
           , DMT.DMT_RATE_OF_EXCHANGE
           , DMT.DMT_BASE_PRICE
           , GAP.GAP_VALUE
           , GAP.GAP_STOCK_MVT
           , GAU.C_ADMIN_DOMAIN
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
           , DOC_DOCUMENT DMT
           , DOC_GAUGE_POSITION GAP
           , DOC_GAUGE GAU
           , STM_MOVEMENT_KIND MOK
       where PDE.DOC_POSITION_DETAIL_ID = aPositionDetailId
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and GAU.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
         and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
         and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID;

    tplPositionDetail  crPositionDetails%rowtype;
    vPdeMvtValue       DOC_POSITION_DETAIL.PDE_MOVEMENT_VALUE%type;
    vExcludeAmount     DOC_POSITION_CHARGE.PCH_AMOUNT%type           default 0;
    vExcludeAmountUnit DOC_POSITION.POS_NET_UNIT_VALUE%type          default 0;
  begin
    open crPositionDetails(aPositionDetailId);

    fetch crPositionDetails
     into tplPositionDetail;

    -- Pour les détails de positions dpour la répartition des frais
    -- la valeur mouvement se calcule différement
    if tplPositionDetail.C_PDE_CREATE_MODE in('205', '206') then
      begin
        -- La valeur mvt = (Qté détail src / Qté position src) * Prix de la position courante
        select (PDE.PDE_BASIS_QUANTITY_SU / POS.POS_BASIS_QUANTITY_SU) * tplPositionDetail.POS_NET_UNIT_VALUE
          into vPdeMvtValue
          from DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
         where PDE.DOC_POSITION_DETAIL_ID = tplPositionDetail.DOC2_DOC_POSITION_DETAIL_ID
           and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID;

        -- si le document est en monnaie étrangère, on converti le prix du mouvement
        if tplPositionDetail.ACS_FINANCIAL_CURRENCY_ID <> ACS_FUNCTION.GetLocalCurrencyId then
          vPdeMvtValue  :=
            ACS_FUNCTION.ConvertAmountForView(vPdeMvtValue
                                            , tplPositionDetail.ACS_FINANCIAL_CURRENCY_ID
                                            , ACS_FUNCTION.GetLocalCurrencyId
                                            , tplPositionDetail.DMT_DATE_DOCUMENT
                                            , tplPositionDetail.DMT_RATE_OF_EXCHANGE
                                            , tplPositionDetail.DMT_BASE_PRICE
                                            , 0
                                             );
        end if;
      exception
        when others then
          vPdeMvtValue  := 0;
      end;
    else
      /* Document de vente ou document de stock de type SOR. Initialise le prix du mouvement en fonction du prix de revient. */
      if    (tplPositionDetail.C_ADMIN_DOMAIN = cAdminDomainSale)
         or (     (tplPositionDetail.C_ADMIN_DOMAIN = cAdminDomainStock)
             and (tplPositionDetail.C_MOVEMENT_SORT = 'SOR') ) then
        -- En vente, si installation est init sur le détail reprendre le prix de revient de l'installation
        if     (tplPositionDetail.C_ADMIN_DOMAIN = cAdminDomainSale)
           and (tplPositionDetail.DOC_RECORD_ID is not null) then
          select nvl(RCO_COST_PRICE, tplPositionDetail.POS_UNIT_COST_PRICE) * tplPositionDetail.PDE_FINAL_QUANTITY_SU
            into vPdeMvtValue
            from DOC_RECORD
           where DOC_RECORD_ID = tplPositionDetail.DOC_RECORD_ID;
        else
          vPdeMvtValue  := tplPositionDetail.POS_UNIT_COST_PRICE * tplPositionDetail.PDE_FINAL_QUANTITY_SU;
        end if;
      else   /* Document d'achat ou autres et document de stock différent de SOR */
        select sum(decode(PCH.C_FINANCIAL_CHARGE, '02', PCH.PCH_AMOUNT * -1, PCH.PCH_AMOUNT) )
          into vExcludeAmount
          from DOC_POSITION_CHARGE PCH
         where PCH.DOC_POSITION_ID = tplPositionDetail.DOC_POSITION_ID
           and nvl(PCH.PCH_PRCS_USE, 1) = 0;

        vExcludeAmount  := nvl(vExcludeAmount, 0);

        -- si on exclu aucune remise/taxe
        if vExcludeAmount = 0 then
          if (tplPositionDetail.POS_FINAL_QUANTITY = 0) then
            vPdeMvtValue  := tplPositionDetail.POS_NET_VALUE_EXCL;
          else
            vPdeMvtValue  := tplPositionDetail.PDE_FINAL_QUANTITY * tplPositionDetail.POS_NET_UNIT_VALUE;
          end if;
        elsif(tplPositionDetail.POS_FINAL_QUANTITY = 0) then
          vPdeMvtValue  := tplPositionDetail.POS_NET_VALUE_EXCL - vExcludeAmount;
        else
          -- Calcul la valeur unitaire des remises/taxes à exclure dans le calul du prix du mouvement. Pour
          -- permettre une répartition sur chaque détail.
          vExcludeAmountUnit  := vExcludeAmount / tplPositionDetail.POS_FINAL_QUANTITY;

          if tplPositionDetail.PDE_FINAL_QUANTITY = 0 then
            vPdeMvtValue  := tplPositionDetail.POS_NET_UNIT_VALUE - vExcludeAmountUnit;
          else
            vPdeMvtValue  := tplPositionDetail.PDE_FINAL_QUANTITY *(tplPositionDetail.POS_NET_UNIT_VALUE - vExcludeAmountUnit);
          end if;
        end if;

        -- si le document est en monnaie étrangère, on converti le prix du mouvement
        if tplPositionDetail.ACS_FINANCIAL_CURRENCY_ID <> ACS_FUNCTION.GetLocalCurrencyId then
          vPdeMvtValue  :=
            ACS_FUNCTION.ConvertAmountForView(vPdeMvtValue
                                            , tplPositionDetail.ACS_FINANCIAL_CURRENCY_ID
                                            , ACS_FUNCTION.GetLocalCurrencyId
                                            , tplPositionDetail.DMT_DATE_DOCUMENT
                                            , tplPositionDetail.DMT_RATE_OF_EXCHANGE
                                            , tplPositionDetail.DMT_BASE_PRICE
                                            , 0
                                             );
        end if;
      end if;
    end if;

    close crPositionDetails;

    return vPdeMvtValue;
  end CalcPdeMvtValue;

  /**
  * Description
  *   Calcul et retourne la quantité en unité de stockage en fonction du facteur de conversion de la position.
  *   Cette fonction peut s'utiliser à l'intérieur d'un trigger de création ou de mise à jour de la position ou
  *   du détail de position. Cela grace à l'utilisation du pragma autonomous_transaction. Mais attention, il
  *   faut être sur que la session dans laquel est déclenché le trigger n'effectue pas de mise à jour sur les
  *   enregistrements recherchés par la fonction.
  */
  function GetQuantityUSAutoTrans(
    aPositionDetailID    DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , aQuantity         in DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type
  )
    return number
  is
    pragma autonomous_transaction;
    vQuantityUS DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY_SU%type;
  begin
    -- recherche de la quantité en unité de stockage après prise en compte du facteur de conversion et
    -- du nombre de décimal du bien
    begin
      select ACS_FUNCTION.RoundNear(aQuantity * nvl(POS.POS_CONVERT_FACTOR, 1), 1 / power(10, GOO.GOO_NUMBER_OF_DECIMAL), 1)
        into vQuantityUS
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
           , GCO_GOOD GOO
       where PDE.DOC_POSITION_DETAIL_ID = aPositionDetailID
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID;
    exception
      when no_data_found then
        vQuantityUS  := aQuantity;
    end;

    return nvl(vQuantityUS, 0);
  end GetQuantityUSAutoTrans;

  /**
  * function ForceDetailUnitQty
  * Description
  *   Indique si le détail doit avoir une qté unitaire en fonction du type
  *   de caractérisation du bien et du type de mouvement
  */
  function ForceDetailUnitQty(aPositionID in DOC_POSITION.DOC_POSITION_ID%type)
    return number
  is
    cursor crPos
    is
      select PDT.GCO_GOOD_ID
           , POS.STM_MOVEMENT_KIND_ID
           , case
               when MOK.C_MOVEMENT_SORT is not null then MOK.C_MOVEMENT_SORT
               when GAU.C_ADMIN_DOMAIN in(cAdminDomainPurchase, cAdminDomainSubContract) then 'ENT'
               else 'NULL'
             end C_MOVEMENT_SORT
           , case
               when nvl(CHA.CHA_STOCK_MANAGEMENT, 0) + nvl(PDT.PDT_STOCK_MANAGEMENT, 0) = 2 then 1
               else 0
             end CHA_STOCK_MANAGEMENT
           , nvl(CHA.C_CHARACT_TYPE, '0') C_CHARACT_TYPE
           , nvl(GAS.GAS_CHARACTERIZATION, 0) GAS_CHARACTERIZATION
           , case
               when nvl(GAS.GAS_ALL_CHARACTERIZATION, 0) + nvl(PCS.PC_CONFIG.GetConfig('DOC_CHARACTERIZATION_MODE'), 0) = 2 then 1
               else 0
             end GAS_ALL_CHARACTERIZATION
        from DOC_POSITION POS
           , STM_MOVEMENT_KIND MOK
           , GCO_PRODUCT PDT
           , GCO_CHARACTERIZATION CHA
           , DOC_DOCUMENT DMT
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
       where POS.DOC_POSITION_ID = aPositionID
         and POS.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+)
         and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID(+)
         and CHA.C_CHARACT_TYPE(+) = '3'
         and POS.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID(+)
         and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
         and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID(+);

    tplPos        crPos%rowtype;
    vForceUnitQty number(1)       default 0;
  begin
    open crPos;

    fetch crPos
     into tplPos;

    close crPos;

    -- Caractérisation de type 3 : Pièce
    -- Mouvement de sortie
    --  Bien
    if     (tplPos.GCO_GOOD_ID is not null)
       and (tplPos.C_CHARACT_TYPE = '3') then
      -- Vérifie si la caract est gérée ou pas dans le contexte
      if    (     (tplPos.STM_MOVEMENT_KIND_ID is null)
             and (tplPos.GAS_CHARACTERIZATION = 0) )
         or (     (tplPos.STM_MOVEMENT_KIND_ID is null)
             and (tplPos.GAS_CHARACTERIZATION = 1)
             and (tplPos.GAS_ALL_CHARACTERIZATION = 0) )
         or (     (tplPos.STM_MOVEMENT_KIND_ID is not null)
             and (tplPos.GAS_CHARACTERIZATION = 0)
             and (tplPos.CHA_STOCK_MANAGEMENT = 0) ) then
        -- L'id de la caractérisation n'est pas initialisé si
        -- Gabarit sans mvt ET Gestion caract. gab = non
        -- Gabarit sans mvt ET Gestion caract. gab = oui ET Gestion toutes caract. gab = non
        -- Gabarit avec mvt ET Gestion caract. gab = non ET Caract. gérée en stock = non
        vForceUnitQty  := 0;
      else
        -- Si en mvt Entrée et que la caract n'est pas gérée en stock
        -- Alors pas d'obligation d'avoir la qté unitaire sur le détail
        if     (tplPos.C_MOVEMENT_SORT = 'ENT')
           and (tplPos.CHA_STOCK_MANAGEMENT = 0) then
          vForceUnitQty  := 0;
        else
          -- Obligation d'avoir la qté unitaire sur le détail
          vForceUnitQty  := 1;
        end if;
      end if;
    end if;

    return vForceUnitQty;
  end;

  /**
  * procedure GetDetailCharact
  * Description
  *   Ramene les id et les valeurs de caractérisation selon les incréments auto
  *   pour la création du détail de position
  * @created  NGV MARCH 2008
  * @lastUpdate
  */
  procedure GetDetailCharact(
    aGoodID      in     GCO_GOOD.GCO_GOOD_ID%type
  , aPositionID  in     DOC_POSITION.DOC_POSITION_ID%type
  , aGasCharact  in     DOC_GAUGE_STRUCTURED.GAS_CHARACTERIZATION%type
  , aMvtSort     in     STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type
  , aAdminDomain in     DOC_GAUGE.C_ADMIN_DOMAIN%type
  , aChar1ID     in out GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aChar2ID     in out GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aChar3ID     in out GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aChar4ID     in out GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aChar5ID     in out GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aChar1Value  in out DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type
  , aChar2Value  in out DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type
  , aChar3Value  in out DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type
  , aChar4Value  in out DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type
  , aChar5Value  in out DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type
  , aCharacType1 in out GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , aCharacType2 in out GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , aCharacType3 in out GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , aCharacType4 in out GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , aCharacType5 in out GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  )
  is
    vCharStk1  GCO_CHARACTERIZATION.CHA_STOCK_MANAGEMENT%type;
    vCharStk2  GCO_CHARACTERIZATION.CHA_STOCK_MANAGEMENT%type;
    vCharStk3  GCO_CHARACTERIZATION.CHA_STOCK_MANAGEMENT%type;
    vCharStk4  GCO_CHARACTERIZATION.CHA_STOCK_MANAGEMENT%type;
    vCharStk5  GCO_CHARACTERIZATION.CHA_STOCK_MANAGEMENT%type;
    vGestPiece number(1)                                        default 0;
  begin
    -- recherche des id de caractérisations du nouveau détail de position
    GCO_CHARACTERIZATION_FUNCTIONS.GetListOfCharacterization(aGoodId            => aGoodID
                                                           , aCharManagement    => aGasCharact
                                                           , aMovementSort      => aMvtSort
                                                           , aAdminDomain       => aAdminDomain
                                                           , aCharac1Id         => aChar1ID
                                                           , aCharac2Id         => aChar2ID
                                                           , aCharac3Id         => aChar3ID
                                                           , aCharac4Id         => aChar4ID
                                                           , aCharac5Id         => aChar5ID
                                                           , aCharacType1       => aCharacType1
                                                           , aCharacType2       => aCharacType2
                                                           , aCharacType3       => aCharacType3
                                                           , aCharacType4       => aCharacType4
                                                           , aCharacType5       => aCharacType5
                                                           , aCharacStk1        => vCharStk1
                                                           , aCharacStk2        => vCharStk2
                                                           , aCharacStk3        => vCharStk3
                                                           , aCharacStk4        => vCharStk4
                                                           , aCharacStk5        => vCharStk5
                                                           , aPieceManagement   => vGestPiece
                                                            );

    -- Valeur de caractérisation 1
    if aChar1ID is not null then
      if     (aChar1Value is null)
         and (    (    aMvtSort = 'ENT'
                   and vCharStk1 = 1)
              or (    aMvtSort = 'SOR'
                  and vCharStk1 = 0) ) then
        -- Version quand versioning actif
        if     aCharacType1 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono
           and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(aGoodId) = 1 then
          aChar1Value  := GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => aGoodId);
        -- Version (comme numérotation), Pièces et Lots
        elsif aCharacType1 in(GCO_I_LIB_CONSTANT.gcCharacTypeVersion, GCO_I_LIB_CONSTANT.gcCharacTypePiece, GCO_I_LIB_CONSTANT.gcCharacTypeSet) then
          aChar1Value  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(aChar1ID, aPositionID, null);
        -- Caractérisation de type Chrono
        elsif aCharacType1 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
          aChar1Value  := GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(aChar1ID, sysdate);
        end if;
      end if;
    else
      aChar1Value  := null;
    end if;

    -- Valeur de caractérisation 2
    if aChar2ID is not null then
      if     (aChar2Value is null)
         and (    (    aMvtSort = 'ENT'
                   and vCharStk2 = 1)
              or (    aMvtSort = 'SOR'
                  and vCharStk2 = 0) ) then
        -- Caractérisations avec possibilité d'un incrément auto
        -- Version quand versioning actif
        if     aCharacType2 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono
           and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(aGoodId) = 1 then
          aChar2Value  := GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => aGoodId);
        -- Version (comme numérotation), Pièces et Lots
        elsif aCharacType2 in(GCO_I_LIB_CONSTANT.gcCharacTypeVersion, GCO_I_LIB_CONSTANT.gcCharacTypePiece, GCO_I_LIB_CONSTANT.gcCharacTypeSet) then
          aChar2Value  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(aChar2ID, aPositionID, null);
        -- Caractérisation de type Chrono
        elsif aCharacType2 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
          aChar2Value  := GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(aChar2ID, sysdate);
        end if;
      end if;
    else
      aChar2Value  := null;
    end if;

    -- Valeur de caractérisation 3
    if aChar3ID is not null then
      if     (aChar3Value is null)
         and (    (    aMvtSort = 'ENT'
                   and vCharStk3 = 1)
              or (    aMvtSort = 'SOR'
                  and vCharStk3 = 0) ) then
        -- Caractérisations avec possibilité d'un incrément auto
        -- Version quand versioning actif
        if     aCharacType3 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono
           and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(aGoodId) = 1 then
          aChar3Value  := GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => aGoodId);
        -- Version (comme numérotation), Pièces et Lots
        elsif aCharacType3 in(GCO_I_LIB_CONSTANT.gcCharacTypeVersion, GCO_I_LIB_CONSTANT.gcCharacTypePiece, GCO_I_LIB_CONSTANT.gcCharacTypeSet) then
          aChar3Value  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(aChar3ID, aPositionID, null);
        -- Caractérisation de type Chrono
        elsif aCharacType3 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
          aChar3Value  := GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(aChar3ID, sysdate);
        end if;
      end if;
    else
      aChar3Value  := null;
    end if;

    -- Valeur de caractérisation 4
    if aChar4ID is not null then
      if     (aChar4Value is null)
         and (    (    aMvtSort = 'ENT'
                   and vCharStk4 = 1)
              or (    aMvtSort = 'SOR'
                  and vCharStk4 = 0) ) then
        -- Caractérisations avec possibilité d'un incrément auto
        -- Version quand versioning actif
        if     aCharacType4 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono
           and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(aGoodId) = 1 then
          aChar4Value  := GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => aGoodId);
        -- Version (comme numérotation), Pièces et Lots
        elsif aCharacType4 in(GCO_I_LIB_CONSTANT.gcCharacTypeVersion, GCO_I_LIB_CONSTANT.gcCharacTypePiece, GCO_I_LIB_CONSTANT.gcCharacTypeSet) then
          aChar4Value  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(aChar4ID, aPositionID, null);
        -- Caractérisation de type Chrono
        elsif aCharacType4 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
          aChar4Value  := GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(aChar4ID, sysdate);
        end if;
      end if;
    else
      aChar4Value  := null;
    end if;

    -- Valeur de caractérisation 5
    if aChar5ID is not null then
      if     (aChar5Value is null)
         and (    (    aMvtSort = 'ENT'
                   and vCharStk5 = 1)
              or (    aMvtSort = 'SOR'
                  and vCharStk5 = 0) ) then
        -- Caractérisations avec possibilité d'un incrément auto
        -- Version quand versioning actif
        if     aCharacType5 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono
           and GCO_I_LIB_CHARACTERIZATION.IsVersioningManagement(aGoodId) = 1 then
          aChar5Value  := GCO_I_LIB_CHARACTERIZATION.PropVersion(iGoodId => aGoodId);
        -- Version (comme numérotation), Pièces et Lots
        elsif aCharacType5 in(GCO_I_LIB_CONSTANT.gcCharacTypeVersion, GCO_I_LIB_CONSTANT.gcCharacTypePiece, GCO_I_LIB_CONSTANT.gcCharacTypeSet) then
          aChar5Value  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(aChar5ID, aPositionID, null);
        -- Caractérisation de type Chrono
        elsif aCharacType5 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
          aChar5Value  := GCO_I_LIB_CHARACTERIZATION.PropChronologicalFormat(aChar5ID, sysdate);
        end if;
      end if;
    else
      aChar5Value  := null;
    end if;
  end GetDetailCharact;
end DOC_POSITION_DETAIL_FUNCTIONS;
