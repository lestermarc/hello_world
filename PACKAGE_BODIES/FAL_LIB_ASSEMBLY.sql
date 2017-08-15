--------------------------------------------------------
--  DDL for Package Body FAL_LIB_ASSEMBLY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_ASSEMBLY" 
is
  /**
  * Description
  *    Retourne les valeurs de caractérisation à l'oigine de la traçabilité
  */
  procedure getOriginTracability(
    iGoodId         in     GCO_GOOD.GCO_GOOD_ID%type
  , ioSet           in out varchar2
  , ioPiece         in out varchar2
  , ioVersion       in out varchar2
  , ioChronological in out varchar2
  , ioCharStd1      in out varchar2
  , ioCharStd2      in out varchar2
  , ioCharStd3      in out varchar2
  , ioCharStd4      in out varchar2
  , ioCharStd5      in out varchar2
  )
  is
  begin
    for tplTracability in (select C_TRACABILITY_SOURCE
                                , HIS_CPT_LOT
                                , HIS_CPT_PIECE
                                , HIS_CPT_VERSION
                                , HIS_CHRONOLOGY_CPT
                                , HIS_CPT_STD_CHAR_1
                                , HIS_CPT_STD_CHAR_2
                                , HIS_CPT_STD_CHAR_3
                                , HIS_CPT_STD_CHAR_4
                                , HIS_CPT_STD_CHAR_5
                             from FAL_TRACABILITY
                            where GCO_GOOD_ID = iGoodId
                              and nvl(HIS_DISASSEMBLED_PDT, 0) = 0
                              and nvl(HIS_PT_LOT, ' ') = nvl(ioSet, ' ')
                              and nvl(HIS_PT_PIECE, ' ') = nvl(ioPiece, ' ')
                              and nvl(HIS_PT_VERSION, ' ') = nvl(ioVersion, ' ')
                              and nvl(HIS_CHRONOLOGY_PT, ' ') = nvl(ioChronological, ' ')
                              and nvl(HIS_PT_STD_CHAR_1, ' ') = nvl(ioCharStd1, ' ')
                              and nvl(HIS_PT_STD_CHAR_2, ' ') = nvl(ioCharStd2, ' ')
                              and nvl(HIS_PT_STD_CHAR_3, ' ') = nvl(ioCharStd3, ' ')
                              and nvl(HIS_PT_STD_CHAR_4, ' ') = nvl(ioCharStd4, ' ')
                              and nvl(HIS_PT_STD_CHAR_5, ' ') = nvl(ioCharStd5, ' ') ) loop
      if tplTracability.C_TRACABILITY_SOURCE <> 'FAL' then
        ioSet            := tplTracability.HIS_CPT_LOT;
        ioPiece          := tplTracability.HIS_CPT_PIECE;
        ioVersion        := tplTracability.HIS_CPT_VERSION;
        ioChronological  := tplTracability.HIS_CHRONOLOGY_CPT;
        ioCharStd1       := tplTracability.HIS_CPT_STD_CHAR_1;
        ioCharStd2       := tplTracability.HIS_CPT_STD_CHAR_2;
        ioCharStd3       := tplTracability.HIS_CPT_STD_CHAR_3;
        ioCharStd4       := tplTracability.HIS_CPT_STD_CHAR_4;
        ioCharStd5       := tplTracability.HIS_CPT_STD_CHAR_5;
        -- Appel récursif pour trouver la source
        getOriginTracability(iGoodId, ioSet, ioPiece, ioVersion, ioChronological, ioCharStd1, ioCharStd2, ioCharStd3, ioCharStd4, ioCharStd5);
      end if;
    end loop;
  end getOriginTracability;
end FAL_LIB_ASSEMBLY;
