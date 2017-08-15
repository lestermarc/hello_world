--------------------------------------------------------
--  DDL for Package Body ASA_COUNTER_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_COUNTER_FUNCTIONS" 
is
  /**
  * procedure CreateCounterMachine
  * Description
  *   Création des compteurs d'une machine
  * @created VJ 04.08.2005
  */
  procedure CreateCounterMachine(aRecordMachineID in DOC_RECORD.DOC_RECORD_ID%type, aGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    if     aRecordMachineID is not null
       and aGoodID is not null then
      -- Création des compteurs associés à la machine
      insert into ASA_COUNTER
                  (ASA_COUNTER_ID
                 , DOC_RECORD_ID
                 , ASA_COUNTER_TYPE_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        (select INIT_ID_SEQ.nextval   -- ASA_COUNTER_ID
              , aRecordMachineID   -- DOC_RECORD_ID
              , CTT.ASA_COUNTER_TYPE_ID   -- ASA_COUNTER_TYPE_ID
              , sysdate   -- A_DATECRE
              , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
           from ASA_COUNTER_TYPE_S_GOOD CTG
              , ASA_COUNTER_TYPE CTT
          where CTG.GCO_GOOD_ID = aGoodID
            and CTT.ASA_COUNTER_TYPE_ID = CTG.ASA_COUNTER_TYPE_ID);
    end if;
  end CreateCounterMachine;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *    Contrôle de cohérence des états compteurs
  */
  procedure CtrlIncreasingStatements(
    aCounterStatementID in     ASA_COUNTER_STATEMENT.ASA_COUNTER_STATEMENT_ID%type
  , aStatus             out    ASA_COUNTER_STATEMENT.C_COUNTER_STATEMENT_STATUS%type
  , aMessage            out    varchar2
  )
  is
    vErrorNb number;
  begin
    select count(*)
      into vErrorNb
      from (select   OTH.CST_STATEMENT_QUANTITY
                   , OTH.CST_STATEMENT_DATE
                from ASA_COUNTER_STATEMENT OTH
                   , ASA_COUNTER_STATEMENT SGL
               where OTH.ASA_COUNTER_ID = SGL.ASA_COUNTER_ID
                 and OTH.CST_STATEMENT_DATE > SGL.CST_STATEMENT_DATE
                 and OTH.CST_STATEMENT_QUANTITY < SGL.CST_STATEMENT_QUANTITY
                 and OTH.ASA_COUNTER_STATEMENT_ID <> SGL.ASA_COUNTER_STATEMENT_ID
                 and SGL.ASA_COUNTER_STATEMENT_ID = aCounterStatementID
            -- Etat compteur postérieur avec une quantité inférieure
            union
            select   OTH.CST_STATEMENT_QUANTITY
                   , OTH.CST_STATEMENT_DATE
                from ASA_COUNTER_STATEMENT OTH
                   , ASA_COUNTER_STATEMENT SGL
               where OTH.ASA_COUNTER_ID = SGL.ASA_COUNTER_ID
                 and OTH.CST_STATEMENT_DATE < SGL.CST_STATEMENT_DATE
                 and OTH.CST_STATEMENT_QUANTITY > SGL.CST_STATEMENT_QUANTITY
                 and OTH.ASA_COUNTER_STATEMENT_ID <> SGL.ASA_COUNTER_STATEMENT_ID
                 and SGL.ASA_COUNTER_STATEMENT_ID = aCounterStatementID
            -- Etat compteur antérieur avec une quantité supérieure
            order by CST_STATEMENT_DATE desc);

    -- Etat compteur validé
    aStatus  := '1';

    -- S'il existe au moins un état compteur postérieur avec qté inférieure ou inversement  alors Erreur
    if vErrorNb > 0 then
      aStatus   := '2';   -- annulé
      aMessage  :=
        pcs.pc_functions.TranslateWord
                               ('Il existe au moins un état compteur postérieur (resp. antérieur) à celui-ci avec une quantité inférieure (resp. supérieure) !');
    else
      select count(*)
        into vErrorNb
        from ASA_COUNTER_STATEMENT OTH
           , ASA_COUNTER_STATEMENT SGL
       where OTH.ASA_COUNTER_ID = SGL.ASA_COUNTER_ID
         and OTH.CST_STATEMENT_DATE = SGL.CST_STATEMENT_DATE
         and OTH.ASA_COUNTER_STATEMENT_ID <> SGL.ASA_COUNTER_STATEMENT_ID
         and SGL.ASA_COUNTER_STATEMENT_ID = aCounterStatementID;

      if vErrorNb > 0 then
        aStatus   := '0';   -- à valider
        aMessage  := pcs.pc_functions.TranslateWord('Plusieurs états compteurs ont la même date !');
      end if;
    end if;
  end CtrlIncreasingStatements;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Moyenne de consommation d'un compteur selon le client et le nombre de mois de calcul
  */
  function CalcCounterAvg(
    aCounterID        in ASA_COUNTER.ASA_COUNTER_ID%type
  , aPartnerID        in PAC_CUSTOM_PARTNER.PAC_CUSTOM_PARTNER_ID%type
  , aInitCounterState in CML_POSITION_MACHINE_DETAIL.CMD_INITIAL_STATEMENT%type
  , aInitDate         in CML_POSITION.CPO_BEGIN_CONTRACT_DATE%type
  , aMonthNb          in number
  )
    return ASA_COUNTER_STATEMENT.CST_STATEMENT_QUANTITY%type
  is
    cursor cr_StatementAvg
    is
      select   (CST_STATEMENT_QUANTITY - lag(CST_STATEMENT_QUANTITY, 1, aInitCounterState) over(order by CST_STATEMENT_DATE asc) ) /
               case
                 when months_between(CST_STATEMENT_DATE, lag(CST_STATEMENT_DATE, 1, aInitDate) over(order by CST_STATEMENT_DATE asc) ) = 0 then 1
                 else months_between(CST_STATEMENT_DATE, lag(CST_STATEMENT_DATE, 1, aInitDate) over(order by CST_STATEMENT_DATE asc) )
               end AVERAGE
             , CST_STATEMENT_DATE
          from ASA_COUNTER_STATEMENT
         where ASA_COUNTER_ID = aCounterID
           and PAC_CUSTOM_PARTNER_ID = aPartnerID
      order by CST_STATEMENT_DATE desc;

    tplStatementAvg cr_StatementAvg%rowtype;
    vNbAvg          number;
    vQtyAvg         ASA_COUNTER_STATEMENT.CST_STATEMENT_QUANTITY%type;
  begin
    vNbAvg   := 0;
    vQtyAvg  := 0;

    if aMonthNb > 0 then
      -- moyenne entre chaque relevé de compteur
      open cr_StatementAvg;

      loop
        fetch cr_StatementAvg
         into tplStatementAvg;

        exit when cr_StatementAvg%notfound
              or (tplStatementAvg.CST_STATEMENT_DATE <= add_months(sysdate, -aMonthNb) );
        vNbAvg   := vNbAvg + 1;
        vQtyAvg  := vQtyAvg + tplStatementAvg.AVERAGE;
      end loop;
    end if;

    if vNbAvg = 0 then
      return 0;
    else
      return round(vQtyAvg / vNbAvg, 0);
    end if;
  end CalcCounterAvg;

/*--------------------------------------------------------------------------------------------------------------------*/
  /**
  * Description
  *   Initialisation du compteur selon l'installation et le type de compteur
  */
  function GetCounter(aCounterTypeID in ASA_COUNTER_TYPE.ASA_COUNTER_TYPE_ID%type, aInstallID in DOC_RECORD.DOC_RECORD_ID%type)
    return ASA_COUNTER.ASA_COUNTER_ID%type
  is
    vCounterID ASA_COUNTER.ASA_COUNTER_ID%type;
  begin
    select ASA_COUNTER_ID
      into vCounterID
      from ASA_COUNTER
     where ASA_COUNTER_TYPE_ID = aCounterTypeID
       and DOC_RECORD_ID = aInstallID;

    return vCounterID;
  exception
    when no_data_found then
      return 0;
  end GetCounter;
end ASA_COUNTER_FUNCTIONS;
