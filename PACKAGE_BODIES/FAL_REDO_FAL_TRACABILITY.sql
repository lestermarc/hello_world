--------------------------------------------------------
--  DDL for Package Body FAL_REDO_FAL_TRACABILITY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_REDO_FAL_TRACABILITY" 
is
  procedure REDO_FAL_TRACABILITY
  is
    -- parcours de la table FAL_LOT_HIST
    cursor CHist
    is
      select *
        from FAL_LOT_HIST
       where FAL_LOT_HIST_ID not in(select FAL_LOT_ID
                                      from FAL_TRACABILITY);

    -- parcours de la table STM_STOCk_MOVEMENT (020 ENT FAC) pour chaque FAL_LOT_HIST_ID
    cursor CMovement020ENTFAC(PrmLOT_REFCOMPL varchar)
    is
      select A.*
        from STM_STOCK_MOVEMENT A
           , STM_MOVEMENT_KIND B
       where A.STM_MOVEMENT_KIND_ID = B.STM_MOVEMENT_KIND_ID
         and C_MOVEMENT_CODE = '020'
         and C_MOVEMENT_SORT = 'ENT'
         and C_MOVEMENT_TYPE = 'FAC'
         and SMO_WORDING = PrmLOT_REFCOMPL
         and GCO_CHARACTERIZATION_ID is not null;

    -- parcours de la table STM_STOCk_MOVEMENT (017 SOR FAC) pour chaque FAL_LOT_HIST_ID
    cursor CMovement017SORFAC(PrmLOT_REFCOMPL varchar)
    is
      select A.*
        from STM_STOCK_MOVEMENT A
           , STM_MOVEMENT_KIND B
       where A.STM_MOVEMENT_KIND_ID = B.STM_MOVEMENT_KIND_ID
         and C_MOVEMENT_CODE = '017'
         and C_MOVEMENT_SORT = 'SOR'
         and C_MOVEMENT_TYPE = 'FAC'
         and SMO_WORDING = PrmLOT_REFCOMPL
         and GCO_CHARACTERIZATION_ID is not null;

    EMovement020ENTFAC      STM_STOCk_MOVEMENT%rowtype;
    EMovement017SORFAC      STM_STOCk_MOVEMENT%rowtype;
    EHist                   FAL_LOT_HIST%rowtype;
    -- Variable pour l'écriture du FAL_TRACABILITY
    aFAL_LOT_ID             FAL_TRACABILITY.FAL_LOT_ID%type;
    aGCO_GOOD_ID            FAL_TRACABILITY.GCO_GOOD_ID%type;   -- 1
    aGCO_GCO_GOOD_ID        FAL_TRACABILITY.GCO_GCO_GOOD_ID%type;   -- 2
    aHIS_PLAN_VERSION       FAL_TRACABILITY.HIS_PLAn_VERSION%type;   -- 3
    aHIS_PLAN_NUMBER        FAL_TRACABILITY.HIS_PLAN_NUMBER%type;   -- 4
    aHIS_PT_PIECE           FAL_TRACABILITY.HIS_PT_PIECE%type;   -- 5
    aHIS_PT_LOT             FAL_TRACABILITY.HIS_PT_LOT%type;   -- 6
    aHIS_PT_VERSION         FAL_TRACABILITY.HIS_PT_VERSION%type;   -- 7
    aHIS_CHRONOLOGY_PT      FAL_TRACABILITY.HIS_CHRONOLOGY_PT%type;   -- 8
    aHIS_PT_STD_CHAR_1      FAL_TRACABILITY.HIS_PT_STD_CHAR_1%type;
    aHIS_PT_STD_CHAR_2      FAL_TRACABILITY.HIS_PT_STD_CHAR_2%type;
    aHIS_PT_STD_CHAR_3      FAL_TRACABILITY.HIS_PT_STD_CHAR_3%type;
    aHIS_PT_STD_CHAR_4      FAL_TRACABILITY.HIS_PT_STD_CHAR_4%type;
    aHIS_PT_STD_CHAR_5      FAL_TRACABILITY.HIS_PT_STD_CHAR_5%type;
    aHIS_CPT_PIECE          FAL_TRACABILITY.HIS_CPT_PIECE%type;   -- 9
    aHIS_CPT_LOT            FAL_TRACABILITY.HIS_CPT_LOT%type;   -- 0
    aHIS_CPT_VERSION        FAL_TRACABILITY.HIS_CPT_VERSION%type;   -- 1
    aHIS_CHRONOLOGY_CPT     FAL_TRACABILITY.HIS_CHRONOLOGY_CPT%type;   -- 2
    aHIS_CPT_STD_CHAR_1     FAL_TRACABILITY.HIS_CPT_STD_CHAR_1%type;
    aHIS_CPT_STD_CHAR_2     FAL_TRACABILITY.HIS_CPT_STD_CHAR_2%type;
    aHIS_CPT_STD_CHAR_3     FAL_TRACABILITY.HIS_CPT_STD_CHAR_3%type;
    aHIS_CPT_STD_CHAR_4     FAL_TRACABILITY.HIS_CPT_STD_CHAR_4%type;
    aHIS_CPT_STD_CHAR_5     FAL_TRACABILITY.HIS_CPT_STD_CHAR_5%type;
    aHIS_VERSION_ORIGIN_NUM FAL_TRACABILITY.HIS_VERSION_ORIGIN_NUM%type;   -- 13
  begin
    -- Boucle sur les FAL_LOT_HIST
    open CHist;

    loop
      fetch CHIST
       into eHIST;

      exit when CHist%notfound;
      DBMS_OUTPUT.put_line('Traite un lot hist ' || eHIST.LOT_REFCOMPL);

      -- Boucle sur les Mouvements 020 ENT FAC
      open CMovement020ENTFAC(eHIST.LOT_REFCOMPL);

      loop
        fetch CMovement020ENTFAC
         into EMovement020ENTFAC;

        exit when CMovement020ENTFAC%notfound;
        DBMS_OUTPUT.put_line('Traite un mouvement');

        -- Boucle sur les Mouvements 017 SOR FAC
        open CMovement017SORFAC(eHIST.LOT_REFCOMPL);

        loop
          fetch CMovement017SORFAC
           into EMovement017SORFAC;

          exit when CMovement017SORFAC%notfound;
----------------------------------------------------------------------------------------------------------
-- Création du FAL_TRACABILITY
          aFAL_LOT_ID              := eHist.FAL_LOT_HIST_ID;
          aGCO_GOOD_ID             := EMovement020ENTFAC.GCO_GOOD_ID;
          aGCO_GCO_GOOD_ID         := EMovement017SORFAC.GCO_GOOD_ID;
          aHIS_PLAN_VERSION        := eHIST.LOT_PLAN_VERSION;
          aHIS_PLAN_NUMBER         := eHIST.LOT_PLAN_NUMBER;
          aHIS_VERSION_ORIGIN_NUM  := eHIST.LOT_VERSION_ORIGIN_NUM;

          if EMovement020ENTFAC.GCO_CHARACTERIZATION_ID is not null then
            -- Mise à jour des champs dénormalisé d'affichage des caractérisations
            GCO_FUNCTIONS.ClassifyCharacterizations(EMovement020ENTFAC.GCO_CHARACTERIZATION_ID
                                                  , EMovement020ENTFAC.GCO_GCO_CHARACTERIZATION_ID
                                                  , EMovement020ENTFAC.GCO2_GCO_CHARACTERIZATION_ID
                                                  , EMovement020ENTFAC.GCO3_GCO_CHARACTERIZATION_ID
                                                  , EMovement020ENTFAC.GCO4_GCO_CHARACTERIZATION_ID
                                                  , EMovement020ENTFAC.SMO_CHARACTERIZATION_VALUE_1
                                                  , EMovement020ENTFAC.SMO_CHARACTERIZATION_VALUE_2
                                                  , EMovement020ENTFAC.SMO_CHARACTERIZATION_VALUE_3
                                                  , EMovement020ENTFAC.SMO_CHARACTERIZATION_VALUE_4
                                                  , EMovement020ENTFAC.SMO_CHARACTERIZATION_VALUE_5
                                                  , aHIS_PT_PIECE
                                                  , aHIS_PT_LOT
                                                  , aHIS_PT_VERSION
                                                  , aHIS_CHRONOLOGY_PT
                                                  , aHIS_PT_STD_CHAR_1
                                                  , aHIS_PT_STD_CHAR_2
                                                  , aHIS_PT_STD_CHAR_3
                                                  , aHIS_PT_STD_CHAR_4
                                                  , aHIS_PT_STD_CHAR_5
                                                   );
          end if;

          if EMovement017SORFAC.GCO_CHARACTERIZATION_ID is not null then
            GCO_FUNCTIONS.ClassifyCharacterizations(EMovement017SORFAC.GCO_CHARACTERIZATION_ID
                                                  , EMovement017SORFAC.GCO_GCO_CHARACTERIZATION_ID
                                                  , EMovement017SORFAC.GCO2_GCO_CHARACTERIZATION_ID
                                                  , EMovement017SORFAC.GCO3_GCO_CHARACTERIZATION_ID
                                                  , EMovement017SORFAC.GCO4_GCO_CHARACTERIZATION_ID
                                                  , EMovement017SORFAC.SMO_CHARACTERIZATION_VALUE_1
                                                  , EMovement017SORFAC.SMO_CHARACTERIZATION_VALUE_2
                                                  , EMovement017SORFAC.SMO_CHARACTERIZATION_VALUE_3
                                                  , EMovement017SORFAC.SMO_CHARACTERIZATION_VALUE_4
                                                  , EMovement017SORFAC.SMO_CHARACTERIZATION_VALUE_5
                                                  , aHIS_CPT_PIECE
                                                  , aHIS_CPT_LOT
                                                  , aHIS_CPT_VERSION
                                                  , aHIS_CHRONOLOGY_CPT
                                                  , aHIS_CPT_STD_CHAR_1
                                                  , aHIS_CPT_STD_CHAR_2
                                                  , aHIS_CPT_STD_CHAR_3
                                                  , aHIS_CPT_STD_CHAR_4
                                                  , aHIS_CPT_STD_CHAR_5
                                                   );
          end if;

          insert into FAL_TRACABILITY
                      (FAL_TRACABILITY_ID
                     , FAl_LOT_ID
                     , GCO_GOOD_ID
                     , GCO_GCO_GOOD_ID
                     , HIS_PLAN_VERSION
                     , HIS_PLAN_NUMBER
                     , HIS_PT_PIECE
                     , HIS_PT_LOT
                     , HIS_PT_VERSION
                     , HIS_CHRONOLOGY_PT
                     , HIS_PT_STD_CHAR_1
                     , HIS_PT_STD_CHAR_2
                     , HIS_PT_STD_CHAR_3
                     , HIS_PT_STD_CHAR_4
                     , HIS_PT_STD_CHAR_5
                     , HIS_CPT_PIECE
                     , HIS_CPT_LOT
                     , HIS_CPT_VERSION
                     , HIS_CHRONOLOGY_CPT
                     , HIS_CPT_STD_CHAR_1
                     , HIS_CPT_STD_CHAR_2
                     , HIS_CPT_STD_CHAR_3
                     , HIS_CPT_STD_CHAR_4
                     , HIS_CPT_STD_CHAR_5
                     , HIS_VERSION_ORIGIN_NUM
                     , A_DATECRE
                     , A_IDCRE
                     , HIS_LOT_REFCOMPL
                      )
               values (GetNewId
                     , aFAL_LOT_ID
                     , aGCO_GOOD_ID
                     , aGCO_GCO_GOOD_ID
                     , aHIS_PLAN_VERSION
                     , aHIS_PLAN_NUMBER
                     , aHIS_PT_PIECE
                     , aHIS_PT_LOT
                     , aHIS_PT_VERSION
                     , aHIS_CHRONOLOGY_PT
                     , aHIS_PT_STD_CHAR_1
                     , aHIS_PT_STD_CHAR_2
                     , aHIS_PT_STD_CHAR_3
                     , aHIS_PT_STD_CHAR_4
                     , aHIS_PT_STD_CHAR_5
                     , aHIS_CPT_PIECE
                     , aHIS_CPT_LOT
                     , aHIS_CPT_VERSION
                     , aHIS_CHRONOLOGY_CPT
                     , aHIS_CPT_STD_CHAR_1
                     , aHIS_CPT_STD_CHAR_2
                     , aHIS_CPT_STD_CHAR_3
                     , aHIS_CPT_STD_CHAR_4
                     , aHIS_CPT_STD_CHAR_5
                     , aHIS_VERSION_ORIGIN_NUM
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                     , eHIST.LOT_REFCOMPL
                      );
-- Fin de création du FAL_TRACABILITY
----------------------------------------------------------------------------------------------------------
        end loop;

        close CMovement017SORFAC;
      end loop;

      close CMovement020ENTFAC;
    end loop;

    close CHist;
  end;
end;   -- Fin du Package
