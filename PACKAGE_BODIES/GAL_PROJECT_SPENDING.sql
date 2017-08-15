--------------------------------------------------------
--  DDL for Package Body GAL_PROJECT_SPENDING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_PROJECT_SPENDING" 
is
--**********************************************************************************************************--
  procedure GET_DATA_FROM_GAL_HOURS(
    inHRM_PERSON_ID                   number
  , inGAL_BUDGET_ID                   number
  , ivDIC_GAL_HOUR_CODE_IND_ID        varchar2
  , inGAL_TASK_ID                     number
  , inGAL_TASK_LINK_ID                number
  , idPOINTING_DATE                   date
  , ionHOURLY_RATE             in out number
  , ionGAL_COST_CENTER_ID      in out number
  )
  is
    lbJobSearch             boolean default true;
    lnFAL_FACTORY_FLOOR_ID1 number  default null;
    lnFAL_FACTORY_FLOOR_ID2 number  default null;
  begin
    if idPOINTING_DATE is null then
      ionHOURLY_RATE         := null;
      ionGAL_COST_CENTER_ID  := null;
      return;
    end if;

    case
      when(inGAL_BUDGET_ID <> 0) then
        ionGAL_COST_CENTER_ID  := null;
        ionHOURLY_RATE         := null;
      when     (inGAL_TASK_ID <> 0)
           and (inGAL_TASK_LINK_ID = 0) then
        GET_DATA_FROM_TASK(inGAL_TASK_ID, idPOINTING_DATE, ionHOURLY_RATE, ionGAL_COST_CENTER_ID);
      when(inGAL_TASK_LINK_ID <> 0) then
        GET_DATA_FROM_RESS_OPE(inGAL_TASK_LINK_ID
                             , lnFAL_FACTORY_FLOOR_ID1
                             , lnFAL_FACTORY_FLOOR_ID2
                             , inGAL_TASK_ID
                             , idPOINTING_DATE
                             , ionHOURLY_RATE
                             , ionGAL_COST_CENTER_ID
                              );
      else
        ionGAL_COST_CENTER_ID  := null;
        ionHOURLY_RATE         := null;
    end case;

    if (ionGAL_COST_CENTER_ID is null) then
      select GET_GAL_COST_CENTER_FROMCPNCDA(null, GET_ACS_CDA_ACCOUNT_OF_PERSON(inHRM_PERSON_ID, idPOINTING_DATE), 'GAL_ANALYTIC_NATURE_LABOUR')
        into ionGAL_COST_CENTER_ID
        from dual;

      if ionGAL_COST_CENTER_ID is not null then
        select GET_HOURLY_RATE_FROM_NAT_ANA(ionGAL_COST_CENTER_ID, idPOINTING_DATE)
          into ionHOURLY_RATE
          from dual;
      end if;
    end if;
  end GET_DATA_FROM_GAL_HOURS;

--**********************************************************************************************************--
  procedure GET_DATA_FROM_TASK(inGAL_TASK_ID in number, idPOINTING_DATE in date, ionHOURLY_RATE in out number, ionGAL_COST_CENTER_ID in out number)
  is
    lnGAL_TASK_CATEGORY_ID number := null;
  begin
    begin
      select GAL_TASK_CATEGORY_ID
        into lnGAL_TASK_CATEGORY_ID
        from GAL_TASK
       where GAL_TASK_ID = inGAL_TASK_ID;
    exception
      when no_data_found then
        lnGAL_TASK_CATEGORY_ID  := null;
    end;

    if lnGAL_TASK_CATEGORY_ID is not null then
      ionGAL_COST_CENTER_ID  := GET_GAL_COST_CENTER_FROM_CATE(lnGAL_TASK_CATEGORY_ID, 'GAL_ANALYTIC_NATURE_LABOUR');
      ionHOURLY_RATE         := GET_HOURLY_RATE_FROM_NAT_ANA(ionGAL_COST_CENTER_ID, idPOINTING_DATE);
    else
      ionGAL_COST_CENTER_ID  := null;
      ionHOURLY_RATE         := null;
    end if;
  end GET_DATA_FROM_TASK;

--**********************************************************************************************************--
  procedure GET_DATA_FROM_RESS_OPE(
    inGAL_TASK_LINK_ID             number
  , inFAL_FACTORY_FLOOR_ID1        number
  , inFAL_FACTORY_FLOOR_ID2        number
  , inGAL_TASK_ID                  number
  , idPOINTING_DATE                date
  , ionHOURLY_RATE          in out number
  , ionGAL_COST_CENTER_ID   in out number
  )
  is
    -- J'ai reçu soit inGAL_TASK_LINK_ID
    --           soit inFAL_FACTORY_FLOOR_ID1 + inFAL_FACTORY_FLOOR_ID2 + inGAL_TASK_ID
    lnFAL_FACTORY_FLOOR_ID1  number := null;
    lnFAL_FACTORY_FLOOR_ID2  number := null;
    lnGAL_TASK_ID            number := null;
    lnFAL_ACS_CDA_ACCOUNT_ID number := null;
    lnGAL_TASK_CATEGORY_ID   number := null;
    lnHOURLY_RATE1           number := null;
    lnHOURLY_RATE2           number := null;
  begin
    if inGAL_TASK_LINK_ID = 0 then
      lnFAL_FACTORY_FLOOR_ID1  := inFAL_FACTORY_FLOOR_ID1;
      lnFAL_FACTORY_FLOOR_ID2  := inFAL_FACTORY_FLOOR_ID2;
      lnGAL_TASK_ID            := inGAL_TASK_ID;
    else
      -- Lecture ID ressource 1 et 2 + ID tâche
      begin
        select FAL_FACTORY_FLOOR_ID
             , FAL_FAL_FACTORY_FLOOR_ID
             , GAL_TASK_ID
          into lnFAL_FACTORY_FLOOR_ID1
             , lnFAL_FACTORY_FLOOR_ID2
             , lnGAL_TASK_ID
          from GAL_TASK_LINK
         where GAL_TASK_LINK_ID = inGAL_TASK_LINK_ID;
      exception
        when no_data_found then
          begin
            lnFAL_FACTORY_FLOOR_ID1  := null;
            lnFAL_FACTORY_FLOOR_ID2  := null;
            lnGAL_TASK_ID            := null;
          end;
      end;
    end if;

    -- Lecture ID catégorie tâche
    begin
      select GAL_TASK_CATEGORY_ID
        into lnGAL_TASK_CATEGORY_ID
        from GAL_TASK
       where GAL_TASK_ID = lnGAL_TASK_ID;
    exception
      when no_data_found then
        lnGAL_TASK_CATEGORY_ID  := null;
    end;

    -- Lecture ID CDA ressource 1 + ID NA ressource 1 + taux horaire ressource 1
    begin
      select ACS_CDA_ACCOUNT_ID
           , GAL_COST_CENTER_ID
           , (FAL_FACT_FLOOR.GetDateRateValue(FAL_FACTORY_FLOOR_ID, idPOINTING_DATE, 1) +
              FAL_FACT_FLOOR.GetDateRateValue(FAL_FACTORY_FLOOR_ID, idPOINTING_DATE, 2)
             )
        into lnFAL_ACS_CDA_ACCOUNT_ID
           , ionGAL_COST_CENTER_ID
           , lnHOURLY_RATE1
        from FAL_FACTORY_FLOOR
       where FAL_FACTORY_FLOOR_ID = lnFAL_FACTORY_FLOOR_ID1;
    exception
      when no_data_found then
        begin
          lnFAL_ACS_CDA_ACCOUNT_ID  := null;
          ionGAL_COST_CENTER_ID     := null;
          lnHOURLY_RATE1            := null;
        end;
    end;

    -- Lecture taux horaire ressource 2
    begin
      select (FAL_FACT_FLOOR.GetDateRateValue(FAL_FACTORY_FLOOR_ID, idPOINTING_DATE, 1) +
              FAL_FACT_FLOOR.GetDateRateValue(FAL_FACTORY_FLOOR_ID, idPOINTING_DATE, 2)
             )
        into lnHOURLY_RATE2
        from FAL_FACTORY_FLOOR
       where FAL_FACTORY_FLOOR_ID = lnFAL_FACTORY_FLOOR_ID2;
    exception
      when no_data_found then
        lnHOURLY_RATE2  := null;
    end;

    ionHOURLY_RATE  := null;

    if    nvl(lnHOURLY_RATE1, 0) <> 0
       or nvl(lnHOURLY_RATE2, 0) <> 0 then
      ionHOURLY_RATE  :=(nvl(lnHOURLY_RATE1, 0) + nvl(lnHOURLY_RATE2, 0) );
    else
      ionHOURLY_RATE  :=
        GET_HOURLY_RATE_FROM_NAT_ANA(GET_GAL_COST_CENTER_FROM_RESS(lnFAL_FACTORY_FLOOR_ID1
                                                                 , lnFAL_ACS_CDA_ACCOUNT_ID
                                                                 , ionGAL_COST_CENTER_ID
                                                                 , lnGAL_TASK_CATEGORY_ID
                                                                 , 'GAL_ANALYTIC_NATURE_LABOUR'
                                                                  )
                                   , idPOINTING_DATE
                                    );
    end if;
  end GET_DATA_FROM_RESS_OPE;

--**********************************************************************************************************--
  function GET_GAL_COST_CENTER_FROM_CONF(ivCONFIG varchar2)
    return number
  is
    lnGAL_COST_CENTER_ID number := null;
  begin
    begin
      select GAL_COST_CENTER_ID
        into lnGAL_COST_CENTER_ID
        from GAL_COST_CENTER
       where GCC_CODE = PCS.PC_CONFIG.GetConfig(ivCONFIG);
    exception
      when no_data_found then
        lnGAL_COST_CENTER_ID  := null;
    end;

    return lnGAL_COST_CENTER_ID;
  end GET_GAL_COST_CENTER_FROM_CONF;

--**********************************************************************************************************--
  function GET_GAL_COST_CENTER_FROM_CATE(inGAL_TASK_CATEGORY_ID number, ivCONFIG varchar2)
    return number
  is
    lnGAL_COST_CENTER_ID number := null;
  begin
    -- si Tache avec CAT
    if inGAL_TASK_CATEGORY_ID is not null then
      -- si existe une NA pour cette CAT
      begin
        select GAL_COST_CENTER_ID
          into lnGAL_COST_CENTER_ID
          from GAL_TASK_CATEGORY
         where GAL_TASK_CATEGORY_ID = inGAL_TASK_CATEGORY_ID;
      exception
        when no_data_found then
          lnGAL_COST_CENTER_ID  := null;
      end;

      if lnGAL_COST_CENTER_ID is not null then
        return lnGAL_COST_CENTER_ID;
      end if;
    end if;

    -- si pas encors trouvé, recherche selon CONF
    return GET_GAL_COST_CENTER_FROM_CONF(ivCONFIG);
  end GET_GAL_COST_CENTER_FROM_CATE;

--**********************************************************************************************************--
  function GET_GAL_COST_CENTER_FROM_CATB(inGCO_GOOD_CATEGORY_ID number)
    return number
  is
    lnGAL_COST_CENTER_ID number := null;
  begin
    -- si Article avec CAT de BIEN
    if inGCO_GOOD_CATEGORY_ID is not null then
      -- si existe une NA pour cette CAT
      begin
        select GAL_COST_CENTER_ID
          into lnGAL_COST_CENTER_ID
          from GCO_GOOD_CATEGORY
         where GCO_GOOD_CATEGORY_ID = inGCO_GOOD_CATEGORY_ID;
      exception
        when no_data_found then
          lnGAL_COST_CENTER_ID  := null;
      end;
    end if;

    return lnGAL_COST_CENTER_ID;
  end GET_GAL_COST_CENTER_FROM_CATB;

--**********************************************************************************************************--
  function GET_GAL_COST_CENTER_FROM_RESS(
    inFAL_FACTORY_FLOOR_ID   number
  , inFAL_ACS_CDA_ACCOUNT_ID number
  , inFAL_GAL_COST_CENTER_ID number
  , inGAL_TASK_CATEGORY_ID   number
  , ivCONFIG                 varchar2
  )
    return number
  is
    lnGAL_COST_CENTER_ID number := null;
  begin
    -- si existe Ressource
    if inFAL_FACTORY_FLOOR_ID is not null then
      -- si Ressource avec CDA
      if inFAL_ACS_CDA_ACCOUNT_ID is not null then
        -- si existe une et une seule NA pour ce CDA
        begin
          select GAL_COST_CENTER_ID
            into lnGAL_COST_CENTER_ID
            from GAL_COST_CENTER
           where ACS_CDA_ACCOUNT_ID = inFAL_ACS_CDA_ACCOUNT_ID
             and 1 = (select count(*)
                        from GAL_COST_CENTER
                       where ACS_CDA_ACCOUNT_ID = inFAL_ACS_CDA_ACCOUNT_ID);
        exception
          when no_data_found then
            lnGAL_COST_CENTER_ID  := null;
        end;

        if lnGAL_COST_CENTER_ID is not null then
          return lnGAL_COST_CENTER_ID;
        end if;
      end if;

      -- si Ressource avec NA
      if inFAL_GAL_COST_CENTER_ID is not null then
        return inFAL_GAL_COST_CENTER_ID;
      end if;
    end if;

    -- si pas encors trouvé, recherche selon CAT Tâche
    return GET_GAL_COST_CENTER_FROM_CATE(inGAL_TASK_CATEGORY_ID, ivCONFIG);
  end GET_GAL_COST_CENTER_FROM_RESS;

--**********************************************************************************************************--
  function GET_GAL_COST_CENTER_FROM_CPN(inACS_CPN_ACCOUNT_ID number)
    return number
  is
    lnGAL_COST_CENTER_ID number := null;
    lnCPN_PERE_ID        number := null;
  begin
    begin
      -- si existe une et une seule NA pour ce CPN
      select GAL_COST_CENTER_ID
        into lnGAL_COST_CENTER_ID
        from GAL_COST_CENTER
       where ACS_CPN_ACCOUNT_ID = inACS_CPN_ACCOUNT_ID
         and 1 = (select count(*)
                    from GAL_COST_CENTER
                   where ACS_CPN_ACCOUNT_ID = inACS_CPN_ACCOUNT_ID);
    exception
      when no_data_found then
        begin
          -- test si existe un CPN PERE pour ce CPN
          select ACS_ACCOUNT.ACS_SUB_ACCOUNT_ID
            into lnCPN_PERE_ID
            from ACS_ACCOUNT
               , ACS_CPN_ACCOUNT
           where ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID
             and ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID = inACS_CPN_ACCOUNT_ID
             and ACS_ACCOUNT.ACS_SUB_ACCOUNT_ID is not null;

          begin
            -- si existe une et une seule NA pour le CPN PERE
            select GAL_COST_CENTER_ID
              into lnGAL_COST_CENTER_ID
              from GAL_COST_CENTER
             where ACS_CPN_ACCOUNT_ID = lnCPN_PERE_ID
               and 1 = (select count(*)
                          from GAL_COST_CENTER
                         where ACS_CPN_ACCOUNT_ID = lnCPN_PERE_ID);
          exception
            when no_data_found then
              lnGAL_COST_CENTER_ID  := null;
          end;
        exception
          when no_data_found then
            lnGAL_COST_CENTER_ID  := null;
        end;
    end;

    return lnGAL_COST_CENTER_ID;
  end GET_GAL_COST_CENTER_FROM_CPN;

--**********************************************************************************************************--
  function GET_GAL_COST_CENTER_FROM_CPNDA(inACS_CPN_ACCOUNT_ID number, inACS_CDA_ACCOUNT_ID number)
    return number
  is
    lnGAL_COST_CENTER_ID number := null;
    lnCPN_PERE_ID        number := null;
    lnCDA_PERE_ID        number := null;
  begin
    begin
      -- si existe une et une seule NA pour ce CPN/CDA
      select GAL_COST_CENTER_ID
        into lnGAL_COST_CENTER_ID
        from GAL_COST_CENTER
       where (    (    ACS_CPN_ACCOUNT_ID = inACS_CPN_ACCOUNT_ID
                   and ACS_CDA_ACCOUNT_ID = inACS_CDA_ACCOUNT_ID)
              or (    ACS_CPN_ACCOUNT_ID is null
                  and inACS_CPN_ACCOUNT_ID is null
                  and ACS_CDA_ACCOUNT_ID = inACS_CDA_ACCOUNT_ID)
              or (    ACS_CPN_ACCOUNT_ID = inACS_CPN_ACCOUNT_ID
                  and ACS_CDA_ACCOUNT_ID is null
                  and inACS_CDA_ACCOUNT_ID is null)
             )
         and 1 =
               (select count(*)
                  from GAL_COST_CENTER
                 where (    ACS_CPN_ACCOUNT_ID = inACS_CPN_ACCOUNT_ID
                        and ACS_CDA_ACCOUNT_ID = inACS_CDA_ACCOUNT_ID)
                    or (    ACS_CPN_ACCOUNT_ID is null
                        and inACS_CPN_ACCOUNT_ID is null
                        and ACS_CDA_ACCOUNT_ID = inACS_CDA_ACCOUNT_ID)
                    or (    ACS_CPN_ACCOUNT_ID = inACS_CPN_ACCOUNT_ID
                        and ACS_CDA_ACCOUNT_ID is null
                        and inACS_CDA_ACCOUNT_ID is null) );
    exception
      when no_data_found then
        begin
          -- test si existe un CPN PERE pour ce CPN
          select ACS_ACCOUNT.ACS_SUB_ACCOUNT_ID
            into lnCPN_PERE_ID
            from ACS_ACCOUNT
               , ACS_CPN_ACCOUNT
           where ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID
             and ACS_CPN_ACCOUNT.ACS_CPN_ACCOUNT_ID = inACS_CPN_ACCOUNT_ID
             and ACS_ACCOUNT.ACS_SUB_ACCOUNT_ID is not null
             and inACS_CPN_ACCOUNT_ID is not null;

          begin
            -- si existe une et une seule NA pour ce CPN PERE/CDA
            select GAL_COST_CENTER_ID
              into lnGAL_COST_CENTER_ID
              from GAL_COST_CENTER
             where (    (    ACS_CPN_ACCOUNT_ID = lnCPN_PERE_ID
                         and ACS_CDA_ACCOUNT_ID = inACS_CDA_ACCOUNT_ID)
                    or (    ACS_CPN_ACCOUNT_ID is null
                        and lnCPN_PERE_ID is null
                        and ACS_CDA_ACCOUNT_ID = inACS_CDA_ACCOUNT_ID)
                    or (    ACS_CPN_ACCOUNT_ID = lnCPN_PERE_ID
                        and ACS_CDA_ACCOUNT_ID is null
                        and inACS_CDA_ACCOUNT_ID is null)
                   )
               and 1 =
                     (select count(*)
                        from GAL_COST_CENTER
                       where (    ACS_CPN_ACCOUNT_ID = lnCPN_PERE_ID
                              and ACS_CDA_ACCOUNT_ID = inACS_CDA_ACCOUNT_ID)
                          or (    ACS_CPN_ACCOUNT_ID is null
                              and lnCPN_PERE_ID is null
                              and ACS_CDA_ACCOUNT_ID = inACS_CDA_ACCOUNT_ID)
                          or (    ACS_CPN_ACCOUNT_ID = lnCPN_PERE_ID
                              and ACS_CDA_ACCOUNT_ID is null
                              and inACS_CDA_ACCOUNT_ID is null) );
          exception
            when no_data_found then
              begin
                -- test si existe un CDA PERE pour ce CDA
                select ACS_ACCOUNT.ACS_SUB_ACCOUNT_ID
                  into lnCDA_PERE_ID
                  from ACS_ACCOUNT
                     , ACS_CDA_ACCOUNT
                 where ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID
                   and ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID = inACS_CDA_ACCOUNT_ID
                   and ACS_ACCOUNT.ACS_SUB_ACCOUNT_ID is not null
                   and inACS_CDA_ACCOUNT_ID is not null;

                begin
                  -- si existe une et une seule NA pour ce CPN PERE/CDA PERE
                  select GAL_COST_CENTER_ID
                    into lnGAL_COST_CENTER_ID
                    from GAL_COST_CENTER
                   where (    (    ACS_CPN_ACCOUNT_ID = lnCPN_PERE_ID
                               and ACS_CDA_ACCOUNT_ID = lnCDA_PERE_ID)
                          or (    ACS_CPN_ACCOUNT_ID is null
                              and lnCPN_PERE_ID is null
                              and ACS_CDA_ACCOUNT_ID = lnCDA_PERE_ID)
                          or (    ACS_CPN_ACCOUNT_ID = lnCPN_PERE_ID
                              and ACS_CDA_ACCOUNT_ID is null
                              and lnCDA_PERE_ID is null)
                         )
                     and 1 =
                           (select count(*)
                              from GAL_COST_CENTER
                             where (    ACS_CPN_ACCOUNT_ID = lnCPN_PERE_ID
                                    and ACS_CDA_ACCOUNT_ID = lnCDA_PERE_ID)
                                or (    ACS_CPN_ACCOUNT_ID is null
                                    and lnCPN_PERE_ID is null
                                    and ACS_CDA_ACCOUNT_ID = lnCDA_PERE_ID)
                                or (    ACS_CPN_ACCOUNT_ID = lnCPN_PERE_ID
                                    and ACS_CDA_ACCOUNT_ID is null
                                    and lnCDA_PERE_ID is null) );
                exception
                  when no_data_found then
                    lnGAL_COST_CENTER_ID  := null;
                end;
              exception
                when no_data_found then
                  lnGAL_COST_CENTER_ID  := null;
              end;
          end;
        exception
          when no_data_found then
            begin
              -- test si existe un CDA PERE pour ce CDA
              select ACS_ACCOUNT.ACS_SUB_ACCOUNT_ID
                into lnCDA_PERE_ID
                from ACS_ACCOUNT
                   , ACS_CDA_ACCOUNT
               where ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID
                 and ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID = inACS_CDA_ACCOUNT_ID
                 and ACS_ACCOUNT.ACS_SUB_ACCOUNT_ID is not null
                 and inACS_CDA_ACCOUNT_ID is not null;

              begin
                -- si existe une et une seule NA pour ce CPN/CDA PERE
                select GAL_COST_CENTER_ID
                  into lnGAL_COST_CENTER_ID
                  from GAL_COST_CENTER
                 where (    (    ACS_CPN_ACCOUNT_ID = inACS_CPN_ACCOUNT_ID
                             and ACS_CDA_ACCOUNT_ID = lnCDA_PERE_ID)
                        or (    ACS_CPN_ACCOUNT_ID is null
                            and inACS_CPN_ACCOUNT_ID is null
                            and ACS_CDA_ACCOUNT_ID = lnCDA_PERE_ID)
                        or (    ACS_CPN_ACCOUNT_ID = inACS_CPN_ACCOUNT_ID
                            and ACS_CDA_ACCOUNT_ID is null
                            and lnCDA_PERE_ID is null)
                       )
                   and 1 =
                         (select count(*)
                            from GAL_COST_CENTER
                           where (    ACS_CPN_ACCOUNT_ID = inACS_CPN_ACCOUNT_ID
                                  and ACS_CDA_ACCOUNT_ID = lnCDA_PERE_ID)
                              or (    ACS_CPN_ACCOUNT_ID is null
                                  and inACS_CPN_ACCOUNT_ID is null
                                  and ACS_CDA_ACCOUNT_ID = lnCDA_PERE_ID)
                              or (    ACS_CPN_ACCOUNT_ID = inACS_CPN_ACCOUNT_ID
                                  and ACS_CDA_ACCOUNT_ID is null
                                  and lnCDA_PERE_ID is null) );
              exception
                when no_data_found then
                  lnGAL_COST_CENTER_ID  := null;
              end;
            exception
              when no_data_found then
                lnGAL_COST_CENTER_ID  := null;
            end;
        end;
    end;

    return lnGAL_COST_CENTER_ID;
  end GET_GAL_COST_CENTER_FROM_CPNDA;

--**********************************************************************************************************--
  function GET_GAL_COST_CENTER_FROM_GOOD(
    inACS_CPN_ACCOUNT_ID   number
  , inACS_CDA_ACCOUNT_ID   number
  , inGCO_GOOD_CATEGORY_ID number
  , inDOC_RECORD_ID        number
  , ivCONFIG               varchar2
  )
    return number
  is
    lnGAL_COST_CENTER_ID   number := null;
    lnGAL_TASK_CATEGORY_ID number := null;
  begin
    -- si Article avec CPN
    if inACS_CPN_ACCOUNT_ID is not null then
      -- si existe une et une seule NA pour ce CPN
      lnGAL_COST_CENTER_ID  := GET_GAL_COST_CENTER_FROM_CPN(inACS_CPN_ACCOUNT_ID);

      if lnGAL_COST_CENTER_ID is not null then
        return lnGAL_COST_CENTER_ID;
      end if;
    end if;

    -- si Article avec CDA
    if inACS_CDA_ACCOUNT_ID is not null then
      -- si existe une et une seule NA pour ce CPN/CDA
      lnGAL_COST_CENTER_ID  := GET_GAL_COST_CENTER_FROM_CPNDA(inACS_CPN_ACCOUNT_ID, inACS_CDA_ACCOUNT_ID);

      if lnGAL_COST_CENTER_ID is not null then
        return lnGAL_COST_CENTER_ID;
      end if;
    end if;

    -- si pas encors trouvé, recherche selon CAT Bien
    lnGAL_COST_CENTER_ID  := GET_GAL_COST_CENTER_FROM_CATB(inGCO_GOOD_CATEGORY_ID);

    if lnGAL_COST_CENTER_ID is not null then
      return lnGAL_COST_CENTER_ID;
    end if;

    -- si pas encors trouvé, recherche selon CAT Tâche
    if inDOC_RECORD_ID is not null then
      -- lecture TAC
      begin
        select GAL_TASK_CATEGORY_ID
          into lnGAL_TASK_CATEGORY_ID
          from GAL_TASK
         where DOC_RECORD_ID = inDOC_RECORD_ID;
      exception
        when no_data_found then
          lnGAL_TASK_CATEGORY_ID  := null;
      end;

      if lnGAL_TASK_CATEGORY_ID is not null then
        lnGAL_COST_CENTER_ID  := GET_GAL_COST_CENTER_FROM_CATE(lnGAL_TASK_CATEGORY_ID, ivCONFIG);

        if lnGAL_COST_CENTER_ID is not null then
          return lnGAL_COST_CENTER_ID;
        end if;
      end if;
    end if;

    -- si pas encors trouvé, recherche selon CONF
    return GET_GAL_COST_CENTER_FROM_CONF(ivCONFIG);
  end GET_GAL_COST_CENTER_FROM_GOOD;

--**********************************************************************************************************--
  function GET_ACS_CDA_ACCOUNT_OF_PERSON(inHRM_PERSON_ID number, idDATE date)
    return number
  is
    lnACS_CDA_ACCOUNT_ID number := null;
  begin   --Si 2 bornes de date
    select ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID
      into lnACS_CDA_ACCOUNT_ID
      from ACS_CDA_ACCOUNT
         , ACS_ACCOUNT
         , HRM_JOB
         , HRM_PERSON_JOB
         , HRM_PERSON
     where HRM_PERSON.HRM_PERSON_ID = inHRM_PERSON_ID
       and HRM_PERSON_JOB.HRM_PERSON_ID = HRM_PERSON.HRM_PERSON_ID
       and idDATE between HRM_PERSON_JOB.PEJ_FROM and HRM_PERSON_JOB.PEJ_TO
       and HRM_JOB.HRM_JOB_ID = HRM_PERSON_JOB.HRM_JOB_ID
       and HRM_JOB.JOB_CDA_NUMBER = ACS_ACCOUNT.ACC_NUMBER
       and ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
       and rownum = 1;

    return(lnACS_CDA_ACCOUNT_ID);
  exception
    when no_data_found then
      begin   --si pas de borne de date de fin
        select ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID
          into lnACS_CDA_ACCOUNT_ID
          from ACS_CDA_ACCOUNT
             , ACS_ACCOUNT
             , HRM_JOB
             , HRM_PERSON_JOB
             , HRM_PERSON
         where HRM_PERSON.HRM_PERSON_ID = inHRM_PERSON_ID
           and HRM_PERSON_JOB.HRM_PERSON_ID = HRM_PERSON.HRM_PERSON_ID
           and idDATE between HRM_PERSON_JOB.PEJ_FROM and nvl(HRM_PERSON_JOB.PEJ_TO, to_date('2199/12/31', 'YYYY/MM/DD') )
           and HRM_JOB.HRM_JOB_ID = HRM_PERSON_JOB.HRM_JOB_ID
           and HRM_JOB.JOB_CDA_NUMBER = ACS_ACCOUNT.ACC_NUMBER
           and ACS_CDA_ACCOUNT.ACS_CDA_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
           and rownum = 1;

        return(lnACS_CDA_ACCOUNT_ID);
      exception
        when no_data_found then
          return(null);
      end;
  end GET_ACS_CDA_ACCOUNT_OF_PERSON;

--**********************************************************************************************************--
  function GET_GAL_COST_CENTER_FROMCPNCDA(inACS_CPN_ACCOUNT_ID number, inACS_CDA_ACCOUNT_ID number, ivCONFIG varchar2)
    return number
  is
    lnGAL_COST_CENTER_ID number := null;
  begin
    -- si existe une et une seule NA pour ce CPN/CDA
    lnGAL_COST_CENTER_ID  := GET_GAL_COST_CENTER_FROM_CPNDA(inACS_CPN_ACCOUNT_ID, inACS_CDA_ACCOUNT_ID);

    if lnGAL_COST_CENTER_ID is not null then
      return lnGAL_COST_CENTER_ID;
    else
      return GET_GAL_COST_CENTER_FROM_CONF(ivCONFIG);
    end if;
  -- si pas encors trouvé, recherche selon CONF
  end GET_GAL_COST_CENTER_FROMCPNCDA;

--**********************************************************************************************************--
  function GET_GAL_BUDGET_FROM_RECORD(inDOC_RECORD_ID number)
    return number
  is
    lvC_RCO_TYPE       varchar2(10) := null;
    lnGAL_BUDGET_ID    number       := null;
    lnGAL_TASK_ID      number       := null;
    lnGAL_TASK_LINK_ID number       := null;
  begin
    -- si avec DOC
    if inDOC_RECORD_ID is not null then
      -- lecture DOC
      begin
        select C_RCO_TYPE
             , GAL_BUDGET_ID
             , GAL_TASK_ID
             , GAL_TASK_LINK_ID
          into lvC_RCO_TYPE
             , lnGAL_BUDGET_ID
             , lnGAL_TASK_ID
             , lnGAL_TASK_LINK_ID
          from DOC_RECORD
         where DOC_RECORD_ID = inDOC_RECORD_ID
           and C_RCO_TYPE in('02', '03', '04', '05');
      exception
        when no_data_found then
          lvC_RCO_TYPE        := null;
          lnGAL_BUDGET_ID     := null;
          lnGAL_TASK_ID       := null;
          lnGAL_TASK_LINK_ID  := null;
      end;

      if lvC_RCO_TYPE is not null then
        -- DOC de type BUDGET
        if lvC_RCO_TYPE = '04' then
          return lnGAL_BUDGET_ID;
        -- DOC de type TACHE
        else
          if lvC_RCO_TYPE in('02', '03') then
            begin
              select GAL_BUDGET_ID
                into lnGAL_BUDGET_ID
                from GAL_TASK
               where GAL_TASK_ID = lnGAL_TASK_ID;
            exception
              when no_data_found then
                lnGAL_BUDGET_ID  := null;
            end;
          -- DOC de type OPERATION DE TACHE
          else
            if lvC_RCO_TYPE = '05' then
              begin
                select GAL_TASK.GAL_BUDGET_ID
                  into lnGAL_BUDGET_ID
                  from GAL_TASK
                     , GAL_TASK_LINK
                 where GAL_TASK.GAL_TASK_ID = GAL_TASK_LINK.GAL_TASK_ID
                   and GAL_TASK_LINK.GAL_TASK_LINK_ID = lnGAL_TASK_LINK_ID;
              exception
                when no_data_found then
                  lnGAL_BUDGET_ID  := null;
              end;
            end if;
          end if;
        end if;
      end if;
    end if;

    return lnGAL_BUDGET_ID;
  end GET_GAL_BUDGET_FROM_RECORD;

--**********************************************************************************************************--
  function GET_HOURLY_RATE_FROM_NAT_ANA(
    inGAL_COST_CENTER_ID    in number
  , idPOINTING_DATE         in date
  , iC_GAL_HOURLY_RATE_TYPE in GAL_COST_HOURLY_RATE.C_GAL_HOURLY_RATE_TYPE%type default '00'
  , iProjectID              in GAL_PROJECT.GAL_PROJECT_ID%type default null
  )
    return number
  is
    lnHOURLY_RATE                number                                                  := null;
    lnProjectCurrID              ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
    lnExchRate                   GAL_CURRENCY_RATE.GCT_RATE_OF_EXCHANGE%type;
    lnBasePrice                  GAL_CURRENCY_RATE.GCT_BASE_PRICE%type;
    a_gal_proc_valuationrate_SF4 varchar2(255);
    a_valuationrate_for_SF4      GAL_CURRENCY_RATE.GCT_RATE_OF_EXCHANGE%type             := 0;
    sqlstatement                 varchar2(2000);
  begin
    begin
      select   GCH_HOURLY_RATE
          into lnHOURLY_RATE
          from GAL_COST_HOURLY_RATE
         where GAL_COST_CENTER_ID = inGAL_COST_CENTER_ID
           and C_GAL_HOURLY_RATE_TYPE = iC_GAL_HOURLY_RATE_TYPE
           and trunc(nvl(idPOINTING_DATE, sysdate) ) >= GCH_START_DATE
           and rownum = 1
      order by GCH_START_DATE desc;
    exception
      when no_data_found then
        begin
          select   GCH_HOURLY_RATE
              into lnHOURLY_RATE
              from GAL_COST_HOURLY_RATE
             where GAL_COST_CENTER_ID = inGAL_COST_CENTER_ID
               and C_GAL_HOURLY_RATE_TYPE = iC_GAL_HOURLY_RATE_TYPE
               and trunc(nvl(idPOINTING_DATE, sysdate) ) < GCH_START_DATE
               and rownum = 1
          order by GCH_START_DATE asc;
        exception
          when no_data_found then
            lnHOURLY_RATE  := null;
        end;
    end;

    if     (iProjectID is not null)
       and (nvl(lnHOURLY_RATE, 0) <> 0)
       and (pcs.pc_config.getconfig('GAL_CURRENCY_CONTRACT_BUDGET') = '1') then
      -- Rechercher la monnaie de l'affaire
      lnProjectCurrID  := GAL_LIB_PROJECT.GetProjectCurrency(iProjectID => iProjectID);

      -- Convertir le taux horaire en monnaie de contrat si diff de la monnaie de base
      if lnProjectCurrID <> ACS_FUNCTION.GetLocalCurrencyID then
        -- Recherche le cours de change de la devise
        begin
          select pcs.pc_config.getconfig
                                ('GAL_PROC_VALUATIONRATE_SF4')   -- recherche de la procédure qui calcule le taux forcé pour remonter en monnaie de contrat dans SF4
            into a_gal_proc_valuationrate_SF4
            from dual;
        exception
          when no_data_found then
            a_gal_proc_valuationrate_SF4  := null;
        end;

        if a_gal_proc_valuationrate_SF4 is not null   -- on initialise le taux forcé de la monnaie de contrat pour SF4
                                                   then
          sqlstatement  := 'BEGIN ' || trim(a_gal_proc_valuationrate_SF4) || '(:agalprojectid,:a_valuationrate_for_SF4); END;';

          execute immediate sqlstatement
                      using in iProjectID, in out a_valuationrate_for_SF4;
        end if;

        if a_valuationrate_for_SF4 <> 0 then
          lnHOURLY_RATE  := lnHOURLY_RATE * a_valuationrate_for_SF4;
        else
          ACS_FUNCTION.GetExchangeRate(aDate           => idPOINTING_DATE
                                     , aCurrency_id    => lnProjectCurrID
                                     , aRateType       => 1
                                     , aExchangeRate   => lnExchRate
                                     , aBasePrice      => lnBasePrice
                                      );
          -- Convertir en devise affaire
          lnHOURLY_RATE  :=
                 ACS_FUNCTION.ConvertAmountForView(lnHOURLY_RATE, ACS_FUNCTION.GetLocalCurrencyID, lnProjectCurrID, idPOINTING_DATE, lnExchRate, lnBasePrice, 0);
        end if;
      end if;
    end if;

    return lnHOURLY_RATE;
  end GET_HOURLY_RATE_FROM_NAT_ANA;

--**********************************************************************************************************--
  function GET_HOURLY_RATE_FROM_TASK(inGAL_TASK_ID number, idPOINTING_DATE date)
    return number
  is
    lnGAL_COST_CENTER_ID number := null;
    lnHOURLY_RATE        number := null;
  begin
    GAL_PROJECT_SPENDING.GET_DATA_FROM_TASK(inGAL_TASK_ID, idPOINTING_DATE, lnHOURLY_RATE, lnGAL_COST_CENTER_ID);
    return lnHOURLY_RATE;
  end GET_HOURLY_RATE_FROM_TASK;

--**********************************************************************************************************--
  function GET_HOURLY_RATE_FROM_RESS_OPE(
    inGAL_TASK_LINK_ID      number
  , inFAL_FACTORY_FLOOR_ID1 number
  , inFAL_FACTORY_FLOOR_ID2 number
  , inGAL_TASK_ID           number
  , idPOINTING_DATE         date
  )
    return number
  is
    lnHOURLY_RATE            number := null;
    lnFAL_GAL_COST_CENTER_ID number := null;
  begin
    GET_DATA_FROM_RESS_OPE(inGAL_TASK_LINK_ID
                         , inFAL_FACTORY_FLOOR_ID1
                         , inFAL_FACTORY_FLOOR_ID2
                         , inGAL_TASK_ID
                         , idPOINTING_DATE
                         , lnHOURLY_RATE
                         , lnFAL_GAL_COST_CENTER_ID
                          );
    return lnHOURLY_RATE;
  end GET_HOURLY_RATE_FROM_RESS_OPE;

  procedure InitGAL_HOURS_RATE_ECO(idPOINTING_DATE in GAL_COST_HOURLY_RATE.GCH_START_DATE%type)
  is
  begin
    update GAL_HOURS
       set HOU_HOURLY_RATE_ECO = GET_HOURLY_RATE_FROM_NAT_ANA(GAL_COST_CENTER_ID, HOU_POINTING_DATE, '01', null)
     where HOU_HOURLY_RATE_ECO is null
       and HOU_POINTING_DATE <= idPOINTING_DATE;

    update GAL_HOURS_JOURNAL
       set HOU_HOURLY_RATE_ECO = GET_HOURLY_RATE_FROM_NAT_ANA(GAL_COST_CENTER_ID, HOU_POINTING_DATE, '01', null)
     where HOU_HOURLY_RATE_ECO is null
       and HOU_POINTING_DATE <= idPOINTING_DATE;
  end;
end GAL_PROJECT_SPENDING;
