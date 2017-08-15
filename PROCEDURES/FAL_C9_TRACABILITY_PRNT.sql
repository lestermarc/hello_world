--------------------------------------------------------
--  DDL for Procedure FAL_C9_TRACABILITY_PRNT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "FAL_C9_TRACABILITY_PRNT" (
  aRefCursor   in out Crystal_Cursor_Types.DualCursorTyp
, PARAMETER_0  in     GCO_GOOD.GOO_MAJOR_REFERENCE%type   -- Produit de ... (* si tous)
, PARAMETER_1  in     GCO_GOOD.GOO_MAJOR_REFERENCE%type   -- Produit à ... (* si tous)
, PARAMETER_2  in     FAL_TRACABILITY.HIS_PT_LOT%type   -- Lot de ... (* si tous)
, PARAMETER_3  in     FAL_TRACABILITY.HIS_PT_LOT%type   -- Lot à ... (* si tous)
, PARAMETER_4  in     FAL_TRACABILITY.HIS_PT_PIECE%type   -- Pièce de ... (* si tous)
, PARAMETER_5  in     FAL_TRACABILITY.HIS_PT_PIECE%type   -- Pièce à... (* si tous)
, PARAMETER_9  in     FAL_TRACABILITY.HIS_PT_VERSION%type   -- Version de ... (* si tous)
, PARAMETER_10 in     FAL_TRACABILITY.HIS_PT_VERSION%type   -- Version à... (* si tous)
, PARAMETER_11 in     FAL_TRACABILITY.HIS_CHRONOLOGY_PT%type   -- Chrono de ... (* si tous)
, PARAMETER_12 in     FAL_TRACABILITY.HIS_CHRONOLOGY_PT%type   -- Chrono à... (* si tous)
, PARAMETER_6  in     number   -- Profondeur de nomenclature visible souhaitée (=-1 si profondeur infinie)
, PARAMETER_7  in     integer   -- Voir tous les composants (1=Oui 2=Non)
, PARAMETER_8  in     PCS.PC_LANG.PC_LANG_ID%type   -- Langue de l'utilisateur
)
is
  /* Curseurs de sélection des informations à imprimer */
  -- Sélection des produits
  cursor CUR_GCO_GOOD_SELECTION
  is
    select distinct GOOD.GCO_GOOD_ID
                  , GOOD.GOO_MAJOR_REFERENCE
                  , GOOD.GOO_SECONDARY_REFERENCE
               from GCO_GOOD GOOD
              where (   PARAMETER_0 = '*'
                     or GOOD.GOO_MAJOR_REFERENCE >= PARAMETER_0)
                and (   PARAMETER_1 = '*'
                     or GOOD.GOO_MAJOR_REFERENCE <= PARAMETER_1)
                and exists(select 1
                             from GCO_CHARACTERIZATION
                            where GCO_GOOD_ID = GOOD.GCO_GOOD_ID)
                and (   PARAMETER_2 = '*'
                     or GCO_GOOD_ID in(select GCO_GOOD_ID
                                         from STM_ELEMENT_NUMBER
                                        where C_ELEMENT_TYPE = '01'
                                          and SEM_VALUE >= PARAMETER_2) )
                and (   PARAMETER_3 = '*'
                     or GCO_GOOD_ID in(select GCO_GOOD_ID
                                         from STM_ELEMENT_NUMBER
                                        where C_ELEMENT_TYPE = '01'
                                          and SEM_VALUE <= PARAMETER_3) )
                and (   PARAMETER_4 = '*'
                     or GCO_GOOD_ID in(select GCO_GOOD_ID
                                         from STM_ELEMENT_NUMBER
                                        where C_ELEMENT_TYPE = '02'
                                          and SEM_VALUE >= PARAMETER_4) )
                and (   PARAMETER_5 = '*'
                     or GCO_GOOD_ID in(select GCO_GOOD_ID
                                         from STM_ELEMENT_NUMBER
                                        where C_ELEMENT_TYPE = '02'
                                          and SEM_VALUE <= PARAMETER_5) )
                and (   PARAMETER_9 = '*'
                     or GCO_GOOD_ID in(select GCO_GOOD_ID
                                         from STM_ELEMENT_NUMBER
                                        where C_ELEMENT_TYPE = '03'
                                          and SEM_VALUE >= PARAMETER_9) )
                and (   PARAMETER_10 = '*'
                     or GCO_GOOD_ID in(select GCO_GOOD_ID
                                         from STM_ELEMENT_NUMBER
                                        where C_ELEMENT_TYPE = '03'
                                          and SEM_VALUE <= PARAMETER_10) )
                and (   PARAMETER_11 = '*'
                     or GCO_GOOD_ID in(select GCO_GOOD_ID
                                         from STM_STOCK_POSITION
                                        where SPO_CHRONOLOGICAL >= PARAMETER_11) )
                and (   PARAMETER_12 = '*'
                     or GCO_GOOD_ID in(select GCO_GOOD_ID
                                         from STM_STOCK_POSITION
                                        where SPO_CHRONOLOGICAL <= PARAMETER_12) )
                and (    (exists(select GCO_CHARACTERIZATION_ID
                                   from GCO_CHARACTERIZATION
                                  where GCO_GOOD_ID = GOOD.GCO_GOOD_ID
                                    and C_CHARACT_TYPE = '3'
                                    and CHA_STOCK_MANAGEMENT = 1) )
                     or (exists(select GCO_CHARACTERIZATION_ID
                                  from GCO_CHARACTERIZATION
                                 where GCO_GOOD_ID = GOOD.GCO_GOOD_ID
                                   and C_CHARACT_TYPE = '4'
                                   and CHA_STOCK_MANAGEMENT = 1) )
                     or (exists(select GCO_CHARACTERIZATION_ID
                                  from GCO_CHARACTERIZATION
                                 where GCO_GOOD_ID = GOOD.GCO_GOOD_ID
                                   and C_CHARACT_TYPE = '1'
                                   and CHA_STOCK_MANAGEMENT = 1) )
                     or (exists(select GCO_CHARACTERIZATION_ID
                                  from GCO_CHARACTERIZATION
                                 where GCO_GOOD_ID = GOOD.GCO_GOOD_ID
                                   and C_CHARACT_TYPE = '5'
                                   and CHA_STOCK_MANAGEMENT = 1) )
                    )
           order by GOOD.GOO_MAJOR_REFERENCE;

  -- Sélection des lots et pièces concernées
  cursor CUR_FAL_LOT_OR_PIECE_SELECTION(aGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type)
  is
    select   min(GCO_GOOD_ID)
           , SEM_VALUE
           , 'LOT' as CHARACTERIZATION
        from STM_ELEMENT_NUMBER
       where (    C_ELEMENT_TYPE = '01'
              and (   PARAMETER_2 = '*'
                   or SEM_VALUE >= PARAMETER_2)
              and (   PARAMETER_3 = '*'
                   or SEM_VALUE <= PARAMETER_3)
              and (GCO_GOOD_ID = aGCO_GOOD_ID)
             )
    group by SEM_VALUE
    union
    select   min(GCO_GOOD_ID)
           , SEM_VALUE
           , 'PIECE' as CHARACTERIZATION
        from STM_ELEMENT_NUMBER
       where C_ELEMENT_TYPE = '02'
         and (   PARAMETER_4 = '*'
              or SEM_VALUE >= PARAMETER_4)
         and (   PARAMETER_5 = '*'
              or SEM_VALUE <= PARAMETER_5)
         and (GCO_GOOD_ID = aGCO_GOOD_ID)
    group by SEM_VALUE
    union
    select   min(GCO_GOOD_ID)
           , SEM_VALUE
           , 'VERSION' as CHARACTERIZATION
        from STM_ELEMENT_NUMBER
       where C_ELEMENT_TYPE = '03'
         and (   PARAMETER_9 = '*'
              or SEM_VALUE >= PARAMETER_9)
         and (   PARAMETER_10 = '*'
              or SEM_VALUE <= PARAMETER_10)
         and (GCO_GOOD_ID = aGCO_GOOD_ID)
    group by SEM_VALUE
    union
    select   min(GCO_GOOD_ID)
           , SPO_CHRONOLOGICAL SEM_VALUE
           , 'CHRONO' as CHARACTERIZATION
        from STM_STOCK_POSITION
       where SPO_CHRONOLOGICAL is not null
         and (   PARAMETER_11 = '*'
              or SPO_CHRONOLOGICAL >= PARAMETER_11)
         and (   PARAMETER_12 = '*'
              or SPO_CHRONOLOGICAL <= PARAMETER_12)
         and (GCO_GOOD_ID = aGCO_GOOD_ID)
    group by SPO_CHRONOLOGICAL;

  -- Sélection des lignes racines
  cursor CUR_FAL_TRACABILITY(
    aGoodId  GCO_GOOD.GCO_GOOD_ID%type
  , aPiece   STM_ELEMENT_NUMBER.SEM_VALUE%type
  , aLot     STM_ELEMENT_NUMBER.SEM_VALUE%type
  , aVersion STM_ELEMENT_NUMBER.SEM_VALUE%type
  )
  is
    select distinct TRA.FAL_LOT_ID
                  , TRA.STM_STOCK_MOVEMENT_ID
                  , TRA.ASA_RECORD_ID
                  , max(TRA.A_DATECRE)
                  , sum(TRA.HIS_QTY) TRA_QTY
               from FAL_TRACABILITY TRA
              where TRA.GCO_GOOD_ID = aGoodID
                and (   aPiece is null
                     or TRA.HIS_PT_PIECE = aPiece)
                and (   aLot is null
                     or TRA.HIS_PT_LOT = aLot)
                and (   aVersion is null
                     or TRA.HIS_PT_VERSION = aVersion)
           group by TRA.FAL_LOT_ID
                  , TRA.STM_STOCK_MOVEMENT_ID
                  , ASA_RECORD_ID
           order by max(TRA.A_DATECRE) desc;

  /* Variables */
  CurGcoGoodSelection CUR_GCO_GOOD_SELECTION%rowtype;
  CurFalLotSelection  CUR_FAL_LOT_OR_PIECE_SELECTION%rowtype;
  CurFalTracability   CUR_FAL_TRACABILITY%rowtype;
  sSEM_VALUE_LOT      STM_ELEMENT_NUMBER.SEM_VALUE%type;
  sSEM_VALUE_PIECE    STM_ELEMENT_NUMBER.SEM_VALUE%type;
  sSEM_VALUE_VERSION  STM_ELEMENT_NUMBER.SEM_VALUE%type;
  sSEM_VALUE_CHRONO   STM_STOCK_POSITION.SPO_CHRONOLOGICAL%type;
  iNOMENCLATURE_DEPTH integer;
  nGroupField         number;
  aDateParent         date;
  aLotParent          FAL_LOT.FAL_LOT_ID%type;
  ShowAllComponents   boolean;
begin
  -- Suppression des enregistrements qui pourraient subsister.
  delete from FAL_TRACABILITY_PRNT;

  nGroupField          := 0;
  iNOMENCLATURE_DEPTH  := 0;

  -- Voir ou non tous les composants
  if PARAMETER_7 = 1 then
    ShowAllComponents  := true;
  else
    ShowAllComponents  := false;
  end if;

  if     PARAMETER_0 is not null
     and PARAMETER_1 is not null then
    -- Pour chaque produit de la fourchette de sélection
    for CurGcoGoodSelection in CUR_GCO_GOOD_SELECTION loop
      -- Pour chaque Tuple Produit, Lot, Piece des fourchettes de sélection
      for CurFalLotSelection in CUR_FAL_LOT_OR_PIECE_SELECTION(CurGcoGoodSelection.GCO_GOOD_ID) loop
        -- Pièce et lot
        if CurFalLotSelection.CHARACTERIZATION = 'PIECE' then
          sSEM_VALUE_LOT      := null;
          sSEM_VALUE_PIECE    := CurFalLotSelection.SEM_VALUE;
          sSEM_VALUE_VERSION  := null;
          sSEM_VALUE_CHRONO   := null;
        elsif CurFalLotSelection.CHARACTERIZATION = 'LOT' then
          sSEM_VALUE_LOT      := CurFalLotSelection.SEM_VALUE;
          sSEM_VALUE_PIECE    := null;
          sSEM_VALUE_VERSION  := null;
          sSEM_VALUE_CHRONO   := null;
        elsif CurFalLotSelection.CHARACTERIZATION = 'VERSION' then
          sSEM_VALUE_LOT      := null;
          sSEM_VALUE_PIECE    := null;
          sSEM_VALUE_VERSION  := CurFalLotSelection.SEM_VALUE;
          sSEM_VALUE_CHRONO   := null;
        else
          sSEM_VALUE_LOT      := null;
          sSEM_VALUE_PIECE    := null;
          sSEM_VALUE_VERSION  := null;
          sSEM_VALUE_CHRONO   := CurFalLotSelection.SEM_VALUE;
        end if;

        -- Pour chaque ligne de tracabilité obtenue
        open CUR_FAL_TRACABILITY(CurGcoGoodSelection.GCO_GOOD_ID, sSEM_VALUE_PIECE, sSEM_VALUE_LOT, sSEM_VALUE_VERSION);

        fetch CUR_FAL_TRACABILITY
         into CurFalTracability;

        if CUR_FAL_TRACABILITY%notfound then
          iNOMENCLATURE_DEPTH  := 0;
          Fal_Print_Procs.BUILDTRACABILITY_ROW(nGroupField
                                             , CurGcoGoodSelection.GCO_GOOD_ID   --aGCO_GOOD_ID             IN GCO_GOOD.GCO_GOOD_ID%TYPE
                                             , null   --aGCO_GCO_GOOD_ID         IN GCO_GOOD.GCO_GOOD_ID%TYPE
                                             , null   --aFAL_LOT_ID              IN FAL_LOT.FAL_LOT_ID%TYPE
                                             , null   --aDOC_POSITION_ID         IN FAL_TRACABILITY.DOC_POSITION_ID%TYPE
                                             , iNOMENCLATURE_DEPTH
                                             , null   --aHIS_DMT_NUMBER          IN DOC_DOCUMENT.DMT_NUMBER%TYPE
                                             , sSEM_VALUE_LOT   --aHIS_PT_LOT              IN FAL_TRACABILITY.HIS_PT_LOT%TYPE
                                             , null   --aLOT_REFCOMPL            IN FAL_LOT.LOT_REFCOMPL%TYPE
                                             , sSEM_VALUE_PIECE   --IN FAL_TRACABILITY.HIS_PT_PIECE%TYPE
                                             , sSEM_VALUE_VERSION   --aHIS_PT_VERSION          IN FAL_TRACABILITY.HIS_PT_VERSION%TYPE
                                             , sSEM_VALUE_CHRONO   --aHIS_CHRONOLOGY_PT       IN FAL_TRACABILITY.HIS_CHRONOLOGY_PT%TYPE
                                             , null   --aHIS_PT_STD_CHAR_1       IN FAL_TRACABILITY.HIS_PT_STD_CHAR_1%TYPE
                                             , null   --aHIS_PT_STD_CHAR_2       IN FAL_TRACABILITY.HIS_PT_STD_CHAR_2%TYPE
                                             , null   --aHIS_PT_STD_CHAR_3       IN FAL_TRACABILITY.HIS_PT_STD_CHAR_3%TYPE
                                             , null   --aHIS_PT_STD_CHAR_4       IN FAL_TRACABILITY.HIS_PT_STD_CHAR_4%TYPE
                                             , null   --aHIS_PT_STD_CHAR_5       IN FAL_TRACABILITY.HIS_PT_STD_CHAR_5%TYPE
                                             , null   --aHIS_CPT_PIECE           IN FAL_TRACABILITY.HIS_CPT_PIECE%TYPE
                                             , null   --aHIS_CPT_LOT             IN FAL_TRACABILITY.HIS_CPT_LOT%TYPE
                                             , null   --aHIS_CPT_VERSION         IN FAL_TRACABILITY.HIS_CPT_VERSION%TYPE
                                             , null   --aHIS_CHRONOLOGY_CPT      IN FAL_TRACABILITY.HIS_CHRONOLOGY_CPT%TYPE
                                             , null   --aHIS_CPT_STD_CHAR_1      IN FAL_TRACABILITY.HIS_CPT_STD_CHAR_1%TYPE
                                             , null   --aHIS_CPT_STD_CHAR_2      IN FAL_TRACABILITY.HIS_CPT_STD_CHAR_2%TYPE
                                             , null   --aHIS_CPT_STD_CHAR_3      IN FAL_TRACABILITY.HIS_CPT_STD_CHAR_3%TYPE
                                             , null   --aHIS_CPT_STD_CHAR_4      IN FAL_TRACABILITY.HIS_CPT_STD_CHAR_4%TYPE
                                             , null   --aHIS_CPT_STD_CHAR_5      IN FAL_TRACABILITY.HIS_CPT_STD_CHAR_5%TYPE
                                             , null   --aHIS_PLAN_NUMBER         IN FAL_TRACABILITY.HIS_PLAN_NUMBER%TYPE
                                             , null   --aHIS_PLAN_VERSION        IN FAL_TRACABILITY.HIS_PLAN_VERSION%TYPE
                                             , null   --aHIS_VERSION_ORIGINE_NUM IN FAL_TRACABILITY.HIS_VERSION_ORIGIN_NUM%TYPE
                                             , null   --aMOVEMENT_DATE           IN FAL_HISTO_LOT.A_DATECRE%TYPE
                                             , null   --aMOVEMENT_QTE            IN FAL_HISTO_LOT.HIS_QTE%TYPE
                                             , null   --aEVEN_TYPE_DESCR         IN VARCHAR2
                                             , null   --aCPT_QUANTITY            IN NUMBER DEFAULT 0
                                             , null
                                             , null
                                             , null
                                              );

          -- Ajout de tous les composants
          if ShowAllComponents then
            Fal_Print_Procs.ADDALLCOMPONENTS(nGroupField
                                           , CurFalTracability.FAL_LOT_ID
                                           , CurGcoGoodSelection.GCO_GOOD_ID
                                           , iNOMENCLATURE_DEPTH
                                           , sSEM_VALUE_LOT
                                           , sSEM_VALUE_PIECE
                                           , sSEM_VALUE_VERSION
                                            );
          end if;
        else
          loop
            exit when CUR_FAL_TRACABILITY%notfound;
            nGroupField          := nGroupField + 1;
            iNOMENCLATURE_DEPTH  := 0;
            -- Construction ligne de tracabilité
            Fal_Print_Procs.BUILDTRACABILITY_ROW(nGroupField
                                               , CurGcoGoodSelection.GCO_GOOD_ID   --aGCO_GOOD_ID             IN GCO_GOOD.GCO_GOOD_ID%TYPE
                                               , null   --aGCO_GCO_GOOD_ID         IN GCO_GOOD.GCO_GOOD_ID%TYPE
                                               , CurFalTracability.FAL_LOT_ID   --aFAL_LOT_ID              IN FAL_LOT.FAL_LOT_ID%TYPE
                                               , null
                                               , iNOMENCLATURE_DEPTH
                                               , null   --aHIS_DMT_NUMBER          IN DOC_DOCUMENT.DMT_NUMBER%TYPE
                                               , sSEM_VALUE_LOT   --aHIS_PT_LOT                IN FAL_TRACABILITY.HIS_PT_LOT%TYPE
                                               , null   --aLOT_REFCOMPL            IN FAL_LOT.LOT_REFCOMPL%TYPE
                                               , sSEM_VALUE_PIECE   --aHIS_PT_PIECE            IN FAL_TRACABILITY.HIS_PT_PIECE%TYPE
                                               , sSEM_VALUE_VERSION   --IN FAL_TRACABILITY.HIS_PT_VERSION%TYPE
                                               , sSEM_VALUE_CHRONO   --aHIS_CHRONOLOGY_PT       IN FAL_TRACABILITY.HIS_CHRONOLOGY_PT%TYPE
                                               , null   --aHIS_PT_STD_CHAR_1       IN FAL_TRACABILITY.HIS_PT_STD_CHAR_1%TYPE
                                               , null   --aHIS_PT_STD_CHAR_2       IN FAL_TRACABILITY.HIS_PT_STD_CHAR_2%TYPE
                                               , null   --aHIS_PT_STD_CHAR_3       IN FAL_TRACABILITY.HIS_PT_STD_CHAR_3%TYPE
                                               , null   --aHIS_PT_STD_CHAR_4       IN FAL_TRACABILITY.HIS_PT_STD_CHAR_4%TYPE
                                               , null   --aHIS_PT_STD_CHAR_5       IN FAL_TRACABILITY.HIS_PT_STD_CHAR_5%TYPE
                                               , null   --aHIS_CPT_PIECE           IN FAL_TRACABILITY.HIS_CPT_PIECE%TYPE
                                               , null   --aHIS_CPT_LOT             IN FAL_TRACABILITY.HIS_CPT_LOT%TYPE
                                               , null   --aHIS_CPT_VERSION         IN FAL_TRACABILITY.HIS_CPT_VERSION%TYPE
                                               , null   --aHIS_CHRONOLOGY_CPT      IN FAL_TRACABILITY.HIS_CHRONOLOGY_CPT%TYPE
                                               , null   --aHIS_CPT_STD_CHAR_1      IN FAL_TRACABILITY.HIS_CPT_STD_CHAR_1%TYPE
                                               , null   --aHIS_CPT_STD_CHAR_2      IN FAL_TRACABILITY.HIS_CPT_STD_CHAR_2%TYPE
                                               , null   --aHIS_CPT_STD_CHAR_3      IN FAL_TRACABILITY.HIS_CPT_STD_CHAR_3%TYPE
                                               , null   --aHIS_CPT_STD_CHAR_4      IN FAL_TRACABILITY.HIS_CPT_STD_CHAR_4%TYPE
                                               , null   --aHIS_CPT_STD_CHAR_5      IN FAL_TRACABILITY.HIS_CPT_STD_CHAR_5%TYPE
                                               , null   --aHIS_PLAN_NUMBER         IN FAL_TRACABILITY.HIS_PLAN_NUMBER%TYPE
                                               , null   --aHIS_PLAN_VERSION        IN FAL_TRACABILITY.HIS_PLAN_VERSION%TYPE
                                               , null   --aHIS_VERSION_ORIGINE_NUM IN FAL_TRACABILITY.HIS_VERSION_ORIGIN_NUM%TYPE
                                               , null   --aMOVEMENT_DATE           IN FAL_HISTO_LOT.A_DATECRE%TYPE
                                               , null   --aMOVEMENT_QTE            IN FAL_HISTO_LOT.HIS_QTE%TYPE
                                               , null   --aEVEN_TYPE_DESCR         IN VARCHAR2
                                               , CurFalTracability.TRA_QTY   --aCPT_QUANTITY            IN NUMBER DEFAULT 0
                                               , null
                                               , null
                                               , CurFalTracability.ASA_RECORD_ID
                                                );
            -- Ajout des mouvements de réception
            Fal_Print_Procs.AddReceptionMovement(CurGcoGoodSelection.GCO_GOOD_ID
                                               , sSEM_VALUE_LOT
                                               , sSEM_VALUE_PIECE
                                               , sSEM_VALUE_VERSION
                                               , sSEM_VALUE_CHRONO
                                               , CurFalTracability.FAL_LOT_ID
                                               , CurFalTracability.STM_STOCK_MOVEMENT_ID
                                               , nGroupField
                                                );
            aDateParent          := null;
            aLotParent           := 0;
            -- Parcours des enfants
            iNOMENCLATURE_DEPTH  := iNOMENCLATURE_DEPTH + 1;
            Fal_Print_Procs.BUILDTRACABILITY_DESCENDANT(nGroupField
                                                      , CurGcoGoodSelection.GCO_GOOD_ID
                                                      , sSEM_VALUE_LOT
                                                      , sSEM_VALUE_PIECE
                                                      , sSEM_VALUE_VERSION
                                                      , sSEM_VALUE_CHRONO
                                                      , null
                                                      , null
                                                      , null
                                                      , null
                                                      , null
                                                      , iNomenclature_depth
                                                      , aLotParent
                                                      , aDateParent
                                                      , ShowAllComponents
                                                      , CurFalTracability.FAL_LOT_ID
                                                      , CurFalTracability.STM_STOCK_MOVEMENT_ID
                                                      , CurFalTracability.ASA_RECORD_ID
                                                      , 0
                                                       );

            -- Ajout de tous les composants
            if ShowAllComponents then
              Fal_Print_Procs.ADDALLCOMPONENTS(nGroupField
                                             , CurFalTracability.FAL_LOT_ID
                                             , CurGcoGoodSelection.GCO_GOOD_ID
                                             , iNOMENCLATURE_DEPTH + 1
                                             , sSEM_VALUE_LOT
                                             , sSEM_VALUE_PIECE
                                             , sSEM_VALUE_VERSION
                                              );
            end if;

            -- Si caractérisation de type pièce, et que l'on a plusieurs points d'entrée alors on ne prend que le plus réçent
            -- (Les autres seront compris dans ce plus réçent).
            if    not(sSEM_VALUE_PIECE is null)
               or (sSEM_VALUE_PIECE <> '') then
              exit;
            end if;

            fetch CUR_FAL_TRACABILITY
             into CurFalTracability;
          end loop;
        end if;

        close CUR_FAL_TRACABILITY;
      end loop;
    end loop;
  end if;

  -- Sélection résultat.
  open aRefCursor for
    select *
      from FAL_TRACABILITY_PRNT
     where (   PARAMETER_6 = -1
            or FTP_NOMENCLATURE_DEPTH <= PARAMETER_6);
exception
  when others then
    raise;
end Fal_C9_Tracability_Prnt;
