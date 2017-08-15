--------------------------------------------------------
--  DDL for Package Body FAL_PRINT_PROCS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRINT_PROCS" 
is
  /* Function qui indique si la ligne de trac à déjà été exploitée */
  function UsedTracabilityLine(aFAL_TRACABILITY_ID FAL_TRACABILITY.FAL_TRACABILITY_ID%type, aGROUP_FIELD integer)
    return boolean
  is
    cursor CUR_FAL_TRACABILITY_PRNT
    is
      select FAL_TRACABILITY_PRNT_ID
        from FAL_TRACABILITY_PRNT
       where FAL_TRACABILITY_ID = aFAL_TRACABILITY_ID
         and FTP_GROUP_FIELD = aGROUP_FIELD;

    CurFalTracabilityPrnt CUR_FAL_TRACABILITY_PRNT%rowtype;
  begin
    open CUR_FAL_TRACABILITY_PRNT;

    fetch CUR_FAL_TRACABILITY_PRNT
     into CurFalTracabilityPrnt;

    if CUR_FAL_TRACABILITY_PRNT%found then
      return true;
    else
      return false;
    end if;

    close CUR_FAL_TRACABILITY_PRNT;
  end;

  /* Construction de la tracabilité descendante */
  procedure BUILDTRACABILITY_DESCENDANT(
    aGROUP_FIELD                in number
  , aGCO_GOOD_ID                in GCO_GOOD.GCO_GOOD_ID%type
  , aLot                        in FAL_LOT.LOT_REFCOMPL%type
  , aPiece                      in FAL_TRACABILITY.HIS_PT_PIECE%type
  , aVersion                    in FAL_TRACABILITY.HIS_PT_VERSION%type
  , aChrono                     in FAL_TRACABILITY.HIS_CHRONOLOGY_PT%type
  , aHIS_PT_STD_CHAR_1          in FAL_TRACABILITY.HIS_PT_STD_CHAR_1%type
  , aHIS_PT_STD_CHAR_2          in FAL_TRACABILITY.HIS_PT_STD_CHAR_2%type
  , aHIS_PT_STD_CHAR_3          in FAL_TRACABILITY.HIS_PT_STD_CHAR_3%type
  , aHIS_PT_STD_CHAR_4          in FAL_TRACABILITY.HIS_PT_STD_CHAR_4%type
  , aHIS_PT_STD_CHAR_5          in FAL_TRACABILITY.HIS_PT_STD_CHAR_5%type
  , aNOMENCLATURE_DEPTH         in integer
  , aLotParent                  in FAL_LOT.FAL_LOT_ID%type
  , aDateParent                 in date
  , ShowAllComponents           in boolean
  , aStartFAL_LOT_ID            in FAL_LOT.FAL_LOT_ID%type
  , aStartSTM_STOCK_MOVEMENT_ID in STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , aStartASA_RECORD_ID         in ASA_RECORD.ASA_RECORD_ID%type
  , aCheckAllCharac             in integer
  )
  is
    cursor CUR_FAL_TRACABILITY
    is
      select distinct TRA.FAL_TRACABILITY_ID
                    , TRA.GCO_GCO_GOOD_ID
                    , TRA.DOC_POSITION_ID
                    , TRA.FAL_LOT_ID
                    , TRA.HIS_DOC_NUMBER
                    , TRA.HIS_LOT_REFCOMPL
                    , TRA.STM_STOCK_MOVEMENT_ID
                    , TRA.HIS_PT_LOT
                    , TRA.HIS_PT_PIECE
                    , TRA.HIS_PT_VERSION
                    , TRA.HIS_CHRONOLOGY_PT
                    , TRA.HIS_PT_STD_CHAR_1
                    , TRA.HIS_PT_STD_CHAR_2
                    , TRA.HIS_PT_STD_CHAR_3
                    , TRA.HIS_PT_STD_CHAR_4
                    , TRA.HIS_PT_STD_CHAR_5
                    , TRA.HIS_CPT_PIECE
                    , TRA.HIS_CPT_LOT
                    , TRA.HIS_CPT_VERSION
                    , TRA.HIS_CHRONOLOGY_CPT
                    , TRA.HIS_CPT_STD_CHAR_1
                    , TRA.HIS_CPT_STD_CHAR_2
                    , TRA.HIS_CPT_STD_CHAR_3
                    , TRA.HIS_CPT_STD_CHAR_4
                    , TRA.HIS_CPT_STD_CHAR_5
                    , TRA.HIS_PLAN_NUMBER
                    , TRA.HIS_PLAN_VERSION
                    , TRA.HIS_VERSION_ORIGIN_NUM
                    , TRA.HIS_QTY
                    , TRA.A_DATECRE
                    , TRA.HIS_FREE_TEXT
                    , TRA.ASA_RECORD_ID
                 from FAL_TRACABILITY TRA
                where TRA.GCO_GOOD_ID = aGCO_GOOD_ID
                  and (nvl(TRA.HIS_PT_PIECE, ' ') = nvl(aPiece, ' ') )
                  and (nvl(TRA.HIS_PT_LOT, ' ') = nvl(aLot, ' ') )
                  and (   aCheckAllCharac = 0
                       or nvl(TRA.HIS_PT_VERSION, ' ') = nvl(aVersion, ' ') )
                  and (   aCheckAllCharac = 0
                       or nvl(TRA.HIS_CHRONOLOGY_PT, ' ') = nvl(aChrono, ' ') )
                  and (   aCheckAllCharac = 0
                       or nvl(TRA.HIS_PT_STD_CHAR_1, ' ') = nvl(aHIS_PT_STD_CHAR_1, ' ') )
                  and (   aCheckAllCharac = 0
                       or nvl(TRA.HIS_PT_STD_CHAR_2, ' ') = nvl(aHIS_PT_STD_CHAR_2, ' ') )
                  and (   aCheckAllCharac = 0
                       or nvl(TRA.HIS_PT_STD_CHAR_3, ' ') = nvl(aHIS_PT_STD_CHAR_3, ' ') )
                  and (   aCheckAllCharac = 0
                       or nvl(TRA.HIS_PT_STD_CHAR_4, ' ') = nvl(aHIS_PT_STD_CHAR_4, ' ') )
                  and (   aCheckAllCharac = 0
                       or nvl(TRA.HIS_PT_STD_CHAR_5, ' ') = nvl(aHIS_PT_STD_CHAR_5, ' ') )
                  and (   aDateParent is null
                       or TRA.A_DATECRE < aDateParent)
                  and (   aStartFAL_LOT_ID is null
                       or TRA.FAL_LOT_ID = aStartFAL_LOT_ID)
                  and (   aStartSTM_STOCK_MOVEMENT_ID is null
                       or TRA.STM_STOCK_MOVEMENT_ID = aStartSTM_STOCK_MOVEMENT_ID)
                  and (   aStartASA_RECORD_ID is null
                       or TRA.ASA_RECORD_ID = aStartASA_RECORD_ID)
             order by TRA.A_DATECRE desc;

    CurFalTracability       CUR_FAL_TRACABILITY%rowtype;
    aLotPrecedent           FAL_LOT.FAL_LOT_ID%type;
    blnDoAffichage          boolean;
    blnDoDuplication        boolean;
    blnFounded              boolean;
    lCPT_GoodId             FAL_TRACABILITY.GCO_GCO_GOOD_ID%type;
    lCPT_Piece              FAL_TRACABILITY.HIS_CPT_PIECE%type;
    lCPT_Lot                FAL_TRACABILITY.HIS_CPT_LOT%type;
    lCPT_Version            FAL_TRACABILITY.HIS_CPT_VERSION%type;
    lCPT_CHrono             FAL_TRACABILITY.HIS_CHRONOLOGY_CPT%type;
    lCPT_STD_CHAR_1         FAL_TRACABILITY.HIS_CPT_STD_CHAR_1%type;
    lCPT_STD_CHAR_2         FAL_TRACABILITY.HIS_CPT_STD_CHAR_2%type;
    lCPT_STD_CHAR_3         FAL_TRACABILITY.HIS_CPT_STD_CHAR_3%type;
    lCPT_STD_CHAR_4         FAL_TRACABILITY.HIS_CPT_STD_CHAR_4%type;
    lCPT_STD_CHAR_5         FAL_TRACABILITY.HIS_CPT_STD_CHAR_5%type;
    vSourceDescr            varchar2(4000);
    iNOMENCLATUREDEPTH      integer;
    aFAL_TRACABILITY_ID     FAL_TRACABILITY.FAL_TRACABILITY_ID%type;
    nSaveLotIdForComponents FAL_LOT.FAL_LOT_ID%type;
  begin
    -- Récupérer la ou les lignes de FAL_TRACABILITY concernées ...
    blnFounded  := false;

    for CurFalTracability in CUR_FAL_TRACABILITY loop
      blnFounded        := true;
      -- Déterminer les valeurs à stocker ...
      lCPT_GoodId       := trim(CurFalTracability.GCO_GCO_GOOD_ID);
      lCPT_Piece        := trim(CurFalTracability.HIS_CPT_PIECE);
      lCPT_Lot          := trim(CurFalTracability.HIS_CPT_LOT);
      lCPT_Version      := trim(CurFalTracability.HIS_CPT_VERSION);
      lCPT_Chrono       := trim(CurFalTracability.HIS_CHRONOLOGY_CPT);
      lCPT_STD_CHAR_1   := trim(CurFalTracability.HIS_CPT_STD_CHAR_1);
      lCPT_STD_CHAR_2   := trim(CurFalTracability.HIS_CPT_STD_CHAR_2);
      lCPT_STD_CHAR_3   := trim(CurFalTracability.HIS_CPT_STD_CHAR_3);
      lCPT_STD_CHAR_4   := trim(CurFalTracability.HIS_CPT_STD_CHAR_4);
      lCPT_STD_CHAR_5   := trim(CurFalTracability.HIS_CPT_STD_CHAR_5);
      blnDoAffichage    := true;
      blnDoDuplication  := false;

      -- Si Mouvement null
      if     CurFalTracability.STM_STOCK_MOVEMENT_ID is null
         and CurFalTracability.ASA_RECORD_ID is null then
        -- Si Lot <> LotParent ou transf caractérisation
        if nvl(aLotParent, 0) <> CurFalTracability.FAL_LOT_ID then
          -- Si caractérisation PT de type pièce
          if not(trim(aPiece) is null) then
            -- Si ligne tracabilité déjà utilisée pour LE PT de niveau 0
            if UsedTracabilityLine(CurFalTracability.FAL_TRACABILITY_ID, aGROUP_FIELD) then
              blnDoAffichage  := false;
            else
              blnDoAffichage  := true;
            end if;
          else
            -- Si LotPrécédent = 0
            if    (aLotPrecedent = 0)
               or (aLotPrecedent is null) then
              aLotPrecedent   := CurFalTracability.FAL_LOT_ID;
              blnDoAffichage  := true;
            else
              -- Si LotPrécédent <> FAL_LOT_ID
              if nvl(aLotPrecedent, 0) <> CurFalTracability.FAL_LOT_ID then
                blnDoAffichage    := true;
                blnDoDuplication  := true;
                aLotPrecedent     := CurFalTracability.FAL_LOT_ID;
              else
                blnDoAffichage  := true;
                aLotPrecedent   := CurFalTracability.FAL_LOT_ID;
              end if;
            end if;
          end if;
        else
          blnDoAffichage  := false;
        end if;
      elsif CurFalTracability.ASA_RECORD_ID is not null then
        blnDoAffichage  := true;
      -- Si mouvement non null
      else
        if ExistsFAL_TRACABILITY(aDateParent
                               , CurFalTracability.A_DATECRE
                               , aGCO_GOOD_ID
                               , aPiece
                               , aLot
                               , aVersion
                               , aChrono
                               , aHIS_PT_STD_CHAR_1
                               , aHIS_PT_STD_CHAR_2
                               , aHIS_PT_STD_CHAR_3
                               , aHIS_PT_STD_CHAR_4
                               , aHIS_PT_STD_CHAR_5
                                ) then
          blnDoAffichage  := false;
        else
          blnDoAffichage  := true;
        end if;
      end if;

      -- Y a t'il duplication de la ligne parent (Plusieurs lots de fabrication possibles pour un produit)?
      if BlnDoDuplication then
        PARENT_Dupplication(aGROUP_FIELD, aNOMENCLATURE_DEPTH);
      end if;

      -- Cette ligne doit-elle être affichée
      if blnDoAffichage then
        -- Formatage de la source de la tracabilité
        if     CurFalTracability.STM_STOCK_MOVEMENT_ID is not null
           and CurFalTracability.ASA_RECORD_ID is null then
          vSourceDescr  := CurFalTracability.HIS_FREE_TEXT;
        elsif CurFalTracability.FAL_LOT_ID is not null then
          vSourceDescr  := CurFalTracability.HIS_LOT_REFCOMPL;
        elsif CurFalTracability.ASA_RECORD_ID is not null then
          vSourceDescr  := GetASA_RECORD_DESCR(CurFalTracability.ASA_RECORD_ID);
        else
          vSourceDescr  := '';
        end if;

        -- Ajout de tous les composants
        nSaveLotIdForComponents  := CurFalTracability.FAL_LOT_ID;

        -- Insertion de la ligne de tracabilité
        if not(aPiece is null) then
          aFAL_TRACABILITY_ID  := CurFalTracaBility.FAL_TRACABILITY_ID;
        else
          aFAL_TRACABILITY_ID  := null;
        end if;

        BUILDTRACABILITY_ROW(aGROUP_FIELD
                           , null
                           , lCPT_GoodId
                           , CurFalTracability.FAL_LOT_ID
                           , CurFalTracability.DOC_POSITION_ID
                           , aNomenclature_depth
                           , CurFalTracaBility.HIS_DOC_NUMBER
                           , CurFalTracaBility.HIS_PT_LOT
                           , vSourceDescr
                           , CurFalTracaBility.HIS_PT_PIECE
                           , CurFalTracaBility.HIS_PT_VERSION
                           , CurFalTracaBility.HIS_CHRONOLOGY_PT
                           , CurFalTracaBility.HIS_PT_STD_CHAR_1
                           , CurFalTracaBility.HIS_PT_STD_CHAR_2
                           , CurFalTracaBility.HIS_PT_STD_CHAR_3
                           , CurFalTracaBility.HIS_PT_STD_CHAR_4
                           , CurFalTracaBility.HIS_PT_STD_CHAR_5
                           , CurFalTracaBility.HIS_CPT_PIECE
                           , CurFalTracaBility.HIS_CPT_LOT
                           , CurFalTracaBility.HIS_CPT_VERSION
                           , CurFalTracaBility.HIS_CHRONOLOGY_CPT
                           , CurFalTracaBility.HIS_CPT_STD_CHAR_1
                           , CurFalTracaBility.HIS_CPT_STD_CHAR_2
                           , CurFalTracaBility.HIS_CPT_STD_CHAR_3
                           , CurFalTracaBility.HIS_CPT_STD_CHAR_4
                           , CurFalTracaBility.HIS_CPT_STD_CHAR_5
                           , CurFalTracaBility.HIS_PLAN_NUMBER
                           , CurFalTracaBility.HIS_PLAN_VERSION
                           , CurFalTracaBility.HIS_VERSION_ORIGIN_NUM
                           , null
                           , null
                           , null
                           , CurFalTracaBility.HIS_QTY
                           , aFAL_TRACABILITY_ID
                           , null
                           , CurFalTracability.ASA_RECORD_ID
                            );
        -- Parcours des enfants
        iNomenclaturedepth       := aNomenclature_depth + 1;
        BUILDTRACABILITY_DESCENDANT(aGROUP_FIELD
                                  , lCPT_goodid
                                  , lCPT_Lot
                                  , lCPT_Piece
                                  , lCPT_Version
                                  , lCPT_Chrono
                                  , lCPT_STD_CHAR_1
                                  , lCPT_STD_CHAR_2
                                  , lCPT_STD_CHAR_3
                                  , lCPT_STD_CHAR_4
                                  , lCPT_STD_CHAR_5
                                  , iNomenclaturedepth
                                  , CurFalTracaBility.FAL_LOT_ID
                                  , CurFalTracaBility.A_DATECRE
                                  , ShowAllComponents
                                  , null
                                  , null
                                  , null
                                  , 1
                                   );
      end if;
    end loop;

    if ShowAllComponents then
      if blnFounded then
        ADDALLCOMPONENTS(aGROUP_FIELD, nSaveLotIdForComponents, aGCO_GOOD_ID, aNomenclature_depth, aLot, aPiece, aVersion);
      end if;
    end if;
  exception
    when others then
      raise;
  end;

  /* Insertion d'une ligne de tracabilité dans la Global temporary table FAL_TRACABILITY_PRNT */
  procedure BUILDTRACABILITY_ROW(
    aGROUP_FIELD             in number
  , aGCO_GOOD_ID             in GCO_GOOD.GCO_GOOD_ID%type
  , aGCO_GCO_GOOD_ID         in GCO_GOOD.GCO_GOOD_ID%type
  , aFAL_LOT_ID              in FAL_LOT.FAL_LOT_ID%type
  , aDOC_POSITION_ID         in FAL_TRACABILITY.DOC_POSITION_ID%type
  , aNOMENCLATURE_DEPTH      in integer
  , aHIS_DMT_NUMBER          in DOC_DOCUMENT.DMT_NUMBER%type
  , aHIS_PT_LOT              in FAL_TRACABILITY.HIS_PT_LOT%type
  , aLOT_REFCOMPL            in FAL_LOT.LOT_REFCOMPL%type
  , aHIS_PT_PIECE            in FAL_TRACABILITY.HIS_PT_PIECE%type
  , aHIS_PT_VERSION          in FAL_TRACABILITY.HIS_PT_VERSION%type
  , aHIS_CHRONOLOGY_PT       in FAL_TRACABILITY.HIS_CHRONOLOGY_PT%type
  , aHIS_PT_STD_CHAR_1       in FAL_TRACABILITY.HIS_PT_STD_CHAR_1%type
  , aHIS_PT_STD_CHAR_2       in FAL_TRACABILITY.HIS_PT_STD_CHAR_2%type
  , aHIS_PT_STD_CHAR_3       in FAL_TRACABILITY.HIS_PT_STD_CHAR_3%type
  , aHIS_PT_STD_CHAR_4       in FAL_TRACABILITY.HIS_PT_STD_CHAR_4%type
  , aHIS_PT_STD_CHAR_5       in FAL_TRACABILITY.HIS_PT_STD_CHAR_5%type
  , aHIS_CPT_PIECE           in FAL_TRACABILITY.HIS_CPT_PIECE%type
  , aHIS_CPT_LOT             in FAL_TRACABILITY.HIS_CPT_LOT%type
  , aHIS_CPT_VERSION         in FAL_TRACABILITY.HIS_CPT_VERSION%type
  , aHIS_CHRONOLOGY_CPT      in FAL_TRACABILITY.HIS_CHRONOLOGY_CPT%type
  , aHIS_CPT_STD_CHAR_1      in FAL_TRACABILITY.HIS_CPT_STD_CHAR_1%type
  , aHIS_CPT_STD_CHAR_2      in FAL_TRACABILITY.HIS_CPT_STD_CHAR_2%type
  , aHIS_CPT_STD_CHAR_3      in FAL_TRACABILITY.HIS_CPT_STD_CHAR_3%type
  , aHIS_CPT_STD_CHAR_4      in FAL_TRACABILITY.HIS_CPT_STD_CHAR_4%type
  , aHIS_CPT_STD_CHAR_5      in FAL_TRACABILITY.HIS_CPT_STD_CHAR_5%type
  , aHIS_PLAN_NUMBER         in FAL_TRACABILITY.HIS_PLAN_NUMBER%type
  , aHIS_PLAN_VERSION        in FAL_TRACABILITY.HIS_PLAN_VERSION%type
  , aHIS_VERSION_ORIGINE_NUM in FAL_TRACABILITY.HIS_VERSION_ORIGIN_NUM%type
  , aMOVEMENT_DATE           in FAL_HISTO_LOT.A_DATECRE%type
  , aMOVEMENT_QTE            in FAL_HISTO_LOT.HIS_QTE%type
  , aEVEN_TYPE_DESCR         in varchar2
  , aCPT_QUANTITY            in number default 0
  , aFAL_TRACABILITY_ID      in FAL_TRACABILITY.FAL_TRACABILITY_ID%type
  , aSTM_STOCK_MOVEMENT_ID   in STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , aASA_RECORD_ID           in ASA_RECORD.ASA_RECORD_ID%type
  )
  is
    NewFAL_TRACABILITY_ID    FAL_TRACABILITY.FAL_TRACABILITY_ID%type;
    vLOT_REFCOMPL            varchar2(4000);
    vDMT_NUMBER              varchar2(4000);
    vARE_NUMBER              varchar2(4000);
    aGOO_MAJOR_REFERENCE     GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    aGOO_SECONDARY_REFERENCE GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
    dLOT_FULL_REL_DTE        FAL_LOT.LOT_FULL_REL_DTE%type;
  begin
    -- Références produit
    GETGCOREFERENCES(nvl(aGCO_GCO_GOOD_ID, aGCO_GOOD_ID), aGOO_MAJOR_REFERENCE, aGOO_SECONDARY_REFERENCE);
    NewFAL_TRACABILITY_ID  := GetNewId;

    -- S'il ne s'agit pas de l'insertion d'un mouvement
    if aSTM_STOCK_MOVEMENT_ID is null then
      -- Si niveau de nomenclature = 0 et lot non null, on recherche la lot_Full_rel_dte pour affichage.
      dLOT_FULL_REL_DTE  := null;

      if     (aNOMENCLATURE_DEPTH = 0)
         and not(aFAL_LOT_ID is null) then
        begin
          select LOT_FULL_REL_DTE
            into dLOT_FULL_REL_DTE
            from FAL_LOT
           where FAL_LOT_ID = aFAL_LOT_ID;
        exception
          when others then
            begin
              select LOT_FULL_REL_DTE
                into dLOT_FULL_REL_DTE
                from FAL_LOT_HIST
               where FAL_LOT_HIST_ID = aFAL_LOT_ID;
            exception
              when others then
                dLOT_FULL_REL_DTE  := null;
            end;
        end;
      end if;

      -- Update de la ligne de tracabilité parente.
      update FAL_TRACABILITY_PRNT
         set FTP_LOT_REFCOMPL = aLOT_REFCOMPL
           , FTP_PLAN_NUMBER = aHIS_PLAN_NUMBER
           , FTP_PLAN_VERSION = aHIS_PLAN_VERSION
           , FTP_VERSION_ORIGIN_NUM = aHIS_VERSION_ORIGINE_NUM
       where FTP_GROUP_FIELD = aGROUP_FIELD
         and FTP_NOMENCLATURE_DEPTH = aNOMENCLATURE_DEPTH - 1
         and FAL_TRACABILITY_PRNT_ID =
                    (select max(FAL_TRACABILITY_PRNT_ID)
                       from FAL_TRACABILITY_PRNT FTP2
                      where FTP2.FTP_GROUP_FIELD = aGROUP_FIELD
                        and FTP2.FTP_NOMENCLATURE_DEPTH = aNOMENCLATURE_DEPTH - 1
                        and FTP2.STM_STOCK_MOVEMENT_ID is null);

      -- Source de la tracabilité courante.
      GetTracabilitySource(nvl(aGCO_GCO_GOOD_ID, aGCO_GOOD_ID)   -- aGCO_GOOD_ID        IN GCO_GOOD.GCO_GOOD_ID%TYPE,
                         , aHIS_CPT_PIECE   -- IN FAL_TRACABILITY.HIS_CPT_PIECE%TYPE,
                         , aHIS_CPT_LOT   -- IN FAL_TRACABILITY.HIS_CPT_LOT%TYPE,
                         , aHIS_CPT_VERSION   -- IN FAL_TRACABILITY.HIS_CPT_VERSION%TYPE,
                         , aHIS_CHRONOLOGY_CPT   -- IN FAL_TRACABILITY.HIS_CHRONOLOGY_CPT%TYPE,
                         , aHIS_CPT_STD_CHAR_1
                         , aHIS_CPT_STD_CHAR_2
                         , aHIS_CPT_STD_CHAR_3
                         , aHIS_CPT_STD_CHAR_4
                         , aHIS_CPT_STD_CHAR_5
                         , aSTM_STOCK_MOVEMENT_ID
                         , null
                         , vLOT_REFCOMPL   -- IN OUT VARCHAR2,
                         , vDMT_NUMBER
                         , vARE_NUMBER
                          );   -- IN OUT VARCHAR2);
    end if;

    insert into FAL_TRACABILITY_PRNT
                (FAL_TRACABILITY_PRNT_ID
               , FTP_GROUP_FIELD
               , GCO_GOOD_ID
               , GCO_GCO_GOOD_ID
               , FAL_LOT_ID
               , DOC_POSITION_ID
               , FTP_GOO_MAJOR_REF
               , FTP_GOO_SECONDARY_REF
               , FTP_NOMENCLATURE_DEPTH
               , FTP_DMT_NUMBER
               , FTP_PT_LOT
               , FTP_LOT_REFCOMPL
               , FTP_LOT_FULL_REL_DTE
               , FTP_PT_PIECE
               , FTP_PT_VERSION
               , FTP_CHRONOLOGY_PT
               , FTP_PT_STD_CHAR_1
               , FTP_PT_STD_CHAR_2
               , FTP_PT_STD_CHAR_3
               , FTP_PT_STD_CHAR_4
               , FTP_PT_STD_CHAR_5
               , FTP_CPT_PIECE
               , FTP_CPT_LOT
               , FTP_CPT_VERSION
               , FTP_CHRONOLOGY_CPT
               , FTP_CPT_STD_CHAR_1
               , FTP_CPT_STD_CHAR_2
               , FTP_CPT_STD_CHAR_3
               , FTP_CPT_STD_CHAR_4
               , FTP_CPT_STD_CHAR_5
               , FTP_PLAN_NUMBER
               , FTP_PLAN_VERSION
               , FTP_VERSION_ORIGIN_NUM
               , FTP_MOVEMENT_DATE
               , FTP_MOVEMENT_QTY
               , FTP_EVEN_TYPE_DESCR
               , FTP_CPT_QUANTITY
               , FAL_TRACABILITY_ID
               , STM_STOCK_MOVEMENT_ID
               , ASA_RECORD_ID
                )
         values (NewFAL_TRACABILITY_ID
               , aGROUP_FIELD
               , aGCO_GOOD_ID
               , aGCO_GCO_GOOD_ID
               , aFAL_LOT_ID
               , aDOC_POSITION_ID
               , aGOO_MAJOR_REFERENCE
               , aGOO_SECONDARY_REFERENCE
               , aNOMENCLATURE_DEPTH
               , aHIS_DMT_NUMBER
               , aHIS_PT_LOT
               , substr(nvl(vLOT_REFCOMPL, nvl(vDMT_NUMBER, vARE_NUMBER) ), 0, 100)
               , dLOT_FULL_REL_DTE
               , aHIS_PT_PIECE
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
               , null   --aHIS_PLAN_NUMBER
               , null   --aHIS_PLAN_VERSION
               , null   --aHIS_VERSION_ORIGINE_NUM
               , aMOVEMENT_DATE
               , aMOVEMENT_QTE
               , aEVEN_TYPE_DESCR
               , aCPT_QUANTITY
               , aFAL_TRACABILITY_ID
               , aSTM_STOCK_MOVEMENT_ID
               , aASA_RECORD_ID
                );
  end BUILDTRACABILITY_ROW;

  /* Renvoie les refs du bien passé en parametre */
  procedure GETGCOREFERENCES(
    aGCO_GOOD_ID             in     GCO_GOOD.GCO_GOOD_ID%type
  , aGOO_MAJOR_REFERENCE     in out GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , aGOO_SECONDARY_REFERENCE in out GCO_GOOD.GOO_SECONDARY_REFERENCE%type
  )
  is
    cursor CUR_GCO_REFERENCES
    is
      select GOO_MAJOR_REFERENCE
           , GOO_SECONDARY_REFERENCE
        from GCO_GOOD
       where GCO_GOOD_ID = aGCO_GOOD_ID;

    CurGcoReferences CUR_GCO_REFERENCES%rowtype;
  begin
    if aGCO_GOOD_ID <> 0 then
      open CUR_GCO_REFERENCES;

      fetch CUR_GCO_REFERENCES
       into CurGcoReferences;

      if CUR_GCO_REFERENCES%found then
        aGOO_MAJOR_REFERENCE      := CurGcoReferences.GOO_MAJOR_REFERENCE;
        aGOO_SECONDARY_REFERENCE  := CurGcoReferences.GOO_SECONDARY_REFERENCE;
      end if;
    end if;
  end GETGCOREFERENCES;

  /* Ajout des composants sans information de tracabilité */
  procedure ADDALLCOMPONENTS(
    aGROUP_FIELD                 in number
  , aFAL_LOT_ID                  in FAL_LOT.FAL_LOT_ID%type
  , aGCO_GOOD_ID                 in GCO_GOOD.GCO_GOOD_ID%type
  , aNOMENCLATURE_DEPTH          in integer
  , aSMO_CHARACTERIZATION_VALUE1 in varchar2
  , aSMO_CHARACTERIZATION_VALUE2 in varchar2
  , aSMO_CHARACTERIZATION_VALUE3 in varchar2
  )
  is
    cursor CUR_FAL_FACTORY_OUT
    is
      select distinct LOT.LOT_REFCOMPL
                    , LOT.LOT_FULL_REL_DTE
                    , LOT.FAL_LOT_ID
                    , FOUT.OUT_QTE
                    , FOUT.OUT_DATE
                    , FOUT.GCO_GOOD_ID
                 from FAL_FACTORY_OUT FOUT
                    , FAL_LOT LOT
                where LOT.FAL_LOT_ID = aFAL_LOT_ID
                  and LOT.FAL_LOT_ID = FOUT.FAL_LOT_ID
                  and not exists(select GCO_CHARACTERIZATION_ID
                                   from GCO_CHARACTERIZATION
                                  where GCO_GOOD_ID = FOUT.GCO_GOOD_ID)
                  and not exists(
                        select *
                          from FAL_TRACABILITY_PRNT FTP
                             , FAL_LOT LOT2
                         where FTP.GCO_GOOD_ID = FOUT.GCO_GOOD_ID
                           and FTP.FAL_LOT_ID = LOT2.FAL_LOT_ID(+)
                           and LOT2.FAL_LOT_ID = aFAL_LOT_ID
                           and FTP.FTP_GROUP_FIELD = aGROUP_FIELD)
      union
      select distinct LOTH.LOT_REFCOMPL
                    , LOTH.LOT_FULL_REL_DTE
                    , LOTH.FAL_LOT_HIST_ID FAL_LOT_ID
                    , FOUTH.OUT_QTE
                    , FOUTH.OUT_DATE
                    , FOUTH.GCO_GOOD_ID
                 from FAL_FACTORY_OUT_HIST FOUTH
                    , FAL_LOT_HIST LOTH
                where LOTH.FAL_LOT_HIST_ID = aFAL_LOT_ID
                  and LOTH.FAL_LOT_HIST_ID = FOUTH.FAL_LOT_HIST_ID
                  and not exists(select GCO_CHARACTERIZATION_ID
                                   from GCO_CHARACTERIZATION
                                  where GCO_GOOD_ID = FOUTH.GCO_GOOD_ID)
                  and not exists(
                        select *
                          from FAL_TRACABILITY_PRNT FTP
                             , FAL_LOT_HIST LOTH2
                         where FTP.GCO_GOOD_ID = FOUTH.GCO_GOOD_ID
                           and FTP.FAL_LOT_ID = LOTH2.FAL_LOT_HIST_ID(+)
                           and LOTH2.FAL_LOT_HIST_ID = aFAL_LOT_ID
                           and FTP.FTP_GROUP_FIELD = aGROUP_FIELD)
             order by OUT_DATE;

    CurFalFactoryOut CUR_FAL_FACTORY_OUT%rowtype;
  begin
    if     not(aFAL_LOT_ID is null)
       and (aFAL_LOT_ID <> 0) then
      for CurFalFactoryOut in CUR_FAL_FACTORY_OUT loop
        BUILDTRACABILITY_ROW(aGROUP_FIELD
                           , CurFalFactoryOut.GCO_GOOD_ID
                           , null
                           , CurFalFactoryOut.FAL_LOT_ID
                           , null
                           , aNOMENCLATURE_DEPTH
                           , null
                           , null
                           , CurFalFactoryOut.LOT_REFCOMPL
                           , CurFalFactoryOut.LOT_FULL_REL_DTE
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , null
                           , CurFalFactoryOut.OUT_QTE
                           , null
                           , null
                           , null
                            );
      end loop;
    end if;
  end;

  /* Récupération de la Source d'un enregistrement de tracabilité */
  procedure GetTracabilitySource(
    aGCO_GOOD_ID           in     GCO_GOOD.GCO_GOOD_ID%type
  , aHIS_CPT_PIECE         in     FAL_TRACABILITY.HIS_CPT_PIECE%type
  , aHIS_CPT_LOT           in     FAL_TRACABILITY.HIS_CPT_LOT%type
  , aHIS_CPT_VERSION       in     FAL_TRACABILITY.HIS_CPT_VERSION%type
  , aHIS_CHRONOLOGY_CPT    in     FAL_TRACABILITY.HIS_CHRONOLOGY_CPT%type
  , aHIS_CPT_STD_CHAR_1    in     FAL_TRACABILITY.HIS_CPT_STD_CHAR_1%type
  , aHIS_CPT_STD_CHAR_2    in     FAL_TRACABILITY.HIS_CPT_STD_CHAR_2%type
  , aHIS_CPT_STD_CHAR_3    in     FAL_TRACABILITY.HIS_CPT_STD_CHAR_3%type
  , aHIS_CPT_STD_CHAR_4    in     FAL_TRACABILITY.HIS_CPT_STD_CHAR_4%type
  , aHIS_CPT_STD_CHAR_5    in     FAL_TRACABILITY.HIS_CPT_STD_CHAR_5%type
  , aSTM_STOCK_MOVEMENT_ID in     STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , aASA_RECORD_ID         in     ASA_RECORD.ASA_RECORD_ID%type
  , aLOT_REFCOMPL          in out varchar2
  , aDMT_NUMBER            in out varchar2
  , aARE_NUMBER            in out ASA_RECORD.ARE_NUMBER%type
  )
  is
    type TTabLotRefCompl is table of FAL_LOT_DETAIL.FAD_LOT_REFCOMPL%type
      index by binary_integer;

    type TTabDmtNumber is table of DOC_DOCUMENT.DMT_NUMBER%type
      index by binary_integer;

    vSourceDescr   varchar2(4000);
    BuffSQL        varchar2(32000);
    TabLotRefCompl TTabLotRefCompl;
    TabDmtNumber   TTabDmtNumber;
    vLOT_REFCOMPL  FAL_LOT.LOT_REFCOMPL%type;
    vDMT_NUMBER    DOC_DOCUMENT.DMT_NUMBER%type;
    StrCharact     varchar2(30);
  begin
    if     (   aHIS_CPT_PIECE is null
            or trim(aHIS_CPT_PIECE) = '')
       and (   aHIS_CPT_LOT is null
            or trim(aHIS_CPT_LOT) = '')
       and (   aHIS_CPT_VERSION is null
            or trim(aHIS_CPT_VERSION) = '')
       and (   aHIS_CHRONOLOGY_CPT is null
            or trim(aHIS_CHRONOLOGY_CPT) = '')
       and (   aHIS_CPT_STD_CHAR_1 is null
            or trim(aHIS_CPT_STD_CHAR_1) = '')
       and (   aHIS_CPT_STD_CHAR_2 is null
            or trim(aHIS_CPT_STD_CHAR_2) = '')
       and (   aHIS_CPT_STD_CHAR_3 is null
            or trim(aHIS_CPT_STD_CHAR_3) = '')
       and (   aHIS_CPT_STD_CHAR_4 is null
            or trim(aHIS_CPT_STD_CHAR_4) = '')
       and (   aHIS_CPT_STD_CHAR_5 is null
            or trim(aHIS_CPT_STD_CHAR_5) = '') then
      vLot_Refcompl  := '';
      vDMT_NUMBER    := '';
    elsif     (aASA_RECORD_ID is not null)
          and (aSTM_STOCK_MOVEMENT_ID is null) then
      aARE_NUMBER  := GetASA_RECORD_DESCR(aASA_RECORD_ID);
    else
      vSourceDescr  := '';

      begin
        -- Recherche d'abord sur les détails lots
        BuffSQL        := ' select FAD.FAD_LOT_REFCOMPL ' || '   from FAL_LOT_DETAIL FAD ' || '  where GCO_GOOD_ID = :aGCO_GOOD_ID ';

        -- Version
        if not(aHIS_CPT_VERSION is null) then
          StrCharact  := replace(aHIS_CPT_VERSION, '''', '''''');
          BuffSQL     :=
            BuffSQL ||
            '  and ((FAL_PRINT_PROCS.GetCharacType(FAD.GCO_CHARACTERIZATION_ID) = ''1'' AND FAD.FAD_CHARACTERIZATION_VALUE_1 = ''' ||
            StrCharact ||
            ''') ' ||
            '        or (FAL_PRINT_PROCS.GetCharacType(FAD.GCO_GCO_CHARACTERIZATION_ID) = ''1'' AND FAD.FAD_CHARACTERIZATION_VALUE_2 = ''' ||
            StrCharact ||
            ''') ' ||
            '        or (FAL_PRINT_PROCS.GetCharacType(FAD.GCO2_GCO_CHARACTERIZATION_ID) = ''1'' AND FAD.FAD_CHARACTERIZATION_VALUE_3 = ''' ||
            StrCharact ||
            ''') ' ||
            '        or (FAL_PRINT_PROCS.GetCharacType(FAD.GCO3_GCO_CHARACTERIZATION_ID) = ''1'' AND FAD.FAD_CHARACTERIZATION_VALUE_4 = ''' ||
            StrCharact ||
            ''') ' ||
            '        or (FAL_PRINT_PROCS.GetCharacType(FAD.GCO4_GCO_CHARACTERIZATION_ID) = ''1'' AND FAD.FAD_CHARACTERIZATION_VALUE_5 = ''' ||
            StrCharact ||
            ''')) ';
        end if;

        --Piece
        if not(aHIS_CPT_PIECE is null) then
          StrCharact  := replace(aHIS_CPT_PIECE, '''', '''''');
          BuffSQL     :=
            BuffSQL ||
            '  and ((FAL_PRINT_PROCS.GetCharacType(FAD.GCO_CHARACTERIZATION_ID) = ''3'' AND FAD.FAD_CHARACTERIZATION_VALUE_1 = ''' ||
            StrCharact ||
            ''') ' ||
            '        or (FAL_PRINT_PROCS.GetCharacType(FAD.GCO_GCO_CHARACTERIZATION_ID) = ''3'' AND FAD.FAD_CHARACTERIZATION_VALUE_2 = ''' ||
            StrCharact ||
            ''')  ' ||
            '        or (FAL_PRINT_PROCS.GetCharacType(FAD.GCO2_GCO_CHARACTERIZATION_ID) = ''3'' AND FAD.FAD_CHARACTERIZATION_VALUE_3 = ''' ||
            StrCharact ||
            ''')  ' ||
            '        or (FAL_PRINT_PROCS.GetCharacType(FAD.GCO3_GCO_CHARACTERIZATION_ID) = ''3'' AND FAD.FAD_CHARACTERIZATION_VALUE_4 = ''' ||
            StrCharact ||
            ''')  ' ||
            '        or (FAL_PRINT_PROCS.GetCharacType(FAD.GCO4_GCO_CHARACTERIZATION_ID) = ''3'' AND FAD.FAD_CHARACTERIZATION_VALUE_5 = ''' ||
            StrCharact ||
            ''')) ';
        end if;

        -- Lot
        if not(aHIS_CPT_LOT is null) then
          StrCharact  := replace(aHIS_CPT_LOT, '''', '''''');
          BuffSQL     :=
            BuffSQL ||
            '  and ((FAL_PRINT_PROCS.GetCharacType(FAD.GCO_CHARACTERIZATION_ID) = ''4'' AND FAD.FAD_CHARACTERIZATION_VALUE_1 = ''' ||
            StrCharact ||
            ''') ' ||
            '        or (FAL_PRINT_PROCS.GetCharacType(FAD.GCO_GCO_CHARACTERIZATION_ID) = ''4'' AND FAD.FAD_CHARACTERIZATION_VALUE_2 = ''' ||
            StrCharact ||
            ''') ' ||
            '        or (FAL_PRINT_PROCS.GetCharacType(FAD.GCO2_GCO_CHARACTERIZATION_ID) = ''4'' AND FAD.FAD_CHARACTERIZATION_VALUE_3 = ''' ||
            StrCharact ||
            ''') ' ||
            '        or (FAL_PRINT_PROCS.GetCharacType(FAD.GCO3_GCO_CHARACTERIZATION_ID) = ''4'' AND FAD.FAD_CHARACTERIZATION_VALUE_4 = ''' ||
            StrCharact ||
            ''') ' ||
            '        or (FAL_PRINT_PROCS.GetCharacType(FAD.GCO4_GCO_CHARACTERIZATION_ID) = ''4'' AND FAD.FAD_CHARACTERIZATION_VALUE_5 = ''' ||
            replace(aHIS_CPT_LOT, ''', ''''') ||
            ''')) ';
        end if;

        -- Chronologie
        if not(aHIS_CHRONOLOGY_CPT is null) then
          StrCharact  := replace(aHIS_CHRONOLOGY_CPT, '''', '''''');
          BuffSQL     :=
            BuffSQL ||
            '  and ((FAL_PRINT_PROCS.GetCharacType(FAD.GCO_CHARACTERIZATION_ID) = ''5'' AND FAD.FAD_CHARACTERIZATION_VALUE_1 = ''' ||
            StrCharact ||
            ''') ' ||
            '        or (FAL_PRINT_PROCS.GetCharacType(FAD.GCO_GCO_CHARACTERIZATION_ID) = ''5'' AND FAD.FAD_CHARACTERIZATION_VALUE_2 = ''' ||
            StrCharact ||
            ''') ' ||
            '        or (FAL_PRINT_PROCS.GetCharacType(FAD.GCO2_GCO_CHARACTERIZATION_ID) = ''5'' AND FAD.FAD_CHARACTERIZATION_VALUE_3 = ''' ||
            StrCharact ||
            ''') ' ||
            '        or (FAL_PRINT_PROCS.GetCharacType(FAD.GCO3_GCO_CHARACTERIZATION_ID) = ''5'' AND FAD.FAD_CHARACTERIZATION_VALUE_4 = ''' ||
            StrCharact ||
            ''') ' ||
            '        or (FAL_PRINT_PROCS.GetCharacType(FAD.GCO4_GCO_CHARACTERIZATION_ID) = ''5'' AND FAD.FAD_CHARACTERIZATION_VALUE_5 = ''' ||
            StrCharact ||
            ''')) ';
        end if;

        -- Ainsi que sur les détails lots archivés
        BuffSQL        :=
                  '( ' || BuffSQL || ' ) UNION ( ' || replace(replace(BuffSQL, 'FAL_LOT_DETAIL', 'FAL_LOT_DETAIL_HIST'), 'FAL_LOT_ID', 'FAL_LOT_HIST_ID')
                  || ' )';

        execute immediate BuffSQL
        bulk collect into TabLotRefcompl
                    using aGCO_GOOD_ID, aGCO_GOOD_ID;

        if TabLotRefcompl.count > 0 then
          for i in TabLotRefcompl.first .. TabLotRefcompl.last loop
            vSourceDescr  := vSourceDescr || TabLotRefcompl(i) || ';';
          end loop;
        end if;

        aLOT_REFCOMPL  := substr(vSourceDescr, 0, length(vSourceDescr) - 1);
      exception
        when others then
          aLOT_REFCOMPL  := '';
          raise;
      end;

      -- Si aucun lot trouvé, alors recherche parmis les documents.
      if    (trim(vSourceDescr) = '')
         or (vSourceDescr is null) then
        begin
          -- Recherche sur les détail positions
          BuffSQL      :=
            ' select DISTINCT DOC.DMT_NUMBER ' ||
            '   from DOC_POSITION_DETAIL PDE ' ||
            '      , DOC_POSITION POS ' ||
            '      , DOC_DOCUMENT DOC ' ||
            '  WHERE PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID ' ||
            '    AND POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID ' ||
            '    AND POS.GCO_GOOD_ID = :aGCO_GOOD_ID ';

          -- Version
          if not(aHIS_CPT_VERSION is null) then
            StrCharact  := replace(aHIS_CPT_VERSION, '''', '''''');
            BuffSQL     :=
              BuffSQL ||
              ' and ((FAL_PRINT_PROCS.GetCharacType(PDE.GCO_CHARACTERIZATION_ID) = ''1'' AND PDE.PDE_CHARACTERIZATION_VALUE_1 = ''' ||
              StrCharact ||
              ''') ' ||
              '       or (FAL_PRINT_PROCS.GetCharacType(PDE.GCO_GCO_CHARACTERIZATION_ID) = ''1'' AND PDE.PDE_CHARACTERIZATION_VALUE_2 = ''' ||
              StrCharact ||
              ''') ' ||
              '       or (FAL_PRINT_PROCS.GetCharacType(PDE.GCO2_GCO_CHARACTERIZATION_ID) = ''1'' AND PDE.PDE_CHARACTERIZATION_VALUE_3 = ''' ||
              StrCharact ||
              ''') ' ||
              '       or (FAL_PRINT_PROCS.GetCharacType(PDE.GCO3_GCO_CHARACTERIZATION_ID) = ''1'' AND PDE.PDE_CHARACTERIZATION_VALUE_4 = ''' ||
              StrCharact ||
              ''') ' ||
              '       or (FAL_PRINT_PROCS.GetCharacType(PDE.GCO4_GCO_CHARACTERIZATION_ID) = ''1'' AND PDE.PDE_CHARACTERIZATION_VALUE_5 = ''' ||
              StrCharact ||
              ''')) ';
          end if;

          -- Piece
          if not(aHIS_CPT_PIECE is null) then
            StrCharact  := replace(aHIS_CPT_PIECE, '''', '''''');
            BuffSQL     :=
              BuffSQL ||
              ' and ((FAL_PRINT_PROCS.GetCharacType(PDE.GCO_CHARACTERIZATION_ID) = ''3'' AND PDE.PDE_CHARACTERIZATION_VALUE_1 = ''' ||
              StrCharact ||
              ''') ' ||
              '       or (FAL_PRINT_PROCS.GetCharacType(PDE.GCO_GCO_CHARACTERIZATION_ID) = ''3'' AND PDE.PDE_CHARACTERIZATION_VALUE_2 = ''' ||
              StrCharact ||
              ''') ' ||
              '       or (FAL_PRINT_PROCS.GetCharacType(PDE.GCO2_GCO_CHARACTERIZATION_ID) = ''3'' AND PDE.PDE_CHARACTERIZATION_VALUE_3 = ''' ||
              StrCharact ||
              ''') ' ||
              '       or (FAL_PRINT_PROCS.GetCharacType(PDE.GCO3_GCO_CHARACTERIZATION_ID) = ''3'' AND PDE.PDE_CHARACTERIZATION_VALUE_4 = ''' ||
              StrCharact ||
              ''') ' ||
              '       or (FAL_PRINT_PROCS.GetCharacType(PDE.GCO4_GCO_CHARACTERIZATION_ID) = ''3'' AND PDE.PDE_CHARACTERIZATION_VALUE_5 = ''' ||
              StrCharact ||
              ''')) ';
          end if;

          -- Lot
          if not(aHIS_CPT_LOT is null) then
            StrCharact  := replace(aHIS_CPT_LOT, '''', '''''');
            BuffSQL     :=
              BuffSQL ||
              ' and ((FAL_PRINT_PROCS.GetCharacType(PDE.GCO_CHARACTERIZATION_ID) = ''4'' AND PDE.PDE_CHARACTERIZATION_VALUE_1 = ''' ||
              StrCharact ||
              ''') ' ||
              '       or (FAL_PRINT_PROCS.GetCharacType(PDE.GCO_GCO_CHARACTERIZATION_ID) = ''4'' AND PDE.PDE_CHARACTERIZATION_VALUE_2 = ''' ||
              StrCharact ||
              ''') ' ||
              '       or (FAL_PRINT_PROCS.GetCharacType(PDE.GCO2_GCO_CHARACTERIZATION_ID) = ''4'' AND PDE.PDE_CHARACTERIZATION_VALUE_3 = ''' ||
              StrCharact ||
              ''') ' ||
              '       or (FAL_PRINT_PROCS.GetCharacType(PDE.GCO3_GCO_CHARACTERIZATION_ID) = ''4'' AND PDE.PDE_CHARACTERIZATION_VALUE_4 = ''' ||
              StrCharact ||
              ''') ' ||
              '       or (FAL_PRINT_PROCS.GetCharacType(PDE.GCO4_GCO_CHARACTERIZATION_ID) = ''4'' AND PDE.PDE_CHARACTERIZATION_VALUE_5 = ''' ||
              StrCharact ||
              ''')) ';
          end if;

          -- Chronologie
          if not(aHIS_CHRONOLOGY_CPT is null) then
            StrCharact  := replace(aHIS_CHRONOLOGY_CPT, '''', '''''');
            BuffSQL     :=
              BuffSQL ||
              ' and ((FAL_PRINT_PROCS.GetCharacType(PDE.GCO_CHARACTERIZATION_ID) = ''5'' AND PDE.PDE_CHARACTERIZATION_VALUE_1 = ''' ||
              StrCharact ||
              ''') ' ||
              '       or (FAL_PRINT_PROCS.GetCharacType(PDE.GCO_GCO_CHARACTERIZATION_ID) = ''5'' AND PDE.PDE_CHARACTERIZATION_VALUE_2 = ''' ||
              StrCharact ||
              ''') ' ||
              '       or (FAL_PRINT_PROCS.GetCharacType(PDE.GCO2_GCO_CHARACTERIZATION_ID) = ''5'' AND PDE.PDE_CHARACTERIZATION_VALUE_3 = ''' ||
              StrCharact ||
              ''') ' ||
              '       or (FAL_PRINT_PROCS.GetCharacType(PDE.GCO3_GCO_CHARACTERIZATION_ID) = ''5'' AND PDE.PDE_CHARACTERIZATION_VALUE_4 = ''' ||
              StrCharact ||
              ''') ' ||
              '       or (FAL_PRINT_PROCS.GetCharacType(PDE.GCO4_GCO_CHARACTERIZATION_ID) = ''5'' AND PDE.PDE_CHARACTERIZATION_VALUE_5 = ''' ||
              StrCharact ||
              ''')) ';
          end if;

          execute immediate BuffSQL
          bulk collect into TabDmtNumber
                      using aGCO_GOOD_ID;

          if TabDmtNumber.count > 0 then
            for i in TabDmtNumber.first .. TabDmtNumber.last loop
              vSourceDescr  := vSourceDescr || TabDmtNumber(i) || ';';
            end loop;
          end if;

          aDMT_NUMBER  := substr(vSourceDescr, 0, length(vSourceDescr) - 1);
        exception
          when others then
            aDMT_NUMBER  := '';
            raise;
        end;
      end if;
    end if;
  end GetTracabilitySource;

  /* Dupplication de la ligne parent */
  procedure PARENT_Dupplication(aGROUP_FIELD number, aNomenclatureDepth integer)
  is
  begin
    insert into FAL_TRACABILITY_PRNT
                (FAL_TRACABILITY_PRNT_ID
               , FTP_GROUP_FIELD
               , GCO_GOOD_ID
               , GCO_GCO_GOOD_ID
               , FAL_LOT_ID
               , DOC_POSITION_ID
               , FTP_GOO_MAJOR_REF
               , FTP_GOO_SECONDARY_REF
               , FTP_NOMENCLATURE_DEPTH
               , FTP_DMT_NUMBER
               , FTP_PT_LOT
               , FTP_LOT_REFCOMPL
               , FTP_LOT_FULL_REL_DTE
               , FTP_PT_PIECE
               , FTP_PT_VERSION
               , FTP_CHRONOLOGY_PT
               , FTP_PT_STD_CHAR_1
               , FTP_PT_STD_CHAR_2
               , FTP_PT_STD_CHAR_3
               , FTP_PT_STD_CHAR_4
               , FTP_PT_STD_CHAR_5
               , FTP_CPT_PIECE
               , FTP_CPT_LOT
               , FTP_CPT_VERSION
               , FTP_CHRONOLOGY_CPT
               , FTP_CPT_STD_CHAR_1
               , FTP_CPT_STD_CHAR_2
               , FTP_CPT_STD_CHAR_3
               , FTP_CPT_STD_CHAR_4
               , FTP_CPT_STD_CHAR_5
               , FTP_PLAN_NUMBER
               , FTP_PLAN_VERSION
               , FTP_VERSION_ORIGIN_NUM
               , FTP_MOVEMENT_DATE
               , FTP_MOVEMENT_QTY
               , FTP_EVEN_TYPE_DESCR
               , FTP_CPT_QUANTITY
               , FAL_TRACABILITY_ID
                )
      select GetNewId
           , aGROUP_FIELD
           , GCO_GOOD_ID
           , GCO_GCO_GOOD_ID
           , FAL_LOT_ID
           , DOC_POSITION_ID
           , FTP_GOO_MAJOR_REF
           , FTP_GOO_SECONDARY_REF
           , FTP_NOMENCLATURE_DEPTH
           , FTP_DMT_NUMBER
           , FTP_PT_LOT
           , FTP_LOT_REFCOMPL
           , FTP_LOT_FULL_REL_DTE
           , FTP_PT_PIECE
           , FTP_PT_VERSION
           , FTP_CHRONOLOGY_PT
           , FTP_PT_STD_CHAR_1
           , FTP_PT_STD_CHAR_2
           , FTP_PT_STD_CHAR_3
           , FTP_PT_STD_CHAR_4
           , FTP_PT_STD_CHAR_5
           , FTP_CPT_PIECE
           , FTP_CPT_LOT
           , FTP_CPT_VERSION
           , FTP_CHRONOLOGY_CPT
           , FTP_CPT_STD_CHAR_1
           , FTP_CPT_STD_CHAR_2
           , FTP_CPT_STD_CHAR_3
           , FTP_CPT_STD_CHAR_4
           , FTP_CPT_STD_CHAR_5
           , FTP_PLAN_NUMBER
           , FTP_PLAN_VERSION
           , FTP_VERSION_ORIGIN_NUM
           , FTP_MOVEMENT_DATE
           , FTP_MOVEMENT_QTY
           , FTP_EVEN_TYPE_DESCR
           , FTP_CPT_QUANTITY
           , FAL_TRACABILITY_ID
        from FAL_TRACABILITY_PRNT
       where FAL_TRACABILITY_PRNT_ID = (select max(FAL_TRACABILITY_PRNT_ID)
                                          from FAL_TRACABILITY_PRNT
                                         where FTP_GROUP_FIELD = aGROUP_FIELD
                                           and FTP_NOMENCLATURE_DEPTH = aNomenclatureDepth - 1);
  end PARENT_Dupplication;

  function ExistsFAL_TRACABILITY(
    aDateParent        in date
  , aDateCre           in date
  , aGoodId            in GCO_GOOD.GCO_GOOD_ID%type
  , aPiece             in STM_ELEMENT_NUMBER.SEM_VALUE%type
  , aLot               in STM_ELEMENT_NUMBER.SEM_VALUE%type
  , aVersion           in STM_ELEMENT_NUMBER.SEM_VALUE%type
  , aChrono            in FAL_TRACABILITY.HIS_CHRONOLOGY_PT%type
  , aHIS_PT_STD_CHAR_1 in FAL_TRACABILITY.HIS_PT_STD_CHAR_1%type
  , aHIS_PT_STD_CHAR_2 in FAL_TRACABILITY.HIS_PT_STD_CHAR_2%type
  , aHIS_PT_STD_CHAR_3 in FAL_TRACABILITY.HIS_PT_STD_CHAR_3%type
  , aHIS_PT_STD_CHAR_4 in FAL_TRACABILITY.HIS_PT_STD_CHAR_4%type
  , aHIS_PT_STD_CHAR_5 in FAL_TRACABILITY.HIS_PT_STD_CHAR_5%type
  )
    return boolean
  is
    aFAL_TRACABILITY_ID number;
  begin
    -- Si DateParent = 0, alors il s'agit d'un composant de premier niveau
    if aDateParent is null then
      return false;
    else
      begin
        select max(TRA.FAL_TRACABILITY_ID)
          into aFAL_TRACABILITY_ID
          from FAL_TRACABILITY TRA
         where TRA.GCO_GOOD_ID = aGoodID
           and nvl(TRA.HIS_PT_PIECE, ' ') = nvl(aPiece, ' ')
           and nvl(TRA.HIS_PT_LOT, ' ') = nvl(aLot, ' ')
           and nvl(TRA.HIS_PT_VERSION, ' ') = nvl(aVersion, ' ')
           and nvl(TRA.HIS_CHRONOLOGY_PT, ' ') = nvl(aChrono, ' ')
           and nvl(TRA.HIS_PT_STD_CHAR_1, ' ') = nvl(aHIS_PT_STD_CHAR_1, ' ')
           and nvl(TRA.HIS_PT_STD_CHAR_2, ' ') = nvl(aHIS_PT_STD_CHAR_2, ' ')
           and nvl(TRA.HIS_PT_STD_CHAR_3, ' ') = nvl(aHIS_PT_STD_CHAR_3, ' ')
           and nvl(TRA.HIS_PT_STD_CHAR_4, ' ') = nvl(aHIS_PT_STD_CHAR_4, ' ')
           and nvl(TRA.HIS_PT_STD_CHAR_5, ' ') = nvl(aHIS_PT_STD_CHAR_5, ' ')
           and TRA.A_DATECRE < aDateParent
           and TRA.A_DATECRE > aDateCre;

        if not(aFAL_TRACABILITY_ID is null) then
          return true;
        else
          return false;
        end if;
      exception
        when others then
          return false;
      end;
    end if;
  end ExistsFAL_TRACABILITY;

  /* Procedure de recherche des mouvements de réception pour un PT */
  procedure AddReceptionMovement(
    aGCO_GOOD_ID           GCO_GOOD.GCO_GOOD_ID%type
  , aLOT_NUMBER            STM_ELEMENT_NUMBER.SEM_VALUE%type
  , aPIECE_NUMBER          STM_ELEMENT_NUMBER.SEM_VALUE%type
  , aVERSION_NUMBER        STM_ELEMENT_NUMBER.SEM_VALUE%type
  , aCHRONO_NUMBER         STM_STOCK_POSITION.SPO_CHRONOLOGICAL%type
  , aFAL_LOT_ID            FAL_LOT.FAL_LOT_ID%type
  , aSTM_STOCK_MOVEMENT_ID STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , nGroupField            integer
  )
  is
    -- Sélection du mouvement aSTM_STOCK_MOVEMENT_ID
    cursor CUR_STOCK_MOVEMENT
    is
      select SMO.SMO_MOVEMENT_DATE
           , SMO.SMO_MOVEMENT_QUANTITY
           , MOK.MOK_ABBREVIATION
           , SMO.STM_STOCK_MOVEMENT_ID
        from STM_STOCK_MOVEMENT SMO
           , STM_MOVEMENT_KIND MOK
       where SMO.STM_STOCK_MOVEMENT_ID = aSTM_STOCK_MOVEMENT_ID
         and SMO.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID;

    -- Sélection des mouvements de réception du lot de fabrication aFAL_LOT_ID
    cursor CUR_LOT_RECEPT_MOVTS(aLOT_REFCOMPL FAL_LOT.LOT_REFCOMPL%type)
    is
      select   SMO.SMO_MOVEMENT_DATE
             , SMO.SMO_MOVEMENT_QUANTITY
             , MOK.MOK_ABBREVIATION
             , SMO.STM_STOCK_MOVEMENT_ID
          from STM_STOCK_MOVEMENT SMO
             , STM_MOVEMENT_KIND MOK
         where SMO.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID
           and SMO.GCO_GOOD_ID = aGCO_GOOD_ID
           and SMO.SMO_WORDING = aLOT_REFCOMPL
           and MOK.C_MOVEMENT_SORT = 'ENT'
           and MOK.C_MOVEMENT_TYPE = 'FAC'
           and MOK.C_MOVEMENT_CODE = '020'
           and (   aLOT_NUMBER is null
                or SMO_SET = aLOT_NUMBER)
           and (   aPIECE_NUMBER is null
                or SMO_PIECE = aPIECE_NUMBER)
           and (   aVERSION_NUMBER is null
                or SMO_VERSION = aVERSION_NUMBER)
           and (   aCHRONO_NUMBER is null
                or SMO_CHRONOLOGICAL = aCHRONO_NUMBER)
      order by SMO.A_DATECRE desc;

    CurStockMovement         CUR_STOCK_MOVEMENT%rowtype;
    CurLotReceptMovts        CUR_LOT_RECEPT_MOVTS%rowtype;
    vGOO_MAJOR_REFERENCE     GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    vGOO_SECONDARY_REFERENCE GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
    vLOT_REFCOMPL            FAL_LOT.LOT_REFCOMPL%type;
  begin
    -- Si lot et mouvement sont null, alors on ne peut associer de mouvement de stocks
    if     (aFAL_LOT_ID is null)
       and (aSTM_STOCK_MOVEMENT_ID is null) then
      null;
    else
      -- Si Mouvement de stock non null (transfert avec Transf. caractérisation), alors on l'affiche.
      if not(aSTM_STOCK_MOVEMENT_ID is null) then
        for CurStockMovement in CUR_STOCK_MOVEMENT loop
          BUILDTRACABILITY_ROW(nGroupField
                             , aGCO_GOOD_ID
                             , aGCO_GOOD_ID
                             , null
                             , null
                             , 0
                             , null
                             , aLOT_NUMBER
                             , null
                             , aPIECE_NUMBER
                             , aVERSION_NUMBER
                             , aCHRONO_NUMBER
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , CurStockMovement.SMO_MOVEMENT_DATE   --MOVEMENT_DTE
                             , CurStockMovement.SMO_MOVEMENT_QUANTITY   --MOVEMENT_QTE
                             , CurStockMovement.MOK_ABBREVIATION   --EVEN_TYPE_DESCR
                             , null
                             , null
                             , CurStockMovement.STM_STOCK_MOVEMENT_ID
                             , null
                              );
        end loop;
      -- Si Lot non null, on affiche les mouvements de réception pour ce produit, lot et caractérisations.
      elsif not(aFAL_LOT_ID is null) then
        -- Référence du lot de fabrication
        begin
          select LOT_REFCOMPL
            into vLOT_REFCOMPL
            from FAL_LOT
           where FAL_LOT_ID = aFAL_LOT_ID;
        exception
          when others then
            begin
              select LOT_REFCOMPL
                into vLOT_REFCOMPL
                from FAL_LOT_HIST
               where FAL_LOT_HIST_ID = aFAL_LOT_ID;
            exception
              when others then
                vLOT_REFCOMPL  := '';
            end;
        end;

        -- Sélection des mouvements
        for CurLotReceptMovts in CUR_LOT_RECEPT_MOVTS(vLOT_REFCOMPL) loop
          BUILDTRACABILITY_ROW(nGroupField
                             , aGCO_GOOD_ID
                             , aGCO_GOOD_ID
                             , null
                             , null
                             , 0
                             , null
                             , aLOT_NUMBER
                             , null
                             , aPIECE_NUMBER
                             , aVERSION_NUMBER
                             , aCHRONO_NUMBER
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , ''
                             , CurLotReceptMovts.SMO_MOVEMENT_DATE   --MOVEMENT_DTE
                             , CurLotReceptMovts.SMO_MOVEMENT_QUANTITY   --MOVEMENT_QTE
                             , CurLotReceptMovts.MOK_ABBREVIATION   --EVEN_TYPE_DESCR
                             , null
                             , null
                             , CurLotReceptMovts.STM_STOCK_MOVEMENT_ID
                             , null
                              );
        end loop;
      end if;
    end if;
  end AddReceptionMovement;

  function GetCharacType(characterization_id gco_characterization.gco_characterization_id%type)
    return char
  is
    cursor CUR_CHARACT_TYPE
    is
      select c_charact_type
        from gco_characterization
       where gco_characterization_id = characterization_id;

    CurCharactType CUR_CHARACT_TYPE%rowtype;
    result         char(1);
  begin
    open CUR_CHARACT_TYPE;

    fetch CUR_CHARACT_TYPE
     into CurCharactType;

    if CUR_CHARACT_TYPE%notfound then
      result  := '';
    else
      result  := CurCharactType.c_charact_type;
    end if;

    close CUR_CHARACT_TYPE;

    return result;
  exception
    when no_data_found then
      return '';
  end GetCharacType;

  function GetASA_RECORD_DESCR(aASA_RECORD_ID ASA_RECORD.ASA_RECORD_ID%type)
    return ASA_RECORD.ARE_NUMBER%type
  is
    vARE_NUMBER ASA_RECORD.ARE_NUMBER%type;
  begin
    select ARE_NUMBER
      into vARE_NUMBER
      from ASA_RECORD
     where ASA_RECORD_ID = aASA_RECORD_ID;

    return vARE_NUMBER;
  exception
    when others then
      return '';
  end;

  /**
  * procedure SelectFactoryFloor
  * Description : Sélection des ateliers via la table COM_LIST_ID_TEMP pour les
  *               impressions fabrication
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFAC_REFERENCE_FROM : référence principale de
  * @param   aFAC_REFERENCE_TO : référence principale à
  */
  procedure SelectFactoryFloor(aFAC_REFERENCE_FROM varchar2, aFAC_REFERENCE_TO varchar2, aDeselectAll integer default 0)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_FACTORY_FLOOR_ID';

    -- Sélection des ID de produits à traiter
    if aDeselectAll = 0 then
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
        select distinct FAC.FAL_FACTORY_FLOOR_ID
                      , 'FAL_FACTORY_FLOOR_ID'
                   from FAL_FACTORY_FLOOR FAC
                  where (    (    aFAC_REFERENCE_FROM is null
                              and aFAC_REFERENCE_TO is null)
                         or FAC.FAC_REFERENCE between nvl(aFAC_REFERENCE_FROM, FAC.FAC_REFERENCE) and nvl(aFAC_REFERENCE_TO, FAC.FAC_REFERENCE)
                        );
    end if;
  end SelectFactoryFloor;

  /**
  * procedure SelectBatches
  * Description : Sélection de lots à imprimer, liste d'ID
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aJOP_REFERENCE_FROM  réf. programme de
  * @param   aJOP_REFERENCE_TO    réf. programme à
  * @param   aORD_REF_FROM        réf ordre de
  * @param   aORD_REF_TO          réf ordre à
  * @param   aLOT_REFCOMPL_FROM   réf lot de
  * @param   aLOT_REFCOMPL_TO     réf lot à
  * @param   aPLANNED_BATCH       lots plannifiés
  * @param   aLAUNCHED_BATCH      lots lancés
  * @param   aBALANCED_BATCH      lots soldés
  * @param   aCreateDateFrom      date création de
  * @param   aCreateDateTo        date création à
  * @param   aPlanBeginDateFrom   date planifiée début de
  * @param   aPlanEndDateTo       date planifiée fin de
  * @param   aLotOpenDateFrom     date lancement de
  * @param   aLotOpenDateTo       date lancement à
  */
  procedure SelectBatches(
    aJOP_REFERENCE_FROM in     varchar2 default null
  , aJOP_REFERENCE_TO   in     varchar2 default null
  , aORD_REF_FROM       in     varchar2 default null
  , aORD_REF_TO         in     varchar2 default null
  , aLOT_REFCOMPL_FROM  in     varchar2 default null
  , aLOT_REFCOMPL_TO    in     varchar2 default null
  , aPLANNED_BATCH      in     integer default 0
  , aLAUNCHED_BATCH     in     integer default 0
  , aBALANCED_BATCH     in     integer default 0
  , aCreateDateFrom     in     date default null
  , aCreateDateTo       in     date default null
  , aPlanBeginDateFrom  in     date default null
  , aPlanEndDateTo      in     date default null
  , aLotOpenDateFrom    in     date default null
  , aLotOpenDateTo      in     date default null
  , aFAL_LOT_IDList     in out varchar2
  )
  is
    cursor crSelectBatches
    is
      select LOT.FAL_LOT_ID
        from FAL_LOT LOT
           , FAL_JOB_PROGRAM JOP
           , FAL_ORDER ORD
       where JOP.FAL_JOB_PROGRAM_ID = ORD.FAL_JOB_PROGRAM_ID
         and ORD.FAL_ORDER_ID = LOT.FAL_ORDER_ID
         and (    (    aJOP_REFERENCE_FROM is null
                   and aJOP_REFERENCE_TO is null)
              or JOP.JOP_REFERENCE between nvl(aJOP_REFERENCE_FROM, JOP.JOP_REFERENCE) and nvl(aJOP_REFERENCE_TO, JOP.JOP_REFERENCE)
             )
         and (    (    aORD_REF_FROM is null
                   and aORD_REF_TO is null)
              or ORD.ORD_REF between nvl(aORD_REF_FROM, ORD.ORD_REF) and nvl(aORD_REF_TO, ORD.ORD_REF) )
         and (    (    aLOT_REFCOMPL_FROM is null
                   and aLOT_REFCOMPL_TO is null)
              or LOT.LOT_REF between nvl(aLOT_REFCOMPL_FROM, LOT.LOT_REF) and nvl(aLOT_REFCOMPL_TO, LOT.LOT_REF)
             )
         and (    (    aCreateDateFrom is null
                   and aCreateDateTo is null)
              or LOT.A_DATECRE between nvl(aCreateDateFrom, LOT.A_DATECRE) and nvl(aCreateDateTo, LOT.A_DATECRE)
             )
         and (    (    aPlanBeginDateFrom is null
                   and aPlanEndDateTo is null)
              or     (LOT.LOT_PLAN_BEGIN_DTE >= nvl(aPlanBeginDateFrom, LOT.LOT_PLAN_BEGIN_DTE) )
                 and (LOT.LOT_PLAN_END_DTE <= nvl(aPlanEndDateTo, LOT.LOT_PLAN_END_DTE) )
             )
         and (    (    aLotOpenDateFrom is null
                   and aLotOpenDateTo is null)
              or LOT.LOT_OPEN__DTE between nvl(aLotOpenDateFrom, LOT.LOT_OPEN__DTE) and nvl(aLotOpenDateTo, LOT.LOT_OPEN__DTE)
             )
         and (    (    aPLANNED_BATCH = 1
                   and LOT.C_LOT_STATUS = '1')
              or (    aLAUNCHED_BATCH = 1
                  and LOT.C_LOT_STATUS = '2')
              or (    aBALANCED_BATCH = 1
                  and LOT.C_LOT_STATUS = '5')
             );
  begin
    aFAL_LOT_IDList  := null;

    for tplSelectBatches in crSelectBatches loop
      exit when length(aFAL_LOT_IDList) > 3985;
      aFAL_LOT_IDList  := aFAL_LOT_IDList || ',' || tplSelectBatches.FAL_LOT_ID;
    end loop;

    aFAL_LOT_IDList  := substr(aFAL_LOT_IDList, 2);
  end SelectBatches;

  /**
  * Description
  *     Sélectionne les lots de fabrications pour l'impression du rapport FAL_BATCHES_COMPONENTS
  */
  procedure InsertSelectedBatchesToPrint(aJobId in out COM_LIST.LIS_JOB_ID%type)
  is
    vJobId     COM_LIST.LIS_JOB_ID%type;
    vSessionID COM_LIST.LIS_SESSION_ID%type;
  begin
    if aJobId is null then
      select INIT_TEMP_ID_SEQ.nextval
        into vJobId
        from dual;
    end if;

    -- Suppression des anciennes valeurs de la table COM_LIST
    COM_PRC_LIST.DeleteIDList(vJobId, vSessionID, 'BATCHES_COMPONENTS');

    -- Récupération des FAL_LOT_ID de la table COM_LIST_ID_TEMP et insertion dans la table COM_LIST pour impression
    for ltplPrint in (select COM_LIST_ID_TEMP_ID
                        from COM_LIST_ID_TEMP list
                       where LID_CODE = 'FAL_LOT_ID') loop
      COM_PRC_LIST.InsertIDList(ltplPrint.COM_LIST_ID_TEMP_ID, 'BATCHES_COMPONENTS', 'Impression des lots', vJobId, vSessionID);
    end loop;

    -- Suppression des anciennes valeurs de la table COM_LIST_ID_TEMP
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_LOT_ID';

    aJobId  := vJobId;
  end InsertSelectedBatchesToPrint;

  /**
  * Description
  *     Sélectionne les composants des lots fabrications pour l'impression du rapport FAL_BATCHES_COMPONENTS
  */
  procedure InsertSelectedCpntsToPrint(aJobId in out COM_LIST.LIS_JOB_ID%type)
  is
    vJobId     COM_LIST.LIS_JOB_ID%type;
    vSessionID COM_LIST.LIS_SESSION_ID%type;
  begin
    if aJobId is null then
      select INIT_TEMP_ID_SEQ.nextval
        into vJobId
        from dual;
    end if;

    -- Suppression des anciennes valeurs de la table COM_LIST
    COM_PRC_LIST.DeleteIDList(vJobId, vSessionID, 'COMPONENTS_BATCHES');

    -- Récupération des GCO_GOOD_ID de la table COM_LIST_ID_TEMP et insertion des FAL_LOT_MATERIAL_LINK_ID dans la table COM_LIST pour impression
    for ltplPrint in (select   LOM.FAL_LOT_MATERIAL_LINK_ID
                          from FAL_LOT LOT
                             , FAL_LOT_MATERIAL_LINK LOM
                         where LOT.FAL_LOT_ID = LOM.FAL_LOT_ID
                           and LOM.GCO_GOOD_ID in(select COM_LIST_ID_TEMP_ID
                                                    from COM_LIST_ID_TEMP list
                                                   where LID_CODE = 'GCO_GOOD_ID')
                           and (   LOT.C_FAB_TYPE = '0'
                                or LOT.C_FAB_TYPE is null)
                      order by LOM.FAL_LOT_MATERIAL_LINK_ID asc) loop
      COM_PRC_LIST.InsertIDList(ltplPrint.FAL_LOT_MATERIAL_LINK_ID, 'COMPONENTS_BATCHES', 'Impression des composants', vJobId, vSessionID);
    end loop;

    -- Suppression des anciennes valeurs de la table COM_LIST_ID_TEMP
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'GCO_GOOD_ID';

    aJobId  := vJobId;
  end InsertSelectedCpntsToPrint;

  /**
  * Description
  *     Sélectionne les lots de fabrications pour l'impression du rapport FAL_BATCHES_COMPONENTS
  */
  procedure InsertBatchesToPrint(
    aJobId          in out COM_LIST.LIS_JOB_ID%type
  , aJobProgramFrom in     FAL_JOB_PROGRAM.JOP_REFERENCE%type default null
  , aJobProgramTo   in     FAL_JOB_PROGRAM.JOP_REFERENCE%type default null
  , aOrderFrom      in     FAL_ORDER.ORD_REF%type default null
  , aOrderTo        in     FAL_ORDER.ORD_REF%type default null
  , aLotFrom        in     FAL_LOT.LOT_REFCOMPL%type default null
  , aLotTo          in     FAL_LOT.LOT_REFCOMPL%type default null
  , aRecordFrom     in     DOC_RECORD.RCO_TITLE%type default null
  , aRecordTo       in     DOC_RECORD.RCO_TITLE%type default null
  )
  is
    vJobId     COM_LIST.LIS_JOB_ID%type;
    vSessionID COM_LIST.LIS_SESSION_ID%type;
  begin
    if aJobId is null then
      select INIT_TEMP_ID_SEQ.nextval
        into vJobId
        from dual;
    end if;

    -- Suppression des anciennes valeurs
    COM_PRC_LIST.DeleteIDList(vJobId, vSessionID, 'BATCHES_COMPONENTS');

    -- insertion des id des lots pour impression
    for ltplPrint in (select distinct LOT.FAL_LOT_ID
                                 from FAL_LOT LOT
                                    , FAL_JOB_PROGRAM JOP
                                    , FAL_ORDER ORD
                                    , DOC_RECORD RCO
                                where LOT.FAL_JOB_PROGRAM_ID = JOP.FAL_JOB_PROGRAM_ID
                                  and ORD.FAL_ORDER_ID = LOT.FAL_ORDER_ID
                                  and RCO.DOC_RECORD_ID(+) = LOT.DOC_RECORD_ID
                                  and (   JOP.C_FAB_TYPE = '0'
                                       or JOP.C_FAB_TYPE is null)
                                  and LOT.C_LOT_STATUS in('1', '2')
                                  and (    (    aJobProgramFrom = 0
                                            and aJobProgramTo = 0)
                                       or JOP.JOP_REFERENCE between nvl(aJobProgramFrom, JOP.JOP_REFERENCE) and nvl(aJobProgramTo, JOP.JOP_REFERENCE)
                                      )
                                  and (    (    aOrderFrom = 0
                                            and aOrderTo = 0)
                                       or ORD.ORD_REF between nvl(aOrderFrom, ORD.ORD_REF) and nvl(aOrderTo, ORD.ORD_REF) )
                                  and (    (    aLotFrom is null
                                            and aLotTo is null)
                                       or LOT.LOT_REFCOMPL between nvl(aLotFrom, LOT.LOT_REFCOMPL) and nvl(aLotTo, LOT.LOT_REFCOMPL)
                                      )
                                  and (    (    aRecordFrom is null
                                            and aRecordTo is null)
                                       or RCO.RCO_TITLE between nvl(aRecordFrom, RCO.RCO_TITLE) and nvl(aRecordTo, RCO.RCO_TITLE)
                                      ) ) loop
      COM_PRC_LIST.InsertIDList(ltplPrint.FAL_LOT_ID, 'BATCHES_COMPONENTS', 'Impression des lots', vJobId, vSessionID);
    end loop;

    aJobId  := vJobId;
  end InsertBatchesToPrint;

  /**
  * Description
  *     Sélectionne les composants des lots de fabrications pour l'impression du rapport FAL_COMPONENTS_BATCHES
  */
  procedure InsertComponentsToPrint(
    aJobId                 in out COM_LIST.LIS_JOB_ID%type
  , aNeedDueDateFrom       in     FAL_LOT_MATERIAL_LINK.LOM_NEED_DATE%type default null
  , aNeedDueDateTo         in     FAL_LOT_MATERIAL_LINK.LOM_NEED_DATE%type default null
  , aComponentFrom         in     GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  , aComponentTo           in     GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  , aRecordFrom            in     DOC_RECORD.RCO_TITLE%type default null
  , aRecordTo              in     DOC_RECORD.RCO_TITLE%type default null
  , aFamilyFrom            in     DIC_FAMILY.DIC_FAMILY_ID%type default null
  , aFamilyTo              in     DIC_FAMILY.DIC_FAMILY_ID%type default null
  , aGoodWordingFrom       in     GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type default null
  , aGoodWordingTo         in     GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type default null
  , aAccountablelGroupFrom in     GCO_GOOD.DIC_ACCOUNTABLE_GROUP_ID%type default null
  , aAccountablelGroupTo   in     GCO_GOOD.DIC_ACCOUNTABLE_GROUP_ID%type default null
  )
  is
    vJobId     COM_LIST.LIS_JOB_ID%type;
    vSessionID COM_LIST.LIS_SESSION_ID%type;
  begin
    if aJobId is null then
      select INIT_TEMP_ID_SEQ.nextval
        into vJobId
        from dual;
    end if;

    -- Suppression des anciennes valeurs
    COM_PRC_LIST.DeleteIDList(vJobId, vSessionID, 'COMPONENTS_BATCHES');

    -- insertion des id des lots pour impression
    for ltplPrint in (select distinct LOM.FAL_LOT_MATERIAL_LINK_ID
                                 from FAL_LOT LOT
                                    , FAL_LOT_MATERIAL_LINK LOM
                                    , FAL_JOB_PROGRAM JOP
                                    , DOC_RECORD RCO
                                    , GCO_GOOD GOO
                                    , GCO_GOOD_CATEGORY CAT
                                where LOT.FAL_JOB_PROGRAM_ID = JOP.FAL_JOB_PROGRAM_ID
                                  and LOM.FAL_LOT_ID(+) = LOT.FAL_LOT_ID
                                  and RCO.DOC_RECORD_ID(+) = LOT.DOC_RECORD_ID
                                  and GOO.GCO_GOOD_ID = LOM.GCO_GOOD_ID
                                  and CAT.GCO_GOOD_CATEGORY_ID = GOO.GCO_GOOD_CATEGORY_ID
                                  and (   JOP.C_FAB_TYPE = '0'
                                       or JOP.C_FAB_TYPE is null)
                                  and LOT.C_LOT_STATUS in('1', '2')
                                  and (    (    aNeedDueDateFrom is null
                                            and aNeedDueDateTo is null)
                                       or LOM.LOM_NEED_DATE between nvl(aNeedDueDateFrom, LOM.LOM_NEED_DATE) and nvl(aNeedDueDateTo, LOM.LOM_NEED_DATE)
                                      )
                                  and (    (    aComponentFrom is null
                                            and aComponentTo is null)
                                       or GOO.GOO_MAJOR_REFERENCE between nvl(aComponentFrom, GOO.GOO_MAJOR_REFERENCE)
                                                                      and nvl(aComponentTo, GOO.GOO_MAJOR_REFERENCE)
                                      )
                                  and (    (    aRecordFrom is null
                                            and aRecordTo is null)
                                       or RCO.RCO_TITLE between nvl(aRecordFrom, RCO.RCO_TITLE) and nvl(aRecordTo, RCO.RCO_TITLE)
                                      )
                                  and (    (    aFamilyFrom is null
                                            and aFamilyTo is null)
                                       or LOT.DIC_FAMILY_ID between nvl(aFamilyFrom, LOT.DIC_FAMILY_ID) and nvl(aFamilyTo, LOT.DIC_FAMILY_ID)
                                      )
                                  and (    (    aGoodWordingFrom is null
                                            and aGoodWordingTo is null)
                                       or CAT.GCO_GOOD_CATEGORY_WORDING between nvl(aGoodWordingFrom, CAT.GCO_GOOD_CATEGORY_WORDING)
                                                                            and nvl(aGoodWordingTo, CAT.GCO_GOOD_CATEGORY_WORDING)
                                      )
                                  and (    (    aAccountablelGroupFrom is null
                                            and aAccountablelGroupTo is null)
                                       or GOO.DIC_ACCOUNTABLE_GROUP_ID between nvl(aAccountablelGroupFrom, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                                                                           and nvl(aAccountablelGroupTo, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                                      ) ) loop
      COM_PRC_LIST.InsertIDList(ltplPrint.FAL_LOT_MATERIAL_LINK_ID, 'COMPONENTS_BATCHES', 'Impression des composants', vJobId, vSessionID);
    end loop;

    aJobId  := vJobId;
  end InsertComponentsToPrint;
end Fal_Print_Procs;
