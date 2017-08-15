--------------------------------------------------------
--  DDL for Package Body FAL_LIB_COMPONENT_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_COMPONENT_LINK" 
is
  /**
  * function CheckBatchTraceability
  * Description
  *
  * @created CLG 07.2015
  * @lastUpdate
  * @param iBatchId    : Id de l'OF dont les composants seront testés
  * @return : un message concernant les composants qui posent problème
  **/
  function CheckBatchTraceability(iBatchId in FAL_LOT.FAL_LOT_ID%type)
    return varchar2
  is
    cursor crBatchCpt
    is
      select   CPT.FAL_LOT_MATERIAL_LINK_ID
             , CPT.GCO_GOOD_ID
             , CPT.LOM_SEQ
             , GOOD.GOO_MAJOR_REFERENCE
             , PROD.PDT_FULL_TRACABILITY_COEF
          from FAL_LOT_MATERIAL_LINK CPT
             , GCO_PRODUCT PROD
             , GCO_GOOD GOOD
         where PROD.GCO_GOOD_ID = CPT.GCO_GOOD_ID
           and GOOD.GCO_GOOD_ID = CPT.GCO_GOOD_ID
           and CPT.FAL_LOT_ID = iBatchId
           and CPT.C_TYPE_COM = '1'
           and CPT.C_KIND_COM = '1'
           and CPT.LOM_STOCK_MANAGEMENT = 1
           and (FAL_TOOLS.PrcIsFullTracability(CPT.GCO_GOOD_ID) = 1)
      order by CPT.LOM_SEQ;

    cursor crCharactLotUsed(iMatLinkId FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type, iGoodId FAL_LOT_MATERIAL_LINK.GCO_GOOD_ID%type)
    is
      /* Recherche des caract de type lot en entrée atelier qui ont encore une quantité solde */
      select distinct IN_LOT LOT_CHARACT
                 from FAL_FACTORY_IN
                where FAL_LOT_MATERIAL_LINK_ID = iMatLinkId
                  and IN_BALANCE > 0
      union
      /* Recherche des caractérisations de type lot qui ont été consommées lors d'une sortie composant (type réception ou réception rebut).
         Il ne faut pas compter les lots qui aurait été retournés ou éclatés, par exemple. Il est impossible de savoir exactement de quel composant il s'agit
         (impossible de remonter sur FAL_LOT_MATERIAL_LINK depuis FAL_FACTORY_OUT), c'est pourquoi on s'assure d'avoir la même caract lot sur une entrée
         atelier d'un même bien, du même OF). On évite pas les problèmes d'avoir plusieurs fois le même bien en composant, avec des caractérisations similaires. */
      select distinct OUT_LOT LOT_CHARACT
                 from FAL_FACTORY_OUT FFO
                where FAL_LOT_ID = iBatchId
                  and GCO_GOOD_ID = iGoodId
                  and exists(select *
                               from FAL_FACTORY_IN
                              where FAL_LOT_MATERIAL_LINK_ID = iMatLinkId
                                and IN_LOT = FFO.OUT_LOT)
                  and C_OUT_TYPE = '1'
                  and C_OUT_TYPE in('1', '2', '7')
      union
      /* Recherche des caractérisations de type lot qu'on est en train de sortir */
      select distinct FCL_BATCH_NUM LOT_CHARACT
                 from FAL_COMPONENT_LINK FCL
                    , FAL_LOT_MAT_LINK_TMP CPT
                where CPT.FAL_LOT_MAT_LINK_TMP_ID = FCL.FAL_LOT_MAT_LINK_TMP_ID
                  and CPT.FAL_LOT_MATERIAL_LINK_ID = iMatLinkId;

    type TtplCharactLotUsed is table of crCharactLotUsed%rowtype;

    tplCharactLotUsed TtplCharactLotUsed;
    lvMsg             varchar2(4000)     := '';
  begin
    /* Pour chaque composant d'OF géré en traçabilité totale, on vérifie de respecter le coef de traçabilité */
    for tplBatchCpt in crBatchCpt loop
      open crCharactLotUsed(tplBatchCpt.FAL_LOT_MATERIAL_LINK_ID, tplBatchCpt.GCO_GOOD_ID);

      fetch crCharactLotUsed
      bulk collect into tplCharactLotUsed;

      close crCharactLotUsed;

      if tplCharactLotUsed.count > tplBatchCpt.PDT_FULL_TRACABILITY_COEF then
        /* dépassement du coefficient de traçabilité */
        lvMsg  := lvMsg || '   ' || tplBatchCpt.LOM_SEQ || ' - ' || tplBatchCpt.GOO_MAJOR_REFERENCE;
        lvMsg  := lvMsg || ' (' || PCS.PC_FUNCTIONS.TranslateWord('Coeff.') || ' = ' || tplBatchCpt.PDT_FULL_TRACABILITY_COEF || ')' || chr(13) || '        (';

        for lIndex in tplCharactLotUsed.first .. tplCharactLotUsed.last loop
          if lIndex <> tplCharactLotUsed.last then
            lvMsg  := lvMsg || tplCharactLotUsed(lIndex).LOT_CHARACT || ', ';
          else
            lvMsg  := lvMsg || tplCharactLotUsed(lIndex).LOT_CHARACT || ')' || chr(13);
          end if;
        end loop;

        lvMsg  := lvMsg || chr(13);
      end if;
    end loop;

    return lvMsg;
  end CheckBatchTraceability;

  /**
  * function CheckTraceability
  * Description
  *
  * @created CLG 07.2015
  * @lastUpdate
  * @public
  * @param iSessionId    : Id de session de mouvements de composants
  * @return : un message concernant les composants qui posent problème
  **/
  function CheckTraceability(iSessionId in FAL_COMPONENT_LINK.FCL_SESSION%type)
    return varchar2
  is
    cursor crBatch
    is
      select distinct FCL.FAL_LOT_ID
                    , LOT.LOT_REFCOMPL
                 from FAL_COMPONENT_LINK FCL
                    , FAL_LOT LOT
                where FCL.FAL_LOT_ID = LOT.FAL_LOT_ID
                  and FCL_SESSION = iSessionId;

    lvMsg       varchar2(4000);
    lvMsgResult varchar2(4000) := '';
  begin
    for tplBatch in crBatch loop
      lvMsg  := CheckBatchTraceability(tplBatch.FAL_LOT_ID);

      if lvMsg is not null then
        if lvMsgResult is null then
          lvMsgResult  := PCS.PC_FUNCTIONS.TranslateWord('Dépassement du coefficient de traçabilité') || chr(13) || chr(13);
        end if;

        lvMsgResult  := lvMsgResult || tplBatch.LOT_REFCOMPL || chr(13) || lvMsg;
      end if;
    end loop;

    return lvMsgResult;
  end CheckTraceability;
end FAL_LIB_COMPONENT_LINK;
