--------------------------------------------------------
--  DDL for Package Body GAL_QI
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_QI" 
is
  /**
  * Description
  *   Cette procédure peut être appelée après validation d'un document COMMANDE CLIENT
  *   Elle maintient la cohérence entre les données des commandes clients et les données commerciales des affaires (client, prix de vente...)
  */
  procedure UPD_GAL_PROJECT_SALES_DATA(iDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    lPrjId           gal_project.gal_project_id%type;
    lBudId           gal_budget.gal_budget_id%type;
    lSalePrice       number;
    lDmtNumber       DOC_DOCUMENT.DMT_NUMBER%type;
    lPacThirdId      DOC_DOCUMENT.PAC_THIRD_ID%type;
    lDmtDateDocument DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    lPdeFinalDelay   DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type;
  begin
    for cur in (select GAL_PROJECT_ID
                  from DOC_POSITION POS
                     , GAL_PROJECT PRJ
                 where POS.DOC_DOCUMENT_ID = iDocumentId
                   and PRJ.doc_record_id = POS.doc_record_id) loop
      lPrjId  := cur.GAL_PROJECT_ID;
      GAL_PRJ_FUNCTIONS.Get_Balance_Order_information(lPrjId
                                                    , lBudId
                                                    , lSalePrice
                                                    , lDmtNumber
                                                    , lPacThirdId
                                                    , lDmtDateDocument
                                                    , lPdeFinalDelay
                                                     );

      update GAL_PROJECT
         set PAC_CUSTOM_PARTNER_ID = lPacThirdId
           , PRJ_CUSTOMER_ORDER_REF = lDmtNumber
           , PRJ_CUSTOMER_ORDER_DATE = lDmtDateDocument
           , PRJ_CUSTOMER_DELIVERY_DATE = lPdeFinalDelay
           , PRJ_SALE_PRICE = lSalePrice
       where gal_project_id = lPrjId;
    end loop;
  end UPD_GAL_PROJECT_SALES_DATA;

  /**
  * Description
  *   Contrôle que le stock logique est celui défini pour les biens SANS GESTION DE STOCK
  */
  function CTRL_STK1_IS_VIRTUEL(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lStoVirtuel stm_stock.c_access_method%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select min(C_ACCESS_METHOD)
        into lStoVirtuel
        from doc_position POS
           , stm_stock STK
       where POS.doc_position_id = iPositionId
         and STK.stm_stock_id = POS.stm_stock_id;

      if nvl(lStoVirtuel, ' ') <> 'DEFAULT' then
        return PCS.PC_FUNCTIONS.TranslateWord
                                     ('Le stock logique doit être celui utilisé pour les biens SANS GESTION DE STOCK') ||
               '[ABORT]';
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_STK1_IS_VIRTUEL;

  /**
  * Description
  *   Contrôle que le dossier, s'il est renseigné, est en phase avec le stock logique
  *   Règle 1 : on ne peut pas imputer sur un dossier de type affaire AVEC un stock logique non affaire (sauf stock logique VIRTUEL)
  *   Règle 2 : on ne peut pas imputer sur un dossier non affaire AVEC un stock logique affaire
  */
  function CTRL_COHERENCE_REC_AND_STO(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lRcoType doc_record.c_rco_type%type;
    lTypePos doc_position.c_gauge_type_pos%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.GET_RCO_TYPE_FROM_DOC_POS_ID(iPositionId)
           , GAL_QI.GET_TYPE_POS(iPositionId)
        into lRcoType
           , lTypePos
        from dual;

      if     not(lTypePos = '4')   -- La position n'est pas de type TEXTE
         and GAL_QI.CTRL_STK1_IS_AFF(iPositionId) is not null   -- Le stock n'est pas un stock AFFAIRE
         and GAL_QI.CTRL_STK1_IS_VIRTUEL(iPositionId) is not null   -- Le stock n'est pas le stock VIRTUEL (pour articles sans gestion de stock)
         and (   nvl(lRcoType, ' ') = '01'
              or nvl(lRcoType, ' ') = '02'
              or nvl(lRcoType, ' ') = '03'
              or nvl(lRcoType, ' ') = '04'
              or nvl(lRcoType, ' ') = '05'
             )   -- Le dossier est de type AFFAIRE
              then
        return PCS.PC_FUNCTIONS.TranslateWord('Incohérence entre le type de dossier et le stock logique') || '[ABORT]';
      else
        if     not(lTypePos = '4')   -- La position n'est pas de type TEXTE
           and GAL_QI.CTRL_STK1_IS_AFF(iPositionId) is null   -- Le stock est un stock AFFAIRE
           and not(   nvl(lRcoType, ' ') = '01'
                   or nvl(lRcoType, ' ') = '02'
                   or nvl(lRcoType, ' ') = '03'
                   or nvl(lRcoType, ' ') = '04'
                   or nvl(lRcoType, ' ') = '05'
                  )   -- Le dossier n'est pas de type AFFAIRE
                   then
          return PCS.PC_FUNCTIONS.TranslateWord('Incohérence entre le type de dossier et le stock logique')
                 || '[ABORT]';
        else
          return null;
        end if;
      end if;
    else
      return null;
    end if;
  end CTRL_COHERENCE_REC_AND_STO;

  /**
  * Description
  *   Contrôle que le dossier, s'il est renseigné, n'est pas un dossier (ou sous-dossier) d'affaire
  *   Indispensable sur les documents "purement stock" (hors contexte affaire) suivants :
  *   "STK-STV-Stock Transfer Voucher" + "STK-SEV-Stock Entry Voucher" + "STK-SOV-Stock Output Voucher"
  *   sinon cette transaction chargerait le prix de revient de l'affaire !!!
  */
  function CTRL_REC_IS_OUT_AFF(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lRcoType doc_record.c_rco_type%type;
    lTypePos doc_position.c_gauge_type_pos%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.GET_RCO_TYPE_FROM_DOC_POS_ID(iPositionId)
           , GAL_QI.GET_TYPE_POS(iPositionId)
        into lRcoType
           , lTypePos
        from dual;

      if     not(lTypePos = '4')   -- La position n'est pas de type TEXTE
         and (   nvl(lRcoType, ' ') = '01'
              or nvl(lRcoType, ' ') = '02'
              or nvl(lRcoType, ' ') = '03'
              or nvl(lRcoType, ' ') = '04'
              or nvl(lRcoType, ' ') = '05'
             ) then
        return PCS.PC_FUNCTIONS.TranslateWord('Dossier interdit, car appartenant à une affaire') || '[ABORT]';
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_REC_IS_OUT_AFF;

-- *********************************************************************************************************************
  function CTRL_REC_IS_NOT_NULL(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lRcoType doc_record.c_rco_type%type;
    lTypePos doc_position.c_gauge_type_pos%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.GET_RCO_TYPE_FROM_DOC_POS_ID(iPositionId)
           , GAL_QI.GET_TYPE_POS(iPositionId)
        into lRcoType
           , lTypePos
        from dual;

      if     nvl(lRcoType, ' ') = ' '
         and not(lTypePos = '4') then
        return PCS.PC_FUNCTIONS.TranslateWord('Dossier obligatoire') || '[ABORT]';
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_REC_IS_NOT_NULL;

-- *********************************************************************************************************************
  function CTRL_REC_IS_NULL(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lRcoType doc_record.c_rco_type%type;
    lTypePos doc_position.c_gauge_type_pos%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.GET_RCO_TYPE_FROM_DOC_POS_ID(iPositionId)
           , GAL_QI.GET_TYPE_POS(iPositionId)
        into lRcoType
           , lTypePos
        from dual;

      if     nvl(lRcoType, ' ') <> ' '
         and not(lTypePos = '4') then
        return PCS.PC_FUNCTIONS.TranslateWord('Dossier interdit') || '[ABORT]';
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_REC_IS_NULL;

  /**
  * Description
  *   Contrôle que le stock logique (stock départ), saisi sur la position de document, est égal au stock transfert (stock arrivée)
  *   A utiliser au cas par cas...
  *   Exemple : je crée un gabarit de transfert d'emplacement de stock, mais l'utilisateur n'a pas le droit de changer de magasin...
  */
  function CTRL_STK1_IS_STK2(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lTypePos         doc_position.c_gauge_type_pos%type;
    lSto1Description stm_stock.sto_description%type;
    lSto2Description stm_stock.sto_description%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.GET_TYPE_POS(iPositionId)
        into lTypePos
        from dual;

      if not(lTypePos = '4') then
        select min(STK1.STO_DESCRIPTION)
             , min(STK2.STO_DESCRIPTION)
          into lSto1Description
             , lSto2Description
          from doc_position POS
             , stm_stock STK1
             , stm_stock STK2
         where POS.doc_position_id = iPositionId
           and STK1.stm_stock_id = POS.stm_stock_id
           and STK2.stm_stock_id = POS.stm_stm_stock_id;

        if nvl(lSto1Description, 'Vide') <> nvl(lSto2Description, 'Vide') then
          return PCS.PC_FUNCTIONS.TranslateWord('Le stock logique doit être égal au stock transfert') || '[ABORT]';
        else
          return null;
        end if;
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_STK1_IS_STK2;

  /**
  * Description
  *   Contrôle que le stock logique, saisi sur la position de document, est égal au stock AFFAIRE
  *   Indispensable sur le document "Transfert affaire vers stock"
  */
  function CTRL_STK1_IS_AFF(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lTypePos        doc_position.c_gauge_type_pos%type;
    lStoDescription stm_stock.sto_description%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.GET_TYPE_POS(iPositionId)
        into lTypePos
        from dual;

      if not(lTypePos = '4') then
        select min(STO_DESCRIPTION)
          into lStoDescription
          from doc_position POS
             , stm_stock STK
         where POS.doc_position_id = iPositionId
           and STK.stm_stock_id = POS.stm_stock_id;

        if lStoDescription <> PCS.PC_CONFIG.GETCONFIG('GCO_DefltSTOCK_PROJECT') then
          return PCS.PC_FUNCTIONS.TranslateWord('Le stock logique doit être de type AFFAIRE') || '[ABORT]';
        else
          return null;
        end if;
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_STK1_IS_AFF;

  /**
  * Description
  *   Contrôle que le stock logique, saisi sur la position de document, n'est pas égal au stock AFFAIRE
  *   Indispensable sur le document "Transfert stock vers affaire"
  */
  function CTRL_STK1_IS_NOT_AFF(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lTypePos        doc_position.c_gauge_type_pos%type;
    lStoDescription stm_stock.sto_description%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.GET_TYPE_POS(iPositionId)
        into lTypePos
        from dual;

      if not(lTypePos = '4') then
        select min(STO_DESCRIPTION)
          into lStoDescription
          from doc_position POS
             , stm_stock STK
         where POS.doc_position_id = iPositionId
           and STK.stm_stock_id = POS.stm_stock_id;

        if lStoDescription = PCS.PC_CONFIG.GETCONFIG('GCO_DefltSTOCK_PROJECT') then
          return PCS.PC_FUNCTIONS.TranslateWord('Le stock logique ne doit pas être de type AFFAIRE') || '[ABORT]';
        else
          return null;
        end if;
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_STK1_IS_NOT_AFF;

  /**
  * Description
  *   Contrôle que le stock transfert, saisi sur la position de document, est égal au stock AFFAIRE
  *   Indispensable sur le document "Transfert stock vers affaire"
  */
  function CTRL_STK2_IS_AFF(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lTypePos        doc_position.c_gauge_type_pos%type;
    lStoDescription stm_stock.sto_description%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.GET_TYPE_POS(iPositionId)
        into lTypePos
        from dual;

      if not(lTypePos = '4') then
        select min(STO_DESCRIPTION)
          into lStoDescription
          from doc_position POS
             , stm_stock STK
         where POS.doc_position_id = iPositionId
           and STK.stm_stock_id = POS.stm_stm_stock_id;

        if lStoDescription <> PCS.PC_CONFIG.GETCONFIG('GCO_DefltSTOCK_PROJECT') then
          return PCS.PC_FUNCTIONS.TranslateWord('Le stock transfert doit être de type AFFAIRE') || '[ABORT]';
        else
          return null;
        end if;
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_STK2_IS_AFF;

  /**
  * Description
  *   Contrôle que le stock transfert, saisi sur la position de document, n'est pas égal au stock AFFAIRE
  *   Indispensable sur le document "Transfert affaire vers stock"
  */
  function CTRL_STK2_IS_NOT_AFF(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lTypePos        doc_position.c_gauge_type_pos%type;
    lStoDescription stm_stock.sto_description%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.GET_TYPE_POS(iPositionId)
        into lTypePos
        from dual;

      if not(lTypePos = '4') then
        select min(STO_DESCRIPTION)
          into lStoDescription
          from doc_position POS
             , stm_stock STK
         where POS.doc_position_id = iPositionId
           and STK.stm_stock_id = POS.stm_stm_stock_id;

        if lStoDescription = PCS.PC_CONFIG.GETCONFIG('GCO_DefltSTOCK_PROJECT') then
          return PCS.PC_FUNCTIONS.TranslateWord('Le stock transfert ne doit pas être de type AFFAIRE') || '[ABORT]';
        else
          return null;
        end if;
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_STK2_IS_NOT_AFF;

  /**
  * Description
  *   Contrôle, dans le cas où un dossier est mis sur le document ou sur la position (en fonction de l'ID passé)
  *             que ce dossier N'EST PAS de type AFFAIRE
  *   Indispensable dans les docs ACHATS qui "alimentent" l'engagé ou le réalisé de l'affaire : il faut un dossier TACHE ou CODE BUDGET...
  */
  function CTRL_REC_IS_NOT_AFF(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lTypePos doc_position.c_gauge_type_pos%type;
    lRcoType doc_record.c_rco_type%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.GET_RCO_TYPE_FROM_DOC_POS_ID(iPositionId)
           , GAL_QI.GET_TYPE_POS(iPositionId)
        into lRcoType
           , lTypePos
        from dual;

      if     nvl(lRcoType, ' ') = '01'
         and not(lTypePos = '4') then
        return PCS.PC_FUNCTIONS.TranslateWord('Dossier de type AFFAIRE interdit') || '[ABORT]';
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_REC_IS_NOT_AFF;

  /**
  * Description
  *   Contrôle qu'un dossier est mis sur le document ou sur la position (en fonction de l'ID passé)
  *   Contrôle que ce dossier est de type AFFAIRE
  *   Indispensable si on veut obliger la liaison entre une commande client et une affaire (pour analyse des marges)
  */
  function CTRL_REC_IS_AFF(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lRcoType doc_record.c_rco_type%type;
    lTypePos doc_position.c_gauge_type_pos%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.GET_RCO_TYPE_FROM_DOC_POS_ID(iPositionId)
           , GAL_QI.GET_TYPE_POS(iPositionId)
        into lRcoType
           , lTypePos
        from dual;

      if     nvl(lRcoType, ' ') <> '01'
         and not(lTypePos = '4') then
        return PCS.PC_FUNCTIONS.TranslateWord('Dossier de type AFFAIRE obligatoire') || '[ABORT]';
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_REC_IS_AFF;

  /**
  * Description
  *   Contrôle qu'un dossier est mis sur le document ou sur la position (en fonction de l'ID passé)
  *   Contrôle que ce dossier est de type BUDGET
  *   Utilisable sur les docs de VENTE ou ACHATS
  */
  function CTRL_REC_IS_CB(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lRcoType doc_record.c_rco_type%type;
    lTypePos doc_position.c_gauge_type_pos%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.GET_RCO_TYPE_FROM_DOC_POS_ID(iPositionId)
           , GAL_QI.GET_TYPE_POS(iPositionId)
        into lRcoType
           , lTypePos
        from dual;

      if     nvl(lRcoType, ' ') <> '04'
         and not(lTypePos = '4') then
        return PCS.PC_FUNCTIONS.TranslateWord('Dossier de type BUDGET obligatoire') || '[ABORT]';
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_REC_IS_CB;

  /**
  * Description
  *   Contrôle qu'un dossier est mis sur le document ou sur la position (en fonction de l'ID passé)
  *   Contrôle que ce dossier est de type AFFAIRE ou BUDGET
  *   Utilisable sur les docs de VENTE
  */
  function CTRL_REC_IS_AFF_OR_CB(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lRecIsNotAff varchar2(4000);
    lRecIsNotCb  varchar2(4000);
    lTypePos     doc_position.c_gauge_type_pos%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.CTRL_REC_IS_AFF(iPositionId)
           , GAL_QI.CTRL_REC_IS_CB(iPositionId)
           , GAL_QI.GET_TYPE_POS(iPositionId)
        into lRecIsNotAff
           , lRecIsNotCb
           , lTypePos
        from dual;

      if     lRecIsNotAff is not null
         and lRecIsNotCb is not null
         and not(lTypePos = '4') then
        return PCS.PC_FUNCTIONS.TranslateWord('Dossier de type AFFAIRE ou BUDGET obligatoire') || '[ABORT]';
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_REC_IS_AFF_OR_CB;

  /**
  * Description
  *   Contrôle qu'un dossier est mis sur le document ou sur la position (en fonction de l'ID passé)
  *   Contrôle que ce dossier est de type Tache APPRO
  *   Utilisable sur les docs de sortie de stock, si on n'autorise que les sorties de stock sur affaire
  *   Utilisable sur certains docs d'achat, si on n'autorise que des achats sur tâche d'appro
  */
  function CTRL_REC_IS_SUPPLY_TASK(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lRcoType doc_record.c_rco_type%type;
    lTypePos doc_position.c_gauge_type_pos%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.GET_RCO_TYPE_FROM_DOC_POS_ID(iPositionId)
           , GAL_QI.GET_TYPE_POS(iPositionId)
        into lRcoType
           , lTypePos
        from dual;

      if     nvl(lRcoType, ' ') <> '02'
         and not(lTypePos = '4') then
        return PCS.PC_FUNCTIONS.TranslateWord('Dossier de type TACHE APPRO obligatoire') || '[ABORT]';
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_REC_IS_SUPPLY_TASK;

  /**
  * Description
  *   Contrôle qu'un dossier est mis sur le document ou sur la position (en fonction de l'ID passé)
  *   Contrôle que ce dossier est de type Tache MAIN D'OEUVRE
  *   Utilisable sur certains docs d'achat, si on n'autorise que des achats sur tâche de main d'oeuvre
  */
  function CTRL_REC_IS_LABOR_TASK(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lRcoType doc_record.c_rco_type%type;
    lTypePos doc_position.c_gauge_type_pos%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.GET_RCO_TYPE_FROM_DOC_POS_ID(iPositionId)
           , GAL_QI.GET_TYPE_POS(iPositionId)
        into lRcoType
           , lTypePos
        from dual;

      if     nvl(lRcoType, ' ') <> '03'
         and not(lTypePos = '4') then
        return PCS.PC_FUNCTIONS.TranslateWord('Dossier de type TACHE MAIN D''OEUVRE obligatoire') || '[ABORT]';
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_REC_IS_LABOR_TASK;

  /**
  * Description
  *   Contrôle qu'un dossier est mis sur le document ou sur la position (en fonction de l'ID passé)
  *   Contrôle que ce dossier est de type Tache (APPRO ou MAIN D'OEUVRE)
  *   Utilisable sur certains docs d'achat, si on n'autorise que des achats sur tâche (appro ou main d'oeuvre)
  */
  function CTRL_REC_IS_TASK(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lRecIsNotSupTask varchar2(4000);
    lRecIsNotLabTask varchar2(4000);
    lTypePos         doc_position.c_gauge_type_pos%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.CTRL_REC_IS_SUPPLY_TASK(iPositionId)
           , GAL_QI.CTRL_REC_IS_LABOR_TASK(iPositionId)
           , GAL_QI.GET_TYPE_POS(iPositionId)
        into lRecIsNotSupTask
           , lRecIsNotLabTask
           , lTypePos
        from dual;

      if     lRecIsNotSupTask is not null
         and lRecIsNotLabTask is not null
         and not(lTypePos = '4') then
        return PCS.PC_FUNCTIONS.TranslateWord('Dossier de type TACHE APPRO ou TACHE MAIN D''OEUVRE obligatoire') ||
               '[ABORT]';
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_REC_IS_TASK;

  /**
  * Description
  *   Contrôle qu'un dossier est mis sur le document ou sur la position (en fonction de l'ID passé)
  *   Contrôle que ce dossier est de type Code budget ou Tâche APPRO
  *   Utilisable sur certains docs d'achat
  */
  function CTRL_REC_IS_CB_OR_SUPTASK(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lRecIsNotSupTask varchar2(4000);
    lRecIsNotCb      varchar2(4000);
    lTypePos         doc_position.c_gauge_type_pos%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.CTRL_REC_IS_SUPPLY_TASK(iPositionId)
           , GAL_QI.CTRL_REC_IS_CB(iPositionId)
           , GAL_QI.GET_TYPE_POS(iPositionId)
        into lRecIsNotSupTask
           , lRecIsNotCb
           , lTypePos
        from dual;

      if     lRecIsNotSupTask is not null
         and lRecIsNotCb is not null
         and not(lTypePos = '4') then
        return PCS.PC_FUNCTIONS.TranslateWord('Dossier de type TACHE APPRO ou BUDGET obligatoire') || '[ABORT]';
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_REC_IS_CB_OR_SUPTASK;

  /**
  * Description
  *   Contrôle qu'un dossier est mis sur le document ou sur la position (en fonction de l'ID passé)
  *   Contrôle que ce dossier est de type Code budget ou Tâche (APPRO ou MAIN D'OEUVRE)
  *   Utilisable sur certains docs d'achat
  */
  function CTRL_REC_IS_CB_OR_TASK(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lRecIsNotSupTask varchar2(4000);
    lRecIsNotLabTask varchar2(4000);
    lRecIsNotCb      varchar2(4000);
    lTypePos         doc_position.c_gauge_type_pos%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select GAL_QI.CTRL_REC_IS_SUPPLY_TASK(iPositionId)
           , GAL_QI.CTRL_REC_IS_LABOR_TASK(iPositionId)
           , GAL_QI.CTRL_REC_IS_CB(iPositionId)
           , GAL_QI.GET_TYPE_POS(iPositionId)
        into lRecIsNotSupTask
           , lRecIsNotLabTask
           , lRecIsNotCb
           , lTypePos
        from dual;

      if     lRecIsNotSupTask is not null
         and lRecIsNotLabTask is not null
         and lRecIsNotCb is not null
         and not(lTypePos = '4') then
        return PCS.PC_FUNCTIONS.TranslateWord
                                         ('Dossier de type TACHE APPRO ou TACHE MAIN D''OEUVRE ou BUDGET obligatoire') ||
               '[ABORT]';
      else
        return null;
      end if;
    else
      return null;
    end if;
  end CTRL_REC_IS_CB_OR_TASK;

  /**
  * Description
  *   Procédure interne GET_RCO_TYPE_FROM_DOC_POS_ID (pas appelable depuis les gabarits)
  *   Retourne le type de dossier d'un ID de document ou de position (en fonction de l'ID passé)
  */
  function GET_RCO_TYPE_FROM_DOC_POS_ID(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lDocumentId doc_document.doc_document_id%type;
    lPositionId doc_position.doc_position_id%type;
    lRcoType    doc_record.c_rco_type%type;
    lRecordId   doc_record.doc_record_id%type;
  begin
    -- L'ID est-il un doc_document ?
    select nvl(min(DOC_DOCUMENT_ID), 0)
      into lDocumentId
      from doc_document
     where doc_document_id = iPositionId;

    -- L'ID est-il un doc_position ?
    select nvl(min(DOC_POSITION_ID), 0)
      into lPositionId
      from doc_position
     where doc_position_id = iPositionId;

    -- Récupération de l'ID du dossier du document
    if nvl(lDocumentId, 0) <> 0 then
      select nvl(doc_record_id, 0)
        into lRecordId
        from doc_document
       where doc_document_id = iPositionId;
    end if;

    -- Récupération de l'ID du dossier de la position du document
    if nvl(lPositionId, 0) <> 0 then
      select nvl(doc_record_id, 0)
        into lRecordId
        from doc_position
       where doc_position_id = iPositionId;
    end if;

    if lRecordId <> 0 then
      select c_rco_type
        into lRcoType
        from doc_record rcd
       where rcd.doc_record_id = lRecordId;
    end if;

    return lRcoType;
  end GET_RCO_TYPE_FROM_DOC_POS_ID;

  /**
  * Description
  *   Retourne le type de position d'un ID de position
  *   Cela permet de contrôler le dossier des positions, SAUF les positions de
  *   type 4 (texte) qui n'ont pas de dossier à l'écran
  */
  function GET_TYPE_POS(iPositionId in doc_position.doc_position_id%type)
    return varchar2
  is
    lResult doc_position.c_gauge_type_pos%type;
  begin
    select nvl(min(c_gauge_type_pos), ' ')
      into lResult
      from doc_position
     where doc_position_id = iPositionId;

    return lResult;
  end GET_TYPE_POS;

  /**
  * Description
  *   Détermine le stock si on est sur un dossier
  *   Si un dossier est renseigné -> On FORCE le sock Affaite
  *   Sinon on FORCE le stock du produit s'il existe
  *   Sinon on FORCE le stock par défaut non affaire
  *   A utiliser AVEC DELICATESSE
  *   CMI 25/09/09 Oui mais... Attention: on pourrait avoir un dossier "non affaire". Exemple : dossier STOCK ou dossier FRAIS GENERAUX ...
  *                Auquel cas on va forcer le stock affaire !!!
  *                A mon avis, ça mérite d'affiner les règles
  */
  procedure Put_stk_AFF_IF_ON_REC(iPositionId in doc_position.doc_position_id%type)
  is
    lRecordId        doc_record.doc_record_id%type;
    lAffaireStmId    doc_position.stm_stock_id%type;
    lAffaireLocId    doc_position.stm_location_id%type;
    lStockPosId      doc_position.stm_stock_id%type;
    lPosGoodId       doc_position.gco_good_id%type;
    lNotAffaireStmId doc_position.stm_stock_id%type;
    lNotAffaireLocId doc_position.stm_location_id%type;
    lProdStmId       doc_position.stm_stock_id%type;
    lProdLocId       doc_position.stm_location_id%type;
    lRcoTitle        doc_record.rco_title%type;
    lPdtStkMgt       gco_product.pdt_stock_management%type;
  begin
    if 1 = PCS.PC_CONFIG.GETCONFIG('GAL_PROJECT_MANAGEMENT') then
      select nvl(doc_record_id, 0)
        into lRecordId
        from doc_position
       where doc_position_id = iPositionId;

      -- on initie le rco_title pour si jamais on veut exclure des nom de dossier des contrôles
      begin
        select rco_title
          into lRcoTitle
          from doc_record
         where doc_record_id = lRecordId;
      exception
        when no_data_found then
          lRcoTitle  := null;
      end;

      select gco_good_id
        into lPosGoodId
        from doc_position
       where doc_position_id = iPositionId;

      select nvl(pdt_stock_management, 0)
        into lPdtStkMgt
        from gco_product
       where gco_good_id = lPosGoodId;

      -- stock affaire depuis la config
      select stm_stock_id
        into lAffaireStmId
        from stm_stock
       where sto_description = (select pcs.pc_config.getconfig('GCO_DefltSTOCK_PROJECT')
                                  from dual);

      -- location affaire depuis la config
      select loc.stm_location_id
        into lAffaireLocId
        from stm_location loc
       where loc.loc_description = (select pcs.pc_config.getconfig('GCO_DefltLOCATION_PROJECT')
                                      from dual)
         and loc.stm_stock_id = lAffaireStmId;

      if lPdtStkMgt = 1   -- non géré en stock
                       then
        if lRecordId = 0   -- pas de dossier ou règles sur le rco_title
                        then
          select stm_stock_id   -- stock du doc
            into lStockPosId
            from doc_position
           where doc_position_id = iPositionId;

          if lStockPosId = lAffaireStmId   -- pas de dossier et stock affaire
                                        then
            select stm_stock_id
                 , stm_location_id   -- on va chercher le stock du produit
              into lProdStmId
                 , lProdLocId
              from gco_good goo
                 , gco_product gcp
             where goo.gco_good_id = gcp.gco_good_id
               and goo.gco_good_id = lPosGoodId;

            if lProdStmId = lAffaireStmId   -- si le stock du produit est affaire
                                         then
              select stm_stock_id   -- on va chercher le stock et l'emplacement non affaire défini dans les configs
                into lNotAffaireStmId
                from stm_stock
               where sto_description = (select pcs.pc_config.getconfig('GCO_DefltSTOCK_not_PROJECT')
                                          from dual);

              select loc.stm_location_id
                into lNotAffaireLocId
                from stm_location loc
               where loc.loc_description = (select pcs.pc_config.getconfig('GCO_DefltLOCATION_not_PROJECT')
                                              from dual)
                 and loc.stm_stock_id = lNotAffaireStmId;

              update doc_position   -- update de la pos
                 set stm_stock_id = lNotAffaireStmId
                   , stm_location_id = lNotAffaireLocId
               where doc_position_id = iPositionId;

              update doc_position_detail
                 set stm_location_id = lNotAffaireLocId
               where doc_position_id = iPositionId;
            else
              update doc_position
                 set stm_stock_id = lProdStmId
                   , stm_location_id = lProdLocId
               where doc_position_id = iPositionId;

              update doc_position_detail
                 set stm_location_id = lProdLocId
               where doc_position_id = iPositionId;
            end if;
          end if;
        else   -- on a un dossier -> on met le stock et emplacement affaire
          update doc_position
             set stm_stock_id = lAffaireStmId
               , stm_location_id = lAffaireLocId
           where doc_position_id = iPositionId;

          update doc_position_detail
             set stm_location_id = lAffaireLocId
           where doc_position_id = iPositionId;
        end if;
      end if;
    end if;
  end Put_stk_AFF_IF_ON_REC;

  /**
     * procedure GET_TYPE_RECORD_GAL
     * Description
     *   retourne la catégorie de dossier, 01, 02, 03, 04, 05, 0 -> si doc_record non appartenant aux affaires
     *  @created hmo 10.2011
     * @public
     */
  function GET_C_RCO_TYPE_RECORD_GAL(i_doc_record_id in doc_record.doc_record_id%type)
    return doc_record.c_rco_type%type
  is
    l_c_rco_type doc_record.c_rco_type%type;
  begin
    select nvl(c_rco_type, 0)
      into l_c_rco_type
      from doc_record
     where doc_record_id = i_doc_record_id;

    return l_c_rco_type;
  end;
end GAL_QI;
