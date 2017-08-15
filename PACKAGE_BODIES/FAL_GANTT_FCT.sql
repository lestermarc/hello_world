--------------------------------------------------------
--  DDL for Package Body FAL_GANTT_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_GANTT_FCT" 
is
  cursor crOperations(iSessionID in number)
  is
    select   FAL_GAN_TASK_ID
           , FAL_GAN_OPERATION_ID
           , FGO_PARALLEL
           , FGO_DURATION
           , lag(FGO_DURATION, 1, 1) over(partition by FAL_GAN_TASK_ID order by FAL_GAN_OPERATION_ID) as PREVIOUS_DURATION
           , lead(FAL_GAN_OPERATION_ID, 1, null) over(partition by FAL_GAN_TASK_ID order by FAL_GAN_OPERATION_ID) as NEXT_OPERATION_ID
           , FGO_TRANSFERT_TIME
           , FGO_STEP_NUMBER
        from FAL_GAN_OPERATION
       where FAL_GAN_SESSION_ID = iSessionID
    order by FAL_GAN_TASK_ID
           , FGO_STEP_NUMBER;

  cursor CrLinks
  is
    select FAL_GAN_LINK_ID
         , C_LINK_TYPE
         , FAL_GAN_PRED_OPERATION_ID
         , FAL_GAN_SUCC_OPERATION_ID
         , FAL_GAN_SUCC_OPERATION_ID FAL_GAN_NEXT_SUCC_OPERATION_ID
      from FAL_GAN_LINK;

  type TOperations is table of crOperations%rowtype
    index by binary_integer;

  type TLinks is table of CrLinks%rowtype
    index by binary_integer;

  /**
  * procedure pConvertDelayIntoQty
  * Description :
  *    Conversion du retard de parall�lisme des op�rations en qt� par 100 pi�ces. Dans le Gantt, le retard se compte en X
  *    pi�ces sur Y par rapport � l'op�tion pr�c�dente, Y �tant d�fini par convention � 100. FGO_PARALLEL d�finit � partir
  *    de combien de pi�ces l'op. parall�le peut commencer (-2 = pas de retard)
  * @created ECA
  * @lastUpdate age 21.05.2014
  * @private
  * @param iSessionID : Identifiant unique de la session concern�e.
  * @return : Le retard en quantit� par 100 pi�ces.
  */
  procedure pConvertDelayIntoQty(iSessionID in number)
  is
  begin
    update FAL_GAN_OPERATION FGO
       set FGO.FGO_PARALLEL =
             100 *
             FGO.FGO_PARALLEL /
             (select FGO1.FGO_DURATION
                from FAL_GAN_OPERATION FGO1
               where FGO1.FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID
                 and FGO1.FGO_STEP_NUMBER = (select max(FGO2.FGO_STEP_NUMBER)
                                               from FAL_GAN_OPERATION FGO2
                                              where FGO2.FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID
                                                and FGO2.FGO_STEP_NUMBER < FGO.FGO_STEP_NUMBER))
     where nvl(FGO.FGO_PARALLEL, 0) > 0
       and FGO.FAL_GAN_SESSION_ID = iSessionID;
  end pConvertDelayIntoQty;

  /**
  * fonction pGetConvertQtyIntoDelay
  * Description
  *    Conversion du retard de parall�lisme en temp.
  * @created age 19.06.2013
  * @lastUpdate age 30.04.2014
  * @private
  * @param iDelay            : D�lai en quantit� par 100 pi�ces
  * @param iPreviousDuration : Dur�e en minutes de l'op�ration pr�c�dente
  * @return : le retard en minutes
  */
  function pGetConvertQtyIntoDelay(iDelay in FAL_GAN_OPERATION.FGO_PARALLEL%type, iPreviousDuration in FAL_GAN_OPERATION.FGO_DURATION%type)
    return number
  as
  begin
    if iDelay = cstParallelFlag then
      return 0;
    else
      return round(iDelay * iPreviousDuration / 100);
    end if;
  end pGetConvertQtyIntoDelay;

  /**
  * procedure pDefineMaxOpDuration
  * Description
  *    Compare la dur�e max actuelle avec celle de l'op�ration transmise. Retourne la plus grande valeur des deux ainsi que la s�quence
  *    de la plus grande op�ration. L'�ventuel retard d�fini sur l'op�ration est ajout� au culul des retards
  * @created age 19.06.2013
  * @lastUpdate age 09.11.2015
  * @private
  * @param iOperation        : Donn�es de l'op�ration sur laquelle on teste la dur�e.
  * @param ioMaxOpDuration   : Dur�e max actuelle � tester avec celle de l'op�ration. Retourne la plus grande des deux.
  * @param ioMaxOpStepNumber : S�quence de l'op�ration du bloc parall�le actuellement la plus longue.
  * @param ioCumulativeDelay : Retards cumul�s du bloc d'op�rations parall�les.
  */
  procedure pDefineMaxOpDuration(
    iOperation        in     crOperations%rowtype
  , ioMaxOpDuration   in out number
  , ioMaxOpStepNumber in out number
  , ioCumulativeDelay in out number
  )
  as
    lOpDuration number;
  begin
    ioCumulativeDelay  := ioCumulativeDelay + pGetConvertQtyIntoDelay(iOperation.FGO_PARALLEL, iOperation.PREVIOUS_DURATION);
    lOpDuration        := ioCumulativeDelay + iOperation.FGO_DURATION + iOperation.FGO_TRANSFERT_TIME;

    if lOpDuration > ioMaxOpDuration then
      ioMaxOpStepNumber  := iOperation.FGO_STEP_NUMBER;
      ioMaxOpDuration    := lOpDuration;
    end if;
  end pDefineMaxOpDuration;

  /**
  * procedure pAddTimout
  * Description
  *    Si la plus grande op�ration parall�le n'est pas la derni�re du bloc, calcul et ajout d'un temps mort sur son temps de transfert.
  *    Comme Le composants XGantt ne g�re pas la notion de parall�lisme au niveau des op�rations, nous avons utilis� le param�tre
  *    "OperationOverlapQuantity" pour que les op. d�finies comme parall�les dans PCS commencent en m�me temps que la pr�c�dente ou
  *    selon le retard d�fini dans PCS. La prochaine op�ration successeur va donc commencer logiquement directement apr�s la derni�re
  *    op. parall�le, raison pour laquelle il faut que cela soit la plus grande du bloc.
  * @created age 19.06.2013
  * @lastUpdate age 09.11.2015
  * @private
  * @param iLastParallelOps  : Donn�es de la derni�re op�ration parall�le du bloc sur laquelle on ajoute le temps mort.
  * @param iMaxOpDuration    : Temps d'ex�cution le plus long du groupe d'op�ration p// (y compris retard et temps de transfert cumul�s.)
  * @param ioCumulativeDelay : Retards cumul�s du bloc d'op�rations parall�les.
  */
  procedure pAddTimout(iLastParallelOps in crOperations%rowtype, iMaxOpDuration in number, iCumulativeDelay in number)
  as
    lTimeOut number := 0;
  begin
    -- Calcul du temp mort � ajouter sur la derni�re op�ration du bloc parall�le afin qu'elle ne soient pas plus courte qu'une autre-
    lTimeOut := iMaxOpDuration - iCumulativeDelay - iLastParallelOps.FGO_DURATION - iLastParallelOps.FGO_TRANSFERT_TIME;

    -- Ajout du temps mort au temps de transfert
    if lTimeOut > 0 then
      update FAL_GAN_OPERATION
         set FGO_TRANSFERT_TIME = FGO_TRANSFERT_TIME + lTimeOut
       where FAL_GAN_OPERATION_ID = iLastParallelOps.FAL_GAN_OPERATION_ID;
    end if;
  end pAddTimout;

  /**
  * procedure pInvertSequences
  * Description
  *    Si la plus grande op�ration parall�le n'est pas la derni�re du bloc, intervertir les deux s�quences. Les s�quences d�terminent
  *    l'ordre de traitement de op�ration par le composants XGantt. Comme celui-ci ne g�re pas la notion de parall�lisme, nous avons utilis�
  *    le param�tre "OperationOverlapQuantity" pour que les op. d�finies comme parall�le dans PCS commencent en m�me temps que la pr�c�dente ou
  *    selon le retard d�fini dans PCS. La prochaine op�ration successeur va donc commencer logiquement directement apr�s la derni�re op. parall�le,
  *    raison pour laquelle il faut que cela soit la plus grande du bloc.
  *    /!\ Seule la plus longue op�ration du bloc peut avoir un temps de tranfert. dans les cas contraire, l'op�ration suivante ne commencera qu'apr�s
  *    ce temps de transfert. En cas d'inversion, l'�ventuel temps de transfert d�fini sur la dernier op�ration avant inversion est remis � 0.
  * @created age 09.11.2015
  * @lastUpdate
  * @private
  * @param iLastParallelOps  : Donn�es de la derni�re op�ration parall�le du bloc
  * @param iMaxOpSequence    : S�quence de l'op�ration la plus longue du bloc d'op�rations parall�les (y compris retard et temps de transfert)
  * @param ioLastOperationID : Identifiant de la derni�re op�ration trait�e. Elle doit �tre mise � jour avec l'op�ration invers�e.
  * @param iTpLinks          : Tableaux de liens inter-op�rations.
  */
  procedure pInvertSequences(
    iLastParallelOps  in            crOperations%rowtype
  , iMaxOpSequence    in            FAL_GAN_OPERATION.FGO_STEP_NUMBER%type
  , ioLastOperationID in out        FAL_GAN_OPERATION.FAL_GAN_OPERATION_ID%type
  , iTpLinks          in out nocopy TLinks
  )
  as
    lMaxOpId  FAL_GAN_OPERATION.FAL_GAN_OPERATION_ID%type;
    lOpLinkId FAL_GAN_LINK.FAL_GAN_LINK_ID%type;
  begin
    -- R�cup�ration de l'Identifiant de la plus longue op�ration parall�le du bloc.
    select FAL_GAN_OPERATION_ID
      into lMaxOpId
      from FAL_GAN_OPERATION
     where FGO_STEP_NUMBER = iMaxOpSequence
       and FAL_GAN_TASK_ID = iLastParallelOps.FAL_GAN_TASK_ID;

    -- Mise � jour de la s�quence de cette op�ration avec la s�quence de la derni�re op�ration du bloc.
    update FAL_GAN_OPERATION
       set FGO_STEP_NUMBER = iLastParallelOps.FGO_STEP_NUMBER
     where FAL_GAN_OPERATION_ID = lMaxOpId;

    -- Mise � jour de la s�quence de la derni�re op�ration avec celle de la plus grande op�ration du bloc.
    -- L'�ventuel temps de transfert d�fini doit �tre mis � 0 puisque l'op�ration n'est plus la derni�re.
    update FAL_GAN_OPERATION
       set FGO_STEP_NUMBER = iMaxOpSequence
         , FGO_TRANSFERT_TIME = 0
     where FAL_GAN_OPERATION_ID = iLastParallelOps.FAL_GAN_OPERATION_ID;

    -- Inversion dans le tableau de lien qui sera utilis� pour cr�er les liens une fois l'ensemble des
    -- op�ration parcourues. Exemple pour une inversion des op�rations 30 et 60.

    -- L30 20->30 --> 20->60
    iTpLinks(lMaxOpId).FAL_GAN_SUCC_OPERATION_ID                                           := iLastParallelOps.FAL_GAN_OPERATION_ID;
    -- L40 30->40 --> 60->40
    iTpLinks(iTpLinks(lMaxOpId).FAL_GAN_NEXT_SUCC_OPERATION_ID).FAL_GAN_PRED_OPERATION_ID  := iLastParallelOps.FAL_GAN_OPERATION_ID;
    -- L60 50->60 --> 50->30
    iTpLinks(iLastParallelOps.FAL_GAN_OPERATION_ID).FAL_GAN_SUCC_OPERATION_ID              := lMaxOpId;
    -- L70 60->70 --> 30->70
    -- null. Ce lien sera cr�� juste apr�s cette m�thode. Le changement de  30 � 60 se fait en red�finissant
    -- la valeur de ioLastOperationID avec lMaxOpId ci-dessous.

    -- Mise � jour de la derni�re op�ration trait�e (utilis� pour la cr�ation des liens visuels entre op�rations.)
    ioLastOperationID                                                                      := lMaxOpId;
  end pInvertSequences;

  /**
  * procedure pInvertSequences
  * Description
  * Application du workaround pour contourner le fait que le composant XGantt ne g�re pas le parall�lisme au niveau des op�rations, mais unquement
  * au niveau des lots. Pour contourner ce probl�me, 3 solutions sont possibles en fonction de la valeur de iParallelWorkAroundMode. Cette valeur
  * est d�finie dans le param�tre d'objet 'FAL_GANTT_OP_WORKAROUND_MODE'. Valeur par d�faut = 1.
  * Valeur = 0 : Pas de workAround.
  *              D�savantage : Si la derni�re op�ration du bloc parall�le n'est pas la plus longue, la suivante commencera avant que l'ensemble
  *              des op�ration du bloc ne soit termin�e.
  * Valeur = 1 : Ajout d'un 'temp mort' dans le temps de transfert de la derni�re op�ration du bloc pour qu'elle soit aussi la plus longue du bloc.
  *              D�savantage : Ce temps mort restera d�fini si une op�ration est bloqu�e ou d�plac�e
  * Valuer = 2 : Inversion de la derni�re op�ration avec la plus longue du bloc.
  *              D�savantage : Incoh�rance si un retard est d�fini sur l'op�ration suivant l'op�ration la plus longue du bloc.
  * @created age 09.11.2015
  * @lastUpdate
  * @private
  * @param iLastParallelOps        : Donn�es de la derni�re op�ration parall�le du bloc
  * @param iMaxOpDuration          : Temps d'ex�cution le plus long du bloc d'op�rations parall�le (y compris retard et temps de transfert)
  * @param iMaxOpSequence          : S�quence de l'op�ration la plus longue du bloc d'op�rations parall�les (y compris retard et temps de transfert)
  * @param ioCumulativeDelay       : Retards cumul�s du bloc d'op�rations parall�les.
  * @param ioLastOperationID       : Identifiant de la derni�re op�ration trait�e. Elle doit �tre mise � jour avec l'op�ration invers�e.
  * @param iParallelWorkAroundMode : Workaround appliqu� pour la simulation des op�rations parall�les que le composants ne g�re pas � ce niveau.
  * @param iTpLinks                : Tableaux de liens inter-op�rations.
  */
  procedure pApplyOpWorkAround(
    iLastParallelOps        in            crOperations%rowtype
  , iMaxOpDuration          in            number
  , iMaxOpSequence          in            FAL_GAN_OPERATION.FGO_STEP_NUMBER%type
  , iCumulativeDelay        in            number
  , ioLastOperationID       in out        FAL_GAN_OPERATION.FAL_GAN_OPERATION_ID%type
  , iParallelWorkAroundMode in            integer
  , iTpLinks                in out nocopy TLinks
  )
  as
  begin
    case iParallelWorkAroundMode
      when 1 then
        pAddTimout(iLastParallelOps, iMaxOpDuration, iCumulativeDelay);
      when 2 then
        pInvertSequences(iLastParallelOps, iMaxOpSequence, ioLastOperationID, iTpLinks);
      else
        return;
    end case;
  end pApplyOpWorkAround;

  /**
  * fonction pUpdatePlanningPriority
  * Description
  *    Mise � jour de la priorit� d'ordonnancement
  * @created eca
  * @lastUpdate age 01.05.2014
  * @private
  * @param iSessionID : ID Session
  * @param iTaskID    : ID T�che (lot)
  * @return : voir description
  */
  procedure pUpdatePlanningPriority(iSessionID in number)
  is
    liPriority          integer;
    lLinkedTaskPriority FAL_GAN_TASK.FGT_PRIORITY%type;
    lttGanTask          ID_TABLE_TYPE;
    lttLinkedTask       ID_TABLE_TYPE;
  begin
    -- mise � jour des priorit�s selon date d�but planifi�e
    select count(FAL_GAN_TASK_ID)
      into liPriority
      from FAL_GAN_TASK
     where FAL_GAN_SESSION_ID = iSessionID;

    -- R�cup�ration des t�ches (lots) afin de les prioriser. Ordre de priorit� d�fini :
    -- 1. Suivi saisi sur l'OF (OF avec suivi en premier)
    -- 2. Priorit� d�finie sur l'OF (FAL_LOT.C_PRIORITY). (02, 03, etc. 01 et non d�fini en dernier).
    -- 3. Date de planification (Plus ancienne en premier)
    -- 4. R�f�rence du lot (A � Z)
    select   fgt.FAL_GAN_TASK_ID
    bulk collect into lttGanTask
        from FAL_GAN_TASK fgt
       where fgt.FAL_GAN_SESSION_ID = iSessionID
    order by (select count('x')
                from dual
               where exists(select 1
                              from FAL_LOT_PROGRESS
                             where FAL_LOT_ID = fgt.FAL_LOT_ID
                               and FLP_REVERSAL = 0) ) desc
           , case fgt.C_PRIORITY
               when '01' then '11'
               else nvl(fgt.C_PRIORITY, '11')
             end asc
           , fgt.FGT_BASIS_PLAN_START_DATE asc
           , fgt.FGT_REFERENCE asc;

    if lttGanTask.count > 0 then
      for i in lttGanTask.first .. lttGanTask.last loop
        -- R�cup�ration de la priorit�
        lLinkedTaskPriority  := FWK_I_LIB_ENTITY.getNumberFieldFromPk('FAL_GAN_TASK', 'FGT_PRIORITY', lttGanTask(i) );

        -- Si priorit� nulle
        if lLinkedTaskPriority = -1 then
          -- Mis � jour de la t�che (lot) courante.
          update FAL_GAN_TASK
             set FGT_PRIORITY = liPriority
           where FAL_GAN_TASK_ID = lttGanTask(i);

          -- Stockage de la priorit� dans le champ texte libre 1 des op�rations. Utilis� pour restaurer
          -- la priorit� initiale lors du d�blocage de la date d�but de l'op�ration.
          update FAL_GAN_OPERATION
             set FGO_FREE_TEXT1 = lipriority
           where FAL_GAN_TASK_ID = lttGanTask(i);

          --R�cup�ration et mise � jour des t�ches (lots) li�s (amont + aval)
          select column_value
          bulk collect into lttLinkedTask
            from table(FAL_LIB_GANTT.getLinkedGanTaskIDs(iSessionID, lttGanTask(i) ) );

          if lttLinkedTask.count > 0 then
            for i in lttLinkedTask.first .. lttLinkedTask.last loop
              -- R�cup�ration de la priorit�
              lLinkedTaskPriority  := FWK_I_LIB_ENTITY.getNumberFieldFromPk('FAL_GAN_TASK', 'FGT_PRIORITY', lttLinkedTask(i) );

              if lipriority > nvl(lLinkedTaskPriority, 0) then
                -- Mis � jour de la t�che (lot) courante.
                update FAL_GAN_TASK
                   set FGT_PRIORITY = liPriority
                 where FAL_GAN_TASK_ID = lttLinkedTask(i);

                -- Stockage de la priorit� dans le champ texte libre 1 des op�rations. Utilis� pour restaurer
                -- la priorit� initiale lors du d�blocage de la date d�but de l'op�ration.
                update FAL_GAN_OPERATION
                   set FGO_FREE_TEXT1 = lipriority
                 where FAL_GAN_TASK_ID = lttLinkedTask(i);
              end if;
            end loop;
          end if;

          -- Mise � jour de la priorit�
          lipriority  := lipriority - 1;
        end if;
      end loop;
    end if;
  end pUpdatePlanningPriority;

  /**
  * procedure : pInsertLinkedRequirements
  * Description : Chargement de la table des dates d'achat et d'appro log
  *
  * @created ECA
  * @lastUpdate
  * @private
  *
  * @param   iSessionID      Session Oracle
  */
  procedure pInsertLinkedRequirements(iSessionID in number)
  is
  begin
    insert into FAL_GAN_LINKED_REQUIRT
                (FAL_GAN_LINKED_REQUIRT_ID
               , FAL_GAN_TASK_ID
               , FAL_GAN_SESSION_ID
               , FLR_REFERENCE
               , FLR_DESCRIPTION
               , FLR_BASIS_START_DATE
               , FLR_BASIS_END_DATE
               , FLR_START_DATE
               , FLR_END_DATE
               , FLR_PIVOT
               , FLR_REQUIREMENT
               , DOC_POSITION_DETAIL_ID
               , FAL_DOC_PROP_ID
                )
      select FAL_TMP_RECORD_SEQ.nextval
           , FAL_GAN_TASK_ID
           , iSessionID
           , FLR_REFERENCE
           , FLR_DESCRIPTION
           , FLR_BASIS_START_DATE
           , FLR_BASIS_END_DATE
           , FLR_START_DATE
           , FLR_END_DATE
           , FLR_PIVOT
           , FLR_REQUIRMENT
           , DOC_POSITION_DETAIL_ID
           , FAL_DOC_PROP_ID
        from (   -- Attributions de type POA sur fab
              select FGT_NEED.FAL_GAN_TASK_ID
                   , PCS.PC_FUNCTIONS.GetDescodeCode('C_PREFIX_PROP', POA.C_PREFIX_PROP, PCS.PC_I_LIB_SESSION.GetCompLangId) || '-' || POA.FDP_NUMBER
                                                                                                                                                  FLR_REFERENCE
                   , '' FLR_DESCRIPTION
                   , null FLR_BASIS_START_DATE
                   , FNS.FAN_END_PLAN FLR_BASIS_END_DATE
                   , null FLR_START_DATE
                   , null FLR_END_DATE
                   , 0 FLR_PIVOT
                   , 0 FLR_REQUIRMENT
                   , null DOC_POSITION_DETAIL_ID
                   , POA.FAL_DOC_PROP_ID FAL_DOC_PROP_ID
                from FAL_NETWORK_LINK FNL
                   , FAL_NETWORK_NEED FNN
                   , FAL_NETWORK_SUPPLY FNS
                   , FAL_DOC_PROP POA
                   , FAL_GAN_TASK FGT_NEED
               where FGT_NEED.FAL_GAN_SESSION_ID = iSessionID
                 and FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
                 and FNL.FAL_NETWORK_SUPPLY_ID = FNS.FAL_NETWORK_SUPPLY_ID
                 and (   FNN.FAL_LOT_ID = FGT_NEED.FAL_LOT_ID
                      or FNN.FAL_LOT_PROP_ID = FGT_NEED.FAL_LOT_PROP_ID)
                 and FNS.FAL_DOC_PROP_ID = POA.FAL_DOC_PROP_ID
                 and PCS.PC_Config.GetConfig('FAL_ORT_SUPPLIER_DELAY') = 2
              union
              -- Attributions de type DOC sur fab
              select FGT_NEED.FAL_GAN_TASK_ID
                   , DOC.DMT_NUMBER
                   , ''
                   , null
                   , FNS.FAN_END_PLAN
                   , null
                   , null
                   , 0
                   , 0
                   , PDE.DOC_POSITION_DETAIL_ID
                   , null
                from FAL_NETWORK_LINK FNL
                   , FAL_NETWORK_NEED FNN
                   , FAL_NETWORK_SUPPLY FNS
                   , DOC_POSITION_DETAIL PDE
                   , DOC_DOCUMENT DOC
                   , FAL_GAN_TASK FGT_NEED
               where FGT_NEED.FAL_GAN_SESSION_ID = iSessionID
                 and FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
                 and FNL.FAL_NETWORK_SUPPLY_ID = FNS.FAL_NETWORK_SUPPLY_ID
                 and DOC.DOC_DOCUMENT_ID = PDE.DOC_DOCUMENT_ID
                 and (   FNN.FAL_LOT_ID = FGT_NEED.FAL_LOT_ID
                      or FNN.FAL_LOT_PROP_ID = FGT_NEED.FAL_LOT_PROP_ID)
                 and (FNS.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID)
              union
              -- Attributions de type Fab sur DOC
              select FGT_SUPPLY.FAL_GAN_TASK_ID
                   , DOC.DMT_NUMBER
                   , ''
                   , FNN.FAN_BEG_PLAN
                   , null
                   , null
                   , null
                   , 0
                   , 1
                   , PDE.DOC_POSITION_DETAIL_ID
                   , null
                from FAL_NETWORK_LINK FNL
                   , FAL_NETWORK_NEED FNN
                   , FAL_NETWORK_SUPPLY FNS
                   , DOC_POSITION_DETAIL PDE
                   , DOC_DOCUMENT DOC
                   , FAL_GAN_TASK FGT_SUPPLY
               where FGT_SUPPLY.FAL_GAN_SESSION_ID = iSessionID
                 and FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
                 and FNL.FAL_NETWORK_SUPPLY_ID = FNS.FAL_NETWORK_SUPPLY_ID
                 and DOC.DOC_DOCUMENT_ID = PDE.DOC_DOCUMENT_ID
                 and (   FNS.FAL_LOT_ID = FGT_SUPPLY.FAL_LOT_ID
                      or FNS.FAL_LOT_PROP_ID = FGT_SUPPLY.FAL_LOT_PROP_ID)
                 and (FNN.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID) );
  end pInsertLinkedRequirements;

  /**
  * procedure pInsertTask
  * Description
  *   Insertion des donn�es � traiter dans la table des t�ches contenant les t�ches
  * @created eca
  * @lastUpdate age 19.11.2014
  * @private
  * @param iSessionID        : Session Oracle
  * @param iHorizonStart     : D�but de l'horizon
  * @param iHorizonEnd       : Fin de l'horizon
  * @param iPlannedBatch     : Lot plannifi�
  * @param iLaunchedBatch    : Lot lanc�
  * @param iSTDBatch         : Lots standard
  * @param iPRPBatch         : Lots d'affaires
  * @param iSAVBatch         : Lot SAV
  * @param iMRPProp          : Propositions du CB
  * @param iPDPProp          : Propositions du PDP
  * @param iSSTADoc          : Achats sous-traitance
  * @param iDocToBeConfirmed : Document � confirmer
  * @param iDocToBalance     : Document � solder
  * @param iSSTAMRPProp      : Propositions SSTA du CB
  * @param iSSTAPDPProp      : Propositions SSTA du PDP
  */
  procedure pInsertTask(
    iSessionID        in number
  , iHorizonStart     in date
  , iHorizonEnd       in date
  , iPlannedBatch     in integer
  , iLaunchedBatch    in integer
  , iSTDBatch         in integer
  , iPRPBatch         in integer
  , iSAVBatch         in integer
  , iMRPProp          in integer
  , iPDPProp          in integer
  , iSSTADoc          in integer default 0
  , iDocToBeConfirmed in integer default 0
  , iDocToBalance     in integer default 0
  , iSSTAMRPProp      in integer default 0
  , iSSTAPDPProp      in integer default 0
  )
  is
  begin
    -- Insertion des Lots de fabrication, standard et SAV interne
    insert into FAL_GAN_TASK
                (FAL_GAN_TASK_ID
               , DOC_POSITION_DETAIL_ID
               , FAL_LOT_PROP_ID
               , FAL_LOT_ID
               , FAL_DOC_PROP_ID
               , C_SCHEDULE_PLANNING
               , C_FAB_TYPE
               , FGT_REFERENCE
               , FGT_DESCRIPTION
               , FGT_MINIMAL_PLAN_START_DATE
               , FGT_BASIS_PLAN_START_DATE
               , FGT_PLAN_START_DATE
               , FGT_REAL_START_DATE
               , FGT_BASIS_PLAN_END_DATE
               , FGT_PLAN_END_DATE
               , FGT_RESULT_START_DATE
               , FGT_RESULT_END_DATE
               , FGT_DURATION
               , FGT_RESULT_DURATION
               , FGT_QUANTITY
               , FGT_PRIORITY
               , FGT_PROCESS_SEQ
               , C_SCHEDULE_STRATEGY
               , FAL_GAN_SESSION_ID
               , FGT_RELEASE_DATE
               , FGT_DUE_DATE
               , GCO_GOOD_ID
               , DOC_RECORD_ID
               , FGT_RECORD_TITLE
               , C_LOT_STATUS
               , FGT_LOT_TOTAL_QTY
               , FGT_FILTER
               , FGT_MAJOR_REFERENCE
               , FGT_SECONDARY_REFERENCE
               , FGT_FREE_NUM1
               , FGT_FREE_NUM2
               , C_PRIORITY
               , DIC_FAMILY_ID
               , DIC_LOT_CODE2_ID
               , DIC_LOT_CODE3_ID
               , DIC_GOOD_LINE_ID
               , DIC_GOOD_FAMILY_ID
               , DIC_GOOD_GROUP_ID
               , DIC_GOOD_MODEL_ID
               , DIC_ACCOUNTABLE_GROUP_ID
               , GCO_PRODUCT_GROUP_ID
               , FGT_PRG_NAME
               , FGT_INPROD_QTY
                )
      select FAL_TMP_RECORD_SEQ.nextval
           , null
           , null
           , LOT.FAL_LOT_ID
           , null
           , LOT.C_SCHEDULE_PLANNING
           , nvl(LOT.C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing)
           , LOT.LOT_REFCOMPL
           , LOT.LOT_PSHORT_DESCR
           , case nvl(lot.C_PRIORITY, ' ')
               when '00' then coalesce(LOT.LOT_BASIS_BEGIN_DTE, LOT.LOT_PLAN_BEGIN_DTE, FAL_LIB_GANTT.getStartSessionTime)
               else decode(FAL_ORTEMS_EXPORT.CheckDelay(LOT.GCO_GOOD_ID)
                         , 0, FAL_LIB_GANTT.getStartSessionTime
                         , 1, greatest(coalesce(LOT.LOT_BASIS_BEGIN_DTE, LOT.LOT_PLAN_BEGIN_DTE, FAL_LIB_GANTT.getStartSessionTime) -
                                       FAL_ORTEMS_EXPORT.GetDelay(LOT.GCO_GOOD_ID)
                                     , FAL_LIB_GANTT.getStartSessionTime
                                      )
                          )
             end   -- FGT_MINIMAL_PLAN_START_DATE
           , nvl(LOT.LOT_BASIS_BEGIN_DTE, LOT.LOT_PLAN_BEGIN_DTE)
           , LOT.LOT_PLAN_BEGIN_DTE
           , LOT.LOT_OPEN__DTE
           , nvl(LOT.LOT_BASIS_END_DTE, LOT.LOT_PLAN_END_DTE)
           , LOT.LOT_PLAN_END_DTE
           , LOT.LOT_PLAN_BEGIN_DTE
           , LOT.LOT_PLAN_END_DTE
           , (case
                when LOT.C_SCHEDULE_PLANNING <> '1' then nvl(LOT.LOT_PLAN_LEAD_TIME, 0)
                else PAC_I_LIB_SCHEDULE.GetOpenTimeBetween(LOT.LOT_PLAN_BEGIN_DTE, LOT.LOT_PLAN_END_DTE)
              end
             ) *
             60
           , 0
           , 100
           , -1
           , 0
           , null
           , iSessionID
           , null
           , null
           , LOT.GCO_GOOD_ID
           , LOT.DOC_RECORD_ID
           , RCO.RCO_TITLE
           , LOT.C_LOT_STATUS
           , LOT.LOT_TOTAL_QTY
           , 0
           , GCO.GOO_MAJOR_REFERENCE
           , GCO.GOO_SECONDARY_REFERENCE
           , lot.LOT_FREE_NUM1
           , lot.LOT_FREE_NUM2
           , lot.C_PRIORITY
           , lot.DIC_FAMILY_ID
           , lot.DIC_LOT_CODE2_ID
           , lot.DIC_LOT_CODE3_ID
           , gco.DIC_GOOD_LINE_ID
           , gco.DIC_GOOD_FAMILY_ID
           , gco.DIC_GOOD_GROUP_ID
           , gco.DIC_GOOD_MODEL_ID
           , gco.DIC_ACCOUNTABLE_GROUP_ID
           , gco.GCO_PRODUCT_GROUP_ID
           , PRG.PRG_NAME
           , LOT.LOT_INPROD_QTY
        from FAL_LOT LOT
           , DOC_RECORD RCO
           , GCO_GOOD GCO
           , GCO_PRODUCT_GROUP PRG
           , FAL_ORDER ORD
       where LOT.C_LOT_STATUS in(FAL_BATCH_FUNCTIONS.bsPlanned, FAL_BATCH_FUNCTIONS.bsLaunched)
         and nvl(LOT.C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) not in(FAL_BATCH_FUNCTIONS.btAssembly, '2')
         and LOT.GCO_GOOD_ID = GCO.GCO_GOOD_ID
         and GCO.GCO_PRODUCT_GROUP_ID = PRG.GCO_PRODUCT_GROUP_ID(+)
         and LOT.FAL_ORDER_ID = ORD.FAL_ORDER_ID
         and LOT.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
         and (   nvl(LOT.LOT_PLAN_LEAD_TIME, 0) > 0
              or LOT.LOT_PLAN_BEGIN_DTE <> LOT.LOT_PLAN_END_DTE)
         and (   iPlannedBatch = 1
              or iLaunchedBatch = 1
              or iDocToBeConfirmed = 1
              or iDocTobalance = 1)
         and (    (    iPlannedBatch = 1
                   and LOT.C_LOT_STATUS = FAL_BATCH_FUNCTIONS.bsPlanned
                   and nvl(LOT.C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) <> FAL_BATCH_FUNCTIONS.btSubcontract
                  )
              or (    iLaunchedBatch = 1
                  and LOT.C_LOT_STATUS = FAL_BATCH_FUNCTIONS.bsLaunched
                  and nvl(LOT.C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) <> FAL_BATCH_FUNCTIONS.btSubcontract
                 )
              or (    iDocToBeConfirmed = 1
                  and LOT.C_LOT_STATUS = FAL_BATCH_FUNCTIONS.bsPlanned
                  and nvl(LOT.C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) = FAL_BATCH_FUNCTIONS.btSubcontract
                 )
              or (    iDocToBalance = 1
                  and LOT.C_LOT_STATUS = FAL_BATCH_FUNCTIONS.bsLaunched
                  and nvl(LOT.C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) = FAL_BATCH_FUNCTIONS.btSubcontract
                 )
             )
         and (   iSTDBatch = 1
              or iPRPBatch = 1
              or iSAVBatch = 1
              or iSSTADoc = 1)
         and (    (    iSAVBatch = 1
                   and nvl(LOT.C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) = FAL_BATCH_FUNCTIONS.btAfterSales)
              or (    iPRPBatch = 1
                  and RCO.GAL_PROJECT_ID is not null)
              or (    iSTDBatch = 1
                  and RCO.GAL_PROJECT_ID is null
                  and nvl(LOT.C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) = FAL_BATCH_FUNCTIONS.btManufacturing
                 )
              or (    iSSTADoc = 1
                  and nvl(LOT.C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) = FAL_BATCH_FUNCTIONS.btSubcontract)
             )
         and (   iHorizonStart is null
              or (    iHorizonStart is not null
                  and LOT.LOT_PLAN_BEGIN_DTE >= iHorizonStart) )
         and (   iHorizonEnd is null
              or (    iHorizonEnd is not null
                  and LOT.LOT_PLAN_END_DTE <= iHorizonEnd) )
         and exists(select COM_LIST_ID_TEMP_ID
                      from COM_LIST_ID_TEMP
                     where (   LID_CODE = 'FAL_LOT_ID'
                            or LID_CODE = 'FAL_LOT_SSTA')
                       and COM_LIST_ID_TEMP_ID = LOT.FAL_LOT_ID)
         and exists(select COM_LIST_ID_TEMP_ID
                      from COM_LIST_ID_TEMP
                     where LID_CODE = 'GCO_GOOD_ID'
                       and COM_LIST_ID_TEMP_ID = LOT.GCO_GOOD_ID)
         and (   exists(select 'x'   -- ne prendre que les lots avec op�rations non termin�es, sauf si planif selon produit.
                          from FAL_TASK_LINK tal
                         where tal.FAL_LOT_ID = lot.FAL_LOT_ID
                           and lot.C_SCHEDULE_PLANNING <> '1'
                           and TAL_DUE_QTY > 0)
              or (lot.C_SCHEDULE_PLANNING = '1') )
         and exists(   -- filtre sur les ressources
               select 'x'
                 from FAL_TASK_LINK tal
                    , COM_LIST_ID_TEMP tmp
                where tal.FAL_LOT_ID = LOT.FAL_LOT_ID
                  and tmp.LID_CODE = 'FAL_GAN_TIMING_RESOURCE_ID'
                  and (   tmp.COM_LIST_ID_TEMP_ID = tal.FAL_FACTORY_FLOOR_ID
                       or tmp.COM_LIST_ID_TEMP_ID = tal.PAC_SUPPLIER_PARTNER_ID) );

    -- Insertion des propositions fab de type MRP et/ou PDP
    insert into FAL_GAN_TASK
                (FAL_GAN_TASK_ID
               , DOC_POSITION_DETAIL_ID
               , FAL_LOT_PROP_ID
               , FAL_LOT_ID
               , FAL_DOC_PROP_ID
               , C_SCHEDULE_PLANNING
               , C_FAB_TYPE
               , FGT_REFERENCE
               , FGT_DESCRIPTION
               , FGT_MINIMAL_PLAN_START_DATE
               , FGT_BASIS_PLAN_START_DATE
               , FGT_PLAN_START_DATE
               , FGT_REAL_START_DATE
               , FGT_BASIS_PLAN_END_DATE
               , FGT_PLAN_END_DATE
               , FGT_RESULT_START_DATE
               , FGT_RESULT_END_DATE
               , FGT_DURATION
               , FGT_RESULT_DURATION
               , FGT_QUANTITY
               , FGT_PRIORITY
               , FGT_PROCESS_SEQ
               , C_SCHEDULE_STRATEGY
               , FAL_GAN_SESSION_ID
               , FGT_RELEASE_DATE
               , FGT_DUE_DATE
               , GCO_GOOD_ID
               , DOC_RECORD_ID
               , FGT_RECORD_TITLE
               , FGT_LOT_TOTAL_QTY
               , FGT_FILTER
               , FGT_MAJOR_REFERENCE
               , FGT_SECONDARY_REFERENCE
               , FGT_FREE_NUM1
               , FGT_FREE_NUM2
               , C_PRIORITY
               , DIC_FAMILY_ID
               , DIC_LOT_CODE2_ID
               , DIC_LOT_CODE3_ID
               , DIC_GOOD_LINE_ID
               , DIC_GOOD_FAMILY_ID
               , DIC_GOOD_GROUP_ID
               , DIC_GOOD_MODEL_ID
               , DIC_ACCOUNTABLE_GROUP_ID
               , GCO_PRODUCT_GROUP_ID
               , FGT_PRG_NAME
               , FGT_INPROD_QTY
                )
      select FAL_TMP_RECORD_SEQ.nextval
           , null
           , LOP.FAL_LOT_PROP_ID
           , null
           , null
           , LOP.C_SCHEDULE_PLANNING
           , (case
                when LOP.FAL_PIC_ID is null then '10'
                else '11'
              end)
           , PCS.PC_FUNCTIONS.GetDescodeCode('C_PREFIX_PROP', LOP.C_PREFIX_PROP, PCS.PC_I_LIB_SESSION.GetCompLangId) || '-' || LOP.LOT_NUMBER
           , LOP.LOT_PSHORT_DESCR
           , decode(FAL_ORTEMS_EXPORT.CheckDelay(LOP.GCO_GOOD_ID)
                  , 0, FAL_LIB_GANTT.getStartSessionTime
                  , 1, greatest(nvl(LOP.LOT_PLAN_BEGIN_DTE, FAL_LIB_GANTT.getStartSessionTime) - FAL_ORTEMS_EXPORT.GetDelay(LOP.GCO_GOOD_ID)
                              , FAL_LIB_GANTT.getStartSessionTime
                               )
                   )
           , LOP.LOT_PLAN_BEGIN_DTE
           , LOP.LOT_PLAN_BEGIN_DTE
           , null
           , LOP.LOT_PLAN_END_DTE
           , LOP.LOT_PLAN_END_DTE
           , LOP.LOT_PLAN_BEGIN_DTE
           , LOP.LOT_PLAN_END_DTE
           , (case
                when LOP.C_SCHEDULE_PLANNING <> '1' then nvl(LOP.LOT_PLAN_LEAD_TIME, 0)
                else PAC_I_LIB_SCHEDULE.GetOpenTimeBetween(LOP.LOT_PLAN_BEGIN_DTE, LOP.LOT_PLAN_END_DTE)
              end
             ) *
             60
           , 0
           , 100
           , -1
           , 0
           , null
           , iSessionID
           , null
           , null
           , LOP.GCO_GOOD_ID
           , LOP.DOC_RECORD_ID
           , RCO.RCO_TITLE
           , LOP.LOT_TOTAL_QTY
           , 0
           , GCO.GOO_MAJOR_REFERENCE
           , GCO.GOO_SECONDARY_REFERENCE
           , null   -- LOT_FREE_NUM1
           , null   -- LOT_FREE_NUM2
           , null   -- C_PRIORITY
           , lop.DIC_FAMILY_ID
           , null   -- DIC_LOT_CODE2_ID
           , null   -- DIC_LOT_CODE3_ID
           , gco.DIC_GOOD_LINE_ID
           , gco.DIC_GOOD_FAMILY_ID
           , gco.DIC_GOOD_GROUP_ID
           , gco.DIC_GOOD_MODEL_ID
           , gco.DIC_ACCOUNTABLE_GROUP_ID
           , gco.GCO_PRODUCT_GROUP_ID
           , PRG.PRG_NAME
           , null   -- LOT_INPROD_QTY
        from FAL_LOT_PROP LOP
           , DOC_RECORD RCO
           , GCO_GOOD GCO
           , GCO_PRODUCT_GROUP PRG
       where LOP.GCO_GOOD_ID = GCO.GCO_GOOD_ID
         and GCO.GCO_PRODUCT_GROUP_ID = PRG.GCO_PRODUCT_GROUP_ID(+)
         and LOP.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
         and (   nvl(LOP.LOT_PLAN_LEAD_TIME, 0) > 0
              or LOP.LOT_PLAN_BEGIN_DTE <> LOP.LOT_PLAN_END_DTE)
         and (    (    iMRPProp = 1
                   and LOP.FAL_PIC_ID is null
                   and nvl(C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) = FAL_BATCH_FUNCTIONS.btManufacturing)
              or (    iPDPProp = 1
                  and LOP.FAL_PIC_ID is not null
                  and nvl(C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) = FAL_BATCH_FUNCTIONS.btManufacturing)
              or (    iSSTAMRPProp = 1
                  and LOP.FAL_PIC_ID is null
                  and nvl(C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) = FAL_BATCH_FUNCTIONS.btSubcontract)
              or (    iSSTAPDPProp = 1
                  and LOP.FAL_PIC_ID is not null
                  and nvl(C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) = FAL_BATCH_FUNCTIONS.btSubcontract)
             )
         and (   iHorizonStart is null
              or (    iHorizonStart is not null
                  and LOP.LOT_PLAN_BEGIN_DTE >= iHorizonStart) )
         and (   iHorizonEnd is null
              or (    iHorizonEnd is not null
                  and LOP.LOT_PLAN_END_DTE <= iHorizonEnd) )
         and exists(select COM_LIST_ID_TEMP_ID
                      from COM_LIST_ID_TEMP
                     where LID_CODE = 'FAL_LOT_PROP_ID'
                       and COM_LIST_ID_TEMP_ID = LOP.FAL_LOT_PROP_ID)
         and exists(select COM_LIST_ID_TEMP_ID
                      from COM_LIST_ID_TEMP
                     where LID_CODE = 'GCO_GOOD_ID'
                       and COM_LIST_ID_TEMP_ID = LOP.GCO_GOOD_ID)
         and exists(   -- filtre sur les ressources
               select 'x'
                 from FAL_TASK_LINK_PROP tal
                    , COM_LIST_ID_TEMP tmp
                where tal.FAL_LOT_PROP_ID = LOP.FAL_LOT_PROP_ID
                  and tmp.LID_CODE = 'FAL_GAN_TIMING_RESOURCE_ID'
                  and (   tmp.COM_LIST_ID_TEMP_ID = tal.FAL_FACTORY_FLOOR_ID
                       or tmp.COM_LIST_ID_TEMP_ID = tal.PAC_SUPPLIER_PARTNER_ID) );
  end pInsertTask;

  /**
  * procedure : pInsertOperation
  * Description : Insertion des donn�es � traiter dans la table FAL_GAN_OPERATION
  *               , contenant les op�rations de t�che
  * @created ECA
  * @lastUpdate
  * @private
  *
  * @param   iSessionID   Session Oracle
  */
  procedure pInsertOperation(iSessionID in number)
  is
    ldMinCalOfDate   date;
    ldMinCalPropDate date;
  begin
    -- Date d�but du chargement des calendriers
    begin
      select min(TAL.TAL_BEGIN_PLAN_DATE)
        into ldMinCalOfDate
        from FAL_GAN_TASK FGT
           , FAL_TASK_LINK TAL
       where FGT.FAL_LOT_ID = TAL.FAL_LOT_ID
         and FGT.C_SCHEDULE_PLANNING <> '1'
         and FGT.FAL_GAN_SESSION_ID = iSessionID
         and nvl(TAL.TAL_DUE_QTY, 0) > 0;
    exception
      when others then
        ldMinCalOfDate  := sysdate;
    end;

    begin
      select min(TAL.TAL_BEGIN_PLAN_DATE)
        into ldMinCalPropDate
        from FAL_GAN_TASK FGT
           , FAL_TASK_LINK_PROP TAL
       where FGT.FAL_LOT_PROP_ID = TAL.FAL_LOT_PROP_ID
         and FGT.C_SCHEDULE_PLANNING <> '1'
         and FGT.FAL_GAN_SESSION_ID = iSessionID;
    exception
      when others then
        ldMinCalPropDate  := sysdate;
    end;

    ldMinCalOfDate  := least(ldMinCalOfDate, ldMinCalPropDate) - 1;

    -- Insertion des op�rations de lot de fabrication s�lectionn�s
    -- avec planification selon op�ration / d�taill�es
    insert into FAL_GAN_OPERATION
                (FAL_GAN_OPERATION_ID
               , FGO_STEP_NUMBER
               , FGO_DESCRIPTION
               , FGO_BASIS_PLAN_START_DATE
               , FGO_PLAN_START_DATE
               , FGO_REAL_START_DATE
               , FGO_BASIS_PLAN_END_DATE
               , FGO_PLAN_END_DATE
               , FGO_LOCK_START_DATE
               , FGO_DURATION
               , FGO_PREPARATION_TIME
               , FGO_TRANSFERT_TIME
               , FGO_QUANTITY
               , FGO_PARALLEL
               , FGO_RESULT_STATUS
               , FGO_RESULT_DURATION
               , FGO_COMPLETION_DEGREE
               , FAL_GAN_TASK_ID
               , FAL_GAN_SESSION_ID
               , FAL_GAN_TIMING_RESOURCE_ID
               , FAL_GAN_RESULT_TIMING_RES_ID
               , FAL_GAN_RESOURCE_GROUP_ID
               , FGO_FILTER
               , C_TASK_TYPE
               , C_OPERATION_TYPE
               , FAL_SCHEDULE_STEP_ID
               , FGO_DUE_QTY
               , FGO_TSK_BALANCE
                )
      select FAL_TMP_RECORD_SEQ.nextval
           , TAL.SCS_STEP_NUMBER
           , TAL.SCS_STEP_NUMBER || ' - ' || TAL.SCS_SHORT_DESCR
           , coalesce(TAL.TAL_BASIS_BEGIN_DATE, TAL.TAL_BEGIN_PLAN_DATE, sysdate)
           , case FAL_LIB_GANTT.doCalculateRemainingTime(iLotId               => TAL.FAL_LOT_ID
                                                       , iTaskId              => TAL.FAL_SCHEDULE_STEP_ID
                                                       , itaskType            => TAL.C_TASK_TYPE
                                                       , iTaskBeginPlanDate   => TAL.TAL_BEGIN_PLAN_DATE
                                                        )
               when 1 then FAL_LIB_GANTT.getStartSessionTime
               else nvl(TAL.TAL_BEGIN_PLAN_DATE, sysdate)
             end   --FGO_PLAN_START_DATE
           , TAL.TAL_BEGIN_REAL_DATE
           , coalesce(TAL.TAL_BASIS_END_DATE, TAL.TAL_END_PLAN_DATE, sysdate)
           , nvl(TAL.TAL_END_PLAN_DATE, sysdate)
           , null   -- FGO_LOCK_START_DATE
           , GetOperationDuration(iTAL_TSK_AD_BALANCE        => TAL.TAL_TSK_AD_BALANCE
                                , iTAL_TSK_W_BALANCE         => TAL.TAL_TSK_W_BALANCE
                                , iTAL_NUM_UNITS_ALLOCATED   => TAL.TAL_NUM_UNITS_ALLOCATED
                                , iSCS_TRANSFERT_TIME        => case FAL_LIB_CONSTANT.gcCfgGanttTransfertTime
                                    when 'FALSE' then TAL.SCS_TRANSFERT_TIME
                                    else 0
                                  end
                                , iSCS_PLAN_PROP             => TAL.SCS_PLAN_PROP
                                , iTAL_PLAN_RATE             => TAL.TAL_PLAN_RATE
                                , iSCS_PLAN_RATE             => TAL.SCS_PLAN_RATE
                                , iC_TASK_TYPE               => TAL.C_TASK_TYPE
                                , iFAL_FACTORY_FLOOR_ID      => TAL.FAL_FACTORY_FLOOR_ID
                                , iPAC_SUPPLIER_PARTNER_ID   => TAL.PAC_SUPPLIER_PARTNER_ID
                                , iTAL_BEGIN_PLAN_DATE       => TAL.TAL_BEGIN_PLAN_DATE
                                , iTAL_END_PLAN_DATE         => TAL.TAL_END_PLAN_DATE
                                , iTAL_BEGIN_REAL_DATE       => TAL.TAL_BEGIN_REAL_DATE
                                , iSCS_OPEN_TIME_MACHINE     => TAL.SCS_OPEN_TIME_MACHINE
                                , iFAC_DAY_CAPACITY          => FAC.FAC_DAY_CAPACITY
                                , iTAL_SUBCONTRACT_QTY       => TAL.TAL_SUBCONTRACT_QTY
                                , iFAL_LOT_ID                => TAL.FAL_LOT_ID
                                , iFAL_SCHEDULE_STEP_ID      => TAL.FAL_SCHEDULE_STEP_ID
                                 )
           , null
           , case FAL_LIB_CONSTANT.gcCfgGanttTransfertTime
               when 'TRUE' then(nvl(TAL.SCS_TRANSFERT_TIME, 0) * FAL_LIB_CONSTANT.gcCfgWorkUnit)
               else 0
             end   -- transfert
           , 0
           , (case
                when C_RELATION_TYPE in('2', '4', '5') then decode(nvl(TAL.SCS_DELAY, 0), 0, cstParallelFlag, TAL.SCS_DELAY * FAL_LIB_CONSTANT.gcCfgWorkUnit)
                else 0
              end
             )
           , 0
           , 0
           , null
           , FGT.FAL_GAN_TASK_ID
           , iSessionID
           , (select FGR.FAL_GAN_TIMING_RESOURCE_ID
                from FAL_GAN_TIMING_RESOURCE FGR
               where (   FGR.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID
                      or FGR.PAC_SUPPLIER_PARTNER_ID = TAL.PAC_SUPPLIER_PARTNER_ID)
                 and FGR.FAL_GAN_SESSION_ID = iSessionID)
           , (select FGR.FAL_GAN_TIMING_RESOURCE_ID
                from FAL_GAN_TIMING_RESOURCE FGR
               where (   FGR.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID
                      or FGR.PAC_SUPPLIER_PARTNER_ID = TAL.PAC_SUPPLIER_PARTNER_ID)
                 and FGR.FAL_GAN_SESSION_ID = iSessionID)
           , (select FGG.FAL_GAN_RESOURCE_GROUP_ID
                from FAL_GAN_RESOURCE_GROUP FGG
               where FGG.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID
                 and FGG.FAL_GAN_SESSION_ID = iSessionID)
           , 0
           , TAL.C_TASK_TYPE
           , TAL.C_OPERATION_TYPE
           , TAL.FAL_SCHEDULE_STEP_ID
           , TAL.TAL_DUE_QTY
           , TAL.TAL_TSK_BALANCE
        from FAL_GAN_TASK FGT
           , FAL_TASK_LINK TAL
           , FAL_FACTORY_FLOOR FAC
       where FGT.FAL_LOT_ID = TAL.FAL_LOT_ID
         and FGT.C_SCHEDULE_PLANNING <> '1'
         and FGT.FAL_GAN_SESSION_ID = iSessionID
         and nvl(TAL.TAL_DUE_QTY, 0) > 0
         and TAL.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID(+);
  end pInsertOperation;

  /**
  * procedure : pInsertMultiLevelLinks
  * Description : Insertion des donn�es � traiter dans la table GAN_OPERATIONS
  *               , Contenant les liens multiniveaux
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param
  */
  procedure pInsertMultiLevelLinks(iSessionID number)
  is
  begin
    -- Il est tr�s important, pour des raisons de performances li�es � la requ�te qui suit,
    -- que les statistiques de la table FAL_GAN_TASK soient recalcul�es.
    -- FAL_GAN_TASK est une table qui est vide au moment o� Oracle recalcule les statistiques.
    -- Dans le cas pr�sent, nous for�ons le recalcul � un moment o� elle a du contenu.
    DBMS_STATS.gather_table_stats(ownname => '', tabname => 'FAL_GAN_TASK', no_invalidate => false);

    insert into FAL_GAN_LINK
                (FAL_GAN_LINK_ID
               , FAL_NETWORK_LINK_ID
               , C_LINK_TYPE
               , FGL_DURATION
               , FGL_BETWEEN_OP
               , FAL_GAN_SESSION_ID
               , FAL_GAN_PRED_TASK_ID
               , FAL_GAN_SUCC_TASK_ID
               , FAL_GAN_PRED_OPERATION_ID
               , FAL_GAN_SUCC_OPERATION_ID
                )
      select FAL_TMP_RECORD_SEQ.nextval
           , NETWORKS.FAL_NETWORK_LINK_ID
           , 'FS'
           , null
           , 0
           , iSessionID
           , NETWORKS.SUPPLY_FAL_GAN_TASK_ID
           , NETWORKS.NEED_FAL_GAN_TASK_ID
           , (select FAL_GAN_OPERATION_ID
                from FAL_GAN_OPERATION FGO1
               where FGO1.FAL_GAN_TASK_ID = NETWORKS.SUPPLY_FAL_GAN_TASK_ID
                 and FGO1.FGO_STEP_NUMBER = (select max(FGO1.FGO_STEP_NUMBER)
                                               from FAL_GAN_OPERATION FGO1
                                              where FGO1.FAL_GAN_TASK_ID = NETWORKS.SUPPLY_FAL_GAN_TASK_ID) )
           , (select FAL_GAN_OPERATION_ID
                from FAL_GAN_OPERATION FGO1
               where FGO1.FAL_GAN_TASK_ID = NETWORKS.NEED_FAL_GAN_TASK_ID
                 and FGO1.FGO_STEP_NUMBER = (select min(FGO1.FGO_STEP_NUMBER)
                                               from FAL_GAN_OPERATION FGO1
                                              where FGO1.FAL_GAN_TASK_ID = NETWORKS.NEED_FAL_GAN_TASK_ID) )
        from (select A.FAL_NETWORK_LINK_ID
                   , A.NEED_FAL_GAN_TASK_ID
                   , B.SUPPLY_FAL_GAN_TASK_ID
                from (select FNL.FAL_NETWORK_LINK_ID
                           , FGT_NEED.FAL_GAN_TASK_ID NEED_FAL_GAN_TASK_ID
                        from FAL_NETWORK_LINK FNL
                           , FAL_NETWORK_NEED FNN
                           , FAL_GAN_TASK FGT_NEED
                           , FAL_NETWORK_SUPPLY FNS
                       where FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
                         and FNL.FAL_NETWORK_SUPPLY_ID = FNS.FAL_NETWORK_SUPPLY_ID
                         and (   nvl(FNN.FAL_LOT_ID, 0) <> nvl(FNS.FAL_LOT_ID, 0)
                              or nvl(FNN.FAL_LOT_PROP_ID, 0) <> nvl(FNS.FAL_LOT_PROP_ID, 0) )
                         and (   FNN.FAL_LOT_ID = FGT_NEED.FAL_LOT_ID
                              or FNN.FAL_LOT_PROP_ID = FGT_NEED.FAL_LOT_PROP_ID)
                         and (   FNS.FAL_LOT_ID is not null
                              or FNS.FAL_LOT_PROP_ID is not null)
                         and FGT_NEED.FAL_GAN_SESSION_ID = iSessionID) A
                   , (select FNL.FAL_NETWORK_LINK_ID
                           , FGT_SUPPLY.FAL_GAN_TASK_ID SUPPLY_FAL_GAN_TASK_ID
                        from FAL_NETWORK_LINK FNL
                           , FAL_NETWORK_NEED FNN
                           , FAL_NETWORK_SUPPLY FNS
                           , FAL_GAN_TASK FGT_SUPPLY
                       where FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID
                         and FNL.FAL_NETWORK_SUPPLY_ID = FNS.FAL_NETWORK_SUPPLY_ID
                         and (   nvl(FNN.FAL_LOT_ID, 0) <> nvl(FNS.FAL_LOT_ID, 0)
                              or nvl(FNN.FAL_LOT_PROP_ID, 0) <> nvl(FNS.FAL_LOT_PROP_ID, 0) )
                         and (   FNN.FAL_LOT_ID is not null
                              or FNN.FAL_LOT_PROP_ID is not null)
                         and (   FNS.FAL_LOT_ID = FGT_SUPPLY.FAL_LOT_ID
                              or FNS.FAL_LOT_PROP_ID = FGT_SUPPLY.FAL_LOT_PROP_ID)
                         and FGT_SUPPLY.FAL_GAN_SESSION_ID = iSessionID) B
               where A.FAL_NETWORK_LINK_ID = B.FAL_NETWORK_LINK_ID) NETWORKS;
  end pInsertMultiLevelLinks;

  /**
  * procedure : pCheckDatas
  * Description : Insertion des charges et assignations pour le th�me industrie
  *
  * @created ECA
  * @lastUpdate
  * @private
  *
  * @param   iSessionID      Session Oracle
  */
  procedure pCheckDatas(iSessionID number)
  is
  begin
    for tplResourceWarning in (select FGT.FAL_GAN_TASK_ID
                                    , FGO.FAL_GAN_OPERATION_ID
                                 from FAL_GAN_TASK FGT
                                    , FAL_GAN_OPERATION FGO
                                where FGT.FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID
                                  and FGO.FAL_GAN_TIMING_RESOURCE_ID is null
                                  and FGT.FAL_GAN_SESSION_ID = iSessionID
                                  and FGO.FAL_GAN_RESOURCE_GROUP_ID is null) loop
      FAL_GANTT_COMMON_FCT.InsertException
                                  (iSessionID              => iSessionID
                                 , iFGE_MESSAGE            => PCS.PC_FUNCTIONS.TranslateWord
                                                                                    ('La ressource n�1 de l''op�ration doit �tre soit un �lot, soit une machine')
                                 , iC_EXCEPTION_CODE       => '7'
                                 , iFAL_GAN_OPERATION_ID   => tplResourceWarning.FAL_GAN_OPERATION_ID
                                 , iFAL_GAN_TASK_ID        => tplResourceWarning.FAL_GAN_TASK_ID
                                  );
    end loop;
  end pCheckDatas;

  function GetOperationDuration(
    iTAL_TSK_AD_BALANCE      in FAL_TASK_LINK.TAL_TSK_AD_BALANCE%type
  , iTAL_TSK_W_BALANCE       in FAL_TASK_LINK.TAL_TSK_W_BALANCE%type
  , iTAL_NUM_UNITS_ALLOCATED in FAL_TASK_LINK.TAL_NUM_UNITS_ALLOCATED%type
  , iSCS_TRANSFERT_TIME      in FAL_TASK_LINK.SCS_TRANSFERT_TIME%type
  , iSCS_PLAN_PROP           in FAL_TASK_LINK.SCS_PLAN_PROP%type
  , iTAL_PLAN_RATE           in FAL_TASK_LINK.TAL_PLAN_RATE%type
  , iSCS_PLAN_RATE           in FAL_TASK_LINK.SCS_PLAN_RATE%type
  , iC_TASK_TYPE             in FAL_TASK_LINK.C_TASK_TYPE%type
  , iFAL_FACTORY_FLOOR_ID    in FAL_TASK_LINK.FAL_FACTORY_FLOOR_ID%type
  , iPAC_SUPPLIER_PARTNER_ID in FAL_TASK_LINK.PAC_SUPPLIER_PARTNER_ID%type
  , iTAL_BEGIN_PLAN_DATE     in FAL_TASK_LINK.TAL_BEGIN_PLAN_DATE%type
  , iTAL_END_PLAN_DATE       in FAL_TASK_LINK.TAL_END_PLAN_DATE%type
  , iTAL_BEGIN_REAL_DATE     in FAL_TASK_LINK.TAL_BEGIN_REAL_DATE%type
  , iSCS_OPEN_TIME_MACHINE   in FAL_TASK_LINK.SCS_OPEN_TIME_MACHINE%type
  , iFAC_DAY_CAPACITY        in number
  , iTAL_SUBCONTRACT_QTY     in FAL_TASK_LINK.TAL_SUBCONTRACT_QTY%type
  , iFAL_LOT_ID              in FAL_TASK_LINK.FAL_LOT_ID%type
  , iFAL_SCHEDULE_STEP_ID    in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  )
    return number
  is
    -- Dur�e de "planification"
    DurationInDay        number := 0;
    DurationInMinutes    number := 0;
    -- Solde temps op�ratoire
    WorkBalanceInMinutes number := 0;
  begin
    -- 1. Calcul de la dur�e de planification (fixe ou proportionnelle)
    -- 1.1 Recherche dur�e en jours.
    DurationInDay         :=
      FAL_LIB_TASK_LINK.getDaysDuration(iSCS_PLAN_PROP             => iSCS_PLAN_PROP
                                      , iTAL_PLAN_RATE             => iTAL_PLAN_RATE
                                      , iTAL_NUM_UNITS_ALLOCATED   => iTAL_NUM_UNITS_ALLOCATED
                                      , iSCS_PLAN_RATE             => iSCS_PLAN_RATE
                                       );

    -- 1.2 Calcul dur�e en minutes selon dur�e en jour.
    if DurationInDay > 0 then
      -- Si les conditions ci-dessous sont remplies, la dur�e de l'op�ration est calcul�e avec la dur�e r�siduelle en minute
      -- depuis l'instant pr�sent (sysdate) jusqu'� iTAL_END_PLAN_DATE.
      -- Conditions :
      -- 1. l'op�ration est externe
      -- 2. sa date d�but est dans le pass�
      -- 3. le lot est lanc�
      -- 4. il existe au moins un CST li�e confirm�e (= avec statut diff�rent de '� confirmer')
      -- 5. toutes les op�rations pr�c�dentes sont r�alis�es (ou l'op�ration est en premi�re position) (Somme TAL_DUE_QTY des op. pr�c�dente = 0)
      if FAL_LIB_GANTT.doCalculateRemainingTime(iLotId               => iFAL_LOT_ID
                                              , iTaskId              => iFAL_SCHEDULE_STEP_ID
                                              , itaskType            => iC_TASK_TYPE
                                              , iTaskBeginPlanDate   => iTAL_BEGIN_PLAN_DATE
                                               ) = 1 then
        DurationInMinutes  :=
          -- Calcul de la dur�e r�siduelle en minute (arrondi � la minute sup�rieure) depuis maintenant (sysdate) jusqu'� iTAL_END_PLAN_DATE.
          ceil(FAL_PLANIF.GetDurationInMinutes(FAL_SCHEDULE_FUNCTIONS.GetSupplierCalendar(iPAC_SUPPLIER_PARTNER_ID)
                                             , null
                                             , iPAC_SUPPLIER_PARTNER_ID
                                             , FAL_LIB_GANTT.getStartSessionTime
                                             , nvl(iTAL_END_PLAN_DATE, sysdate)
                                              )
              );
      else
        -- Calcul de la dur�e en minute � partir de iTAL_BEGIN_PLAN_DATE pour un nombre de jour = � DurationInDay
        DurationInMinutes  := FAL_PLANIF.GetDurationInMinutes(iFAL_FACTORY_FLOOR_ID, iPAC_SUPPLIER_PARTNER_ID, DurationInDay, iTAL_BEGIN_PLAN_DATE);
      end if;
    end if;

    -- 2. Calcul du solde du temps op�ratoire
    WorkBalanceInMinutes  :=
      FAL_LIB_TASK_LINK.getMinutesWorkBalance(iC_TASK_TYPE               => iC_TASK_TYPE
                                            , iTAL_TSK_AD_BALANCE        => iTAL_TSK_AD_BALANCE
                                            , iTAL_TSK_W_BALANCE         => iTAL_TSK_W_BALANCE
                                            , iTAL_NUM_UNITS_ALLOCATED   => iTAL_NUM_UNITS_ALLOCATED
                                            , iSCS_TRANSFERT_TIME        => iSCS_TRANSFERT_TIME
                                            , iSCS_OPEN_TIME_MACHINE     => iSCS_OPEN_TIME_MACHINE
                                            , iFAC_DAY_CAPACITY          => iFAC_DAY_CAPACITY
                                             );

    -- l'atelier est � capacit� finie, il faut prendre uniquement le temps op�ratoire. Sinon si l'atelier est � capacit� infinie ou si
    -- l'op�ration est externe (atelier null), il faut prendre le plus grand temps entre la dur�e de "planification" et le temps op�ratoire.
    if nvl(FWK_I_LIB_ENTITY.getNumberFieldFromPk(FWK_TYP_FAL_ENTITY.gcFalFactoryFloor, 'FAC_INFINITE_FLOOR', iFAL_FACTORY_FLOOR_ID), 1) = 0 then
      return greatest(WorkBalanceInMinutes, 1);
    else
      return greatest(DurationInMinutes, WorkBalanceInMinutes, 1);
    end if;
  end GetOperationDuration;

  /**
  * Description
  *   S�lectionne les lots de fabrications pour affichage
  */
  procedure SelectBatches(
    iJobProgramFrom in FAL_JOB_PROGRAM.JOP_REFERENCE%type
  , iJobProgramTo   in FAL_JOB_PROGRAM.JOP_REFERENCE%type
  , iOrderFrom      in FAL_ORDER.ORD_REF%type
  , iOrderTo        in FAL_ORDER.ORD_REF%type
  , iPriorityFrom   in FAL_LOT.C_PRIORITY%type
  , iPriorityTo     in FAL_LOT.C_PRIORITY%type
  , iFamilyFrom     in DIC_FAMILY.DIC_FAMILY_ID%type
  , iFamilyTo       in DIC_FAMILY.DIC_FAMILY_ID%type
  , iRecordFrom     in DOC_RECORD.RCO_TITLE%type
  , iRecordTo       in DOC_RECORD.RCO_TITLE%type
  , iHorizonStart   in date default null
  , iHorizonEnd     in date default null
  , iPlannedBatch   in integer default 0
  , iLaunchedBatch  in integer default 0
  , iSTDBatch       in integer default 1
  , iPRPBatch       in integer default 0
  , iSAVBatch       in integer default 0
  , iMRPProp        in integer default 0
  , iPDPProp        in integer default 0
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_LOT_ID';

    -- S�lection des ID de lots � afficher
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct LOT.FAL_LOT_ID
                    , 'FAL_LOT_ID'
                 from FAL_LOT LOT
                    , FAL_JOB_PROGRAM JOP
                    , FAL_ORDER ORD
                    , DOC_RECORD RCO
                where LOT.C_LOT_STATUS in(FAL_BATCH_FUNCTIONS.bsPlanned, FAL_BATCH_FUNCTIONS.bsLaunched)
                  and LOT.FAL_JOB_PROGRAM_ID = JOP.FAL_JOB_PROGRAM_ID
                  and (    (    iJobProgramFrom is null
                            and iJobProgramTo is null)
                       or JOP.JOP_REFERENCE between nvl(iJobProgramFrom, JOP.JOP_REFERENCE) and nvl(iJobProgramTo, JOP.JOP_REFERENCE)
                      )
                  and ORD.FAL_ORDER_ID = LOT.FAL_ORDER_ID
                  and (    (    iOrderFrom is null
                            and iOrderTo is null)
                       or ORD.ORD_REF between nvl(iOrderFrom, ORD.ORD_REF) and nvl(iOrderTo, ORD.ORD_REF) )
                  and (    (    iPriorityFrom is null
                            and iPriorityTo is null)
                       or LOT.C_PRIORITY between nvl(iPriorityFrom, LOT.C_PRIORITY) and nvl(iPriorityTo, LOT.C_PRIORITY)
                      )
                  and (    (    iFamilyFrom is null
                            and iFamilyTo is null)
                       or LOT.DIC_FAMILY_ID between nvl(iFamilyFrom, LOT.DIC_FAMILY_ID) and nvl(iFamilyTo, LOT.DIC_FAMILY_ID)
                      )
                  and RCO.DOC_RECORD_ID(+) = LOT.DOC_RECORD_ID
                  and (    (    iRecordFrom is null
                            and iRecordTo is null)
                       or RCO.RCO_TITLE between nvl(iRecordFrom, RCO.RCO_TITLE) and nvl(iRecordTo, RCO.RCO_TITLE) )
                  and (   iPlannedBatch = 1
                       or iLaunchedBatch = 1)
                  and (    (    iPlannedBatch = 1
                            and iLaunchedBatch = 0
                            and LOT.C_LOT_STATUS = FAL_BATCH_FUNCTIONS.bsPlanned)
                       or (    iPlannedBatch = 0
                           and iLaunchedBatch = 1
                           and LOT.C_LOT_STATUS = FAL_BATCH_FUNCTIONS.bsLaunched)
                       or (    iPlannedBatch = 1
                           and iLaunchedBatch = 1
                           and LOT.C_LOT_STATUS in(FAL_BATCH_FUNCTIONS.bsPlanned, FAL_BATCH_FUNCTIONS.bsLaunched) )
                      )
                  and (     (   iSTDBatch = 1
                             or iPRPBatch = 1
                             or iSAVBatch = 1)
                       and nvl(LOT.C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) <> FAL_BATCH_FUNCTIONS.btSubcontract
                      )
                  and (    (    iSTDBatch = 0
                            and iPRPBatch = 0
                            and iSAVBatch = 1
                            and nvl(LOT.C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) = FAL_BATCH_FUNCTIONS.btAfterSales
                           )
                       or (    iSTDBatch = 0
                           and iPRPBatch = 1
                           and iSAVBatch = 0
                           and RCO.GAL_PROJECT_ID is not null)
                       or (    iSTDBatch = 0
                           and iPRPBatch = 1
                           and iSAVBatch = 1
                           and (   RCO.GAL_PROJECT_ID is not null
                                or nvl(LOT.C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) = FAL_BATCH_FUNCTIONS.btAfterSales)
                          )
                       or (    iSTDBatch = 1
                           and iPRPBatch = 0
                           and iSAVBatch = 0
                           and RCO.GAL_PROJECT_ID is null
                           and nvl(LOT.C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) = FAL_BATCH_FUNCTIONS.btManufacturing
                          )
                       or (    iSTDBatch = 1
                           and iPRPBatch = 0
                           and iSAVBatch = 1
                           and RCO.GAL_PROJECT_ID is null
                           and nvl(LOT.C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) in
                                                                                         (FAL_BATCH_FUNCTIONS.btManufacturing, FAL_BATCH_FUNCTIONS.btAfterSales)
                          )
                       or (    iSTDBatch = 1
                           and iPRPBatch = 1
                           and iSAVBatch = 0
                           and nvl(LOT.C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) = FAL_BATCH_FUNCTIONS.btManufacturing
                          )
                       or (    iSTDBatch = 1
                           and iPRPBatch = 1
                           and iSAVBatch = 1)
                      )
                  and (   iHorizonStart is null
                       or (    iHorizonStart is not null
                           and LOT.LOT_PLAN_BEGIN_DTE >= iHorizonStart) )
                  and (   iHorizonEnd is null
                       or (    iHorizonEnd is not null
                           and LOT.LOT_PLAN_END_DTE <= iHorizonEnd) );
  end SelectBatches;

  /**
  * procedure : SelectProducts
  * Description : S�lectionne les produits pour affichage
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iProductFrom          r�f�rence principale de
  * @param   iProductTo            r�f�rence principale d�
  * @param   iCategoryFrom         Cat�gorie de
  * @param   iCategoryTo           Cat�gorie �
  * @param   iFamilyFrom           Famille de
  * @param   iFamilyTo             Famille �
  * @param   iAccountableGroupFrom Groupe responsable de
  * @param   iAccountableGroupTo   Groupe responsable �
  * @param   iLineFrom             Ligne de produit de
  * @param   iLineTo               Ligne de produit �
  * @param   iGroupFrom            Groupe de produit de
  * @param   iGroupTo              Groupe de produit �
  * @param   iModelFrom            Mod�le de
  * @param   iModelTo              Mod�le �
  */
  procedure SelectProducts(
    iProductFrom          in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iProductTo            in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iCategoryFrom         in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
  , iCategoryTo           in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
  , iFamilyFrom           in DIC_GOOD_FAMILY.DIC_GOOD_FAMILY_ID%type
  , iFamilyTo             in DIC_GOOD_FAMILY.DIC_GOOD_FAMILY_ID%type
  , iAccountableGroupFrom in DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
  , iAccountableGroupTo   in DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
  , iLineFrom             in DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
  , iLineTo               in DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
  , iGroupFrom            in DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
  , iGroupTo              in DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
  , iModelFrom            in DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
  , iModelTo              in DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'GCO_GOOD_ID';

    -- S�lection des ID de produits � afficher
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct GOO.GCO_GOOD_ID
                    , 'GCO_GOOD_ID'
                 from GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                    , GCO_GOOD_CATEGORY CAT
                where PDT.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                  and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID(+)
                  and GOO.GOO_MAJOR_REFERENCE between nvl(iProductFrom, GOO.GOO_MAJOR_REFERENCE) and nvl(iProductTo, GOO.GOO_MAJOR_REFERENCE)
                  and (    (    iCategoryFrom is null
                            and iCategoryTo is null)
                       or CAT.GCO_GOOD_CATEGORY_WORDING between nvl(iCategoryFrom, CAT.GCO_GOOD_CATEGORY_WORDING)
                                                            and nvl(iCategoryTo, CAT.GCO_GOOD_CATEGORY_WORDING)
                      )
                  and (    (    iFamilyFrom is null
                            and iFamilyTo is null)
                       or GOO.DIC_GOOD_FAMILY_ID between nvl(iFamilyFrom, GOO.DIC_GOOD_FAMILY_ID) and nvl(iFamilyTo, GOO.DIC_GOOD_FAMILY_ID)
                      )
                  and (    (    iAccountableGroupFrom is null
                            and iAccountableGroupTo is null)
                       or GOO.DIC_ACCOUNTABLE_GROUP_ID between nvl(iAccountableGroupFrom, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                                                           and nvl(iAccountableGroupTo, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                      )
                  and (    (    iLineFrom is null
                            and iLineTo is null)
                       or GOO.DIC_GOOD_LINE_ID between nvl(iLineFrom, GOO.DIC_GOOD_LINE_ID) and nvl(iLineTo, GOO.DIC_GOOD_LINE_ID)
                      )
                  and (    (    iGroupFrom is null
                            and iGroupTo is null)
                       or GOO.DIC_GOOD_GROUP_ID between nvl(iGroupFrom, GOO.DIC_GOOD_GROUP_ID) and nvl(iGroupTo, GOO.DIC_GOOD_GROUP_ID)
                      )
                  and (    (    iModelFrom is null
                            and iModelTo is null)
                       or GOO.DIC_GOOD_MODEL_ID between nvl(iModelFrom, GOO.DIC_GOOD_MODEL_ID) and nvl(iModelTo, GOO.DIC_GOOD_MODEL_ID)
                      );
  end SelectProducts;

  /**
  * Description
  *   S�lectionne les ressources pour affichag
  */
  procedure SelectResources(
    iBlockReferenceFrom in varchar2
  , iBlockReferenceTo   in varchar2
  , iMachReferenceFrom  in varchar2
  , iMachReferenceTo    in varchar2
  , iSuplierFrom        in varchar2
  , iSuplierTo          in varchar2
  , iFloorFreeCode1From in varchar2
  , iFloorFreeCode1To   in varchar2
  , iFloorFreeCode2From in varchar2
  , iFloorFreeCode2To   in varchar2
  , iExcludeBlocks      in integer default 0
  , iExcludeMachines    in integer default 0
  , iExcludeSuppliers   in integer default 0
  )
  is
  begin
    -- Suppression des anciennes valeurs ilots, machine et fournisseurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_GAN_TIMING_RESOURCE_ID';

    -- S�lection des ID d'ilots � afficher
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct FAC.FAL_FACTORY_FLOOR_ID
                    , 'FAL_GAN_TIMING_RESOURCE_ID'
                 from FAL_FACTORY_FLOOR FAC
                where FAC.FAC_OUT_OF_ORDER = 0
                  and FAC.FAC_IS_BLOCK = 1
                  and iExcludeBlocks = 0
                  and nvl(FAC.DIC_FLOOR_FREE_CODE_ID, 'null') between coalesce(iFloorFreeCode1From, FAC.DIC_FLOOR_FREE_CODE_ID, 'null')
                                                                  and coalesce(iFloorFreeCode1To, FAC.DIC_FLOOR_FREE_CODE_ID, 'null')
                  and nvl(FAC.DIC_FLOOR_FREE_CODE2_ID, 'null') between coalesce(iFloorFreeCode2From, FAC.DIC_FLOOR_FREE_CODE2_ID, 'null')
                                                                   and coalesce(iFloorFreeCode2To, FAC.DIC_FLOOR_FREE_CODE2_ID, 'null')
                  and FAC.FAC_REFERENCE between nvl(iBlockReferenceFrom, FAC.FAC_REFERENCE) and nvl(iBlockReferenceTo, FAC.FAC_REFERENCE);

    -- S�lection des machines des ilots s�lectionn�s � afficher
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct FAC.FAL_FACTORY_FLOOR_ID
                    , 'FAL_GAN_TIMING_RESOURCE_ID'
                 from FAL_FACTORY_FLOOR FAC
                where FAC.FAC_OUT_OF_ORDER = 0
                  and FAC.FAC_IS_MACHINE = 1
                  and iExcludeMachines = 0
                  and nvl(FAC.DIC_FLOOR_FREE_CODE_ID, 'null') between coalesce(iFloorFreeCode1From, FAC.DIC_FLOOR_FREE_CODE_ID, 'null')
                                                                  and coalesce(iFloorFreeCode1To, FAC.DIC_FLOOR_FREE_CODE_ID, 'null')
                  and nvl(FAC.DIC_FLOOR_FREE_CODE2_ID, 'null') between coalesce(iFloorFreeCode2From, FAC.DIC_FLOOR_FREE_CODE2_ID, 'null')
                                                                   and coalesce(iFloorFreeCode2To, FAC.DIC_FLOOR_FREE_CODE2_ID, 'null')
                  and FAC.FAC_REFERENCE between nvl(iMachReferenceFrom, FAC.FAC_REFERENCE) and nvl(iMachReferenceTo, FAC.FAC_REFERENCE)
                  and exists(select 'x'
                               from COM_LIST_ID_TEMP
                              where LID_CODE = 'FAL_GAN_TIMING_RESOURCE_ID'
                                and COM_LIST_ID_TEMP_ID = fac.FAL_FAL_FACTORY_FLOOR_ID);

    -- S�lection des ID de fournisseurs
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct PAC.PAC_SUPPLIER_PARTNER_ID
                    , 'FAL_GAN_TIMING_RESOURCE_ID'
                 from PAC_SUPPLIER_PARTNER PAC
                    , PAC_PERSON PER
                where PAC.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
                  and iExcludeSuppliers = 0
                  and PAC.C_PARTNER_STATUS in('1', '2')
                  and PER.PER_NAME between nvl(iSuplierFrom, PER.PER_NAME) and nvl(iSuplierTo, PER.PER_NAME);
  end SelectResources;

  /**
  * procedure : SelectPropositions
  * Description : S�lectionne les propositions
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iType              Type de proposition 'MRP' ou 'PDP'
  * @param   iRecordFrom        Dossier de
  * @param   iRecordTo          Dossier �
  * @param   iStockFrom         Stock de
  * @param   iStockTo           Stock �
  * @param   iDicPropFreeFrom   Code traitt de
  * @param   iDicPropFreeto     Code traitt �
  * @param   iIncludeSSTAProp   Proposition SSTA Comprises
  * @param   iIncludeFabProp    Proposition Fab Comprises
  */
  procedure SelectPropositions(
    iType            in varchar2
  , iRecordFrom      in varchar2
  , iRecordTo        in varchar2
  , iStockFrom       in varchar2
  , iStockTo         in varchar2
  , iDicPropFreeFrom in varchar2
  , iDicPropFreeTo   in varchar2
  , iIncludeSSTAProp in integer default 0
  , iInCludeFabProp  in integer default 1
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_LOT_PROP_ID'
            and COM_LIST_ID_TEMP_ID in(
                  select distinct LOT.FAL_LOT_PROP_ID
                             from FAL_LOT_PROP LOT
                            where (    (    iType in('MRP', 'SSTAMRP')
                                        and FAL_PIC_ID is null)
                                   or (    iType in('PDP', 'SSTAPDP')
                                       and FAL_PIC_ID is not null) )
                              and (    (    iIncludeFabProp = 1
                                        and nvl(C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) <> FAL_BATCH_FUNCTIONS.btSubcontract)
                                   or (    iIncludeSSTAProp = 1
                                       and nvl(C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) = FAL_BATCH_FUNCTIONS.btSubcontract)
                                  ) );

    -- S�lection des ID de propositions � afficher
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct LOT.FAL_LOT_PROP_ID
                    , 'FAL_LOT_PROP_ID'
                 from FAL_LOT_PROP LOT
                    , DOC_RECORD RCO
                    , STM_STOCK STO
                where LOT.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and (    (    iType in('MRP', 'SSTAMRP')
                            and FAL_PIC_ID is null)
                       or (    iType in('PDP', 'SSTAPDP')
                           and FAL_PIC_ID is not null) )
                  and (    (    iIncludeFabProp = 1
                            and nvl(C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) <> FAL_BATCH_FUNCTIONS.btSubcontract)
                       or (    iIncludeSSTAProp = 1
                           and nvl(C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing) = FAL_BATCH_FUNCTIONS.btSubcontract)
                      )
                  and LOT.STM_STOCK_ID = STO.STM_STOCK_ID(+)
                  and (    (    iStockFrom is null
                            and iStockTo is null)
                       or STO.STO_DESCRIPTION between nvl(iStockFrom, STO.STO_DESCRIPTION) and nvl(iStockTo, STO.STO_DESCRIPTION)
                      )
                  and (    (    iRecordFrom is null
                            and iRecordTo is null)
                       or RCO.RCO_TITLE between nvl(iRecordFrom, RCO.RCO_TITLE) and nvl(iRecordTo, RCO.RCO_TITLE) )
                  and (    (    iDicPropFreeFrom is null
                            and iDicPropFreeTo is null)
                       or LOT.DIC_LOT_PROP_FREE_ID between nvl(iDicPropFreeFrom, LOT.DIC_LOT_PROP_FREE_ID) and nvl(iDicPropFreeTo, LOT.DIC_LOT_PROP_FREE_ID)
                      );
  end SelectPropositions;

  /**
  * procedure : SelectMRPPropositions
  * Description : S�lectionne les propositions de type MRP
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iRecordFrom        Dossier de
  * @param   iRecordTo          Dossier �
  * @param   iStockFrom         Stock de
  * @param   iStockTo           Stock �
  * @param   iDicPropFreeFrom   Code traitt de
  * @param   iDicPropFreeto     Code traitt �
  */
  procedure SelectMRPPropositions(
    iRecordFrom      in varchar2
  , iRecordTo        in varchar2
  , iStockFrom       in varchar2
  , iStockTo         in varchar2
  , iDicPropFreeFrom in varchar2
  , iDicPropFreeTo   in varchar2
  )
  is
  begin
    SelectPropositions('MRP', iRecordFrom, iRecordTo, iStockFrom, iStockTo, iDicPropFreeFrom, iDicPropFreeTo, 0, 1);
  end SelectMRPPropositions;

  /**
  * procedure : SelectSSTAMRPPropositions
  * Description : S�lectionne les propositions de type MRP de sous traitance
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iRecordFrom        Dossier de
  * @param   iRecordTo          Dossier �
  * @param   iStockFrom         Stock de
  * @param   iStockTo           Stock �
  * @param   iDicPropFreeFrom   Code traitt de
  * @param   iDicPropFreeto     Code traitt �
  */
  procedure SelectSSTAMRPPropositions(
    iRecordFrom      in varchar2
  , iRecordTo        in varchar2
  , iStockFrom       in varchar2
  , iStockTo         in varchar2
  , iDicPropFreeFrom in varchar2
  , iDicPropFreeTo   in varchar2
  )
  is
  begin
    SelectPropositions('MRP', iRecordFrom, iRecordTo, iStockFrom, iStockTo, iDicPropFreeFrom, iDicPropFreeTo, 1, 0);
  end SelectSSTAMRPPropositions;

  /**
  * procedure : SelectPDPPropositions
  * Description : S�lectionne les propositions de type PDP
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iRecordFrom        Dossier de
  * @param   iRecordTo          Dossier �
  * @param   iStockFrom         Stock de
  * @param   iStockTo           Stock �
  * @param   iDicPropFreeFrom   Code traitt de
  * @param   iDicPropFreeto     Code traitt �
  */
  procedure SelectPDPPropositions(
    iRecordFrom      in varchar2
  , iRecordTo        in varchar2
  , iStockFrom       in varchar2
  , iStockTo         in varchar2
  , iDicPropFreeFrom in varchar2
  , iDicPropFreeTo   in varchar2
  )
  is
  begin
    SelectPropositions('PDP', iRecordFrom, iRecordTo, iStockFrom, iStockTo, iDicPropFreeFrom, iDicPropFreeTo, 0, 1);
  end SelectPDPPropositions;

  /**
  * procedure : SelectSSTAPDPPropositions
  * Description : S�lectionne les propositions de type PDP
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iRecordFrom        Dossier de
  * @param   iRecordTo          Dossier �
  * @param   iStockFrom         Stock de
  * @param   iStockTo           Stock �
  * @param   iDicPropFreeFrom   Code traitt de
  * @param   iDicPropFreeto     Code traitt �
  */
  procedure SelectSSTAPDPPropositions(
    iRecordFrom      in varchar2
  , iRecordTo        in varchar2
  , iStockFrom       in varchar2
  , iStockTo         in varchar2
  , iDicPropFreeFrom in varchar2
  , iDicPropFreeTo   in varchar2
  )
  is
  begin
    SelectPropositions('PDP', iRecordFrom, iRecordTo, iStockFrom, iStockTo, iDicPropFreeFrom, iDicPropFreeTo, 1, 0);
  end SelectSSTAPDPPropositions;

  /**
  * procedure : SelectSSTADoc
  * Description : S�lectionne les Documents (lots de fab sous-ja�ents)
  *               de sous-traitance d'achat
  *
  * @created ECA
  * @lastUpdate 14.02.2013
  * @public
  *
  * @param   iDmtNumberFrom   Document de
  * @param   iDmtNumberTo     Document �
  * @param   iDocRecordFrom   Dossier de
  * @param   iDocRecordTo     Dossier �
  * @param   iGcoServiceFrom  Service de
  * @param   iGcoServiceTo    Service �
  */
  procedure SelectSSTADoc(
    iDmtNumberFrom  in varchar2
  , iDmtNumberTo    in varchar2
  , iDocRecordFrom  in varchar2
  , iDocRecordTo    in varchar2
  , iGcoServiceFrom in varchar2
  , iGcoServiceTo   in varchar2
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_LOT_SSTA';

    -- S�lection des ID de documents � afficher
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct LOT.FAL_LOT_ID
                    , 'FAL_LOT_SSTA'
                 from table(DOC_I_LIB_SUBCONTRACTP.GetSUPOGaugeId(null) ) DocGauge
                    , FAL_LOT LOT
                    , DOC_RECORD RCO
                    , DOC_DOCUMENT DOC
                    , DOC_POSITION POS
                    , GCO_GOOD GCO
                    , GCO_SERVICE SER
                where LOT.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and LOT.C_FAB_TYPE = FAL_BATCH_FUNCTIONS.btSubcontract
                  and LOT.FAL_LOT_ID = POS.FAL_LOT_ID
                  and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
                  and POS.GCO_GOOD_ID = GCO.GCO_GOOD_ID
                  and POS.GCO_GOOD_ID = SER.GCO_GOOD_ID
                  and DOC.DOC_GAUGE_ID = DocGauge.column_value
                  and (    (    iDmtNumberFrom is null
                            and iDmtNumberTo is null)
                       or DOC.DMT_NUMBER between nvl(iDmtNumberFrom, DOC.DMT_NUMBER) and nvl(iDmtNumberTo, DOC.DMT_NUMBER)
                      )
                  and (    (    iDocRecordFrom is null
                            and iDocRecordTo is null)
                       or RCO.RCO_TITLE between nvl(iDocRecordFrom, RCO.RCO_TITLE) and nvl(iDocRecordTo, RCO.RCO_TITLE)
                      )
                  and (    (    iGcoServiceFrom is null
                            and iGcoServiceTo is null)
                       or GCO.GOO_MAJOR_REFERENCE between nvl(iGcoServiceFrom, GCO.GOO_MAJOR_REFERENCE) and nvl(iGcoServiceTo, GCO.GOO_MAJOR_REFERENCE)
                      );
  end SelectSSTADoc;

  /**
  * procedure : FinalizeLinkedRequirements
  * Description : Chargement de la table des dates d'achat et d'appro log
  *
  * @created ECA
  * @lastUpdate age 19.11.2014
  * @public
  *
  * @param   iSessionID      Session Oracle
  */
  procedure FinalizeLinkedRequirements(iSessionID in number)
  is
  begin
    -- Ajout des dates au plus t�t
    update FAL_GAN_TASK FGT
       set FGT_RELEASE_DATE = (select nvl(max(FLR_BASIS_END_DATE), FAL_LIB_GANTT.getStartSessionTime)
                                 from FAL_GAN_LINKED_REQUIRT FLR
                                where FLR.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID
                                  and FLR.FLR_REQUIREMENT = 0
                                  and FLR.FLR_BASIS_END_DATE is not null)
     where FAL_GAN_SESSION_ID = iSessionID
       and gal_task_id is null;

    update FAL_GAN_TASK FGT
       set FGT_RELEASE_DATE = greatest(FGT_RELEASE_DATE, FGT_MINIMAL_PLAN_START_DATE, FAL_LIB_GANTT.getStartSessionTime)
     where FAL_GAN_SESSION_ID = iSessionID
       and FGT.FGT_RELEASE_DATE is not null
       and gal_task_id is null;

    -- Ajout des dates au plus tard
    update FAL_GAN_TASK FGT
       set FGT_DUE_DATE = (select min(FLR_BASIS_START_DATE)
                             from FAL_GAN_LINKED_REQUIRT FLR
                            where FLR.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID
                              and FLR.FLR_REQUIREMENT = 1
                              and FLR.FLR_BASIS_START_DATE is not null)
     where FAL_GAN_SESSION_ID = iSessionID
       and gal_task_id is null;
  end FinalizeLinkedRequirements;

  /**
  * procedure : FinalizeOperation
  * Description : Finalization de l'insertion des op�rations
  * @created AGA
  * @lastUpdate age 05.05.2014
  * @public
  *
  * @param   iSessionID   Session Oracle
  */
  procedure FinalizeOperation(iSessionID in number)
  is
    lnTimingResourceByProductID number;
    lnGroupResourceByProductID  number;
  begin
    -- Ressource virtuelle pour les gammes selon produit
    lnTimingResourceByProductID  := FAL_GANTT_COMMON_FCT.GetTimingResourceByProductID(iSessionID);
    lnGroupResourceByProductID   := FAL_GANTT_COMMON_FCT.GetGroupResourceByProductID(iSessionID);

    -- Insertion des op�rations de Propositions de fabrications avec planification selon op�ration / d�taill�es
    insert into FAL_GAN_OPERATION
                (FAL_GAN_OPERATION_ID
               , FGO_STEP_NUMBER
               , FGO_DESCRIPTION
               , FGO_BASIS_PLAN_START_DATE
               , FGO_PLAN_START_DATE
               , FGO_REAL_START_DATE
               , FGO_BASIS_PLAN_END_DATE
               , FGO_PLAN_END_DATE
               , FGO_LOCK_START_DATE
               , FGO_DURATION
               , FGO_PREPARATION_TIME
               , FGO_TRANSFERT_TIME
               , FGO_QUANTITY
               , FGO_PARALLEL
               , FGO_RESULT_STATUS
               , FGO_RESULT_DURATION
               , FGO_COMPLETION_DEGREE
               , FAL_GAN_TASK_ID
               , FAL_GAN_SESSION_ID
               , FAL_GAN_TIMING_RESOURCE_ID
               , FAL_GAN_RESULT_TIMING_RES_ID
               , FAL_GAN_RESOURCE_GROUP_ID
               , FGO_FILTER
               , C_TASK_TYPE
               , C_OPERATION_TYPE
               , FAL_TASK_LINK_PROP_ID
                )
      select FAL_TMP_RECORD_SEQ.nextval
           , TAL.SCS_STEP_NUMBER
           , TAL.SCS_STEP_NUMBER || ' - ' || TAL.SCS_SHORT_DESCR
           , TAL.TAL_BEGIN_PLAN_DATE
           , TAL.TAL_BEGIN_PLAN_DATE
           , null
           , TAL.TAL_END_PLAN_DATE
           , TAL.TAL_END_PLAN_DATE
           , null   -- FGO_LOCK_START_DATE
           , GetOperationDuration(iTAL_TSK_AD_BALANCE        => TAL.TAL_TSK_AD_BALANCE
                                , iTAL_TSK_W_BALANCE         => TAL.TAL_TSK_W_BALANCE
                                , iTAL_NUM_UNITS_ALLOCATED   => TAL.TAL_NUM_UNITS_ALLOCATED
                                , iSCS_TRANSFERT_TIME        => case FAL_LIB_CONSTANT.gcCfgGanttTransfertTime
                                    when 'FALSE' then TAL.SCS_TRANSFERT_TIME
                                    else 0
                                  end
                                , iSCS_PLAN_PROP             => TAL.SCS_PLAN_PROP
                                , iTAL_PLAN_RATE             => TAL.TAL_PLAN_RATE
                                , iSCS_PLAN_RATE             => TAL.SCS_PLAN_RATE
                                , iC_TASK_TYPE               => TAL.C_TASK_TYPE
                                , iFAL_FACTORY_FLOOR_ID      => TAL.FAL_FACTORY_FLOOR_ID
                                , iPAC_SUPPLIER_PARTNER_ID   => TAL.PAC_SUPPLIER_PARTNER_ID
                                , iTAL_BEGIN_PLAN_DATE       => TAL.TAL_BEGIN_PLAN_DATE
                                , iTAL_END_PLAN_DATE         => TAL.TAL_END_PLAN_DATE
                                , iTAL_BEGIN_REAL_DATE       => null
                                , iSCS_OPEN_TIME_MACHINE     => TAL.SCS_OPEN_TIME_MACHINE
                                , iFAC_DAY_CAPACITY          => FAC.FAC_DAY_CAPACITY
                                , iTAL_SUBCONTRACT_QTY       => null
                                , iFAL_LOT_ID                => null
                                , iFAL_SCHEDULE_STEP_ID      => null
                                 )
           , null
           , case FAL_LIB_CONSTANT.gcCfgGanttTransfertTime
               when 'TRUE' then(nvl(TAL.SCS_TRANSFERT_TIME, 0) * FAL_LIB_CONSTANT.gcCfgWorkUnit)
               else 0
             end   -- transfert
           , 0
           , (case
                when C_RELATION_TYPE in('2', '4') then decode(nvl(TAL.SCS_DELAY, 0), 0, cstParallelFlag, TAL.SCS_DELAY * FAL_LIB_CONSTANT.gcCfgWorkUnit)
                else 0
              end)
           , 0
           , 0
           , null
           , FGT.FAL_GAN_TASK_ID
           , iSessionID
           , (select FGR.FAL_GAN_TIMING_RESOURCE_ID
                from FAL_GAN_TIMING_RESOURCE FGR
               where (   FGR.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID
                      or FGR.PAC_SUPPLIER_PARTNER_ID = TAL.PAC_SUPPLIER_PARTNER_ID)
                 and FGR.FAL_GAN_SESSION_ID = iSessionID)
           , (select FGR.FAL_GAN_TIMING_RESOURCE_ID
                from FAL_GAN_TIMING_RESOURCE FGR
               where (   FGR.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID
                      or FGR.PAC_SUPPLIER_PARTNER_ID = TAL.PAC_SUPPLIER_PARTNER_ID)
                 and FGR.FAL_GAN_SESSION_ID = iSessionID)
           , (select FGG.FAL_GAN_RESOURCE_GROUP_ID
                from FAL_GAN_RESOURCE_GROUP FGG
               where FGG.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID
                 and FGG.FAL_GAN_SESSION_ID = iSessionID)
           , 0
           , TAL.C_TASK_TYPE
           , TAL.C_OPERATION_TYPE
           , TAL.FAL_TASK_LINK_PROP_ID
        from FAL_GAN_TASK FGT
           , FAL_TASK_LINK_PROP TAL
           , FAL_FACTORY_FLOOR FAC
       where FGT.FAL_LOT_PROP_ID = TAL.FAL_LOT_PROP_ID
         and FGT.C_SCHEDULE_PLANNING <> '1'
         and FGT.FAL_GAN_SESSION_ID = iSessionID
         and TAL.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID(+);

    -- Insertion d'une op�ration virtuelle pour les lots et propositions de
    -- fabrication avec planification selon produit ou  sans op�ration
    insert into FAL_GAN_OPERATION
                (FAL_GAN_OPERATION_ID
               , FGO_STEP_NUMBER
               , FGO_DESCRIPTION
               , FGO_BASIS_PLAN_START_DATE
               , FGO_PLAN_START_DATE
               , FGO_REAL_START_DATE
               , FGO_BASIS_PLAN_END_DATE
               , FGO_PLAN_END_DATE
               , FGO_LOCK_START_DATE
               , FGO_DURATION
               , FGO_PREPARATION_TIME
               , FGO_TRANSFERT_TIME
               , FGO_QUANTITY
               , FGO_PARALLEL
               , FGO_RESULT_STATUS
               , FGO_RESULT_DURATION
               , FGO_COMPLETION_DEGREE
               , FAL_GAN_TASK_ID
               , FAL_GAN_SESSION_ID
               , FAL_GAN_TIMING_RESOURCE_ID
               , FAL_GAN_RESULT_TIMING_RES_ID
               , FAL_GAN_RESOURCE_GROUP_ID
               , FGO_FILTER
                )
      select FAL_TMP_RECORD_SEQ.nextval
           , '10'
           , FAL_GANTT_COMMON_FCT.cstResByProductDescr
           , FGT.FGT_PLAN_START_DATE
           , FGT.FGT_PLAN_START_DATE
           , null
           , FGT.FGT_PLAN_END_DATE
           , FGT.FGT_PLAN_END_DATE
           , null   -- FGO_LOCK_START_DATE
           , decode(FGT.FGT_DURATION, 0, FAL_LIB_CONSTANT.gcCfgWorkUnit, FGT.FGT_DURATION)
           , null
           , null
           , 0
           , 0
           , 0
           , 0
           , null
           , FGT.FAL_GAN_TASK_ID
           , iSessionID
           , lnTimingResourceByProductID
           , lnTimingResourceByProductID
           , lnGroupResourceByProductID
           , 0
        from FAL_GAN_TASK FGT
       where FGT.FAL_GAN_SESSION_ID = iSessionID
         and not exists(select 1
                          from FAL_GAN_OPERATION FGO
                         where FGO.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID)
         and not exists(select 1
                          from FAL_GAN_TASK FGT1
                         where FGT.GAL_TASK_ID = FGT1.GAL_FATHER_TASK_ID
                           and FGT1.GAL_FATHER_TASK_ID is not null);

    -- Convertion des retard sur op�rations parall�les en retard en Qt� de pi�ces
    pConvertDelayIntoQty(iSessionID);

    -- Mise � jour chp Qt� de temps et dur�e calcul�e
    update FAL_GAN_OPERATION
       set FGO_QUANTITY = FGO_DURATION
         , FGO_RESULT_DURATION = FGO_DURATION
     where FAL_GAN_SESSION_ID = iSessionID;

    -- Blocage des op�rations li�es � au moins une commande de sous-traitance op�ratoire dont le statut <> '� confirmer'
    update FAL_GAN_OPERATION
       set FGO_LOCK_START_DATE = FGO_PLAN_START_DATE
     where FAL_GAN_SESSION_ID = iSessionID
       and C_TASK_TYPE = '2'
       and FAL_LIB_TASK_LINK.hasLinkedCST(FAL_SCHEDULE_STEP_ID, '02,03,04,') = 1;

    -- Mise � jour des dates d�buts et fin d'ofs
    update FAL_GAN_TASK FGT
       set FGT_RESULT_START_DATE = (select min(FGO.FGO_PLAN_START_DATE)
                                      from FAL_GAN_OPERATION FGO
                                     where FGO.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID)
         , FGT_RESULT_END_DATE = (select max(FGO.FGO_PLAN_END_DATE)
                                    from FAL_GAN_OPERATION FGO
                                   where FGO.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID)
     where fal_lot_id is not null
       and FGT.FAL_GAN_SESSION_ID = iSessionID;

    -- Initialisation des codes projet / t�ches / t�ches parente des op�ration � partir des t�ches affaire
    update FAL_GAN_OPERATION FGO
       set (FGO_PRJ_CODE, FGO_TAS_CODE, FGO_TAS_DF_CODE) = (select FGT_PRJ_CODE
                                                                 , FGT_TAS_CODE
                                                                 , FGT_TAS_DF_CODE
                                                              from FAL_GAN_TASK FGT
                                                             where FGO.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID
                                                               and FGT.FGT_PRJ_CODE is not null)
     where FGO_PRJ_CODE is null
       and FAL_GAN_SESSION_ID = iSessionId
       and exists(select 1
                    from FAL_GAN_TASK FGT
                   where FGO.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID
                     and FGT.FGT_PRJ_CODE is not null);

    -- Mise � jour des dates d�buts et fin d'ofs
    update FAL_GAN_TASK FGT
       set (FGT_RESULT_START_DATE, FGT_RESULT_END_DATE, FGT_RESULT_DURATION) =
             (select min(FGO.FGO_PLAN_START_DATE)
                   , max(FGO.FGO_PLAN_END_DATE)
                   , GAL_GANTT_FCT.GetDurationInMinutes(min(FGO.FGO_PLAN_START_DATE), max(FGO.FGO_PLAN_END_DATE) )
                from FAL_GAN_OPERATION FGO
               where FGO.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID
                 and FGT.FGT_PRJ_CODE is not null)
     where FGT.FAL_GAN_SESSION_ID = iSessionId
       and exists(select 1
                    from FAL_GAN_OPERATION FGO
                   where FGO.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID
                     and FGT.FGT_PRJ_CODE is not null);
  end FinalizeOperation;

  /**
  * procedure : InsertAssignment
  * Description : Insertion des donn�es � traiter dans la table des assignations
  *               , contenant les informations d'affectation des ressources aux
  *               op�rations.
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iSessionID   Session Oracle
  */
  procedure InsertAssignment(iSessionID number)
  is
  begin
    insert into FAL_GAN_ASSIGNMENT
                (FAL_GAN_ASSIGNMENT_ID
               , FGA_IS_RESULT
               , FAL_GAN_RESOURCE_GROUP_ID
               , FAL_GAN_TIMING_RESOURCE_ID
               , FAL_GAN_OPERATION_ID
               , FAL_GAN_SESSION_ID
                )
      select FAL_TMP_RECORD_SEQ.nextval
           , 0
           , FGO.FAL_GAN_RESOURCE_GROUP_ID
           , FGO.FAL_GAN_TIMING_RESOURCE_ID
           , FGO.FAL_GAN_OPERATION_ID
           , FGO.FAL_GAN_SESSION_ID
        from FAL_GAN_OPERATION FGO
       where FGO.FAL_GAN_SESSION_ID = iSessionID;
  end InsertAssignment;

  /**
  * Description
  *    Insertion des donn�es � traiter dans la table GAN_OPERATION_LINK contenant les liens entre op�rations
  *    et mise � jour de la dur�e de la derni�re op�ration d'un groupe d'op. p// pour qu'elle ait la m�me dur�e
  *    que la plus longue du groupe.
  */
  procedure InsertOperationLinks(iSessionID in number, iParallelWorkAroundMode in integer default 1)
  is
    /* Collection regroupant les op�rations auxquelles il faut ajouter les liens */
    tplOperations    TOperations;
    /* Collection regroupant les liens � ins�rer */
    tplLinks         TLinks;
    /* Stocke l'ID du lot de rla derni�re op�ration trait�e */
    nLastTaskID      number       := 0;
    /* Stocke l'ID de la derni�re op�ration trait�e */
    nLastOperationID number       := 0;
    /* Stocke la dur�e la plus longue d'une s�rie d'op�rations parall�les successives */
    nMaxOpDuration   number       := 0;
    /* Stocke la s�quence de l'op�ration ayant la dur�e la plus longue d'une s�rie d'op. parall�les successives */
    nMaxOpSequence   number       := 0;
    /* Stocke le retard cumul� d'une s�rie d'op�rations parall�les successives. */
    nCumulativeDelay number       := 0;
    /* Stocke le type de lien entre op�ration */
    vLinKType        varchar2(10) := 'FS';
    /* Compteur pour le parcours des liens */
    nLinkIdx         number;
  begin
    -- R�cup�ration des op�rations
    open crOperations(iSessionID);

    fetch crOperations
    bulk collect into tplOperations;

    close crOperations;

    -- Pas d'op�rations, inutile d'aller plus loin. Ce cas ne devrait jamais arriver.
    if tplOperations.count = 0 then
      return;
    end if;

    for i in tplOperations.first .. tplOperations.last loop
      if     nLastTaskID = 0
         and nLastOperationID = 0 then
        nLastTaskID       := tplOperations(i).FAL_GAN_TASK_ID;
        nLastOperationID  := tplOperations(i).FAL_GAN_OPERATION_ID;
        -- On est sur la premi�re op�ration de la table FAL_GAN_OPERATION, inutile de continuer le traitement sur cette op�ration..
        continue;
      end if;

      -- On est sur une op�ration du m�me lot.
      if nLastTaskID = tplOperations(i).FAL_GAN_TASK_ID then
        if    tplOperations(i).FGO_PARALLEL = cstParallelFlag
           or tplOperations(i).FGO_PARALLEL > 0 then   -- Op�ration parall�le
          vLinKType  := 'SS';   -- Type de lien = d�but-d�but
          -- M�morisation de la plus grand op�ration parall�le du groupe.
          pDefineMaxOpDuration(tplOperations(i - 1), nMaxOpDuration, nMaxOpSequence, nCumulativeDelay);
        else   -- Op�ration Successeur
          vLinKType  := 'FS';   -- Type de lien = fin - d�but

          if    tplOperations(i - 1).FGO_PARALLEL = cstParallelFlag
             or tplOperations(i - 1).FGO_PARALLEL > 0 then
            -- M�morisation de la plus grand op�ration parall�le.
            pDefineMaxOpDuration(tplOperations(i - 1), nMaxOpDuration, nMaxOpSequence, nCumulativeDelay);
            -- Application du workaround pour contourner le fait que le composant XGantt ne g�re pas le parall�lisme au niveau des op�rations, mais unquement
            -- au niveau des lots. Pour contourner ce probl�me, 3 solutions sont possibles en fonction de la valeur de iParallelWorkAroundMode. Cette valeur
            -- est d�finie dans le param�tre d'objet 'FAL_GANTT_OP_WORKAROUND_MODE'. Valeur par d�faut = 1.
            -- Valeur = 0 : Pas de workAround.
            -- Valeur = 1 : Ajout d'un 'temp mort' dans le temps de transfert de la derni�re op�ration du bloc pour qu'elle soit aussi la plus longue du bloc.
            -- Valuer = 2 : Inversion de la derni�re op�ration avec la plus longue du bloc.
            pApplyOpWorkAround(tplOperations(i - 1), nMaxOpDuration, nMaxOpSequence, nCumulativeDelay, nLastOperationID, iParallelWorkAroundMode, TplLinks);
            nMaxOpDuration    := 0;
            nMaxOpSequence    := 0;
            nCumulativeDelay  := 0;
          end if;
        end if;

        -- Cr�ation du lien entre op�rations
        TplLinks(tplOperations(i).FAL_GAN_OPERATION_ID).FAL_GAN_LINK_ID                 := FAL_TMP_RECORD_SEQ.nextval;
        TplLinks(tplOperations(i).FAL_GAN_OPERATION_ID).C_LINK_TYPE                     := vLinKType;
        TplLinks(tplOperations(i).FAL_GAN_OPERATION_ID).FAL_GAN_PRED_OPERATION_ID       := nLastOperationID;
        TplLinks(tplOperations(i).FAL_GAN_OPERATION_ID).FAL_GAN_SUCC_OPERATION_ID       := tplOperations(i).FAL_GAN_OPERATION_ID;
        TplLinks(tplOperations(i).FAL_GAN_OPERATION_ID).FAL_GAN_NEXT_SUCC_OPERATION_ID  := tplOperations(i).NEXT_OPERATION_ID;

        if    (tplOperations(i).FGO_PARALLEL = cstParallelFlag
           or     tplOperations(i).FGO_PARALLEL > 0)
              and i = tplOperations.last then   -- Op�ration parall�le
          -- Si on est sur la derni�re op�ration du curseur qui est parall�le.
          -- Appliquer �galement le workaround sur tplOperations(i) s'il s'agit de la derni�re op�ration du curseur de type parall�le.
          pApplyOpWorkAround(tplOperations(i), nMaxOpDuration, nMaxOpSequence, nCumulativeDelay, nLastOperationID, iParallelWorkAroundMode, TplLinks);
          nMaxOpDuration    := 0;
          nMaxOpSequence    := 0;
          nCumulativeDelay  := 0;
        end if;
      -- Changement d'OF. La derni�re op�ration de l'OF pr�c�dent �tait parall�le. Il faut donc appliquer le workaround.
      elsif    tplOperations(i - 1).FGO_PARALLEL = cstParallelFlag
            or tplOperations(i - 1).FGO_PARALLEL > 0 then   -- Op�ration parall�le
        -- Application du workaround pour contourner le fait que le composant XGantt ne g�re pas le parall�lisme au niveau des op�rations, mais unquement
        -- au niveau des lots. Pour contourner ce probl�me, 3 solutions sont possibles en fonction de la valeur de iParallelWorkAroundMode. Cette valeur
        -- est d�finie dans le param�tre d'objet 'FAL_GANTT_OP_WORKAROUND_MODE'. Valeur par d�faut = 1.
        -- Valeur = 0 : Pas de workAround.
        -- Valeur = 1 : Ajout d'un 'temp mort' dans le temps de transfert de la derni�re op�ration du bloc pour qu'elle soit aussi la plus longue du bloc.
        -- Valuer = 2 : Inversion de la derni�re op�ration avec la plus longue du bloc.
        pApplyOpWorkAround(tplOperations(i - 1), nMaxOpDuration, nMaxOpSequence, nCumulativeDelay, nLastOperationID, iParallelWorkAroundMode, TplLinks);
        nMaxOpDuration    := 0;
        nMaxOpSequence    := 0;
        nCumulativeDelay  := 0;
      end if;

      nLastTaskID       := tplOperations(i).FAL_GAN_TASK_ID;
      nLastOperationID  := tplOperations(i).FAL_GAN_OPERATION_ID;
    end loop;

    -- Insertion des liens
    nLinkIdx  := tplLinks.first;

    while(nLinkIdx is not null) loop
      insert into FAL_GAN_LINK
                  (FAL_GAN_LINK_ID
                 , C_LINK_TYPE
                 , FGL_BETWEEN_OP
                 , FAL_GAN_SESSION_ID
                 , FAL_GAN_PRED_OPERATION_ID
                 , FAL_GAN_SUCC_OPERATION_ID
                  )
           values (tplLinks(nLinkIdx).FAL_GAN_LINK_ID
                 , tplLinks(nLinkIdx).C_LINK_TYPE
                 , 1
                 , iSessionID
                 , tplLinks(nLinkIdx).FAL_GAN_PRED_OPERATION_ID
                 , tplLinks(nLinkIdx).FAL_GAN_SUCC_OPERATION_ID
                  );

      nLinkIdx  := tplLinks.next(nLinkIdx);
    end loop;
  end InsertOperationLinks;

  /**
  * procedure : ApplyFilter
  * Description : S�lectionne les op�ration � afficher parmis celles � planifier
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iSessionID       Session
  */
  procedure ApplyFilter(iSessionID in FAL_GAN_SESSION.FAL_GAN_SESSION_ID%type)
  is
    lnTimingResourceByProductID number;

    cursor crFilter
    is
      select FGO.FAL_GAN_OPERATION_ID
        from FAL_GAN_OPERATION FGO
       where FGO.FAL_GAN_OPERATION_ID in(
               select FGO.FAL_GAN_OPERATION_ID
                 from FAL_GAN_OPERATION FGO
                    , FAL_GAN_TASK FGT
                where FGT.FAL_GAN_SESSION_ID = iSessionID
                  and FGT.FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID
                  and (   FGT.FAL_LOT_PROP_ID in(select COM_LIST_ID_TEMP_ID
                                                   from COM_LIST_ID_TEMP
                                                  where LID_CODE = 'FAL_LOT_PROP_ID')
                       or FGT.FAL_LOT_ID in(select COM_LIST_ID_TEMP_ID
                                              from COM_LIST_ID_TEMP
                                             where LID_CODE = 'FAL_LOT_ID'
                                                or LID_CODE = 'FAL_LOT_SSTA')
                      )
                  and FGT.GCO_GOOD_ID in(select COM_LIST_ID_TEMP_ID
                                           from COM_LIST_ID_TEMP
                                          where LID_CODE = 'GCO_GOOD_ID') )
         and (    (FGO.FAL_GAN_TIMING_RESOURCE_ID in(
                                                   select FAL_GAN_TIMING_RESOURCE_ID
                                                     from FAL_GAN_TIMING_RESOURCE FTR
                                                    where nvl(FTR.FAL_FACTORY_FLOOR_ID, PAC_SUPPLIER_PARTNER_ID) in(
                                                                                                                   select COM_LIST_ID_TEMP_ID
                                                                                                                     from COM_LIST_ID_TEMP
                                                                                                                    where LID_CODE =
                                                                                                                                    'FAL_GAN_TIMING_RESOURCE_ID') )
                  )
              or (FGO.FAL_GAN_RESOURCE_GROUP_ID in(select FAL_GAN_RESOURCE_GROUP_ID
                                                     from FAL_GAN_RESOURCE_GROUP FGG
                                                    where FGG.FAL_FACTORY_FLOOR_ID in(select COM_LIST_ID_TEMP_ID
                                                                                        from COM_LIST_ID_TEMP
                                                                                       where LID_CODE = 'FAL_GAN_TIMING_RESOURCE_ID') ) )
              or FGO.FAL_GAN_TIMING_RESOURCE_ID = lnTimingResourceByProductID
             );
  begin
    -- Ressource virtuelle pour les gammes selon produit
    lnTimingResourceByProductID  := FAL_GANTT_COMMON_FCT.GetTimingResourceByProductID(iSessionID);

    for tplFilter in crFilter loop
      update FAL_GAN_OPERATION FGO
         set FGO_FILTER = 1
       where FGO.FAL_GAN_OPERATION_ID = tplFilter.FAL_GAN_OPERATION_ID;
    end loop;
  end Applyfilter;

  /**
  * procedure : CheckSSTAResourceModify
  * Description : Fonction qui v�rifie la possibilit� de changer la resource d'une op�ration
  *               R�gles : 1 - Fabrication hors sous-traitance -> Possible
  *                        2 - Sous-traitance, document -> impossible
  *                        3 - Sous-traitance, Propositions -> possibilit�s sur les ressources des donn�es
  *                            compl�mentaires valides du produit.
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iFalTaskId       op�ration
  * @param   iNewResourceId   Nouvelle ressource
  * @param   iOldResourceId   Ancienne ressource
  * @param   iDateReference   Date r�f pour recherche validit� de la DCompl�mentaire
  * @param   ioNewDuration    Nouvelle dur�e planifi�e
  * @param   ioNewEndDate     Nouvelle date fin
  * @param   ioWarningMsg     Message d'avertissement
  * @param   ioComplDataId    Nouvelle donn�e compl. Valide
  * @param   ioAllowModify    Modification autoris�e
  * @param   ioUpdateDuration Modification de dur�e requise
  */
  procedure CheckSSTAResourceModify(
    iFalTaskId       in     number
  , iNewResourceId   in     number
  , iOldResourceId   in     number
  , iDateReference   in     date
  , ioNewDuration    in out number
  , ioNewEndDate     in out date
  , ioWarningMsg     in out varchar2
  , ioComplDataId    in out number
  , ioAllowModify    in out integer
  , ioUpdateDuration in out integer
  )
  is
    lvCFabType                   varchar2(10);
    lnFalLotId                   number;
    lnFalLotPropId               number;
    lnGcoGoodId                  number;
    ltGCO_COMPL_DATA_SUBCONTRACT GCO_COMPL_DATA_SUBCONTRACT%rowtype;
    lnPacSupplierPartnerId       number;
    lnLotTotalQty                number;
    ldCommandDelay               date;
    lnDurationInDays             number;
    lnStatusLinkedCST            varchar2(10);
  begin
    ioNewDuration     := 0;
    ioNewEndDate      := null;
    ioWarningMsg      := null;
    ioComplDataId     := null;
    ioAllowModify     := 1;
    ioUpdateDuration  := 0;

    select nvl(FGT.C_FAB_TYPE, FAL_BATCH_FUNCTIONS.btManufacturing)
         , FGT.FAL_LOT_ID
         , FGT.FAL_LOT_PROP_ID
         , FGT.GCO_GOOD_ID
         , (select PAC_SUPPLIER_PARTNER_ID
              from FAL_GAN_TIMING_RESOURCE
             where FAL_GAN_TIMING_RESOURCE_ID = iNewResourceId)
         , FGT.FGT_LOT_TOTAL_QTY
         , (select min(DOC.C_DOCUMENT_STATUS)
              from DOC_DOCUMENT DOC
                 , DOC_POSITION POS
             where POS.FAL_SCHEDULE_STEP_ID = FGO.FAL_SCHEDULE_STEP_ID
               and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
               and DOC_LIB_SUBCONTRACTO.IsSUOOGauge(DOC.DOC_GAUGE_ID) = 1)
      into lvCFabType
         , lnFalLotId
         , lnFalLotPropId
         , lnGcoGoodId
         , lnPacSupplierPartnerId
         , lnLotTotalQty
         , lnStatusLinkedCST
      from FAL_GAN_TASK FGT
         , FAL_GAN_OPERATION FGO
     where FGO.FAL_GAN_OPERATION_ID = iFalTaskId
       and FGO.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID;

    if nvl(lnStatusLinkedCST, '01') <> '01' then
      -- Toute modification impossible s'il existe des documents confirm�s
      ioAllowModify  := 0;
      ioWarningMsg   := PCS.PC_FUNCTIONS.TranslateWord('Impossible de d�placer l''op�ration. Des documents confim�es li�s � cette op�ration existent.');
      return;
    elsif iNewResourceId = iOldResourceId then
      -- Ok si on ne change pas de ressource
      return;
    else
      -- changement de ressource
      if lvCFabType <> FAL_BATCH_FUNCTIONS.btSubcontract then
        -- Fabrication standard
        if lnStatusLinkedCST is not null then
          ioAllowModify  := 0;
          ioWarningMsg   := PCS.PC_FUNCTIONS.TranslateWord('Impossible de changer la ressource. Des documents ont �t� g�n�r�s pour cette op�ration.');
        end if;

        return;
      else
        -- Sous traitance d'achat
        -- Document = Lot, alors il est trop tard pour modifier la ressource
        if lnFalLotId is not null then
          ioAllowModify  := 0;
          ioWarningMsg   := PCS.PC_FUNCTIONS.TranslateWord('Impossible de changer la ressource d''un document de sous-traitance d''achat!');
          return;
        -- Proposition de sous-traitance d'achat -> Possibilit� de changer pour une resource d'une des donn�es compl�mentaires valides
        else
          -- Recherche de la nouvelle resource dans les donn�es compl�menataires valides du produit
          ltGCO_COMPL_DATA_SUBCONTRACT  := GCO_LIB_COMPL_DATA.GetDefaultSubCComplData(lnGcoGoodId, lnPacSupplierPartnerId, null, iDateReference);

          -- Non trouv�e
          if ltGCO_COMPL_DATA_SUBCONTRACT.GCO_COMPL_DATA_SUBCONTRACT_ID is null then
            ioAllowModify  := 0;
            ioWarningMsg   :=
              PCS.PC_FUNCTIONS.TranslateWord('Impossible de passer cette proposition d''achat sous-traitance sur cette ressource!') ||
              chr(13) ||
              PCS.PC_FUNCTIONS.TranslateWord('Ressource non pr�sente dans les donn�es compl�mentaires valides du produit!');
          -- Trouv�e, recalcul des dur�es et dates fin
          else
            ldCommandDelay    := iDateReference;
            FAL_SUPPLY_REQUEST_FUNCTIONS.GetSubcPSupplyRequestDelay(lnGcoGoodId
                                                                  , lnPacSupplierPartnerId
                                                                  , ltGCO_COMPL_DATA_SUBCONTRACT.DIC_FAB_CONDITION_ID
                                                                  , lnLotTotalQty
                                                                  , iDateReference
                                                                  , 1
                                                                  , lnDurationInDays
                                                                  , ldCommandDelay
                                                                  , ioNewEndDate
                                                                   );
            ioUpdateDuration  := 1;
            ioNewDuration     := FAL_PLANIF.GetDurationInMinutes(null, lnPacSupplierPartnerId, lnDurationInDays, ldCommandDelay);
          end if;
        end if;
      end if;
    end if;
  exception
    when others then
      ioAllowModify  := 1;
  end CheckSSTAResourceModify;

  /**
  * Description
  *    Insertion des charges et assignations pour le th�me industrie
  */
  procedure InsertDatas(
    iSessionID              in number
  , iHorizonStart           in date default null
  , iHorizonEnd             in date default null
  , iPlannedBatch           in integer default 0
  , iLaunchedBatch          in integer default 0
  , iSTDBatch               in integer default 1
  , iPRPBatch               in integer default 0
  , iDFBatch                in integer default 0
  , iSAVBatch               in integer default 0
  , iMRPProp                in integer default 0
  , iPDPProp                in integer default 0
  , iSSTADoc                in integer default 0
  , iDocToBeConfirmed       in integer default 0
  , iDocToBalance           in integer default 0
  , iSSTAMRPProp            in integer default 0
  , iSSTAPDPProp            in integer default 0
  , iParallelWorkAroundMode in integer default 1
  )
  is
  begin
    -- Suppressions des avertissements
    FAL_GANTT_COMMON_FCT.DeleteException(iSessionID);
    -- Chargement des t�ches
    pInsertTask(iSessionID
              , iHorizonStart
              , iHorizonEnd
              , iPlannedBatch
              , iLaunchedBatch
              , iSTDBatch
              , iPRPBatch
              , iSAVBatch
              , iMRPProp
              , iPDPProp
              , iSSTADoc
              , iDocToBeConfirmed
              , iDocToBalance
              , iSSTAMRPProp
              , iSSTAPDPProp
               );

    if (iDFBatch = 1) then
      GAL_GANTT_FCT.InsertTask(iSessionId       => iSessionId
                             , iPRPTask         => iPRPBatch
                             , iDFTask          => iDFBatch
                             , iHorizonStart    => iHorizonStart
                             , iHorizonEnd      => iHorizonEnd
                             , iPlannedBatch    => iPlannedBatch
                             , iLaunchedBatch   => iLaunchedBatch
                              );
    end if;

    -- Chargement table des op�rations
    pInsertOperation(iSessionID);

    if (iDFBatch = 1) then
      GAL_GANTT_FCT.InsertOperation(iSessionId       => iSessionID
                                  , iPRPOperation    => iPRPBatch
                                  , iDFOperation     => iDFBatch
                                  , iPlannedBatch    => iPlannedBatch
                                  , iLaunchedBatch   => iLaunchedBatch
                                   );
    end if;

    FinalizeOperation(iSessionID);
    -- Chargement de la table des assignations
    InsertAssignment(iSessionID);
    -- Chargement de la table des liens multiniveaux
    pInsertMultiLevelLinks(iSessionID);

    if (iDFBatch = 1) then
      GAL_GANTT_FCT.InsertMultiLevelLinks(iSessionID, 0, iDFBatch);
    end if;

    -- Mise � jour de la priorit� d'ordonnancement
    pUpdatePlanningPriority(iSessionID);
    -- Chargement de la table des liens entre op�rations
    InsertOperationLinks(iSessionID, iParallelWorkAroundMode);
    -- Chargement de la table des dates d'achat et d'appro log
    pInsertLinkedRequirements(iSessionID);

    if (iDFBatch = 1) then
      GAL_GANTT_FCT.InsertLinkedRequirements(iSessionID);
    end if;

    FinalizeLinkedRequirements(iSessionID);
    -- Application des filtres
    ApplyFilter(iSessionID);

    if (iDFBatch = 1) then
      GAL_GANTT_FCT.ApplyFilter(iSessionID, 0);
    end if;

    -- Check des donn�es
    pCheckDatas(iSessionID);
  end InsertDatas;
end FAL_GANTT_FCT;
