--------------------------------------------------------
--  DDL for Package Body DOC_TRACABILITY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_TRACABILITY" 
is
  -- retourne true si le PT et le composant du mouvement gère des caractérisations
  function IsPositionTracable(aDetailPositionId in number, aCptPosId out number, aPtPosId out number)
    return boolean
  is
    ptHasChar  number(1) default 0;
    cptHasChar number(1);
  begin
    begin
      select sign(GCO_CHARACTERIZATION_ID)
           , DET.DOC_POSITION_ID
           , DOC_DOC_POSITION_ID
        into cptHasChar
           , aCptPosId
           , aPtPosId
        from DOC_POSITION_DETAIL DET
           , DOC_POSITION POS
           , STM_MOVEMENT_KIND MOK
       where DET.DOC_POSITION_ID = POS.DOC_POSITION_ID
         and DOC_DOC_POSITION_ID is not null
         and POS.C_GAUGE_TYPE_POS in('71', '81')
         and POS.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID
         and MOK.C_MOVEMENT_SORT = 'ENT'
         and DET.DOC_POSITION_DETAIL_ID = aDetailPositionId
         and GCO_CHARACTERIZATION_ID is not null;
    exception
      when no_data_found then
        cptHasChar  := 0;
    end;

    if cptHasChar = 1 then
      select max(nvl(sign(GCO_CHARACTERIZATION_ID), 0) )
        into ptHasChar
        from DOC_POSITION_DETAIL DET
       where DET.DOC_POSITION_ID = aPtPosId
         and GCO_CHARACTERIZATION_ID is not null;
    end if;

    return(    ptHasChar = 1
           and cptHasChar = 1);
  end;

  procedure TracePosition(
    aDetailPositionId in number
  , aGoodId           in number
  , aCharacId1        in number
  , aCharacId2        in number
  , aCharacId3        in number
  , aCharacId4        in number
  , aCharacId5        in number
  , aCharacValue1     in varchar2
  , aCharacValue2     in varchar2
  , aCharacValue3     in varchar2
  , aCharacValue4     in varchar2
  , aCharacValue5     in varchar2
  , aExtourne         in number
  )
  is
    ptPosId        number(12);
    cptPosId       number(12);
    ptPiece        DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    ptLot          DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    ptVersion      DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    ptChrono       DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    cptPiece       DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    cptLot         DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    cptVersion     DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    cptChrono      DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    -- variables internes pour les caractérisations standard
    CharStd1PT     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd2PT     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd3PT     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd4PT     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd5PT     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd1CPT    STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd2CPT    STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd3CPT    STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd4CPT    STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charStd5CPT    STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    charType       varchar2(1);

    cursor ptDetail(ptPositionId number)
    is
      select DMT.DMT_NUMBER
           , POS.GCO_GOOD_ID
           , PDE.GCO_CHARACTERIZATION_ID CHARACID1
           , PDE.GCO_GCO_CHARACTERIZATION_ID CHARACID2
           , PDE.GCO2_GCO_CHARACTERIZATION_ID CHARACID3
           , PDE.GCO3_GCO_CHARACTERIZATION_ID CHARACID4
           , PDE.GCO4_GCO_CHARACTERIZATION_ID CHARACID5
           , PDE.PDE_CHARACTERIZATION_VALUE_1
           , PDE.PDE_CHARACTERIZATION_VALUE_2
           , PDE.PDE_CHARACTERIZATION_VALUE_3
           , PDE.PDE_CHARACTERIZATION_VALUE_4
           , PDE.PDE_CHARACTERIZATION_VALUE_5
           , PDE.PDE_FINAL_QUANTITY
           , PDE.PDE_BALANCE_QUANTITY
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
           , DOC_DOCUMENT DMT
       where PDE.DOC_POSITION_ID = ptPositionId
         and POS.DOC_POSITION_ID = ptPositionId
         and DMT.DOC_DOCUMENT_ID = PDE.DOC_DOCUMENT_ID;

    ptDetail_tuple ptDetail%rowtype;
  begin
    if     aDetailPositionId is not null
       and IsPositionTracable(aDetailPositionId, cptPosId, ptPosId) then
      GCO_I_LIB_CHARACTERIZATION.ClassifyCharacterizations(aCharacId1
                                                         , aCharacId2
                                                         , aCharacId3
                                                         , aCharacId4
                                                         , aCharacId5
                                                         , aCharacValue1
                                                         , aCharacValue2
                                                         , aCharacValue3
                                                         , aCharacValue4
                                                         , aCharacValue5
                                                         , cptPiece
                                                         , cptLot
                                                         , cptVersion
                                                         , cptChrono
                                                         , CharStd1CPT
                                                         , CharStd2CPT
                                                         , CharStd3CPT
                                                         , CharStd4CPT
                                                         , CharStd5CPT
                                                          );

      open ptDetail(ptPosId);

      fetch ptDetail
       into ptDetail_tuple;

      while ptDetail%found loop
        GCO_I_LIB_CHARACTERIZATION.ClassifyCharacterizations(ptDetail_tuple.CharacId1
                                                           , ptDetail_tuple.CharacId2
                                                           , ptDetail_tuple.CharacId3
                                                           , ptDetail_tuple.CharacId4
                                                           , ptDetail_tuple.CharacId5
                                                           , ptDetail_tuple.PDE_CHARACTERIZATION_VALUE_1
                                                           , ptDetail_tuple.PDE_CHARACTERIZATION_VALUE_2
                                                           , ptDetail_tuple.PDE_CHARACTERIZATION_VALUE_3
                                                           , ptDetail_tuple.PDE_CHARACTERIZATION_VALUE_4
                                                           , ptDetail_tuple.PDE_CHARACTERIZATION_VALUE_5
                                                           , ptPiece
                                                           , ptLot
                                                           , ptVersion
                                                           , ptChrono
                                                           , CharStd1PT
                                                           , CharStd2PT
                                                           , CharStd3PT
                                                           , CharStd4PT
                                                           , CharStd5PT
                                                            );

        -- mouvement normal, pas d'extourne
        if aExtourne = 0 then
          insert into FAL_TRACABILITY
                      (FAL_TRACABILITY_ID
                     , GCO_GOOD_ID
                     , GCO_GCO_GOOD_ID
                     , DOC_POSITION_ID
                     , HIS_DOC_NUMBER
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
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (init_id_seq.nextval
                     , aGoodId
                     , ptDetail_tuple.GCO_GOOD_ID
                     , ptPosId
                     ,   -- DOC_POSITION_ID du PT
                       ptdetail_tuple.DMT_NUMBER
                     , ptPiece
                     , ptLot
                     , ptVersion
                     , ptChrono
                     , CharStd1PT
                     , CharStd2PT
                     , CharStd3PT
                     , CharStd4PT
                     , CharStd5PT
                     , cptPiece
                     , cptLot
                     , cptVersion
                     , cptChrono
                     , CharStd1CPT
                     , CharStd2CPT
                     , CharStd3CPT
                     , CharStd4CPT
                     , CharStd5CPT
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        -- mouvement d'extourne
        elsif aExtourne = 1 then
          --seulement si on fait une extourne totale de la position
          if ptDetail_tuple.PDE_BALANCE_QUANTITY = ptDetail_tuple.PDE_FINAL_QUANTITY then
            delete from FAL_TRACABILITY
                  where DOC_POSITION_ID = ptPosId
                    and nvl(HIS_PT_PIECE, ' ') = nvl(ptPiece, ' ')
                    and nvl(HIS_PT_LOT, ' ') = nvl(ptLot, ' ')
                    and nvl(HIS_PT_VERSION, ' ') = nvl(ptVersion, ' ')
                    and nvl(HIS_CHRONOLOGY_PT, ' ') = nvl(ptChrono, ' ')
                    and nvl(HIS_PT_STD_CHAR_1, ' ') = nvl(CharStd1PT, ' ')
                    and nvl(HIS_PT_STD_CHAR_2, ' ') = nvl(CharStd2PT, ' ')
                    and nvl(HIS_PT_STD_CHAR_3, ' ') = nvl(CharStd3PT, ' ')
                    and nvl(HIS_PT_STD_CHAR_4, ' ') = nvl(CharStd4PT, ' ')
                    and nvl(HIS_PT_STD_CHAR_5, ' ') = nvl(CharStd5PT, ' ')
                    and nvl(HIS_CPT_PIECE, ' ') = nvl(cptPiece, ' ')
                    and nvl(HIS_CPT_LOT, ' ') = nvl(cptLot, ' ')
                    and nvl(HIS_CPT_VERSION, ' ') = nvl(cptVersion, ' ')
                    and nvl(HIS_CHRONOLOGY_CPT, ' ') = nvl(cptChrono, ' ')
                    and nvl(HIS_CPT_STD_CHAR_1, ' ') = nvl(CharStd1CPT, ' ')
                    and nvl(HIS_CPT_STD_CHAR_2, ' ') = nvl(CharStd2CPT, ' ')
                    and nvl(HIS_CPT_STD_CHAR_3, ' ') = nvl(CharStd3CPT, ' ')
                    and nvl(HIS_CPT_STD_CHAR_4, ' ') = nvl(CharStd4CPT, ' ')
                    and nvl(HIS_CPT_STD_CHAR_5, ' ') = nvl(CharStd5CPT, ' ');
          end if;
        end if;

        fetch ptDetail
         into ptDetail_tuple;
      end loop;

      close ptDetail;
    end if;
  end;
end;
