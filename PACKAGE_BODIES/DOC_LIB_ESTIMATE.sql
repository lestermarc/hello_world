--------------------------------------------------------
--  DDL for Package Body DOC_LIB_ESTIMATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_LIB_ESTIMATE" 
is
  /**
  * procedure CanModifyEstimate
  * Description
  *   Indique si le devis est modifiable
  */
  procedure CanModifyEstimate(
    iEstimateID in     DOC_ESTIMATE.DOC_ESTIMATE_ID%type
  , oCanModify  out    number
  , oMessage    out    varchar2
  )
  is
    lvStatus DOC_ESTIMATE.C_DOC_ESTIMATE_STATUS%type;
    cCode    PCS.PC_GCODES.GCLCODE%type;
  begin
    cCode  := PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_CREATE_GOOD');

    -- Selectionne le devis
    select C_DOC_ESTIMATE_STATUS
      into lvStatus
      from DOC_ESTIMATE
     where DOC_ESTIMATE_ID = iEstimateID;

    case lvStatus
      when '02' then   -- Devis annul�
        oCanModify  := 0;
        oMessage    := PCS.PC_FUNCTIONS.TranslateWord('Modification impossible, le devis est annul�.');
      when '04' then   -- En attente de r�ponse
        if    (cCode = '3')
           or (cCode = '2') then   -- cr�ation des produits � la g�n�ration de la commande ou � acceptation du devis
          oCanModify  := 1;
          oMessage    :=
            PCS.PC_FUNCTIONS.TranslateWord
                                          ('Le devis est en attente de r�ponse. �tes-vous s�r de vouloir le modifier ?');
        elsif cCode = '1' then   -- cr�ation des produits � la g�n�ration de l'offre
          oCanModify  := 0;
          oMessage    := PCS.PC_FUNCTIONS.TranslateWord('Modification impossible, le devis a d�j� g�n�r� une offre.');
        end if;
      when '05' then   -- Devis liquid�
        if cCode = '3' then   -- cr�ation des produit � la g�n�ration de la commande
          oCanModify  := 0;
          oMessage    :=
                        PCS.PC_FUNCTIONS.TranslateWord('Modification impossible, le devis a d�j� g�n�r� une commande.');
        elsif cCode = '2' then   -- cr�ation des produit � l'acceptation du devis
          oCanModify  := 0;
          oMessage    := PCS.PC_FUNCTIONS.TranslateWord('Modification impossible, le devis est d�j� accept�.');
        elsif cCode = '1' then   -- cr�ation des produit � la g�n�ration de l'offre
          oCanModify  := 0;
          oMessage    := PCS.PC_FUNCTIONS.TranslateWord('Modification impossible, le devis a d�j� g�n�r� une offre.');
        end if;
      when '06' then   -- Accept�
        if cCode = '3' then   -- cr�ation des produit � la g�n�ration de la commande
          oCanModify  := 1;
          oMessage    :=
                  PCS.PC_FUNCTIONS.TranslateWord('Le devis a d�j� �t� accept�. �tes-vous s�r de vouloir le modifier ?');
        elsif cCode = '2' then   -- cr�ation des produit � l'acceptation du devis
          oCanModify  := 0;
          oMessage    := PCS.PC_FUNCTIONS.TranslateWord('Modification impossible, le devis est d�j� accept�.');
        elsif cCode = '1' then   -- cr�ation des produit � la g�n�ration de l'offre
          oCanModify  := 0;
          oMessage    := PCS.PC_FUNCTIONS.TranslateWord('Modification impossible, le devis a d�j� g�n�r� une offre.');
        end if;
      when '07' then   -- Refus�
        if cCode = '3' then   -- cr�ation des produit � la g�n�ration de la commande
          oCanModify  := 1;
          oMessage    :=
                        PCS.PC_FUNCTIONS.TranslateWord('Le devis a �t� refus�. �tes-vous s�r de vouloir le modifier ?');
        elsif cCode = '1' then   -- cr�ation des produit � la g�n�ration de l'offre
          oCanModify  := 0;
          oMessage    := PCS.PC_FUNCTIONS.TranslateWord('Modification impossible, le devis a d�j� g�n�r� une offre.');
        end if;
      else
        oCanModify  := 1;
        oMessage    := null;
    end case;
  end CanModifyEstimate;

  /**
  * procedure CanDeleteEstimate
  * Description
  *   Indique si le devis est effa�able
  */
  procedure CanDeleteEstimate(
    iEstimateID in     DOC_ESTIMATE.DOC_ESTIMATE_ID%type
  , oCanDelete  out    number
  , oMessage    out    varchar2
  )
  is
    lvStatus DOC_ESTIMATE.C_DOC_ESTIMATE_STATUS%type;
  begin
    -- Selectionne le devis
    select C_DOC_ESTIMATE_STATUS
      into lvStatus
      from DOC_ESTIMATE
     where DOC_ESTIMATE_ID = iEstimateID;

    if lvStatus in('01', '04', '06', '07') then
      oCanDelete  := 1;
      oMessage    :=
        PCS.PC_FUNCTIONS.TranslateWord
                             ('Le devis a d�j� g�n�r� une ou plusieurs offres. �tes-vous s�r de vouloir le supprimer ?');
    elsif lvStatus = '02' then
      oCanDelete  := 0;
      oMessage    := PCS.PC_FUNCTIONS.TranslateWord('Effacement impossible, le devis est annul�.');
    elsif lvStatus = '05' then
      oCanDelete  := 0;
      oMessage    := PCS.PC_FUNCTIONS.TranslateWord('Effacement impossible, le devis a g�n�r� une commande.');
    else
      oCanDelete  := 1;
      oMessage    := null;
    end if;
  end CanDeleteEstimate;

  /**
  * Description
  *   Indique si le devis a g�n�r� des documents (offres ou commandes)
  */
  function ExistsEstimateDocuments(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type)
    return boolean
  is
    lCount pls_integer;
  begin
    -- Recherche des documents logistiques g�n�r�s par le devis
    select count(*)
      into lCount
      from DOC_DOCUMENT
     where DOC_ESTIMATE_ID = iEstimateId;

    return(lCount > 0);
  end ExistsEstimateDocuments;

  /**
  * Description
  *   Indique si le devis a g�n�r� une ou plusieurs offres
  */
  function ExistsEstimateOffer(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type)
    return boolean
  is
    lCount pls_integer;
  begin
    -- Recherche des offres logistiques g�n�r�es par le devis
    select count(*)
      into lCount
      from DOC_DOCUMENT DMT
         , DOC_ESTIMATE DES
     where DES.DOC_ESTIMATE_ID = iEstimateId
       and DMT.DOC_ESTIMATE_ID = DES.DOC_ESTIMATE_ID
       and DMT.DOC_GAUGE_ID = DES.DOC_GAUGE_OFFER_ID;

    return(lCount > 0);
  end ExistsEstimateOffer;

  /**
  * Description
  *   Indique si le devis a g�n�r� une commande
  */
  function ExistsEstimateOrder(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type)
    return boolean
  is
    lCount pls_integer;
  begin
    -- Recherche des commandes logistiques g�n�r�es par le devis
    select count(*)
      into lCount
      from DOC_DOCUMENT DMT
         , DOC_ESTIMATE DES
     where DES.DOC_ESTIMATE_ID = iEstimateId
       and DMT.DOC_ESTIMATE_ID = DES.DOC_ESTIMATE_ID
       and DMT.DOC_GAUGE_ID = DES.DOC_GAUGE_ORDER_ID;

    return(lCount > 0);
  end ExistsEstimateOrder;

  /**
  * Description
  *   Indique si le devis est modifiable
  */
  function CanModifyEstimate(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type)
    return varchar2
  is
    lResult                     varchar2(4000);
    lEstimateStatus             varchar2(2);
    lvEstimateCanceledMsg       varchar2(255);
    lvEstimateWaiting4AnswerMsg varchar2(255);
    lvEstimateLiquidatedMsg     varchar2(255);
    lvEstimateAcceptedMsg       varchar2(255);
    lvEstimateRefusedMsg        varchar2(255);
    lvStandardConfirmMsg        varchar2(255);
  begin
    -- Selectionne le devis
    select C_DOC_ESTIMATE_STATUS
      into lEstimateStatus
      from DOC_ESTIMATE
     where DOC_ESTIMATE_ID = iEstimateId;

    lvEstimateCanceledMsg        := PCS.PC_FUNCTIONS.TranslateWord('Modification impossible, le devis est annul�.');
    lvEstimateWaiting4AnswerMsg  :=
            PCS.PC_FUNCTIONS.TranslateWord('Le devis est en attente de r�ponse. �tes-vous s�r de vouloir le modifier ?');
    lvEstimateLiquidatedMsg      :=
                         PCS.PC_FUNCTIONS.TranslateWord('Modification impossible, le devis a d�j� g�n�r� une commande.');
    lvEstimateAcceptedMsg        :=
                   PCS.PC_FUNCTIONS.TranslateWord('Le devis a d�j� �t� accept�. �tes-vous s�r de vouloir le modifier ?');
    lvEstimateRefusedMsg         :=
                         PCS.PC_FUNCTIONS.TranslateWord('Le devis a �t� refus�. �tes-vous s�r de vouloir le modifier ?');
    lvStandardConfirmMsg         := '';

    case lEstimateStatus
      when '02' then   -- Devis annul�
        lResult  := lvEstimateCanceledMsg;
      when '04' then   -- En attente de r�ponse
        lResult  := lvEstimateWaiting4AnswerMsg || '[CHECK]';
      when '05' then   -- Devis liquid�
        lResult  := lvEstimateLiquidatedMsg;
      when '06' then   -- Accept�
        lResult  := lvEstimateAcceptedMsg || '[CHECK]';
      when '07' then   -- Refus�
        lResult  := lvEstimateRefusedMsg || '[CHECK]';
      else
        lResult  := lvStandardConfirmMsg || '[CHECK]';
    end case;

    return lResult;
  end CanModifyEstimate;

  /**
  * function GetProjectTasks
  * Description
  *   Renvoi la liste des t�ches/bugdets d'une affaire
  */
  function GetProjectTasks(iProjectID in GAL_PROJECT.GAL_PROJECT_ID%type)
    return TProjectTaskTable pipelined
  is
    ltBudget  TProjectTask;
    ltTask    TProjectTask;
    lnTaskSeq integer;
  begin
    -- Liste des budget de l'affaire (meme si celui-ci ne poss�de pas de t�che)
    for lptlBudget in (select     rownum ROW_SEQ
                                , level ROW_LEVEL
                                , BDG.GAL_BUDGET_ID
                                , null as GAL_TASK_ID
                             from GAL_BUDGET BDG
                            where BDG.GAL_PROJECT_ID = iProjectID
                       connect by prior BDG.GAL_BUDGET_ID = BDG.GAL_FATHER_BUDGET_ID
                       start with BDG.GAL_FATHER_BUDGET_ID is null
                         order siblings by lpad(BDG.BDG_SORT_CRITERIA, 30, '0') asc nulls last
                                 , BDG.BDG_CODE asc) loop
      ltBudget.GAL_BUDGET_ID  := lptlBudget.GAL_BUDGET_ID;
      ltBudget.GAL_TASK_ID    := lptlBudget.GAL_TASK_ID;
      ltBudget.ROW_LEVEL      := lptlBudget.ROW_LEVEL;
      ltBudget.ROW_SEQ        := lptlBudget.ROW_SEQ * 1000;
      pipe row(ltBudget);
      lnTaskSeq               := 1;

      -- Liste des t�ches du budget courant
      for ltplTask in (select   TSK.GAL_BUDGET_ID
                              , TSK.GAL_TASK_ID
                           from GAL_TASK TSK
                              , GAL_TASK_CATEGORY TCA
                          where TSK.GAL_BUDGET_ID = lptlBudget.GAL_BUDGET_ID
                            and TSK.GAL_FATHER_TASK_ID is null
                            and TSK.GAL_TASK_CATEGORY_ID = TCA.GAL_TASK_CATEGORY_ID
                            and TCA.C_TCA_TASK_TYPE in('1', '2')
                       order by TAS_CODE) loop
        ltTask.GAL_BUDGET_ID  := ltplTask.GAL_BUDGET_ID;
        ltTask.GAL_TASK_ID    := ltplTask.GAL_TASK_ID;
        ltTask.ROW_LEVEL      := ltBudget.ROW_LEVEL + 1;
        ltTask.ROW_SEQ        := ltBudget.ROW_SEQ + lnTaskSeq;
        pipe row(ltTask);
        lnTaskSeq             := lnTaskSeq + 1;
      end loop;
    end loop;
  end GetProjectTasks;

    /**
  * function CanLinkToGalProject
  * Description
  *   Indique si le devis peux �tre li� � une affaire
  * @created jfr 10.01.2012
  * @lastUpdate
  * @public
  * @param iEstimateID : ID du devis
  * @param iProjectID : ID de l'affaire
  * @return retourne un message d'erreur si le lien avec une affaire est impossible,
  *   et retourne NULL si le lien est autoris�e
  */
  function CanLinkToGalProject(
    iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type
  , iProjectID  in GAL_PROJECT.GAL_PROJECT_ID%type
  )
    return varchar2
  is
    lCountDocEstimatePosAppro number;
    lCountDocEstimatePosTask  number;
    lCountGalTaskAppro        number;
    lCountGalTaskTask         number;
    lMessage                  varchar2(1000);
    lnIncrement               number;

    procedure SetMessage(iMess in varchar2)
    is
    begin
      if lMessage is null then
        lMessage  := iMess;
      else
        lMessage  := lMessage || chr(13) || iMess;
      end if;
    end;
  begin
    -- V�rifier si l'affaire est li�e � une num�rotation automatique
    select nvl(max(GAN.GAN_INCREMENT), 0)
      into lnIncrement
      from GAL_PROJECT PRJ
         , DIC_GAL_PRJ_CATEGORY CAT
         , DOC_GAUGE_NUMBERING GAN
     where PRJ.GAL_PROJECT_ID = iProjectId
       and PRJ.DIC_GAL_PRJ_CATEGORY_ID = CAT.DIC_GAL_PRJ_CATEGORY_ID
       and CAT.DOC_GAUGE_NUMBERING_ID = GAN.DOC_GAUGE_NUMBERING_ID;

    if lnIncrement = 0 then
      SetMessage(PCS.PC_FUNCTIONS.TranslateWord('Cette affaire ne poss�de pas de num�rotation automatique !') );
    end if;

    select count(*)
      into lCountDocEstimatePosAppro
      from EV_DOC_ESTIMATE_POS VPOS
     where VPOS.DOC_ESTIMATE_ID = iEstimateId
       and VPOS.GCO_GOOD_ID is not null
       and VPOS.DEP_OPTION = 0;

    select count(*)
      into lCountDocEstimatePosTask
      from EV_DOC_ESTIMATE_POS VPOS
     where VPOS.DOC_ESTIMATE_ID = iEstimateId
       and VPOS.GCO_GOOD_ID is null
       and VPOS.DEP_OPTION = 0;

    select count(*)
      into lCountGalTaskAppro
      from GAL_TASK TAS
         , GAL_TASK_CATEGORY TCA
     where TAS.GAL_PROJECT_ID = iProjectId
       and TAS.GAL_TASK_CATEGORY_ID = TCA.GAL_TASK_CATEGORY_ID
       and TCA.C_TCA_TASK_TYPE = '1';

    select count(*)
      into lCountGalTaskTask
      from GAL_TASK TAS
         , GAL_TASK_CATEGORY TCA
     where TAS.GAL_PROJECT_ID = iProjectId
       and TAS.GAL_TASK_CATEGORY_ID = TCA.GAL_TASK_CATEGORY_ID
       and TCA.C_TCA_TASK_TYPE = '2';

    if     lCountDocEstimatePosAppro <> 0
       and lCountGalTaskAppro = 0 then
      SetMessage(PCS.PC_FUNCTIONS.TranslateWord('Cette affaire ne contient pas de t�che de type approvisionnement !') );
    end if;

    if     lCountDocEstimatePosTask <> 0
       and lCountGalTaskTask = 0 then
      SetMessage(PCS.PC_FUNCTIONS.TranslateWord('Cette affaire ne contient pas de t�che de type main d''oeuvre !') );
    end if;

    return lMessage;
  end CanLinkToGalProject;

  /**
  * function CanLinkToGalBudget
  * Description
  *   Indique si la position de devis peux �tre li� au budget affaire
  */
  function CanLinkToGalBudget(
    iEstimatePosID in DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type
  , iBudgetID      in GAL_BUDGET.GAL_BUDGET_ID%type
  )
    return varchar2
  is
    lnVirtualGoodID GCO_GOOD.GCO_GOOD_ID%type;
    lvMsg           varchar2(4000)              := null;
    lnCount         integer;
  begin
    -- Rechercher l'id du produit virtuel
    lnVirtualGoodID  :=
      nvl(FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_GOOD') )
        , 0
         );

    -- D�finition du type de t�che necessaire
    -- Si (pas de cr�ation de bien) ET (bien vide OU bien = bien virtuel)
    --       : T�che de type main d'oeuvre (2)  ou Code de budget
    -- sinon : T�che de type approvisionnement (1)
    select case
             when(C_DOC_ESTIMATE_CREATE_MODE = '00')
             and (nvl(GCO_GOOD_ID, lnVirtualGoodID) = lnVirtualGoodID) then null
             else PCS.PC_FUNCTIONS.TranslateWord
                                       ('Cette position de devis doit �tre li�e � une t�che de type approvisionnement !')
           end
      into lvMsg
      from EV_DOC_ESTIMATE_POS
     where DOC_ESTIMATE_POS_ID = iEstimatePosId;

    if lvMsg is null then
      -- V�rification du code de budget
      select count(*)
        into lnCount
        from GAL_BUDGET
       where GAL_BUDGET_ID = iBudgetID
         and GAL_FATHER_BUDGET_ID is null
         and C_BDG_STATE = '10';

      if lnCount = 0 then
        lvMsg  := PCS.PC_FUNCTIONS.TranslateWord('Cette position de devis ne peut pas �tre li�e � ce code de budget !');
        lvMsg  :=
          lvMsg ||
          chr(10) ||
          PCS.PC_FUNCTIONS.TranslateWord
                      ('Le code de budget doit �tre au statut "Nouveau" et ne doit pas avoir de lien "Budget p�re" !');
      end if;
    end if;

    return lvMsg;
  end CanLinkToGalBudget;

  /**
  * function CanLinkToGalTask
  * Description
  *   Indique si la position de devis peux �tre li� � une t�che d'affaire
  * @created aga 16.01.2012
  * @lastUpdate
  * @public
  * @param iEstimatePosID : ID de la position de devis
  * @param iTaskID : ID de la t�che d'affaire
  * @return retourne un message d'erreur si le lien avec une t�che d'affaire est impossible,
  *   et retourne NULL si le lien est autoris�e
  */
  function CanLinkToGalTask(
    iEstimatePosID in DOC_ESTIMATE_POS.DOC_ESTIMATE_POS_ID%type
  , iTaskID        in GAL_TASK.GAL_TASK_ID%type
  )
    return varchar2
  is
    lnVirtualGoodID GCO_GOOD.GCO_GOOD_ID%type;
    lvTaskType      varchar2(10);
    lnCountTask     integer;
    lvMsg           varchar2(4000)              := null;
  begin
    -- Rechercher l'id du produit virtuel
    lnVirtualGoodID  :=
      nvl(FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', PCS.PC_CONFIG.GetConfig('DOC_ESTIMATE_GOOD') )
        , 0
         );

    -- D�finition du type de t�che necessaire
    -- Si (pas de cr�ation de bien) ET (bien vide OU bien = bien virtuel)
    --       : T�che de type main d'oeuvre (2) ou Code de budget
    -- sinon : T�che de type approvisionnement (1)
    select case
             when(C_DOC_ESTIMATE_CREATE_MODE = '00')
             and (nvl(GCO_GOOD_ID, lnVirtualGoodID) = lnVirtualGoodID) then '2'
             else '1'
           end
      into lvTaskType
      from EV_DOC_ESTIMATE_POS
     where DOC_ESTIMATE_POS_ID = iEstimatePosId;

    select count(*)
      into lnCountTask
      from GAL_TASK TAS
         , GAL_TASK_CATEGORY TCA
     where TAS.GAL_TASK_ID = iTaskId
       and TAS.GAL_TASK_CATEGORY_ID = TCA.GAL_TASK_CATEGORY_ID
       and TCA.C_TCA_TASK_TYPE = lvTaskType;

    if lnCountTask = 0 then
      if lvTaskType = '1' then
        lvMsg  :=
          PCS.PC_FUNCTIONS.TranslateWord
                                      ('Cette position de devis doit �tre li�e � une t�che de type approvisionnement !');
      else
        lvMsg  :=
          PCS.PC_FUNCTIONS.TranslateWord('Cette position de devis doit �tre li�e � une t�che de type main d''oeuvre !');
      end if;
    end if;

    return lvMsg;
  end CanLinkToGalTask;

  /**
  * function CtrlLinkToProject
  * Description
  *   V�rifie que toutes les positions soient li�es � l'affaire
  */
  function CtrlLinkToProject(iEstimateID in DOC_ESTIMATE.DOC_ESTIMATE_ID%type)
    return varchar2
  is
    lnCount   integer        := 0;
    lvMsg     varchar2(4000);
    lvPosList varchar2(4000) := null;
  begin
    -- Liste des positions de devis qui ne sont pas li�es � l'affaire
    for ltplPos in (select   VPOS.DEP_NUMBER
                        from EV_DOC_ESTIMATE_POS VPOS
                       where VPOS.DOC_ESTIMATE_ID = iEstimateID
                         and VPOS.DEP_OPTION = 0
                         and VPOS.GAL_BUDGET_ID is null
                         and VPOS.GAL_TASK_ID is null
                    order by VPOS.DEP_NUMBER) loop
      if lvPosList is null then
        lvPosList  := ltplPos.DEP_NUMBER;
      else
        lvPosList  := lvPosList || ', ' || ltplPos.DEP_NUMBER;
      end if;

      lnCount  := lnCount + 1;
    end loop;

    -- Pas de positions sans lien
    if lnCount = 0 then
      lvMsg  := null;
    elsif lnCount = 1 then
      lvMsg  :=
            replace(PCS.PC_FUNCTIONS.TranslateWord('La position n�%f n''est pas li�e � l''affaire !'), '%f', lvPosList);
    else
      lvMsg  := PCS.PC_FUNCTIONS.TranslateWord('Plusieurs positions ne sont pas li�es � l''affaire !') || chr(10);
      lvMsg  := lvMsg || PCS.PC_FUNCTIONS.TranslateWord('Positions � traiter : ') || lvPosList;
    end if;

    return lvMsg;
  end CtrlLinkToProject;
end DOC_LIB_ESTIMATE;
