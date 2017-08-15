--------------------------------------------------------
--  DDL for Package Body PPS_NOMENCLATURE_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PPS_NOMENCLATURE_FCT" 
is
  vAuthorizedTypes varchar2(4000);

/**************************************************************************************************/
  procedure NOM_GENERATION_BY_COPY(
    pNEW0_ERASE1_COMPLETE2_NOM in     number
  , pORIGIN_GOOD_ID            in     PPS_NOMENCLATURE.GCO_GOOD_ID%type
  , pTARGET_GOOD_ID            in     PPS_NOMENCLATURE.GCO_GOOD_ID%type
  , pORIGIN_NOM_ID             in     PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , pTARGET_NOM_ID             in     PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , pC_TYPE_NOM                in     PPS_NOMENCLATURE.C_TYPE_NOM%type
  , pNOM_VERSION               in     PPS_NOMENCLATURE.NOM_VERSION%type
  , pNOM_REF_QTY               in     PPS_NOMENCLATURE.NOM_REF_QTY%type
  , pKEEP_TARGET_ORIGIN_BOTH   in     number
  , pSUCCESSION_SORT           in     number
  , pKEEPTARGET_USEORIGIN_QTY  in     number
  , pNEWNOMID                  in out PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  )
  is
    vTargetRangeId      PPS_NOMENCLATURE.PPS_RANGE_ID%type;   /* Id gamme nomenclature cible                        */
    vOriginRangeId      PPS_NOMENCLATURE.PPS_RANGE_ID%type;   /* Id gamme nomenclature source                       */
    vTargetPlanId       PPS_NOMENCLATURE.FAL_SCHEDULE_PLAN_ID%type;   /* GAmme nomenclature cible                           */
    vOriginPlanId       PPS_NOMENCLATURE.FAL_SCHEDULE_PLAN_ID%type;   /* Gamme nomenclature source                          */
    vCopyRangeOperation number;   /* Indique la reprise de l'opération des composants   */
    vCopyScheduleStep   number;   /* Indique la reprise du lien tâche des composants    */
  begin
    pNewNomId  := pTARGET_NOM_ID;   /* Nomenclature modifiée est par défaut la cible      */

    if pNEW0_ERASE1_COMPLETE2_NOM <> 0 then   /* Ecrasement ou Complément                           */
      select PPS_RANGE_ID
           , FAL_SCHEDULE_PLAN_ID   /* Réception des gamme de  la nomenclature cible      */
        into vTargetRangeId
           , vTargetPlanId   /* et source                                          */
        from PPS_NOMENCLATURE   /* permettra d'initialiser l'opération de gamme       */
       where PPS_NOMENCLATURE_ID = pTARGET_NOM_ID;   /* et le lien tâche des composants si équivalence     */
                                                     /* entre val.sources et cibles                        */

      select PPS_RANGE_ID
           , FAL_SCHEDULE_PLAN_ID
        into vOriginRangeId
           , vOriginPlanId
        from PPS_NOMENCLATURE
       where PPS_NOMENCLATURE_ID = pORIGIN_NOM_ID;

      vCopyRangeOperation  := 0;   /* Pas de reprise de l'opération des composants       */
      vCopyScheduleStep    := 0;   /* Pas de reprise du lien tâche des composants        */

      if vTargetRangeId = vOriginRangeId then   /* Reprise de l'opération des composants              */
        vCopyRangeOperation  := 1;   /* si Gamme source = Gamme cible                      */
      end if;

      if vTargetPlanId = vOriginPlanId then   /* Reprise du lien tâche des composants               */
        vCopyScheduleStep  := 1;   /* si Gamme source = Gamme cible                      */
      end if;

      if pKEEPTARGET_USEORIGIN_QTY = 1 then   /*La qté référence est déjà initialisée avec la bonne*/
        update PPS_NOMENCLATURE   /*valeur (cible ou source selon la variable )        */
           set NOM_REF_QTY = pNOM_REF_QTY   /*Aussi on ne traite que le cas ou on utilise la qté */
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where PPS_NOMENCLATURE_ID = pTARGET_NOM_ID;   /*source                                             */
      end if;
    end if;

    if pNEW0_ERASE1_COMPLETE2_NOM = 0 then   /* Nouvelle nomenclature                              */
      CREATE_NEW_NOMENCLATURE(pORIGIN_NOM_ID, pTARGET_GOOD_ID, pC_TYPE_NOM, pNOM_VERSION, pNOM_REF_QTY, null, pNEWNOMID);
    elsif pNEW0_ERASE1_COMPLETE2_NOM = 1 then   /* Ecraser les composants de la nomenclature cible    */
      ERASE_NOM_COMPONENT(pTARGET_NOM_ID,   /* par les composants de la nomenclature source       */
                          pORIGIN_NOM_ID, pTARGET_GOOD_ID, pNOM_REF_QTY, vCopyRangeOperation, vCopyScheduleStep);
    elsif pNEW0_ERASE1_COMPLETE2_NOM = 2 then   /* Compléter les composants de la nomenclature cible  */
      COMPLETE_NOM_COMPONENT(pTARGET_NOM_ID,   /* par les composants de la nomenclature source       */
                             pORIGIN_NOM_ID, pTARGET_GOOD_ID, pKEEP_TARGET_ORIGIN_BOTH, pNOM_REF_QTY, vCopyRangeOperation, vCopyScheduleStep);
      RENUMBERING_COMPONENT(pTARGET_NOM_ID, pSUCCESSION_SORT, 1   /* tri ascendant                */
                                                               );
    end if;
  end;

/**************************************************************************************************/
  procedure CREATE_NEW_NOMENCLATURE(
    pORIGIN_NOM_ID  in     PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , pTARGET_GOOD_ID in     PPS_NOMENCLATURE.GCO_GOOD_ID%type
  , pC_TYPE_NOM     in     PPS_NOMENCLATURE.C_TYPE_NOM%type
  , pNOM_VERSION    in     PPS_NOMENCLATURE.NOM_VERSION%type
  , pNOM_REF_QTY    in     PPS_NOMENCLATURE.NOM_REF_QTY%type
  , pDOC_RECORD_ID  in     PPS_NOMENCLATURE.DOC_RECORD_ID%type
  , pNEWNOMID       in out PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  )
  is
    vNOM_MARK_NOMENCLATURE PPS_NOMENCLATURE.NOM_MARK_NOMENCLATURE%type;
    lOriginTypNom          PPS_NOMENCLATURE.C_TYPE_NOM%type;
  begin
    select INIT_ID_SEQ.nextval
      into pNewNomId   /* Génération d'un nouvel Id                          */
      from dual;

    -- Vérifier si la nomenclature source et le bien cible gèrent les repères topologiques
    select case
             when NOM.NOM_MARK_NOMENCLATURE = 1
             and (select nvl(max(PDT.PDT_MARK_NOMENCLATURE), 0)
                    from GCO_PRODUCT PDT
                   where PDT.GCO_GOOD_ID = pTARGET_GOOD_ID) = 1 then 1
             else 0
           end NOM_MARK_NOMENCLATURE
         , C_TYPE_NOM
      into vNOM_MARK_NOMENCLATURE
         , lOriginTypNom
      from PPS_NOMENCLATURE NOM
     where NOM.PPS_NOMENCLATURE_ID = pORIGIN_NOM_ID;

    /*Création de la nouvelle nomenclature*/
    insert into PPS_NOMENCLATURE
                (PPS_NOMENCLATURE_ID
               , GCO_GOOD_ID
               , C_TYPE_NOM
               , NOM_TEXT
               , NOM_REF_QTY
               , A_DATECRE
               , A_IDCRE
               , NOM_VERSION
               , C_REMPLACEMENT_NOM
               , NOM_BEG_VALID
               , NOM_DEFAULT
               , FAL_SCHEDULE_PLAN_ID
               , PPS_RANGE_ID
               , NOM_MARK_NOMENCLATURE
               , DOC_RECORD_ID
                )
      select pNewNomId
           , pTARGET_GOOD_ID
           , pC_TYPE_NOM
           , NOM_TEXT
           , pNOM_REF_QTY
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , pNOM_VERSION
           , C_REMPLACEMENT_NOM
           , NOM_BEG_VALID
           , 0
           , FAL_SCHEDULE_PLAN_ID
           , PPS_RANGE_ID
           , vNOM_MARK_NOMENCLATURE
           , pDOC_RECORD_ID
        from PPS_NOMENCLATURE
       where PPS_NOMENCLATURE_ID = pORIGIN_NOM_ID;

    /*Création des composants*/
    insert into PPS_NOM_BOND
                (PPS_NOM_BOND_ID
               , PPS_NOMENCLATURE_ID
               , PPS_RANGE_OPERATION_ID
               , STM_LOCATION_ID
               , GCO_GOOD_ID
               , C_REMPLACEMENT_NOM
               , C_TYPE_COM
               , C_DISCHARGE_COM
               , C_KIND_COM
               , COM_SEQ
               , COM_TEXT
               , COM_RES_TEXT
               , COM_RES_NUM
               , COM_VAL
               , COM_SUBSTITUT
               , COM_POS
               , COM_UTIL_COEFF
               , COM_PDIR_COEFF
               , COM_REC_PCENT
               , COM_INTERVAL
               , COM_BEG_VALID
               , COM_END_VALID
               , COM_REMPLACEMENT
               , A_DATECRE
               , A_IDCRE
               , STM_STOCK_ID
               , FAL_SCHEDULE_STEP_ID
               , PPS_PPS_NOMENCLATURE_ID
               , COM_REF_QTY
               , COM_PERCENT_WASTE
               , COM_FIXED_QUANTITY_WASTE
               , COM_QTY_REFERENCE_LOSS
               , COM_MARK_TOPO
                )
      select INIT_ID_SEQ.nextval
           , pNewNomId
           , PPS_RANGE_OPERATION_ID
           , STM_LOCATION_ID
           , GCO_GOOD_ID
           , C_REMPLACEMENT_NOM
           , C_TYPE_COM
           , C_DISCHARGE_COM
           , C_KIND_COM
           , COM_SEQ
           , COM_TEXT
           , COM_RES_TEXT
           , COM_RES_NUM
           , COM_VAL
           , COM_SUBSTITUT
           , COM_POS
           , COM_UTIL_COEFF
           , COM_PDIR_COEFF
           , COM_REC_PCENT
           , COM_INTERVAL
           , COM_BEG_VALID
           , COM_END_VALID
           , COM_REMPLACEMENT
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , STM_STOCK_ID
           , FAL_SCHEDULE_STEP_ID
           , decode(lOriginTypNom, pC_TYPE_NOM, PPS_PPS_NOMENCLATURE_ID, GetDefaultNomenclature(GCO_GOOD_ID, decode(pC_TYPE_NOM, '6', '2', pC_TYPE_NOM) ) )
           , pNOM_REF_QTY
           , COM_PERCENT_WASTE
           , COM_FIXED_QUANTITY_WASTE
           , COM_QTY_REFERENCE_LOSS
           , case
               when vNOM_MARK_NOMENCLATURE = 1 then COM_MARK_TOPO
               else null
             end COM_MARK_TOPO
        from PPS_NOM_BOND
       where PPS_NOMENCLATURE_ID = pORIGIN_NOM_ID
         and (   GCO_GOOD_ID <> pTARGET_GOOD_ID
              or GCO_GOOD_ID is null);   /*Le composant ne peut être égale au composé*/

    -- Copier les repères topologiques si nomenclature source et bien cible gèrent ceux-ci
    if vNOM_MARK_NOMENCLATURE = 1 then
      insert into PPS_MARK_BOND
                  (PPS_MARK_BOND_ID
                 , PPS_NOMENCLATURE_ID
                 , GCO_GOOD_ID
                 , FAL_SCHEDULE_STEP_ID
                 , PMB_PREFIX
                 , PMB_NUMBER
                 , PMB_SUFFIX
                 , PMB_MARK_TOPO
                 , A_DATECRE
                 , A_IDCRE
                  )
        select INIT_ID_SEQ.nextval
             , pNewNomId
             , GCO_GOOD_ID
             , FAL_SCHEDULE_STEP_ID
             , PMB_PREFIX
             , PMB_NUMBER
             , PMB_SUFFIX
             , PMB_MARK_TOPO
             , sysdate as A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from PPS_MARK_BOND
         where PPS_NOMENCLATURE_ID = pORIGIN_NOM_ID
           and GCO_GOOD_ID <> pTARGET_GOOD_ID;   /*Le composant ne peut être égale au composé */
    end if;
  end;

/**************************************************************************************************/
  procedure ERASE_NOM_COMPONENT(
    pTARGET_NOM_ID      in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , pORIGIN_NOM_ID      in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , pTARGET_GOOD_ID     in PPS_NOMENCLATURE.GCO_GOOD_ID%type
  , pNOM_REF_QTY        in PPS_NOMENCLATURE.NOM_REF_QTY%type
  , pCopyRangeOperation in number
  , pCopyScheduleStep   in number
  )
  is
  begin
    delete   /*Supression des composants de la nom. cible          */
           from PPS_NOM_BOND
          where PPS_NOMENCLATURE_ID = pTARGET_NOM_ID;

    /*Création des composants*/
    insert into PPS_NOM_BOND
                (PPS_NOM_BOND_ID   /*ID lien nomenclature                                */
               , PPS_NOMENCLATURE_ID   /*ID Nomenclature                                     */
               , PPS_RANGE_OPERATION_ID   /*ID opération de gamme                               */
               , STM_LOCATION_ID   /*ID emplacement de stock                             */
               , GCO_GOOD_ID   /*ID bien                                             */
               , C_REMPLACEMENT_NOM   /*Condition de remplacement                           */
               , C_TYPE_COM   /*Type de lien nomenclature                           */
               , C_DISCHARGE_COM   /*Décharge                                            */
               , C_KIND_COM   /*Genre de lien nomenclature                          */
               , COM_SEQ   /*Séquence lien                                       */
               , COM_TEXT   /*Texte                                               */
               , COM_RES_TEXT   /*Réserve texte                                       */
               , COM_RES_NUM   /*Réserve numérique                                   */
               , COM_VAL   /*Valorisation                                        */
               , COM_SUBSTITUT   /*Substitution                                        */
               , COM_POS   /*Position                                            */
               , COM_UTIL_COEFF   /*Utilisation                                         */
               , COM_PDIR_COEFF   /*Coefficient Plan directeur                          */
               , COM_REC_PCENT   /*Pourcentage recette                                 */
               , COM_INTERVAL   /*Décalage                                            */
               , COM_BEG_VALID   /*Début validité                                      */
               , COM_END_VALID   /*Fin validité                                        */
               , COM_REMPLACEMENT   /*Remplacement                                        */
               , A_DATECRE   /*Date de création                                    */
               , A_IDCRE   /*ID de création                                      */
               , STM_STOCK_ID   /*ID stock logique                                    */
               , FAL_SCHEDULE_STEP_ID   /*Lien tâche                                          */
               , PPS_PPS_NOMENCLATURE_ID   /*PPS_Nomenclature                                    */
               , COM_REF_QTY   /*Qté référence                                       */
               , COM_PERCENT_WASTE   /*Pourcentage de déchet                               */
               , COM_FIXED_QUANTITY_WASTE   /*Quantité fixe de déchet                             */
               , COM_QTY_REFERENCE_LOSS
                )   /*Quantité de référence perte                         */
      select INIT_ID_SEQ.nextval
           , pTARGET_NOM_ID   /*Lien sur la nomenclature cible                      */
           , decode(pCopyRangeOperation,   /*Reprise de l'opération de gamme ou mise à nul       */
                    1, PPS_RANGE_OPERATION_ID, null)
           , STM_LOCATION_ID
           , GCO_GOOD_ID
           , C_REMPLACEMENT_NOM
           , C_TYPE_COM
           , C_DISCHARGE_COM
           , C_KIND_COM
           , COM_SEQ
           , COM_TEXT
           , COM_RES_TEXT
           , COM_RES_NUM
           , COM_VAL
           , COM_SUBSTITUT
           , COM_POS
           , COM_UTIL_COEFF
           , COM_PDIR_COEFF
           , COM_REC_PCENT
           , COM_INTERVAL
           , COM_BEG_VALID
           , COM_END_VALID
           , COM_REMPLACEMENT
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , STM_STOCK_ID
           , decode(pCopyScheduleStep,   /*Reprise du lien tâche                               */
                    1, FAL_SCHEDULE_STEP_ID, null)
           , PPS_PPS_NOMENCLATURE_ID
           , pNOM_REF_QTY   /*Qté réf passé en paramètre                          */
           , COM_PERCENT_WASTE
           , COM_FIXED_QUANTITY_WASTE
           , COM_QTY_REFERENCE_LOSS
        from PPS_NOM_BOND
       where PPS_NOMENCLATURE_ID = pORIGIN_NOM_ID   /*Composants de la nomenclature source                */
         and GCO_GOOD_ID <> pTARGET_GOOD_ID;   /*Le composant ne peut être égale au composé          */
  end;

/**************************************************************************************************/
  procedure COMPLETE_NOM_COMPONENT(
    pTARGET_NOM_ID           in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , pORIGIN_NOM_ID           in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , pTARGET_GOOD_ID          in PPS_NOMENCLATURE.GCO_GOOD_ID%type
  , pKEEP_TARGET_ORIGIN_BOTH in number
  , pNOM_REF_QTY             in PPS_NOMENCLATURE.NOM_REF_QTY%type
  , pCopyRangeOperation      in number
  , pCopyScheduleStep        in number
  )
  is
    vLastSeq number;
  begin
    select nvl(max(COM_SEQ), 0)
      into vLastSeq   /*Réception du dernier n° composant de la nom. cible  */
      from PPS_NOM_BOND
     where PPS_NOMENCLATURE_ID = pTARGET_NOM_ID;

    /*Doublons --> On ne garde que les composants cibles i.e. on ne prend que les composants sources qui n'existent pas dans les */
    /*composants de la nomenclature cible*/
    if pKEEP_TARGET_ORIGIN_BOTH = 0 then
      /*Ajout de composants se trouvant dans la source mais non dans la cible                                                  */
      insert into PPS_NOM_BOND
                  (PPS_NOM_BOND_ID   /*ID lien nomenclature                                */
                 , PPS_NOMENCLATURE_ID   /*ID Nomenclature                                     */
                 , PPS_RANGE_OPERATION_ID   /*ID opération de gamme                               */
                 , STM_LOCATION_ID   /*ID emplacement de stock                             */
                 , GCO_GOOD_ID   /*ID bien                                             */
                 , C_REMPLACEMENT_NOM   /*Condition de remplacement                           */
                 , C_TYPE_COM   /*Type de lien nomenclature                           */
                 , C_DISCHARGE_COM   /*Décharge                                            */
                 , C_KIND_COM   /*Genre de lien nomenclature                          */
                 , COM_SEQ   /*Séquence lien                                       */
                 , COM_TEXT   /*Texte                                               */
                 , COM_RES_TEXT   /*Réserve texte                                       */
                 , COM_RES_NUM   /*Réserve numérique                                   */
                 , COM_VAL   /*Valorisation                                        */
                 , COM_SUBSTITUT   /*Substitution                                        */
                 , COM_POS   /*Position                                            */
                 , COM_UTIL_COEFF   /*Utilisation                                         */
                 , COM_PDIR_COEFF   /*Coefficient Plan directeur                          */
                 , COM_REC_PCENT   /*Pourcentage recette                                 */
                 , COM_INTERVAL   /*Décalage                                            */
                 , COM_BEG_VALID   /*Début validité                                      */
                 , COM_END_VALID   /*Fin validité                                        */
                 , COM_REMPLACEMENT   /*Remplacement                                        */
                 , A_DATECRE   /*Date de création                                    */
                 , A_IDCRE   /*ID de création                                      */
                 , STM_STOCK_ID   /*ID stock logique                                    */
                 , FAL_SCHEDULE_STEP_ID   /*Lien tâche                                          */
                 , PPS_PPS_NOMENCLATURE_ID   /*PPS_Nomenclature                                    */
                 , COM_REF_QTY   /*Qté référence                                       */
                 , COM_PERCENT_WASTE   /*Pourcentage de déchet                               */
                 , COM_FIXED_QUANTITY_WASTE   /*Quantité fixe de déchet                             */
                 , COM_QTY_REFERENCE_LOSS
                  )   /*Quantité de référence perte                         */
        select INIT_ID_SEQ.nextval
             , pTARGET_NOM_ID   /*Lien sur la nomenclature cible                      */
             , decode(pCopyRangeOperation,   /*Reprise de l'opération de gamme ou mise à nul       */
                      1, PPS_RANGE_OPERATION_ID, null)
             , STM_LOCATION_ID
             , GCO_GOOD_ID
             , C_REMPLACEMENT_NOM
             , C_TYPE_COM
             , C_DISCHARGE_COM
             , C_KIND_COM
             , vLastSeq + COM_SEQ
             , COM_TEXT
             , COM_RES_TEXT
             , COM_RES_NUM
             , COM_VAL
             , COM_SUBSTITUT
             , COM_POS
             , COM_UTIL_COEFF
             , COM_PDIR_COEFF
             , COM_REC_PCENT
             , COM_INTERVAL
             , COM_BEG_VALID
             , COM_END_VALID
             , COM_REMPLACEMENT
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
             , STM_STOCK_ID
             , decode(pCopyScheduleStep,   /*Reprise du lien tâche                               */
                      1, FAL_SCHEDULE_STEP_ID, null)
             , PPS_PPS_NOMENCLATURE_ID
             , pNOM_REF_QTY   /*Qté réf passé en paramètre                          */
             , COM_PERCENT_WASTE
             , COM_FIXED_QUANTITY_WASTE
             , COM_QTY_REFERENCE_LOSS
          from PPS_NOM_BOND ORIGIN_BOND
         where ORIGIN_BOND.PPS_NOMENCLATURE_ID = pORIGIN_NOM_ID   /*Composants de la nomenclature source                */
           and ORIGIN_BOND.GCO_GOOD_ID <> pTARGET_GOOD_ID   /*Le composant ne peut être égale au composé          */
           and not exists(
                 select 1
                   from PPS_NOM_BOND TARGET_BOND
                  where TARGET_BOND.PPS_NOMENCLATURE_ID = PTARGET_NOM_ID
                    and TARGET_BOND.GCO_GOOD_ID = ORIGIN_BOND.GCO_GOOD_ID
                    and TARGET_BOND.C_KIND_COM = ORIGIN_BOND.C_KIND_COM);
    else
      /*Suppression des composants cibles se trouvant dans les composants sources                                                */
      /* Si l'option est de garder les composants sources                                                                        */
      if pKEEP_TARGET_ORIGIN_BOTH = 1 then
        delete from PPS_NOM_BOND TARGET_BOND
              where PPS_NOMENCLATURE_ID = pTARGET_NOM_ID
                and exists(
                      select 1
                        from PPS_NOM_BOND ORIGIN_BOND
                       where ORIGIN_BOND.PPS_NOMENCLATURE_ID = pORIGIN_NOM_ID
                         and TARGET_BOND.GCO_GOOD_ID = ORIGIN_BOND.GCO_GOOD_ID
                         and TARGET_BOND.C_KIND_COM = ORIGIN_BOND.C_KIND_COM);
      end if;

      /*Ajout de tous les composants sources                                                                                     */
      insert into PPS_NOM_BOND
                  (PPS_NOM_BOND_ID   /*ID lien nomenclature                                */
                 , PPS_NOMENCLATURE_ID   /*ID Nomenclature                                     */
                 , PPS_RANGE_OPERATION_ID   /*ID opération de gamme                               */
                 , STM_LOCATION_ID   /*ID emplacement de stock                             */
                 , GCO_GOOD_ID   /*ID bien                                             */
                 , C_REMPLACEMENT_NOM   /*Condition de remplacement                           */
                 , C_TYPE_COM   /*Type de lien nomenclature                           */
                 , C_DISCHARGE_COM   /*Décharge                                            */
                 , C_KIND_COM   /*Genre de lien nomenclature                          */
                 , COM_SEQ   /*Séquence lien                                       */
                 , COM_TEXT   /*Texte                                               */
                 , COM_RES_TEXT   /*Réserve texte                                       */
                 , COM_RES_NUM   /*Réserve numérique                                   */
                 , COM_VAL   /*Valorisation                                        */
                 , COM_SUBSTITUT   /*Substitution                                        */
                 , COM_POS   /*Position                                            */
                 , COM_UTIL_COEFF   /*Utilisation                                         */
                 , COM_PDIR_COEFF   /*Coefficient Plan directeur                          */
                 , COM_REC_PCENT   /*Pourcentage recette                                 */
                 , COM_INTERVAL   /*Décalage                                            */
                 , COM_BEG_VALID   /*Début validité                                      */
                 , COM_END_VALID   /*Fin validité                                        */
                 , COM_REMPLACEMENT   /*Remplacement                                        */
                 , A_DATECRE   /*Date de création                                    */
                 , A_IDCRE   /*ID de création                                      */
                 , STM_STOCK_ID   /*ID stock logique                                    */
                 , FAL_SCHEDULE_STEP_ID   /*Lien tâche                                          */
                 , PPS_PPS_NOMENCLATURE_ID   /*PPS_Nomenclature                                    */
                 , COM_REF_QTY   /*Qté référence                                       */
                 , COM_PERCENT_WASTE   /*Pourcentage de déchet                               */
                 , COM_FIXED_QUANTITY_WASTE   /*Quantité fixe de déchet                             */
                 , COM_QTY_REFERENCE_LOSS
                  )   /*Quantité de référence perte                         */
        select INIT_ID_SEQ.nextval
             , pTARGET_NOM_ID   /*Lien sur la nomenclature cible                      */
             , decode(pCopyRangeOperation,   /*Reprise de l'opération de gamme ou mise à nul       */
                      1, PPS_RANGE_OPERATION_ID, null)
             , STM_LOCATION_ID
             , GCO_GOOD_ID
             , C_REMPLACEMENT_NOM
             , C_TYPE_COM
             , C_DISCHARGE_COM
             , C_KIND_COM
             , vLastSeq + COM_SEQ
             , COM_TEXT
             , COM_RES_TEXT
             , COM_RES_NUM
             , COM_VAL
             , COM_SUBSTITUT
             , COM_POS
             , COM_UTIL_COEFF
             , COM_PDIR_COEFF
             , COM_REC_PCENT
             , COM_INTERVAL
             , COM_BEG_VALID
             , COM_END_VALID
             , COM_REMPLACEMENT
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
             , STM_STOCK_ID
             , decode(pCopyScheduleStep,   /*Reprise du lien tâche                               */
                      1, FAL_SCHEDULE_STEP_ID, null)
             , PPS_PPS_NOMENCLATURE_ID
             , pNOM_REF_QTY   /*Qté réf passé en paramètre                          */
             , COM_PERCENT_WASTE
             , COM_FIXED_QUANTITY_WASTE
             , COM_QTY_REFERENCE_LOSS
          from PPS_NOM_BOND ORIGIN_BOND
         where ORIGIN_BOND.PPS_NOMENCLATURE_ID = pORIGIN_NOM_ID   /*Composants de la nomenclature source                */
           and ORIGIN_BOND.GCO_GOOD_ID <> pTARGET_GOOD_ID;   /*Le composant ne peut être égale au composé          */
    end if;
  end;

/**************************************************************************************************/
  procedure RENUMBERING_COMPONENT(pNOMENCLATURE_ID in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type, pORDER_BY in number, pASCENDANT in number)
  is
    /*Réception des composants de la nomenclature cible ordonnée par le composant pour effectuer le tri */
    cursor crComponentAsc(pNomenclatureId in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type)
    is
      select   PPS.PPS_NOM_BOND_ID
          from PPS_NOM_BOND PPS
             , GCO_GOOD GCO
         where PPS.PPS_NOMENCLATURE_ID = pNomenclatureId
           and GCO.GCO_GOOD_ID = PPS.GCO_GOOD_ID
      order by GCO.GOO_MAJOR_REFERENCE asc;

    cursor crComponentDesc(pNomenclatureId in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type)
    is
      select   PPS.PPS_NOM_BOND_ID
          from PPS_NOM_BOND PPS
             , GCO_GOOD GCO
         where PPS.PPS_NOMENCLATURE_ID = pNomenclatureId
           and GCO.GCO_GOOD_ID = PPS.GCO_GOOD_ID
      order by GCO.GOO_MAJOR_REFERENCE desc;

    /*Réception des composants de la nomenclature cible ordonnée par la séquence pour effectuer la renumérotation */
    cursor crSequenceAsc(pNomenclatureId in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type)
    is
      select   PPS_NOM_BOND_ID
          from PPS_NOM_BOND
         where PPS_NOMENCLATURE_ID = pNomenclatureId
      order by abs(COM_SEQ) asc;

    cursor crSequenceDesc(pNomenclatureId in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type)
    is
      select   PPS_NOM_BOND_ID
          from PPS_NOM_BOND
         where PPS_NOMENCLATURE_ID = pNomenclatureId
      order by abs(COM_SEQ) desc;

    tplComponentAsc  crComponentAsc%rowtype;
    tplComponentDesc crComponentAsc%rowtype;
    tplSequenceAsc   crSequenceAsc%rowtype;
    tplSequenceDesc  crSequenceDesc%rowtype;
    vCounter         number;
    vStep            number;
  begin
    vCounter  := 1;   /*Initialisation du compteur                          */
    vStep     := to_number(PCS.PC_CONFIG.GetConfig('PPS_Com_Numbering') );   /*Récupération du pas défini par la config            */

    -- Passer les valeurs des sequences à une valeur négative pour ne pas
    --  avoir de contrainte avec la PK2 unique durant le processus de renumérotation
    update PPS_NOM_BOND
       set COM_SEQ = COM_SEQ * -1
     where PPS_NOMENCLATURE_ID = pNOMENCLATURE_ID;

    if (pORDER_BY = 0) then
      if (pASCENDANT = 0) then
        open crSequenceDesc(pNOMENCLATURE_ID);   /*Ouverture du curseur ordonné par séquence Descendante */

        fetch crSequenceDesc
         into tplSequenceDesc;   /* renumérotation                                       */

        while crSequenceDesc%found loop
          update PPS_NOM_BOND
             set COM_SEQ = vCounter * vStep
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where PPS_NOM_BOND_ID = tplSequenceDesc.PPS_NOM_BOND_ID;

          vCounter  := vCounter + 1;

          fetch crSequenceDesc
           into tplSequenceDesc;
        end loop;

        close crSequenceDesc;
      elsif(pASCENDANT = 1) then
        open crSequenceAsc(pNOMENCLATURE_ID);   /*Ouverture du curseur ordonné par séquence ascendante  */

        fetch crSequenceAsc
         into tplSequenceAsc;   /*renumérotation                                        */

        while crSequenceAsc%found loop
          update PPS_NOM_BOND
             set COM_SEQ = vCounter * vStep
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where PPS_NOM_BOND_ID = tplSequenceAsc.PPS_NOM_BOND_ID;

          vCounter  := vCounter + 1;

          fetch crSequenceAsc
           into tplSequenceAsc;
        end loop;

        close crSequenceAsc;
      end if;
    elsif(pORDER_BY = 1) then   /*Composants triés par composants                       */
      if (pASCENDANT = 0) then
        open crComponentDesc(pNOMENCLATURE_ID);   /*Ouverture du curseur ordonné par composant décroissant */

        fetch crComponentDesc
         into tplComponentDesc;   /*Renumérotation                                        */

        while crComponentDesc%found loop
          update PPS_NOM_BOND
             set COM_SEQ = vCounter * vStep
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where PPS_NOM_BOND_ID = tplComponentDesc.PPS_NOM_BOND_ID;

          vCounter  := vCounter + 1;

          fetch crComponentDesc
           into tplComponentDesc;
        end loop;

        close crComponentDesc;
      elsif(pASCENDANT = 1) then
        open crComponentAsc(pNOMENCLATURE_ID);   /*Ouverture du curseur ordonné par composant croissant  */

        fetch crComponentAsc
         into tplComponentAsc;   /*Renumérotation                                        */

        while crComponentAsc%found loop
          update PPS_NOM_BOND
             set COM_SEQ = vCounter * vStep
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where PPS_NOM_BOND_ID = tplComponentAsc.PPS_NOM_BOND_ID;

          vCounter  := vCounter + 1;

          fetch crComponentAsc
           into tplComponentAsc;
        end loop;

        close crComponentAsc;
      end if;
    end if;
  end;

/**************************************************************************************************/
  procedure CREATE_NEW_AS_NOMENCLATURE(
    pORIGIN_NOM_ID  in     PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , pTAS_RECORD_ID  in     PPS_NOMENCLATURE.DOC_RECORD_ID%type
  , pPRJ_RECORD_ID  in     PPS_NOMENCLATURE.DOC_RECORD_ID%type
  , pBUD_RECORD_ID  in     PPS_NOMENCLATURE.DOC_RECORD_ID%type
  , pGCO_INST_ID    in     PPS_NOMENCLATURE.GCO_GOOD_ID%type
  , pPPS_INST_ID    in     PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , pGOOD_ID        in     PPS_NOMENCLATURE.GCO_GOOD_ID%type
  , pSEQUENCE       in     PPS_NOM_BOND.COM_SEQ%type
  , pQTY_DIR        in     PPS_NOM_BOND.COM_UTIL_COEFF%type
  , pNEWNOMHeaderID in out PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , pNEWNOMID       in out PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  )
  is
    v_cpt            number;
    v_cpt_as         number;
    v_cpt_nom        number;
    v_loop           number;
    v_line           number;
    v_new_nom        number;
    v_create_art_dir number;
    v_is_art_dir     char(1);
    v_list_DocId     varchar2(32000);
    out_new_pps_id   pps_nom_bond.pps_nomenclature_id%type;
    vNomId           pps_nom_bond.pps_nomenclature_id%type;
    v_good_id        gco_good.gco_good_id%type;
    v_exist_nom_id   pps_nomenclature.pps_nomenclature_id%type;
    v_pps_id_art_dir pps_nomenclature.pps_nomenclature_id%type;
    v_doc_id         doc_record.doc_record_id%type;
    v_upd_doc_rec_id doc_record.doc_record_id%type;
    csant_to_add     char(1);

    type upd_bond is record(
      old_pps_id  pps_nom_bond.pps_nomenclature_id%type
    , new_pps_id  pps_nom_bond.pps_nomenclature_id%type
    , pps_id_pere gco_good.gco_good_id%type
    , goo_id_pere gco_good.gco_good_id%type
    , path        varchar2(4000)
    , path_pere   varchar2(4000)
    , is_art_dir  char(1)
    );

    type type_upd_bond is table of upd_bond
      index by binary_integer;

    tableau_pps      type_upd_bond;
  begin
    pNEWNOMID         := null;
    vNomId            := null;
    v_doc_id          := null;
    v_list_DocId      := null;
    v_new_nom         := 0;
    v_cpt             := 0;
    v_create_art_dir  := 1;
    tableau_pps.delete;

    if pTAS_RECORD_ID is null then
      if pPRJ_RECORD_ID is not null then
        v_doc_id  := pPRJ_RECORD_ID;
      elsif pBUD_RECORD_ID is not null then
        v_doc_id  := pBUD_RECORD_ID;
      else
        begin
          select doc_record_id
            into v_doc_id
            from pps_nomenclature
           where pps_nomenclature_id = pORIGIN_NOM_ID;
        exception
          when no_data_found then
            v_doc_id  := null;
        end;
      end if;
    else
      v_doc_id  := pTAS_RECORD_ID;
    end if;

    if v_doc_id is not null then
      -- Lecture des différentes têtes sous la nomenclature principale
      -- + création nomenclatures
      -- + stockage des infos en tableau pour refaire tous les liens
      for c_nom_bond in (select   pORIGIN_NOM_ID || '/' || lpad('0', 10, '0') || '-' || to_char(good.gco_good_id) path
                                , substr(pORIGIN_NOM_ID || '/' || lpad('0', 10, '0') || '-' || to_char(good.gco_good_id)
                                       , 1
                                       , instr(pORIGIN_NOM_ID || '/' || lpad('0', 10, '0') || '-' || to_char(good.gco_good_id), '/', -1, 1) - 1
                                        ) path_pere
                                , good.gco_good_id gco_good_id
                                , goo_major_reference
                                , good.gco_good_id gco_good_id_pere
                                , goo_major_reference goo_major_reference_pere
                                , pps.pps_nomenclature_id pps_nomenclature_id1
                                , null pps_nomenclature_id2
                                , nom_version
                                , nvl(nom_version, ' ') test_nom_version
                             from gco_good good
                                , pps_nomenclature pps
                            where good.gco_good_id = pps.gco_good_id
                              and pps.pps_nomenclature_id = pORIGIN_NOM_ID
                         union all
                         select   path
                                , substr(path, 1, instr(path, '/', -1, 1) - 1) path_pere
                                , good.gco_good_id gco_good_id
                                , good.goo_major_reference
                                , good2.gco_good_id gco_good_id_pere
                                , good2.goo_major_reference goo_major_reference_pere
                                , pps_nomenclature_id1
                                , pps_nomenclature_id2
                                , pps.nom_version
                                , nvl(pps.nom_version, ' ') test_nom_version
                             from (select     pORIGIN_NOM_ID || sys_connect_by_path(lpad(pps_nom_bond.com_seq, 10, '0') || '-' || pps_nom_bond.gco_good_id, '/')
                                                                                                                                                           path
                                            , pps_pps_nomenclature_id pps_nomenclature_id1
                                            , pps_nomenclature_id pps_nomenclature_id2
                                            , com_seq
                                         from pps_nom_bond
                                   start with pps_nomenclature_id = pORIGIN_NOM_ID
                                   connect by /*nocycle*/ prior pps_pps_nomenclature_id = pps_nomenclature_id
                                     order siblings by pps_nomenclature_id
                                             , com_seq)
                                , gco_good good
                                , gco_good good2
                                , pps_nomenclature pps
                                , pps_nomenclature pps2
                            where good.gco_good_id = pps.gco_good_id
                              and pps.pps_nomenclature_id = pps_nomenclature_id1
                              and good2.gco_good_id = pps2.gco_good_id
                              and pps2.pps_nomenclature_id = pps_nomenclature_id2
                         order by path) loop
        begin
          select pps_nomenclature_id
            into v_exist_nom_id
            from pps_nomenclature
           where gco_good_id = c_nom_bond.gco_good_id
             and nvl(nom_version, ' ') = nvl(c_nom_bond.test_nom_version, ' ')
             and c_type_nom = '8'
             and doc_record_id = v_doc_id;

          if     c_nom_bond.pps_nomenclature_id1 = pORIGIN_NOM_ID
             and pPPS_INST_ID <> pORIGIN_NOM_ID then
            v_pps_id_art_dir  := v_exist_nom_id;
          end if;

          if pPPS_INST_ID = pORIGIN_NOM_ID then
            pNEWNOMHeaderID  := v_exist_nom_id;
            vNomId           := v_exist_nom_id;
          end if;

          v_cpt                           := v_cpt + 1;
          tableau_pps(v_cpt).old_pps_id   := c_nom_bond.pps_nomenclature_id1;
          tableau_pps(v_cpt).new_pps_id   := v_exist_nom_id;
          tableau_pps(v_cpt).pps_id_pere  := c_nom_bond.pps_nomenclature_id2;
          tableau_pps(v_cpt).goo_id_pere  := c_nom_bond.gco_good_id_pere;
          tableau_pps(v_cpt).path         := c_nom_bond.path;
          tableau_pps(v_cpt).path_pere    := c_nom_bond.path_pere;
          tableau_pps(v_cpt).is_art_dir   := 'N';
        exception
          when no_data_found then
            --" Deux Cas si on ne trouve pas de nomenclatures sav existante :
            --> 1 : Controle des articles directeurs des tâches (si on trouve, on met à jour le doc_record_id de pps_nomenclature pour faire le lien avec le dossier tâche)
            --> 2 : Si pas d'article directeur, création simple de nomenclature SAV
            v_cpt_as  := 0;

            if     pTAS_RECORD_ID is null
               and (   pPRJ_RECORD_ID is not null
                    or pBUD_RECORD_ID is not null) then
              v_cpt_nom  := 0;

              for c_pps_as in (select pps_nomenclature_id
                                    , doc_record_id
                                 from pps_nomenclature
                                where gco_good_id = c_nom_bond.gco_good_id
                                  and nvl(nom_version, ' ') = nvl(c_nom_bond.test_nom_version, ' ')
                                  and c_type_nom = '8'
                                  and doc_record_id in(
                                        select doc_record_id
                                          from gal_task
                                         where gal_project_id = (select gal_project_id
                                                                   from gal_project
                                                                  where doc_record_id = pPRJ_RECORD_ID
                                                                    and pBUD_RECORD_ID is null)
                                        union all
                                        select doc_record_id
                                          from gal_task
                                         where gal_budget_id = (select gal_budget_id
                                                                  from gal_budget
                                                                 where doc_record_id = pBUD_RECORD_ID
                                                                   and pPRJ_RECORD_ID is null) )
                                  and (   0 = instr(v_list_DocId, doc_record_id)
                                       or v_list_DocId is null) ) loop
                v_cpt_nom  := v_cpt_nom + 1;

                if v_cpt_nom = 1 then
                  begin
                    --Si art Directeur...
                    select '*'
                      into v_is_art_dir
                      from gal_task tas
                         , gal_task_good gtg
                     where tas.doc_record_id = c_pps_as.doc_record_id
                       and gtg.gal_task_id = tas.gal_task_id
                       and gtg.pps_nomenclature_id = c_pps_as.pps_nomenclature_id
                       and rownum = 1;

                    csant_to_add  := 'Y';

                        --Controle si le pere est un article directeur
                    --(test si article est prise en charge par la nomencalture de l'article directeur
                    -- qui possede son propre dossier doc_record_id )
                    for v_line in 1 .. v_cpt loop
                      if     instr(c_nom_bond.path, tableau_pps(v_line).path) <> 0
                         and tableau_pps(v_line).is_art_dir = 'Y' then
                        csant_to_add  := 'N';
                      end if;
                    end loop;

                    v_cpt_as      := v_cpt_as + 1;

                    if csant_to_add = 'Y' then
                      v_cpt                           := v_cpt + 1;
                      v_list_DocId                    := nvl(v_list_DocId, ';') || c_pps_as.doc_record_id || ';';
                      tableau_pps(v_cpt).old_pps_id   := c_nom_bond.pps_nomenclature_id1;
                      tableau_pps(v_cpt).new_pps_id   := c_pps_as.pps_nomenclature_id;
                      tableau_pps(v_cpt).pps_id_pere  := c_nom_bond.pps_nomenclature_id2;
                      tableau_pps(v_cpt).goo_id_pere  := c_nom_bond.gco_good_id_pere;
                      tableau_pps(v_cpt).path         := c_nom_bond.path;
                      tableau_pps(v_cpt).path_pere    := c_nom_bond.path_pere;
                      tableau_pps(v_cpt).is_art_dir   := 'Y';
                    end if;
                  exception
                    when no_data_found then
                      v_cpt_as  := v_cpt_as + 1;
                      null;
                  end;

                  v_new_nom  := 0;
                end if;
              end loop;

              if v_cpt_as = 0 then
                v_new_nom  := 1;
              end if;   --n'existe pas : creation = 1
            else
              v_new_nom  := 1;
            end if;

            if v_new_nom = 1 then
              v_cpt                           := v_cpt + 1;
              PPS_NOMENCLATURE_FCT.CREATE_NEW_NOMENCLATURE(c_nom_bond.pps_nomenclature_id1   --source
                                                         , c_nom_bond.gco_good_id   --good_id
                                                         , '8'   --type
                                                         , c_nom_bond.nom_version   --version
                                                         , 1   --Qté ref cible
                                                         , v_doc_id
                                                         , out_new_pps_id
                                                          );   --cible

              if c_nom_bond.pps_nomenclature_id1 = pORIGIN_NOM_ID
                                                                 --and pPPS_INST_ID <> pORIGIN_NOM_ID
              then
                pNEWNOMID         := out_new_pps_id;
                vNomId            := out_new_pps_id;
                v_pps_id_art_dir  := out_new_pps_id;
              end if;

              tableau_pps(v_cpt).old_pps_id   := c_nom_bond.pps_nomenclature_id1;
              tableau_pps(v_cpt).new_pps_id   := out_new_pps_id;
              tableau_pps(v_cpt).pps_id_pere  := c_nom_bond.pps_nomenclature_id2;
              tableau_pps(v_cpt).goo_id_pere  := c_nom_bond.gco_good_id_pere;
              tableau_pps(v_cpt).path         := c_nom_bond.path;
              tableau_pps(v_cpt).path_pere    := c_nom_bond.path_pere;
              tableau_pps(v_cpt).is_art_dir   := 'N';
            end if;
        end;
      end loop;

      select     count(*) + 1
            into v_loop
            from pps_nom_bond
      start with pps_nomenclature_id = pORIGIN_NOM_ID
      connect by prior pps_pps_nomenclature_id = pps_nomenclature_id;

      for v_line in 1 .. v_cpt loop
         --Checker si dans le cas ou un sous-niveau déjà figé, le lien est bien mis à jour...
        --> Sinon voir à stocker dans le tableau le(s) ligne(s) remontée(s) dans la requete de controle d'existance de la nomenclature...
        if vNomId is not null then
          update pps_nom_bond
             set pps_pps_nomenclature_id = tableau_pps(v_line).new_pps_id
               , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
               , a_datemod = sysdate
           where PPS_NOM_BOND_ID in(
                   select COM.PPS_NOM_BOND_ID
                     from PPS_NOM_BOND COM
                        , PPS_NOMENCLATURE NOM
                        , PPS_NOMENCLATURE NEW_NOM
                    where COM.PPS_NOMENCLATURE_ID = NOM.PPS_NOMENCLATURE_ID
                      and NOM.C_TYPE_NOM = '8'
                      and NOM.DOC_RECORD_ID = v_doc_id
                      and NEW_NOM.PPS_NOMENCLATURE_ID = tableau_pps(v_line).new_pps_id
                      and NEW_NOM.C_TYPE_NOM = '8'
                      and NEW_NOM.DOC_RECORD_ID = v_doc_id
                      and nvl(COM.PPS_PPS_NOMENCLATURE_ID, -1) <> tableau_pps(v_line).new_pps_id
                      and COM.GCO_GOOD_ID = NEW_NOM.GCO_GOOD_ID);
        end if;
      end loop;

      --Si création d'une nomenclature sav niveau affaire :
      --> utilisation de doc_record_id de l'affaire pour creer une entete
      --> utilisation du pNEWNOMID pour creer les liens de nomenclature
        --  (cela correspondra aux articles directeurs des differentes taches d'appro)
      if pPRJ_RECORD_ID is not null then
        PPS_NOMENCLATURE_FCT.CREATE_NEW_AS_HEADER(pPRJ_RECORD_ID, pNEWNOMHeaderID, pGCO_INST_ID, pPPS_INST_ID);
      end if;

      if pBUD_RECORD_ID is not null then
        PPS_NOMENCLATURE_FCT.CREATE_NEW_AS_HEADER(pBUD_RECORD_ID, pNEWNOMHeaderID, pGCO_INST_ID, pPPS_INST_ID);
      end if;

      if     (   pPRJ_RECORD_ID is not null
              or pBUD_RECORD_ID is not null)
         and pTAS_RECORD_ID is not null
         and v_create_art_dir = 1 then
        PPS_NOMENCLATURE_FCT.CREATE_NEW_AS_COMPONENT(pNEWNOMHeaderID, pGOOD_ID, v_pps_id_art_dir, pSEQUENCE, pQTY_DIR);
      end if;

      /*Mise à jour de l'installation avec la nouvelle nomenclature si installation doc_record de type 11 est liée à affaire ou budget*/
      if     pPRJ_RECORD_ID is not null
         and pNEWNOMHeaderID is not null then
        update doc_record
           set pps_nomenclature_id = pNEWNOMHeaderID
         where c_rco_type = '11'
           and doc_record_gal_id = pPRJ_RECORD_ID;
      end if;

      if     pBUD_RECORD_ID is not null
         and pNEWNOMHeaderID is not null then
        update doc_record
           set pps_nomenclature_id = pNEWNOMHeaderID
         where c_rco_type = '11'
           and doc_record_gal_id = pBUD_RECORD_ID;
      end if;
    end if;
  end CREATE_NEW_AS_NOMENCLATURE;

/**************************************************************************************************/
  procedure CREATE_NEW_AS_HEADER(
    pDOC_RECORD_ID  in     PPS_NOMENCLATURE.DOC_RECORD_ID%type
  , pNEWNOMHeaderID in out PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , pGCO_INST_ID    in     PPS_NOMENCLATURE.GCO_GOOD_ID%type
  , pPPS_INST_ID    in     PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  )
  is
    v_exist_pps_id PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
    vNomDef        PPS_NOMENCLATURE.NOM_DEFAULT%type;
  begin
    select pps_nomenclature_id
      into v_exist_pps_id
      from PPS_NOMENCLATURE
     where GCO_GOOD_ID = pGCO_INST_ID
       and DOC_RECORD_ID = pDOC_RECORD_ID
       and C_TYPE_NOM = '8';   -- and rownum = 1;

    pNEWNOMHeaderID  := v_exist_pps_id;
  exception
    when no_data_found then
      begin
        select pps_nomenclature_id
          into v_exist_pps_id
          from PPS_NOMENCLATURE
         where PPS_NOMENCLATURE_ID = pPPS_INST_ID
           and GCO_GOOD_ID = pGCO_INST_ID
           and DOC_RECORD_ID = pDOC_RECORD_ID
           and C_TYPE_NOM = '8';

        pNEWNOMHeaderID  := v_exist_pps_id;
      exception
        when no_data_found then
          select INIT_ID_SEQ.nextval
            into pNEWNOMHeaderID   /* Génération d'un nouvel Id nomenclature Sav */
            from dual;

          select decode(nvl(max(NOM_DEFAULT), 0), 0, 1, 0)
            into vNomDef
            from PPS_NOMENCLATURE
           where C_TYPE_NOM = '8'
             and GCO_GOOD_ID = pGCO_INST_ID;

          /*Création de la nouvelle nomenclature*/
          insert into PPS_NOMENCLATURE
                      (PPS_NOMENCLATURE_ID
                     , GCO_GOOD_ID
                     , C_TYPE_NOM
                     , NOM_TEXT
                     , NOM_REF_QTY
                     , A_DATECRE
                     , A_IDCRE
                     , NOM_VERSION
                     , C_REMPLACEMENT_NOM
                     , NOM_BEG_VALID
                     , NOM_DEFAULT
                     , FAL_SCHEDULE_PLAN_ID
                     , PPS_RANGE_ID
                     , NOM_MARK_NOMENCLATURE
                     , NOM_REMPL_PART
                     , DOC_RECORD_ID
                      )
               values (pNEWNOMHeaderID
                     , pGCO_INST_ID   --pTARGET_GOOD_ID
                     , '8'   --pC_TYPE_NOM
                     , pcs.pc_functions.translateword('Nomenclature d''affaire')   --NOM_TEXT
                     , 1   --pNOM_REF_QTY
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                     , (select NOM_VERSION
                          from PPS_NOMENCLATURE
                         where pps_nomenclature_id = pPPS_INST_ID)   -- Null --pNOM_VERSION
                     , '1'   --C_REMPLACEMENT_NOM
                     , sysdate   --NOM_BEG_VALID
                     , vNomDef   --NOM_DEFAULT
                     , null   --FAL_SCHEDULE_PLAN_ID
                     , null   --PPS_RANGE_ID
                     , 0   --vNOM_MARK_NOMENCLATURE
                     , 0   --NOM_REMPL_PART
                     , pDOC_RECORD_ID
                      );
      end;
  end CREATE_NEW_AS_HEADER;

/**************************************************************************************************/
  procedure CREATE_NEW_AS_COMPONENT(
    pNEWNOMHeaderID in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , pGOOD_ID        in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , pPPS_PPS_ID     in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , pSEQUENCE       in PPS_NOM_BOND.COM_SEQ%type
  , pQTY_DIR        in PPS_NOM_BOND.COM_UTIL_COEFF%type
  )
  is
    pNewNomBondId      PPS_NOMENCLATURE.DOC_RECORD_ID%type;
    v_exist_NomBond_id PPS_NOM_BOND.PPS_NOM_BOND_ID%type;
    v_max_seq          PPS_NOM_BOND.COM_SEQ%type;
  --Création des composant articles directeurs --> base nomen SAV généré juste avant (pPPS_PPS_ID)
  begin
    select max(PPS_NOM_BOND_ID)
      into v_exist_NomBond_id
      from PPS_NOM_BOND
     where pps_nomenclature_id = pNEWNOMHeaderID
       and (    (    pps_pps_nomenclature_id = pPPS_PPS_ID
                 and pPPS_PPS_ID is not null)
            or pPPS_PPS_ID is null)
       and gco_good_id = pGOOD_ID;

    if v_exist_NomBond_id is null then
      select nvl(max(COM_SEQ), 0)
        into v_max_seq
        from PPS_NOM_BOND
       where pps_nomenclature_id = pNEWNOMHeaderID;

      select INIT_ID_SEQ.nextval
        into pNewNomBondId   /* Génération d'un nouvel Id nomenclature Sav */
        from dual;

      /*Ajout de tous les composants sources*/
      insert into PPS_NOM_BOND
                  (PPS_NOM_BOND_ID   /*ID lien nomenclature                                */
                 , PPS_NOMENCLATURE_ID   /*ID Nomenclature                                     */
                 , PPS_RANGE_OPERATION_ID   /*ID opération de gamme                               */
                 , STM_LOCATION_ID   /*ID emplacement de stock                             */
                 , GCO_GOOD_ID   /*ID bien                                             */
                 , C_REMPLACEMENT_NOM   /*Condition de remplacement                           */
                 , C_TYPE_COM   /*Type de lien nomenclature                           */
                 , C_DISCHARGE_COM   /*Décharge                                            */
                 , C_KIND_COM   /*Genre de lien nomenclature                          */
                 , COM_SEQ   /*Séquence lien                                       */
                 , COM_TEXT   /*Texte                                               */
                 , COM_RES_TEXT   /*Réserve texte                                       */
                 , COM_RES_NUM   /*Réserve numérique                                   */
                 , COM_VAL   /*Valorisation                                        */
                 , COM_SUBSTITUT   /*Substitution                                        */
                 , COM_POS   /*Position                                            */
                 , COM_UTIL_COEFF   /*Utilisation                                        */
                 , COM_PDIR_COEFF   /*Coefficient Plan directeur                          */
                 , COM_REC_PCENT   /*Pourcentage recette                                 */
                 , COM_INTERVAL   /*Décalage                                            */
                 , COM_BEG_VALID   /*Début validité                                      */
                 , COM_END_VALID   /*Fin validité                                        */
                 , COM_REMPLACEMENT   /*Remplacement                                        */
                 , A_DATECRE   /*Date de création                                    */
                 , A_IDCRE   /*ID de création                                      */
                 , STM_STOCK_ID   /*ID stock logique                                    */
                 , FAL_SCHEDULE_STEP_ID   /*Lien tâche                                          */
                 , PPS_PPS_NOMENCLATURE_ID   /*PPS_Nomenclature                                    */
                 , COM_REF_QTY   /*Qté référence                                       */
                 , COM_PERCENT_WASTE   /*Pourcentage de déchet                               */
                 , COM_FIXED_QUANTITY_WASTE   /*Quantité fixe de déchet                             */
                 , COM_INCREASE_COST
                 , COM_QTY_REFERENCE_LOSS
                  )   /*Quantité de référence perte                         */
           values (pNewNomBondId
                 , pNEWNOMHeaderID
                 , null
                 , null
                 , pGOOD_ID
                 , '2'
                 , '1'
                 , '1'
                 , '1'
                 , v_max_seq + pSEQUENCE
                 , pcs.pc_functions.translateword('Article directeur')
                 , null
                 , null
                 , 1
                 , 0
                 , null
                 , pQTY_DIR
                 , null
                 , null
                 , null
                 , null
                 , null
                 , 0
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , null
                 , null
                 , pPPS_PPS_ID
                 , null
                 , null
                 , null
                 , 1
                 , null
                  );
    end if;
  end CREATE_NEW_AS_COMPONENT;

/**************************************************************************************************/
  procedure p_InitParameters
  is
  begin
    --Récupération des paramètres de lancement de l'objet
    vAuthorizedTypes  := PCS.PC_I_LIB_SESSION.GetObjectParam('PPS_AUTHORIZED_TYPE');

    --Si vAuthorizedTypes est null, c'est qu'aucun paramètre n'a été
    --spécifié pour l'objet. Par conséquent, les types de nomenclature
    --existant sont autorisés.
    if vAuthorizedTypes is null then
      vAuthorizedTypes  := getExistingTypes;   --Récupère les types existants
    else
      vAuthorizedTypes  := vAuthorizedTypes || ',';
    end if;
  end p_InitParameters;

/**************************************************************************************************/
  function getExistingTypes
    return varchar2
  is
    cursor csTypes(langid in pcs.pc_lang.pc_lang_id%type)
    is
      select GCDCODE || ',' as GCDCODE
        from V_COM_CPY_PCS_CODES
       where GCGNAME = 'C_TYPE_NOM'
         and PC_LANG_ID = langid;

    result varchar2(4000);
  begin
    for item in csTypes(PCS.PC_I_LIB_SESSION.GETUSERLANGID) loop
      result  := result || item.GCDCODE;
    end loop;

    return result;
  end getExistingTypes;

/**************************************************************************************************/
  function is_Type_Authorized(aCode in varchar2)
    return varchar2
  is
  begin
    --Initialisation des paramètres qu'une seule fois (lors du premier appel)
    --vAuthorizedTypes va contenir les types de nomenclature autorisés
    --Serra initialisé à chaque nouveau lancement de l'objet
    if vAuthorizedTypes is null then
      p_InitParameters;   -- Initialisation des types de nomenclature autorisés
    end if;

    --Si le code passé en paramètre se trouve parmis les types autorisés
    --Renvoyé vrai sinon faux
    if instr(vAuthorizedTypes, aCode || ',') > 0 then
      return 1;
    else
      return 0;
    end if;
  end is_Type_Authorized;

  /**
  * Description
  *   retourne l'id de la nomenclature par défaut pour le bien et le type de nomenclature demandés
  */
  function GetDefaultNomenclature(iGoodId in PPS_NOMENCLATURE.GCO_GOOD_ID%type, iTypNom in PPS_NOMENCLATURE.C_TYPE_NOM%type)
    return PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  is
  begin
    return PPS_LIB_FUNCTIONS.GetDefaultNomenclature(iGoodId => iGoodId, iTypNom => iTypNom);
  end GetDefaultNomenclature;
end PPS_NOMENCLATURE_FCT;
