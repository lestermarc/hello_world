--------------------------------------------------------
--  DDL for Package Body FAL_WEIGH_FUNCTION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_WEIGH_FUNCTION" 
is
  cMvtWeighingMode integer := PCS.PC_CONFIG.GetConfig('FAL_MVT_WEIGHING_MODE');

  /**
   * function IsMultiAlloyPDT
   * Description : Renvoie le Nbre d'alliage constitutifs d'un bien avec MP.
   *
   * @created ECA
   * @lastUpdate
   * @public
   * @param   iGoodId : Bien
   */
  function IsMultiAlloyPDT(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return integer
  is
    liAlloyNum integer;
  begin
    select count(GPM.GCO_PRECIOUS_MAT_ID) ALLOY_NUM
      into liAlloyNum
      from GCO_PRECIOUS_MAT GPM
     where GCO_GOOD_ID = iGoodId;

    return liAlloyNum;
  exception
    when others then
      return 0;
  end IsMultiAlloyPDT;

  /**
  * proc�dure FILE_FAL_WEIGH_HIST
  * Description : Procedure d'Archivage des pes�es.
  *               On Archive les pes�e dont la date est inf�rieure � PrmDATE_MAX_ARCHIVAGE
  * @created ECA
  * @lastUpdate
  * @public
  * @param   PrmDATE_MAX_ARCHIVAGE : Date d'archivage maxi
  */
  procedure FILE_FAL_WEIGH_HIST(PrmDATE_MAX_ARCHIVAGE date)
  is
    --  Curseurs
    cursor CUR_FAL_WEIGH
    is
      select FAL_WEIGH_ID
        from FAL_WEIGH
       where FWE_DATE <= PrmDATE_MAX_ARCHIVAGE;

    -- Variables
    CurFalWeigh CUR_FAL_WEIGH%rowtype;
  begin
    -- Pour chaque pes�e de date <= Date archivage max .
    for CurFalWeigh in CUR_FAL_WEIGH loop
      -- Archivage pes�e
      FILE_FAL_WEIGH(CurFalWeigh.FAL_WEIGH_ID);
      -- Suppression pes�e
      DELETE_FAL_WEIGH(CurFalWeigh.FAL_WEIGH_ID);
    end loop;
  end FILE_FAL_WEIGH_HIST;

  /**
  * proc�dure FILE_FAL_WEIGH
  * Description : Procedure d'Archivage d'une pes�e.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   PrmFAL_WEIGH_ID : pes�e � archiver
  */
  procedure FILE_FAL_WEIGH(PrmFAL_WEIGH_ID FAL_WEIGH.FAL_WEIGH_ID%type)
  is
  --
  begin
    insert into FAL_WEIGH_HIST
                (FAL_WEIGH_HIST_ID
               , GCO_ALLOY_ID
               , GCO_GOOD_ID
               , STM_ELEMENT_NUMBER_ID
               , STM_ELEMENT_NUMBER2_ID
               , STM_ELEMENT_NUMBER3_ID
               , DOC_RECORD_ID
               , DOC_DOCUMENT_ID
               , DOC_POSITION_ID
               , FAL_SCHEDULE_STEP_ID
               , FAL_LOT_ID
               , FAL_LOT_DETAIL_ID
               , DIC_OPERATOR_ID
               , FAL_POSITION1_ID
               , FAL_POSITION2_ID
               , FWE_IN
               , FWE_WASTE
               , FWE_TURNINGS
               , FWE_INIT
               , FWE_DATE
               , FWE_WEIGHT
               , FWE_WEIGHT_MAT
               , FWE_STONE_NUM
               , FWE_COMMENT
               , A_DATECRE
               , A_IDCRE
               , FWE_REF_PROD
               , FWE_REF_LOT
               , FWE_PIECE
               , FWE_REF_OP
               , FWE_REF_POS
               , FWE_REF_DOC
               , GAL_ALLOY_REF
               , FWE_POSITION1_DESCR
               , FWE_POSITION2_DESCR
               , GOO_MAJOR_REFERENCE
               , GOO_SECONDARY_REFERENCE
               , FWE_WEEKDATE
               , FWE_ENTRY_WEIGHT
               , LOT_REFCOMPL
               , DMT_NUMBER
               , FWE_PIECE_QTY
               , C_WEIGH_TYPE
               , FAL_LOT_PROGRESS_ID
               , FAL_LOT_HIST_ID
               , FAL_FAL_SCHEDULE_STEP_ID
               , FAL_LOT_PROGRESS_HIST_ID
               , SCS_STEP_NUMBER_HIST
               , LOT_REFCOMPL_HIST
               , FAL_LOT_MATERIAL_LINK_ID
               , FAL_FAL_LOT_MAT_LINK_HIST_ID
                )
      select   --GetNewId,
             FWE.FAL_WEIGH_ID
           , FWE.GCO_ALLOY_ID
           , FWE.GCO_GOOD_ID
           , FWE.STM_ELEMENT_NUMBER_ID
           , FWE.STM_ELEMENT_NUMBER2_ID
           , FWE.STM_ELEMENT_NUMBER3_ID
           , FWE.DOC_RECORD_ID
           , FWE.DOC_DOCUMENT_ID
           , FWE.DOC_POSITION_ID
           , FWE.FAL_SCHEDULE_STEP_ID
           , FWE.FAL_LOT_ID
           , FWE.FAL_LOT_DETAIL_ID
           , FWE.DIC_OPERATOR_ID
           , FWE.FAL_POSITION1_ID
           , FWE.FAL_POSITION2_ID
           , FWE.FWE_IN
           , FWE.FWE_WASTE
           , FWE.FWE_TURNINGS
           , FWE.FWE_INIT
           , FWE.FWE_DATE
           , FWE.FWE_WEIGHT
           , FWE.FWE_WEIGHT_MAT
           , FWE.FWE_STONE_NUM
           , FWE.FWE_COMMENT
           , sysdate
           , PCS.PC_I_LIB_SESSION.GETUSERINI
           , GCO.GOO_MAJOR_REFERENCE
           , LOT.LOT_REFCOMPL
           , LOTDET.FAD_PIECE
           , TAL.SCS_STEP_NUMBER
           , POS.POS_NUMBER
           , DOC.DMT_NUMBER
           , FWE.GAL_ALLOY_REF
           , FWE.FWE_POSITION1_DESCR
           , FWE.FWE_POSITION2_DESCR
           , FWE.GOO_MAJOR_REFERENCE
           , FWE.GOO_SECONDARY_REFERENCE
           , FWE.FWE_WEEKDATE
           , FWE.FWE_ENTRY_WEIGHT
           , FWE.LOT_REFCOMPL
           , FWE.DMT_NUMBER
           , FWE.FWE_PIECE_QTY
           , FWE.C_WEIGH_TYPE
           , FWE.FAL_LOT_PROGRESS_ID
           , FWE.FAL_LOT_HIST_ID
           , FWE.FAL_FAL_SCHEDULE_STEP_ID
           , FWE.FAL_LOT_PROGRESS_HIST_ID
           , TAL_HIST.SCS_STEP_NUMBER
           , LOT_HIST.LOT_REFCOMPL
           , FWE.FAL_LOT_MATERIAL_LINK_ID
           , FWE.FAL_FAL_LOT_MAT_LINK_HIST_ID
        from FAL_WEIGH FWE
           , GCO_GOOD GCO
           , FAL_LOT LOT
           , FAL_LOT_HIST LOT_HIST
           , FAL_LOT_DETAIL LOTDET
           , FAL_TASK_LINK TAL
           , FAL_TASK_LINK_HIST TAL_HIST
           , DOC_DOCUMENT DOC
           , DOC_POSITION POS
       where FWE.FAL_WEIGH_ID = PrmFAL_WEIGH_ID
         and FWE.GCO_GOOD_ID = GCO.GCO_GOOD_ID(+)
         and FWE.FAL_LOT_ID = LOT.FAL_LOT_ID(+)
         and FWE.FAL_LOT_HIST_ID = LOT_HIST.FAL_LOT_HIST_ID(+)
         and FWE.FAL_LOT_DETAIL_ID = LOTDET.FAL_LOT_DETAIL_ID(+)
         and FWE.FAL_SCHEDULE_STEP_ID = TAL.FAL_SCHEDULE_STEP_ID(+)
         and FWE.FAL_FAL_SCHEDULE_STEP_ID = TAL_HIST.FAL_SCHEDULE_STEP_ID(+)
         and FWE.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID(+)
         and FWE.DOC_POSITION_ID = POS.DOC_POSITION_ID(+);
  end FILE_FAL_WEIGH;

  /**
  * proc�dure DELETE_FAL_WEIGH
  * Description : Procedure de suppression d'une pes�e archiv�e
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   PrmFAL_WEIGH_ID : pes�e � supprimer
  */
  procedure DELETE_FAL_WEIGH(PrmFAL_WEIGH_ID FAL_WEIGH.FAL_WEIGH_ID%type)
  is
  begin
    delete from FAL_WEIGH
          where FAL_WEIGH_ID = PrmFAL_WEIGH_ID;
  end DELETE_FAL_WEIGH;

/*
 Procedure d'update ou de cr�ation d'une pes�e
     PrmFAL_WEIGH_ID pes�e de base � updater
     PrmFAL_POSITION1_ID poste entrant <> 0 si pes�e d'entr�e
     PrmFAL_POSITION2_ID poste sortant <> 0 si pes�e de sortie
     PrmDoublepesee indique s'il s'agit d'un double pes�e c-a-d poste entrant et sortants non nuls
     PrmFAL_WEIGH_CREATE = 0 Update de la pes�e pass�e en param�tre
                          = 1 Cr�ation d'une nouvelle pes�e � partir de celle pass�e en param�tre
*/
  function FAL_WEIGH_CREATE_OR_UPDATE(
    PrmFAL_WEIGH_ID      FAL_WEIGH.FAL_WEIGH_ID%type
  , PrmFAL_POSITION1_ID  FAL_POSITION.FAL_POSITION_ID%type
  , PrmFAL_POSITION2_ID  FAL_POSITION.FAL_POSITION_ID%type
  , PrmDoublePesee       number
  , PrmFAL_WEIGH_CREATE  number
  , PrmWeighingWithStone integer default 0
  , iGenericRepartition  integer default 0
  )
    return FAL_WEIGH.FAL_WEIGH_ID%type
  is
    -- Curseurs sur la pes�e � "doubler" ou non
    cursor CUR_FAL_WEIGH
    is
      select FWE.FAL_WEIGH_ID
           , FWE.GCO_ALLOY_ID
           , FWE.GCO_GOOD_ID
           , FWE.STM_ELEMENT_NUMBER_ID
           , FWE.STM_ELEMENT_NUMBER2_ID
           , FWE.STM_ELEMENT_NUMBER3_ID
           , FWE.DOC_RECORD_ID
           , FWE.DOC_DOCUMENT_ID
           , FWE.DOC_POSITION_ID
           , FWE.FAL_SCHEDULE_STEP_ID
           , FWE.FAL_LOT_ID
           , FWE.FAL_LOT_DETAIL_ID
           , FWE.DIC_OPERATOR_ID
           , FWE.FAL_POSITION1_ID
           , FWE.FAL_POSITION2_ID
           , FWE.FWE_IN
           , FWE.FWE_WASTE
           , FWE.FWE_TURNINGS
           , FWE.FWE_INIT
           , FWE.FWE_DATE
           , FWE.FWE_WEIGHT
           , FWE.FWE_WEIGHT_MAT
           , FWE.FWE_STONE_NUM
           , FWE.FWE_COMMENT
           , FWE.A_DATECRE
           , FWE.A_IDCRE
           , FWE.FWE_WEEKDATE
           , FWE.FWE_ENTRY_WEIGHT
           , FWE.FWE_PIECE_QTY
           , FWE.C_WEIGH_TYPE
           , FWE.FAL_LOT_PROGRESS_ID
           , FWE.FAL_LOT_PROGRESS_FOG_ID
           , FWE.FWE_SESSION
           , FWE.FAL_LOT_MATERIAL_LINK_ID
           , nvl(FWE.FWE_PAN_WEIGHT, 0) FWE_PAN_WEIGHT
           , FWE.FAL_SCALE_PAN_ID
           , nvl(FSP.FSP_PAN_WEIGHT, 0) FSP_PAN_WEIGHT
           , GAL.GAL_ALLOY_REF
           , FPO1.FPO_DESCRIPTION FPO_DESCRIPTION1
           , FPO2.FPO_DESCRIPTION FPO_DESCRIPTION2
           , GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_SECONDARY_REFERENCE
           , LOT.LOT_REFCOMPL
           , DOC.DMT_NUMBER
        from FAL_WEIGH FWE
           , GCO_ALLOY GAL
           , FAL_POSITION FPO1
           , FAL_POSITION FPO2
           , GCO_GOOD GOO
           , FAL_LOT LOT
           , DOC_DOCUMENT DOC
           , FAL_SCALE_PAN FSP
       where FWE.FAL_WEIGH_ID = PrmFAL_WEIGH_ID
         and FWE.GCO_ALLOY_ID = GAL.GCO_ALLOY_ID(+)
         and FWE.FAL_POSITION1_ID = FPO1.FAL_POSITION_ID(+)
         and FWE.FAL_POSITION2_ID = FPO2.FAL_POSITION_ID(+)
         and FWE.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
         and FWE.FAL_LOT_ID = LOT.FAL_LOT_ID(+)
         and FWE.FAL_SCALE_PAN_ID = FSP.FAL_SCALE_PAN_ID(+)
         and FWE.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID(+);

    -- Variables
    CurFalWeigh            CUR_FAL_WEIGH%rowtype;
    VarFWE_IN              FAL_WEIGH.FWE_IN%type;
    VarFWE_WEIGHT_MAT      FAL_WEIGH.FWE_WEIGHT_MAT%type;
    VarFWE_WEEKDATE        FAL_WEIGH.FWE_WEEKDATE%type;
    VarFWE_ENTRY_WEIGHT    FAL_WEIGH.FWE_ENTRY_WEIGHT%type;
    VarFWE_POSITION1_DESCR FAL_WEIGH.FWE_POSITION1_DESCR%type;
    VarFWE_POSITION2_DESCR FAL_WEIGH.FWE_POSITION2_DESCR%type;
    VarOutFalWeighID       FAL_WEIGH.FAL_WEIGH_ID%type;
  begin
    VarFWE_POSITION1_DESCR  := null;
    VarFWE_POSITION2_DESCR  := null;
    VarOutFalWeighID        := 0;

    open CUR_FAL_WEIGH;

    fetch CUR_FAL_WEIGH
     into CurFalWeigh;

    if CUR_FAL_WEIGH%found then
------------------------------------------------------------------------------------
--                             Pes�e d'entr�e
------------------------------------------------------------------------------------
      if PrmFAL_POSITION1_ID is not null then
        VarFWE_IN               := 1;

        if PCS.PC_CONFIG.GETCONFIG('FAL_WEIGH_STONE') = '0' then
          VarFWE_WEIGHT_MAT  := CurFalWeigh.FWE_WEIGHT;
        elsif PCS.PC_CONFIG.GETCONFIG('FAL_WEIGH_STONE') = '1' then
          if CurFalWeigh.FAL_SCHEDULE_STEP_ID is null then
            if PrmWeighingWithStone = 1 then
              VarFWE_WEIGHT_MAT  :=
                                  CurFalWeigh.FWE_WEIGHT
                                  -(nvl(GET_GCO_THEORICAL_STONE_WEIGHT(CurFalWeigh.GCO_GOOD_ID), 0) * nvl(CurFalWeigh.FWE_PIECE_QTY, 1) );
            else
              VarFWE_WEIGHT_MAT  := CurFalWeigh.FWE_WEIGHT;
            end if;
          else
            -- Si Double pes�e = Faux
            if PrmDoublePesee = 0 then
              if trim(GET_DIC_FREE_TASK_CODE(CurFalWeigh.FAL_SCHEDULE_STEP_ID) ) = 0 then
                VarFWE_WEIGHT_MAT  := CurFalWeigh.FWE_WEIGHT;
              else
                VarFWE_WEIGHT_MAT  :=
                                  CurFalWeigh.FWE_WEIGHT
                                  -(nvl(GET_GCO_THEORICAL_STONE_WEIGHT(CurFalWeigh.GCO_GOOD_ID), 0) * nvl(CurFalWeigh.FWE_PIECE_QTY, 1) );
              end if;
            else
              if trim(GET_DIC_FREE_TASK_CODE(GET_PREVIOUS_FAL_TASK_LINK_ID(CurFalWeigh.FAL_LOT_ID, CurFalWeigh.FAL_SCHEDULE_STEP_ID) ) ) = 0 then
                VarFWE_WEIGHT_MAT  := CurFalWeigh.FWE_WEIGHT;
              else
                VarFWE_WEIGHT_MAT  :=
                                  CurFalWeigh.FWE_WEIGHT
                                  -(nvl(GET_GCO_THEORICAL_STONE_WEIGHT(CurFalWeigh.GCO_GOOD_ID), 0) * nvl(CurFalWeigh.FWE_PIECE_QTY, 1) );
              end if;
            end if;
          end if;
        end if;

        -- Pes�e d'entr�e donc poids de la pes�e d'entr�e correspondante est null
        VarFWE_ENTRY_WEIGHT     := null;
        -- R�cup�ration de la description du poste entrant
        VarFWE_POSITION1_DESCR  := CurFalWeigh.FPO_DESCRIPTION1;
------------------------------------------------------------------------------------
--                             Pes�e de sortie
------------------------------------------------------------------------------------
      elsif PrmFAL_POSITION2_ID is not null then
        VarFWE_IN               := 0;

        if PCS.PC_CONFIG.GETCONFIG('FAL_WEIGH_STONE') = '0' then
          VarFWE_WEIGHT_MAT  := CurFalWeigh.FWE_WEIGHT;
        elsif PCS.PC_CONFIG.GETCONFIG('FAL_WEIGH_STONE') = '1' then
          if CurFalWeigh.FAL_SCHEDULE_STEP_ID is null then
            if PrmWeighingWithStone = 1 then
              VarFWE_WEIGHT_MAT  :=
                                  CurFalWeigh.FWE_WEIGHT
                                  -(nvl(GET_GCO_THEORICAL_STONE_WEIGHT(CurFalWeigh.GCO_GOOD_ID), 0) * nvl(CurFalWeigh.FWE_PIECE_QTY, 1) );
            else
              VarFWE_WEIGHT_MAT  := CurFalWeigh.FWE_WEIGHT;
            end if;
          else
            if trim(GET_DIC_FREE_TASK_CODE(CurFalWeigh.FAL_SCHEDULE_STEP_ID) ) = 0 then
              VarFWE_WEIGHT_MAT  := CurFalWeigh.FWE_WEIGHT;
            else
              VarFWE_WEIGHT_MAT  :=
                                  CurFalWeigh.FWE_WEIGHT
                                  -(nvl(GET_GCO_THEORICAL_STONE_WEIGHT(CurFalWeigh.GCO_GOOD_ID), 0) * nvl(CurFalWeigh.FWE_PIECE_QTY, 1) );
            end if;
          end if;
        end if;

        -- R�cup�ration de la description du poste sortant
        VarFWE_POSITION2_DESCR  := CurFalWeigh.FPO_DESCRIPTION2;
      end if;
    end if;

    /* Si pes�e pes�e Mouvement mati�re reli�e � une position document
    et si Config FAL_WEIGH_STONE = 1
    et bien pes� multi-alliage, alors
     prise en compte du poids des pierres dans le calcul du poids mati�re de l'alliage :
     poids mati�re = Poids pes� - poids th�oriques des pierres du produit */
    if nvl(CurFalWeigh.DOC_POSITION_ID, 0) <> 0 then
      if     IsMultiAlloyPDT(CurFalWeigh.GCO_GOOD_ID) > 1
         and PCS.PC_CONFIG.GETCONFIG('FAL_WEIGH_STONE') = '1'
         and iGenericRepartition = 0 then
        VarFWE_WEIGHT_MAT  := CurFalWeigh.FWE_WEIGHT -(nvl(GET_GCO_THEORICAL_STONE_WEIGHT(CurFalWeigh.GCO_GOOD_ID), 0) * nvl(CurFalWeigh.FWE_PIECE_QTY, 1) );
      elsif iGenericRepartition = 1 then
        VarFWE_WEIGHT_MAT  := CurFalWeigh.FWE_WEIGHT_MAT;
      else
        VarFWE_WEIGHT_MAT  := CurFalWeigh.FWE_WEIGHT;
      end if;
    end if;

    /* Si pes�e de type r�ception lot de fabrication, ni rebut, ni copeaux (cad si r�ception de produits termin�s
       et si config fal_weigh_stone = 1, alors prise en compte du poids des pierres dans le calcul du poids mati�re
       de l'alliage.
       poids mati�re = Poids pes� - poids th�oriques des pierres du produit */
    if     CurFalWeigh.C_WEIGH_TYPE = '4'
       and CurFalWeigh.FWE_WASTE <> 1
       and CurFalWeigh.FWE_TURNINGS <> 1 then
      if PCS.PC_CONFIG.GETCONFIG('FAL_WEIGH_STONE') = '1' then
        VarFWE_WEIGHT_MAT  := CurFalWeigh.FWE_WEIGHT -(nvl(GET_GCO_THEORICAL_STONE_WEIGHT(CurFalWeigh.GCO_GOOD_ID), 0) * nvl(CurFalWeigh.FWE_PIECE_QTY, 1) );
      else
        VarFWE_WEIGHT_MAT  := CurFalWeigh.FWE_WEIGHT;
      end if;
    end if;

    /* Si un plateau ou un poids plateau a �t� saisi alors on doit le d�duire du poids mati�re */
    if nvl(CurFalWeigh.FAL_SCALE_PAN_ID, 0) <> 0 then
      VarFWE_WEIGHT_MAT  := VarFWE_WEIGHT_MAT - CurFalWeigh.FSP_PAN_WEIGHT;
    elsif CurFalWeigh.FWE_PAN_WEIGHT <> 0 then
      VarFWE_WEIGHT_MAT  := VarFWE_WEIGHT_MAT - CurFalWeigh.FWE_PAN_WEIGHT;
    end if;

    /* Calcul de la semaine de la pes�e */
    VarFWE_WEEKDATE         := DOC_DELAY_FUNCTIONS.DATETOWEEK(CurFalWeigh.FWE_DATE);

    /* Update de la pes�e */
    if PrmFAL_WEIGH_CREATE = 0 then
      update FAL_WEIGH
         set GCO_ALLOY_ID = CurFalWeigh.GCO_ALLOY_ID
           , GCO_GOOD_ID = CurFalWeigh.GCO_GOOD_ID
           , STM_ELEMENT_NUMBER_ID = CurFalWeigh.STM_ELEMENT_NUMBER_ID
           , STM_ELEMENT_NUMBER2_ID = CurFalWeigh.STM_ELEMENT_NUMBER2_ID
           , STM_ELEMENT_NUMBER3_ID = CurFalWeigh.STM_ELEMENT_NUMBER3_ID
           , DOC_RECORD_ID = CurFalWeigh.DOC_RECORD_ID
           , DOC_DOCUMENT_ID = CurFalWeigh.DOC_DOCUMENT_ID
           , DOC_POSITION_ID = CurFalWeigh.DOC_POSITION_ID
           , FAL_SCHEDULE_STEP_ID = CurFalWeigh.FAL_SCHEDULE_STEP_ID
           , FAL_LOT_ID = CurFalWeigh.FAL_LOT_ID
           , FAL_LOT_DETAIL_ID = CurFalWeigh.FAL_LOT_DETAIL_ID
           , DIC_OPERATOR_ID = CurFalWeigh.DIC_OPERATOR_ID
           , FAL_POSITION1_ID = PrmFAL_POSITION1_ID
           , FAL_POSITION2_ID = PrmFAL_POSITION2_ID
           , FWE_IN = VarFWE_IN
           , FWE_WASTE = CurFalWeigh.FWE_WASTE
           , FWE_TURNINGS = CurFalWeigh.FWE_TURNINGS
           , FWE_INIT = 0
           , FWE_DATE = CurFalWeigh.FWE_DATE
           , FWE_WEIGHT = CurFalWeigh.FWE_WEIGHT
           , FWE_WEIGHT_MAT = VarFWE_WEIGHT_MAT
           , FWE_STONE_NUM = CurFalWeigh.FWE_STONE_NUM
           , FWE_COMMENT = CurFalWeigh.FWE_COMMENT
           , A_DATECRE = sysdate
           , A_IDCRE = CurFalWeigh.A_IDCRE
           , GAL_ALLOY_REF = CurFalWeigh.GAL_ALLOY_REF
           , FWE_POSITION1_DESCR = VarFWE_POSITION1_DESCR
           , FWE_POSITION2_DESCR = VarFWE_POSITION2_DESCR
           , GOO_MAJOR_REFERENCE = CurFalWeigh.GOO_MAJOR_REFERENCE
           , GOO_SECONDARY_REFERENCE = CurFalWeigh.GOO_SECONDARY_REFERENCE
           , FWE_WEEKDATE = VarFWE_WEEKDATE
           , FWE_ENTRY_WEIGHT = VarFWE_ENTRY_WEIGHT
           , C_WEIGH_TYPE = CurFalWeigh.C_WEIGH_TYPE
           , LOT_REFCOMPL = CurFalWeigh.LOT_REFCOMPL
           , DMT_NUMBER = CurFalWeigh.DMT_NUMBER
           , FWE_PIECE_QTY = CurFalWeigh.FWE_PIECE_QTY
           , FAL_LOT_PROGRESS_ID = CurFalWeigh.FAL_LOT_PROGRESS_ID
           , FAL_LOT_PROGRESS_FOG_ID = CurFalWeigh.FAL_LOT_PROGRESS_FOG_ID
           , FWE_PAN_WEIGHT = CurFalWeigh.FWE_PAN_WEIGHT
           , FAL_SCALE_PAN_ID = CurFalWeigh.FAL_SCALE_PAN_ID
       where FAL_WEIGH_ID = PrmFAL_WEIGH_ID;
    /* Cr�ation d'une pes�e */
    else
      VarOutFalWeighID  := GetNewId;

      insert into FAL_WEIGH
                  (FAL_WEIGH_ID
                 , GCO_ALLOY_ID
                 , GCO_GOOD_ID
                 , STM_ELEMENT_NUMBER_ID
                 , STM_ELEMENT_NUMBER2_ID
                 , STM_ELEMENT_NUMBER3_ID
                 , DOC_RECORD_ID
                 , DOC_DOCUMENT_ID
                 , DOC_POSITION_ID
                 , FAL_SCHEDULE_STEP_ID
                 , FAL_LOT_ID
                 , FAL_LOT_DETAIL_ID
                 , DIC_OPERATOR_ID
                 , FAL_POSITION1_ID
                 , FAL_POSITION2_ID
                 , FWE_IN
                 , FWE_WASTE
                 , FWE_TURNINGS
                 , FWE_INIT
                 , FWE_DATE
                 , FWE_WEIGHT
                 , FWE_WEIGHT_MAT
                 , FWE_STONE_NUM
                 , FWE_COMMENT
                 , A_DATECRE
                 , A_IDCRE
                 , GAL_ALLOY_REF
                 , FWE_POSITION1_DESCR
                 , FWE_POSITION2_DESCR
                 , GOO_MAJOR_REFERENCE
                 , GOO_SECONDARY_REFERENCE
                 , FWE_WEEKDATE
                 , FWE_ENTRY_WEIGHT
                 , LOT_REFCOMPL
                 , DMT_NUMBER
                 , FWE_PIECE_QTY
                 , C_WEIGH_TYPE
                 , FAL_LOT_PROGRESS_ID
                 , FAL_LOT_PROGRESS_FOG_ID
                 , FAL_SCALE_PAN_ID
                 , FWE_PAN_WEIGHT
                 , FWE_SESSION
                 , FAL_LOT_MATERIAL_LINK_ID
                  )
           values (VarOutFalWeighID
                 , CurFalWeigh.GCO_ALLOY_ID
                 , CurFalWeigh.GCO_GOOD_ID
                 , CurFalWeigh.STM_ELEMENT_NUMBER_ID
                 , CurFalWeigh.STM_ELEMENT_NUMBER2_ID
                 , CurFalWeigh.STM_ELEMENT_NUMBER3_ID
                 , CurFalWeigh.DOC_RECORD_ID
                 , CurFalWeigh.DOC_DOCUMENT_ID
                 , CurFalWeigh.DOC_POSITION_ID
                 , CurFalWeigh.FAL_SCHEDULE_STEP_ID
                 , CurFalWeigh.FAL_LOT_ID
                 , CurFalWeigh.FAL_LOT_DETAIL_ID
                 , CurFalWeigh.DIC_OPERATOR_ID
                 , PrmFAL_POSITION1_ID
                 , PrmFAL_POSITION2_ID
                 , VarFWE_IN
                 , CurFalWeigh.FWE_WASTE
                 , CurFalWeigh.FWE_TURNINGS
                 , 0
                 , CurFalWeigh.FWE_DATE
                 , CurFalWeigh.FWE_WEIGHT
                 , VarFWE_WEIGHT_MAT
                 , CurFalWeigh.FWE_STONE_NUM
                 , CurFalWeigh.FWE_COMMENT
                 , sysdate
                 , CurFalWeigh.A_IDCRE
                 , CurFalWeigh.GAL_ALLOY_REF
                 , VarFWE_POSITION1_DESCR
                 , VarFWE_POSITION2_DESCR
                 , CurFalWeigh.GOO_MAJOR_REFERENCE
                 , CurFalWeigh.GOO_SECONDARY_REFERENCE
                 , VarFWE_WEEKDATE
                 , VarFWE_ENTRY_WEIGHT
                 , CurFalWeigh.LOT_REFCOMPL
                 , CurFalWeigh.DMT_NUMBER
                 , CurFalWeigh.FWE_PIECE_QTY
                 , CurFalWeigh.C_WEIGH_TYPE
                 , CurFalWeigh.FAL_LOT_PROGRESS_ID
                 , CurFalWeigh.FAL_LOT_PROGRESS_FOG_ID
                 , CurFalWeigh.FAL_SCALE_PAN_ID
                 , CurFalWeigh.FWE_PAN_WEIGHT
                 , CurFalWeigh.FWE_SESSION
                 , CurFalWeigh.FAL_LOT_MATERIAL_LINK_ID
                  );
    end if;

    close CUR_FAL_WEIGH;

    return VarOutFalWeighID;
  end FAL_WEIGH_CREATE_OR_UPDATE;

  function CreateNonGenericWeigh(
    PrmFAL_WEIGH_ID     FAL_WEIGH.FAL_WEIGH_ID%type
  , prmGCO_ALLOY_ID     GCO_ALLOY.GCO_ALLOY_ID%type
  , prmWEIGHT_RATIO     number
  , prmFAL_POSITION1_ID FAL_WEIGH.FAL_POSITION1_ID%type
  , prmFAL_POSITION2_ID FAL_WEIGH.FAL_POSITION2_ID%type
  )
    return FAL_WEIGH.FAL_WEIGH_ID%type
  is
    newFAL_WEIGH_ID FAL_WEIGH.FAL_WEIGH_ID%type;
  begin
    newFAL_WEIGH_ID  := GetNewId;

    insert into FAL_WEIGH
                (FAL_WEIGH_ID
               , GCO_ALLOY_ID
               , GCO_GOOD_ID
               , STM_ELEMENT_NUMBER_ID
               , STM_ELEMENT_NUMBER2_ID
               , STM_ELEMENT_NUMBER3_ID
               , DOC_RECORD_ID
               , DOC_DOCUMENT_ID
               , DOC_POSITION_ID
               , FAL_SCHEDULE_STEP_ID
               , FAL_LOT_ID
               , FAL_LOT_DETAIL_ID
               , DIC_OPERATOR_ID
               , FAL_POSITION1_ID
               , FAL_POSITION2_ID
               , FWE_IN
               , FWE_WASTE
               , FWE_TURNINGS
               , FWE_INIT
               , FWE_DATE
               , FWE_WEIGHT
               , FWE_WEIGHT_MAT
               , FWE_STONE_NUM
               , FWE_COMMENT
               , A_DATECRE
               , A_IDCRE
               , GAL_ALLOY_REF
               , FWE_POSITION1_DESCR
               , FWE_POSITION2_DESCR
               , GOO_MAJOR_REFERENCE
               , GOO_SECONDARY_REFERENCE
               , FWE_WEEKDATE
               , FWE_ENTRY_WEIGHT
               , LOT_REFCOMPL
               , DMT_NUMBER
               , FWE_PIECE_QTY
               , C_WEIGH_TYPE
               , FAL_LOT_PROGRESS_ID
               , FAL_LOT_PROGRESS_FOG_ID
               , FAL_SCALE_PAN_ID
               , FWE_PAN_WEIGHT
               , FAL_LOT_HIST_ID
               , FAL_FAL_SCHEDULE_STEP_ID
               , FAL_LOT_PROGRESS_HIST_ID
               , SCS_STEP_NUMBER_HIST
               , LOT_REFCOMPL_HIST
                )
      (select newFAL_WEIGH_ID
            , prmGCO_ALLOY_ID   -- Alliage r�el (non g�n�rique)
            , GCO_GOOD_ID
            , STM_ELEMENT_NUMBER_ID
            , STM_ELEMENT_NUMBER2_ID
            , STM_ELEMENT_NUMBER3_ID
            , DOC_RECORD_ID
            , DOC_DOCUMENT_ID
            , DOC_POSITION_ID
            , FAL_SCHEDULE_STEP_ID
            , FAL_LOT_ID
            , FAL_LOT_DETAIL_ID
            , DIC_OPERATOR_ID
            , decode(prmFAL_POSITION1_ID, 0, null, prmFAL_POSITION1_ID)
            , decode(prmFAL_POSITION2_ID, 0, null, prmFAL_POSITION2_ID)
            , FWE_IN
            , FWE_WASTE
            , FWE_TURNINGS
            , FWE_INIT
            , FWE_DATE
            , FWE_WEIGHT * prmWEIGHT_RATIO   -- FWE_WEIGHT ???
            , FWE_WEIGHT_MAT * prmWEIGHT_RATIO   -- FWE_WEIGHT_MAT ???
            , FWE_STONE_NUM
            , FWE_COMMENT
            , A_DATECRE
            , A_IDCRE
            , GAL_ALLOY_REF
            , FWE_POSITION1_DESCR
            , FWE_POSITION2_DESCR
            , GOO_MAJOR_REFERENCE
            , GOO_SECONDARY_REFERENCE
            , FWE_WEEKDATE
            , FWE_ENTRY_WEIGHT
            , LOT_REFCOMPL
            , DMT_NUMBER
            , FWE_PIECE_QTY
            , C_WEIGH_TYPE
            , FAL_LOT_PROGRESS_ID
            , FAL_LOT_PROGRESS_FOG_ID
            , null   -- Plateau
            , 0   -- poids plateau
            , FAL_LOT_HIST_ID
            , FAL_FAL_SCHEDULE_STEP_ID
            , FAL_LOT_PROGRESS_HIST_ID
            , SCS_STEP_NUMBER_HIST
            , LOT_REFCOMPL_HIST
         from FAL_WEIGH
        where FAL_WEIGH_ID = PrmFAL_WEIGH_ID);

    return newFAL_WEIGH_ID;
  end;

  /**
  * proc�dure FAL_WEIGH_VALIDATION
  * Description : Procedure de validation d'une pes�e.
  *
  * @created ECA
  * @lastUpdate
  * @private
  * @param   PrmFAL_WEIGH_ID : pes�e � valider
  * @param   prmFAL_POSITION1_ID : Poste Sortant
  * @param   prmFAL_POSITION2_ID : Poste Entrant
  * @param   VarDoublePesee : Double pes�e
  * @param   outWeighID : ID pes�e
  * @param   PrmWeighingWithStone : pes�e avec pierres.
  */
  procedure FAL_WEIGH_VALIDATION(
    PrmFAL_WEIGH_ID             FAL_WEIGH.FAL_WEIGH_ID%type
  , prmFAL_POSITION1_ID         FAL_WEIGH.FAL_POSITION1_ID%type
  , prmFAL_POSITION2_ID         FAL_WEIGH.FAL_POSITION2_ID%type
  , VarDoublePesee              number
  , outWeighID           in out FAL_WEIGH.FAL_WEIGH_ID%type
  , PrmWeighingWithStone        integer default 0
  , iGenericRepartition         integer default 0
  )
  is
    varTemp         FAL_WEIGH.FAL_WEIGH_ID%type;
    lvCMovementSort varchar2(10);
  begin
    outWeighID  := 0;

    -- Si on a une double pes�e,
    if VarDoublePesee = 1 then
      if (prmFAL_POSITION2_ID <> 0) then
        varTemp  := FAL_WEIGH_CREATE_OR_UPDATE(PrmFAL_WEIGH_ID, null, prmFAL_POSITION2_ID, VarDoublePesee, 0, PrmWeighingWithStone, iGenericRepartition);
      -- Si poste entrant n'est pas nul.
      elsif(prmFAL_POSITION1_ID <> 0) then
        varTemp  := FAL_WEIGH_CREATE_OR_UPDATE(PrmFAL_WEIGH_ID, prmFAL_POSITION1_ID, null, VarDoublePesee, 0, PrmWeighingWithStone, iGenericRepartition);
      end if;
    -- Si simple pes�e
    else
      -- Recherche du genre de mouvement de la position de document
      begin
        select nvl(MOK.C_MOVEMENT_SORT, 'UNKNOWN') C_MOVEMENT_SORT
          into lvCMovementSort
          from DOC_POSITION POS
             , FAL_WEIGH FWE
             , STM_MOVEMENT_KIND MOK
         where FWE.FAL_WEIGH_ID = PrmFAL_WEIGH_ID
           and POS.DOC_POSITION_ID = FWE.DOC_POSITION_ID
           and MOK.STM_MOVEMENT_KIND_ID(+) = POS.STM_MOVEMENT_KIND_ID;
      exception
        when others then
          lvCMovementSort  := 'UNKNOWN';
      end;

      -- Genre de mouvement inconnu, ou entr�e
      if    lvCMovementSort = 'UNKNOWN'
         or lvCMovementSort = 'ENT' then
        -- Cr�ation de la pes�e de sortie
        outWeighID  := FAL_WEIGH_CREATE_OR_UPDATE(PrmFAL_WEIGH_ID, null, prmFAL_POSITION2_ID, VarDoublePesee, 1, PrmWeighingWithStone, iGenericRepartition);
        -- Update de la pes�e d�j� valid�e
        varTemp     := FAL_WEIGH_CREATE_OR_UPDATE(PrmFAL_WEIGH_ID, prmFAL_POSITION1_ID, null, VarDoublePesee, 0, PrmWeighingWithStone, iGenericRepartition);
      -- Genre de mouvement sortie
      elsif lvCMovementSort = 'SOR' then
        -- Cr�ation de la pes�e d'entr�e
        outWeighID  := FAL_WEIGH_CREATE_OR_UPDATE(PrmFAL_WEIGH_ID, prmFAL_POSITION1_ID, null, VarDoublePesee, 1, PrmWeighingWithStone, iGenericRepartition);
        -- Update de la pes�e d�j� valid�e
        varTemp     := FAL_WEIGH_CREATE_OR_UPDATE(PrmFAL_WEIGH_ID, null, prmFAL_POSITION2_ID, VarDoublePesee, 0, PrmWeighingWithStone, iGenericRepartition);
      end if;
    end if;
  end;

  /**
  * proc�dure FAL_WEIGH_VALIDATION
  * Description : Procedure de validation d'une pes�e.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   PrmFAL_WEIGH_ID : pes�e � valider
  * @param   PrmWeighingWithStone : Pes�e avec pierres
  */
  procedure FAL_WEIGH_VALIDATION(PrmFAL_WEIGH_ID FAL_WEIGH.FAL_WEIGH_ID%type, PrmWeighingWithStone integer default 0)
  is
    -- Curseurs
    cursor CUR_FAL_WEIGH
    is
      select nvl(FAL_POSITION1_ID, 0) FAL_POSITION1_ID
           , nvl(FAL_POSITION2_ID, 0) FAL_POSITION2_ID
           , GCO_GOOD_ID
           , GCO_ALLOY_ID
        from FAL_WEIGH
       where FAL_WEIGH_ID = PrmFAL_WEIGH_ID;

    cursor CUR_FAL_ALLOY_OF_GOOD(aGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type)
    is
      select PMA.GCO_ALLOY_ID
           , nvl(GPM_WEIGHT_DELIVER, 0) / (select sum( (GPM.GPM_WEIGHT_DELIVER) * nvl(GAL.GAL_CONVERT_FACTOR_GR, 1) )
                                             from GCO_PRECIOUS_MAT GPM
                                                , GCO_ALLOY GAL
                                            where GPM.GCO_GOOD_ID = aGCO_GOOD_ID
                                              and GPM.GCO_ALLOY_ID = GAL.GCO_ALLOY_ID
                                              and nvl(GPM.GPM_REAL_WEIGHT, 0) = 1) WEIGHT_RATIO
        from GCO_PRECIOUS_MAT PMA
           , GCO_ALLOY LOY
       where PMA.GCO_GOOD_ID = aGCO_GOOD_ID
         and PMA.GCO_ALLOY_ID = LOY.GCO_ALLOY_ID
         and PMA.GPM_WEIGHT = 1
         and nvl(LOY.GAL_GENERIC, 0) = 0
         and nvl(PMA.GPM_REAL_WEIGHT, 0) = 1;   -- On ne prend que les pes�es r�elles

    -- Variables
    CurFalWeigh     CUR_FAL_WEIGH%rowtype;
    VarDoublePesee  number;
    newFAL_WEIGH_ID FAL_WEIGH.FAL_WEIGH_ID%type;
    outWeighID      FAL_WEIGH.FAL_WEIGH_ID%type;
  begin
    -- Initialisation param�tre double pes�e.
    VarDoublePesee  := 1;

    for CurFalWeigh in CUR_FAL_WEIGH loop
      -- Si poste sortants et entrant non nuls, alors double pes�e.
      if     (CurFalWeigh.FAL_POSITION1_ID <> 0)
         and (CurFalWeigh.FAL_POSITION2_ID <> 0) then
        VarDoublePesee  := 0;
      end if;

      if     (VarDoublePesee = 1)
         and (CurFalWeigh.FAL_POSITION1_ID = 0)
         and (CurFalWeigh.FAL_POSITION2_ID = 0) then
        DELETE_FAL_WEIGH(PrmFAL_WEIGH_ID);
      else
        FAL_WEIGH_VALIDATION(PrmFAL_WEIGH_ID, CurFalWeigh.FAL_POSITION1_ID, CurFalWeigh.FAL_POSITION2_ID, VarDoublePesee, outWeighID, PrmWeighingWithStone);
      end if;

      if (CurFalWeigh.GCO_ALLOY_ID = GCO_I_LIB_ALLOY.getGenericAlloy) then
        for CurFalAlloyOfGood in CUR_FAL_ALLOY_OF_GOOD(CurFalWeigh.GCO_GOOD_ID) loop
          newFAL_WEIGH_ID  :=
            CreateNonGenericWeigh(PrmFAL_WEIGH_ID
                                , CurFalAlloyOfGood.GCO_ALLOY_ID
                                , CurFalAlloyOfGood.WEIGHT_RATIO
                                , CurFalWeigh.FAL_POSITION1_ID
                                , CurFalWeigh.FAL_POSITION2_ID
                                 );
          FAL_WEIGH_VALIDATION(newFAL_WEIGH_ID, CurFalWeigh.FAL_POSITION1_ID, CurFalWeigh.FAL_POSITION2_ID, VarDoublePesee, outWeighID, PrmWeighingWithStone, 1);
        end loop;
      end if;
    end loop;
  end FAL_WEIGH_VALIDATION;

  /**
   * proc�dure FAL_CUST_WEIGH_VALIDATION
   * Description : Procedure de validation d'une pes�e individualisable (template)
   * @created AGA
   * @lastUpdate SMA DEZ.2012
   * @public
   * @param   iFAL_WEIGH_ID : pes�e � valider
   * @param   iGCO_ALLOY_ID : Alliage
   * @param   iGCO_GOOD_ID : Bien
   * @param   iSTM_ELEMENT_NUMBER_ID : Num�ro de pi�ce lot ou version
   * @param   iDOC_DOCUMENT_ID : Document
   * @param   iDOC_POSITION_ID : Position
   * @param   iFAL_SCHEDULE_STEP_ID : Lien t�che
   * @param   iFAL_LOT_ID : Lot
   * @param   iDIC_OPERATOR_ID : Op�rateur
   * @param   iFAL_POSITION1_ID : Poste entrant
   * @param   iFAL_POSITION2_ID : Poste sortant
   * @param   iFWE_IN : Code entr�e
   * @param   iFWE_WASTE : Code rebut
   * @param   iFWE_TURNINGS : Code copeaux
   * @param   iFWE_WEIGHT : Poids pes�
   * @param   iFWE_WEIGHT_MAT : Poids mati�re
   * @param   iFWE_STONE_NUM : Nombre de pierre
   * @param   iFWE_PIECE_QTY : Nombre de pi�ce
   * @param   iC_WEIGH_TYPE : Types de pes�es
   * @param   iFAL_LOT_PROGRESS_ID : Suivi de fabrication
   * @param   iFAL_SCALE_PAN_ID : Plateau
   * @param   iFWE_PAN_WEIGHT : Poids plateau
   * @param   iFAL_LOT_MATERIAL_LINK_ID : Lien composant
   * @param   iDOC_RECORD_ID : Dossier
   * @param   iSTM_ELEMENT_NUMBER2_ID : Num�ro de pi�ce lot ou version 2
   * @param   iSTM_ELEMENT_NUMBER3_ID : Num�ro de pi�ce lot ou version 3
   * @param   oErrorMessage : message d'erreur de validation
   */
  procedure FAL_CUST_WEIGH_VALIDATION(
    iFAL_WEIGH_ID             in     FAL_WEIGH.FAL_WEIGH_ID%type
  , iGCO_ALLOY_ID             in     FAL_WEIGH.GCO_ALLOY_ID%type
  , iGCO_GOOD_ID              in     FAL_WEIGH.GCO_GOOD_ID%type
  , iSTM_ELEMENT_NUMBER_ID    in     FAL_WEIGH.STM_ELEMENT_NUMBER_ID%type
  , iDOC_DOCUMENT_ID          in     FAL_WEIGH.DOC_DOCUMENT_ID%type
  , iDOC_POSITION_ID          in     FAL_WEIGH.DOC_POSITION_ID%type
  , iFAL_SCHEDULE_STEP_ID     in     FAL_WEIGH.FAL_SCHEDULE_STEP_ID%type
  , iFAL_LOT_ID               in     FAL_WEIGH.FAL_LOT_ID%type
  , iDIC_OPERATOR_ID          in     FAL_WEIGH.DIC_OPERATOR_ID%type
  , iFAL_POSITION1_ID         in     FAL_WEIGH.FAL_POSITION1_ID%type
  , iFAL_POSITION2_ID         in     FAL_WEIGH.FAL_POSITION2_ID%type
  , iFWE_IN                   in     FAL_WEIGH.FWE_IN%type
  , iFWE_WASTE                in     FAL_WEIGH.FWE_WASTE%type
  , iFWE_TURNINGS             in     FAL_WEIGH.FWE_TURNINGS%type
  , iFWE_WEIGHT               in     FAL_WEIGH.FWE_WEIGHT%type
  , iFWE_WEIGHT_MAT           in     FAL_WEIGH.FWE_WEIGHT_MAT%type
  , iFWE_STONE_NUM            in     FAL_WEIGH.FWE_STONE_NUM%type
  , iFWE_PIECE_QTY            in     FAL_WEIGH.FWE_PIECE_QTY%type
  , iC_WEIGH_TYPE             in     FAL_WEIGH.C_WEIGH_TYPE%type
  , iFAL_LOT_PROGRESS_ID      in     FAL_WEIGH.FAL_LOT_PROGRESS_ID%type
  , iFAL_SCALE_PAN_ID         in     FAL_WEIGH.FAL_SCALE_PAN_ID%type
  , iFWE_PAN_WEIGHT           in     FAL_WEIGH.FWE_PAN_WEIGHT%type
  , iFAL_LOT_MATERIAL_LINK_ID in     FAL_WEIGH.FAL_LOT_MATERIAL_LINK_ID%type
  , iDOC_RECORD_ID            in     FAL_WEIGH.DOC_RECORD_ID%type
  , iSTM_ELEMENT_NUMBER2_ID   in     FAL_WEIGH.STM_ELEMENT_NUMBER2_ID%type
  , iSTM_ELEMENT_NUMBER3_ID   in     FAL_WEIGH.STM_ELEMENT_NUMBER3_ID%type
  , oErrorMessage             out    varchar2
  )
  is
  begin
    oErrorMessage  := '';
  end;

/*
 Procedure dD'�clatement d'une pes�e lors de l'�clatement d'un lot
*  @param        iFAL_WEIGH_ID  identifiant de l'enregistrement utilis� pour la saisie manuelle des poids
*  @param        iMatLinkID composant relatif � la pes�e pour le lot �clat�
*  @param        iNewMatLinkID composant relatif � la pes�e pour le nouveau lot
*  @param        iSplitRatio -> correspond au rapport entre la quantit� de l'�clatement par rapport � la quantit� totale du composant avant l'�clatement
*  @param        iSessionID : Session oracle.
*/
  procedure FAL_WEIGH_SPLIT(
    iFAL_WEIGH_ID in TTypeID default null
  , iMatLinkID    in TTypeID default null
  , iNewMatLinkID in TTypeID default null
  , iSplitRatio      number default 1
  , iSession      in varchar2
  )
  is
    -- Curseurs
    cursor Cur_Origin_Fal_Weigh(iMatLinkId in TTypeID, iFAL_WEIGH_ID in TTypeId)
    is
      select   *
          -- Lectures des poids li�s au composants
      from     (select   GCO_ALLOY_ID   -- Liste des entr�es sortie du stock atelier
                       , min(FAL_WEIGH_ID) FAL_WEIGH_ID   -- premiere entr�e  dans le stock atelier
                       , min(nvl(FAL_POSITION1_ID, 0) ) FAL_POSITION1_ID
                       , min(nvl(FAL_POSITION2_ID, 0) ) FAL_POSITION2_ID
                       , min(nvl(FAL_POSITION1_ID, FAL_POSITION2_ID) ) FAL_POSITION_ID
                       , sum(decode(FWE_IN, 1, nvl(FWE_PIECE_QTY, 0), 0) ) - sum(decode(FWE_IN, 0, nvl(FWE_PIECE_QTY, 0), 0) ) FWE_PIECE_QTY
                       , sum(decode(FWE_IN, 1, nvl(FWE_WEIGHT, 0), 0) ) - sum(decode(FWE_IN, 0, nvl(FWE_WEIGHT, 0), 0) ) FWE_WEIGHT
                       , sum(decode(FWE_IN, 1, nvl(FWE_WEIGHT_MAT, 0), 0) ) - sum(decode(FWE_IN, 0, nvl(FWE_WEIGHT_MAT, 0), 0) ) FWE_WEIGHT_MAT
                       , sum(decode(FWE_IN, 1, nvl(FWE_STONE_NUM, 0), 0) ) - sum(decode(FWE_IN, 0, nvl(FWE_STONE_NUM, 0), 0) ) FWE_STONE_NUM
                    from FAL_WEIGH FWE
                       , FAL_POSITION FPO
                   where iFAL_WEIGH_ID is null
                     and iMatLinkId is not null
                     and FWE.FAL_LOT_MATERIAL_LINK_ID = iMatLinkId
                     and FPO.STM_STOCK_ID = (select max(STM_STOCK_ID)   -- uniquement le stock atelier
                                               from STM_STOCK
                                              where STO_DESCRIPTION = PCS.PC_CONFIG.GetConfig('PPS_DefltSTOCK_FLOOR') )
                     and nvl(FAL_POSITION1_ID, FAL_POSITION2_ID) = FPO.FAL_POSITION_ID
                group by FWE.GCO_ALLOY_ID
                union
                -- LECTURE DU RECORD SAISI PAR L'INTERFACE FAL_frmFAL_WEIGH (contient le stock entrant et sortant dans le m�me record)
                select FWE.GCO_ALLOY_ID
                     , FWE.FAL_WEIGH_ID
                     , FWE.FAL_POSITION1_ID
                     , FWE.FAL_POSITION2_ID
                     , null FAL_POSITION_ID
                     , FWE.FWE_PIECE_QTY
                     , FWE.FWE_WEIGHT
                     , FWE.FWE_WEIGHT_MAT
                     , FWE.FWE_STONE_NUM
                  from FAL_WEIGH FWE
                 where iFAL_WEIGH_ID is not null
                   and FAL_WEIGH_ID = iFAL_WEIGH_ID)
      order by FAL_WEIGH_ID;

    cursor Cur_Origin_Fal_Weigh_out(iMatLinkID in TTypeID, iInWeighId in TTypeId, iAlloyId in TTypeId)
    is
      select   FWE.FAL_WEIGH_ID
             , FWE.FAL_POSITION2_ID
          from FAL_WEIGH FWE
         where FWE.FAL_WEIGH_ID > iInWeighId
           and FWE.FAL_LOT_MATERIAL_LINK_ID = iMatLinkId
           and FWE_IN = 0
           and GCO_ALLOY_ID = iAlloyId
      order by FWE.FAL_WEIGH_ID;

    -- Variables
    CurOriginFalWeigh     Cur_Origin_Fal_Weigh%rowtype;
    CurOriginFalWeigh_out Cur_Origin_Fal_Weigh_out%rowtype;
    lNewWeighID           FAL_WEIGH.FAL_WEIGH_ID%type;
    lFAL_POSITION1_ID     FAL_POSITION.FAL_POSITION_ID%type;
    lFAL_POSITION2_ID     FAL_POSITION.FAL_POSITION_ID%type;
    VarDoublePesee        number;
    newFAL_WEIGH_ID       FAL_WEIGH.FAL_WEIGH_ID%type;
    lInWeighID            FAL_WEIGH.FAL_WEIGH_ID%type;
    loutWeighID           FAL_WEIGH.FAL_WEIGH_ID%type;
    loutWeighID2          FAL_WEIGH.FAL_WEIGH_ID%type;
  begin
    -- Initialisation param�tre double pes�e.
    VarDoublePesee  := 1;

    for CurOriginFalWeigh in Cur_Origin_Fal_Weigh(iMatLinkId, iFAL_WEIGH_ID) loop
      if     iFAL_WEIGH_ID is null
         and iMatLinkId is not null then
        lFAL_POSITION1_ID  := 0;
        lFAL_POSITION2_ID  := CurOriginFalWeigh.FAL_POSITION_ID;   -- initialisation stock sortant = stock atelier

        for CurOriginFalWeighOut in Cur_Origin_Fal_Weigh_Out(iMatLinkId, CurOriginFalWeigh.FAL_WEIGH_ID, CurOriginFalWeigh.GCO_ALLOY_ID) loop
          -- lecture de la premiere sortie qui suit la premiere entr�e dans le stock atelier
          -- le stock atelier devient le stock sortant
          -- le stock sortant devient le stock entrant
          lOutWeighId        := CurOriginFalWeighOut.FAL_WEIGH_ID;
          lFAL_POSITION1_ID  := CurOriginFalWeighOut.FAL_POSITION2_ID;   -- initialisation stock entrant
          exit;
        end loop;
      elsif iFAL_WEIGH_ID is not null then
        lFAL_POSITION1_ID  := CurOriginFalWeigh.FAL_POSITION1_ID;
        lFAL_POSITION2_ID  := CurOriginFalWeigh.FAL_POSITION2_ID;
      end if;

      -- Si poste sortants et entrant non nuls, alors double pes�e.
      if     (lFAL_POSITION1_ID <> 0)
         and (lFAL_POSITION2_ID <> 0) then
        VarDoublePesee   := 0;

        if iFAL_WEIGH_ID is null then
          -- mouvement de poids sortant du lot �clat�
          -- Sortie du stock atelier + entr�e dans le stock de sortie de la premiere pes�e relatif au composant
          newFAL_WEIGH_ID  := CreateNonGenericWeigh(CurOriginFalWeigh.FAL_WEIGH_ID, CurOriginFalWeigh.GCO_ALLOY_ID, 1, lFAL_POSITION1_ID, lFAL_POSITION2_ID);
        else
          newFAL_WEIGH_ID  := iFAL_WEIGH_ID;
        end if;

        if iMatLinkId is not null then
          update FAL_WEIGH
             set FWE_SESSION = iSession
               , C_WEIGH_TYPE = '7'   -- retour atelier
               , FAL_LOT_MATERIAL_LINK_ID = iMatLinkId
               , FAL_LOT_ID = (select FAL_LOT_ID
                                 from FAL_LOT_MATERIAL_LINK
                                where FAL_LOT_MATERIAL_LINK_ID = iMatLinkId)
               , FWE_PIECE_QTY = CurOriginFalWeigh.FWE_PIECE_QTY * iSplitRatio
               , FWE_WEIGHT = CurOriginFalWeigh.FWE_WEIGHT * iSplitRatio
               , FWE_WEIGHT_MAT = CurOriginFalWeigh.FWE_WEIGHT_MAT * iSplitRatio
               , FWE_STONE_NUM = CurOriginFalWeigh.FWE_STONE_NUM * iSplitRatio
           where FAL_WEIGH_ID = newFAL_WEIGH_ID;
        end if;

        FAL_WEIGH_VALIDATION(newFAL_WEIGH_ID, lFAL_POSITION1_ID, lFAL_POSITION2_ID, VarDoublePesee, lOutWeighID2);
        -- mouvement de poids entrant pour le nouveau lot
        -- Sortie du stock de sortie de la premiere pes�e relatif au composant + entr�e dans le stock atelier
        -- le stock sortant devient le stock entrant
        newFAL_WEIGH_ID  := CreateNonGenericWeigh(CurOriginFalWeigh.FAL_WEIGH_ID, CurOriginFalWeigh.GCO_ALLOY_ID, 1, lFAL_POSITION2_ID, lFAL_POSITION1_ID);

        if iNewMatLinkId is not null then
          update FAL_WEIGH
             set FWE_SESSION = iSession
               , C_WEIGH_TYPE = '6'   -- Mouvement composants
               , FAL_LOT_MATERIAL_LINK_ID = iNewMatLinkId
               , FAL_LOT_ID = (select FAL_LOT_ID
                                 from FAL_LOT_MATERIAL_LINK
                                where FAL_LOT_MATERIAL_LINK_ID = iNewMatLinkId)
               , FWE_PIECE_QTY = CurOriginFalWeigh.FWE_PIECE_QTY * iSplitRatio
               , FWE_WEIGHT = CurOriginFalWeigh.FWE_WEIGHT * iSplitRatio
               , FWE_WEIGHT_MAT = CurOriginFalWeigh.FWE_WEIGHT_MAT * iSplitRatio
               , FWE_STONE_NUM = CurOriginFalWeigh.FWE_STONE_NUM * iSplitRatio
           where FAL_WEIGH_ID = newFAL_WEIGH_ID;
        end if;

        FAL_WEIGH_VALIDATION(newFAL_WEIGH_ID, lFAL_POSITION2_ID, lFAL_POSITION1_ID, VarDoublePesee, loutWeighID2);
      end if;
    end loop;
  end;

  /**
  * function GET_DIC_FREE_TASK_CODE
  * Description : Fonction qui renvoie le DIC_FREE_TASK_CODE de l'op�ration pass�e en param�tre
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   PrmFAL_SCHEDULE_STEP_ID : Op�ration
  */
  function GET_DIC_FREE_TASK_CODE(PrmFAL_SCHEDULE_STEP_ID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return number
  is
    -- Curseur
    cursor CUR_FREE_TASK_CODE
    is
      select nvl(DIC_FREE_TASK_CODE_ID, '') DIC_FREE_TASK_CODE_ID
        from FAL_TASK_LINK
       where FAL_SCHEDULE_STEP_ID = PrmFAL_SCHEDULE_STEP_ID
         and DIC_FREE_TASK_CODE_ID is not null;

    -- Variables
    CurFreeTaskCode CUR_FREE_TASK_CODE%rowtype;
  begin
    if PrmFAL_SCHEDULE_STEP_ID is not null then
      open CUR_FREE_TASK_CODE;

      fetch CUR_FREE_TASK_CODE
       into CurFreeTaskCode;

      if CUR_FREE_TASK_CODE%found then
        return 1;
      else
        return 0;
      end if;

      close CUR_FREE_TASK_CODE;
    else
      return 0;
    end if;
  end GET_DIC_FREE_TASK_CODE;

  /**
  * function GET_GCO_THEORICAL_STONE_WEIGHT
  * Description : Function qui renvoie le poids th�orique de pierre du produit pass� en param�tre
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   PrmGCO_GOOD_ID : produit
  */
  function GET_GCO_THEORICAL_STONE_WEIGHT(PrmGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER%type
  is
    -- Curseurs
    cursor CUR_GCO_PRECIOUS_MAT
    is
      select sum(nvl(GPM.GPM_WEIGHT_DELIVER, 0) * nvl(GAL.GAL_CONVERT_FACTOR_GR, 1) ) GPM_WEIGHT_DELIVER
        from GCO_PRECIOUS_MAT GPM
           , GCO_ALLOY GAL
       where GPM.GCO_GOOD_ID = PrmGCO_GOOD_ID
         and GPM.GCO_ALLOY_ID = GAL.GCO_ALLOY_ID
         and GAL.GAL_STONE = 1;

    -- Variables
    CurGcoPreciousMat CUR_GCO_PRECIOUS_MAT%rowtype;
    nStoneWeight      number;
  begin
    nStoneWeight  := 0;

    open CUR_GCO_PRECIOUS_MAT;

    fetch CUR_GCO_PRECIOUS_MAT
     into CurGcoPreciousMat;

    if CUR_GCO_PRECIOUS_MAT%found then
      nStoneWeight  := CurGcoPreciousMat.GPM_WEIGHT_DELIVER;
    else
      nStoneWeight  := 0;
    end if;

    close CUR_GCO_PRECIOUS_MAT;

    return nStoneWeight;
  end GET_GCO_THEORICAL_STONE_WEIGHT;

  /**
  * function GET_PREVIOUS_FAL_TASK_LINK_ID
  * Description : Fonction qui renvoie l'ID de l'op�ration pr�c�dent celle pass�e en param�tre du lot
  *               pass� en param�tre
  * @created ECA
  * @lastUpdate
  * @public
  * @param   PrmFAL_LOT_ID            : Lot
  * @param   PrmFAL_SCHEDULE_STEP_ID  : Operation
  */
  function GET_PREVIOUS_FAL_TASK_LINK_ID(PrmFAL_LOT_ID FAL_LOT.FAL_LOT_ID%type, PrmFAL_SCHEDULE_STEP_ID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
    return FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  is
    -- Curseur
    cursor CUR_FAL_TASK_LINK
    is
      select   nvl(FAL_SCHEDULE_STEP_ID, 0) FAL_SCHEDULE_STEP_ID
          from FAL_TASK_LINK
         where FAL_LOT_ID = PrmFAL_LOT_ID
           and SCS_STEP_NUMBER < (select SCS_STEP_NUMBER
                                    from FAL_TASK_LINK
                                   where FAL_SCHEDULE_STEP_ID = PrmFAL_SCHEDULE_STEP_ID)
      order by SCS_STEP_NUMBER desc;

    -- Variables
    CurFalTaskLink CUR_FAL_TASK_LINK%rowtype;
  begin
    if     (PrmFAL_LOT_ID is not null)
       and (PrmFAL_SCHEDULE_STEP_ID is not null) then
      open CUR_FAL_TASK_LINK;

      fetch CUR_FAL_TASK_LINK
       into CurFalTaskLink;

      if CUR_FAL_TASK_LINK%found then
        return CurFalTaskLink.FAL_SCHEDULE_STEP_ID;
      else
        return 0;
      end if;

      close CUR_FAL_TASK_LINK;
    else
      return 0;
    end if;
  end;

  /**
  * function GET_PREVIOUS_FAL_TASK_LINK_HIST_ID
  * Description : Fonction qui renvoie l'ID de l'op�ration pr�c�dent celle pass�e en param�tre du lot
  *               pass� en param�tre, pour les lots et liens t�ches archiv�s.
  * @created ECA
  * @lastUpdate
  * @public
  * @param   PrmFAL_LOT_HIST_ID       : Lot archiv�
  * @param   PrmFAL_SCHEDULE_STEP_ID  : Operation archiv�e
  */
  function GET_PREV_FAL_TASK_LINK_HIST_ID(
    PrmFAL_LOT_HIST_ID      FAL_LOT_HIST.FAL_LOT_HIST_ID%type
  , PrmFAL_SCHEDULE_STEP_ID FAL_TASK_LINK_HIST.FAL_SCHEDULE_STEP_ID%type
  )
    return FAL_TASK_LINK_HIST.FAL_SCHEDULE_STEP_ID%type
  is
    -- Curseur
    cursor CUR_FAL_TASK_LINK_HIST
    is
      select   nvl(FAL_SCHEDULE_STEP_ID, 0) FAL_SCHEDULE_STEP_ID
          from FAL_TASK_LINK_HIST
         where FAL_LOT_HIST_ID = PrmFAL_LOT_HIST_ID
           and SCS_STEP_NUMBER < (select SCS_STEP_NUMBER
                                    from FAL_TASK_LINK_HIST
                                   where FAL_SCHEDULE_STEP_ID = PrmFAL_SCHEDULE_STEP_ID)
      order by SCS_STEP_NUMBER desc;

    -- Variables
    CurFalTaskLinkHist CUR_FAL_TASK_LINK_HIST%rowtype;
  begin
    if     (PrmFAL_LOT_HIST_ID is not null)
       and (PrmFAL_SCHEDULE_STEP_ID is not null) then
      open CUR_FAL_TASK_LINK_HIST;

      fetch CUR_FAL_TASK_LINK_HIST
       into CurFalTaskLinkHist;

      if CUR_FAL_TASK_LINK_HIST%found then
        return CurFalTaskLinkHist.FAL_SCHEDULE_STEP_ID;
      else
        return 0;
      end if;

      close CUR_FAL_TASK_LINK_HIST;
    else
      return 0;
    end if;
  end;

  /**
  * function GET_ENTRY_WEIGHT
  * Description : Fonction qui renvoie le poids de la pes�e d'entr�e correspondant � une pes�e de sortie.
  * @created ECA
  * @lastUpdate
  * @public
  * @param   PrmFAL_LOT_ID           Lot
  * @param   PrmFAL_SCHEDULE_STEP_ID Operation
  * @param   PrmGCO_ALLOY_ID         Alliage
  */
  function GET_ENTRY_WEIGHT(
    PrmFAL_LOT_ID           FAL_LOT.FAL_LOT_ID%type
  , PrmFAL_SCHEDULE_STEP_ID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , PrmGCO_ALLOY_ID         GCO_ALLOY.GCO_ALLOY_ID%type
  )
    return FAL_WEIGH.FWE_WEIGHT%type
  is
    -- Curseurs
    cursor CUR_FWE_WEIGHT(
      aFAL_SCHEDULE_STEP_ID          FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
    , aPrevious_FAL_SCHEDULE_STEP_ID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
    )
    is
      select sum(nvl(FWE.FWE_WEIGHT_MAT, 0) ) FWE_WEIGHT
        from FAL_WEIGH FWE
       where FWE.FWE_IN = 1
         and FWE_WASTE = 0
         and FWE_TURNINGS = 0
         and FWE.FAL_LOT_ID = PrmFAL_LOT_ID
         and FWE.GCO_ALLOY_ID = PrmGCO_ALLOY_ID
         and (    (    FWE.FAL_SCHEDULE_STEP_ID = aFAL_SCHEDULE_STEP_ID
                   and C_WEIGH_TYPE = '1')   -- Sortie composants sur l'op�ration
              or (    FWE.FAL_SCHEDULE_STEP_ID = aPrevious_FAL_SCHEDULE_STEP_ID
                  and C_WEIGH_TYPE <> '1')
             );

    cursor CUR_FWE_WEIGHT_HIST(
      aFAL_SCHEDULE_STEP_ID          FAL_TASK_LINK_HIST.FAL_SCHEDULE_STEP_ID%type
    , aPrevious_FAL_SCHEDULE_STEP_ID FAL_TASK_LINK_HIST.FAL_SCHEDULE_STEP_ID%type
    )
    is
      select sum(nvl(FWE.FWE_WEIGHT_MAT, 0) ) FWE_WEIGHT
        from FAL_WEIGH FWE
       where FWE.FWE_IN = 1
         and FWE_WASTE = 0
         and FWE_TURNINGS = 0
         and FWE.FAL_LOT_HIST_ID = PrmFAL_LOT_ID
         and FWE.GCO_ALLOY_ID = PrmGCO_ALLOY_ID
         and (    (    FWE.FAL_FAL_SCHEDULE_STEP_ID = aFAL_SCHEDULE_STEP_ID
                   and C_WEIGH_TYPE = '1')   -- Sortie composants sur l'op�ration
              or (    FWE.FAL_FAL_SCHEDULE_STEP_ID = aPrevious_FAL_SCHEDULE_STEP_ID
                  and C_WEIGH_TYPE <> '1')
             );

    CurFweWeight                  CUR_FWE_WEIGHT%rowtype;
    CurFweWeightHist              CUR_FWE_WEIGHT_HIST%rowtype;
    VarFWE_WEIGHT                 number;
    Previous_FAL_SCHEDULE_STEP_ID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
  begin
    VarFWE_WEIGHT                  := 0;
    Previous_FAL_SCHEDULE_STEP_ID  := 0;
    -- On r�cup�re l'ID de l'op�ration pr�c�dente.
    Previous_FAL_SCHEDULE_STEP_ID  := GET_PREVIOUS_FAL_TASK_LINK_ID(PrmFAL_LOT_ID, PrmFAL_SCHEDULE_STEP_ID);

    open CUR_FWE_WEIGHT(PrmFAL_SCHEDULE_STEP_ID, Previous_FAL_SCHEDULE_STEP_ID);

    fetch CUR_FWE_WEIGHT
     into CurFweWeight;

    if CUR_FWE_WEIGHT%found then
      VarFWE_WEIGHT  := CurFweWeight.FWE_WEIGHT;
    else
      -- Recherche sur les lots et liens t�ches histori�s
      VarFWE_WEIGHT                  := 0;
      Previous_FAL_SCHEDULE_STEP_ID  := 0;
      Previous_FAL_SCHEDULE_STEP_ID  := GET_PREV_FAL_TASK_LINK_HIST_ID(PrmFAL_LOT_ID, PrmFAL_SCHEDULE_STEP_ID);

      open CUR_FWE_WEIGHT_HIST(PrmFAL_SCHEDULE_STEP_ID, Previous_FAL_SCHEDULE_STEP_ID);

      fetch CUR_FWE_WEIGHT_HIST
       into CurFweWeightHist;

      if CUR_FWE_WEIGHT_HIST%found then
        VarFWE_WEIGHT  := CurFweWeightHist.FWE_WEIGHT;
      else
        VarFWE_WEIGHT  := 0;
      end if;

      close CUR_FWE_WEIGHT_HIST;
    end if;

    close CUR_FWE_WEIGHT;

    return VarFWE_WEIGHT;
  end GET_ENTRY_WEIGHT;

  /**
  * function GET_WEIGHED_QTY
  * Description : Fonction qui renvoie la quantit� pes�e pour un composant de lot de fabrication.
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFAL_LOT_ID               Lot
  * @param   aFAL_LOT_MATERIAL_LINK_ID Composant
  * @param   aGCO_ALLOY_ID             Alliage
  * @param   aLOM_SESSION              Session oracle
  * @param   aSTM_STOCK_ID             Stock
  * @param   aForReplacement           cas du remplacement de composants
  */
  function GET_WEIGHED_QTY(
    aFAL_LOT_ID               number
  , aFAL_LOT_MATERIAL_LINK_ID number
  , aGCO_ALLOY_ID             number
  , aLOM_SESSION              varchar2
  , aSTM_STOCK_ID             number
  , aForReplacement           integer default 0
  )
    return number
  is
    nWeighedQty number;
  begin
    select sum(FWE.FWE_PIECE_QTY)
      into nWeighedQty
      from FAL_WEIGH FWE
         , FAL_POSITION FPO1
         , FAL_POSITION FPO2
     where FWE.FAL_LOT_ID = aFAL_LOT_ID
       and FWE.FAL_LOT_MATERIAL_LINK_ID = aFAL_LOT_MATERIAL_LINK_ID
       and FWE.GCO_ALLOY_ID = aGCO_ALLOY_ID
       and FWE.FWE_SESSION = aLOM_SESSION
       and FWE.FAL_POSITION1_ID = FPO1.FAL_POSITION_ID(+)
       and FWE.FAL_POSITION2_ID = FPO2.FAL_POSITION_ID(+)
       and (   FPO1.STM_STOCK_ID = aSTM_STOCK_ID
            or FPO2.STM_STOCK_ID = aSTM_STOCK_ID)
       and (   aForReplacement = 0
            or (    aForReplacement = 1
                and FWE_IN = 0) );

    return nvl(nWeighedQty, 0);
  exception
    when no_data_found then
      return 0;
  end;

  /**
  * Description
  *    Indique si des pes�es doivent �tre faites pour les composants dont des mouvements sont en cours.
  *    Pes�e � faire si la config FAL_MVT_WEIGHING_MODE > 0, des quantit�s sont saisies sur les composants temporaires et
  *    et le composant est g�r� en mati�re pr�cieuse avec alliage en pes�e r�elle.
  */
  function MustDoWeighing(aSessionID varchar2, iCheckOnlyDerivate integer default 0, iCheckOnLaunchByReleaseCode integer default 0)
    return integer
  is
    iCount integer;
  begin
    if cMvtWeighingMode = 0 then
      return wtWeighingNone;
    else
      select count(*)
        into iCount
        from GCO_PRECIOUS_MAT GPM
           , FAL_LOT_MAT_LINK_TMP LOM
           , FAL_COMPONENT_LINK FCL
           , GCO_GOOD GOOD
           , FAL_LOT LOT
       where LOM.LOM_SESSION = aSessionID
         and LOM.GCO_GOOD_ID = GPM.GCO_GOOD_ID
         and LOM.FAL_LOT_MAT_LINK_TMP_ID = FCL.FAL_LOT_MAT_LINK_TMP_ID
         and LOM.GCO_GOOD_ID = GOOD.GCO_GOOD_ID
         and LOM.FAL_LOT_ID = LOT.FAL_LOT_ID
         and (   iCheckOnlyDerivate = 0
              or LOM.C_KIND_COM = '2')
         and nvl(GOOD.GOO_PRECIOUS_MAT, 0) = 1
         and GPM.GPM_WEIGHT = 1
         and GPM.GPM_REAL_WEIGHT = 1
         and nvl(LOT.C_FAB_TYPE, '0') <> '4'   -- PAS DE LOT DE SOUS TRAITANCE (gestion MP g�r� lors du transfert de stock dans stock du sous-traitant)
         and (   FCL.FCL_HOLD_QTY > 0
              or FCL.FCL_RETURN_QTY > 0
              or FCL.FCL_TRASH_QTY > 0)
         and (   iCheckOnLaunchByReleaseCode = 0
              or (    iCheckOnLaunchByReleaseCode = 1
                  and LOM.C_DISCHARGE_COM in('1', '5') ) )
         and (   cMvtWeighingMode = 1
              or cMvtWeighingMode = 2
              or (    cMvtWeighingMode = 3
                  and LOM.LOM_WEIGHING_MANDATORY = 1) );

      if iCount > 0 then
        if cMvtWeighingMode = 1 then
          return wtWeighingOptional;
        else
          return wtWeighingMandatory;
        end if;
      else
        return wtWeighingNone;
      end if;
    end if;
  exception
    when others then
      return 0;
  end;

  /**
  * function DeleteSessionWeighing
  * Description : Suppression des pes�es pour une session , composants donn�s.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSessionID : Session oracle.
  * @param   aFAL_LOT_MATERIAL_LINK_ID : Composant
  * @param   aFAL_POSITION1_ID : Poste Entrant
  * @param   aFAL_POSITION2_ID : Poste Sortant
  */
  procedure DeleteSessionWeighing(
    aSessionID                varchar2
  , aFAL_LOT_MATERIAL_LINK_ID number default null
  , aFAL_POSITION1_ID         number default null
  , aFAL_POSITION2_ID         number default null
  )
  is
  begin
    delete from FAL_WEIGH
          where FWE_SESSION = aSessionID
            and (   nvl(aFAL_LOT_MATERIAL_LINK_ID, 0) = 0
                 or FAL_LOT_MATERIAL_LINK_ID = aFAL_LOT_MATERIAL_LINK_ID)
            and (    (   nvl(aFAL_POSITION1_ID, 0) = 0
                      or FAL_POSITION1_ID = aFAL_POSITION1_ID)
                 or (   nvl(aFAL_POSITION2_ID, 0) = 0
                     or FAL_POSITION2_ID = aFAL_POSITION2_ID)
                );
  end;

  /**
  * function SetSessionWeighingToNull
  * Description : Mise � null de l'identifiant de session sur les pes�es
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSessionID : Session oracle.
  */
  procedure SetSessionWeighingToNull(aSessionID varchar2)
  is
  begin
    update FAL_WEIGH
       set FWE_SESSION = null
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FWE_SESSION = aSessionID;
  end;

  /**
  * Procedure CheckMovementsWeighing
  * Description
  *    V�rification des pes�es effectu�es pour les mouvements de composants en cours.
  */
  procedure CheckMovementsWeighing(
    aSessionID                  in     varchar2
  , aResult                     in out integer
  , aErrorMsg                   in out varchar2
  , iCheckOnlyDerivate                 integer default 0
  , iCheckOnLaunchByReleaseCode        integer default 0
  )
  is
    cursor CUR_CHECK_MOVEMENT_WEIGHING
    is
      select GCO.GOO_MAJOR_REFERENCE
           , (nvl(FCL.FCL_HOLD_QTY, 0) + nvl(FCL.FCL_RETURN_QTY, 0) + nvl(FCL.FCL_TRASH_QTY, 0) ) QTY_TO_WEIGH
           , (select nvl(sum(FWE_PIECE_QTY), 0)
                from FAL_WEIGH FWE
               where FWE.FAL_LOT_ID = LOM.FAL_LOT_ID
                 and FWE.FAL_LOT_MATERIAL_LINK_ID = LOM.FAL_LOT_MATERIAL_LINK_ID
                 and FWE.GCO_ALLOY_ID = GPM.GCO_ALLOY_ID
                 and FWE_IN = 1
                 and FWE_SESSION = aSessionID) WEIGHED_QTY
        from GCO_PRECIOUS_MAT GPM
           , FAL_LOT_MAT_LINK_TMP LOM
           , GCO_GOOD GCO
           , FAL_LOT LOT
           , (select   FAL_LOT_MAT_LINK_TMP_ID
                     , sum(FCL_HOLD_QTY) FCL_HOLD_QTY
                     , sum(FCL_RETURN_QTY) FCL_RETURN_QTY
                     , sum(FCL_TRASH_QTY) FCL_TRASH_QTY
                  from FAL_COMPONENT_LINK
                 where FCL_SESSION = aSessionID
              group by FAL_LOT_MAT_LINK_TMP_ID) FCL
       where LOM.LOM_SESSION = aSessionID
         and LOM.GCO_GOOD_ID = GPM.GCO_GOOD_ID
         and LOM.GCO_GOOD_ID = GCO.GCO_GOOD_ID
         and LOM.FAL_LOT_MAT_LINK_TMP_ID = FCL.FAL_LOT_MAT_LINK_TMP_ID
         and LOM.FAL_LOT_ID = LOT.FAL_LOT_ID
         and nvl(LOT.C_FAB_TYPE, '0') <> '4'   -- PAS DE LOT DE SOUS TRAITANCE (gestion MP g�r� lors du transfert de stock dans stock du sous-traitant)
         and (   iCheckOnlyDerivate = 0
              or LOM.C_KIND_COM = '2')
         and GPM.GPM_WEIGHT = 1
         and GPM.GPM_REAL_WEIGHT = 1
         and GCO.GOO_PRECIOUS_MAT = 1
         and (   iCheckOnLaunchByReleaseCode = 0
              or (    iCheckOnLaunchByReleaseCode = 1
                  and LOM.C_DISCHARGE_COM in('1', '5') ) )
         and (   cMvtWeighingMode = 1
              or cMvtWeighingMode = 2
              or (    cMvtWeighingMode = 3
                  and LOM.LOM_WEIGHING_MANDATORY = 1) )
         and (nvl(FCL.FCL_HOLD_QTY, 0) + nvl(FCL.FCL_RETURN_QTY, 0) + nvl(FCL.FCL_TRASH_QTY, 0) ) <>
               (select nvl(sum(FWE_PIECE_QTY), 0)
                  from FAL_WEIGH FWE
                 where FWE.FAL_LOT_ID = LOM.FAL_LOT_ID
                   and FWE.FAL_LOT_MATERIAL_LINK_ID = LOM.FAL_LOT_MATERIAL_LINK_ID
                   and FWE.GCO_ALLOY_ID = GPM.GCO_ALLOY_ID
                   and FWE_IN = 1
                   and FWE_SESSION = aSessionID);

    CurCheckMovementWeighing CUR_CHECK_MOVEMENT_WEIGHING%rowtype;
  begin
    if cMvtWeighingMode = 0 then
      aResult  := wtWeighingNone;
    else
      for CurCheckMovementWeighing in CUR_CHECK_MOVEMENT_WEIGHING loop
        if cMvtWeighingMode = 1 then
          aResult  := wtWeighingOptional;
        else
          aResult  := wtWeighingMandatory;
        end if;

        aErrorMsg  :=
          aErrorMsg ||
          '   . ' ||
          PCS.PC_FUNCTIONS.TranslateWord('Composant') ||
          ' : ' ||
          CurCheckMovementWeighing.GOO_MAJOR_REFERENCE ||
          ' - ' ||
          PCS.PC_FUNCTIONS.TranslateWord('Qt� mouvement') ||
          ' = ' ||
          CurCheckMovementWeighing.QTY_TO_WEIGH ||
          ' - ' ||
          PCS.PC_FUNCTIONS.TranslateWord('Qt� pes�e') ||
          ' = ' ||
          CurCheckMovementWeighing.WEIGHED_QTY ||
          chr(13);
      end loop;
    end if;
  exception
    when others then
      aResult  := wtWeighingNone;
  end;
end FAL_WEIGH_FUNCTION;
