--------------------------------------------------------
--  DDL for Package Body FAL_LIB_TASK_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_TASK_LINK" 
is
  /**
  * Description
  *    Cette function retourne La date de r�cup�ration (date de fin r�elle ou
  *    planifi�e) de l'op�ration de lot transmise en param�tre.
  */
  function getEndDate(inFalTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return date
  as
    lnRecupDate date;
  begin
    select nvl(nvl(TAL.TAL_END_REAL_DATE, TAL.TAL_END_PLAN_DATE), LOT.LOT_PLAN_END_DTE)
      into lnRecupDate
      from FAL_TASK_LINK TAL
         , FAL_LOT LOT
     where TAL.FAL_SCHEDULE_STEP_ID = inFalTaskLinkID
       and TAL.FAL_LOT_ID = LOT.FAL_LOT_ID;

    return lnRecupDate;
  end getEndDate;

  /**
  * Description
  *    Cette function retourne 1 si les copeaux de l'op�ration de lot dont la
  *    clef primaire est transmise en param�tre doivent �tre pes�s � l'op�ration
  */
  function hasWeighing(inFalTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_TASK_CHIP_DETAIL.TCH_WEIGHING_BY_TASK%type
  as
    lnTaskLinkAlloyNumber number default 0;
  begin
    lnTaskLinkAlloyNumber  := FAL_LIB_TASK_LINK.getChipAlloyNumber(inFalTaskLinkID => inFalTaskLinkID);

    if lnTaskLinkAlloyNumber > 0 then
      return 1;
    else
      return 0;
    end if;
  exception
    when no_data_found then
      return 0;
  end hasWeighing;

  /**
  * Description
  *    Cette fonction retourne le nombre d'alliage pour lesquels une pes�e doit �tre effectu�
  *    pour l'op�ration de lot dont la clef primaire est transmise en param�tre.
  */
  function getChipAlloyNumber(inFalTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  as
    lnTaskLinkAlloyNumber number;
  begin
    select count(tch.FAL_TASK_CHIP_DETAIL_ID)
      into lnTaskLinkAlloyNumber
      from GCO_ALLOY gal
         , GCO_PRECIOUS_MAT gpm
         , FAL_LOT lot
         , FAL_TASK_LINK tal
         , FAL_TASK_CHIP_DETAIL tch
     where gal.GCO_ALLOY_ID = gpm.GCO_ALLOY_ID
       and gpm.GCO_GOOD_ID = lot.GCO_GOOD_ID
       and tal.FAL_LOT_ID = lot.FAL_LOT_ID
       and tal.FAL_SCHEDULE_STEP_ID = tch.FAL_TASK_LINK_ID
       and tch.GCO_ALLOY_ID = gal.GCO_ALLOY_ID
       and gpm.GPM_WEIGHT = 1
       and gpm.GPM_REAL_WEIGHT = 1
       and nvl(gal.GAL_GENERIC, 0) = 0
       and tch.TCH_WEIGHING_BY_TASK = 1
       and tal.FAL_SCHEDULE_STEP_ID = inFalTaskLinkID;

    return lnTaskLinkAlloyNumber;
  exception
    when no_data_found then
      return 0;
  end getChipAlloyNumber;

  /**
  * Description
  *    Cette fonction retourne la clef primaire de l'alliage pour lequel une pes�e
  *    doit �tre effectu�e pour l'op�ration de lot dont la clef primaire est transmise
  *    en param�tre pour autant que celui-ci soit unique. Retourne null si plusieurs
  *    alliages sont d�fini pour la pes�e de copeaux � l'op�ration de lot.
  */
  function getUniqueChipAlloy(inFalTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_TASK_CHIP_DETAIL.GCO_ALLOY_ID%type
  as
    lnGcoAlloyID FAL_TASK_CHIP_DETAIL.GCO_ALLOY_ID%type;
  begin
    select gal.GCO_ALLOY_ID
      into lnGcoAlloyID
      from GCO_ALLOY gal
         , GCO_PRECIOUS_MAT gpm
         , FAL_LOT lot
         , FAL_TASK_LINK tal
         , FAL_TASK_CHIP_DETAIL tch
     where gal.GCO_ALLOY_ID = gpm.GCO_ALLOY_ID
       and gpm.GCO_GOOD_ID = lot.GCO_GOOD_ID
       and tal.FAL_LOT_ID = lot.FAL_LOT_ID
       and tal.FAL_SCHEDULE_STEP_ID = tch.FAL_TASK_LINK_ID
       and tch.GCO_ALLOY_ID = gal.GCO_ALLOY_ID
       and gpm.GPM_WEIGHT = 1
       and gpm.GPM_REAL_WEIGHT = 1
       and nvl(GAL_GENERIC, 0) = 0
       and tch.TCH_WEIGHING_BY_TASK = 1
       and tal.FAL_SCHEDULE_STEP_ID = inFalTaskLinkID
    having (select count(gal.GCO_ALLOY_ID)
              from GCO_ALLOY gal
                 , GCO_PRECIOUS_MAT gpm
                 , FAL_LOT lot
                 , FAL_TASK_LINK tal
                 , FAL_TASK_CHIP_DETAIL tch
             where gal.GCO_ALLOY_ID = gpm.GCO_ALLOY_ID
               and gpm.GCO_GOOD_ID = lot.GCO_GOOD_ID
               and tal.FAL_LOT_ID = lot.FAL_LOT_ID
               and tal.FAL_SCHEDULE_STEP_ID = tch.FAL_TASK_LINK_ID
               and tch.GCO_ALLOY_ID = gal.GCO_ALLOY_ID
               and gpm.GPM_WEIGHT = 1
               and gpm.GPM_REAL_WEIGHT = 1
               and nvl(GAL_GENERIC, 0) = 0
               and tch.TCH_WEIGHING_BY_TASK = 1
               and tal.FAL_SCHEDULE_STEP_ID = inFalTaskLinkID) = 1;

    return lnGcoAlloyID;
  exception
    when no_data_found then
      return null;
  end getUniqueChipAlloy;

  /**
  * Description
  *    Cette function retourne 1 si les copeaux de l'op�ration de lot dont la
  *    clef primaire est transmise en param�tre doivent �tre retourn�s sous forme
  *    de mouvement de produit de d�riv� et que le lot de fabrication poss�de dans
  *    sa nomenclature au moins un composant de type d�riv� avec une d�finition
  *    d'alliage correspondant.
  */
  function hasDerivativeMvt(inFalTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_TASK_CHIP_DETAIL.TCH_MVT_BY_TASK%type
  as
    hasDerivativeMvt FAL_TASK_CHIP_DETAIL.TCH_MVT_BY_TASK%type;
  begin
    select count(tch.FAL_TASK_CHIP_DETAIL_ID)
      into hasDerivativeMvt
      from GCO_ALLOY gal
         , GCO_PRECIOUS_MAT gpm
         , FAL_LOT_MATERIAL_LINK lom
         , FAL_LOT lot
         , FAL_TASK_LINK tal
         , FAL_TASK_CHIP_DETAIL tch
     where gal.GCO_ALLOY_ID = gpm.GCO_ALLOY_ID
       and gpm.GCO_GOOD_ID = lom.GCO_GOOD_ID
       and lot.FAL_LOT_ID = lom.FAL_LOT_ID
       and tal.FAL_LOT_ID = lot.FAL_LOT_ID
       and tal.FAL_SCHEDULE_STEP_ID = tch.FAL_TASK_LINK_ID
       and tch.GCO_ALLOY_ID = gal.GCO_ALLOY_ID
       and gpm.GPM_WEIGHT = 1
       and gpm.GPM_REAL_WEIGHT = 1
       and nvl(gal.GAL_GENERIC, 0) = 0
       and tch.TCH_MVT_BY_TASK = 1
       and lom.C_KIND_COM = '2'   /* d�riv� */
       and tal.FAL_SCHEDULE_STEP_ID = inFalTaskLinkID;

    if hasDerivativeMvt > 0 then
      return 1;
    else
      return 0;
    end if;
  exception
    when no_data_found then
      return 0;
  end hasDerivativeMvt;

  /**
  * Description
  *    Cette function retourne la clef primaire du lot de l'op�ration dont la clef
  *    primaire est transmise en param�tre.
  */
  function getFalLotID(inFalTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_TASK_LINK.FAL_LOT_ID%type
  as
    lLotID FAL_TASK_LINK.FAL_LOT_ID%type;
  begin
    select FAL_LOT_ID
      into lLotID
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = inFalTaskLinkID;

    return lLotID;
  exception
    when no_data_found then
      return null;
  end getFalLotID;

  /**
  * Description
  *    Cette function retourne la s�quence de l'op�ration
  */
  function getStepNumber(iTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_TASK_LINK.SCS_STEP_NUMBER%type
  as
    lStepNumber FAL_TASK_LINK.SCS_STEP_NUMBER%type;
  begin
    select SCS_STEP_NUMBER
      into lStepNumber
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = iTaskLinkID;

    return lStepNumber;
  exception
    when no_data_found then
      return null;
  end getStepNumber;

  /**
  * Description
  *    Cette function r�cup�re le nombre de pes�es non effectu�es (poids ou mvt)
  *    sur l'avancement de lot dont la clef primaire est transmise en param�tre.
  *    retourne 1 si des pes�es non effectu�es existe, sinon 0
  */
  function hasNotWeighedYetChipPM(inFalLotProgressID in FAL_LOT_PROGRESS.FAL_LOT_PROGRESS_ID%type)
    return number
  as
    notAlreadyWeighed number;
  begin
    select count(tch.FAL_TASK_CHIP_DETAIL_ID)
      into notAlreadyWeighed
      from GCO_ALLOY gal
         , GCO_PRECIOUS_MAT gpm
         , GCO_GOOD goo
         , FAL_LOT lot
         , FAL_TASK_LINK tal
         , FAL_TASK_CHIP_DETAIL tch
     where gal.GCO_ALLOY_ID = gpm.GCO_ALLOY_ID
       and gpm.GCO_GOOD_ID = goo.GCO_GOOD_ID
       and lot.GCO_GOOD_ID = goo.GCO_GOOD_ID
       and tal.FAL_LOT_ID = lot.FAL_LOT_ID
       and tal.FAL_SCHEDULE_STEP_ID = tch.FAL_TASK_LINK_ID
       and tch.GCO_ALLOY_ID = gal.GCO_ALLOY_ID
       and gpm.GPM_WEIGHT = 1
       and gpm.GPM_REAL_WEIGHT = 1
       and nvl(gal.GAL_GENERIC, 0) = 0
       and TAL.FAL_SCHEDULE_STEP_ID in(select FLP.FAL_SCHEDULE_STEP_ID
                                         from FAL_LOT_PROGRESS FLP
                                        where FLP.FAL_LOT_PROGRESS_ID = inFalLotProgressID)
       and not exists(
             select fwe.GCO_ALLOY_ID
               from FAL_WEIGH fwe
              where fwe.FAL_SCHEDULE_STEP_ID = tch.FAL_TASK_LINK_ID
                and fwe.GCO_ALLOY_ID = tch.GCO_ALLOY_ID
                and fwe.FWE_TURNINGS = 1
                and fwe.FAL_LOT_PROGRESS_ID = inFalLotProgressID);

    if (notAlreadyWeighed) > 0 then
      return 1;
    else
      return 0;
    end if;
  exception
    when no_data_found then
      return 0;
  end hasNotWeighedYetChipPM;

  /**
  * Description
  *    Cette function retourne 1 si l'op�ration de lot dont la clef primaire comporte
  *    une d�finition de copeaux pour un alliage d�fini sur le produit termin�
  *    de l'ordre de fabrication.
  */
  function hasChipRecovery(inFalTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  as
    lnGcoGoodID     GCO_GOOD.GCO_GOOD_ID%type;
    hasPreciousMat  GCO_GOOD.GOO_PRECIOUS_MAT%type;
    ltt_GcoAlloyIDs ID_TABLE_TYPE;
    hasChipRecovery number                           default 0;
  begin
    /* R�cup�ration de la clef primaire du bien li� au lot de l'op�ration*/
    lnGcoGoodID  := FAL_LIB_BATCH.getGcoGoodID(inFalLotID => getFalLotID(inFalTaskLinkID => inFalTaskLinkID) );

    /* Si le bien contient des alliages de mati�re pr�cieuse */
    if GCO_I_LIB_PRECIOUS_MAT.doesContainsPreciousMat(inGcoGoodID => lnGcoGoodID) = 1 then
      /* R�cup�ration du nombre de d�finitions de copeaux de l'op�ration pour un alliage d�fini dans le produit fini */
      select count(gal.GCO_ALLOY_ID)
        into HasChipRecovery
        from GCO_ALLOY gal
           , GCO_PRECIOUS_MAT gpm
           , GCO_GOOD goo
           , FAL_LOT lot
           , FAL_TASK_LINK tal
           , FAL_TASK_CHIP_DETAIL tch
       where gal.GCO_ALLOY_ID = gpm.GCO_ALLOY_ID
         and gpm.GCO_GOOD_ID = goo.GCO_GOOD_ID
         and lot.GCO_GOOD_ID = goo.GCO_GOOD_ID
         and tal.FAL_LOT_ID = lot.FAL_LOT_ID
         and tal.FAL_SCHEDULE_STEP_ID = tch.FAL_TASK_LINK_ID
         and tch.GCO_ALLOY_ID = gal.GCO_ALLOY_ID
         and tal.FAL_SCHEDULE_STEP_ID = inFalTaskLinkID;

      if HasChipRecovery > 0 then
        return 1;
      else
        return 0;
      end if;
    else
      return 0;
    end if;
  end hasChipRecovery;

  /**
  * Description
  *    Retourne 1 si la pes�e des mati�res pr�cieuses est pr�vue pour l'op�ration
  *    de lot transmise en param�tre. (Le produit fini g�re la MP, contient au moins
  *    un alliage avec pes�e r��lle et une pes�e est pr�vue sur l'op�ration)
  */
  function isWeighingManaged(inFalTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  as
    lnIsWeighingManaged number := 0;
  begin
    /* Le produit termin� g�re-t-il la mati�re pr�cieuse ? */
    lnIsWeighingManaged  := FAL_LIB_BATCH.doesFPManagePreciousMat(inFalLotID => getFalLotID(inFalTaskLinkID => inFalTaskLinkID) );

    if lnIsWeighingManaged = 1 then
      /* Le produit termin� contient-il un alliage avec pes�e r��lle ? */
      lnIsWeighingManaged  := FAL_LIB_BATCH.doesFPContainsRealWeighedAlloy(inFalLotID => getFalLotID(inFalTaskLinkID => inFalTaskLinkID) );

      if lnIsWeighingManaged = 1 then
        /* Une pes�e est-elle pr�vue pour l'op�ration de lot transmise en param�tre ? */
        select nvl(SCS_WEIGH, 0)
          into lnIsWeighingManaged
          from FAL_TASK_LINK
         where FAL_SCHEDULE_STEP_ID = inFalTaskLinkID;
      end if;
    end if;

    return lnIsWeighingManaged;
  end isWeighingManaged;

  /**
  * Description
  *    Retourne 1 si la pes�e des mati�res pr�cieuses est obligatoire pour
  *    l'op�ration de lot transmise en param�tre.
  */
  function isWeighingMandatory(inFalTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  as
    lnIsWeighingMandatory number;
  begin
    select nvl(SCS_WEIGH_MANDATORY, 0)
      into lnIsWeighingMandatory
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = inFalTaskLinkID;

    return lnIsWeighingMandatory;
  end isWeighingMandatory;

  /**
  * Description
  *    Retourne l'ID de l'op�ration de lot en fonction du lot et de la s�quence
  *    transmise en param�tre.
  */
  function getTaskLinkIDbyStepAndLot(inFalLotID in FAL_TASK_LINK.FAL_LOT_ID%type, inScsStepNumber in FAL_TASK_LINK.SCS_STEP_NUMBER%type)
    return FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  as
    lnFalTaskLinkID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
  begin
    select FAL_SCHEDULE_STEP_ID
      into lnFalTaskLinkID
      from FAL_TASK_LINK
     where FAL_LOT_ID = inFalLotID
       and SCS_STEP_NUMBER = inScsStepNumber;

    return lnFalTaskLinkID;
  exception
    when no_data_found then
      return null;
  end getTaskLinkIDbyStepAndLot;

  /**
  * function hasLinkedCST
  * Description
  *    Retourne 1 si au moins une commande de sous-traitance op�ratoire est li�e � l'op�ration transmise en param�tre.
  *    Possibilit� de restreindre la recherche au niveau du statut du document.
  */
  function hasLinkedCST(iExternalTaskId in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type, iDocStatus in varchar2 default null)
    return integer
  as
    lHasLinedCST integer;
  begin
    select count('x')
      into lHasLinedCST
      from dual
     where exists(select column_value
                    from table(getLinkedCstDocsIDs(iExtTaskLinkID => iExternalTaskId, iDocStatus => iDocStatus) ) );

    return lHasLinedCST;
  end hasLinkedCST;

  /**
  * Description
  *    SOUS-TRAITANCE OP�RATOIRE (STO) : retourne les ID des commandes li�es � l'op�ration externe.
  *    Si iIncludeChild vaut 1, retourne �galements leur(s) descendant(s). Si iUntilMvtDoneSTO vaut 1, retourne
  *    leur(s) descendant(s) jusqu'au document contenant au moins un position g�n�rant les mouvements.
  *    iDocStatus permet de restreindre les CST concern�es sur leur statut.
  */
  function getLinkedCSTDocsIDs(
    iExtTaskLinkID   in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iIncludeChild    in number default 0
  , iUntilMvtDoneSTO in number default 0
  , iDocStatus       in varchar2 default null
  )
    return ID_TABLE_TYPE pipelined deterministic
  as
  begin
    /* Sous-traitance op�ratoire */
    /* S�lection identique � l'interrogation des document depuis l'op�ration de l'interrogation de lot. */
    for ltplDocsID in (select   doc.DOC_DOCUMENT_ID
                              , doc.C_DOCUMENT_STATUS
                           from DOC_DOCUMENT doc
                              , DOC_POSITION pos
                              , DOC_POSITION_DETAIL pde
                              , DOC_GAUGE gau
                          where pos.FAL_SCHEDULE_STEP_ID = iExtTaskLinkID
                            and pos.C_GAUGE_TYPE_POS in('1', '2', '3')
                            and doc.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                            and gau.DOC_GAUGE_ID = doc.DOC_GAUGE_ID
                            and pde.DOC_POSITION_ID = pos.DOC_POSITION_ID
                            and pde.DOC_DOC_POSITION_DETAIL_ID is null
                            and instr(',' || PCS.PC_CONFIG.getConfig('DOC_GAUGE_OP_SUBCONTRACT') || ',', ',' || gau.DIC_GAUGE_TYPE_DOC_ID || ',') > 0
                       group by doc.DOC_DOCUMENT_ID
                              , doc.C_DOCUMENT_STATUS
                       order by 1) loop
      if nvl(instr(iDocStatus, ltplDocsID.C_DOCUMENT_STATUS), 1) > 0 then
        pipe row(ltplDocsID.DOC_DOCUMENT_ID);   --CST

        if iIncludeChild = 1 then
          /* Liste des ID des enfants des CST */
          for ltplChildrenDmtNumbers in (select column_value
                                           from table(DOC_I_LIB_DOCUMENT.getDocChildrenIDList(iRootDocumentID    => ltplDocsID.DOC_DOCUMENT_ID
                                                                                            , iMaxSearchLevel    => 20
                                                                                            , iUntilMvtDoneSTO   => iUntilMvtDoneSTO
                                                                                            , iExtTaskLinkID     => iExtTaskLinkID
                                                                                             )
                                                     ) ) loop
            pipe row(ltplChildrenDmtNumbers.column_value);   -- BST, FST, ...
          end loop;
        end if;
      end if;
    end loop;
  exception
    when NO_DATA_NEEDED then
      return;
  end getLinkedCSTDocsIDs;

  /**
  * Description
  *    SOUS-TRAITANCE OP�RATOIRE (STO) : retourne les num�ro des commandes li�es � l'op�ration externe.
  *    Si iIncludeChild vaut 1, retourne �galements leur(s) descendant(s). Les num�ro sont
  *    s�par�s par le caract�re iSeparator. iDocStatus permet de restreindre les CST concern�es sur leur statut.
  */
  function getLinkedCSTDocs(
    iExtTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iSeparator     in varchar2 default '\'
  , iIncludeChild  in number default 0
  , iDocStatus     in varchar2 default null
  )
    return varchar2
  as
    lvDmtNumberList varchar2(4000);
    lvDmtNumber     DOC_DOCUMENT.DMT_NUMBER%type;
    lbFirstElement  boolean;
  begin
    lbFirstElement  := true;

    /* Si la config DOC_GAUGE_OP_SUBCONTRACT a une valeur du genre "A-CST,A-BST,A-FST" et que les A-CST sont d�charg�s dans a-BST,
       on aura les BST � double. Une fois � la recherche des documents li�s � l'op�ration (getLinkedCstDocsIDs) et une autre fois
       � la recherche des documents enfants (enfant de CST). D'o� le "distinct". */
    for ltplDmtNumbers in (select distinct column_value
                                      from table(getLinkedCstDocsIDs(iExtTaskLinkID   => iExtTaskLinkID, iIncludeChild => iIncludeChild
                                                                   , iDocstatus       => iDocStatus) )
                                  order by column_value) loop
      lvDmtNumber     :=
          FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(iv_entity_name   => 'DOC_DOCUMENT', iv_column_name => 'DMT_NUMBER'
                                                , it_pk_value      => ltplDmtNumbers.column_value);

      if lbFirstElement then
        lvDmtNumberList  := lvDmtNumber;
      else
        if (lengthb(lvDmtNumberList || ' ' || iSeparator || ' ' || lvDmtNumber) > 4000) then
          lvDmtNumberList  := substrb(lvDmtNumberList || ' ' || iSeparator || ' ' || lvDmtNumber, 1, 4000);
          return lvDmtNumberList;
        end if;

        lvDmtNumberList  := lvDmtNumberList || ' ' || iSeparator || ' ' || lvDmtNumber;
      end if;

      lbFirstElement  := false;
    end loop;

    return lvDmtNumberList;
  end getLinkedCSTDocs;

  /**
  * Description
  *    Indique si des commandes de sous-traitance sont attach�es � une op�ration externe du lot
  *    Possibilit� de restreindre la recherche au niveau du statut du document.
  */
  function hasLinkedCSTDocs(iLotID in FAL_LOT.FAL_LOT_ID%type, iDocStatus in varchar2 default null)
    return integer
  as
  begin
    for ltplTaskLink in (select FAL_SCHEDULE_STEP_ID
                           from FAL_TASK_LINK
                          where FAL_LOT_ID = iLotID
                            and C_TASK_TYPE = '2') loop
      if hasLinkedCST(ltplTaskLink.FAL_SCHEDULE_STEP_ID, iDocStatus) = 1 then
        return 1;
      end if;
    end loop;

    return 0;
  end hasLinkedCSTDocs;

  /**
  * Description
  *    SOUS-TRAITANCE OP�RATOIRE (STO) : retourne les ID des Bulletins de livraison/retour concernant les composants
  *    li�s � l'op�ration / au lot
  */
  function getLinkedBLSTDocsIDs(
    iExtTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iLotID         in FAL_TASK_LINK.FAL_LOT_ID%type default null
  , iStepNumber    in FAL_TASK_LINK.SCS_STEP_NUMBER%type default null
  )
    return ID_TABLE_TYPE pipelined deterministic
  as
    lLotID      FAL_TASK_LINK.FAL_LOT_ID%type;
    lStepNumber FAL_TASK_LINK.SCS_STEP_NUMBER%type;
  begin
    if iLotID is null then
      lLotID  := getFalLotID(inFalTaskLinkID => iExtTaskLinkID);
    else
      lLotID  := iLotID;
    end if;

    if iStepNumber is null then
      lStepNumber  := getStepNumber(iTaskLinkID => iExtTaskLinkID);
    else
      lStepNumber  := iStepNumber;
    end if;

    /* Liste des num�ro de documents de transfert de composant de composants du lot li�s � l'op�ration courante */
    for ltplBVDmtNumber in (select   lnk.DOC_DMT_TARGET_ID
                                from DOC_LINK lnk
                                   , FAL_LOT_MATERIAL_LINK lom
                               where lom.FAL_LOT_MATERIAL_LINK_ID = lnk.FAL_LOT_MATERIAL_LINK_ID
                                 and lom.FAL_LOT_ID = lLotID
                                 and lom.LOM_TASK_SEQ = lStepNumber
                                 and lnk.C_DOC_LINK_TYPE in('03', '04')
                            group by lnk.DOC_DMT_TARGET_ID) loop
      pipe row(ltplBVDmtNumber.DOC_DMT_TARGET_ID);
    end loop;
  exception
    when NO_DATA_NEEDED then
      return;
  end getLinkedBLSTDocsIDs;

  /**
  * Description
  *    SOUS-TRAITANCE OP�RATOIRE (STO) : retourne les num�ro Bulletins de livraison/retour concernant les composants
  *    li�s � l'op�ration / au lot. Les num�ro sont s�par�s par le caract�re iSeparator
  */
  function getLinkedBLSTDocs(
    iExtTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iLotID         in FAL_TASK_LINK.FAL_LOT_ID%type
  , iStepNumber    in FAL_TASK_LINK.SCS_STEP_NUMBER%type
  , iSeparator     in varchar2 default '\'
  )
    return varchar2
  as
    lvDmtNumberList varchar2(4000);
    lvDmtNumber     DOC_DOCUMENT.DMT_NUMBER%type;
    lbFirstElement  boolean;
  begin
    lbFirstElement  := true;

    for ltplDmtNumbers in (select column_value
                             from table(getLinkedBLSTDocsIDs(iExtTaskLinkID => iExtTaskLinkID, iLotID => iLotID, iStepNumber => iStepNumber) ) ) loop
      lvDmtNumber     :=
          FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(iv_entity_name   => 'DOC_DOCUMENT', iv_column_name => 'DMT_NUMBER'
                                                , it_pk_value      => ltplDmtNumbers.column_value);

      if lbFirstElement then
        lvDmtNumberList  := lvDmtNumber;
      else
        if (lengthb(lvDmtNumberList || ' ' || iSeparator || ' ' || lvDmtNumber) > 4000) then
          lvDmtNumberList  := substrb(lvDmtNumberList || ' ' || iSeparator || ' ' || lvDmtNumber, 1, 4000);
          return lvDmtNumberList;
        end if;

        lvDmtNumberList  := lvDmtNumberList || ' ' || iSeparator || ' ' || lvDmtNumber;
      end if;

      lbFirstElement  := false;
    end loop;

    return lvDmtNumberList;
  end getLinkedBLSTDocs;

  /**
  * Description
  *   SOUS-TRAITANCE ACHAT (STA) : retourne les ID des commandes li�es au lot. Si iIncludeChild vaut 1, retourne
  *   �galements leur(s) descendant(s).
  */
  function getLinkedSupoDocsIDs(iLotID in FAL_LOT.FAL_LOT_ID%type, iIncludeChild in number default 0)
    return ID_TABLE_TYPE pipelined deterministic
  is
  begin
    /* Sous-traitance d'achat */
    /* S�lection identique � l'interrogation des document depuis l'op�ration de l'interrogation de lot. */
    for ltplDocsID in (select   POS.DOC_DOCUMENT_ID
                           from DOC_POSITION POS
                              , DOC_GAUGE_POSITION GAP
                          where pos.FAL_LOT_ID = iLotID
                            and pos.C_GAUGE_TYPE_POS in('1', '2', '3')
                            and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
                            and GAP.C_DOC_LOT_TYPE = '001'
                            and DOC_I_LIB_SUBCONTRACTP.IsSUPOGauge(GAP.DOC_GAUGE_ID) = 1
                       group by POS.DOC_DOCUMENT_ID
                       order by 1) loop
      pipe row(ltplDocsID.DOC_DOCUMENT_ID);

      if iIncludeChild = 1 then
        /* Liste des ID des enfants des CAST's */
        for ltplChildrenDmtNumbers in (select column_value
                                         from table(DOC_I_LIB_DOCUMENT.getDocChildrenIDList(iRootDocumentID   => ltplDocsID.DOC_DOCUMENT_ID
                                                                                          , iMaxSearchLevel   => 1) ) ) loop
          pipe row(ltplChildrenDmtNumbers.column_value);
        end loop;
      end if;
    end loop;
  exception
    when NO_DATA_NEEDED then
      return;
  end getLinkedSupoDocsIDs;

  /**
  * Description
  *   SOUS-TRAITANCE ACHAT (STA) : retourne les num�ros des commandes li�es au lot. Si iIncludeChild vaut 1, retourne
  *   �galements leur(s) descendant(s). Les num�ros sont s�par�s par le caract�re iSeparator.
  */
  function getLinkedSupoDocs(iLotID in FAL_LOT.FAL_LOT_ID%type, iSeparator in varchar2 default '\', iIncludeChild in number default 0)
    return varchar2
  is
    lvDmtNumberList varchar2(4000);
    lvDmtNumber     DOC_DOCUMENT.DMT_NUMBER%type;
    lbFirstElement  boolean;
  begin
    lbFirstElement  := true;

    for ltplDmtNumbers in (select column_value
                             from table(getLinkedSupoDocsIDs(iLotID => iLotID, iIncludeChild => iIncludeChild) ) ) loop
      lvDmtNumber     :=
          FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(iv_entity_name   => 'DOC_DOCUMENT', iv_column_name => 'DMT_NUMBER'
                                                , it_pk_value      => ltplDmtNumbers.column_value);

      if lbFirstElement then
        lvDmtNumberList  := lvDmtNumber;
      else
        if (lengthb(lvDmtNumberList || ' ' || iSeparator || ' ' || lvDmtNumber) > 4000) then
          lvDmtNumberList  := substrb(lvDmtNumberList || ' ' || iSeparator || ' ' || lvDmtNumber, 1, 4000);
          return lvDmtNumberList;
        end if;

        lvDmtNumberList  := lvDmtNumberList || ' ' || iSeparator || ' ' || lvDmtNumber;
      end if;

      lbFirstElement  := false;
    end loop;

    return lvDmtNumberList;
  end getLinkedSupoDocs;

  /**
  * Description
  *    SOUS-TRAITANCE ACHAT (STA)t : retourne les ID des Bulletins de livraison/retour concernant les composants
  *    du lot.
  */
  function getLinkedSuprsDocsIDs(iLotID in FAL_TASK_LINK.FAL_LOT_ID%type default null)
    return ID_TABLE_TYPE pipelined deterministic
  is
  begin
    /* Sous-traitance d'achat */
    /* Pour chaque CAST li�e au lot */
    for ltplDocCast in (select column_value as DOC_DOCUMENT_ID
                          from table(getLinkedSupoDocsIDs(iLotID => iLotID) ) ) loop
      /* Liste des bulletins de livraison */
      for ltplDocsID in (select   DOC_DMT_TARGET_ID
                             from DOC_LINK
                            where DOC_DMT_SOURCE_ID = ltplDocCast.DOC_DOCUMENT_ID
                              and C_DOC_LINK_TYPE in('01', '02')
                         group by DOC_DMT_TARGET_ID
                         order by 1) loop
        pipe row(ltplDocsID.DOC_DMT_TARGET_ID);
      end loop;
    end loop;
  exception
    when NO_DATA_NEEDED then
      return;
  end getLinkedSuprsDocsIDs;

  /**
  * Description
  *    SOUS-TRAITANCE ACHAT (STA) : retourne les ID des Bulletins de livraison/retour concernant les composants
  *    du lot. Les num�ros sont s�par�s par le caract�re iSeparator.
  */
  function getLinkedSuprsDocs(iLotID in FAL_TASK_LINK.FAL_LOT_ID%type, iSeparator in varchar2 default '\')
    return varchar2
  is
    lvDmtNumberList varchar2(4000);
    lvDmtNumber     DOC_DOCUMENT.DMT_NUMBER%type;
    lbFirstElement  boolean;
  begin
    lbFirstElement  := true;

    for ltplDmtNumbers in (select column_value
                             from table(getLinkedSuprsDocsIDs(iLotID => iLotID) ) ) loop
      lvDmtNumber     :=
          FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(iv_entity_name   => 'DOC_DOCUMENT', iv_column_name => 'DMT_NUMBER'
                                                , it_pk_value      => ltplDmtNumbers.column_value);

      if lbFirstElement then
        lvDmtNumberList  := lvDmtNumber;
      else
        if (lengthb(lvDmtNumberList || ' ' || iSeparator || ' ' || lvDmtNumber) > 4000) then
          lvDmtNumberList  := substrb(lvDmtNumberList || ' ' || iSeparator || ' ' || lvDmtNumber, 1, 4000);
          return lvDmtNumberList;
        end if;

        lvDmtNumberList  := lvDmtNumberList || ' ' || iSeparator || ' ' || lvDmtNumber;
      end if;

      lbFirstElement  := false;
    end loop;

    return lvDmtNumberList;
  end getLinkedSuprsDocs;

  /**
  * Description
  *   STA + STO : retourne les num�ros des commandes li�es � L'op�ration externe / au lot.
  *   Si iIncludeChild vaut 1, retourne �galements leur(s) descendant(s).
  *   Les num�ro sont s�par�s par le caract�re iSeparator.
  */
  function getLinkedOrderDocs(
    iLotID        in FAL_TASK_LINK.FAL_LOT_ID%type default null
  , iTaskID       in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type default null
  , iSeparator    in varchar2 default '\'
  , iIncludeChild in number default 0
  )
    return varchar2
  is
    lvDocsList  varchar2(4000);
    lvTempList1 varchar2(4000);
    lvTempList2 varchar2(4000);
    lvTempList3 varchar2(4000);
  begin
    lvDocsList   := null;

    /***** Sous-traitance op�ratoire *****/
    if iTaskID is not null then
      /* Recherche des CSTs li�es � l'op�ration externe transmise */
      lvTempList1  := getLinkedCSTDocs(iExtTaskLinkID => iTaskID, iSeparator => iSeparator, iIncludeChild => iIncludeChild);
    elsif iLotID is not null then
      /* Recherche des CSTs li�es aux op�rations externes du lot */
      for ltplExternalTask in (select FAL_SCHEDULE_STEP_ID
                                 from FAL_TASK_LINK
                                where FAL_LOT_ID = iLotID
                                  and C_TASK_TYPE = FAL_OPERATION_FUNCTIONS.ttExternal) loop
        if lvTempList1 is not null then
          if (lengthb(lvTempList1 || iSeparator) > 4000) then
            return lvTempList1;
          end if;

          lvTempList1  := lvTempList1 || iSeparator;
        end if;

        lvTempList3  := getLinkedCSTDocs(iExtTaskLinkID => ltplExternalTask.FAL_SCHEDULE_STEP_ID, iSeparator => iSeparator, iIncludeChild => iIncludeChild);

        if (lengthb(lvTempList1 || lvTempList3) > 4000) then
          lvTempList1  := substrb(lvTempList1 || lvTempList3, 1, 4000);
          return lvTempList1;
        end if;

        lvTempList1  := lvTempList1 || lvTempList3;
      end loop;
    else
      ra(PCS.PC_FUNCTIONS.TranslateWord('PCS - FAL_LIB_TASK_LINK.getLinkedOrderDocs : Le lot ou l''op�ration doivent �tre d�finis !') );
    end if;

    /***** Sous-traitance d'achat *****/
    lvTempList2  := getLinkedSupoDocs(iLotID => iLotID, iSeparator => iSeparator, iIncludeChild => iIncludeChild);

    if     lvTempList1 is not null
       and lvTempList2 is not null then
      if (lengthb(lvTempList1 || ' ' || iSeparator || ' ' || lvTempList2) > 4000) then
        lvDocsList  := substrb(lvTempList1 || ' ' || iSeparator || ' ' || lvTempList2, 1, 4000);
        return lvDocsList;
      end if;

      lvDocsList  := lvTempList1 || ' ' || iSeparator || ' ' || lvTempList2;
    else
      lvDocsList  := nvl(lvTempList1, lvTempList2);
    end if;

    return lvDocsList;
  end getLinkedOrderDocs;

  /**
  * Description
  *   STA + STO : retourne les ID des bulletins de livraison/retour li�s � L'op�ration externe / au lot.
  *   Les num�ro sont s�par�s par le caract�re iSeparator.
  */
  function getLinkedDelivReturnDocs(
    iLotID         in FAL_TASK_LINK.FAL_LOT_ID%type
  , iExtTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iStepNumber    in FAL_TASK_LINK.SCS_STEP_NUMBER%type
  , iSeparator     in varchar2 default '\'
  )
    return varchar2
  is
    lvDocsList  varchar2(4000);
    lvTempList1 varchar2(4000);
    lvTempList2 varchar2(4000);
  begin
    lvDocsList   := null;
    -- Sous-traitance op�ratoire
    lvTempList1  := getLinkedBLSTDocs(iExtTaskLinkID => iExtTaskLinkID, iLotID => iLotID, iStepNumber => iStepNumber, iSeparator => iSeparator);
    -- Sous-traitance d'achat
    lvTempList2  := getLinkedSuprsDocs(iLotID => iLotID, iSeparator => iSeparator);

    if     lvTempList1 is not null
       and lvTempList2 is not null then
      if (lengthb(lvTempList1 || ' ' || iSeparator || ' ' || lvTempList2) > 4000) then
        lvDocsList  := substrb(lvTempList1 || ' ' || iSeparator || ' ' || lvTempList2, 1, 4000);
        return lvDocsList;
      end if;

      lvDocsList  := lvTempList1 || ' ' || iSeparator || ' ' || lvTempList2;
    else
      lvDocsList  := nvl(lvTempList1, lvTempList2);
    end if;

    return lvDocsList;
  end getLinkedDelivReturnDocs;

  /**
  * Description
  *    Limite la longueur d'une chaine de caract�res.
  */
  function truncateStrValue(iValue in varchar2, iLength in number default 255)
    return varchar2
  is
    lvResult varchar(4000);
  begin
    if lengthb(iValue) > iLength then
      lvResult  := substrb(iValue, 1, iLength - 3);
      lvResult  := lvResult || '...';
    else
      lvResult  := iValue;
    end if;

    return lvResult;
  end truncateStrValue;

  /**
  * Description
  *    Retourne 1 si au moins un composant est li� � l'op�ration.
  */
  function hasLinkedComponents(iExtTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  as
    lHasLinkedComponents number;
  begin
    select sign(count(FAL_LOT_MATERIAL_LINK_ID) )
      into lHasLinkedComponents
      from FAL_LOT_MATERIAL_LINK lom
         , FAL_TASK_LINK tal
     where FAL_SCHEDULE_STEP_ID = iExtTaskLinkID
       and lom.FAL_LOT_ID = tal.FAL_LOT_ID
       and lom.LOM_TASK_SEQ = tal.SCS_STEP_NUMBER;

    return lHasLinkedComponents;
  exception
    when no_data_found then
      return 0;
  end hasLinkedComponents;

  /**
  * Description
  *    Retourne la quantit� planifi�e de l'op�ration.
  */
  function getPlanedQty(iTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_TASK_LINK.TAL_PLAN_QTY%type
  as
    lPlanedQty FAL_TASK_LINK.TAL_RELEASE_QTY%type;
  begin
    select nvl(TAL_PLAN_QTY, 0)
      into lPlanedQty
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = iTaskLinkID;

    return lPlanedQty;
  exception
    when no_data_found then
      return 0;
  end getPlanedQty;

  /**
  * Description
  *    Retourne la quantit� en cours de l'op�ration.
  */
  function getSubcontractQty(iTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_TASK_LINK.TAL_SUBCONTRACT_QTY%type
  as
    lSubcontractQty FAL_TASK_LINK.TAL_SUBCONTRACT_QTY%type;
  begin
    select nvl(TAL_SUBCONTRACT_QTY, 0)
      into lSubcontractQty
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = iTaskLinkID;

    return lSubcontractQty;
  exception
    when no_data_found then
      return 0;
  end getSubcontractQty;

  /**
  * Description
  *    Retourne la quantit� r�alis�e de l'op�ration.
  */
  function getReleaseQty(iTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_TASK_LINK.TAL_RELEASE_QTY%type
  as
    lReleaseQty FAL_TASK_LINK.TAL_RELEASE_QTY%type;
  begin
    select nvl(TAL_RELEASE_QTY, 0)
      into lReleaseQty
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = iTaskLinkID;

    return lReleaseQty;
  exception
    when no_data_found then
      return 0;
  end getReleaseQty;

  /**
  * Description
  *    Cette function retourne le type d'op�ration (C_TASK_TYPE = interne ou externe)
  */
  function getCTaskType(iTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_TASK_LINK.C_TASK_TYPE%type
  as
    lCTaskType FAL_TASK_LINK.C_TASK_TYPE%type;
  begin
    select C_TASK_TYPE
      into lCTaskType
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = iTaskLinkID;

    return lCTaskType;
  exception
    when no_data_found then
      return null;
  end getCTaskType;

  /**
  * Description
  *    Retourne le type de l'op�ration (C_OPERATION_TYPE = principale, secondaire, ...)
  */
  function getCOperationType(iTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_TASK_LINK.C_OPERATION_TYPE%type
  as
    lCOperationType FAL_TASK_LINK.C_OPERATION_TYPE%type;
  begin
    select C_OPERATION_TYPE
      into lCOperationType
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = iTaskLinkID;

    return lCOperationType;
  exception
    when no_data_found then
      return null;
  end getCOperationType;

  /**
  * Description
  *    Retourne la t�che principale pr�c�dente.
  */
  function getPreviousMainTaskID(iTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  as
    lPreviousMainTaskID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
  begin
    select previous.FAL_SCHEDULE_STEP_ID
      into lPreviousMainTaskID
      from FAL_TASK_LINK previous
     where previous.FAL_LOT_ID = fal_lib_task_link.getFalLotID(inFalTaskLinkID => iTaskLinkID)
       and previous.SCS_STEP_NUMBER =
               (select max(SCS_STEP_NUMBER)
                  from FAL_TASK_LINK
                 where FAL_LOT_ID = previous.FAL_LOT_ID
                   and C_OPERATION_TYPE = '1'   -- Principale
                   and SCS_STEP_NUMBER < (select SCS_STEP_NUMBER
                                            from FAL_TASK_LINK
                                           where FAL_SCHEDULE_STEP_ID = iTaskLinkID) );

    return lPreviousMainTaskID;
  exception
    when no_data_found then
      return null;
  end getPreviousMainTaskID;

  /**
  * Description
  *    Retourne la t�che principale pr�c�dente.
  */
  function getPreviousTaskId(iTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type, iTypeOpe varchar default '1')
    return FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  as
    lPreviousMainTaskID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
  begin
    select previous.FAL_SCHEDULE_STEP_ID
      into lPreviousMainTaskID
      from FAL_TASK_LINK previous
     where previous.FAL_LOT_ID = fal_lib_task_link.getFalLotID(inFalTaskLinkID => iTaskLinkID)
       and previous.SCS_STEP_NUMBER =
             (select max(SCS_STEP_NUMBER)
                from FAL_TASK_LINK
               where FAL_LOT_ID = previous.FAL_LOT_ID
                 and (instr(iTypeOpe, C_OPERATION_TYPE) > 0)   -- d�faut '1' = Principale
                 and SCS_STEP_NUMBER < (select SCS_STEP_NUMBER
                                          from FAL_TASK_LINK
                                         where FAL_SCHEDULE_STEP_ID = iTaskLinkID) );

    return lPreviousMainTaskID;
  exception
    when no_data_found then
      return null;
  end getPreviousTaskId;

  /**
  * Description
  *    Retourne la t�che principale pr�c�dente.
  */
  function getPreviousMainTaskSeq(iLotID in FAL_TASK_LINK.FAL_LOT_ID%type, iCurrentTaskSeq in FAL_TASK_LINK.SCS_STEP_NUMBER%type)
    return FAL_TASK_LINK.SCS_STEP_NUMBER%type
  as
    cursor lcurPreviousMainTaskSeq
    is
      select   SCS_STEP_NUMBER
          from FAL_TASK_LINK
         where FAL_LOT_ID = iLotID
           and C_OPERATION_TYPE = '1'
           and SCS_STEP_NUMBER < iCurrentTaskSeq
      order by SCS_STEP_NUMBER desc;

    lPreviousMainTaskSeq FAL_TASK_LINK.SCS_STEP_NUMBER%type;
  begin
    open lcurPreviousMainTaskSeq;

    fetch lcurPreviousMainTaskSeq
     into lPreviousMainTaskSeq;

    close lcurPreviousMainTaskSeq;

    return lPreviousMainTaskSeq;
  exception
    when others then
      close lcurPreviousMainTaskSeq;

      return null;
  end getPreviousMainTaskSeq;

  /**
  * Description
  *    Retourne l'Id de l'op�ration principale suivante.
  */
  function getNextMainTaskID(iCurrentTaskSeq in FAL_TASK_LINK.SCS_STEP_NUMBER%type, iLotID in FAL_TASK_LINK.FAL_LOT_ID%type default null)
    return FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  as
    lReturnValue FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type   := null;
  begin
    for ltplNextMainTask in (select   FAL_SCHEDULE_STEP_ID
                                 from FAL_TASK_LINK
                                where FAL_LOT_ID = nvl(iLotID, FAL_LIB_TASK_LINK.getFalLotID(inFalTaskLinkID => iCurrentTaskSeq) )
                                  and C_OPERATION_TYPE = '1'   -- Principale
                                  and SCS_STEP_NUMBER > (select SCS_STEP_NUMBER
                                                           from FAL_TASK_LINK
                                                          where FAL_SCHEDULE_STEP_ID = iCurrentTaskSeq)
                             order by SCS_STEP_NUMBER asc) loop
      lReturnValue  := ltplNextMainTask.FAL_SCHEDULE_STEP_ID;
      exit;   --TODO : Am�liorer avec Oracle 12c qui permet de faire un 'select ... fetch first X rows only' retournant les X premi�res lignes.
    end loop;

    return lReturnValue;
  end getNextMainTaskID;

  /**
  * Description
  *    Retourne la t�che principale suivante.
  */
  function getNextMainTaskSeq(iLotID in FAL_TASK_LINK.FAL_LOT_ID%type, iCurrentTaskSeq in FAL_TASK_LINK.SCS_STEP_NUMBER%type)
    return FAL_TASK_LINK.SCS_STEP_NUMBER%type
  as
    cursor lcurNextMainTaskSeq
    is
      select   SCS_STEP_NUMBER
          from FAL_TASK_LINK
         where FAL_LOT_ID = iLotID
           and C_OPERATION_TYPE = '1'
           and SCS_STEP_NUMBER > iCurrentTaskSeq
      order by SCS_STEP_NUMBER asc;

    lNextMainTaskSeq FAL_TASK_LINK.SCS_STEP_NUMBER%type;
  begin
    open lcurNextMainTaskSeq;

    fetch lcurNextMainTaskSeq
     into lNextMainTaskSeq;

    close lcurNextMainTaskSeq;

    return lNextMainTaskSeq;
  exception
    when others then
      close lcurNextMainTaskSeq;

      return null;
  end getNextMainTaskSeq;

  /**
  * Description
  *    Retourne 1 si l'op�ration transmise existe.
  */
  function taskExists(iTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  as
    lTaskExists number;
  begin
    select sign(FAL_SCHEDULE_STEP_ID)
      into lTaskExists
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = iTaskLinkID;

    return 1;
  exception
    when no_data_found then
      return 0;
  end taskExists;

  /**
  * Description
  *    Retourne 1 si l'op�ration transmise est la premi�re t�che de la gamme du lot.
  *    Par d�faut on recherche si c'est la premi�re "Principale" (iTypeOp = '1')
  */
  function isFirstOp(iTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type, iTypeOp in varchar default '1')
    return number
  as
    lnFirstOpId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
  begin
    select FTL.FAL_SCHEDULE_STEP_ID
      into lnFirstOpId
      from FAL_TASK_LINK FTL
     where FAL_LOT_ID = fal_lib_task_link.getFalLotID(iTaskLinkID)
       and FTL.SCS_STEP_NUMBER = (select min(SCS_STEP_NUMBER)
                                    from FAL_TASK_LINK
                                   where FAL_LOT_ID = FTL.FAL_LOT_ID
                                     and (instr(iTypeOp, C_OPERATION_TYPE) > 0) );   -- d�faut '1' = Principale

    if iTaskLinkID = lnFirstOpId then
      return 1;
    end if;

    return 0;
  end isFirstOp;

  /**
  * Description
  *    Retourne 1 Si l'op�ration de lot est externe (C_TASK_TYPE = '2')
  */
  function isExternal(iLotID in FAL_TASK_LINK.FAL_LOT_ID%type, iScsStepNumber in FAL_TASK_LINK.SCS_STEP_NUMBER%type)
    return number
  as
  begin
    if getCTaskType(iTaskLinkID => getTaskLinkIDbyStepAndLot(inFalLotID => iLotID, inScsStepNumber => iScsStepNumber) ) = '2' then
      return 1;
    else
      return 0;
    end if;
  end isExternal;

  /**
  * Description
  *    Portefeuille : Retourne 1 si au moins une op�ration a �t� s�lectionn� pour un fournisseur
  */
  function TaskIsSelectionned(iPacSuplierPartnerID in PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type)
    return number
  as
    lnTaskSelectionned number;
  begin
    select sign(nvl(max(FTL.FAL_SCHEDULE_STEP_ID), 0) )
      into lnTaskSelectionned
      from FAL_TASK_LINK FTL
     where FTL.PAC_SUPPLIER_PARTNER_ID = iPacSuplierPartnerID
       and FTL.TAL_SUBCONTRACT_SELECT = 1;

    return lnTaskSelectionned;
  end TaskIsSelectionned;

  /**
  * Description
  *    Portefeuille : Retourne 1 si au moins une op�ration avec PCST a �t� s�lectionn�
  */
  function TaskWithPcstIsSelectionned
    return number
  as
    lnTaskSelectionned number;
  begin
    select sign(nvl(max(FTL.FAL_SCHEDULE_STEP_ID), 0) )
      into lnTaskSelectionned
      from FAL_TASK_LINK FTL
         , COM_LIST_ID_TEMP LID
     where LID.COM_LIST_ID_TEMP_ID = FTL.FAL_SCHEDULE_STEP_ID
       and LID.LID_CODE = 'PCST_BATCH'
       and FTL.TAL_PCST_NUMBER is not null
       and LID.LID_SELECTION = 1;

    return lnTaskSelectionned;
  end TaskWithPcstIsSelectionned;

  /**
  * Description
  *    Retourne le fournisseur li� � l'op�ration de lot transmise.
  */
  function getSupplierPartnerID(iTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_TASK_LINK.PAC_SUPPLIER_PARTNER_ID%type
  as
    lSupplierPartnerID FAL_TASK_LINK.PAC_SUPPLIER_PARTNER_ID%type;
  begin
    select PAC_SUPPLIER_PARTNER_ID
      into lSupplierPartnerID
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = iTaskLinkID;

    return lSupplierPartnerID;
  exception
    when no_data_found then
      return null;
  end getSupplierPartnerID;

  /**
  * Description
  *    Retourne la quantit� de rebuts PT du lot � valoriser sur l'op�ration en tenant compte de
  *    la quantit� en r�ception qui peut �tre partielle (ex : on ne r�ceptionne que deux pi�ces
  *    sur les 6 pi�ces d�clar�es en rebut, il faut donc diviser le r�sultat par 3).
  *    Les rebuts comptabilis�s sont les pi�ces sur lesquelles l'op�ration a �t� faites. On prend
  *    donc les quantit�s sur l'op�rations et sur les suivantes.
  */
  function getRejectedProductDone(iLotID in FAL_TASK_LINK.FAL_LOT_ID%type, iTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type, iReceptQty in number)
    return number
  as
    lRejectedProductDone number;
  begin
    select sum(flp.FLP_PT_REJECT_QTY) * iReceptQty / case max(nvl(lot.LOT_PT_REJECT_QTY, 0) )
             when 0 then iReceptQty
             else max(lot.LOT_PT_REJECT_QTY)
           end QTY
      into lRejectedProductDone
      from FAL_TASK_LINK tal
         , FAL_LOT_PROGRESS flp
         , FAL_LOT lot
     where lot.FAL_LOT_ID = iLotID
       and tal.FAL_LOT_ID = lot.FAL_LOT_ID
       and flp.FAL_SCHEDULE_STEP_ID = tal.FAL_SCHEDULE_STEP_ID
       and tal.SCS_STEP_NUMBER >= (select SCS_STEP_NUMBER
                                     from FAL_TASK_LINK
                                    where FAL_SCHEDULE_STEP_ID = iTaskLinkID);

    return lRejectedProductDone;
  end getRejectedProductDone;

  /**
  * Description
  *    Retourne la quantit� disponible sur l'op�ration de lot
  */
  function getAvailableQty(iTaskLinkID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_TASK_LINK.TAL_AVALAIBLE_QTY%type
  as
    lAvailableQty FAL_TASK_LINK.TAL_AVALAIBLE_QTY%type;
  begin
    select nvl(TAL_AVALAIBLE_QTY, 0)
      into lAvailableQty
      from FAL_TASK_LINK
     where FAL_SCHEDULE_STEP_ID = iTaskLinkID;

    return lAvailableQty;
  exception
    when no_data_found then
      return 0;
  end getAvailableQty;

  /**
  * Description
  *    Retourne la s�quence de la derni�re op�ration du lot.
  */
  function getLastStepNumber(iLotID in FAL_TASK_LINK.FAL_LOT_ID%type)
    return FAL_TASK_LINK.SCS_STEP_NUMBER%type
  as
    lLastStepNumber FAL_TASK_LINK.SCS_STEP_NUMBER%type;
  begin
    select max(SCS_STEP_NUMBER)
      into lLastStepNumber
      from FAL_TASK_LINK
     where FAL_LOT_ID = iLotID;

    return lLastStepNumber;
  end getLastStepNumber;

  /**
  * fonction getMinutesWorkBalance
  * Description
  *    Retourne le solde du temps op�ratoire d'une op�ration.
  */
  function getMinutesWorkBalance(
    iC_TASK_TYPE             in FAL_TASK_LINK.C_TASK_TYPE%type
  , iTAL_TSK_AD_BALANCE      in FAL_TASK_LINK.TAL_TSK_AD_BALANCE%type
  , iTAL_TSK_W_BALANCE       in FAL_TASK_LINK.TAL_TSK_W_BALANCE%type
  , iTAL_NUM_UNITS_ALLOCATED in FAL_TASK_LINK.TAL_NUM_UNITS_ALLOCATED%type
  , iSCS_TRANSFERT_TIME      in FAL_TASK_LINK.SCS_TRANSFERT_TIME%type
  , iSCS_OPEN_TIME_MACHINE   in FAL_TASK_LINK.SCS_OPEN_TIME_MACHINE%type default 0
  , iFAC_DAY_CAPACITY        in FAL_FACTORY_FLOOR.FAC_DAY_CAPACITY%type default 0
  )
    return number
  as
    lResult number;
  begin
    if iC_TASK_TYPE = '2' then
      return 0;
    end if;

    lResult  :=
      (nvl(iTAL_TSK_AD_BALANCE, 0) + nvl(iTAL_TSK_W_BALANCE, 0) / FAL_TOOLS.nvla(iTAL_NUM_UNITS_ALLOCATED, 1) + nvl(iSCS_TRANSFERT_TIME, 0) ) *
      FAL_LIB_CONSTANT.gcCfgWorkUnit;

    -- Utilisation du temps d'ouverture machine. On calcule la dur�e de r�alisation en fonction de ce temps et de la capacit� jour de l'atelier
    if     FAL_LIB_CONSTANT.gcCfgUseOpenTimeMachine
       and nvl(iSCS_OPEN_TIME_MACHINE, 0) > 0 then
      lResult  := lResult * nvl(iFAC_DAY_CAPACITY, 0) / iSCS_OPEN_TIME_MACHINE;
    end if;

    return ceil(lResult);
  end getMinutesWorkBalance;

  /**
  * fonction getDaysDuration
  * Description
  *    Retourne la dur�e en jour d'une op�ration
  */
  function getDaysDuration(
    iSCS_PLAN_PROP           in FAL_TASK_LINK.SCS_PLAN_PROP%type
  , iTAL_PLAN_RATE           in FAL_TASK_LINK.TAL_PLAN_RATE%type
  , iTAL_NUM_UNITS_ALLOCATED in FAL_TASK_LINK.TAL_NUM_UNITS_ALLOCATED%type
  , iSCS_PLAN_RATE           in FAL_TASK_LINK.SCS_PLAN_RATE%type
  )
    return number
  as
  begin
    if iSCS_PLAN_PROP = 1 then
      -- si dur�e proportionnelle (planification proportionnelle) : Cadencement * unit� de cadencement / Ressources affect�es
      return (nvl(iTAL_PLAN_RATE, 0) * FAL_LIB_CONSTANT.gcCfgPpsRateDay) / FAL_TOOLS.NvlA(iTAL_NUM_UNITS_ALLOCATED, 1);
    else   -- sinon (planification fixe) : dur�e planifi�e en jour * unti� de cadencement
      return nvl(iSCS_PLAN_RATE, 0) * FAL_LIB_CONSTANT.gcCfgPpsRateDay;
    end if;
  end getDaysDuration;

  /**
  * fonction getPrevTotalDueQty
  * Description
  *    Retourne la quantit� solde totale sur les op�rations pr�c�dentes.
  */
  function getPrevTotalDueQty(iTaskID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  as
    lRes number;
  begin
    select nvl(QTE_SOLDE, 0)
      into lRes
      from (select sum(TAL_DUE_QTY) over(partition by FAL_LOT_ID order by SCS_STEP_NUMBER rows between unbounded preceding and 1 preceding) QTE_SOLDE
                 , FAL_SCHEDULE_STEP_ID
              from FAL_TASK_LINK where fal_lot_id in (select fal_lot_id from fal_task_link where fal_schedule_step_id = iTaskID))
     where FAL_SCHEDULE_STEP_ID = iTaskID;

    return lRes;
  end getPrevTotalDueQty;

  /**
  * fonction GetAvailQty
  * Description
  *    Return the available quantity (calculated) of a batch operation
  */
  function GetAvailQty(iTaskId in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_TASK_LINK.TAL_AVALAIBLE_QTY%type
  is
    lnAvailQty FAL_TASK_LINK.TAL_AVALAIBLE_QTY%type   := 0;
  begin
    /* - Pour la premi�re op�ration : qt� due - qt� en-cours - qt� sur les op�ration ind�pendantes pr�c�dentes
       - Si type op�ration secondaire (2) : toujours = � 0
       - Si op�ration ind�pendante (4) : toujours = � la quantit� due
       - Dans tous les autres cas : Qt� r�alis�e sur l'op�ration principale pr�c�dente
                                    - l'en-cours - le r�alis� - le rebut - qt� sur les op�ration ind�pendantes pr�c�dentes */
    select case isFirstOp(FAL_SCHEDULE_STEP_ID)
             when 1 then greatest(0, TAL_DUE_QTY - nvl(TAL_SUBCONTRACT_QTY, 0) - getAvailOnSecOpeLnk(FTL.FAL_LOT_ID, FTL.SCS_STEP_NUMBER) )
             else case C_OPERATION_TYPE
             when '2' then 0
             when '4' then TAL_DUE_QTY - nvl(TAL_SUBCONTRACT_QTY, 0)
             else greatest(0
                         , ( (select TAL_RELEASE_QTY
                                from FAL_TASK_LINK
                               where FAL_SCHEDULE_STEP_ID = getPreviousTaskId(FTL.FAL_SCHEDULE_STEP_ID) ) -
                            nvl(TAL_SUBCONTRACT_QTY, 0) -
                            TAL_RELEASE_QTY -
                            TAL_REJECTED_QTY -
                            getAvailOnSecOpeLnk(FAL_LOT_ID, SCS_STEP_NUMBER)
                           )
                          )
           end
           end
      into lnAvailQty
      from FAL_TASK_LINK FTL
     where FAL_SCHEDULE_STEP_ID = iTaskId;

    return lnAvailQty;
  end GetAvailQty;

  /**
  * fonction getAvailOnSecOpeLnk
  * Description
  *    Return the available quantity of the independant operations placed juste before the operation
  */
  function getAvailOnSecOpeLnk(iBatchId in FAL_TASK_LINK.FAL_LOT_ID%type, iSeq in FAL_TASK_LINK.SCS_STEP_NUMBER%type)
    return FAL_TASK_LINK.TAL_AVALAIBLE_QTY%type
  is
    lnTotAvailQty FAL_TASK_LINK.TAL_AVALAIBLE_QTY%type   := 0;
  begin
    for tplSecOpLinked in (select   C_OPERATION_TYPE
                                  , (TAL_DUE_QTY + TAL_R_METER) AVAIL_QTY
                               from FAL_TASK_LINK
                              where FAL_LOT_ID = iBatchId
                                and SCS_STEP_NUMBER < iSeq
                           order by SCS_STEP_NUMBER desc) loop
      /* - Si op�ration secondaire (4), on aditionne
         - Si op�ration principale (1), on sort
         - Si op�ration secondaire (2), on passe � l'enregistrement suivant */
      if tplSecOpLinked.C_OPERATION_TYPE = '4' then
        lnTotAvailQty  := lnTotAvailQty + tplSecOpLinked.AVAIL_QTY;
      elsif tplSecOpLinked.C_OPERATION_TYPE = '1' then
        return lnTotAvailQty;
      end if;
    end loop;

    return lnTotAvailQty;
  end getAvailOnSecOpeLnk;

  /**
  * fonction doCalculateRemainingTime
  * Description
  *     Si les conditions ci-dessous sont remplies, la date de d�but de l'op�ration (d�lai de commande) est ramen�e � la date du jour.
  *     Conditions :
  *     1. l'op�ration est externe
  *     2. le d�lai de commande est dans le pass�
  *     3. le lot est lanc�
  *     4. il existe au moins un CST li�e confirm�e (= avec statut diff�rent de '� confirmer')
  *     5. toutes les op�rations pr�c�dentes sont r�alis�es (ou l'op�ration est en premi�re position) (Somme TAL_DUE_QTY des op. pr�c�dente = 0)
  */
  function doCalculateRemainingTime(
    iLotId             in FAL_GAN_TASK.FAL_LOT_ID%type
  , iTaskId            in FAL_GAN_OPERATION.FAL_SCHEDULE_STEP_ID%type
  , itaskType          in FAL_GAN_OPERATION.C_TASK_TYPE%type
  , iTaskBeginPlanDate in FAL_GAN_OPERATION.FGO_PLAN_START_DATE%type
  )
    return number
  as
  begin
    if     (iLotId is not null)
       and (nvl(iTaskType, '0') = 2)
       and (iTaskBeginPlanDate < sysdate)
       and (FAL_LIB_BATCH.isBatchLaunched(iLotId) )
       and (hasLinkedCST(iTaskId, '02,03,04,') = 1)
       and (getPrevTotalDueQty(iTaskId) = 0) then
      return 1;
    end if;

    return 0;
  end doCalculateRemainingTime;
end FAL_LIB_TASK_LINK;
