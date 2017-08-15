--------------------------------------------------------
--  DDL for Package Body SQM_INIT_METHOD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SQM_INIT_METHOD" 
is
/*--------------------------------------------------------------------------------------------------------------------*/
  procedure PUR_01_DELAY(
    pExpValue    in out SQM_PENALTY.SPE_EXPECTED_VALUE%type
  , pEffValue    out    SQM_PENALTY.SPE_EFFECTIVE_VALUE%type
  , pAxisValue   out    SQM_PENALTY.SPE_INIT_VALUE%type
  , pDocPosDetID in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  )
  is
    vDateDocument DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    vExpDate      DOC_DELAY_HISTORY.DHI_ACCEPT_DELAY%type;
  begin
    /* En cr�ation du d�tail la position */
    if pDocPosDetID is null then
      /*
       Le d�lai pris en compte est le PREMIER d�lai de r�ception du d�tail de position PDE_INTERMEDIATE_DELAY
      de type PUR-CONF post�rieur au dernier d�lai de type PUR-DEM .
      ATTENTION: si le d�tail de position est splitt� en plusieurs d�lais APRES que
      le d�lai ait �t� plac� � PUR-CONF, il y a des d�tails sans valeur PUR-DEM .
      --> si pas g�r�, la note est vide! .
      */
      begin   --exception 1 .
        -- Cas type: il existe un PUR-DEM et un PUR-CONF .
        select nvl(DHI_INTERMEDIATE_DELAY, sysdate)
          into vExpDate
          from (select DHI_INTERMEDIATE_DELAY
                  from
                       -- Premier d�lai de type PUR-CONF .
                       (select   DHI_INTERMEDIATE_DELAY
                            from doc_delay_history
                           where DOC_POSITION_DETAIL_ID = SQM_INIT_METHOD.DetailInfo.DOC_DOC_POSITION_DETAIL_ID
                             and dic_delay_update_type_id = 'PUR-CONF'
                             and A_DATECRE >=

                                   -- dernier d�lai de type PUR-DEM .
                                   (select A_DATECRE
                                      from (select   A_DATECRE
                                                from doc_delay_history
                                               where DOC_POSITION_DETAIL_ID = SQM_INIT_METHOD.DetailInfo.DOC_DOC_POSITION_DETAIL_ID
                                                 and dic_delay_update_type_id = 'PUR-DEM'
                                            order by A_DATECRE desc   -- DESC pour tri des PUR-DEM car on veut le dernier
                                                                   )
                                     where rownum = 1)
                        order by A_DATECRE asc   -- ASC pour tri des PUR-CONF car on veut le premier
                                              )
                 where rownum = 1);
      exception   --exception 1 : g�re le caso� il n'y a pas de PUR-CONF .
        when no_data_found then
          begin   -- exception 2
            -- dernier d�lai de type PUR-DEM . Existe tr�s souvent car initialis� par gabarit!
            select DHI_INTERMEDIATE_DELAY
              into vExpDate
              from (select   DHI_INTERMEDIATE_DELAY
                        from doc_delay_history
                       where DOC_POSITION_DETAIL_ID = SQM_INIT_METHOD.DetailInfo.DOC_DOC_POSITION_DETAIL_ID
                         and dic_delay_update_type_id = 'PUR-DEM'
                    order by A_DATECRE desc   -- DESC pour tri des PUR-DEM car on veut le dernier
                                           )
             where rownum = 1;
          exception   -- 2 .
            when no_data_found then
              vExpdate  := null;
          end;

          if vExpDate is null then
            begin
              -- C'est un d�tail sans PUR-DEM -- > on prend le PUR-CONF le plus ancien !
              select DHI_INTERMEDIATE_DELAY
                into vExpDate
                from (select   DHI_INTERMEDIATE_DELAY
                          from doc_delay_history
                         where DOC_POSITION_DETAIL_ID = SQM_INIT_METHOD.DetailInfo.DOC_DOC_POSITION_DETAIL_ID
                           and dic_delay_update_type_id = 'PUR-CONF'
                      order by A_DATECRE asc   -- ASC pour tri des PUR-CONF car on veut le plus ancien
                                            )
               where rownum = 1;
            exception   -- exception 3 .
              when no_data_found then
                raise_application_error(-20000, 'Ni d�lai confirm� ni d�lai demand� trouv�! Evaluation fournisseur impossible');
            end;   -- exception 3 .
          end if;
      end;   -- exception 1.

      -- Recherche date du document selon config
      select decode(upper(PCS.PC_CONFIG.GETCONFIG('SQM_REFERENCE_DATE') ), 'VAL', DOC.DMT_DATE_VALUE, DOC.DMT_DATE_DOCUMENT)
        into vDateDocument
        from DOC_POSITION POS
           , DOC_DOCUMENT DOC
       where POS.DOC_POSITION_ID = SQM_INIT_METHOD.DetailInfo.DOC_POSITION_ID
         and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID;

      -- Calcul du nombre de jour ouvr�s entre les deux dates
      -- selon calendrier du tiers si existe, selon calendrier par d�faut sinon.
      pAxisValue  := DOC_DELAY_FUNCTIONS.OpenDaysBetween(vExpDate, vDateDocument, '1', SQM_INIT_METHOD.DetailInfo.PAC_THIRD_ID);
      pExpValue   := to_char(vExpDate, 'dd.mm.yyyy');
      pEffValue   := to_char(vDateDocument, 'dd.mm.yyyy');
    /* En Modification du d�tail de la position */
    else
      begin
        select pExpValue
             , to_char(decode(upper(PCS.PC_CONFIG.GETCONFIG('SQM_REFERENCE_DATE') ), 'VAL', DOC.DMT_DATE_VALUE, DOC.DMT_DATE_DOCUMENT), 'dd.mm.yyyy')
             , DOC_DELAY_FUNCTIONS.OpenDaysBetween(to_date(pExpValue, 'dd.mm.yyyy')
                                                 , decode(upper(PCS.PC_CONFIG.GETCONFIG('SQM_REFERENCE_DATE') )
                                                        , 'VAL', DOC.DMT_DATE_VALUE
                                                        , DOC.DMT_DATE_DOCUMENT
                                                         )
                                                 , '1'
                                                 , POS.PAC_THIRD_ID
                                                  )
          into pExpValue
             , pEffValue
             , pAxisValue
          from DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE_EFF
             , DOC_POSITION_DETAIL PDE_EXP
             , DOC_DOCUMENT DOC
         where POS.DOC_POSITION_ID = PDE_EFF.DOC_POSITION_ID
           and PDE_EXP.DOC_POSITION_DETAIL_ID = PDE_EFF.DOC_DOC_POSITION_DETAIL_ID
           and PDE_EFF.DOC_POSITION_DETAIL_ID = pDocPosDetID
           and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID;
      exception
        when ex.TABLE_MUTATING then   -- trigger de mise � jour de la date document DOC_DMT_AU_SQM_PENALTY
          select pExpValue
               , to_char(SQM_INIT_METHOD.dtDateDoc, 'dd.mm.yyyy')
               , DOC_DELAY_FUNCTIONS.OpenDaysBetween(to_date(pExpValue, 'dd.mm.yyyy'), SQM_INIT_METHOD.dtDateDoc, '1', PDE_EFF.PAC_THIRD_ID)
            into pExpValue
               , pEffValue
               , pAxisValue
            from DOC_POSITION_DETAIL PDE_EXP
               , DOC_POSITION_DETAIL PDE_EFF
           where PDE_EXP.DOC_POSITION_DETAIL_ID = PDE_EFF.DOC_DOC_POSITION_DETAIL_ID
             and PDE_EFF.DOC_POSITION_DETAIL_ID = pDocPosDetID;
        when no_data_found then   -- calcul des notes en attente
          select to_char(SQM_INIT_METHOD.dtDateDoc, 'dd.mm.yyyy')
               , to_date(pExpValue, 'dd.mm.yyyy')
               , DOC_DELAY_FUNCTIONS.opendaysbetween(to_date(pExpValue, 'dd.mm.yyyy'), SQM_INIT_METHOD.dtDateDoc, '1', pac_third_id)
            into pEffValue
               , pExpValue
               , pAxisValue
            from DOC_POSITION_DETAIL
           where doc_position_detail_Id = pdocposdetid;
      end;
    end if;
  end PUR_01_DELAY;

/*--------------------------------------------------------------------------------------------------------------------*/

  /*--------------------------------------------------------------------------------------------------------------------*/
/*
Le respect de la quantit� attendue des fournisseurs est calcul� en fonction:
 �   de l'�cart entre la quantit� attendue et la quantit� livr�e
 �   rapport� au nombre de d�tails de positions livr�s dans la p�riode d'�valuation
Renvoie directement le pourcentage (2 = 2%, 5 = 5% etc...) .
Arrondir � 2 d�cimales maximum car la notation ne peut g�rer que 2 d�cimales maximum.
*/
/*--------------------------------------------------------------------------------------------------------------------*/
  procedure PUR_02_QUANTITY(
    pExpValue    in out SQM_PENALTY.SPE_EXPECTED_VALUE%type
  , pEffValue    out    SQM_PENALTY.SPE_EFFECTIVE_VALUE%type
  , pAxisValue   out    SQM_PENALTY.SPE_INIT_VALUE%type
  , pDocPosDetID in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  )
  is
    vGap DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type;
    vDic gco_good.dic_good_family_id%type;
    vPct number;
  begin   -- proc�dure
    vGap        := 0;
    vPct        := 0;

    /* En cr�ation du d�tail la position */
    if pDocPosDetId is null then
      select nvl(pExpValue, PDE_EXP.PDE_FINAL_QUANTITY)
           , SQM_INIT_METHOD.DetailInfo.PDE_FINAL_QUANTITY
           , case
               when nvl(pExpValue, PDE_EXP.PDE_FINAL_QUANTITY) = 0 then null   -- caso� il reste 0 sur la position du doc p�re
               else round( (SQM_INIT_METHOD.DetailInfo.PDE_FINAL_QUANTITY - nvl(pExpValue, PDE_EXP.PDE_FINAL_QUANTITY) ) /
                          (case
                             when SQM_INIT_METHOD.DetailInfo.PDE_FINAL_QUANTITY = 0 then 1
                             --else SQM_INIT_METHOD.DetailInfo.PDE_FINAL_QUANTITY
                           else PDE_EXP.PDE_FINAL_QUANTITY
                           end
                          ) *
                          100
                        , 2
                         )
             end
        into pExpValue
           , pEffValue
           , vPct
        from DOC_POSITION_DETAIL PDE_EXP
           ,   -- d�tail du document p�re
             gco_good gco
       where PDE_EXP.DOC_POSITION_DETAIL_ID = SQM_INIT_METHOD.DetailInfo.DOC_DOC_POSITION_DETAIL_ID
         and pde_exp.gco_good_id = gco.gco_good_id;
    /* En Modification du d�tail la position */
    else
      begin
        select pExpValue
             , PDE_EFF.PDE_FINAL_QUANTITY
             , case
                 when pExpValue = 0 then null
                 else round( (SQM_INIT_METHOD.DetailInfo.PDE_FINAL_QUANTITY - nvl(pExpValue, PDE_EXP.PDE_FINAL_QUANTITY) ) /
                            (case
                               when SQM_INIT_METHOD.DetailInfo.PDE_FINAL_QUANTITY = 0 then 1
                               --else SQM_INIT_METHOD.DetailInfo.PDE_FINAL_QUANTITY
                             else PDE_EXP.PDE_FINAL_QUANTITY
                             end
                            ) *
                            100
                          , 2
                           )
               end
          into pExpValue
             , pEffValue
             , vPct
          from DOC_POSITION_DETAIL PDE_EXP
             , DOC_POSITION_DETAIL PDE_EFF
         where PDE_EXP.DOC_POSITION_DETAIL_ID = PDE_EFF.DOC_DOC_POSITION_DETAIL_ID
           and PDE_EFF.DOC_POSITION_DETAIL_ID = pDocPosDetID;
      exception
        when no_data_found then   -- calcul des notes en attente
          select PDE.PDE_FINAL_QUANTITY
            into pExpValue
            from DOC_POSITION_DETAIL PDE
           where PDE.DOC_POSITION_DETAIL_ID = pDocPosDetId;

          pEffValue  := SQM_INIT_METHOD.DetailInfo.PDE_FINAL_QUANTITY;

          select case
                   when pExpValue = 0 then null
                   else (pEffValue - pExpValue) / pExpValue
                 end
            into vPct
            from dual;
      end;
    end if;

    pAxisValue  := to_char(vPct);
  end PUR_02_QUANTITY;

/*--------------------------------------------------------------------------------------------------------------------*/

  /*--------------------------------------------------------------------------------------------------------------------*/
/*
Le respect de la qualit� attendue des fournisseurs est calcul� en fonction:
 �   du nombre de points attribu�s � la d�cision qualit� (selon tabelle ci-dessous)
 �   rapport�e au nombre de d�tails de positions livr�s dans la p�riode d'�valuation

Accepter    0.
D�roger    5.
Trier    10.
Retoucher    15.
Refuser    20.

la m�thode retourne Accepter si le gabarit est:
o    PUR-RN-Reception Note
o    PUR-SE-Stock Entry

et Refuser dans les autres cas
--> si le gabarit est
o    PUR-SEWS-Scrap Entry (with supply)
o    PUR-SENS-Scrap Entry (no supply)
o    PUR-GRWS-Goods Return (with supply)
o    PUR-GRNS-Goods Return (no supply)
*/
/*--------------------------------------------------------------------------------------------------------------------*/
  procedure PUR_03_QUALITY(
    pExpValue    in out SQM_PENALTY.SPE_EXPECTED_VALUE%type
  , pEffValue    out    SQM_PENALTY.SPE_EFFECTIVE_VALUE%type
  , pAxisValue   out    SQM_PENALTY.SPE_INIT_VALUE%type
  , pDocPosDetID in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  )
  is
    vGauge      DOC_POSITION_DETAIL.DOC_GAUGE_ID%type;
    vGaugeTitle DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE%type;
    vPct        number;
  begin   -- proc�dure
    vPct  := 0;

    /* En cr�ation du d�tail la position */
    if pDocPosDetId is null then
      --R�cup�ration du c_gauge_title du document cible
      select c_gauge_title
        into vGaugeTitle
        from DOC_DOCUMENT DOC
           , DOC_GAUGE_STRUCTURED DGS
       where DOC.DOC_GAUGE_ID = DGS.DOC_GAUGE_ID
         and DOC.DOC_DOCUMENT_ID = SQM_INIT_METHOD.DetailInfo.DOC_DOCUMENT_ID;

      if vGaugeTitle = '3'   -- Bulletin fournisseur Stock
                          then
        pAxisValue  := '01';   --Accepter;
        pExpValue   := '01';
        pEffValue   := '01';
      else
        pAxisValue  := '05';   --Refuser;
        pExpValue   := '05';
        pEffValue   := '05';
      end if;
    /* En Modification du d�tail la position */
    else
      select c_gauge_title
        into vGaugeTitle
        from DOC_POSITION_DETAIL PDE
           , DOC_GAUGE_STRUCTURED DGS
       where PDE.DOC_GAUGE_ID = DGS.DOC_GAUGE_ID
         and PDE.DOC_POSITION_DETAIL_ID = pDocPosDetId;

      if vGaugeTitle = '3'   -- Bulletin fournisseur Stock
                          then
        pAxisValue  := '01';   --Accepter;
        pExpValue   := '01';
        pEffValue   := '01';
      else
        pAxisValue  := '05';   --Refuser;
        pExpValue   := '05';
        pEffValue   := '05';
      end if;
    end if;
  end PUR_03_QUALITY;

/*--------------------------------------------------------------------------------------------------------------------*/

  /*--------------------------------------------------------------------------------------------------------------------*/
  procedure PUR_04_PRICE_STD_SUB(
    pExpValue    in out SQM_PENALTY.SPE_EXPECTED_VALUE%type
  , pEffValue    out    SQM_PENALTY.SPE_EFFECTIVE_VALUE%type
  , pAxisValue   out    SQM_PENALTY.SPE_INIT_VALUE%type
  , pDocPosDetID in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  )
  is
    vPct      number;
    vExpvalue number;   -- variable temporaire pour faire les calculs avec pleins de d�cimales.
    vEffvalue number;   -- variable temporaire pour faire les calculs avec pleins de d�cimales.
    vTmpValue number;
  begin
    vPct        := 0;

    -- En cr�ation
    if pDocPosDetID is null then
      -- Informations de la PO .
      for V1 in (select DOCPO.DMT_NUMBER
                      , POSPO.POS_NUMBER
                      , POSPO.POS_NET_VALUE_EXCL
                      , POSPO.POS_FINAL_QUANTITY
                      , POSPO.POS_NET_UNIT_VALUE POS_NET_UNIT_VALUE_EXCL
                      , GAUPO.GAU_DESCRIBE
                      , DGSPO.C_GAUGE_TITLE
                      , DOCPO.DOC_DOCUMENT_ID
                      , GAUPO.DOC_GAUGE_ID
                   from DOC_DOCUMENT DOCPO
                      , DOC_POSITION POSPO
                      , DOC_GAUGE GAUPO
                      , DOC_GAUGE_STRUCTURED DGSPO
                      , (select     level LEVEL_DOC
                                  , DOC_POSITION_DETAIL_ID
                                  , DOC_DOC_POSITION_DETAIL_ID
                                  , DOC_POSITION_ID
                               from DOC_POSITION_DETAIL DET
                         start with DET.DOC_POSITION_DETAIL_ID = SQM_INIT_METHOD.DetailInfo.DOC_DOC_POSITION_DETAIL_ID
                         connect by prior DET.DOC_DOC_POSITION_DETAIL_ID = DET.DOC_POSITION_DETAIL_ID
                           order siblings by DET.DOC_DOC_POSITION_DETAIL_ID) FATHERS_DOC
                  where DOCPO.DOC_DOCUMENT_ID = POSPO.DOC_DOCUMENT_ID
                    and POSPO.DOC_GAUGE_ID = GAUPO.DOC_GAUGE_ID
                    and GAUPO.DOC_GAUGE_ID = DGSPO.DOC_GAUGE_ID
                    and POSPO.DOC_POSITION_ID = FATHERS_DOC.DOC_POSITION_ID
                    and GAUPO.DIC_GAUGE_CATEG_ID in('PUR-PO', 'SUB-SSO')   -- ACHATS STANDARDS ET SOUS-TRAITANCE (HORS ACHATS QUICK PAYMENT)
                                                                        ) loop
        /*
         Infos sur la position de facture en cours de d�charge
         Contrairement au d�tail en cours de d�charge, la position, elle, existe d�j� !
         Les prix de la facture sont donc connus
         (et si non modifi�s, identiques � ceux de la commande)
        */
        for VINV in (select DOCINV.DMT_NUMBER DMT_NUMBER_INV
                          , DOCINV.DMT_DATE_DOCUMENT DMT_DATE_INV
                          , DOCINV.DMT_BASE_PRICE DMT_BASE_PRICE_INV
                          , DOCINV.ACS_FINANCIAL_CURRENCY_ID DMT_LOCAL_CURRENCY_INV
                          , POSINV.POS_NUMBER POS_NUMBER_INV
                          , POSINV.POS_NET_VALUE_EXCL POS_NET_VALUE_EXCL_INV
                          , POSINV.POS_FINAL_QUANTITY POS_FINAL_QUANTITY_INV
                          , case
                              when POSINV.POS_FINAL_QUANTITY = 0 then 0
                              else POSINV.POS_NET_VALUE_EXCL_B / POSINV.POS_FINAL_QUANTITY
                            end POS_NET_UNIT_VALUE_EXCL_INV
                          , case
                              when DOCINV.DMT_BASE_PRICE = 0 then 0
                              else DOCINV.DMT_RATE_OF_EXCHANGE / DOCINV.DMT_BASE_PRICE
                            end INV_RATE_OF_EXCHANGE
                       from DOC_DOCUMENT DOCINV
                          , DOC_POSITION POSINV
                      where DOCINV.DOC_DOCUMENT_ID = POSINV.DOC_DOCUMENT_ID
                        and POSINV.DOC_POSITION_ID = SQM_INIT_METHOD.DetailInfo.DOC_POSITION_ID) loop
          /*
          Faire le calcul avec les variables locales pour �viter la perte de pr�cision
          li�e au fait que les variables de retour sont en varchar2(30):

          Valeur attendue = valeur de la commande, convertie au taux de change de la facture
          car la facture peut �tre dans une monnaie diff�rente de la commande.
          */
--
          if VINV.INV_RATE_OF_EXCHANGE = 0 then
            vExpValue  := 0;
          else
            ACS_FUNCTION.ConvertAmount(nvl(V1.POS_NET_UNIT_VALUE_EXCL, 0)
                                     , VINV.DMT_LOCAL_CURRENCY_INV
                                     , ACS_FUNCTION.GetLocalCurrencyID
                                     , VINV.DMT_DATE_INV
                                     , VINV.INV_RATE_OF_EXCHANGE
                                     , VINV.DMT_BASE_PRICE_INV
                                     , 0
                                     , vTmpValue
                                     , vExpValue
                                      );
          end if;

          -- Valeur effective = valeur de la facture .
          vEffValue  := VINV.POS_NET_UNIT_VALUE_EXCL_INV;
          vPct       := case
                         when vExpValue = 0 then 0   -- la meilleure note car pas de comparaison possible
                         else ( (vEffValue - vExpValue) / vExpValue) * 100
                       end;
        end loop;   -- VINV .
      end loop;   -- V1;
    --RAISE_APPLICATION_ERROR(-20000,'fin loop cr�ation:' || pEffvalue);
    else   -- en modification (recalcule apr�s modification de la date document ou de la quantit� du d�tail)
      begin
        -- Informations de la PO .
        for V1 in (select DOCPO.DMT_NUMBER
                        , POSPO.POS_NUMBER
                        , POSPO.POS_NET_VALUE_EXCL
                        , POSPO.POS_FINAL_QUANTITY
                        , POSPO.POS_NET_UNIT_VALUE POS_NET_UNIT_VALUE_EXCL
                        , GAUPO.GAU_DESCRIBE
                        , DGSPO.C_GAUGE_TITLE
                        , DOCPO.DOC_DOCUMENT_ID
                        , GAUPO.DOC_GAUGE_ID
                     from DOC_DOCUMENT DOCPO
                        , DOC_POSITION POSPO
                        , DOC_GAUGE GAUPO
                        , DOC_GAUGE_STRUCTURED DGSPO
                        , (select     level LEVEL_DOC
                                    , DOC_POSITION_DETAIL_ID
                                    , DOC_DOC_POSITION_DETAIL_ID
                                    , DOC_POSITION_ID
                                 from DOC_POSITION_DETAIL DET
                           start with DET.DOC_POSITION_DETAIL_ID = pDocPosDetID
                           connect by prior DET.DOC_DOC_POSITION_DETAIL_ID = DET.DOC_POSITION_DETAIL_ID
                             order siblings by DET.DOC_DOC_POSITION_DETAIL_ID) FATHERS_DOC
                    where DOCPO.DOC_DOCUMENT_ID = POSPO.DOC_DOCUMENT_ID
                      and POSPO.DOC_GAUGE_ID = GAUPO.DOC_GAUGE_ID
                      and GAUPO.DOC_GAUGE_ID = DGSPO.DOC_GAUGE_ID
                      and POSPO.DOC_POSITION_ID = FATHERS_DOC.DOC_POSITION_ID
                      and GAUPO.DIC_GAUGE_CATEG_ID in('PUR-PO', 'SUB-SSO')   -- ACHATS STANDARDS ET SOUS-TRAITANCE (HORS ACHATS QUICK PAYMENT)
                                                                          ) loop
          /*
           Infos sur la position de facture en cours de d�charge
           Contrairement au d�tail en cours de d�charge, la position, elle, existe d�j� !
           Les prix de la facture sont donc connus
           (et si non modifi�s, identiques � ceux de la commande)
          */
          for VINV in (select DOCINV.DMT_NUMBER DMT_NUMBER_INV
                            , DOCINV.DMT_DATE_DOCUMENT DMT_DATE_INV
                            , DOCINV.DMT_BASE_PRICE DMT_BASE_PRICE_INV
                            , DOCINV.ACS_FINANCIAL_CURRENCY_ID DMT_LOCAL_CURRENCY_INV
                            , POSINV.POS_NUMBER POS_NUMBER_INV
                            , POSINV.POS_NET_VALUE_EXCL POS_NET_VALUE_EXCL_INV
                            , POSINV.POS_FINAL_QUANTITY POS_FINAL_QUANTITY_INV
                            , case
                                when POSINV.POS_FINAL_QUANTITY = 0 then 0
                                else POSINV.POS_NET_VALUE_EXCL_B / POSINV.POS_FINAL_QUANTITY
                              end POS_NET_UNIT_VALUE_EXCL_INV
                            , case
                                when DOCINV.DMT_BASE_PRICE = 0 then 0
                                else DOCINV.DMT_RATE_OF_EXCHANGE / DOCINV.DMT_BASE_PRICE
                              end INV_RATE_OF_EXCHANGE
                         from DOC_DOCUMENT DOCINV
                            , DOC_POSITION POSINV
                            ,
                              -- modif par rapport au cas de la cr�ation ci-dessus: ajout du d�tail
                              -- car on n'a que le pDocPosDetID � disposition .
                              DOC_POSITION_DETAIL PDEINV
                        where DOCINV.DOC_DOCUMENT_ID = POSINV.DOC_DOCUMENT_ID
                          and POSINV.DOC_POSITION_ID = PDEINV.DOC_POSITION_ID
                          and PDEINV.DOC_POSITION_DETAIL_ID = pDocPosDetID) loop
            /*
            Faire le calcul avec les variables locales pour �viter la perte de pr�cision
            li�e au fait que les variables de retour sont en varchar2(30):

            Valeur attendue = valeur de la commande, convertie au taux de change de la facture
            car la facture peut �tre dans une monnaie diff�rente de la commande.
            */
            if VINV.INV_RATE_OF_EXCHANGE = 0 then
              vExpValue  := 0;
            else
              ACS_FUNCTION.ConvertAmount(nvl(V1.POS_NET_UNIT_VALUE_EXCL, 0)
                                       , VINV.DMT_LOCAL_CURRENCY_INV
                                       , ACS_FUNCTION.GetLocalCurrencyID
                                       , VINV.DMT_DATE_INV
                                       , VINV.INV_RATE_OF_EXCHANGE
                                       , VINV.DMT_BASE_PRICE_INV
                                       , 0
                                       , vTmpValue
                                       , vExpValue
                                        );
            end if;

            -- Valeur effective = valeur de la facture .
            vEffValue  := VINV.POS_NET_UNIT_VALUE_EXCL_INV;
            vPct       := case
                           when vExpValue = 0 then 0   -- la meilleure note car pas de comparaison possible
                           else ( (vEffValue - vExpValue) / vExpValue) * 100
                         end;
          end loop;   -- VINV .
        end loop;   -- V1;
      exception
        when ex.TABLE_MUTATING then   -- trigger de mise � jour du prix de la position (table DOC_POSITION is mutating)
          --vEffValue  := SQM_INIT_METHOD.PosNetUnitValue;
          vEffValue  := case
                         when PosFinalQuantity = 0 then 0
                         else PosNetUnitValBase / PosFinalQuantity
                       end;
          ACS_FUNCTION.ConvertAmount(nvl(PosNetUnitValue, 0)
                                   , DocLocalCurrencyId
                                   , ACS_FUNCTION.GetLocalCurrencyID
                                   , dtDateDoc
                                   , DocRateofExchInv
                                   , DocBasePrice
                                   , 0
                                   , vTmpValue
                                   , vExpValue
                                    );

          /*pExpValue correspond � la valeur issue la commande fournisseur (PO-...) .
            ET stock�e dans la note existante
            (car cette exception ne survient qu'en modification et non en cr�ation!).

            pExpValue est donc d�j� convertie dans la monnaie de la facture et peut donc �tre
            directement compar�e � la valeur effective stock�e dans pEffValue.
          */
          if vExpValue = 0 then
            vPct  := 0;   -- la meilleure note car pas de comparaison possible
          else
            vPct  := ( (vEffValue - vExpValue) / vExpValue) * 100;
          end if;
      end;
    end if;

    -- arrondi apr�s le calcul !
    -- affectation aux variable de retours qui sont en varchar2(30);
    -- Arrondi � 2 car la plupart des monnaies ne g�rent que 2 d�cimales
    pExpValue   := round(vExpvalue, 2);
    pEffValue   := round(vEffValue, 2);
    -- Valeur de l'axe pour la variable de retour.
    -- 2 d�cimales car la notation n'en g�re que 2 au maximum .
    pAxisValue  := round(vPct, 2);
  end PUR_04_PRICE_STD_SUB;

/*--------------------------------------------------------------------------------------------------------------------*/
  procedure PUR_04_PRICE_QUICK_PAYEMENT(
    pExpValue    in out SQM_PENALTY.SPE_EXPECTED_VALUE%type
  , pEffValue    out    SQM_PENALTY.SPE_EFFECTIVE_VALUE%type
  , pAxisValue   out    SQM_PENALTY.SPE_INIT_VALUE%type
  , pDocPosDetID in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  )
  is
    vPct      number;
    vExpvalue number;   -- variable temporaire pour faire les calculs avec pleins de d�cimales.
    vEffvalue number;   -- variable temporaire pour faire les calculs avec pleins de d�cimales.
    vTmpValue number;
  begin
    vPct        := 0;

    -- En cr�ation
    if pDocPosDetID is null then
      -- Informations de la PO .
      for V1 in (select DOCPO.DMT_NUMBER
                      , POSPO.POS_NUMBER
                      , POSPO.POS_NET_VALUE_EXCL
                      , POSPO.POS_FINAL_QUANTITY
                      , POSPO.POS_NET_UNIT_VALUE POS_NET_UNIT_VALUE_EXCL
                      , GAUPO.GAU_DESCRIBE
                      , DGSPO.C_GAUGE_TITLE
                      , DOCPO.DOC_DOCUMENT_ID
                      , GAUPO.DOC_GAUGE_ID
                   from DOC_DOCUMENT DOCPO
                      , DOC_POSITION POSPO
                      , DOC_GAUGE GAUPO
                      , DOC_GAUGE_STRUCTURED DGSPO
                      , (select     level LEVEL_DOC
                                  , DOC_POSITION_DETAIL_ID
                                  , DOC_DOC_POSITION_DETAIL_ID
                                  , DOC_POSITION_ID
                               from DOC_POSITION_DETAIL DET
                         start with DET.DOC_POSITION_DETAIL_ID = SQM_INIT_METHOD.DetailInfo.DOC2_DOC_POSITION_DETAIL_ID   -- parent en copie .
                         connect by prior DET.DOC_DOC_POSITION_DETAIL_ID = DET.DOC_POSITION_DETAIL_ID
                           order siblings by DET.DOC_DOC_POSITION_DETAIL_ID) FATHERS_DOC
                  where DOCPO.DOC_DOCUMENT_ID = POSPO.DOC_DOCUMENT_ID
                    and POSPO.DOC_GAUGE_ID = GAUPO.DOC_GAUGE_ID
                    and GAUPO.DOC_GAUGE_ID = DGSPO.DOC_GAUGE_ID
                    and POSPO.DOC_POSITION_ID = FATHERS_DOC.DOC_POSITION_ID
                    and GAUPO.DIC_GAUGE_CATEG_ID = 'PUR-PO'   -- ACHATS QUICK PAYMENT
                                                           ) loop
        /*
         Infos sur la position de facture en cours de d�charge
         Contrairement au d�tail en cours de d�charge, la position, elle, existe d�j� !
         Les prix de la facture sont donc connus
         (et si non modifi�s, identiques � ceux de la commande)
        */
        for VINV in (select DOCINV.DMT_NUMBER DMT_NUMBER_INV
                          , DOCINV.DMT_DATE_DOCUMENT DMT_DATE_INV
                          , DOCINV.DMT_BASE_PRICE DMT_BASE_PRICE_INV
                          , DOCINV.ACS_FINANCIAL_CURRENCY_ID DMT_LOCAL_CURRENCY_INV
                          , POSINV.POS_NUMBER POS_NUMBER_INV
                          , POSINV.POS_NET_VALUE_EXCL POS_NET_VALUE_EXCL_INV
                          , POSINV.POS_FINAL_QUANTITY POS_FINAL_QUANTITY_INV
                          , case
                              when POSINV.POS_FINAL_QUANTITY = 0 then 0
                              else POSINV.POS_NET_VALUE_EXCL_B / POSINV.POS_FINAL_QUANTITY
                            end POS_NET_UNIT_VALUE_EXCL_INV
                          , case
                              when DOCINV.DMT_BASE_PRICE = 0 then 0
                              else DOCINV.DMT_RATE_OF_EXCHANGE / DOCINV.DMT_BASE_PRICE
                            end INV_RATE_OF_EXCHANGE
                       from DOC_DOCUMENT DOCINV
                          , DOC_POSITION POSINV
                      where DOCINV.DOC_DOCUMENT_ID = POSINV.DOC_DOCUMENT_ID
                        and POSINV.DOC_POSITION_ID = SQM_INIT_METHOD.DetailInfo.DOC_POSITION_ID) loop
          /*
          Faire le calcul avec les variables locales pour �viter la perte de pr�cision
          li�e au fait que les variables de retour sont en varchar2(30):

          Valeur attendue = valeur de la commande, convertie au taux de change de la facture
          car la facture peut �tre dans une monnaie diff�rente de la commande.
          */
          if VINV.INV_RATE_OF_EXCHANGE = 0 then
            vExpValue  := 0;
          else
            ACS_FUNCTION.ConvertAmount(nvl(V1.POS_NET_UNIT_VALUE_EXCL, 0)
                                     , VINV.DMT_LOCAL_CURRENCY_INV
                                     , ACS_FUNCTION.GetLocalCurrencyID
                                     , VINV.DMT_DATE_INV
                                     , VINV.INV_RATE_OF_EXCHANGE
                                     , VINV.DMT_BASE_PRICE_INV
                                     , 0
                                     , vTmpValue
                                     , vExpValue
                                      );
          end if;

          -- Valeur effective = valeur de la facture .
          vEffValue  := VINV.POS_NET_UNIT_VALUE_EXCL_INV;
          vPct       := case
                         when vExpValue = 0 then 0   -- la meilleure note car pas de comparaison possible
                         else ( (vEffValue - vExpValue) / vExpValue) * 100
                       end;
        end loop;   -- VINV .
      end loop;   -- V1;
    --RAISE_APPLICATION_ERROR(-20000,'fin loop cr�ation:' || pEffvalue);
    else   -- en modification (recalcule apr�s modification de la date document ou de la quantit� du d�tail)
      begin
        -- Informations de la PO .
        for V1 in (select DOCPO.DMT_NUMBER
                        , POSPO.POS_NUMBER
                        , POSPO.POS_NET_VALUE_EXCL
                        , POSPO.POS_FINAL_QUANTITY
                        , POSPO.POS_NET_UNIT_VALUE POS_NET_UNIT_VALUE_EXCL
                        , GAUPO.GAU_DESCRIBE
                        , DGSPO.C_GAUGE_TITLE
                        , DOCPO.DOC_DOCUMENT_ID
                        , GAUPO.DOC_GAUGE_ID
                     from DOC_DOCUMENT DOCPO
                        , DOC_POSITION POSPO
                        , DOC_GAUGE GAUPO
                        , DOC_GAUGE_STRUCTURED DGSPO
                        , (select     level LEVEL_DOC
                                    , DOC_POSITION_DETAIL_ID
                                    , DOC_DOC_POSITION_DETAIL_ID
                                    , DOC_POSITION_ID
                                 from DOC_POSITION_DETAIL DET
                           start with DET.DOC_POSITION_DETAIL_ID = (select DOC2_DOC_POSITION_DETAIL_ID
                                                                      from DOC_POSITION_DETAIL
                                                                     where DOC_POSITION_DETAIL_ID = pDocPosDetID)
                           connect by prior DET.DOC_DOC_POSITION_DETAIL_ID = DET.DOC_POSITION_DETAIL_ID
                             order siblings by DET.DOC_DOC_POSITION_DETAIL_ID) FATHERS_DOC
                    where DOCPO.DOC_DOCUMENT_ID = POSPO.DOC_DOCUMENT_ID
                      and POSPO.DOC_GAUGE_ID = GAUPO.DOC_GAUGE_ID
                      and GAUPO.DOC_GAUGE_ID = DGSPO.DOC_GAUGE_ID
                      and POSPO.DOC_POSITION_ID = FATHERS_DOC.DOC_POSITION_ID
                      and GAUPO.DIC_GAUGE_CATEG_ID = 'PUR-PO'   -- ACHATS QUICK PAYMENT
                                                             ) loop
          /*
           Infos sur la position de facture en cours de d�charge
           Contrairement au d�tail en cours de d�charge, la position, elle, existe d�j� !
           Les prix de la facture sont donc connus
           (et si non modifi�s, identiques � ceux de la commande)
          */
          for VINV in (select DOCINV.DMT_NUMBER DMT_NUMBER_INV
                            , DOCINV.DMT_DATE_DOCUMENT DMT_DATE_INV
                            , DOCINV.DMT_BASE_PRICE DMT_BASE_PRICE_INV
                            , DOCINV.ACS_FINANCIAL_CURRENCY_ID DMT_LOCAL_CURRENCY_INV
                            , POSINV.POS_NUMBER POS_NUMBER_INV
                            , POSINV.POS_NET_VALUE_EXCL POS_NET_VALUE_EXCL_INV
                            , POSINV.POS_FINAL_QUANTITY POS_FINAL_QUANTITY_INV
                            , case
                                when POSINV.POS_FINAL_QUANTITY = 0 then 0
                                else POSINV.POS_NET_VALUE_EXCL_B / POSINV.POS_FINAL_QUANTITY
                              end POS_NET_UNIT_VALUE_EXCL_INV
                            , case
                                when DOCINV.DMT_BASE_PRICE = 0 then 0
                                else DOCINV.DMT_RATE_OF_EXCHANGE / DOCINV.DMT_BASE_PRICE
                              end INV_RATE_OF_EXCHANGE
                         from DOC_DOCUMENT DOCINV
                            , DOC_POSITION POSINV
                            ,
                              -- modif par rapport au cas de la cr�ation ci-dessus: ajout du d�tail
                              -- car on n'a que le pDocPosDetID � disposition .
                              DOC_POSITION_DETAIL PDEINV
                        where DOCINV.DOC_DOCUMENT_ID = POSINV.DOC_DOCUMENT_ID
                          and POSINV.DOC_POSITION_ID = PDEINV.DOC_POSITION_ID
                          and PDEINV.DOC_POSITION_DETAIL_ID = pDocPosDetID) loop
            /*
            Faire le calcul avec les variables locales pour �viter la perte de pr�cision
            li�e au fait que les variables de retour sont en varchar2(30):

            Valeur attendue = valeur de la commande, convertie au taux de change de la facture
            car la facture peut �tre dans une monnaie diff�rente de la commande.
            */
            if VINV.INV_RATE_OF_EXCHANGE = 0 then
              vExpValue  := 0;
            else
              ACS_FUNCTION.ConvertAmount(nvl(V1.POS_NET_UNIT_VALUE_EXCL, 0)
                                       , VINV.DMT_LOCAL_CURRENCY_INV
                                       , ACS_FUNCTION.GetLocalCurrencyID
                                       , VINV.DMT_DATE_INV
                                       , VINV.INV_RATE_OF_EXCHANGE
                                       , VINV.DMT_BASE_PRICE_INV
                                       , 0
                                       , vTmpValue
                                       , vExpValue
                                        );
            end if;

            -- Valeur effective = valeur de la facture .
            vEffValue  := VINV.POS_NET_UNIT_VALUE_EXCL_INV;
            vPct       := case
                           when vExpValue = 0 then 0   -- la meilleure note car pas de comparaison possible
                           else ( (vEffValue - vExpValue) / vExpValue) * 100
                         end;
          end loop;   -- VINV .
        end loop;   -- V1;
      exception
        when ex.TABLE_MUTATING then   -- trigger de mise � jour du prix de la position (table DOC_POSITION is mutating)
          vEffValue  := case
                         when PosFinalQuantity = 0 then 0
                         else PosNetUnitValBase / PosFinalQuantity
                       end;
          ACS_FUNCTION.ConvertAmount(nvl(PosNetUnitValue, 0)
                                   , DocLocalCurrencyId
                                   , ACS_FUNCTION.GetLocalCurrencyID
                                   , dtDateDoc
                                   , DocRateofExchInv
                                   , DocBasePrice
                                   , 0
                                   , vTmpValue
                                   , vExpValue
                                    );

          /*pExpValue correspond � la valeur issue la commande fournisseur (PO-...) .
            ET stock�e dans la note existante
            (car cette exception ne survient qu'en modification et non en cr�ation!).

            pExpValue est donc d�j� convertie dans la monnaie de la facture et peut donc �tre
            directement compar�e � la valeur effective stock�e dans pEffValue.
          */
          if vExpValue = 0 then
            vPct  := 0;   -- la meilleure note car pas de comparaison possible
          else
            vPct  := ( (vEffValue - vExpValue) / vExpValue) * 100;
          end if;
      end;
    end if;

    -- arrondi apr�s le calcul !
    -- affectation aux variable de retours qui sont en varchar2(30);
    -- Arrondi � 2 car la plupart des monnaies ne g�rent que 2 d�cimales
    pExpValue   := round(vExpvalue, 2);
    pEffValue   := round(vEffValue, 2);
    -- Valeur de l'axe pour la variable de retour.
    -- 2 d�cimales car la notation n'en g�re que 2 au maximum .
    pAxisValue  := to_char(round(vPct, 2) );
  end PUR_04_PRICE_QUICK_PAYEMENT;

/*--------------------------------------------------------------------------------------------------------------------*/

  /*--------------------------------------------------------------------------------------------------------------------*/
  procedure PUR_04_PRICE(
    pExpValue    in out SQM_PENALTY.SPE_EXPECTED_VALUE%type
  , pEffValue    out    SQM_PENALTY.SPE_EFFECTIVE_VALUE%type
  , pAxisValue   out    SQM_PENALTY.SPE_INIT_VALUE%type
  , pDocPosDetID in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  )
  is
    /*
     Appelle la proc�dure de calcul appropri�e pour l'axe prix.
     Achats avec paiement apr�s r�ception + sous-traitance --> PUR_04_PRICE_STD_SUB
     Achats avec Quick Payement --PUR_04_PRICE_QUICK_PAYEMENT
     Cette proc�dure est � placer apr�s les autres proc�dures PUR_04_PRICE_xxx
     pour que ces derni�res soient reconnues lors de leur appel ci-dessous car les
     proc�dures PUR_04_PRICE_xxx ne sont pas d�clar�es dans le header du package.
    */
    vCategId   DIC_GAUGE_CATEG.DIC_GAUGE_CATEG_ID%type;
    vExpvalue  number;   -- variable temporaire pour faire les calculs avec pleins de d�cimales.
    vEffvalue  number;   -- variable temporaire pour faire les calculs avec pleins de d�cimales.
    vAxisValue number;
  begin
    vExpvalue   := pExpvalue;
    vEffvalue   := pEffvalue;
    vAxisValue  := pAxisValue;

    -- En cr�ation
    if pDocPosDetID is null then
      select dic_gauge_categ_id
        into vCategId
        from doc_gauge gau
           , doc_position pos
       where pos.doc_gauge_id = gau.doc_gauge_id
         and pos.doc_position_id = SQM_INIT_METHOD.DetailInfo.doc_position_id;
    else
      select dic_gauge_categ_id
        into vCategId
        from doc_gauge gau
           , doc_position_detail pde
       where pde.doc_gauge_id = gau.doc_gauge_id
         and pde.doc_position_detail_id = pDocPosDetID;
    end if;

    if vCategId = 'PUR-INVQ' then
      PUR_04_PRICE_QUICK_PAYEMENT(vExpValue, vEffValue, vAxisValue, pDocPosDetID);
    else
      PUR_04_PRICE_STD_SUB(vExpValue, vEffValue, vAxisValue, pDocPosDetID);
    end if;

    pExpvalue   := vExpvalue;
    pEffvalue   := vEffvalue;
    pAxisValue  := vAxisValue;
  end PUR_04_PRICE;

/*--------------------------------------------------------------------------------------------------------------------*/

  /*-----------------------------------------------------------------------------------
PROCEDURES GENERALES
-----------------------------------------------------------------------------------*/
  procedure CalcAxisValue(
    pAxisID         in     SQM_AXIS.SQM_AXIS_ID%type
  , pExpectedValue  in out SQM_PENALTY.SPE_EXPECTED_VALUE%type
  , pEffectiveValue out    SQM_PENALTY.SPE_EFFECTIVE_VALUE%type
  , pAxisValue      out    SQM_PENALTY.SPE_INIT_VALUE%type
  , pDocPosDetID    in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  )
  is
    vSQL SQM_INITIALIZATION_METHOD.SIM_FUNCTION%type;
  begin
    -- R�cup�ration de la m�thode d'initialisation
    begin
      select SIM_FUNCTION
        into vSQL
        from SQM_AXIS SAX
           , SQM_INITIALIZATION_METHOD SIM
       where SQM_AXIS_ID = pAxisID
         and SAX.SQM_INITIALIZATION_METHOD_ID = SIM.SQM_INITIALIZATION_METHOD_ID;

      -- Ex�cution de la m�thode et calcul des valeurs
      execute immediate 'begin ' || vSQL || '(:ExpValue,:EffValue,:AxisValue,:DocPosDet); end;'
                  using in out pExpectedValue, out pEffectiveValue, out pAxisValue, in pDocPosDetID;
    exception
      when no_data_found then
        pExpectedValue   := null;
        pEffectiveValue  := null;
        pAxisValue       := null;
    end;
  end CalcAxisValue;

/*-----------------------------------------------------------------------------------*/
  procedure RecalcPenalties(pDocPosID in DOC_POSITION.DOC_POSITION_ID%type)
  is
    vExpValue  SQM_PENALTY.SPE_EXPECTED_VALUE%type;
    vEffValue  SQM_PENALTY.SPE_EFFECTIVE_VALUE%type;
    vAxisValue SQM_PENALTY.SPE_INIT_VALUE%type;
  begin
    --if PCS.PC_CONFIG.GETCONFIG('SQM_QUALITY_MGM') = '1' then
      -- Mise � jour des notes du d�tail de position lors de la mise � jour du prix
    for cr_axis in (select SPE_DATE_REFERENCE DATE_REF
                         , SQM_FUNCTIONS.GetFirstFitScale(SPE.SQM_AXIS_ID, SPE_DATE_REFERENCE, SPE.GCO_GOOD_ID) SQM_SCALE_ID
                         , SPE.SQM_AXIS_ID
                         , SPE.DOC_POSITION_DETAIL_ID
                         , SPE.GCO_GOOD_ID GOOD_ID
                         , SPE.SQM_PENALTY_ID
                         , SPE.SPE_EXPECTED_VALUE
                      from SQM_PENALTY SPE
                         , SQM_AXIS SAX
                     where DOC_POSITION_ID = pDocPosId
                       and SAX.SQM_AXIS_ID = SPE.SQM_AXIS_ID
                       and SAX.C_AXIS_STATUS = 'ACT'
                       and SPE.SPE_MANUAL_PENALTY = 0) loop
      vExpValue   := cr_axis.SPE_EXPECTED_VALUE;
      vEffValue   := null;
      vAxisValue  := null;
      SQM_INIT_METHOD.CalcAxisValue(cr_axis.SQM_AXIS_ID, vExpValue, vEffValue, vAxisValue, cr_axis.DOC_POSITION_DETAIL_ID);

      update SQM_PENALTY
         set SQM_SCALE_ID = cr_axis.SQM_SCALE_ID
           , SPE_DATE_REFERENCE = cr_axis.DATE_REF
           , SPE_CALC_PENALTY = SQM_FUNCTIONS.CalcPenalty(cr_axis.SQM_SCALE_ID, vAxisValue)
           , SPE_EFFECTIVE_VALUE = vEffValue
           , SPE_INIT_VALUE = vAxisValue
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where SQM_PENALTY_ID = cr_axis.SQM_PENALTY_ID;
    end loop;
  --end if;
  end RecalcPenalties;

/*--------------------------------------------------------------------------------------------------------------------*/
/* ANCIENNES VERSIONS DES PROCEDURES - UTILES POUR MAS_F
/*--------------------------------------------------------------------------------------------------------------------*/

  /*-----------------------------------------------------------------------------------*/
  procedure PriceGap(
    pExpValue    in out SQM_PENALTY.SPE_EXPECTED_VALUE%type
  , pEffValue    out    SQM_PENALTY.SPE_EFFECTIVE_VALUE%type
  , pAxisValue   out    SQM_PENALTY.SPE_INIT_VALUE%type
  , pDocPosDetID in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  )
  is
    vGap DOC_POSITION.POS_NET_UNIT_VALUE%type;
  begin
    vGap        := 0;

    -- En cr�ation
    if pDocPosDetID is null then
      select POS_EXP.POS_NET_UNIT_VALUE
           , POS_EFF.POS_NET_UNIT_VALUE
           , case
               when POS_EXP.POS_NET_UNIT_VALUE = 0 then null
               else (POS_EFF.POS_NET_UNIT_VALUE - POS_EXP.POS_NET_UNIT_VALUE) / POS_EXP.POS_NET_UNIT_VALUE * 100
             end
        into pExpValue
           , pEffValue
           , vGap
        from DOC_POSITION POS_EFF
           , DOC_POSITION POS_EXP
           , DOC_POSITION_DETAIL PDE_EXP
       where PDE_EXP.DOC_POSITION_DETAIL_ID = DetailInfo.DOC_DOC_POSITION_DETAIL_ID
         and PDE_EXP.DOC_POSITION_ID = POS_EXP.DOC_POSITION_ID
         and POS_EFF.DOC_POSITION_ID = DetailInfo.DOC_POSITION_ID;
    else   -- en modification (recalcule apr�s modification de la date document ou de la quantit� du d�tail)
      begin
        select POS_EXP.POS_NET_UNIT_VALUE
             , POS_EFF.POS_NET_UNIT_VALUE
             , case
                 when POS_EXP.POS_NET_UNIT_VALUE = 0 then null
                 else (POS_EFF.POS_NET_UNIT_VALUE - POS_EXP.POS_NET_UNIT_VALUE) / POS_EXP.POS_NET_UNIT_VALUE * 100
               end
          into pExpValue
             , pEffValue
             , vGap
          from DOC_POSITION POS_EFF
             , DOC_POSITION POS_EXP
             , DOC_POSITION_DETAIL PDE_EXP
             , DOC_POSITION_DETAIL PDE_EFF
         where PDE_EXP.DOC_POSITION_DETAIL_ID = PDE_EFF.DOC_DOC_POSITION_DETAIL_ID
           and PDE_EXP.DOC_POSITION_ID = POS_EXP.DOC_POSITION_ID
           and POS_EFF.DOC_POSITION_ID = PDE_EFF.DOC_POSITION_ID
           and PDE_EFF.DOC_POSITION_DETAIL_ID = pDocPosDetID;
      exception
        when ex.TABLE_MUTATING then   -- trigger de mise � jour du prix de la position (table DOC_POSITION is mutating)
          pEffValue  := PosNetUnitValue;

          if pExpValue = 0 then
            vGap  := null;
          else
            vGap  := (PosNetUnitValue - pExpValue) / pExpValue * 100;
          end if;
      end;
    end if;

    pAxisValue  := to_char(vGap);
  end PriceGap;

/*-----------------------------------------------------------------------------------*/
  procedure QuantityGap(
    pExpValue    in out SQM_PENALTY.SPE_EXPECTED_VALUE%type
  , pEffValue    out    SQM_PENALTY.SPE_EFFECTIVE_VALUE%type
  , pAxisValue   out    SQM_PENALTY.SPE_INIT_VALUE%type
  , pDocPosDetID in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  )
  is
    vGap DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY%type;
  begin
    vGap        := 0;

    -- En reg�n�ration, cr�ation et modification de la quantit� du d�tail
    if pDocPosDetId is null then
      begin   -- si proc�dure de reg�n�ration, calculer solde par rapport aux quantit�s d�j� d�charg�es
        select   PDE_FATHER.PDE_FINAL_QUANTITY - nvl(sum(PDE_BROTHER.PDE_FINAL_QUANTITY), 0) + DetailInfo.PDE_FINAL_QUANTITY
               , DetailInfo.PDE_FINAL_QUANTITY
               , case
                   when(PDE_FATHER.PDE_FINAL_QUANTITY - sum(PDE_BROTHER.PDE_FINAL_QUANTITY) + PDE_SON.PDE_FINAL_QUANTITY) = 0 then null
                   else (DetailInfo.PDE_FINAL_QUANTITY -(PDE_FATHER.PDE_FINAL_QUANTITY - sum(PDE_BROTHER.PDE_FINAL_QUANTITY) + PDE_SON.PDE_FINAL_QUANTITY) ) /
                        (PDE_FATHER.PDE_FINAL_QUANTITY - sum(PDE_BROTHER.PDE_FINAL_QUANTITY) + PDE_SON.PDE_FINAL_QUANTITY
                        ) *
                        100
                 end
            into pExpValue
               , pEffValue
               , vGap
            from DOC_POSITION_DETAIL PDE_SON
               , DOC_POSITION_DETAIL PDE_BROTHER
               , DOC_POSITION_DETAIL PDE_FATHER
           where PDE_SON.DOC_POSITION_DETAIL_ID = DetailInfo.DOC_POSITION_DETAIL_ID
             and PDE_BROTHER.DOC_DOC_POSITION_DETAIL_ID = PDE_FATHER.DOC_POSITION_DETAIL_ID
             and PDE_SON.DOC_DOC_POSITION_DETAIL_ID = PDE_FATHER.DOC_POSITION_DETAIL_ID
             and PDE_BROTHER.DOC_POSITION_DETAIL_ID <= PDE_SON.DOC_POSITION_DETAIL_ID
        group by PDE_FATHER.PDE_FINAL_QUANTITY
               , PDE_SON.PDE_FINAL_QUANTITY
               , PDE_FATHER.PDE_BALANCE_QUANTITY;
      exception
        when no_data_found then   -- en cr�ation, l'id du d�tail n'existe encore pas
          select nvl(pExpValue, PDE_EXP.PDE_BALANCE_QUANTITY)
               , DetailInfo.PDE_FINAL_QUANTITY
               , case
                   when nvl(pExpValue, PDE_EXP.PDE_BALANCE_QUANTITY) = 0 then null
                   else (DetailInfo.PDE_FINAL_QUANTITY - nvl(pExpValue, PDE_EXP.PDE_BALANCE_QUANTITY) ) / nvl(pExpValue, PDE_EXP.PDE_BALANCE_QUANTITY) * 100
                 end
            into pExpValue
               , pEffValue
               , vGap
            from DOC_POSITION_DETAIL PDE_EXP
           where PDE_EXP.DOC_POSITION_DETAIL_ID = DetailInfo.DOC_DOC_POSITION_DETAIL_ID;
      end;
    else   -- En Modification (date du document, prix de la position)
      begin
        select pExpValue
             , PDE_EFF.PDE_FINAL_QUANTITY
             , case
                 when pExpValue = 0 then null
                 else (PDE_EFF.PDE_FINAL_QUANTITY - pExpValue) / pExpValue * 100
               end
          into pExpValue
             , pEffValue
             , vGap
          from DOC_POSITION_DETAIL PDE_EXP
             , DOC_POSITION_DETAIL PDE_EFF
         where PDE_EXP.DOC_POSITION_DETAIL_ID = PDE_EFF.DOC_DOC_POSITION_DETAIL_ID
           and PDE_EFF.DOC_POSITION_DETAIL_ID = pDocPosDetID;
      exception
        when no_data_found then   -- calcul des notes en attente
          select PDE.PDE_FINAL_QUANTITY
            into pExpValue
            from DOC_POSITION_DETAIL PDE
           where PDE.DOC_POSITION_DETAIL_ID = pDocPosDetId;

          pEffValue  := DetailInfo.PDE_FINAL_QUANTITY;

          if pExpValue = 0 then
            vGap  := null;
          else
            vGap  := (pEffValue - pExpValue) / pExpValue * 100;
          end if;
      end;
    end if;

    pAxisValue  := to_char(vGap);
  end QuantityGap;

/*-----------------------------------------------------------------------------------*/
  procedure DelayGapByDay(
    pExpValue    in out SQM_PENALTY.SPE_EXPECTED_VALUE%type
  , pEffValue    out    SQM_PENALTY.SPE_EFFECTIVE_VALUE%type
  , pAxisValue   out    SQM_PENALTY.SPE_INIT_VALUE%type
  , pDocPosDetID in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  )
  is
    vDateDocument DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
  begin
    /* Cr�ation */
    if pDocPosDetID is null then
      -- Recherche date du document selon config
      select decode(upper(PCS.PC_CONFIG.GETCONFIG('SQM_REFERENCE_DATE') ), 'VAL', DOC.DMT_DATE_VALUE, DOC.DMT_DATE_DOCUMENT)
        into vDateDocument
        from DOC_POSITION POS
           , DOC_DOCUMENT DOC
       where POS.DOC_POSITION_ID = DetailInfo.DOC_POSITION_ID
         and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID;

      select to_char(nvl(PDE_EXP.PDE_SQM_ACCEPTED_DELAY, PDE_EXP.PDE_INTERMEDIATE_DELAY), 'dd.mm.yyyy')
           , to_char(vDateDocument, 'dd.mm.yyyy')
           , DOC_DELAY_FUNCTIONS.OpenDaysBetween(nvl(PDE_EXP.PDE_SQM_ACCEPTED_DELAY, PDE_EXP.PDE_INTERMEDIATE_DELAY)
                                               , vDateDocument
                                               , '1'
                                               , DetailInfo.PAC_THIRD_ID
                                                )
        into pExpValue
           , pEffValue
           , pAxisValue
        from DOC_POSITION_DETAIL PDE_EXP
       where PDE_EXP.DOC_POSITION_DETAIL_ID = DetailInfo.DOC_DOC_POSITION_DETAIL_ID;
    /* Modification */
    else
      begin
        select pExpValue
             , to_char(decode(upper(PCS.PC_CONFIG.GETCONFIG('SQM_REFERENCE_DATE') ), 'VAL', DOC.DMT_DATE_VALUE, DOC.DMT_DATE_DOCUMENT), 'dd.mm.yyyy')
             , DOC_DELAY_FUNCTIONS.OpenDaysBetween(nvl(PDE_EXP.PDE_SQM_ACCEPTED_DELAY, PDE_EXP.PDE_INTERMEDIATE_DELAY)
                                                 , decode(upper(PCS.PC_CONFIG.GETCONFIG('SQM_REFERENCE_DATE') )
                                                        , 'VAL', DOC.DMT_DATE_VALUE
                                                        , DOC.DMT_DATE_DOCUMENT
                                                         )
                                                 , '1'
                                                 , POS.PAC_THIRD_ID
                                                  )
          into pExpValue
             , pEffValue
             , pAxisValue
          from DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE_EFF
             , DOC_POSITION_DETAIL PDE_EXP
             , DOC_DOCUMENT DOC
         where POS.DOC_POSITION_ID = PDE_EFF.DOC_POSITION_ID
           and PDE_EXP.DOC_POSITION_DETAIL_ID = PDE_EFF.DOC_DOC_POSITION_DETAIL_ID
           and PDE_EFF.DOC_POSITION_DETAIL_ID = pDocPosDetID
           and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID;
      exception
        when ex.TABLE_MUTATING then   -- trigger de mise � jour de la date document DOC_DMT_AU_SQM_PENALTY
          select to_char(dtDateDoc, 'dd.mm.yyyy')
               , DOC_DELAY_FUNCTIONS.OpenDaysBetween(nvl(PDE_EXP.PDE_SQM_ACCEPTED_DELAY, PDE_EXP.PDE_INTERMEDIATE_DELAY), dtDateDoc, '1', PDE_EFF.PAC_THIRD_ID)
            into pEffValue
               , pAxisValue
            from DOC_POSITION_DETAIL PDE_EXP
               , DOC_POSITION_DETAIL PDE_EFF
           where PDE_EXP.DOC_POSITION_DETAIL_ID = PDE_EFF.DOC_DOC_POSITION_DETAIL_ID
             and PDE_EFF.DOC_POSITION_DETAIL_ID = pDocPosDetID;
        when no_data_found then   -- calcul des notes en attente
          select to_char(dtDateDoc, 'dd.mm.yyyy')
               , to_char(nvl(PDE_SQM_ACCEPTED_DELAY, PDE_INTERMEDIATE_DELAY), 'dd.mm.yyyy')
               , DOC_DELAY_FUNCTIONS.opendaysbetween(nvl(PDE_SQM_ACCEPTED_DELAY, PDE_INTERMEDIATE_DELAY), dtDateDoc, '1', pac_third_id)
            into pEffValue
               , pExpValue
               , pAxisValue
            from DOC_POSITION_DETAIL
           where doc_position_detail_Id = pdocposdetid;
      end;
    end if;
  end DelayGapByDay;

/*-----------------------------------------------------------------------------------*/
  procedure DelayGap(
    pExpValue    in out SQM_PENALTY.SPE_EXPECTED_VALUE%type
  , pEffValue    out    SQM_PENALTY.SPE_EFFECTIVE_VALUE%type
  , pAxisValue   out    SQM_PENALTY.SPE_INIT_VALUE%type
  , pDocPosDetID in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  )
  is
    vGap          number(15, 4);
    vExpectedGap  number(15, 4);
    vEffectiveGap number(15, 4);
    vDateDocument DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
  begin
    vGap        := 0;

    /* En cr�ation */
    if pDocPosDetID is null then
      -- Recherche date du document selon config
      select decode(upper(PCS.PC_CONFIG.GETCONFIG('SQM_REFERENCE_DATE') ), 'VAL', DOC.DMT_DATE_VALUE, DOC.DMT_DATE_DOCUMENT)
        into vDateDocument
        from DOC_POSITION POS
           , DOC_DOCUMENT DOC
       where POS.DOC_POSITION_ID = DetailInfo.DOC_POSITION_ID
         and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID;

      -- Ecart pr�vu
      select DOC_DELAY_FUNCTIONS.OpenDaysBetween(decode(upper(PCS.PC_CONFIG.GETCONFIG('SQM_REFERENCE_DATE') )
                                                      , 'VAL', DOC_EXP.DMT_DATE_VALUE
                                                      , DOC_EXP.DMT_DATE_DOCUMENT
                                                       )
                                               , nvl(PDE_EXP.PDE_SQM_ACCEPTED_DELAY, PDE_EXP.PDE_INTERMEDIATE_DELAY)
                                               , GAU.C_ADMIN_DOMAIN
                                               , DetailInfo.PAC_THIRD_ID
                                                )
        into vExpectedGap
        from DOC_DOCUMENT DOC_EXP
           , DOC_POSITION POS_EXP
           , DOC_POSITION_DETAIL PDE_EXP
           , DOC_GAUGE GAU
       where PDE_EXP.DOC_POSITION_DETAIL_ID = DetailInfo.DOC_DOC_POSITION_DETAIL_ID
         and PDE_EXP.DOC_POSITION_ID = POS_EXP.DOC_POSITION_ID
         and POS_EXP.DOC_DOCUMENT_ID = DOC_EXP.DOC_DOCUMENT_ID
         and DOC_EXP.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;

      if vExpectedGap = 0 then
        vExpectedGap  := 1;
      end if;

      -- Ecart effectif
      select DOC_DELAY_FUNCTIONS.OpenDaysBetween(nvl(PDE_EXP.PDE_SQM_ACCEPTED_DELAY, PDE_EXP.PDE_INTERMEDIATE_DELAY)
                                               , vDateDocument
                                               , GAU.C_ADMIN_DOMAIN
                                               , DetailInfo.PAC_THIRD_ID
                                                )
        into vEffectiveGap
        from DOC_POSITION_DETAIL PDE_EXP
           , DOC_GAUGE GAU
       where PDE_EXP.DOC_POSITION_DETAIL_ID = DetailInfo.DOC_DOC_POSITION_DETAIL_ID
         and PDE_EXP.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID;
    /* en modification */
    else
      -- Ecart pr�vu
      vExpectedGap  := pExpValue;

      if vExpectedGap is null then
        select DOC_DELAY_FUNCTIONS.OpenDaysBetween(decode(upper(PCS.PC_CONFIG.GETCONFIG('SQM_REFERENCE_DATE') )
                                                        , 'VAL', DOC_EXP.DMT_DATE_VALUE
                                                        , DOC_EXP.DMT_DATE_DOCUMENT
                                                         )
                                                 , nvl(PDE_EXP.PDE_SQM_ACCEPTED_DELAY, PDE_EXP.PDE_INTERMEDIATE_DELAY)
                                                 , GAU.C_ADMIN_DOMAIN
                                                 , DetailInfo.PAC_THIRD_ID
                                                  )
          into vExpectedGap
          from DOC_DOCUMENT DOC_EXP
             , DOC_POSITION POS_EXP
             , DOC_POSITION_DETAIL PDE_EXP
             , DOC_POSITION_DETAIL PDE_EFF
             , DOC_GAUGE GAU
         where PDE_EXP.DOC_POSITION_DETAIL_ID = PDE_EFF.DOC_DOC_POSITION_DETAIL_ID
           and PDE_EXP.DOC_POSITION_ID = POS_EXP.DOC_POSITION_ID
           and POS_EXP.DOC_DOCUMENT_ID = DOC_EXP.DOC_DOCUMENT_ID
           and PDE_EFF.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
           and PDE_EFF.DOC_POSITION_DETAIL_ID = pDocPosDetID;
      end if;

      -- Ecart effectif
      begin
        select DOC_DELAY_FUNCTIONS.OpenDaysBetween(nvl(PDE_EXP.PDE_SQM_ACCEPTED_DELAY, PDE_EXP.PDE_INTERMEDIATE_DELAY)
                                                 , decode(upper(PCS.PC_CONFIG.GETCONFIG('SQM_REFERENCE_DATE') )
                                                        , 'VAL', DOC_EFF.DMT_DATE_VALUE
                                                        , DOC_EFF.DMT_DATE_DOCUMENT
                                                         )
                                                 , GAU.C_ADMIN_DOMAIN
                                                 , PDE_EFF.PAC_THIRD_ID
                                                  )
          into vEffectiveGap
          from DOC_POSITION_DETAIL PDE_EFF
             , DOC_POSITION_DETAIL PDE_EXP
             , DOC_POSITION POS_EFF
             , DOC_DOCUMENT DOC_EFF
             , DOC_GAUGE GAU
         where PDE_EXP.DOC_POSITION_DETAIL_ID = PDE_EFF.DOC_DOC_POSITION_DETAIL_ID
           and POS_EFF.DOC_POSITION_ID = PDE_EFF.DOC_POSITION_ID
           and DOC_EFF.DOC_DOCUMENT_ID = POS_EFF.DOC_DOCUMENT_ID
           and DOC_EFF.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
           and PDE_EFF.DOC_POSITION_DETAIL_ID = pDocPosDetID;
      exception
        when ex.TABLE_MUTATING then   -- trigger de mise � jour de la date document DOC_DMT_AU_SQM_PENALTY
          select DOC_DELAY_FUNCTIONS.OpenDaysBetween(nvl(PDE_EXP.PDE_SQM_ACCEPTED_DELAY, PDE_EXP.PDE_INTERMEDIATE_DELAY)
                                                   , dtDateDoc
                                                   , GAU.C_ADMIN_DOMAIN
                                                   , PDE_EFF.PAC_THIRD_ID
                                                    )
            into vEffectiveGap
            from DOC_POSITION_DETAIL PDE_EFF
               , DOC_POSITION_DETAIL PDE_EXP
               , DOC_GAUGE GAU
           where PDE_EXP.DOC_POSITION_DETAIL_ID = PDE_EFF.DOC_DOC_POSITION_DETAIL_ID
             and PDE_EFF.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
             and PDE_EFF.DOC_POSITION_DETAIL_ID = pDocPosDetID;
      end;
    end if;

    -- �cart d�lai en %
    if vExpectedGap = 0 then
      vExpectedGap  := 1;
    end if;

    vGap        := vEffectiveGap / vExpectedGap * 100;
    pExpValue   := to_char(vExpectedGap);
    pEffValue   := to_char(vEffectiveGap);
    pAxisValue  := to_char(vGap);
  end DelayGap;

/*-----------------------------------------------------------------------------------*/
  procedure ReturnSequence(
    pExpValue    in out SQM_PENALTY.SPE_EXPECTED_VALUE%type
  , pEffValue    out    SQM_PENALTY.SPE_EFFECTIVE_VALUE%type
  , pAxisValue   out    SQM_PENALTY.SPE_INIT_VALUE%type
  , pDocPosDetID in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type default null
  )
  is
    vSequence number;
  begin
    if pdocposdetid is not null then
      select nvl(count(*), 0) + 1
        into vSequence
        from DOC_POSITION_DETAIL DET
           , DOC_POSITION POS
           , DOC_GAUGE GAU
       where DET.DOC2_DOC_POSITION_DETAIL_ID = pDocPosDetID
         and GAU.DOC_GAUGE_ID = POS.DOC_GAUGE_ID
         and GAU.DIC_GAUGE_TYPE_DOC_ID = 'A-RET'
         and DET.DOC_POSITION_ID = POS.DOC_POSITION_ID;
    else
      select nvl(count(*), 0) + 1
        into vSequence
        from DOC_POSITION_DETAIL DET
           , DOC_POSITION POS
           , DOC_GAUGE GAU
       where DET.DOC2_DOC_POSITION_DETAIL_ID = DetailInfo.DOC2_DOC_POSITION_DETAIL_ID
         and GAU.DOC_GAUGE_ID = POS.DOC_GAUGE_ID
         and GAU.DIC_GAUGE_TYPE_DOC_ID = 'A-RET'
         and DET.DOC_POSITION_ID = POS.DOC_POSITION_ID;
    end if;

    pAxisValue  := to_char(vSequence);
  end ReturnSequence;

/*--------------------------------------------------------------------------------------------------------------------*/
  procedure ConfirmationTime(pDocId doc_document.doc_document_id%type)
  is
    cursor crConfirmedDelay
    is
      select det.doc_position_detail_id
           , det.dic_delay_update_type_id
           , det.doc_position_id
           , det.pac_third_id
           , det.gco_good_id
           , nvl(det.a_datemod, det.a_datecre) date_ref
           , case
               when gau.c_admin_domain = '1' then (select sqm_axis_id
                                                     from sqm_axis
                                                    where sax_free_number1 = 1)
               when gau.c_admin_domain = '2' then (select sqm_axis_id
                                                     from sqm_axis
                                                    where sax_free_number1 = 2)
             end axis_id
           ,   -- identification de l'axe qualit�
             gau.c_admin_domain
        from doc_position_detail det
           , doc_gauge gau
       where doc_document_id = pDocId
         and det.doc_gauge_id = gau.doc_gauge_id
         and dic_delay_update_type_id = 'PUR-CONF';

    tplConfirmedDelay crConfirmedDelay%rowtype;
    vscale_id         number;
    vAxisvalue        number;
    vExpDate          date;
    vEffDate          date;
    vFlag             number(1);
  begin
    open crConfirmedDelay;

    fetch crConfirmedDelay
     into tplConfirmedDelay;

    while crConfirmedDelay%found loop
      -- Calcul du nombre de jour ouvr�s entre la date de cr�ation du d�lai'PUR-DEM' du plus r�cent d�tail de position
      -- et la date de cr�ation du d�lai 'PUR-CONF' le plus r�cent.

      -- Recherche dans l'historique des d�lais du d�lai 'PUR-DEM' le plus r�cent
      begin
        select a_datecre
          into vExpDate
          from (select   nvl(a_datemod, a_datecre) a_datecre
                    from doc_delay_history
                   where doc_position_detail_id = tplConfirmedDelay.doc_position_detail_id
                     and dic_delay_update_type_id = 'PUR-DEM'
                order by a_datecre desc)
         where rownum = 1;
      exception
        when no_data_found then
          vExpdate  := tplConfirmedDelay.date_ref;
      end;

      if vExpdate is null then
        vExpdate  := sysdate;
      end if;

      vEffdate  := nvl(tplConfirmedDelay.date_ref, sysdate);

      if tplConfirmedDelay.pac_third_id is not null then
        select doc_delay_functions.OpenDaysBetween(vExpdate
                                                 , vEffdate   -- calcul par rapport � la date du 'dernier 'PUR-CONF' = celui du curseur
                                                 , tplConfirmedDelay.c_admin_domain   -- domaine
                                                 , tplConfirmedDelay.pac_third_id
                                                  )
          into vAxisValue
          from dual;
      end if;

      -- pas d'exception car on a toujours au moins l'un des 2 d�lais renseign� et le d�tail de position existe tjs
      select nvl(SQM_FUNCTIONS.GetFirstFitScale(tplConfirmedDelay.axis_id, sysdate, tplConfirmedDelay.gco_good_id), 0)
        into vscale_id
        from dual;

      -- Insertion OU update dans la table SQM_PENALTY si l'on a trouv� la notation
      if vscale_id > 0 then
        vFlag  := 1;

        begin
          select 1
            into vFlag
            from SQM_PENALTY
           where doc_position_detail_id = tplConfirmedDelay.doc_position_detail_id
             and sqm_axis_id = tplConfirmedDelay.axis_id;
        exception
          when no_data_found then
            vFlag  := 0;
        end;

        if vFlag = 0 then
          insert into SQM_PENALTY
                      (SQM_PENALTY_ID
                     , SQM_SCALE_ID
                     , DOC_POSITION_DETAIL_ID
                     , DOC_POSITION_ID
                     , PAC_THIRD_ID
                     , GCO_GOOD_ID
                     , SQM_AXIS_ID
                     , C_PENALTY_STATUS
                     , SPE_DATE_REFERENCE
                     , SPE_CALC_PENALTY
                     , SPE_INIT_VALUE
                     , SPE_EXPECTED_VALUE
                     , SPE_EFFECTIVE_VALUE
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (init_id_seq.nextval
                     , vscale_id
                     , tplConfirmedDelay.doc_position_detail_id
                     , tplConfirmedDelay.doc_position_id
                     , tplConfirmedDelay.pac_third_id
                     , tplConfirmedDelay.gco_good_id
                     , tplConfirmedDelay.axis_id
                     , 'CONF'   -- c_penalty_status
                     , tplConfirmedDelay.date_ref
                     , SQM_FUNCTIONS.CalcPenalty(vscale_id, vAxisValue)
                     , vAxisValue
                     , to_char(vExpdate, 'DD.MM.YYYY')
                     , to_char(tplConfirmedDelay.date_ref, 'DD.MM.YYYY')
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        else
          update sqm_penalty
             set SPE_DATE_REFERENCE = tplConfirmedDelay.date_ref
               , SPE_CALC_PENALTY = SQM_FUNCTIONS.CalcPenalty(vscale_id, vAxisValue)
               , SPE_INIT_VALUE = vAxisValue
               , SPE_EFFECTIVE_VALUE = to_char(tplConfirmedDelay.date_ref, 'DD.MM.YYYY')
               , SPE_EXPECTED_VALUE = to_char(vExpDate, 'DD.MM.YYYY')
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where doc_position_detail_id = tplConfirmedDelay.doc_position_detail_id
             and sqm_axis_id = tplConfirmedDelay.axis_id;
        end if;
      end if;

      fetch crConfirmedDelay
       into tplConfirmedDelay;
    end loop;
  end ConfirmationTime;

/*--------------------------------------------------------------------------------------------------------------------*/
  procedure DelayGapAskedConfirmed(pDocId doc_document.doc_document_id%type)
  is
    cursor crConfirmedDelay
    is
      select det.doc_position_detail_id
           , det.dic_delay_update_type_id
           , det.doc_position_id
           , det.pac_third_id
           , det.gco_good_id
           , nvl(det.pde_sqm_accepted_delay, det.pde_intermediate_delay) date_ref
           , case
               when gau.c_admin_domain = '1' then (select sqm_axis_id
                                                     from sqm_axis
                                                    where sax_free_number1 = 3)
               when gau.c_admin_domain = '2' then (select sqm_axis_id
                                                     from sqm_axis
                                                    where sax_free_number1 = 4)
             end axis_id   -- identification de l'axe qualit�
           , gau.c_admin_domain
           , nvl(det.a_datemod, det.a_datecre) a_datecre
        from doc_position_detail det
           , doc_gauge gau
       where doc_document_id = pDocId
         and det.doc_gauge_id = gau.doc_gauge_id
         and dic_delay_update_type_id = 'PUR-CONF';

    tplConfirmedDelay crConfirmedDelay%rowtype;
    vscale_id         number;
    vAxisvalue        number;
    vExpDate          date;
    vEffDate          date;
    vFlag             number(1);
  begin
    open crConfirmedDelay;

    fetch crConfirmedDelay
     into tplConfirmedDelay;

    while crConfirmedDelay%found loop
      -- Calcul du nombre de jour ouvr�s entre la date de cr�ation du d�lai'DEM' du plus r�cent d�tail de position
      -- et la date de cr�ation du d�lai 'CONF' le plus r�cent.

      -- Recherche dans l'historique des d�lais du d�lai 'DEM' le plus r�cent
      begin
        select ref_delay
          into vExpDate
          from (select   nvl(dhi_accept_delay, dhi_intermediate_delay) ref_delay
                    from doc_delay_history
                   where doc_position_detail_id = tplConfirmedDelay.doc_position_detail_id
                     and dic_delay_update_type_id = 'PUR-DEM'
                order by a_datecre desc)
         where rownum = 1;
      exception
        when no_data_found then
          vExpdate  := tplConfirmedDelay.date_ref;
      end;

      if vExpdate is null then
        vExpdate  := sysdate;
      end if;

      vEffdate  := nvl(tplConfirmedDelay.date_ref, sysdate);

      if tplConfirmedDelay.pac_third_id is not null then
        select doc_delay_functions.OpenDaysBetween(vExpdate   -- d�lai demand�
                                                 , vEffdate   -- dernier d�lai 'PUR-CONF' = celui du curseur
                                                 , tplConfirmedDelay.c_admin_domain   -- domaine
                                                 , tplConfirmedDelay.pac_third_id
                                                  )
          into vAxisValue
          from dual;
      end if;

      -- pas d'exception car on a toujours au moins l'un des 2 d�lais renseign� et le d�tail de position existe tjs
      select nvl(SQM_FUNCTIONS.GetFirstFitScale(tplConfirmedDelay.axis_id, sysdate, tplConfirmedDelay.gco_good_id), 0)
        into vscale_id
        from dual;

      -- Insertion OU update dans la table SQM_PENALTY si l'on a trouv� la notation
      if vscale_id > 0 then
        vFlag  := 1;

        begin
          select 1
            into vFlag
            from SQM_PENALTY
           where doc_position_detail_id = tplConfirmedDelay.doc_position_detail_id
             and sqm_axis_id = tplConfirmedDelay.axis_id;
        exception
          when no_data_found then
            vFlag  := 0;
        end;

        if vFlag = 0 then
          insert into SQM_PENALTY
                      (SQM_PENALTY_ID
                     , SQM_SCALE_ID
                     , DOC_POSITION_DETAIL_ID
                     , DOC_POSITION_ID
                     , PAC_THIRD_ID
                     , GCO_GOOD_ID
                     , SQM_AXIS_ID
                     , C_PENALTY_STATUS
                     , SPE_DATE_REFERENCE
                     , SPE_CALC_PENALTY
                     , SPE_INIT_VALUE
                     , SPE_EXPECTED_VALUE
                     , SPE_EFFECTIVE_VALUE
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (init_id_seq.nextval
                     , vscale_id
                     , tplConfirmedDelay.doc_position_detail_id
                     , tplConfirmedDelay.doc_position_id
                     , tplConfirmedDelay.pac_third_id
                     , tplConfirmedDelay.gco_good_id
                     , tplConfirmedDelay.axis_id
                     , 'CONF'   -- c_penalty_status
                     , tplConfirmedDelay.a_datecre
                     , SQM_FUNCTIONS.CalcPenalty(vscale_id, vAxisValue)
                     , vAxisValue
                     , to_char(vExpdate, 'DD.MM.YYYY')
                     , to_char(vEffdate, 'DD.MM.YYYY')
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        else
          update sqm_penalty
             set SPE_DATE_REFERENCE = tplConfirmedDelay.date_ref
               , SPE_CALC_PENALTY = SQM_FUNCTIONS.CalcPenalty(vscale_id, vAxisValue)
               , SPE_INIT_VALUE = vAxisValue
               , SPE_EXPECTED_VALUE = to_char(vExpdate, 'DD.MM.YYYY')
               , SPE_EFFECTIVE_VALUE = to_char(vEffdate, 'DD.MM.YYYY')
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where doc_position_detail_id = tplConfirmedDelay.doc_position_detail_id
             and sqm_axis_id = tplConfirmedDelay.axis_id;
        end if;
      end if;

      fetch crConfirmedDelay
       into tplConfirmedDelay;
    end loop;
  end DelayGapAskedConfirmed;
end SQM_INIT_METHOD;
