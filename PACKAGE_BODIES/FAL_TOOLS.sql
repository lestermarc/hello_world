--------------------------------------------------------
--  DDL for Package Body FAL_TOOLS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_TOOLS" 
is
  -- Configurations
  cfgFAL_PGM_REF_LENGTH      integer         := PCS.PC_CONFIG.GetConfig('FAL_PGM_REF_LENGTH');
  cfgFAL_ORD_REF_LENGTH      integer         := PCS.PC_CONFIG.GetConfig('FAL_ORD_REF_LENGTH');
  cfgFAL_LOT_REF_LENGTH      integer         := PCS.PC_CONFIG.GetConfig('FAL_LOT_REF_LENGTH');
  cfgFAL_PROGRAM_PREFIX      varchar2(30)    := PCS.PC_CONFIG.GetConfig('FAL_PROGRAM_PREFIX');
  cfgFAL_SEPAR_PROGRAM_ORDER varchar2(30)    := PCS.PC_CONFIG.GetConfig('FAL_SEPAR_PROGRAM_ORDER');
  cfgFAL_SEPAR_ORDER_LOT     varchar2(30)    := PCS.PC_CONFIG.GetConfig('FAL_SEPAR_ORDER_LOT');
  cfgFAL_PROGRAM_AS_PREFIX   varchar2(30)    := PCS.PC_CONFIG.GetConfig('FAL_PROGRAM_ASSEMBLE_PREFIX');
  --
  aMsg                       varchar2(32000);
  aCounter                   integer;

  /**
  * function GetGoodMeasureUnit
  * Description : Récupère l'unité de mesure d'un produit donné
  * @created ECA
  * @lastUpdate
  */
  function GetGoodMeasureUnit(iGcoGoodID in number)
    return varchar2
  is
    result varchar2(10);
  begin
    select DIC_UNIT_OF_MEASURE_ID
      into result
      from GCO_GOOD
     where GCO_GOOD_ID = iGcoGoodId;

    return result;
  exception
    when no_data_found then
      return '';
  end GetGoodMeasureUnit;

  /* Function IncCounter, getCounter et ResetCounter
  *  Description
  *     Set de fonctions permettant d'incrémenter un compteur aCounter
  *     au sein d'un SQL statement (Par ex: pour connaitre le nombre de
  *     lignes insérées, sans avoir a exécuter une seconde requête ).
  * @author ECA
  * @lastUpdate
  * @public
  */
  function IncCounter
    return integer
  is
  begin
    aCounter  := nvl(aCounter, 0) + 1;
    return 0;
  end;

  function GetCounter
    return integer
  is
  begin
    return aCounter;
  end;

  procedure ResetCounter
  is
  begin
    aCounter  := 0;
  end;

  /* Function ConcatMsg, getMsg et ResetMsg
  *  Description
  *     Set de fonctions permettant d'acumuler des informations dans une variable varchar
  *     au sein d'un SQL statement MERGE (Par ex: Connaitre les refcompl de lots non mis à jours...etc ).
  * @author ECA
  * @lastUpdate
  * @public
  */
  function ConcatMsg(aValue varchar2)
    return integer
  is
  begin
    aMsg  := aMsg || chr(13) || chr(10) || aValue;
    return 0;
  end;

  function GetMsg
    return varchar2
  is
  begin
    return aMsg;
  end;

  procedure ResetMsg
  is
  begin
    aMsg  := '';
  end;

  -- Renvoie Vrai si le produit est caractérisé
  function GoodHasCaracterization(PrmGCO_GOOD_ID PCS_PK_ID)
    return integer
  is
    BuffTotal number;
  begin
    select count(GCO_characterization_id) as TOTAL
      into BuffTOTAL
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = PrmGCO_GOOD_ID;

    if buffTOTAL > 0 then
      return 1;
    else
      return 0;
    end if;
  end;

-------------------------------------------------------------------
-- Renvoi le nombre de décimal gérés pour un GCo_GOOD_ID donné
-------------------------------------------------------------------
  function GetGoo_Number_Of_Decimal(PrmGCO_GOOD_ID PCS_PK_ID)
    return integer
  is
    BuffNumberDecimal integer;
  begin
    select GOO_NUMBER_OF_DECIMAL
      into BuffNumberDecimal
      from GCO_GOOD
     where GCO_GOOD_ID = PrmGCO_GOOD_ID;

    return BuffNumberDecimal;
  exception
    when no_data_found then
      return 0;
  end;

-------------------------------------------------------------------
-- retourne la GOO_MAJOR_REFERENCE pour un GCO_GOOD_ID Donné
-------------------------------------------------------------------
  function GetGOO_MAJOR_REFERENCE(InGco_Good_Id PCS_PK_ID)
    return varchar2
  is
    RefPrinc   GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    RefSecond  GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
    DescrShort GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
    DescrFree  GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type;
    DescrLong  GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
  begin
    if InGco_Good_Id is not null then
      GetMajorSecShortFreeLong(InGco_Good_Id, RefPrinc, RefSecond, DescrShort, DescrFree, DescrLong);
      return RefPrinc;
    else
      return null;
    end if;
  end;

  -- retourne la Description courte pour un GCO_GOOD_ID Donné
  function GetGOO_SHORT_DESCRIPTION(InGco_Good_Id PCS_PK_ID)
    return varchar2
  is
    RefPrinc   GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    RefSecond  GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
    DescrShort GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
    DescrFree  GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type;
    DescrLong  GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
  begin
    if InGco_Good_Id is not null then
      GetMajorSecShortFreeLong(InGco_Good_Id, RefPrinc, RefSecond, DescrShort, DescrFree, DescrLong);
      return DescrShort;
    else
      return null;
    end if;
  end;

-------------------------------------------------------------------
-- retourne la GOO_SECONDARY_REFERENCE pour un GCO_GOOD_ID Donné
-------------------------------------------------------------------
  function GetGOO_SECONDARY_REFERENCE(InGco_Good_Id PCS_PK_ID)
    return varchar2
  is
    RefPrinc   GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    RefSecond  GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
    DescrShort GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
    DescrFree  GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type;
    DescrLong  GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
  begin
    if InGco_Good_Id is not null then
      GetMajorSecShortFreeLong(InGco_Good_Id, RefPrinc, RefSecond, DescrShort, DescrFree, DescrLong);
      return RefSecond;
    else
      return null;
    end if;
  end;

--------------------------------------------------------------------------------------------------------------
-- retourne le STO_DESCRIPTION pour un STM_STOCk_iD Donné
-----------------------------------------------------------------------------------------------------------------
  function GetSTO_DESCRIPTION(PrmSTM_STOCK_ID STM_STOCK.STM_STOCK_ID%type)
    return varchar2
  is
    aSTO_DESCRIPTION STm_STOCK.STo_DESCRIPTION%type;
  begin
    if PrmSTM_STOCK_ID is not null then
      select STO_DESCRIPTION
        into aSTO_DESCRIPTION
        from STM_STOCK
       where STM_STOCk_ID = PrmSTM_STOCK_ID;

      return aSTO_DESCRIPTION;
    else
      return null;
    end if;
  end;

-------------------------------------------------------------------
-- Détermination si le composant a des caractérisations
-------------------------------------------------------------------
  function IsCmpWithChz(PrmGCO_GOOD_ID PCS_PK_ID)
    return boolean
  is
    BuffTotal number;
  begin
    select count(GCO_characterization_id) as TOTAL
      into BuffTOTAL
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = PrmGCO_GOOD_ID;

    return buffTOTAL = 0;
  exception
    when no_data_found then
      BuffTOTAL  := 0;
      return buffTOTAL = 0;
  end;

/****
* function IsFullTracability
*
* Description : Détermine si le produit est considéré en tracabilité complète ou pas
* Conditions  : il doit posséder au moins une charact. de type lot
*               Sa politique d'appro. ne doit pas être délais fixe.
*               Doit être coché tracabilité complète
*/
  function IsFullTracability(PrmGCO_GOOD_ID PCS_PK_ID)
    return boolean
  is
    Resultat number;
  begin
    Resultat  := 0;

    select PDT_FULL_TRACABILITY
      into Resultat
      from GCO_PRODUCT A
     where GCO_GOOD_ID = PrmGCO_GOOD_ID
       and PDT_FULL_TRACABILITY = 1
       and exists(select 1
                    from gco_characterization
                   where c_charact_type = 4
                     and gco_good_id = a.gco_good_id)
       and (not(   exists(select 1
                            from GCO_COMPL_DATA_MANUFACTURE comp
                           where comp.GCO_GOOD_ID = a.gco_good_id
                             and C_TIME_SUPPLY_RULE = '2')
                or exists(select 1
                            from GCO_COMPL_DATA_PURCHASE comp
                           where comp.GCO_GOOD_ID = a.gco_good_id
                             and C_TIME_SUPPLY_RULE = '2')
                or exists(select 1
                            from GCO_COMPL_DATA_SUBCONTRACT comp
                           where comp.GCO_GOOD_ID = a.gco_good_id
                             and C_TIME_SUPPLY_RULE = '2')
               )
           );

    if Resultat = 1 then
      return true;
    else
      return false;
    end if;
  exception
    when no_data_found then
      return false;
  end;

  function prcIsFullTracability(PrmGCO_GOOD_ID PCS_PK_ID)
    return integer
  is
  begin
    if IsFullTracability(PrmGCO_GOOD_ID) then
      return 1;
    else
      return 0;
    end if;
  end;

------------------------------------------------------------------------------
-- Détermination si le composant est geré selon "1 reception d'appro = 1 lot"
------------------------------------------------------------------------------
  function OneReceiptSupplyIsOneLot(PrmGCO_GOOD_ID PCS_PK_ID)
    return boolean
  is
    Buff number(1);
  begin
    select PDT_FULL_TRACABILITY_SUPPLY
      into Buff
      from GCO_PRODUCT
     where GCO_GOOD_ID = PrmGCO_GOOD_ID;

    return Buff = 1;
  end;

-------------------------------------------------------------------
-- Retourne la partie fractionnaire d'un nombre
-------------------------------------------------------------------
  function Frac(x number)
    return number
  is
  begin
    return x - floor(x);
  end;

  -- Cette fonction ne fait rien d'autre que de retourner la lot_refcompl du lot.
  -- pour un Lot_Id donné
  -- !! Elle a été recrée pour assurer la compatibilité avec les versions rapports !!
  function Format_lot(prmFAL_LOT_ID PCS_PK_ID)
    return varchar2
  is
    Buff varchar2(100);
  begin
    select lot_refcompl
      into buff
      from FAL_LOT
     where FAL_LOT_ID = PrmFAL_LOT_ID;

    return buff;
  exception
    when no_data_found then
      return null;
  end;

----------------------------------------------------------------------------------------------------
-- Formate l'affichage du lot en fonction des configs utilisateurs
-- pour un Lot_Id donné (que ce soit un lot de fabrication ou un lot d'assemblage)
------------------------------------------------------------------------------------------------------
  function Format_Lot_Generic(prmFAL_LOT_ID PCS_PK_ID)
    return varchar2
  is
    FAB_TYPE varchar2(10);
    varRef   TRef;
  begin
    select a.LOT_REF
         , b.ORD_REF
         , c.JOP_REFERENCE
      into varRef
      from FAL_LOT a
         , FAL_ORDER b
         , FAL_JOB_PROGRAM c
     where a.FAL_LOT_ID = prmFAL_LOT_ID
       and a.FAL_ORDER_ID = b.FAL_ORDER_ID
       and b.FAL_JOB_PROGRAM_ID = c.FAL_JOB_PROGRAM_ID;

    -- Récupération du C_FAB_TYPE du lot
    select C_FAB_TYPE
      into FAB_TYPE
      from FAL_LOT
     where FAL_LOT_ID = prmFAL_LOT_ID;

    -- Lot de fabrication
    if nvl(FAB_TYPE, 0) = 0 then
      return CfgFAL_PROGRAM_PREFIX ||
             lpad(varRef.ProgRef, CfgFAL_PGM_REF_LENGTH, '0') ||
             CfgFAL_SEPAR_PROGRAM_ORDER ||
             lpad(varRef.OrdRef, CfgFAL_ORD_REF_LENGTH, '0') ||
             CfgFAL_SEPAR_ORDER_LOT ||
             lpad(varRef.LotRef, CfgFAL_LOT_REF_LENGTH, '0');
    -- Lot d'assemblage
    elsif(FAB_TYPE = '1') then
      return CfgFAL_PROGRAM_AS_PREFIX ||
             lpad(varRef.ProgRef, CfgFAL_PGM_REF_LENGTH, '0') ||
             CfgFAL_SEPAR_PROGRAM_ORDER ||
             lpad(varRef.OrdRef, CfgFAL_ORD_REF_LENGTH, '0') ||
             CfgFAL_SEPAR_ORDER_LOT ||
             lpad(varRef.LotRef, CfgFAL_LOT_REF_LENGTH, '0');
    -- Sinon Pb
    else
      return '';
    end if;
  end;

----------------------------------------------------------------------------------------------------
-- Formate l'affichage du lot en fonction des configs utilisateurs
-- pour un Lot_Id donné (que ce soit un lot de fabrication ou un lot d'assemblage)
-- Idem mais pour les lots historiés
------------------------------------------------------------------------------------------------------
  function Format_Lot_Hist_Generic(prmFAL_LOT_HIST_ID PCS_PK_ID)
    return varchar2
  is
    FAB_TYPE varchar2(10);
    varRef   TRef;
  begin
    select a.LOT_REF
         , b.ORD_REF
         , c.JOP_REFERENCE
      into varRef
      from FAL_LOT_HIST a
         , FAL_ORDER_HIST b
         , FAL_JOB_PROGRAM_HIST c
     where a.FAL_LOT_HIST_ID = prmFAL_LOT_HIST_ID
       and a.FAL_ORDER_HIST_ID = b.FAL_ORDER_HIST_ID
       and b.FAL_JOB_PROGRAM_HIST_ID = c.FAL_JOB_PROGRAM_HIST_ID;

    -- Récupération du C_FAB_TYPE du lot
    select C_FAB_TYPE
      into FAB_TYPE
      from FAL_LOT_HIST
     where FAL_LOT_HIST_ID = prmFAL_LOT_HIST_ID;

    -- Lot de fabrication
    if nvl(FAB_TYPE, 0) = 0 then
      return CfgFAL_PROGRAM_PREFIX ||
             lpad(varRef.ProgRef, CfgFAL_PGM_REF_LENGTH, '0') ||
             CfgFAL_SEPAR_PROGRAM_ORDER ||
             lpad(varRef.OrdRef, CfgFAL_ORD_REF_LENGTH, '0') ||
             CfgFAL_SEPAR_ORDER_LOT ||
             lpad(varRef.LotRef, CfgFAL_LOT_REF_LENGTH, '0');
    -- Lot d'assemblage
    elsif(FAB_TYPE = '1') then
      return CfgFAL_PROGRAM_AS_PREFIX ||
             lpad(varRef.ProgRef, CfgFAL_PGM_REF_LENGTH, '0') ||
             CfgFAL_SEPAR_PROGRAM_ORDER ||
             lpad(varRef.OrdRef, CfgFAL_ORD_REF_LENGTH, '0') ||
             CfgFAL_SEPAR_ORDER_LOT ||
             lpad(varRef.LotRef, CfgFAL_LOT_REF_LENGTH, '0');
    -- Sinon Pb
    else
      return '';
    end if;
  end;

---------------------------------------------------------------------------
-- cette fonctionne retourne NULL si la valeur passée en paramètre est 0
---------------------------------------------------------------------------
  function NIFZ(PrmX number)
    return number
  is
  begin
    if PrmX = 0 then
      return null;
    else
      return PrmX;
    end if;
  end;

  -- Fonctionnement similare à la fonction NVL mais renvoi la valeur de "ReturnValueIfNullOrZero"
  -- si X est nul ou égal à Zéro
  function NvlA(X number, ReturnValueIfNullOrZero number)
    return number
  is
    Temp number;
  begin
    if nvl(x, 0) = 0 then
      Temp  := ReturnValueIfNullOrZero;
    else
      Temp  := X;
    end if;

    return Temp;
  end;

  -- @deprecated since ProConcept ERP 11.1. Will be removed in future version. Use least(...) instead.
  -- Renvoi le plus petit des 2 nombres
  function GetMinOf(x number, y number)
    return number
  is
  begin
    return least(x, y);
  end;

  -- @deprecated since ProConcept ERP 11.1. Will be removed in future version. Use greatest(...) instead.
  -- Renvoi le plus grand des 2 nombres
  function GetMaxOf(x number, y number)
    return number
  is
  begin
    return greatest(x, y);
  end;

  -- Cette fonction n'est autre que l'ancienne fonction Get_besoin_origine
  -- Mais ou j'ai rajouté un controle sur le niveau de récursivité
  function Compute_Get_besoin_origine(prmFAL_NETWORK_SUP_NEED_ID PCS_PK_ID, sep varchar2, BesoinOrigineResult number default 0, Compteur_Recursif number)
    return varchar2
  is
    cursor produit(prmGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type)
    is
      select GOO_MAJOR_REFERENCE
        from GCO_GOOD
       where GCO_GOOD_ID = prmGCO_GOOD_ID;

    cursor produit_id(prmFAL_NETWORK_SUPPLY_ID PCS_PK_ID)
    is
      select GCO_GOOD_ID
        from FAL_NETWORK_SUPPLY
       where FAL_NETWORK_SUPPLY_ID = prmFAL_NETWORK_SUPPLY_ID;

    cursor doc(prmDOC_POSITION_ID FAL_NETWORK_NEED.DOC_POSITION_ID%type)
    is
      select DMT_NUMBER
           , A.DOC_DOCUMENT_ID
        from DOC_DOCUMENT A
           , DOC_POSITION B
       where B.DOC_POSITION_ID = prmDOC_POSITION_ID
         and B.DOC_DOCUMENT_ID = A.DOC_DOCUMENT_ID;

    varProduit                   GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    varDMT_NUMBER                DOC_DOCUMENT.DMT_NUMBER%type;
    varDOC_DOCUMENT_ID           DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    varProduit_id                PCS_PK_ID;
    id                           PCS_PK_ID;
    aC_PREFIX_PROP               FAL_DOC_PROP.C_PREFIX_PROP%type;
    resultat                     varchar2(3900);

    type TV_attrib is table of FAL_NETWORK_LINK.fal_network_need_id%type;

    Tab_Attrib                   TV_Attrib;

    -- Besoin.FAL_LOT_ID
    type TV_b_FAL_LOT_ID is table of FAL_NETWORK_NEED.FAL_LOT_ID%type;

    Tab_B_FAL_LOT_ID             TV_B_FAL_LOT_ID;

    -- Besoin.FAL_LOT_PROP_ID
    type TV_b_FAL_LOT_PROP_ID is table of FAL_NETWORK_NEED.FAL_LOT_PROP_ID%type;

    Tab_B_FAL_LOT_PROP_ID        TV_B_FAL_LOT_PROP_ID;

    -- Besoin.FAL_DOC_PROP_ID
    type TV_b_FAL_DOC_PROP_ID is table of FAL_NETWORK_NEED.FAL_DOC_PROP_ID%type;

    Tab_B_FAL_DOC_PROP_ID        TV_B_FAL_DOC_PROP_ID;

    -- Besoin.DOC_POSITION_ID
    type TV_b_DOC_POSITION_ID is table of FAL_NETWORK_NEED.DOC_POSITION_ID%type;

    Tab_B_DOC_POSITION_ID        TV_B_DOC_POSITION_ID;

    -- Besoin.DOC_POSITION_DETAIL_ID
    type TV_b_DOC_POSITION_DETAIL_ID is table of FAL_NETWORK_NEED.DOC_POSITION_DETAIL_ID%type;

    Tab_B_DOC_POSITION_DETAIL_ID TV_B_DOC_POSITION_DETAIL_ID;

    type TV_Appro is table of FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type;

    Tab_Appro                    TV_Appro;
    aFDP_NUMBER                  FAL_DOC_PROP.FDP_NUMBER%type;
    R                            varchar2(3900);
  begin
    if Compteur_Recursif < 20 then   -- 20 est arbitraire mais une vingtaine de niveaux
                                     -- représentant des besoins de besoins de besoins est énorme.
      resultat  := '';

      --Recherche des attributions
      select fal_network_need_id
      bulk collect into tab_attrib
        from FAL_NETWORK_LINK
       where FAL_NETWORK_SUPPLY_ID = prmFAL_NETWORK_SUP_NEED_ID
          or FAL_NETWORK_NEED_ID = prmFAL_NETWORK_SUP_NEED_ID;

      for j in 1 .. tab_attrib.count loop
        select FAL_LOT_ID
             , FAL_LOT_PROP_ID
             , FAL_DOC_PROP_ID
             , DOC_POSITION_ID
             , DOC_POSITION_DETAIL_ID
        bulk collect into tab_b_FAL_LOT_ID
              , tab_b_FAL_LOT_PROP_ID
              , tab_b_FAL_DOC_PROP_ID
              , tab_b_DOC_POSITION_ID
              , tab_b_DOC_POSITION_DETAIL_ID
          from FAL_NETWORK_NEED
         where FAL_NETWORK_NEED_ID = tab_attrib(j);

        if tab_B_FAL_LOT_ID.count = 0 then
          open produit_id(prmFAL_NETWORK_SUP_NEED_ID);

          fetch produit_id
           into varProduit_id;

          close produit_id;

          open produit(varProduit_id);

          fetch produit
           into varProduit;

          close produit;
        end if;

        if tab_B_FAL_LOT_ID.count <> 0 then
          --on regarde si l'attribution pointe sur une autre attribution ou sur rien (dans ce cas c'est le besoin initial)
          id  := null;

          if tab_B_FAL_LOT_ID(1) is not null then
            id  := tab_B_FAL_LOT_ID(1);
          end if;

          if tab_B_FAL_LOT_PROP_ID(1) is not null then
            id  := tab_B_FAL_LOT_PROP_ID(1);
          end if;

          if tab_B_FAL_DOC_PROP_ID(1) is not null then
            id  := tab_B_FAL_DOC_PROP_ID(1);

            -- Regarder s'il ne s'agit pas d'une POT auquel car on retourne elle-même
            select C_PREFIX_PROP
              into aC_PREFIX_PROP
              from FAL_DOC_pROP
             where FAL_DOC_PROp_ID = id;

            if    (aC_PREFIX_PROP = 'POT')
               or (aC_PREFIX_PROP = 'DRA') then
              -- Retrouver le numéro de la proposition
              select FDP_NUMBER
                into aFDP_NUMBER
                from FAL_DOC_PROP
               where FAL_DOC_PROp_ID = id;

              R   := aC_PREFIX_PROP || aFDP_NUMBER;

              if nvl(instr(resultat, R, 1, 1), 0) = 0 then
                resultat  := resultat || R || sep;
              end if;

              id  := null;
              return resultat;
            end if;
          end if;

          if id is not null then
            select FAL_NETWORK_SUPPLY_ID
            bulk collect into tab_Appro
              from FAL_NETWORK_SUPPLY
             where FAL_LOT_ID = id
                or FAL_LOT_PROP_ID = id
                or FAL_DOC_PROP_ID = id;

            for k in 1 .. tab_appro.count loop
              R  := Compute_Get_besoin_origine(tab_appro(k), sep, BesoinOrigineResult, Compteur_Recursif + 1);

              if nvl(instr(resultat, R, 1, 1), 0) = 0 then
                resultat  := resultat || R;
              end if;
            end loop;
          else
            if BesoinOrigineResult = ResultIsDocPositionId then
              if nvl(instr(resultat, tab_B_DOC_POSITION_ID(1), 1, 1), 0) = 0 then
                resultat  := resultat || tab_B_DOC_POSITION_ID(1) || sep;
              end if;
            elsif BesoinOrigineResult = ResultIsDocPositionDetailId then
              if nvl(instr(resultat, tab_B_DOC_POSITION_DETAIL_ID(1), 1, 1), 0) = 0 then
                resultat  := resultat || tab_B_DOC_POSITION_DETAIL_ID(1) || sep;
              end if;
            else
              open doc(tab_B_DOC_POSITION_ID(1) );

              fetch doc
               into varDMT_NUMBER
                  , varDOC_DOCUMENT_ID;

              close doc;

              if BesoinOrigineResult = ResultIsDocDocumentId then
                if nvl(instr(resultat, varDOC_DOCUMENT_ID, 1, 1), 0) = 0 then
                  resultat  := resultat || varDOC_DOCUMENT_ID || sep;
                end if;
              else
                if nvl(instr(resultat, varDMT_NUMBER, 1, 1), 0) = 0 then
                  resultat  := resultat || varDMT_NUMBER || sep;
                end if;
              end if;
            end if;
          end if;
        end if;
      end loop;   -- Fin de la boucle "for j in 1..tab_attrib.count loop"

      return resultat;
    else
      -- Histoire de savoir quand même que nous avons dépassé la limite de niveaux d'appel
      raise_application_error(-20001, PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - Trop de besoin de besoin') );
    end if;   -- Fin du test sur le compteur de récursivité
  exception
    when others then
      return substr(1, instr(resultat, sep, -1, 1) - 1) || ' ...';
  end;

  -- Cette fonction n'est autre que l'ancienne fonction Get_besoin_origine_Produit
  -- Mais ou j'ai rajouté un controle sur le niveau de récursivité
  function ComputeGet_besoin_origine_Pdt(prmFAL_NETWORK_SUP_NEED_ID PCS_PK_ID, sep varchar2, Compteur_Recursif number)
    return varchar2
  is
    cursor attrib(prmFAL_NETWORK_SUP_NEED_ID PCS_PK_ID)
    is
      select FAL_NETWORK_NEED_ID
        from FAL_NETWORK_LINK
       where FAL_NETWORK_SUPPLY_ID = prmFAL_NETWORK_SUP_NEED_ID
          or FAL_NETWORK_NEED_ID = prmFAL_NETWORK_SUP_NEED_ID;

    cursor besoin(prmFAL_NETWORK_NEED_ID PCS_PK_ID)
    is
      select fal_lot_id
           , fal_lot_prop_id
           , fal_doc_prop_id
           , gco_good_id
        from FAL_NETWORK_NEED
       where FAL_NETWORK_NEED_ID = prmFAL_NETWORK_NEED_ID;

    cursor appro(prmID PCS_PK_ID)
    is
      select FAL_NETWORK_SUPPLY_ID
        from FAL_NETWORK_SUPPLY
       where FAL_LOT_ID = prmID
          or FAL_LOT_PROP_ID = prmID
          or FAL_DOC_PROP_ID = prmID;

    cursor produit(prmGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type)
    is
      select GOO_MAJOR_REFERENCE
        from GCO_GOOD
       where GCO_GOOD_ID = prmGCO_GOOD_ID;

    cursor produit_id(prmFAL_NETWORK_SUPPLY_ID PCS_PK_ID)
    is
      select GCO_GOOD_ID
        from FAL_NETWORK_SUPPLY
       where FAL_NETWORK_SUPPLY_ID = prmFAL_NETWORK_SUPPLY_ID;

    enrFAL_NETWORK_NEED   besoin%rowtype;
    enrFAL_NETWORK_SUPPLY Appro%rowtype;
    enrFAL_NETWORK_LINK   Attrib%rowtype;
    varProduit            GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    varProduit_id         PCS_PK_ID;
    id                    PCS_PK_ID;
    resultat              varchar2(3900);
    aC_PREFIX_PROP        FAL_DOC_PROP.C_PREFIX_PROP%type;
    aGOO_MAJOR_REFERENCE  GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    aFDP_NUMBER           FAL_DOC_PROP.FDP_NUMBER%type;
    R                     varchar2(3900);
  begin
    if Compteur_Recursif < 20 then   -- 20 est arbitraire mais une vingtaine de niveaux
                                     -- représentant des besoins de besoins de besoins est énorme.
      resultat  := '';

      --Recherche des attributions
      open attrib(prmFAL_NETWORK_SUP_NEED_ID);

      loop
        fetch attrib
         into enrFAL_NETWORK_LINK;

        if attrib%notfound then
          open produit_id(prmFAL_NETWORK_SUP_NEED_ID);

          fetch produit_id
           into varProduit_id;

          close produit_id;

          open produit(varProduit_id);

          fetch produit
           into varProduit;

          close produit;

          if nvl(instr(resultat, varProduit, 1, 1), 0) = 0 then
            resultat  := resultat || varProduit || sep;
          end if;

          exit;
        else
          open besoin(enrFAL_NETWORK_LINK.FAL_NETWORK_NEED_ID);

          fetch besoin
           into enrFAL_NETWORK_NEED;

          if besoin%notfound then
            open produit_id(prmFAL_NETWORK_SUP_NEED_ID);

            fetch produit_id
             into varProduit_id;

            close produit_id;

            open produit(varProduit_id);

            fetch produit
             into varProduit;

            close produit;

            if nvl(instr(resultat, varProduit, 1, 1), 0) = 0 then
              resultat  := resultat || varProduit || sep;
            end if;
          else
            --on regarde si l'attribution pointe sur une autre attribution ou sur rien (dans ce cas c'est le besoin initial)
            id  := null;

            if enrFAL_NETWORK_NEED.FAL_LOT_ID is not null then
              id  := enrFAL_NETWORK_NEED.FAL_LOT_ID;
            end if;

            if enrFAL_NETWORK_NEED.FAL_LOT_PROP_ID is not null then
              id  := enrFAL_NETWORK_NEED.FAL_LOT_PROP_ID;
            end if;

            if enrFAL_NETWORK_NEED.FAL_DOC_PROP_ID is not null then
              id  := enrFAL_NETWORK_NEED.FAL_DOC_PROP_ID;

              -- Regarder s'il ne s'agit pas d'une POT auquel car on retourne elle-même
              select C_PREFIX_PROP
                into aC_PREFIX_PROP
                from FAL_DOC_pROP
               where FAL_DOC_PROp_ID = id;

              if    (aC_PREFIX_PROP = 'POT')
                 or (aC_PREFIX_PROP = 'DRA') then
                -- Retrouver le numéro de la proposition
                select FDP_NUMBER
                  into aFDP_NUMBER
                  from FAL_DOC_PROP
                 where FAL_DOC_PROp_ID = id;

                select FAL_TOOLS.GetGOO_MAJOR_REFERENCE(GCO_GOOD_ID)
                  into aGOO_MAJOR_REFERENCE
                  from FAL_DOC_PROP
                 where FAL_DOC_PROp_ID = id;

                if nvl(instr(resultat, aGOO_MAJOR_REFERENCE, 1, 1), 0) = 0 then
                  resultat  := resultat || aGOO_MAJOR_REFERENCE || sep;
                end if;

                id  := null;

                close besoin;

                return resultat;
              end if;
            end if;

            if id is not null then
              open appro(id);

              loop
                fetch appro
                 into enrFAL_NETWORK_SUPPLY;

                exit when appro%notfound;
                R  := ComputeGet_besoin_origine_Pdt(enrFAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID, sep, Compteur_recursif);

                if nvl(instr(resultat, R, 1, 1), 0) = 0 then
                  resultat  := resultat || R;
                end if;
              end loop;

              close appro;
            else
              open produit(enrFAL_NETWORK_NEED.GCO_GOOD_ID);

              fetch produit
               into varProduit;

              close produit;

              if nvl(instr(resultat, varProduit, 1, 1), 0) = 0 then
                resultat  := resultat || varProduit || sep;
              end if;
            end if;
          end if;

          close besoin;
        end if;
      end loop;

      close attrib;

      return resultat;
    else
      -- Histoire de savoir quand même que nous avons dépassé la limite de niveaux d'appel
      raise_application_error(-20001, PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - Trop de besoin de besoin') );
    end if;   -- Fin du test sur le compteur de récursivité
  exception
    when others then
      return substr(resultat, 1, instr(resultat, sep, -1, 1) - 1) || ' ...';
  end;

  -- Cette fonction n'est autre que l'ancienne fonction Get_besoin_origine_Emp
  -- Mais ou j'ai rajouté un controle sur le niveau de récursivité
  function ComputeGet_besoin_origine_Emp(prmFAL_NETWORK_SUP_NEED_ID PCS_PK_ID, sep varchar2, Compteur_Recursif number)
    return varchar2
  is
    cursor attrib(prmFAL_NETWORK_SUP_NEED_ID PCS_PK_ID)
    is
      select FAL_NETWORK_NEED_ID
        from FAL_NETWORK_LINK
       where FAL_NETWORK_SUPPLY_ID = prmFAL_NETWORK_SUP_NEED_ID
          or FAL_NETWORK_NEED_ID = prmFAL_NETWORK_SUP_NEED_ID;

    cursor besoin(prmFAL_NETWORK_NEED_ID PCS_PK_ID)
    is
      select fal_lot_id
           , fal_lot_prop_id
           , fal_doc_prop_id
           , gco_good_id
        from FAL_NETWORK_NEED
       where FAL_NETWORK_NEED_ID = prmFAL_NETWORK_NEED_ID;

    cursor appro(prmID PCS_PK_ID)
    is
      select FAL_NETWORK_SUPPLY_ID
        from FAL_NETWORK_SUPPLY
       where FAL_LOT_ID = prmID
          or FAL_LOT_PROP_ID = prmID
          or FAL_DOC_PROP_ID = prmID;

    cursor produit(prmGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type)
    is
      select GOO_MAJOR_REFERENCE
        from GCO_GOOD
       where GCO_GOOD_ID = prmGCO_GOOD_ID;

    cursor produit_id(prmFAL_NETWORK_SUPPLY_ID PCS_PK_ID)
    is
      select GCO_GOOD_ID
        from FAL_NETWORK_SUPPLY
       where FAL_NETWORK_SUPPLY_ID = prmFAL_NETWORK_SUPPLY_ID;

    enrFAL_NETWORK_NEED   Besoin%rowtype;
    enrFAL_NETWORK_SUPPLY Appro%rowtype;
    enrFAL_NETWORK_LINK   Attrib%rowtype;
    varProduit            GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    varProduit_id         PCS_PK_ID;
    id                    PCS_PK_ID;
    resultat              varchar2(3900);
    aC_PREFIX_PROP        FAL_DOC_PROP.C_PREFIX_PROP%type;
    aGCO_GOOD_ID          GCO_GOOD.GCO_GOOD_ID%type;
    aSTM_STM_STOCk_ID     STM_STOCK.STM_STOCK_ID%type;
    aFDP_NUMBER           FAL_DOC_PROP.FDP_NUMBER%type;
    R                     varchar2(3900);
  begin
    if Compteur_Recursif < 20 then   -- 20 est arbitraire mais une vingtaine de niveaux
                                     -- représentant des besoins de besoins de besoins est énorme.
      resultat  := '';

      --Recherche des attributions
      open attrib(prmFAL_NETWORK_SUP_NEED_ID);

      loop
        fetch attrib
         into enrFAL_NETWORK_LINK;

        if attrib%notfound then
          exit;
        else
          open besoin(enrFAL_NETWORK_LINK.FAL_NETWORK_NEED_ID);

          fetch besoin
           into enrFAL_NETWORK_NEED;

          if besoin%notfound then
            null;
          else
            --on regarde si l'attribution pointe sur une autre attribution ou sur rien (dans ce cas c'est le besoin initial)
            id  := null;

            if enrFAL_NETWORK_NEED.FAL_LOT_ID is not null then
              id  := enrFAL_NETWORK_NEED.FAL_LOT_ID;
            end if;

            if enrFAL_NETWORK_NEED.FAL_LOT_PROP_ID is not null then
              id  := enrFAL_NETWORK_NEED.FAL_LOT_PROP_ID;
            end if;

            if enrFAL_NETWORK_NEED.FAL_DOC_PROP_ID is not null then
              id  := enrFAL_NETWORK_NEED.FAL_DOC_PROP_ID;

              -- Regarder s'il ne s'agit pas d'une POT auquel car on retourne elle-même
              select C_PREFIX_PROP
                into aC_PREFIX_PROP
                from FAL_DOC_pROP
               where FAL_DOC_PROp_ID = id;

              if    (aC_PREFIX_PROP = 'POT')
                 or (aC_PREFIX_PROP = 'DRA') then
                -- Retrouver le numéro de la proposition
                select STM_STM_STOCk_ID
                  into aSTM_STM_STOCK_ID
                  from FAL_DOC_PROP
                 where FAL_DOC_PROp_ID = id;

                R   := GetSTO_DESCRIPTION(aSTM_STM_STOCK_ID);

                if nvl(instr(resultat, R, 1, 1), 0) = 0 then
                  resultat  := resultat || R || sep;
                end if;

                id  := null;

                close besoin;

                return resultat;
              end if;
            end if;

            if id is not null then
              open appro(id);

              loop
                fetch appro
                 into enrFAL_NETWORK_SUPPLY;

                exit when appro%notfound;
                R  := ComputeGet_besoin_origine_Emp(enrFAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID, sep, Compteur_recursif);

                if nvl(instr(resultat, R, 1, 1), 0) = 0 then
                  resultat  := resultat || R || sep;
                end if;
              end loop;

              close appro;
            else
              null;
            end if;
          end if;

          close besoin;
        end if;
      end loop;

      close attrib;

      return resultat;
    else
      -- Histoire de savoir quand même que nous avons dépassé la limite de niveaux d'appel
      raise_application_error(-20001, PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - Trop de niveaux') );
    end if;   -- Fin du test sur le compteur de récursivité
  exception
    when others then
      return substr(resultat, 1, instr(resultat, sep, -1, 1) - 1) || ' ...';
  end;

-------------------------------------------------------------------
-- Retourne le  besoin d'origine pour un lot donné
-- Quand il y en a plusieurs les besoins sont séparés dans la chaine de retour par la parametre "sep" de la fonction
-- En fonction de BesoinOrigineResult, la fonction retourne :
--     ResultIsDocPositionId  (= 1) : le DOC_POSITION_ID du besoin origine
--     ResultIsDocPositionDetailId  (= 2) : le DOC_POSITION_DETAIL_ID du besoin origine
--     ResultIsDocDocumentId  (= 3) : le DOC_DOCUMENT_ID du besoin origine
-- Si le paramètre n'est pas renseigné ou égal à 0, on retourne le DMT_NUMBER.
-- Par défaut, l'option est à 0
-------------------------------------------------------------------
  function Get_besoin_origine(prmFAL_NETWORK_SUP_NEED_ID PCS_PK_ID, sep varchar2, BesoinOrigineResult number default 0)
    return varchar2
  is
  begin
    return Compute_Get_besoin_origine(prmFAL_NETWORK_SUP_NEED_ID, sep, BesoinOrigineResult, 0   -- Niveau de récursivité
                                                                                             );
  end;

-------------------------------------------------------------------
-- Retourne le besoin origine produit
-- Quand il y en a plusieurs les besoins sont séparés dans la chaine de retour par la parametre "sep" de la fonction
-------------------------------------------------------------------
  function Get_besoin_origine_produit(prmFAL_NETWORK_SUP_NEED_ID PCS_PK_ID, sep varchar2)
    return varchar2
  is
  begin
    return ComputeGet_besoin_origine_Pdt(prmFAL_NETWORK_SUP_NEED_ID, sep, 0   -- Niveau de récursivité
                                                                           );
  end;

-------------------------------------------------------------------
-- Retourne l'emplacement du besoin origine
-- Quand il y en a plusieurs les besoins sont séparés dans la chaine de retour par la parametre "sep" de la fonction
-------------------------------------------------------------------
  function Get_besoin_origine_emp(prmFAL_NETWORK_SUP_NEED_ID PCS_PK_ID, sep varchar2)
    return varchar2
  is
  begin
    return ComputeGet_besoin_origine_Emp(prmFAL_NETWORK_SUP_NEED_ID, sep, 0   -- Niveau de récursivité
                                                                           );
  end;

------------------------------------------------------------------------------------------------
-- Parcours ascendant pour remonter à l'origine (commande ou produit sinon) d'un lot/prop ou poa
------------------------------------------------------------------------------------------------
  function attribution_asc(prmID PCS_PK_ID, sep varchar2)
    return varchar2
  is
    cursor C(prmID PCS_PK_ID)
    is
      select FAL_NETWORK_SUPPLY_ID
        from FAL_NETWORK_SUPPLY
       where FAL_LOT_ID = prmID
          or FAL_LOT_PROP_ID = prmID
          or FAL_DOC_PROP_ID = prmID;

    var_FAL_NETWORK_SUPPLY_ID FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type;
    res                       varchar2(32767);
  begin
    open C(prmID);

    fetch C
     into var_FAL_NETWORK_SUPPLY_ID;

    close C;

    res  := Get_besoin_origine(var_FAL_NETWORK_SUPPLY_ID, sep);
--  EPI_TESTFIC.creation_fichier;
--  EPI_TESTFIC.ecrit(res);
    return(res);
  end;

-------------------------------------------------------------------
-- Renvoie le nieme besoin initial renvoyé par "attribution asc"
-------------------------------------------------------------------
  function decode_besoin_init(besoin varchar2, n integer, sep varchar2)
    return varchar2
  is
    tamp    varchar2(32767);
    i       integer;
    pos     integer;
    postemp integer;
    deb     integer;
  begin
    tamp  := besoin;
    pos   := 0;

    if n = 1 then
      deb  := 1;
      pos  := instr(tamp, sep) - 1;
    else
      for i in 1 .. n loop
        postemp  := instr(tamp, sep);
        pos      := pos + postemp + length(sep) - 1;

        if i =(n - 1) then
          deb  := pos;
        end if;

        tamp     := substr(tamp, postemp + length(sep) );
      end loop;

      pos  := pos - length(sep);
      deb  := deb + 1;
    end if;

    return(substr(besoin, deb, pos - deb + 1) );
  end;

------------------------------------------------------------------------------------------------
-- Parcours ascendant pour remonter à l'origine (produit) d'un lot/prop ou poa
------------------------------------------------------------------------------------------------
  function attribution_asc_produit(prmID PCS_PK_ID, sep varchar2)
    return varchar2
  is
    cursor C(prmID PCS_PK_ID)
    is
      select FAL_NETWORK_SUPPLY_ID
        from FAL_NETWORK_SUPPLY
       where FAL_LOT_ID = prmID
          or FAL_LOT_PROP_ID = prmID
          or FAL_DOC_PROP_ID = prmID;

    var_FAL_NETWORK_SUPPLY_ID FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type;
    res                       varchar2(32767);
  begin
    open C(prmID);

    fetch C
     into var_FAL_NETWORK_SUPPLY_ID;

    close C;

    res  := Get_besoin_origine_produit(var_FAL_NETWORK_SUPPLY_ID, sep);
    return(res);
  end;

  /**
  * procedure : GetLocationIdOfAtelier
  * Description : Donne la valeur de l'ID de l'emplacement "Atelier" par rapport aux configs
  *               PPS_DefltSTOCK_FLOOR et PPS_DefltLOCATION_FLOOR
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @return   ID de l'emplacement du stock atelier
  */
  function GetLocationIdOfAtelier
    return PCS_PK_ID
  is
    aSTM_LOCATION_ID number;
  begin
    select STM_LOCATION_ID
      into aSTM_LOCATION_ID
      from STM_LOCATION
     where LOC_DESCRIPTION = PCS.PC_CONFIG.GetConfig('PPS_DefltLOCATION_FLOOR')
       and STM_STOCK_ID = (select max(STM_STOCK_ID)
                             from STM_STOCK
                            where STO_DESCRIPTION = PCS.PC_CONFIG.GetConfig('PPS_DefltSTOCK_FLOOR') );

    return aSTM_LOCATION_ID;
  exception
    when others then
      raise;
      return null;
  end;

-------------------------------------------------------------------------------------------------------------------
-- Procedure de controle pour retrouver les Produits pour lesquels il existe une différence entre les la quantité
-- en stock atelier prévu par le Fal_FActory_in et la quantité dispo de l'emplacement du stock atelier
-------------------------------------------------------------------------------------------------------------------
  procedure FalInQtyAndStockQtyComp
  is
    SumIN_BALANCE             FAL_FACTORY_IN.IN_BALANCE%type;
    SumSPO_AVAILABLE_QUANTITY STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;

    type TGCO_GOOD is record(
      CurGCO_GOOD_ID         GCO_GOOD.GCo_GOOD_iD%type
    , CurGOO_MAJOR_REFERENCE GCO_GOOD.GOO_MAJOR_REFERENCE%type
    );

    EnrGCO_GOOD               TGCO_GOOD;

    cursor CurGOOD
    is
      select A.gco_good_id
           , A.GOO_MAJOR_REFERENCE
        from GCo_GOOD A
       where gco_good_id in(select gco_good_id
                              from FAL_FACTORY_IN);

    EnrFAl_FACTORY_IN         FAL_FACTORY_IN%rowtype;

    cursor CurFAl_FACTORY_IN
    is
      select *
        from FAL_FACTORY_IN
       where IN_BALANCE > 0
         and GCO_GOOD_ID = EnrGCO_GOOD.CurGCO_GOOD_ID
         and IN_BALANCE is not null;

    EnrSTM_STOCK_POSITION     STM_STOCK_POSITION%rowtype;

    cursor CurSTM_STOCK_POSITION
    is
      select *
        from stm_stock_position
       where STM_LOCATION_ID = GetLocationIdOfAtelier
         and GCO_GOOD_ID = EnrGCO_GOOD.CurGCO_GOOD_ID
         and SPO_AVAILABLE_QUANTITY is not null
         and SPO_AVAILABLE_QUANTITY > 0;

    cursor CurFAL_FACTORY_IN2
    is
      select a.*
        from fal_factory_in a
           , STM_STOCK_POSITION b
           , FAL_LOT c
       where a.STM_STOCK_POSITION_ID = b.STM_STOCK_POSITION_ID
         and b.STM_LOCATION_ID <> GetLocationIdOfAtelier
         and a.GCO_GOOD_ID = EnrGCO_GOOD.CurGCO_GOOD_ID
         and c.FAL_LOT_ID = a.FAL_LOT_ID
         and c.C_LOT_STATUS <> 3;

    Ecart                     number;
  begin
    if CurGOOD%isopen then
      close CurGOOD;
    end if;

    open CurGOOD;

    loop
      fetch CurGOOD
       into EnrGCO_GOOD;

      exit when CurGOOD%notfound;

      select sum(IN_BALANCE)
        into SumIN_BALANCE
        from fal_factory_in
       where IN_BALANCE > 0
         and GCO_GOOD_ID = EnrGCO_GOOD.CurGCO_GOOD_ID
         and IN_BALANCE is not null;

      select sum(SPO_AVAILABLE_QUANTITY)
        into SumSPO_AVAILABLE_QUANTITY
        from stm_stock_position
       where STM_LOCATION_ID = GetLocationIdOfAtelier
         and GCO_GOOD_ID = EnrGCO_GOOD.CurGCO_GOOD_ID
         and SPO_AVAILABLE_QUANTITY is not null
         and SPO_AVAILABLE_QUANTITY > 0;

      if SumIn_BALANCE <> SumSPO_AVAILABLE_QUANTITY then
        DBMS_OUTPUT.put_line('------------------------------------');
        DBMS_OUTPUT.put_line('Product: ' || EnrGCo_GOOD.CurGOO_MAJOR_REFERENCE || '  ID:' || EnrGCo_GOOD.CurGCO_GOOD_ID);
        DBMS_OUTPUT.put_line('------------------------------------');
        DBMS_OUTPUT.put_line('');
        DBMS_OUTPUT.put_line('SumIN_BALANCE             = ' || SumIN_BALANCE);
        DBMS_OUTPUT.put_line('SumSPO_AVAILABLE_QUANTITY = ' || SumSPO_AVAILABLE_QUANTITY);
        Ecart  := nvl(SumIN_BALANCE, 0) - nvl(SumSPO_AVAILABLE_QUANTITY, 0);
        DBMS_OUTPUT.put_line('Ecart                     = ' || Ecart);

        if CurFAL_FACTORY_IN%isopen then
          close CurFAL_FACTORY_IN;
        end if;

        DBMS_OUTPUT.put_line('');
        DBMS_OUTPUT.put_line(' => Table: FAL_FACTORY_IN');

        open CurFAL_FACTORY_IN;

        loop
          fetch CurFAL_FACTORY_IN
           into EnrFAL_FACTORY_IN;

          exit when CurFAL_FACTORY_IN%notfound;
          DBMS_OUTPUT.put_line('  => ' ||
                               EnrFAl_FACTORY_IN.IN_LOT_REFCOMPL ||
                               ' <|> ID Lot:' ||
                               EnrFAl_FACTORY_IN.FAL_LOT_ID ||
                               ' <|> IN_BALANCE=' ||
                               EnrFAl_FACTORY_IN.IN_BALANCE ||
                               ' <|> ID Position:' ||
                               EnrFAl_FACTORY_IN.STM_STOCK_POSITION_ID
                              );
        end loop;

        close CurFAL_FACTORY_IN;

        if CurSTM_STOCK_POSITION%isopen then
          close CurSTM_STOCK_POSITION;
        end if;

        DBMS_OUTPUT.put_line('');
        DBMS_OUTPUT.put_line(' => Table: STM_STOCK_POSITION');

        open CurSTM_STOCK_POSITION;

        loop
          fetch CurSTM_STOCK_POSITION
           into EnrSTM_STOCK_POSITION;

          exit when CurSTM_STOCK_POSITION%notfound;
          DBMS_OUTPUT.put_line('  => ' || EnrSTM_STOCK_POSITION.STM_STOCK_POSITION_ID || ' <|> ' || EnrSTM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY);
        end loop;

        close CurSTM_STOCK_POSITION;

        DBMS_OUTPUT.put_line('');
        DBMS_OUTPUT.put_line('Entrée Atelier avec une position de stock pointant sur un emplacement différent de l''emplacement atelier');
        DBMS_OUTPUT.put_line('(Attention si la position de l''entrée atelier n''existe plus l''enregistrement ne sera pas montrée)');
        DBMS_OUTPUT.put_line('Exemple: Mag1 = 10 Pièces, un 1er lot crée une erreur, l''entrée atelier conserve l''id de la pos de stock de Mag1');
        DBMS_OUTPUT.put_line
             ('  Un 2eme lot se passe bien, la position de stock de mag1 n''existe plus et donc l''entrée atelier du 1er lot ne ressortira pas de cette requete');
        DBMS_OUTPUT.put_line('');

        open CurFAL_FACTORY_IN2;

        loop
          fetch CurFAL_FACTORY_IN2
           into EnrFAL_FACTORY_IN;

          exit when CurFAL_FACTORY_IN2%notfound;
          DBMS_OUTPUT.put_line('  => FAL_FACTORY_IN_ID:' ||
                               EnrFAL_FACTORY_IN.FAL_FACTORY_IN_ID ||
                               ' Lot:' ||
                               EnrFAL_FACTORY_IN.FAL_LOT_ID ||
                               '   IN_LOT_REFCOMPL:' ||
                               enrFAL_FACTORY_IN.IN_LOT_REFCOMPL ||
                               '  IN_IN_QTE:' ||
                               enrFAL_FACTORY_IN.IN_IN_QTE
                              );
        end loop;

        close CurFAL_FACTORY_IN2;

        DBMS_OUTPUT.put_line('------------------------------------');
      end if;
    end loop;

    close CurGOOD;
  end;

-------------------------------------------------------------------------------------------------------------------
-- Procedure de controle pour savoir si tout les fal_factory_in crées possèdent bien un mouvement de stock associés
-------------------------------------------------------------------------------------------------------------------
  procedure FalInAndStockIsOk(PrmListIdFalFactoryIn varchar2, PrmIsOk in out integer)
  is
    buff              varchar2(32767);
    Ignore            integer;
    LocSource_Cursor  integer;
    IDLocationAtelier PCS_PK_ID;
  begin
    -- recherche du stock Atelier sur la config PPS_DefltLOCATION_FLOOR
    IDLocationAtelier  := GetLocationIdOfAtelier;
    -- Nouvelle méthode
    buff               := '  select FAL_FACTORY_IN_ID';
    buff               := buff || '  from fal_factory_in a';
    buff               := buff || '   where';
    buff               := buff || PrmListIdFalFactoryIn;
    buff               := buff || '   and not exists (';
    buff               := buff || '                   select 1 from stm_stock_movement b';
    buff               := buff || '  				 where';
    buff               := buff || '  				 b.gco_good_id = a.gco_good_id';
    buff               := buff || '  				 and b.STM_LOCATION_ID = ' || IdLocationAtelier;
    buff               := buff || '  				 and b.smo_wording = a.in_lot_refcompl';
    buff               := buff || '  				 and b.smo_movement_quantity = a.in_in_qte';
    buff               :=
      buff ||
      '  				 and (a.in_characterization_value_1 = b.smo_characterization_value_1 or (a.in_characterization_value_1 is null and b.smo_characterization_value_1 is null))';
    buff               :=
      buff ||
      '  				 and (a.in_characterization_value_2 = b.smo_characterization_value_2 or (a.in_characterization_value_2 is null and b.smo_characterization_value_2 is null))';
    buff               :=
      buff ||
      '  				 and (a.in_characterization_value_3 = b.smo_characterization_value_3 or (a.in_characterization_value_3 is null and b.smo_characterization_value_3 is null))';
    buff               :=
      buff ||
      '  				 and (a.in_characterization_value_4 = b.smo_characterization_value_4 or (a.in_characterization_value_4 is null and b.smo_characterization_value_4 is null))';
    buff               :=
      buff ||
      '  				 and (a.in_characterization_value_5 = b.smo_characterization_value_5 or (a.in_characterization_value_5 is null and b.smo_characterization_value_5 is null))';
    buff               := buff || '        		     )';
-- Ancienne Méthode
-- buff :=         'select a.gco_good_id,';
-- buff := buff || ' a.in_characterization_value_1,';
-- buff := buff || ' a.in_characterization_value_2,';
-- buff := buff || ' a.in_characterization_value_3,';
-- buff := buff || ' a.in_characterization_value_4,';
-- buff := buff || ' a.in_characterization_value_5,';
-- buff := buff || ' a.IN_LOT_REFCOMPL,';
-- buff := buff || ' a.in_in_qte,';
-- buff := buff || ' a.gco_good_id || a.IN_LOT_REFCOMPL || a.in_in_qte || a.in_characterization_value_1 || a.in_characterization_value_2 || a.in_characterization_value_3 || a.in_characterization_value_4 || a.in_characterization_value_5';
-- buff := buff || ' from';
-- buff := buff || ' fal_factory_in a';
-- buff := buff || ' where';
-- buff := buff || PrmListIdFalFactoryIn;
-- buff := buff || ' MINUS';
-- buff := buff || ' select b.gco_good_id,';
-- buff := buff || ' b.smo_characterization_value_1,';
-- buff := buff || ' b.smo_characterization_value_2,';
-- buff := buff || ' b.smo_characterization_value_3,';
-- buff := buff || ' b.smo_characterization_value_5,';
-- buff := buff || ' b.smo_characterization_value_5,';
-- buff := buff || ' b.SMO_WORDING,';
-- buff := buff || ' b.smo_movement_quantity,';
-- buff := buff || ' b.gco_good_id || b.SMO_WORDING || b.smo_movement_quantity || b.smo_characterization_value_1 || b.smo_characterization_value_2 || b.smo_characterization_value_3 || b.smo_characterization_value_4 || b.smo_characterization_value_5';
-- buff := buff || ' from';
-- buff := buff || ' stm_stock_movement b';
-- buff := buff || ' where STM_LOCATION_ID = ' || IdLocationAtelier || ' AND gco_good_id in (select gco_good_id from fal_factory_in where ' || PrmListIdFalFactoryIn||')';
    PrmIsOk            := 0;
    LocSource_Cursor   := DBMS_SQL.open_cursor;
    DBMS_SQL.Parse(LocSource_Cursor, Buff, DBMS_SQL.native);
    Ignore             := DBMS_SQL.execute(LocSource_Cursor);

    if DBMS_SQL.fetch_rows(Locsource_cursor) > 0 then
      PrmIsOk  := 0;
    else
      PrmIsOk  := 1;
    end if;

    DBMS_SQL.close_cursor(Locsource_cursor);
  exception
    when others then
      DBMS_SQL.close_cursor(Locsource_cursor);
      PrmIsOk  := 0;
      raise;
  end;

-- La fonction ci dessous fait exactement le même job que MAX mais pour 2 entiers et gère le NULL qu'elle considère comme 0
  function MaximumDe(X integer, Y integer)
    return integer
  is
  begin
    if nvl(X, 0) > nvl(Y, 0) then
      return nvl(X, 0);
    else
      return nvl(Y, 0);
    end if;
  end;

-- Permet d'arrondir un réel à la valeur supérieure selon le nombre de décimale
-- de sa partie fractionnaire qui dépend du produit
  function ArrondiSuperieur(aValue Currency, aGCO_GOOD_ID PCS_PK_ID, aGOO_NUMBER_OF_DECIMAL integer default -1)
    return Currency
  is
    Exposant integer;
    result   number;
  begin
    -- Récupération du nombre de décimal pour le produit
    if aGOO_NUMBER_OF_DECIMAL <> -1 then
      Exposant  := aGOO_NUMBER_OF_DECIMAL;
    else
      if nvl(aGCO_GOOD_ID, 0) = 0 then
        Exposant  := 4;
      else
        Exposant  := GetGOO_Number_Of_Decimal(aGCO_GOOD_ID);
      end if;
    end if;

    -- Calcul de la valeur exposant le nombre de décimale
    result  := aValue * power(10, Exposant);

    -- S'il reste une partie décimale alors
    -- incrémentation de la partie entière de la valeur
    if Frac(result) > 0 then
      if result >= 0 then
        result  := trunc(result) + 1;
      else
        result  := trunc(result);
      end if;
    end if;

    -- Rétablissement de la valeur
    result  := result / power(10, Exposant);
    -- Retourne le résultat arrondi
    return result;
  end;

-- Permet d'arrondir un réel à la valeur inférieure selon le nombre de décimale
-- de sa partie fractionnaire qui dépend du produit
  function ArrondiInferieur(aValue Currency, aGCO_GOOD_ID PCS_PK_ID)
    return Currency
  is
    Exposant integer;
    result   number;
  begin
    -- Récupération du nombre de décimal pour le produit
    if nvl(aGCO_GOOD_ID, 0) = 0 then
      Exposant  := 4;
    else
      Exposant  := GetGOO_Number_Of_Decimal(aGCO_GOOD_ID);
    end if;

    -- Calcul de la valeur exposant le nombre de décimale
    result  := aValue * power(10, Exposant);

    -- S'il reste une partie décimale alors
    -- incrémentation de la partie entière de la valeur
    if Frac(result) > 0 then
      result  := trunc(result);
    end if;

    -- Rétablissement de la valeur
    result  := result / power(10, Exposant);
    -- Retourne le résultat arrondi
    return result;
  end;

-- Permet d'arrondir une valeur à l'entier supérieur
-- La valeur retour est quand même un réel pour garder le typage des qtés sous PCS
  function RoundSuccInt(aValue Currency)
    return Currency
  is
    result Currency;
  begin
    -- Récupération de la partie entière de la valeur
    result  := floor(nvl(aValue, 0) );

    -- Si la valeur est supérieure à sa partie entière alors la fonction retourne
    -- l'entier supérieur
    if aValue > result then
      result  := result + 1;
    end if;

    return result;
  end;

-- Permet de récupérer l'ID du stock par défaut par rapport au bien
  function GetDefltSTM_STOCK_ID(aGoodID Currency)
    return Currency
  is
    result         Currency;
    No_Stock_Found exception;

    cursor CUR_STM_STOCK(aGoodID Currency)
    is
      select STM_STOCK_ID
        from GCO_PRODUCT
       where GCO_GOOD_ID = aGoodID;

    -- Permet de récupérer l'ID du stock par défaut par rapport à la config
    cursor CUR_DEFAULT_STOCK
    is
      select STM_STOCK_ID
        from STM_STOCK
       where upper(STO_DESCRIPTION) = upper(PCS.PC_CONFIG.GetConfig(upper('GCO_DefltSTOCK') ) );
  begin
    result  := null;

    open CUR_STM_STOCK(aGoodID);

    fetch CUR_STM_STOCK
     into result;

    if result is null then
      open CUR_DEFAULT_STOCK;

      fetch CUR_DEFAULT_STOCK
       into result;

      close CUR_DEFAULT_STOCK;

      if result is null then
        raise No_Stock_Found;
      end if;
    end if;

    close CUR_STM_STOCK;

    return result;
  exception
    when No_Stock_Found then
      RAISE_APPLICATION_ERROR(-20010, 'No default stock defined');
  end;

-- Permet de récupérer l'ID de l'emplacement par défaut par rapport au bien ou à l'ID du stock
  function GetDefltSTM_LOCATION_ID(aGoodID Currency, aStockID Currency)
    return Currency
  is
    result Currency;
  begin
    begin
      select STM_LOCATION_ID
        into result
        from GCO_PRODUCT
       where GCO_GOOD_ID = aGoodID;
    exception
      when no_data_found then
        result  := null;
    end;

    if result is null then
      begin
        -- On utilise la nouvelle fonction histoire de ne pas répeter le code sql c'est tout.
        result  := GetMinusLocClaOnStock(aStockID);
      exception
        when no_data_found then
          result  := null;
      end;
    end if;

    return result;
  end;

--------------------------------------------------------------------------------------------------
-- Permet de retourner une clause IN formatée pour éviter un dépassement d'éléments dans la liste
--------------------------------------------------------------------------------------------------
-- Paramètres : aFieldNameForIN -> le nom du champ de la base
--              aListToTreat    -> la liste des éléments avec pour séparateur ","
--              aCheckValue     -> si on test une valeur ou un champ (0 : Champs, 1 : Valeur)
--              aCheckString    -> si on test des valeurs de type chaîne (0 : Autres, 1 : Chaîne)
--
-- Résultat   : il ne reste plus qu'à faire ajout de la chaîne retournée dans la cmd SQL
--
-- Exemple :
--       Remplacer :
--          SQL.Add(' AND FAL_FACTORY_OUT_ID IN ('+ FactoryOutIDList +')');
--       Par :
--          SQL.Add(' AND ' + FracListForSQLClauseIN('FAL_FACTORY_OUT_ID',glbFactoryOutIDList));
--
  function FracListForSQLClauseIN(aFieldNameForIN varchar2, aListToTreat varchar2, aCheckValue integer, aCheckString integer)
    return varchar2
  is
    ListId       MaxVarchar2;
    SubStrListId MaxVarchar2;
    glbResult    MaxVarchar2;
    I            integer;
    strItem      varchar2(100);

    -- Découpe la liste des ID d'entrées atelier en 250 éléments pour la clause IN de la requête
    function EndOfFracList(aListId in out varchar2, aSubStrListId in out varchar2)
      return boolean
    is
      PosInProgress integer;
      PosOfLastItem integer;
      NbrItems      integer;
      result        boolean;
    begin
      -- Par défaut, on retourne la liste en cours et on annonce la fin du découpage
      aSubStrListId  := aListId;
      result         := true;
      -- Initialisation
      NbrItems       := 0;

      -- Initialisation avec la première position
      for PosInProgress in 1 .. length(aListId) loop
        if (NbrItems < 250) then
          if substr(aListId, PosInProgress, 1) = ',' then
            PosOfLastItem  := PosInProgress;
            NbrItems       := NbrItems + 1;
          end if;
        end if;
      end loop;

      -- La liste contient plus de 250 éléments
      if (NbrItems >= 250) then
        -- Récupération de la liste découpée
        aSubStrListId  := substr(aListId, 1, PosOfLastItem - 1);
        -- La liste des entrées restante
        aListId        := substr(aListId, PosOfLastItem + 1, length(aListId) );
        result         := false;
      end if;

      return result;
    end;
  begin
    -- Si il existe des éléments dans la liste à traiter
    if length(aListToTreat) <> 0 then
      ListId     := aListToTreat;
      glbResult  := ' (';

      -- TQ l'on découpe d'ensemble par bloc de "cstNbrMaxItems" éléments
      while not EndOfFracList(ListId, SubStrListId) loop
        -- Si on test une valeur de type chaîne
        if     (aCheckValue = 1)
           and (aCheckString = 1) then
          glbResult  := glbResult || ' ' || '''' || aFieldNameForIN || '''' || ' IN (';
        else
          glbResult  := glbResult || ' ' || aFieldNameForIN || ' IN (';
        end if;

        -- Constitution de la liste de Items
        strItem    := '''';
        I          := 1;

        while I <= length(SubStrListId) loop
          if substr(SubStrListId, I, 1) = ',' then
            if (aCheckString = 1) then
              glbResult  := glbResult || strItem || '''';
            else
              glbResult  := glbResult || strItem;
            end if;

            strItem  := ',' || '''';
          else
            strItem  := strItem || substr(SubStrListId, I, 1);
          end if;

          I  := I + 1;
        end loop;

        if (aCheckString = 1) then
          glbResult  := glbResult || strItem || '''';
        else
          glbResult  := glbResult || strItem;
        end if;

        glbResult  := glbResult || ') OR ';
      end loop;

      -- Si on test une valeur de type chaîne
      if     (aCheckValue = 1)
         and (aCheckString = 1) then
        glbResult  := glbResult || ' ' || '''' || aFieldNameForIN || '''' || ' IN (';
      else
        glbResult  := glbResult || ' ' || aFieldNameForIN || ' IN (';
      end if;

      -- Constitution de la liste de Items
      strItem    := '''';
      I          := 1;

      while I <= length(SubStrListId) loop
        if substr(SubStrListId, I, 1) = ',' then
          if (aCheckString = 1) then
            glbResult  := glbResult || strItem || '''';
          else
            glbResult  := glbResult || strItem;
          end if;

          strItem  := ',' || '''';
        else
          strItem  := strItem || substr(SubStrListId, I, 1);
        end if;

        I  := I + 1;
      end loop;

      if (aCheckString = 1) then
        glbResult  := glbResult || strItem || '''';
      else
        glbResult  := glbResult || strItem;
      end if;

      glbResult  := glbResult || ')) ';
    -- Sinon il faut retourner une condition forcément fausse
    else
      -- Si on test une valeur de type chaîne
      if     (aCheckValue = 1)
         and (aCheckString = 1) then
        glbResult  := '''' || aFieldNameForIN || '''' || ' = ''''';
      else
        glbResult  := aFieldNameForIN || ' = 0';
      end if;
    end if;

    return glbResult;
  end;

--------------------------------------------------------------------------------------------------
-- Permet de définir si un ID de lot à pour besoin inial un N° commande spécifique
--------------------------------------------------------------------------------------------------
-- Retourne :
--    -1 si erreur
--    0  si NOK
--    1  si OK
  function CheckLotFromInitNeed(aLotID Currency, aRefInitNeed DOC_DOCUMENT.DMT_NUMBER%type)
    return integer
  is
    cursor GetSupplyRecords
    is
      select FAL_NETWORK_SUPPLY_ID
        from FAL_NETWORK_SUPPLY
       where FAL_LOT_ID = aLotID;

    vSupplyRecord  GetSupplyRecords%rowtype;
    result         integer;
    BuffSQL        MaxVarChar2;
    IntResult      integer;
    CurSQL         integer;
    Ignore         integer;
    ResGetInitNeed MaxVarChar2;
  begin
    result  := 0;

    -- Ouverture du curseur
    open GetSupplyRecords;

    loop
      fetch GetSupplyRecords
       into vSupplyRecord;

      -- S'assurer qu'il y ai un enregistrement et que l'on a toujours pas trouver...
      exit when(GetSupplyRecords%notfound)
            or (result = 1);
      ResGetInitNeed  := GET_BESOIN_ORIGINE(vSupplyRecord.FAL_NETWORK_SUPPLY_ID, ',');
      ResGetInitNeed  := substr(ResGetInitNeed, 1, length(ResGetInitNeed) - 1);

      if length(ResGetInitNeed) <> 0 then
        BuffSQL  := ' SELECT COUNT(1) ';
        BuffSQL  := BuffSQL || ' FROM DUAL ';
        BuffSQL  := BuffSQL || ' WHERE ' || FracListForSQLClauseIN(aRefInitNeed, ResGetInitNeed, 1, 1);
        -- Ligne de test de la commande SQL
        --DBMS_OUTPUT.PUT_LINE(BuffSQL);
        CurSQL   := DBMS_SQL.Open_Cursor;

        begin
          DBMS_SQL.Parse(CurSQL, BuffSQL, DBMS_SQL.V7);
          DBMS_SQL.Define_Column(CurSQL, 1, IntResult);
          Ignore  := DBMS_SQL.execute(CurSQL);

          if (DBMS_SQL.Fetch_Rows(CurSQL) > 0) then
            DBMS_SQL.column_value(CurSQL, 1, IntResult);

            if IntResult > 0 then
              -- Le lot est bien issu du besoin initial du N° commande
              result  := 1;
            else
              -- Le lot n'est pas issu du besoin initial du N° commande
              result  := 0;
            end if;
          else
            -- Pb d'exécution
            result  := -1;
          end if;

          DBMS_SQL.Close_Cursor(CurSQL);
        exception
          when others then
            DBMS_SQL.Close_Cursor(CurSQL);

            close GetSupplyRecords;

            raise;
        end;
      end if;
    end loop;

    -- Fermeture du curseur
    close GetSupplyRecords;

    return result;
  end;

--------------------------------------------------------------------------------------------------
-- Permet d'utiliser la fonction qui retourne si un ID de lot à pour besoin inial un N° commande spécifique
-- Mais ceci avec un passage par paramètre pour la valeur de retour
--------------------------------------------------------------------------------------------------
-- Retourne :
--    -1 si erreur
--    0  si NOK
--    1  si OK
  procedure CheckLotFromInitNeed(aLotID Currency, aRefInitNeed DOC_DOCUMENT.DMT_NUMBER%type, aResult out integer)
  is
  begin
    aResult  := CheckLotFromInitNeed(aLotID, aRefInitNeed);
  end;

--------------------------------------------------------------------------------------------------
-- Permet de retourner la liste des N° Commande selon un ID de lot
--------------------------------------------------------------------------------------------------
  function GetInitNeedListFromLotID(aLotID PCS_PK_ID, aSeparator varchar2)
    return varchar2
  is
    cursor GetSupplyRecords
    is
      select FAL_NETWORK_SUPPLY_ID
        from FAL_NETWORK_SUPPLY
       where FAL_LOT_ID = aLotID;

    vSupplyRecord  GetSupplyRecords%rowtype;
    ResGetInitNeed MaxVarChar2;
    I              integer;
    result         MaxVarChar2;
  begin
    result  := '';

    -- Ouverture du curseur
    open GetSupplyRecords;

    fetch GetSupplyRecords
     into vSupplyRecord;

    -- S'assurer qu'il y ai un enregistrement...
    if GetSupplyRecords%found then
      ResGetInitNeed  := GET_BESOIN_ORIGINE(vSupplyRecord.FAL_NETWORK_SUPPLY_ID, aSeparator);

      if length(ResGetInitNeed) <> 0 then
        result  := substr(ResGetInitNeed, 1, length(ResGetInitNeed) - length(aSeparator) );
      end if;
    end if;

    -- Fermeture du curseur
    close GetSupplyRecords;

    return result;
  end;

--------------------------------------------------------------------------------------------------
-- Permet de retourner la liste des N° Commande selon un ID de proposition de lot
--------------------------------------------------------------------------------------------------
  function GetInitNeedListFromLotPropID(aLotPropID PCS_PK_ID, aSeparator varchar2)
    return varchar2
  is
    cursor GetSupplyRecords
    is
      select FAL_NETWORK_SUPPLY_ID
        from FAL_NETWORK_SUPPLY
       where FAL_LOT_PROP_ID = aLotPropID;

    vSupplyRecord  GetSupplyRecords%rowtype;
    ResGetInitNeed MaxVarChar2;
    I              integer;
    result         MaxVarChar2;
  begin
    result  := '';

    -- Ouverture du curseur
    open GetSupplyRecords;

    fetch GetSupplyRecords
     into vSupplyRecord;

    -- S'assurer qu'il y ait un enregistrement...
    if GetSupplyRecords%found then
      ResGetInitNeed  := GET_BESOIN_ORIGINE(vSupplyRecord.FAL_NETWORK_SUPPLY_ID, aSeparator);

      if length(ResGetInitNeed) <> 0 then
        result  := substr(ResGetInitNeed, 1, length(ResGetInitNeed) - length(aSeparator) );
      end if;
    end if;

    -- Fermeture du curseur
    close GetSupplyRecords;

    return result;
  end;

-- Fonction qui retourne un nouvel ID, deprecated, utiliser la fonction PLSQL GetNewId sans prefixer du nom du package
--   function GetNewID

  /**
  * procedure : GetConfig_StockID
  * Description : Récupération de l'ID d'un stock par sa description
  *
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param    ConfigWord : Description du stock recherché
  * @return   ID du stock
  */
  function GetConfig_StockID(ConfigWord varchar)
    return STM_STOCK.STM_STOCK_ID%type
  is
    aSTM_STOCK_ID number;
  begin
    aSTM_STOCK_ID  := null;

    select STM_STOCK_ID
      into aSTM_STOCK_ID
      from STM_STOCK
     where STO_DESCRIPTION = PCS.PC_CONFIG.GetConfig(ConfigWord);

    return aSTM_STOCK_ID;
  exception
    when no_data_found then
      return null;
  end;

  /**
  * procedure : GetConfig_LocationID
  * Description : Récupération de l'ID d'un emplacement par son stock et sa description
  *
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param    ConfigWord : Description de l'emplacement recherché recherché
  * @param    PrmSTM_STOCK_ID : ID du stock
  * @return   ID de l'emplacement du stock.
  */
  function GetConfig_LocationID(ConfigWord varchar, PrmSTM_STOCK_ID STM_STOCK.STM_STOCK_ID%type)
    return STM_LOCATION.STM_LOCATION_ID%type
  is
    aSTM_LOCATION_ID STM_LOCATION.STM_LOCATION_ID%type;
  begin
    aSTM_LOCATION_ID  := null;

    select STM_LOCATION_ID
      into aSTM_LOCATION_ID
      from STM_LOCATION
     where LOC_DESCRIPTION = PCS.PC_CONFIG.GetConfig(ConfigWord)
       and STM_STOCK_ID = PrmSTM_STOCK_ID;

    return aSTM_LOCATION_ID;
  exception
    when no_data_found then
      return null;
  end;

-- Permet de récupérer l' emplacement ayant la plus petite classification pour le stock donné
  function GetMinusLocClaOnStock(aSTM_STOCK_ID STM_STOCK.STM_STOCK_ID%type)
    return STM_LOCATION.STM_LOCATION_ID%type
  is
    calcSTM_LOCATION_ID STM_LOCATION.STM_LOCATION_ID%type;

    cursor C1
    is
      select   STM_LOCATION_ID
          from STM_LOCATION
         where STM_STOCK_ID = aSTM_STOCK_ID
      order by LOC_CLASSIFICATION asc;
  begin
    calcSTM_LOCATION_ID  := null;

    open C1;

    fetch C1
     into calcSTM_LOCATION_ID;

    close C1;

    return calcSTM_LOCATION_ID;
  end;

-- Cette Fonction retourne le stock et l'emplacement
-- D'abord en tenant compte des paramètres en entrées préconisés pour Stock et Emplacement puis du produit
-- Traduction de la procedure Delphi:GetStockEtEmplacementStartWithParamsFirstAndGoodAfter du source FAl_fctfunctions.PAs
  procedure GetStockEmpWithPrmsAndGood(
    PrmSTM_STOCK_ID           STM_STOCK.STM_STOCK_ID%type
  , PrmSTM_LOCATION_ID        STM_LOCATION.STM_LOCATION_ID%type
  , PrmGCO_GOOD_ID            GCO_GOOD.GCO_GOOD_ID%type
  , OutSTM_STOCK_ID    in out STM_STOCK.STM_STOCK_ID%type
  , OutSTM_LOCATION_ID in out STM_LOCATION.STM_LOCATION_ID%type
  )
  is
  begin
    --  Détermination de outSTM_STOCK_ID
    outSTM_STOCK_ID  := nvl(PrmSTM_STOCK_ID, GETDEFLTSTM_STOCK_ID(PrmGCO_GOOD_ID) );

    -- Détermination du outSTM_LOCATION_ID
    if nvl(PrmSTM_LOCATION_ID, 0) = 0 then
      if nvl(PrmSTM_STOCK_ID, 0) <> 0 then
        outSTM_LOCATION_ID  := GetMinusLocClaOnStock(PrmSTM_STOCK_ID);
      else
        -- raise_application_error(-20001, 'outSTock = ' || nvl(outSTM_STOCK_ID,0) || 'Good = ' ||PrmGCo_GOOD_ID);
        OutSTM_LOCATION_ID  := GetDefltSTM_LOCATION_ID(PrmGCO_GOOD_ID, outSTM_STOCK_ID);
      end if;
    else
      OutSTM_LOCATION_ID  := PrmSTM_LOCATION_ID;
    end if;
  end;

-- Cette fonction retrourne
--   1 si s1 est contenu dans les éléments de s2 séparés par le caractère car
--   0 dans tous les autres cas
--   Attention: Utiliser cette fonction avec un caractère NULL n'a aucun sens
--              Exemple si chaine     = 1200.100.101
--                         souschaine = 120
--                         Résultat vrai.
  function IsSubStrInStrWithSepar(Chaine varchar, SousChaine varchar, car varchar)
    return number
  is
    RESULTAT number;
  begin
    RESULTAT  := 0;

    if chaine = souschaine then
      RESULTAT  := 1;
    end if;

    if car is null then
      raise_application_error
                           (-20001
                          , PCS.PC_FUNCTIONS.TRANSLATEWORD('PCS - Valeur incorrecte pour la fonction IsSubStrInStrWithSepar. Le séparateur ne peut être nul.')
                           );
      RESULTAT  := 0;
    end if;

    if (car is not null) then
      if instr(car || chaine || car, Car || SousChaine || Car, 1) > 0 then
        RESULTAT  := 1;
      else
        RESULTAT  := 0;
      end if;
    end if;

    return RESULTAT;
  end;

  -- Cette fonction retourne le titre d'un dossier
  -- Paramètre entrant: Le dossier DOC_RECORD_ID
  function GetRCO_TITLE(inDOC_RECORD_ID DOC_RECORD.DOC_RECORD_ID%type)
    return varchar
  is
    cursor C1
    is
      select RCO_TITLE
        from DOC_RECORD
       where DOC_RECORD_ID = inDOC_RECORD_ID;

    BuffRCO_TITLE DOC_RECORD.RCO_TITLE%type   := null;
  begin
    open C1;

    fetch C1
     into BuffRCO_TITLE;

    close C1;

    return BuffRCO_TITLE;
  end;

-- Cette function renvoie la chaine ' (*)' s'il existe pour la produit donné
-- une ou plsuieusr Appro (FAL_NETWORK_SUPPLY)
-- ayant:
--     lot non null ou detail position non null
--     ET Qté libre > 0
  function StartIfGoodHasApproWithFreeQty(inGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type)
    return varchar
  is
    OutVarchar varchar2(10);
    Finder     number;

    cursor C1
    is
      select 1
        from FAL_NETWORK_SUPPLY
       where (GCO_GOOD_ID = inGCO_GOOD_ID)
         and (   FAL_LOT_ID is not null
              or DOC_POSITION_DETAIL_ID is not null)
         and (FAN_FREE_QTY > 0);
  begin
    outVarchar  := null;

    open C1;

    fetch C1
     into Finder;

    if C1%found then
      OutVarchar  := ' (*)';
    end if;

    close C1;

    return OutVarchar;
  end;

-------------------------------------------------------------------
-- Détermination si le détail position porte sur un emplacement
-- d'un stock "En-Cours PIC" (fonction créée pour fil rouge 0730)
-------------------------------------------------------------------
  function IsLocationOnStockNeedPic(aSTM_LOCATION_ID STM_LOCATION.STM_LOCATION_ID%type)
    return boolean
  is
    cursor Cur_Stock_Need_Pic(aSTM_LOCATION_ID STM_LOCATION.STM_LOCATION_ID%type)
    is
      select nvl(STO_NEED_PIC, 0)
        from STM_STOCK SS
           , STM_LOCATION SL
       where SS.STM_STOCK_ID = SL.STM_STOCK_ID
         and SL.STM_LOCATION_ID = aSTM_LOCATION_ID;

    nSTO_NEED_PIC STM_STOCK.STO_NEED_PIC%type;
  begin
    nSTO_NEED_PIC  := 0;

    open Cur_Stock_Need_Pic(aSTM_LOCATION_ID);

    fetch Cur_Stock_Need_Pic
     into nSTO_NEED_PIC;

    close Cur_Stock_Need_Pic;

    return(nSTO_NEED_PIC = 1);
  end;

---------------------------------------------------------------------------------------------
--  Retourner la valeur de l'emplacement de stock pour un Produit donné et un stock donné
---------------------------------------------------------------------------------------------
  function GetLocationFromCompldataStock(aGoodID GCO_GOOD.GCO_GOOD_ID%type, aStockID STM_STOCk.STM_STOCK_ID%type)
    return STM_LOCATION.STM_LOCATION_ID%type
  is
    resultSTM_LOCATION_ID STM_LOCATION.STM_LOCATION_ID%type;
  begin
    resultSTM_LOCATION_ID  := 0;

    select nvl(STM_LOCATION_ID, 0)
      into resultSTM_LOCATION_ID
      from GCO_COMPL_DATA_STOCK
     where GCO_GOOD_ID = aGoodID
       and STM_STOCK_ID = aStockID;

    if resultSTM_LOCATION_ID = 0 then   -- Hé oui car la requete retourne peut-être quand même un élément mais nulle
      resultSTM_LOCATION_ID  := GetMinusLocClaOnStock(aStockId);
    end if;

    return resultSTM_LOCATION_ID;
  exception
    when no_data_found then
      resultSTM_LOCATION_ID  := GetMinusLocClaOnStock(aStockId);
      return resultSTM_LOCATION_ID;
  end;

-- Cette fonction retourne l'arrondi supérieur avec le modulo
-- Exemple avec ( 0,30) = > resultat 30
-- Exemple avec (29,30) = > resultat 30
-- Exemple avec (30,30) = > resultat 30
-- Exemple avec (31,60) = > resultat 60
-- Exemple avec (60,60) = > resultat 60
  function ArrondiSupSelonModulo(valeur number, Modulo number)
    return number
  is
    Resultat number;
  begin
    if nvl(Valeur, 0) <> 0 then
      Resultat  := nvl(Valeur, 0) / Modulo;

      if Frac(Resultat) <> 0 then
        Resultat  := trunc(Resultat) + 1;
      else
        Resultat  := trunc(Resultat);
      end if;

      resultat  := Resultat * Modulo;
    else
      resultat  := Modulo;
    end if;

    return resultat;
  end;

/**********************************************************************************************************
* PRD-A040212-32400 : Retourne la quantité disponible pour un produit, à la date passée en paramètre.
*     Tous les stocks qui ont le flag "Calcul des besoins" sont pris en compte.
*   - aGCO_GOOD_ID     : Produit
*      - aUseRequierementCalculationProp : Prise en compte des propositions calcul des besoins.
*      - aUseOnlyFreeQuantity : Prise en compte uniquement les quantités libres
*      - aUseMinimumStock : Prise en compte stock mini (Oui = 1, Non = 0)
*      - aUseProvisoryQty : Prise en compte des Quantité provisoires (Entrée - sortie) (Oui = 1, Non = 0).
*      - aUseMasterPlanProp : Prise en compte des propositions plan directeur.
*      - aDate            : Date d'évaluation
*/
  function GetGoodAvailableQuantity(
    aGCO_GOOD_ID                   GCO_GOOD.GCO_GOOD_ID%type
  , aUseRequirementCalculationProp number
  , aUseOnlyFreeQuantity           number
  , aUseMinimumStock               number
  , aUseProvisoryQty               number
  , aUseMasterPlanProp             number
  , aDate                          date
  )
    return number
  is
    cursor CUR_STOCK_AVAILABLE_QTY
    is
      select (decode(aUseMinimumStock
                   , 0, nvl(Available_Qty.SPO_AVAILABLE_QUANTITY, 0) + nvl(Available_Qty.SPO_ASSIGN_QUANTITY, 0)
                   , (nvl(Available_Qty.SPO_AVAILABLE_QUANTITY, 0) + nvl(Available_Qty.SPO_ASSIGN_QUANTITY, 0) - nvl(Min_Stock.CST_QUANTITY_MIN, 0) )
                    ) +
              decode(aUseProvisoryQty, 1, nvl(Available_Qty.SPO_PROVISORY_INPUT, 0), 0)
             ) AVAILABLE_STOCK_QTY
        from (select sum(nvl(SPO.SPO_AVAILABLE_QUANTITY, 0) ) SPO_AVAILABLE_QUANTITY
                   , sum(nvl(SPO.SPO_PROVISORY_INPUT, 0) ) SPO_PROVISORY_INPUT
                   , decode(aUseOnlyFreeQuantity, 0, sum(nvl(SPO.SPO_ASSIGN_QUANTITY, 0) ), 0) SPO_ASSIGN_QUANTITY
                from STM_STOCK_POSITION SPO
                   , STM_STOCK STO
               where STO.STM_STOCK_ID = SPO.STM_STOCK_ID
                 and STO.STO_NEED_CALCULATION = 1
                 and SPO.GCO_GOOD_ID = aGCO_GOOD_ID) Available_Qty
           , (select sum(nvl(CDA.CST_QUANTITY_MIN, 0) ) CST_QUANTITY_MIN
                from GCO_COMPL_DATA_STOCK CDA
                   , STM_STOCK STO
               where CDA.GCO_GOOD_ID = aGCO_GOOD_ID
                 and CDA.STM_STOCK_ID = STO.STM_STOCK_ID
                 and STO.STO_NEED_CALCULATION = 1) Min_Stock;

    cursor CUR_NEED(aC_GAUGE_TITLE varchar2)
    is
      select sum(nvl(FAN.FAN_FREE_QTY, 0) ) FAN_FREE_QTY_NEED
           , decode(aUseOnlyFreeQuantity, 1, 0, sum(nvl(FAN.FAN_STK_QTY, 0) ) ) FAN_STK_QTY_NEED
           , decode(aUseOnlyFreeQuantity, 1, 0, sum(nvl(FAN.FAN_NETW_QTY, 0) ) ) FAN_NETW_QTY_NEED
           , sum(nvl(FAN.FAN_BALANCE_QTY, 0) ) FAN_BALANCE_QTY_NEED
        from FAL_NETWORK_NEED FAN
       where FAN.GCO_GOOD_ID = aGCO_GOOD_ID
         and FAN.FAN_BEG_PLAN < aDate + 1
         and (    (aUseOnlyFreeQuantity = 0)
              or (    aUseOnlyFreeQuantity = 1
                  and FAN.FAN_FREE_QTY > 0) )
         and (    (    aUseRequirementCalculationProp = 1
                   and aUseMasterPlanProp = 1)
              or (    aUseRequirementCalculationProp = 0
                  and aUseMasterPlanProp = 0
                  and FAN.FAL_DOC_PROP_ID is null
                  and FAN.FAL_LOT_PROP_ID is null
                  and FAN.FAL_LOT_MAT_LINK_PROP_ID is null
                  and FAN.C_GAUGE_TITLE <> aC_GAUGE_TITLE
                 )
              or (    aUseRequirementCalculationProp = 0
                  and aUseMasterPlanProp = 1
                  and (    (    FAN.FAL_DOC_PROP_ID is null
                            and FAN.FAL_LOT_PROP_ID is null
                            and FAN.FAL_LOT_MAT_LINK_PROP_ID is null
                            and FAN.C_GAUGE_TITLE <> aC_GAUGE_TITLE
                           )
                       or (     (   FAN.FAL_DOC_PROP_ID is not null
                                 or FAN.FAL_LOT_PROP_ID is not null
                                 or FAN.FAL_LOT_MAT_LINK_PROP_ID is not null)
                           and (FAN.C_GAUGE_TITLE = aC_GAUGE_TITLE)
                          )
                      )
                 )
              or (    aUseRequirementCalculationProp = 1
                  and aUseMasterPlanProp = 0
                  and FAN.C_GAUGE_TITLE <> aC_GAUGE_TITLE)
             );

    cursor CUR_SUPPLY(aC_GAUGE_TITLE varchar2)
    is
      select sum(nvl(FNS.FAN_FREE_QTY, 0) ) FAN_FREE_QTY_SUPPLY
           , decode(aUseOnlyFreeQuantity, 1, 0, sum(nvl(FNS.FAN_STK_QTY, 0) ) ) FAN_STK_QTY_SUPPLY
           , decode(aUseOnlyFreeQuantity, 1, 0, sum(nvl(FNS.FAN_NETW_QTY, 0) ) ) FAN_NETW_QTY_SUPPLY
           , sum(nvl(FNS.FAN_BALANCE_QTY, 0) ) FAN_BALANCE_QTY_SUPPLY
        from FAL_NETWORK_SUPPLY FNS
       where FNS.GCO_GOOD_ID = aGCO_GOOD_ID
         and FNS.FAN_END_PLAN < aDate + 1
         and (    (aUseOnlyFreeQuantity = 0)
              or (    aUseOnlyFreeQuantity = 1
                  and FNS.FAN_FREE_QTY > 0) )
         and (    (    aUseRequirementCalculationProp = 1
                   and aUseMasterPlanProp = 1)
              or (    aUseRequirementCalculationProp = 0
                  and aUseMasterPlanProp = 0
                  and FNS.FAL_DOC_PROP_ID is null
                  and FNS.FAL_LOT_PROP_ID is null
                  and FNS.FAL_LOT_MAT_LINK_PROP_ID is null
                  and FNS.C_GAUGE_TITLE <> aC_GAUGE_TITLE
                 )
              or (    aUseRequirementCalculationProp = 0
                  and aUseMasterPlanProp = 1
                  and (    (    FNS.FAL_DOC_PROP_ID is null
                            and FNS.FAL_LOT_PROP_ID is null
                            and FNS.FAL_LOT_MAT_LINK_PROP_ID is null
                            and FNS.C_GAUGE_TITLE <> aC_GAUGE_TITLE
                           )
                       or (     (   FNS.FAL_DOC_PROP_ID is not null
                                 or FNS.FAL_LOT_PROP_ID is not null
                                 or FNS.FAL_LOT_MAT_LINK_PROP_ID is not null)
                           and (FNS.C_GAUGE_TITLE = aC_GAUGE_TITLE)
                          )
                      )
                 )
              or (    aUseRequirementCalculationProp = 1
                  and aUseMasterPlanProp = 0
                  and FNS.C_GAUGE_TITLE <> aC_GAUGE_TITLE)
             );

    CurStockAvailableQty CUR_STOCK_AVAILABLE_QTY%rowtype;
    CurNeed              CUR_NEED%rowtype;
    CurSupply            CUR_SUPPLY%rowtype;
    nAvailableStockQty   number;
    nBalanceQtyNeed      number;
    nBalanceQtySupply    number;
  begin
    nAvailableStockQty  := 0;
    nBalanceQtyNeed     := 0;
    nBalanceQtySupply   := 0;

    -- Quantité disponible en stocks (Avec prise en compte Stock minin ou pas) .
    open CUR_STOCK_AVAILABLE_QTY;

    fetch CUR_STOCK_AVAILABLE_QTY
     into CurStockAvailableQty;

    if     (CUR_STOCK_AVAILABLE_QTY%found)
       and (CurStockAvailableQty.AVAILABLE_STOCK_QTY is not null) then
      nAvailableStockQty  := CurStockAvailableQty.AVAILABLE_STOCK_QTY;
    end if;

    close CUR_STOCK_AVAILABLE_QTY;

    -- Besoins à la date souhaitée
    open CUR_NEED(PCS.PC_CONFIG.GETCONFIG('FAL_TITLE_PLAN_DIR') );

    fetch CUR_NEED
     into CurNeed;

    if (CUR_NEED%found) then
      nBalanceQtyNeed  := nvl(CurNeed.FAN_FREE_QTY_NEED, 0) + nvl(CurNeed.FAN_STK_QTY_NEED, 0) + nvl(CurNeed.FAN_NETW_QTY_NEED, 0);
    end if;

    close CUR_NEED;

    -- Appro à la date souhaitée
    open CUR_SUPPLY(PCS.PC_CONFIG.GETCONFIG('FAL_TITLE_PLAN_DIR') );

    fetch CUR_SUPPLY
     into CurSupply;

    if (CUR_SUPPLY%found) then
      nBalanceQtySupply  := nvl(CurSupply.FAN_FREE_QTY_SUPPLY, 0) + nvl(CurSupply.FAN_STK_QTY_SUPPLY, 0) + nvl(CurSupply.FAN_NETW_QTY_SUPPLY, 0);
    end if;

    close CUR_SUPPLY;

    -- Retour de la quantité disponible pour le produit à la date données
    return(nAvailableStockQty - nBalanceQtyNeed + nBalanceQtySupply);
  end GetGoodAvailableQuantity;

-- Retourne 1 si l'id de la caractérisation correspond à une caractérisation de type
--            Version ou caractéristique
-- Retourne 0 dans tous les autres cas
  function VersionOrCharacteristicType(aGCO_CHARACTERIZATION_ID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type, aC_CHARACT_TYPE varchar2 default null)
    return integer
  is
    BuffC_CHARACT_TYPE GCo_CHARACTERIZATION.C_CHARACT_TYPE%type;
    version            boolean;
    Characteristic     boolean;
  begin
    if aGCO_CHARACTERIZATION_ID is not null then
      begin
        if aC_CHARACT_TYPE is null then
          select C_CHARACT_TYPE
            into BuffC_CHARACT_TYPE
            from GCO_CHARACTERIZATION
           where GCO_CHARACTERIZATION_ID = aGCO_CHARACTERIZATION_ID;
        else
          BuffC_CHARACT_TYPE  := aC_CHARACT_TYPE;
        end if;

        version         := BuffC_CHARACT_TYPE = 1;

        -- Attention, Si la config est à 4 on considère que nous n'avons pas de caractérisation de type version
        if to_number(PCS.PC_CONFIG.GetConfig('FAL_ATTRIB_ON_CHARACT_MODE') ) = 4 then
          version  := false;
        end if;

        Characteristic  := BuffC_CHARACT_TYPE = 2;

        if (   version
            or Characteristic) then
          return 1;
        else
          return 0;
        end if;
      exception
        when no_data_found then
          return 0;
      end;
    else
      return 0;
    end if;
  end;

-- Retourne 1 si le produit est géré avec une caractérisation de type
--            Version ou caractéristique
-- Retourne 0 dans tous les autres cas
  function ProductHasVersionOrCharacteris(prmGCO_GOOD_ID GCo_GOOD.GCO_GOOD_ID%type)
    return integer
  is
    aGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type;

    cursor C1
    is
      select gco_good_id
        from GCO_CHARACTERIZATION
       where GCO_GOOD_ID = prmGCO_GOOD_ID
         and c_charact_type in(1, 2);

    cursor C2
    is
      select gco_good_id
        from GCO_CHARACTERIZATION
       where GCO_GOOD_ID = prmGCO_GOOD_ID
         and c_charact_type in(2);
  begin
    -- Explication du pourquoi des 2 curseurs.
    -- Si nous avons 4 dans la config FAL_ATTRIB_ON_CHARACT_MODE nous ne gérons
    -- pas les versions comme des versions au sens initial du terme.
    if to_number(PCS.PC_CONFIG.GetConfig('FAL_ATTRIB_ON_CHARACT_MODE') ) <> 4 then
      open C1;

      fetch C1
       into aGCO_GOOD_ID;

      if C1%found then
        close C1;

        return 1;
      else
        close C1;

        return 0;
      end if;
    else
      open C2;

      fetch C2
       into aGCO_GOOD_ID;

      if C2%found then
        close C2;

        return 1;
      else
        close C2;

        return 0;
      end if;
    end if;
  end;

-- Retourne NULL   si la caractérisation est une caractérisation de type autre
--                 que version ou caractéristique
--
-- Retourne aValue dans tous les autres cas.
  function NullForNoMorpho(aGCO_CHARACTERIZATION_ID number, aValue varchar)
    return varchar
  is
    BuffC_CHARACT_TYPE GCo_CHARACTERIZATION.C_CHARACT_TYPE%type;
  begin
    if VersionOrCharacteristicType(aGCO_CHARACTERIZATION_ID) = 1 then
      return aValue;
    else
      return null;
    end if;
  exception
    when no_data_found then
      return null;
  end;

  function NullForNoMorpho(aGCO_CHARACTERIZATION_ID number, aValue varchar, aC_CHARACT_TYPE varchar2)
    return varchar
  is
  begin
    if VersionOrCharacteristicType(aGCO_CHARACTERIZATION_ID, aC_CHARACT_TYPE) = 1 then
      return aValue;
    else
      return null;
    end if;
  exception
    when no_data_found then
      return null;
  end;

------------------------------------------------------------------------------------------------
-- Donne la valeur du STM_STOCK_ID en fonction de la description
------------------------------------------------------------------------------------------------
  function GetSTM_STOCK_ID(aSTO_DESCRIPTION STM_STOCk.STO_DESCRIPTION%type)
    return PCS_PK_ID
  is
    Resultat STM_STOCK.STM_STOCK_ID%type;
  begin
    select STM_STOCK_ID
      into resultat
      from STM_STOCK
     where upper(STO_DESCRIPTION) = upper(aSTO_DESCRIPTION);

    return resultat;
  exception
    when others then
      raise;
      return null;
  end;

------------------------------------------------------------------------------------------------
-- retourne 1 si les 2 valeurs sont égales
--          0 dans les autres cas.
------------------------------------------------------------------------------------------------
  function identical(a number, b number)
    return integer
  is
  begin
    if nvl(a, 0) = nvl(b, 0) then
      return 1;
    else
      return 0;
    end if;
  end;

-- Cette fonction enlève les 0 situés tout de suite derrière le séparateur
-- Pourquoi cette fonction a été crée
--  - parce que la SMO_WORDING de STM_STOCK_MOVEMENT n'a pas hélas subit les mêmes modifications au cours du temps.
-- Ainsi pour comparer les IN_LOT_REFCOMPL des FAL_FACTORY_IN avec les SMO_WORDING il faut utiliser cette fonction

  -- Exemples
--   SimplifyREF_COMPL('PF-000123-23-1','-') retourne -123-23-1
--   SimplifyREF_COMPL('PF-001-00015-1','-') retourne -1-15-1
--   !!! pièges
--       SimplifyREF_COMPL('PF-001-00015.1','-')  retourne -1-151
--       => C'est pour cette raison qu'il faut mieux utiliser lors de l'appel qqchose
--          comme SimplifyREF_COMPL(replace(SMO_WORDING,'.','-'),'-') remplaçant ainsi
--          tout '.' avec le séparateur normal.
  function SimplifyREF_COMPL(RefBuff varchar, separateur varchar)
    return varchar
  is
    I        number;
    Tiret    boolean;
    Res      varchar(2000);
    ResEpure varchar(2000);
  begin
    I         := 1;
    Tiret     := true;
    Res       := '';

    loop
      if substr(RefBUff, I, 1) = separateur then
        Tiret  := true;
      end if;

      if not tiret then
        res  := Res || substr(RefBUff, I, 1);
      end if;

      if Tiret then
        if substr(RefBUff, I, 1) <> '0' then
          res  := Res || substr(RefBUff, I, 1);

          if substr(RefBUff, I, 1) <> separateur then
            Tiret  := false;
          end if;
        end if;
      end if;

      I  := I + 1;
      exit when I > length(RefBuff);
    end loop;

    -- Enlever tout ce qui n'est pas chiffre ou séparateur
    I         := 1;
    ResEpure  := null;

    loop
      if    ( (    substr(Res, I, 1) >= '0'
               and substr(Res, I, 1) <= '9') )
         or substr(Res, I, 1) = separateur then
        ResEpure  := ResEpure || substr(Res, I, 1);
      end if;

      I  := I + 1;
      exit when I > length(Res);
    end loop;

    return ResEpure;
  end;

------------------------------------------------------------------------------------------------
-- Fonction qui retourne la séquence de l'opération d'un lot ou d'une proposition
-- sur laquelle est lié le composant.
-- Retourne 0 si ce lien opération/Composant n'existe pas.
------------------------------------------------------------------------------------------------
  function GetOperationNumberLinked(LotCibleId FAL_LOT.FAL_LOT_ID%type, ComposantId FAL_LOT.GCO_GOOD_ID%type)
    return number
  is
    cursor CUR_LOT(LotCibleId FAL_LOT.FAL_LOT_ID%type, ComposantId FAL_LOT.GCO_GOOD_ID%type)
    is
      select FTL.SCS_STEP_NUMBER
        from FAL_LOT FL
           , FAL_LOT_MATERIAL_LINK FLML
           , FAL_TASK_LINK FTL
       where FL.FAL_LOT_ID = FLML.FAL_LOT_ID
         and FTL.FAL_LOT_ID = FL.FAL_LOT_ID
         and FTL.SCS_STEP_NUMBER = FLML.LOM_TASK_SEQ
         and FL.FAL_LOT_ID = LotCibleId
         and FLML.GCO_GOOD_ID = ComposantId;

    cursor CUR_LOT_PROP(LotCibleId FAL_LOT.FAL_LOT_ID%type, ComposantId FAL_LOT.GCO_GOOD_ID%type)
    is
      select FTLP.SCS_STEP_NUMBER
        from FAL_LOT_PROP FLP
           , FAL_LOT_MAT_LINK_PROP FLMLP
           , FAL_TASK_LINK_PROP FTLP
       where FLP.FAL_LOT_PROP_ID = FLMLP.FAL_LOT_PROP_ID
         and FTLP.FAL_LOT_PROP_ID = FLP.FAL_LOT_PROP_ID
         and FTLP.SCS_STEP_NUMBER = FLMLP.LOM_TASK_SEQ
         and FLP.FAL_LOT_PROP_ID = LotCibleId
         and FLMLP.GCO_GOOD_ID = ComposantId;

    result number;
  begin
    result  := null;

    open CUR_LOT(LotCibleId, ComposantId);

    fetch CUR_LOT
     into result;

    if CUR_LOT%notfound then
      open CUR_LOT_PROP(LotCibleId, ComposantId);

      fetch CUR_LOT_PROP
       into result;

      close CUR_LOT_PROP;
    end if;

    close CUR_LOT;

    return nvl(result, 0);
  end;

-- Cette Fonction retourne une chaine indiquant comment l'attribution a été construite
-- Exemple:   (Besoin Vert) (Sur stock Vert)
-- ou encore  (Besoin non caractérisé) (sur appro Rouge)
  function GetInfoAttribCaracterisation(
    onNeedOrAppro          varchar
  ,   -- NEED ou SUPPLY
    PrmFAL_NETWORK_LINK_ID FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID%type
  , CaracterizationNumber  integer
  )
    return varchar
  is
    aFAL_NETWORK_SUPPLY_ID FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type;
    aSTM_STOCK_POSITION_ID STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type;
    aFAL_NETWORK_NEED_ID   FAl_NETWORk_NEED.FAL_NETWORk_NEED_ID%type;
    aSTM_LOCATION_ID       STM_LOCATIOn.STM_LOCATION_ID%type;
    aFAN_CHAR_VALUE1       FAL_NETWORK_NEED.FAN_CHAR_VALUE1%type;
    aFAN_CHAR_VALUE2       FAL_NETWORK_NEED.FAN_CHAR_VALUE2%type;
    aFAN_CHAR_VALUE3       FAL_NETWORK_NEED.FAN_CHAR_VALUE3%type;
    aFAN_CHAR_VALUE4       FAL_NETWORK_NEED.FAN_CHAR_VALUE4%type;
    aFAN_CHAR_VALUE5       FAL_NETWORK_NEED.FAN_CHAR_VALUE5%type;
    CaractValue            varchar2(4000);
    Resultat               varchar2(4000);
    buff1                  varchar2(4000);
    buff2                  varchar2(4000);
    buff3                  varchar2(4000);
    buff4                  varchar2(4000);
    buff5                  varchar2(4000);
    /* idée originale
    TEXTsurAppro         VARCHAR2(4000) := 'sur appro ->';
    TEXTbesoin2Point     VARCHAR2(4000) := 'Besoin:';
    TEXTappro2Point      VARCHAR2(4000) := 'Appro:';
    TEXTsurBesoin        VARCHAR2(4000) := 'sur Besoin->';
    TEXTsurStock         VARCHAR2(4000) := 'sur Stock->';
    TEXTnonCaracterise   VARCHAR2(4000) := 'non caractérisé';
    TEXTnonCaracterisee  VARCHAR2(4000) := 'non caractérisée';
    */
    TEXTsurAppro           varchar2(4000)                                  := ' <-->';
    TEXTbesoin2Point       varchar2(4000)                                  := '';
    TEXTappro2Point        varchar2(4000)                                  := '';
    TEXTsurBesoin          varchar2(4000)                                  := ' <-->';
    TEXTsurStock           varchar2(4000)                                  := ' <-->';
    TEXTnonCaracterise     varchar2(4000)                                  := '      ';
    TEXTnonCaracterisee    varchar2(4000)                                  := '      ';
  begin
    Resultat  := '';

    -- Récupérer les infos de l'attribution
    select FAL_NETWORK_NEED_ID
         , Fal_NETWORK_SUPPLY_ID
         , STM_STOCK_POSITION_ID
         , STM_LOCATION_ID
      into aFAL_NETWORK_NEED_ID
         , aFAL_NETWORK_SUPPLY_ID
         , aSTM_STOCK_POSITION_ID
         , aSTM_LOCATION_ID
      from fal_network_link
     where FAL_NETWORK_LINK_ID = PrmFAL_NETWORK_LINK_ID;

    -- Récupérer les infos des valeurs de caractérisations du besoin
    if OnNeedOrAppro = 'NEED' then
      select FAN_CHAR_VALUE1
           , FAN_CHAR_VALUE2
           , FAN_CHAR_VALUE3
           , FAN_CHAR_VALUE4
           , FAN_CHAR_VALUE5
        into aFAN_CHAR_VALUE1
           , aFAN_CHAR_VALUE2
           , aFAN_CHAR_VALUE3
           , aFAN_CHAR_VALUE4
           , aFAN_CHAR_VALUE5
        from fal_network_Need
       where FAL_NETWORK_NEED_ID = aFAL_NETWORK_NEED_ID;
    end if;

    if OnNeedOrAppro = 'SUPPLY' then
      -- Récupérer les infos des valeurs de caractérisations de l'appro
      select FAN_CHAR_VALUE1
           , FAN_CHAR_VALUE2
           , FAN_CHAR_VALUE3
           , FAN_CHAR_VALUE4
           , FAN_CHAR_VALUE5
        into aFAN_CHAR_VALUE1
           , aFAN_CHAR_VALUE2
           , aFAN_CHAR_VALUE3
           , aFAN_CHAR_VALUE4
           , aFAN_CHAR_VALUE5
        from fal_network_Supply
       where FAL_NETWORK_SUPPLY_ID = aFAL_NETWORK_SUPPLY_ID;
    end if;

    if CaracterizationNumber = 1 then
      CaractValue  := nvl(aFAN_CHAR_VALUE1, TEXTnonCaracterise);

      if OnNeedOrAppro = 'NEED' then
        BUFF1     := '(' || TEXTBesoin2Point || CaractValue || ')';

        if aSTM_STOCK_POSITION_ID is null then
          BUFF2  := TEXTSurAppro;

          select ' (' || nvl(FAN_CHAR_VALUE1, TEXTnonCaracterisee) || ')'
            into BUFF3
            from FAl_NETWORK_SUPPLY Appro
           where Appro.FAl_NETWORK_SUPPLY_ID = aFAl_NETWORK_SUPPLY_ID;
        end if;

        if aFAL_NETWoRK_SUPPLY_ID is null then
          BUFF4  := TEXTSurStock || ' ';

          select ' (' || nvl(SPO_CHARACTERIZATION_VALUE_1, TEXTnonCaracterisee) || ')'
            into BUFF5
            from STM_STOCK_POSITION stock
           where Stock.STM_STOCK_POSITION_ID = aSTM_STOCK_POSITION_ID;
        end if;

        RESULTAT  := BUFF1 || BUFF2 || BUFF3 || BUFF4 || BUFF5;
      else
        BUFF1     := '(' || TEXTAppro2Point || CaractValue || ')';

        if aSTM_LOCATION_ID is null then
          BUFF2  := TEXTSurBesoin;

          select ' (' || nvl(FAN_CHAR_VALUE1, TEXTnonCaracterise) || ')'
            into BUFF3
            from FAl_NETWORK_NEED Need
           where Need.FAl_NETWORK_NEED_ID = aFAl_NETWORK_NEED_ID;
        end if;

        if aFAL_NETWoRK_NEED_ID is null then
          BUFF4  := TEXTSurStock || ' ';

          select ' (' || LOC_DESCRIPTION || ')'
            into BUFF5
            from STM_LOCATION LOC
           where LOC.STM_LOCATION_ID = aSTM_LOCATION_ID;
        end if;

        RESULTAT  := BUFF1 || BUFF2 || BUFF3 || BUFF4 || BUFF5;
      end if;
    end if;

    if CaracterizationNumber = 2 then
      CaractValue  := nvl(aFAN_CHAR_VALUE2, TEXTnonCaracterise);

      if OnNeedOrAppro = 'NEED' then
        BUFF1     := '(' || TEXTBesoin2Point || CaractValue || ')';

        if aSTM_STOCK_POSITION_ID is null then
          BUFF2  := TEXTSurAppro;

          select ' (' || nvl(FAN_CHAR_VALUE2, TEXTnonCaracterisee) || ')'
            into BUFF3
            from FAl_NETWORK_SUPPLY Appro
           where Appro.FAl_NETWORK_SUPPLY_ID = aFAl_NETWORK_SUPPLY_ID;
        end if;

        if aFAL_NETWoRK_SUPPLY_ID is null then
          BUFF4  := TEXTSurStock || ' ';

          select ' (' || nvl(SPO_CHARACTERIZATION_VALUE_2, TEXTnonCaracterisee) || ')'
            into BUFF5
            from STM_STOCK_POSITION stock
           where Stock.STM_STOCK_POSITION_ID = aSTM_STOCK_POSITION_ID;
        end if;

        RESULTAT  := BUFF1 || BUFF2 || BUFF3 || BUFF4 || BUFF5;
      else
        BUFF1     := '(' || TEXTAppro2Point || CaractValue || ')';

        if aSTM_LOCATION_ID is null then
          BUFF2  := TEXTSurBesoin;

          select ' (' || nvl(FAN_CHAR_VALUE2, TEXTnonCaracterise) || ')'
            into BUFF3
            from FAl_NETWORK_NEED Need
           where Need.FAl_NETWORK_NEED_ID = aFAl_NETWORK_NEED_ID;
        end if;

        if aFAL_NETWoRK_NEED_ID is null then
          BUFF4  := TEXTSurStock || ' ';

          select ' (' || LOC_DESCRIPTION || ')'
            into BUFF5
            from STM_LOCATION LOC
           where LOC.STM_LOCATION_ID = aSTM_LOCATION_ID;
        end if;

        RESULTAT  := BUFF1 || BUFF2 || BUFF3 || BUFF4 || BUFF5;
      end if;
    end if;

    if CaracterizationNumber = 3 then
      CaractValue  := nvl(aFAN_CHAR_VALUE3, TEXTnonCaracterise);

      if OnNeedOrAppro = 'NEED' then
        BUFF1     := '(' || TEXTBesoin2Point || CaractValue || ')';

        if aSTM_STOCK_POSITION_ID is null then
          BUFF2  := TEXTSurAppro;

          select ' (' || nvl(FAN_CHAR_VALUE3, TEXTnonCaracterisee) || ')'
            into BUFF3
            from FAl_NETWORK_SUPPLY Appro
           where Appro.FAl_NETWORK_SUPPLY_ID = aFAl_NETWORK_SUPPLY_ID;
        end if;

        if aFAL_NETWoRK_SUPPLY_ID is null then
          BUFF4  := TEXTSurStock || ' ';

          select ' (' || nvl(SPO_CHARACTERIZATION_VALUE_3, TEXTnonCaracterisee) || ')'
            into BUFF5
            from STM_STOCK_POSITION stock
           where Stock.STM_STOCK_POSITION_ID = aSTM_STOCK_POSITION_ID;
        end if;

        RESULTAT  := BUFF1 || BUFF2 || BUFF3 || BUFF4 || BUFF5;
      else
        BUFF1     := '(' || TEXTAppro2Point || CaractValue || ')';

        if aSTM_LOCATION_ID is null then
          BUFF2  := TEXTSurBesoin;

          select ' (' || nvl(FAN_CHAR_VALUE3, TEXTnonCaracterise) || ')'
            into BUFF3
            from FAl_NETWORK_NEED Need
           where Need.FAl_NETWORK_NEED_ID = aFAl_NETWORK_NEED_ID;
        end if;

        if aFAL_NETWoRK_NEED_ID is null then
          BUFF4  := TEXTSurStock || ' ';

          select ' (' || LOC_DESCRIPTION || ')'
            into BUFF5
            from STM_LOCATION LOC
           where LOC.STM_LOCATION_ID = aSTM_LOCATION_ID;
        end if;

        RESULTAT  := BUFF1 || BUFF2 || BUFF3 || BUFF4 || BUFF5;
      end if;
    end if;

    if CaracterizationNumber = 4 then
      CaractValue  := nvl(aFAN_CHAR_VALUE4, TEXTnonCaracterise);

      if OnNeedOrAppro = 'NEED' then
        BUFF1     := '(' || TEXTBesoin2Point || CaractValue || ')';

        if aSTM_STOCK_POSITION_ID is null then
          BUFF2  := TEXTSurAppro;

          select ' (' || nvl(FAN_CHAR_VALUE4, TEXTnonCaracterisee) || ')'
            into BUFF3
            from FAl_NETWORK_SUPPLY Appro
           where Appro.FAl_NETWORK_SUPPLY_ID = aFAl_NETWORK_SUPPLY_ID;
        end if;

        if aFAL_NETWoRK_SUPPLY_ID is null then
          BUFF4  := TEXTSurStock || ' ';

          select ' (' || nvl(SPO_CHARACTERIZATION_VALUE_4, TEXTnonCaracterisee) || ')'
            into BUFF5
            from STM_STOCK_POSITION stock
           where Stock.STM_STOCK_POSITION_ID = aSTM_STOCK_POSITION_ID;
        end if;

        RESULTAT  := BUFF1 || BUFF2 || BUFF3 || BUFF4 || BUFF5;
      else
        BUFF1     := '(' || TEXTAppro2Point || CaractValue || ')';

        if aSTM_LOCATION_ID is null then
          BUFF2  := TEXTSurBesoin;

          select ' (' || nvl(FAN_CHAR_VALUE4, TEXTnonCaracterise) || ')'
            into BUFF3
            from FAl_NETWORK_NEED Need
           where Need.FAl_NETWORK_NEED_ID = aFAl_NETWORK_NEED_ID;
        end if;

        if aFAL_NETWoRK_NEED_ID is null then
          BUFF4  := TEXTSurStock || ' ';

          select ' (' || LOC_DESCRIPTION || ')'
            into BUFF5
            from STM_LOCATION LOC
           where LOC.STM_LOCATION_ID = aSTM_LOCATION_ID;
        end if;

        RESULTAT  := BUFF1 || BUFF2 || BUFF3 || BUFF4 || BUFF5;
      end if;
    end if;

    if CaracterizationNumber = 5 then
      CaractValue  := nvl(aFAN_CHAR_VALUE5, TEXTnonCaracterise);

      if OnNeedOrAppro = 'NEED' then
        BUFF1     := '(' || TEXTBesoin2Point || CaractValue || ')';

        if aSTM_STOCK_POSITION_ID is null then
          BUFF2  := TEXTSurAppro;

          select ' (' || nvl(FAN_CHAR_VALUE5, TEXTnonCaracterisee) || ')'
            into BUFF3
            from FAl_NETWORK_SUPPLY Appro
           where Appro.FAl_NETWORK_SUPPLY_ID = aFAl_NETWORK_SUPPLY_ID;
        end if;

        if aFAL_NETWoRK_SUPPLY_ID is null then
          BUFF4  := TEXTSurStock || ' ';

          select ' (' || nvl(SPO_CHARACTERIZATION_VALUE_5, TEXTnonCaracterisee) || ')'
            into BUFF5
            from STM_STOCK_POSITION stock
           where Stock.STM_STOCK_POSITION_ID = aSTM_STOCK_POSITION_ID;
        end if;

        RESULTAT  := BUFF1 || BUFF2 || BUFF3 || BUFF4 || BUFF5;
      else
        BUFF1     := '(' || TEXTAppro2Point || CaractValue || ')';

        if aSTM_LOCATION_ID is null then
          BUFF2  := TEXTSurBesoin;

          select ' (' || nvl(FAN_CHAR_VALUE5, TEXTnonCaracterise) || ')'
            into BUFF3
            from FAl_NETWORK_NEED Need
           where Need.FAl_NETWORK_NEED_ID = aFAl_NETWORK_NEED_ID;
        end if;

        if aFAL_NETWoRK_NEED_ID is null then
          BUFF4  := TEXTSurStock || ' ';

          select ' (' || LOC_DESCRIPTION || ')'
            into BUFF5
            from STM_LOCATION LOC
           where LOC.STM_LOCATION_ID = aSTM_LOCATION_ID;
        end if;

        RESULTAT  := BUFF1 || BUFF2 || BUFF3 || BUFF4 || BUFF5;
      end if;
    end if;

    return resultat;
  end;

-- Retourne: Reference Principale, Reference secondaire, Description Courte, Libre et longue d'un bien
  procedure GetMajorSecShortFreeLong(
    PrmGCO_GOOD_ID in     GCO_GOOD.GCO_GOOD_ID%type
  , RefPrinc       out    varchar
  , RefSecond      out    varchar
  , DescrShort     out    varchar
  , DescrFree      out    varchar
  , DescrLong      out    varchar
  )
  is
    cursor crGoodDescr(cGoodID number, cLangID number, cTypeDescr varchar2)
    is
      select GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_SECONDARY_REFERENCE
           , nvl(nvl(DES_1.DES_SHORT_DESCRIPTION, DES_2.DES_SHORT_DESCRIPTION), nvl(DES_3.DES_SHORT_DESCRIPTION, DES_4.DES_SHORT_DESCRIPTION) )
                                                                                                                                          DES_SHORT_DESCRIPTION
           , nvl(nvl(DES_1.DES_LONG_DESCRIPTION, DES_2.DES_LONG_DESCRIPTION), nvl(DES_3.DES_LONG_DESCRIPTION, DES_4.DES_LONG_DESCRIPTION) )
                                                                                                                                           DES_LONG_DESCRIPTION
           , nvl(nvl(DES_1.DES_FREE_DESCRIPTION, DES_2.DES_FREE_DESCRIPTION), nvl(DES_3.DES_FREE_DESCRIPTION, DES_4.DES_FREE_DESCRIPTION) )
                                                                                                                                           DES_FREE_DESCRIPTION
        from GCO_GOOD GOO
           , GCO_DESCRIPTION DES_1
           , GCO_DESCRIPTION DES_2
           , GCO_DESCRIPTION DES_3
           , GCO_DESCRIPTION DES_4
       where GOO.GCO_GOOD_ID = cGoodID
         and DES_1.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and DES_1.C_DESCRIPTION_TYPE(+) = cTypeDescr
         and DES_1.PC_LANG_ID(+) = cLangID
         and DES_2.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and DES_2.C_DESCRIPTION_TYPE(+) = '01'
         and DES_2.PC_LANG_ID(+) = cLangID
         and DES_3.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and DES_3.C_DESCRIPTION_TYPE(+) = cTypeDescr
         and DES_3.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetCompLangId
         and DES_4.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and DES_4.C_DESCRIPTION_TYPE(+) = '01'
         and DES_4.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetCompLangId;

    tplGoodDescr crGoodDescr%rowtype;
  begin
    tplGoodDescr  := null;

    if PrmGCO_GOOD_ID is not null then
      open crGoodDescr(PrmGCO_GOOD_ID, PCS.PC_I_LIB_SESSION.getuserlangid, '05'   -- fabrication
                                                                              );

      fetch crGoodDescr
       into tplGoodDescr;

      RefPrinc    := tplGoodDescr.GOO_MAJOR_REFERENCE;
      RefSecond   := tplGoodDescr.GOO_SECONDARY_REFERENCE;
      DescrShort  := tplGoodDescr.DES_SHORT_DESCRIPTION;
      DescrLong   := tplGoodDescr.DES_LONG_DESCRIPTION;
      DescrFree   := tplGoodDescr.DES_FREE_DESCRIPTION;

      close crGoodDescr;
    end if;
  end;

-- Cette fonction élimine tous les 0 après un séparateur tant
-- que 0 ou un autre séparateur n' a pas été trouvé
--
-- Limite d'usage:               cette fonction retrournera des résultats erronés
--                     si le spérateur n'est pas '-' ou '.' ou pire encore des
--                     séparateurs à caractère multiple.
--
-- Historique de cette fonction: Elle sert à comparer facilement des
--                               des références complètes de lots dans diverses tables
--                               alors que différenres valeurs de config pour ce formatage
--                               a été utilisés tout au long de la durée de vie de l'application
--                 C'est le cas avec le champ SMO_WORDING qui lui n'est jamais mis à jour
--                               par la fonction ModifyAllLot_Refcompl qui est généralement utilisée
--                 lors d'un changement des valeurs de config de formatage
-- Exemples d'utilisation correctes:
--    select zc ('fg-00101-102.3','-') from dual
--    -101-102-3
--    select zc ('PF-A100.00103.003','-') from dual
--    -100-103-3
-- Exemples d'utilisation INCORRECTES:
--    select zc ('PF-A100.00103.003','-A-') from dual;
--    10000103003 -- !!! Inexploitable !!!
-- restriction: le séparateur ne peut être qu'un seul caractère
--              0 ne peut être utilisé comme sépareteur
-- Exemple d'utilisation:
-- Lorsque par exemple nous devons chercher les fal_factory_in qui n'aurait pas donné lieu
-- à des mouvement. En effet le champ SMO_WORDING de la table STM_STOCK_MOVEMENT n'est pas
-- mis à jour lors des chagements issus de modifications des configs jouant sur les séparateurs
-- Programme Ordre Lot ou sur le nombre de Digit des numéros de programmes, ordres ou lot.
  function ZC(RefBuff varchar, separateur varchar)
    return varchar
  is
    I     number;
    Tiret boolean;
    Res   varchar(2000);
    Buff  varchar(2000);
  begin
    Buff   := replace(refbuff, '.', '-');
    I      := 1;
    Tiret  := true;
    Res    := '';

    if buff is not null then
      loop
        if substr(BUff, I, 1) = separateur then
          Tiret  := true;
        end if;

        if not tiret then
          if substr(BUff, I, 1) in('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', separateur) then
            res  := Res || substr(BUff, I, 1);
          end if;
        end if;

        if Tiret then
          if substr(BUff, I, 1) <> '0' then
            if substr(BUff, I, 1) in('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', separateur) then
              res  := Res || substr(BUff, I, 1);
            end if;

            if substr(BUff, I, 1) <> separateur then
              Tiret  := false;
            end if;
          end if;
        end if;

        I  := I + 1;
        exit when I > length(Buff);
      end loop;
    end if;

    return res;
  end;

-- Retourne la valeur de la caractérisation de type lot si celle-ci figure
-- dans la liste des valeurs en paramètres
  function ValueLotOfCaractLot(
    Car1ID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , Val1ID FAL_NETWORK_NEED.FAN_CHAR_VALUE1%type
  , Car2ID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , Val2ID FAL_NETWORK_NEED.FAN_CHAR_VALUE1%type
  , Car3ID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , Val3ID FAL_NETWORK_NEED.FAN_CHAR_VALUE1%type
  , Car4ID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , Val4ID FAL_NETWORK_NEED.FAN_CHAR_VALUE1%type
  , Car5ID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , Val5ID FAL_NETWORK_NEED.FAN_CHAR_VALUE1%type
  )
    return varchar
  is
    Resultat FAL_NETWORK_NEED.FAN_CHAR_VALUE1%type;
  begin
    Resultat  := null;

    if GCO_FUNCTIONS.GetCharacType(Car1ID) = '4' then
      Resultat  := Val1ID;
    end if;

    if GCO_FUNCTIONS.GetCharacType(Car2ID) = '4' then
      Resultat  := Val2ID;
    end if;

    if GCO_FUNCTIONS.GetCharacType(Car3ID) = '4' then
      Resultat  := Val3ID;
    end if;

    if GCO_FUNCTIONS.GetCharacType(Car4ID) = '4' then
      Resultat  := Val4ID;
    end if;

    if GCO_FUNCTIONS.GetCharacType(Car5ID) = '4' then
      Resultat  := Val5ID;
    end if;

    return Resultat;
  end;

-- Retourne le GCO_GOOD_ID du lot
  function GetGCO_GOOD_ID(aLotID FAL_LOT.FAL_LOT_ID%type)
    return GCO_GOOD.GCO_GOOD_ID%type
  is
    result GCO_GOOD.GCO_GOOD_ID%type;
  begin
    select GCO_GOOD_ID
      into result
      from FAL_LOT
     where FAL_LOT_ID = aLotID;

    return result;
  exception
    when no_data_found then
      return null;
  end;

-- Retourne la valeur aValue seulement si Ref est <> de 0 et de NULL
  function OnNoZeroOrNullSetWithValue(ref number, aValue varchar)
    return varchar
  is
  begin
    if nvl(ref, 0) <> 0 then
      return aValue;
    else
      return null;
    end if;
  end;

  -- Calcul de la quantité de rebut/déchets
  function CalcTotalTrashQuantity(
    aAskedQty          in FAL_LOT.LOT_ASKED_QTY%type default null
  , aTotalQty          in FAL_LOT.LOT_TOTAL_QTY%type default null
  , aTrashPercent      in PPS_NOM_BOND.COM_PERCENT_WASTE%type
  , aTrashFixedQty     in PPS_NOM_BOND.COM_FIXED_QUANTITY_WASTE%type
  , aTrashReferenceQty in PPS_NOM_BOND.COM_QTY_REFERENCE_LOSS%type
  )
    return FAL_LOT.LOT_REJECT_PLAN_QTY%type
  is
    vTrashQtyFactor     FAL_LOT.LOT_TOTAL_QTY%type;
    vTotalTrashPercent  FAL_LOT.LOT_TOTAL_QTY%type;
    vTotalTrashFixedQty FAL_LOT.LOT_TOTAL_QTY%type;
  begin
    -- Si on nous fourni la quantité demandée sans rebut
    if nvl(aAskedQty, 0) <> 0 then
      -- Calcul de la quantités de rebut selon pourcentage
      vTotalTrashPercent   := aAskedQty *( (1 /(1 - nvl(aTrashPercent, 0) / 100) ) - 1);

      if nvl(aTrashReferenceQty, 0) = 0 then
        -- Quantité de rebut fixe (indépendemment de la quantité du lot)
        vTrashQtyFactor  := 1;
      else
        -- Calcul du facteur de la quantité de rebut fixe en fonction de la
        -- quantité du lot, arrondi à l'entier supérieur
        vTrashQtyFactor  := RoundSuccInt( (aAskedQty + vTotalTrashPercent) / aTrashReferenceQty);
      end if;

      -- Calcul de la quantités de rebut selon quantité fixe
      vTotalTrashFixedQty  := vTrashQtyFactor * nvl(aTrashFixedQty, 0);
    --
    -- Ou si on nous fourni la quantité totale avec rebut
    elsif nvl(aTotalQty, 0) <> 0 then
      if nvl(aTrashReferenceQty, 0) = 0 then
        -- Quantité de rebut fixe (indépendemment de la quantité du lot)
        vTrashQtyFactor  := 1;
      else
        -- Calcul du facteur de la quantité de rebut fixe en fonction de la
        -- quantité du lot, arrondi à l'entier supérieur
        vTrashQtyFactor  := RoundSuccInt(aTotalQty /(aTrashReferenceQty + aTrashFixedQty) );
      end if;

      -- Calcul de la quantités de rebut selon quantité fixe
      vTotalTrashFixedQty  := vTrashQtyFactor * nvl(aTrashFixedQty, 0);
      -- Calcul de la quantités de rebut selon pourcentage
      vTotalTrashPercent   := (aTotalQty - vTotalTrashFixedQty) *(nvl(aTrashPercent, 0) / 100);
    --
    -- Ou sinon : 0
    else
      if     nvl(aTrashFixedQty, 0) > 0
         and nvl(aTrashReferenceQty, 0) = 0 then
        vTotalTrashFixedQty  := aTrashFixedQty;
      else
        vTotalTrashFixedQty  := 0;
      end if;

      vTotalTrashPercent  := 0;
    end if;

    -- Retourne la quantité totale de rebut (pourcentage + quantité fixe)
    return vTotalTrashPercent + vTotalTrashFixedQty;
  end CalcTotalTrashQuantity;

  -- Renvoie la marge pour péremption du produit
  function getCHA_LAPSING_MARGE(PrmGCO_GOOD_ID PCS_PK_ID)
    return GCO_CHARACTERIZATION.CHA_LAPSING_MARGE%type
  is
    ResCHA_LAPSING_MARGE GCO_CHARACTERIZATION.CHA_LAPSING_MARGE%type;
  begin
    select CHA_LAPSING_MARGE
      into ResCHA_LAPSING_MARGE
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = PrmGCO_GOOD_ID
       -- Il faut bien entendu ne rechercher cette valeur que pour les produits
       -- Gérés avec des caractérisations de type chrono et Péremption
       and (C_CHARACT_TYPE = 5)
       and (C_CHRONOLOGY_TYPE = 3);

    return ResCHA_LAPSING_MARGE;
  exception
    when no_data_found then
      return null;
  end getCHA_LAPSING_MARGE;

  -- Indique si le produit est lié à une caractérisation de type péremption
  function ProductHasPeremptionDate(PrmGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type)
    return integer
  is
    InUsed integer;
  begin
    select 1
      into InUsed
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = PrmGCO_GOOD_ID
       and C_CHARACT_TYPE = '5'
       and C_CHRONOLOGY_TYPE = '3';

    return 1;
  exception
    when no_data_found then
      return 0;
  end ProductHasPeremptionDate;

  --Renvoie le type d'une caractérization
  function GetCharactType(aGCO_CHARACTERIZATION_ID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
    return varchar2
  is
    BuffC_CHARACT_TYPE varchar2(10);
  begin
    select C_CHARACT_TYPE
      into BuffC_CHARACT_TYPE
      from GCO_CHARACTERIZATION
     where GCO_CHARACTERIZATION_ID = aGCO_CHARACTERIZATION_ID;

    return BuffC_CHARACT_TYPE;
  exception
    when no_data_found then
      return null;
  end GetCharactType;

  /**
  * @deprecated since ProConcept ERP 11.0. Will be removed in future version. Use GCO_LIB_CHARACTERIZATION.NbCharInStock(aGcoGoodId) > 0 instead.
  */
  function AtLeastOneCharactExists(aGcoGoodId fal_lot.gco_good_id%type)
    return boolean
  is
  begin
    return GCO_I_LIB_CHARACTERIZATION.NbCharInStock(aGcoGoodId) > 0;
  end;

  /* Function AtLeastOneDetailLotExists
  * Description
  *     Retourne vrai si le lot a au moins un détail lot
  *
  * @author CLE
  * @lastUpdate
  * @public
  * @param aFalLotId : id du lot
  * @return   :  Vrai si un détail lot trouvé
  */
  function AtLeastOneDetailLotExists(aFalLotId fal_lot.fal_lot_id%type)
    return boolean
  is
    cntDetail integer;
  begin
    select nvl(count(*), 0)
      into cntDetail
      from FAL_LOT_DETAIL
     where FAL_LOT_ID = aFalLotId;

    if (cntDetail > 0) then
      return true;
    else
      return false;
    end if;
  end;

  /**
  * procedure GetDefaultSupplier
  * Description : Fonction de recherche du supplier en cascade
  * @created ECA
  * @lastUpdate
  * @private
  */
  function GetDefaultSupplier
    return number
  is
    cursor Cur_Supplier_Partner
    is
      select   PAC_PERSON_ID
          from PAC_PERSON
             , PAC_SUPPLIER_PARTNER
         where PAC_PERSON_ID = PAC_SUPPLIER_PARTNER_ID
      order by PER_NAME;

    aPAC_SUPPLIER_PARTNER_ID number;
  begin
    select PER.PAC_PERSON_ID
      into aPAC_SUPPLIER_PARTNER_ID
      from PAC_PERSON PER
         , PAC_SUPPLIER_PARTNER SUP
     where PER.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
       and PER.PER_NAME = PCS.PC_CONFIG.GetConfig('FAL_DEFAULT_PURCHASE');

    return aPAC_SUPPLIER_PARTNER_ID;
  exception
    when no_data_found then
      begin
        open Cur_Supplier_Partner;

        fetch Cur_Supplier_Partner
         into aPAC_SUPPLIER_PARTNER_ID;

        close Cur_Supplier_Partner;

        return aPAC_SUPPLIER_PARTNER_ID;
      exception
        when others then
          return null;
      end;
  end;

  /**
  * procedure GetDefaultSubcontract
  * Description : Fonction de recherche du sous-traitant par défaut
  * @created CLE
  * @lastUpdate
  * @private
  */
  function GetDefaultSubcontract
    return number
  is
    aPAC_SUPPLIER_PARTNER_ID number;
  begin
    select PER.PAC_PERSON_ID
      into aPAC_SUPPLIER_PARTNER_ID
      from PAC_PERSON PER
         , PAC_SUPPLIER_PARTNER SUP
     where PER.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
       and PER.PER_NAME = PCS.PC_CONFIG.GetConfig('FAL_DEFAULT_SUBCONTRACT');

    return aPAC_SUPPLIER_PARTNER_ID;
  exception
    when no_data_found then
      raise_application_error(-20000, 'Error in the configuration value FAL_DEFAULT_SUBCONTRACT');
  end;

  /**
  * procedure GetDefaultStock
  * Description : Récupération du stock flagué stock par défaut.
  * @created CLE
  * @lastUpdate
  * @private
  */
  function GetDefaultStock
    return STM_STOCK.STM_STOCK_ID%type
  is
    aStmStockId STM_STOCK.STM_STOCK_ID%type;
  begin
    select max(STM_STOCK_ID)
      into aStmStockId
      from STM_STOCK
     where C_ACCESS_METHOD = 'DEFAULT';

    return aStmStockId;
  end;

  /**
  * procedure GetMinClassifLocationOfStock
  * Description : Récupération de l'emplacement de classification minimum du stock passé en paramètres
  * @created CLE
  * @lastUpdate
  * @private
  */
  function GetMinClassifLocationOfStock(aStmStockId STM_STOCK.STM_STOCK_ID%type)
    return STM_LOCATION.STM_LOCATION_ID%type
  is
    cursor crLocation
    is
      select   STM_LOCATION_ID
          from STM_LOCATION
         where STM_STOCK_ID = aStmStockId
      order by LOC_CLASSIFICATION;

    aStmLocationId STM_LOCATION.STM_LOCATION_ID%type;
  begin
    open crLocation;

    fetch crLocation
     into aStmLocationId;

    close crLocation;

    return aStmLocationId;
  end;

  /**
  * function GetPicLineByNeed
  * Description : Récupère la ligne de PIC d'un besoin. Null si non trouvé
  * @created CLE
  * @lastUpdate
  * @private
  */
  function GetPicLineByNeed(aFalNetworkNeedId number)
    return number
  is
    nFalPicLineId number;
  begin
    select FAL_PIC_LINE_ID
      into nFalPicLineId
      from FAL_NETWORK_NEED
     where FAL_NETWORK_NEED_ID = aFalNetworkNeedId;

    return nFalPicLineId;
  exception
    when no_data_found then
      return null;
  end;

  /**
  * function GetSubcontractStockId
  * Description : Récupère le stock du sous-traitant de l'OF
  * @created CLE
  * @lastUpdate
  */
  function GetSubcontractStockId(aFalLotId number)
    return number
  is
    nStockId number;
  begin
    select STM_STOCK_ID
      into nStockId
      from STM_STOCK
     where PAC_SUPPLIER_PARTNER_ID = (select PAC_SUPPLIER_PARTNER_ID
                                        from FAL_TASK_LINK
                                       where FAL_LOT_ID = aFalLotId);

    return nStockId;
  exception
    when others then
      return null;
  end;

  /**
  * function GetSubcontractLocationId
  * Description : Récupère l'emplacement de stock du sous-traitant de l'OF
  * @created CLE
  * @lastUpdate
  */
  function GetSubcontractLocationId(aFalLotId number)
    return number
  is
    nLocationID number;
  begin
    select STM_LOCATION_ID
      into nLocationID
      from (select   STM_LOCATION_ID
                from STM_LOCATION
               where STM_STOCK_ID = GetSubcontractStockId(aFalLotId)
            order by LOC_CLASSIFICATION)
     where rownum = 1;

    return nLocationID;
  exception
    when no_data_found then
      return null;
  end;

  /**
  * function RemoveCompanyOwner
  *   Description : Supprime la macro C_ITX ou [CO] de la requête SQL passée en paramètre
  * @created CLE
  * @lastUpdate
  * @return      La requête modifiée
  */
  function RemoveCompanyOwner(iSql in clob)
    return clob
  is
    lResult clob;
  begin
    lResult  := replace(upper(iSql), '[COMPANY_OWNER' || '].', '');
    lResult  := replace(upper(lResult), '[CO' || '].', '');
    return lResult;
  end RemoveCompanyOwner;

  /**
  * function GetProcurementDelay
  *   Description : Recherche du délai d'appro d'un fournisseur
  * @created CLE
  * @lastUpdate
  * @public
  * @param aSupplierId : id du fournisseur
  * @return      Délai d'appro
  */
  function GetProcurementDelay(aSupplierId number)
    return number
  is
    nCreSupplyDelay number;
  begin
    select nvl(CRE_SUPPLY_DELAY, 0)
      into nCreSupplyDelay
      from PAC_SUPPLIER_PARTNER
     where PAC_SUPPLIER_PARTNER_ID = aSupplierId;

    return nCreSupplyDelay;
  exception
    when no_data_found then
      return 0;
  end;

   /**
  * function getCharactFieldIndex
  * Description
  *   Recherche de l'Id et de l'emplacement du champ d'une caractérisation du produit
  * @author CLE
  * @return  Index de la caractérisation
  * @param   aGcoGoodId              Id du produit terminé
  * @param   aCharactType            Type de caractérisation à rechercher
  * @param   aGcoCharacterizationId  Valeur de retour, Id de la charactérisation trouvée
  */
  function getCharactFieldIndex(aGcoGoodId number, aCharactType varchar2, aGcoCharacterizationId in out number)
    return integer
  is
    cursor cur_GCO_CHARACTERIZATION
    is
      select   GCO_CHARACTERIZATION_ID
             , C_CHARACT_TYPE
          from GCO_CHARACTERIZATION
         where GCO_GOOD_ID = aGcoGoodId
           and CHA_STOCK_MANAGEMENT = 1
      order by GCO_CHARACTERIZATION_ID;

    FieldIdx integer;
  begin
    FieldIdx                := 1;
    aGcoCharacterizationId  := null;

    for curGCO_CHARACTERIZATION in cur_GCO_CHARACTERIZATION loop
      -- Si on est en type Chronologie
      if curGCO_CHARACTERIZATION.C_CHARACT_TYPE = aCharactType then
        aGcoCharacterizationId  := curGCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID;
        exit;
      else
        FieldIdx  := FieldIdx + 1;
      end if;
    end loop;

    if aGcoCharacterizationId is not null then
      return FieldIdx;
    else
      return null;
    end if;
  end;

  /**
  * function GetDayCapacity
  * Description
  *   Recherche de la capacité jour d'un atelier
  * @author CLE
  * @return  capacité jour de l'atelier
  * @param   aFalFactoryFloorId      Id de l'atelier
  */
  function GetDayCapacity(aFalFactoryFloorId number)
    return number
  is
    nDayCapacity number;
  begin
    select FAC_DAY_CAPACITY
      into nDayCapacity
      from FAL_FACTORY_FLOOR
     where FAL_FACTORY_FLOOR_ID = aFalFactoryFloorId;

    return nDayCapacity;
  exception
    when no_data_found then
      return 0;
  end;

  /**
  * function GetConfigDefaultService
  * Description
  *   Recherche du service (GCO_GOOD_ID) en fonction de la configuration FAL_ORT_DEFAULT_SERVICE
  * @author CLE
  * @return  Id du service
  */
  function GetConfigDefaultService
    return number
  is
    nGoodId number;
  begin
    if PCS.PC_Config.GetConfig('FAL_ORT_DEFAULT_SERVICE') is null then
      Raise_Application_Error(-20000, 'You have to define the configuration FAL_ORT_DEFAULT_SERVICE');
    end if;

    select GCO_GOOD_ID
      into nGoodId
      from GCO_GOOD
     where GOO_MAJOR_REFERENCE = PCS.PC_Config.GetConfig('FAL_ORT_DEFAULT_SERVICE');

    return nGoodId;
  end;

  /**
  * function CheckConfig
  * Description
  *      fonction de contrôle de configuration
  */
  function CheckConfig(ivConfigName in varchar2, ivConfigValue in varchar2)
    return number
  is
    lvFlag           varchar2(100);
    lvCostPriceDescr varchar2(100);
    lvOldPriceStatus varchar2(100);
    lvNewPriceStatus varchar2(100);
    lnCount          integer;
  begin
    if upper(ivConfigName) = 'FAL_AUTO_SAVE_POSTCALC_RECEPT' then
      lvFlag            := ExtractLine(ivConfigValue, 1, ';');
      lvCostPriceDescr  := ExtractLine(ivConfigValue, 2, ';');
      lvOldPriceStatus  := ExtractLine(ivConfigValue, 3, ';');
      lvNewPriceStatus  := ExtractLine(ivConfigValue, 4, ';');

      if lvFlag not in('0', '1') then
        return 0;
      end if;

      if CheckExistInTable(lvCostPriceDescr, 'DIC_FIXED_COSTPRICE_DESCR', 'DIC_FIXED_COSTPRICE_DESCR_ID') <> '1' then
        return 0;
      end if;

      if lvFlag = '1' then
        select count(1)
          into lnCount
          from PCS.PC_GCLST
             , PCS.PC_GCGRP
         where PC_GCGRP.GCGNAME = 'C_COSTPRICE_STATUS'
           and PCS.PC_GCLST.GCLCODE = lvOldPriceStatus
           and PCS.PC_GCLST.PC_GCGRP_ID = PCS.PC_GCGRP.PC_GCGRP_ID;

        if lnCount = 0 then
          return 0;
        end if;
      end if;

      select count(1)
        into lnCount
        from PCS.PC_GCLST
           , PCS.PC_GCGRP
       where PC_GCGRP.GCGNAME = 'C_COSTPRICE_STATUS'
         and PCS.PC_GCLST.GCLCODE = lvNewPriceStatus
         and PCS.PC_GCLST.PC_GCGRP_ID = PCS.PC_GCGRP.PC_GCGRP_ID;

      if lnCount = 0 then
        return 0;
      else
        return 1;
      end if;
    end if;

    return 0;
  end;
end;
