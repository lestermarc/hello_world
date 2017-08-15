--------------------------------------------------------
--  DDL for Package Body FAL_LOT_DETAIL_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LOT_DETAIL_FUNCTIONS" 
is
  cInitLotRefCompl constant boolean := PCS.PC_CONFIG.GetBooleanConfig('FAL_INIT_LOTREFCOMPL');

  /**
  * Description
  *   G�n�ration automatique des num�ros de s�rie de d�tail lot pour un lot donn�
  */
  procedure GeneratePieceLotDetailByLot(aLotId in FAL_LOT.FAL_LOT_ID%type)
  is
    cursor crLotInfo(cLotId number)
    is
      select LOT.GCO_GOOD_ID
           , LOT.LOT_TOTAL_QTY
           , LOT.LOT_REFCOMPL
           , nvl(LOT.C_FAB_TYPE, '0') C_FAB_TYPE
        from FAL_LOT LOT
       where LOT.FAL_LOT_ID = cLotId;

    tplLotInfo       crLotInfo%rowtype;
    Charac1Id        FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
    Charac2Id        FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
    Charac3Id        FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
    Charac4Id        FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
    Charac5Id        FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
    CharacType1      GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    CharacType2      GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    CharacType3      GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    CharacType4      GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    CharacType5      GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    CharacVal0       FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    CharacVal1       FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    CharacVal2       FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_2%type;
    CharacVal3       FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_3%type;
    CharacVal4       FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_4%type;
    CharacVal5       FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_5%type;
    CharacStk1       number(1);
    CharacStk2       number(1);
    CharacStk3       number(1);
    CharacStk4       number(1);
    CharacStk5       number(1);
    PieceManagement  number(1);
    IsAlreadyDetails number(1);
  begin
    open crLotInfo(aLotId);

    fetch crLotInfo
     into tplLotInfo;

    if crLotInfo%found then
      -- contr�le qu'il n'existe pas d�j� de d�tails cr��s
      select sign(count(*) )
        into IsAlreadyDetails
        from FAL_LOT_DETAIL
       where FAL_LOT_ID = aLotId
         and nvl(A_CONFIRM, 0) = 0;

      if IsAlreadyDetails = 0 then
        -- recherche la liste des caract�risations du bien du lot
        GCO_LIB_CHARACTERIZATION.GetListOfCharacterization(tplLotInfo.GCO_GOOD_ID
                                                         , 0
                                                         , 'ENT'
                                                         , '2'
                                                         , Charac1Id
                                                         , Charac2Id
                                                         , Charac3Id
                                                         , Charac4Id
                                                         , Charac5Id
                                                         , CharacType1
                                                         , CharacType2
                                                         , CharacType3
                                                         , CharacType4
                                                         , CharacType5
                                                         , CharacStk1
                                                         , CharacStk2
                                                         , CharacStk3
                                                         , CharacStk4
                                                         , CharacStk5
                                                         , PieceManagement
                                                          );

        -- si on a une gestion de pi�ces
        if PieceManagement = 1 then
          begin
            select FAD_CHARACTERIZATION_VALUE_1
                 , FAD_CHARACTERIZATION_VALUE_2
                 , FAD_CHARACTERIZATION_VALUE_3
                 , FAD_CHARACTERIZATION_VALUE_4
                 , FAD_CHARACTERIZATION_VALUE_5
              into CharacVal1
                 , CharacVal2
                 , CharacVal3
                 , CharacVal4
                 , CharacVal5
              from FAL_LOT_DETAIL
             where FAL_LOT_ID = aLotId
               and C_LOT_DETAIL = '1'
               and nvl(A_CONFIRM, 0) = 1;
          exception
            when no_data_found then
              CharacVal1  := null;
              CharacVal2  := null;
              CharacVal3  := null;
              CharacVal4  := null;
              CharacVal5  := null;
          end;

          -- on cr�e autant de d�tails que la quantit� totale
          for i in 1 .. tplLotInfo.LOT_TOTAL_QTY loop
            -- Initialisation des valeurs de caract�risation
            if Charac1Id is not null then
              CharacVal0  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(Charac1Id, null, aLotId);

              if     CharacVal0 is null
                 and CharacType1 = '4'
                 and (   cInitLotRefCompl
                      or tplLotInfo.C_FAB_TYPE = '4') then   -- Demande de reprise de la r�f�rence du lot ou lot de sous-traitance d'achat
                CharacVal1  := tplLotInfo.LOT_REFCOMPL;
              elsif CharacVal0 is not null then
                CharacVal1  := CharacVal0;
              end if;
            end if;

            if Charac2Id is not null then
              CharacVal0  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(Charac2Id, null, aLotId);

              if     CharacVal0 is null
                 and CharacType2 = '4'
                 and (   cInitLotRefCompl
                      or tplLotInfo.C_FAB_TYPE = '4') then   -- Demande de reprise de la r�f�rence du lot ou lot de sous-traitance d'achat
                CharacVal2  := tplLotInfo.LOT_REFCOMPL;
              elsif CharacVal0 is not null then
                CharacVal2  := CharacVal0;
              end if;
            end if;

            if Charac3Id is not null then
              CharacVal0  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(Charac3Id, null, aLotId);

              if     CharacVal0 is null
                 and CharacType3 = '4'
                 and (   cInitLotRefCompl
                      or tplLotInfo.C_FAB_TYPE = '4') then   -- Demande de reprise de la r�f�rence du lot ou lot de sous-traitance d'achat
                CharacVal3  := tplLotInfo.LOT_REFCOMPL;
              elsif CharacVal0 is not null then
                CharacVal3  := CharacVal0;
              end if;
            end if;

            if Charac4Id is not null then
              CharacVal0  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(Charac4Id, null, aLotId);

              if     CharacVal0 is null
                 and CharacType4 = '4'
                 and (   cInitLotRefCompl
                      or tplLotInfo.C_FAB_TYPE = '4') then   -- Demande de reprise de la r�f�rence du lot ou lot de sous-traitance d'achat
                CharacVal4  := tplLotInfo.LOT_REFCOMPL;
              elsif CharacVal0 is not null then
                CharacVal4  := CharacVal0;
              end if;
            end if;

            if Charac5Id is not null then
              CharacVal0  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(Charac5Id, null, aLotId);

              if     CharacVal0 is null
                 and CharacType5 = '4'
                 and (   cInitLotRefCompl
                      or tplLotInfo.C_FAB_TYPE = '4') then   -- Demande de reprise de la r�f�rence du lot ou lot de sous-traitance d'achat
                CharacVal5  := tplLotInfo.LOT_REFCOMPL;
              elsif CharacVal0 is not null then
                CharacVal5  := CharacVal0;
              end if;
            end if;

            -- Si on n'a pas que des caract�risations automatiques on sort
            exit when Charac1Id is null
                  or (    Charac1Id is not null
                      and CharacVal1 is null)
                  or (    Charac2Id is not null
                      and CharacVal2 is null)
                  or (    Charac3Id is not null
                      and CharacVal3 is null)
                  or (    Charac4Id is not null
                      and CharacVal4 is null)
                  or (    Charac5Id is not null
                      and CharacVal5 is null);

            delete from FAL_LOT_DETAIL
                  where FAL_LOT_ID = aLotId
                    and C_LOT_DETAIL = '1'
                    and nvl(A_CONFIRM, 0) = 1;

            insert into FAL_LOT_DETAIL
                        (FAL_LOT_DETAIL_ID
                       , FAL_LOT_ID
                       , GCO_CHARACTERIZATION_ID
                       , GCO_GCO_CHARACTERIZATION_ID
                       , GCO2_GCO_CHARACTERIZATION_ID
                       , GCO3_GCO_CHARACTERIZATION_ID
                       , GCO4_GCO_CHARACTERIZATION_ID
                       , FAD_CHARACTERIZATION_VALUE_1
                       , FAD_CHARACTERIZATION_VALUE_2
                       , FAD_CHARACTERIZATION_VALUE_3
                       , FAD_CHARACTERIZATION_VALUE_4
                       , FAD_CHARACTERIZATION_VALUE_5
                       , GCO_GOOD_ID
                       , C_LOT_DETAIL
                       , GCG_INCLUDE_GOOD
                       , FAD_RECEPT_SELECT
                       , FAD_QTY
                       , FAD_RECEPT_QTY
                       , FAD_BALANCE_QTY
                       , FAD_CANCEL_QTY
                       , FAD_LOT_REFCOMPL
                       , FAD_RECEPT_INPROGRESS_QTY
                       , A_DATECRE
                       , A_IDCRE
                        )
                 values (GetNewId
                       , aLotId
                       , Charac1Id
                       , Charac2Id
                       , Charac3Id
                       , Charac4Id
                       , Charac5Id
                       , CharacVal1
                       , CharacVal2
                       , CharacVal3
                       , CharacVal4
                       , CharacVal5
                       , tplLotInfo.GCO_GOOD_ID
                       , 1   -- C_LOT_DETAIL caract�ris�
                       , 1   -- GCG_INCLUDE_GOOD
                       , 0   -- FAD_RECEPT_SELECT
                       , 1   -- FAD_QTY
                       , 0   -- FAD_RECEPT_QTY
                       , 1   -- FAD_BALANCE_QTY
                       , 0   -- FAD_CANCEL_QTY
                       , tplLotInfo.LOT_REFCOMPL
                       , 0   -- FAD_RECEPT_INPROGRESS_QTY
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                        );
          end loop;
        end if;
      end if;
    end if;

    close crLotInfo;
  end GeneratePieceLotDetailByLot;

  /**
  * procedure CreateBatchDetail
  * Description
  *   Cr�ation de d�tail lot pour un produit caract�ris� lot ou chronologique
  *   (ne doit �tre appel� que si le produit ne contient que des caract�risation
  *   de type Chrono ou Lot avec la configuration FAL_INIT_LOTREFCOMPL � True)
  * @created CLG 10.10.2011
  * @version 2003
  * @lastUpdate
  */
  procedure CreateBatchDetail(aFalLotId in number, aGcoGoodId in number, aQty in number)
  is
    cursor crLotInfo(cLotId number)
    is
      select LOT.GCO_GOOD_ID
           , LOT.LOT_REFCOMPL
           , LOT_INPROD_QTY
           , nvl(LOT.C_FAB_TYPE, '0') C_FAB_TYPE
        from FAL_LOT LOT
       where LOT.FAL_LOT_ID = cLotId;

    tplLotInfo           crLotInfo%rowtype;
    Charac1Id            FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
    Charac2Id            FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
    Charac3Id            FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
    Charac4Id            FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
    Charac5Id            FAL_LOT_DETAIL.GCO_CHARACTERIZATION_ID%type;
    CharacType1          GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    CharacType2          GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    CharacType3          GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    CharacType4          GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    CharacType5          GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    CharacVal0           FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    CharacVal1           FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    CharacVal2           FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_2%type;
    CharacVal3           FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_3%type;
    CharacVal4           FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_4%type;
    CharacVal5           FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_5%type;
    CharacStk1           number(1);
    CharacStk2           number(1);
    CharacStk3           number(1);
    CharacStk4           number(1);
    CharacStk5           number(1);
    PieceManagement      number(1);
    nAlreadyDetails      number(1);
    nQty                 number;
    nAlreadyLotDetailQty number;
    bBatchCharact        boolean;
    bChronoCharact       boolean;
  begin
    open crLotInfo(aFalLotId);

    fetch crLotInfo
     into tplLotInfo;

    if crLotInfo%found then
      -- contr�le qu'il n'existe pas d�j� de d�tails cr��s ou dans le cas des lots de sous-traitance d'achat
      -- que tous les d�tails n'ont pas d�j� �t� cr��s pour l'ensemble de la quantit� en fabrication
      select count(*)
           , nvl(sum(FAD_QTY), 0)
        into nAlreadyDetails
           , nAlreadyLotDetailQty
        from FAL_LOT_DETAIL
       where FAL_LOT_ID = aFalLotId
         and nvl(A_CONFIRM, 0) = 0;

      if    (nAlreadyDetails = 0)
         or (    tplLotInfo.C_FAB_TYPE = FAL_BATCH_FUNCTIONS.btSubcontract
             and nAlreadyLotDetailQty < tplLotInfo.LOT_INPROD_QTY) then
        -- recherche la liste des caract�risations du bien du lot
        GCO_LIB_CHARACTERIZATION.GetListOfCharacterization(tplLotInfo.GCO_GOOD_ID
                                                         , 0
                                                         , 'ENT'
                                                         , '2'
                                                         , Charac1Id
                                                         , Charac2Id
                                                         , Charac3Id
                                                         , Charac4Id
                                                         , Charac5Id
                                                         , CharacType1
                                                         , CharacType2
                                                         , CharacType3
                                                         , CharacType4
                                                         , CharacType5
                                                         , CharacStk1
                                                         , CharacStk2
                                                         , CharacStk3
                                                         , CharacStk4
                                                         , CharacStk5
                                                         , PieceManagement
                                                          );
        bBatchCharact   :=    CharacType1 = '4'
                           or CharacType2 = '4'
                           or CharacType3 = '4'
                           or CharacType4 = '4'
                           or CharacType5 = '4';
        bChronoCharact  :=    CharacType1 = '5'
                           or CharacType2 = '5'
                           or CharacType3 = '5'
                           or CharacType4 = '5'
                           or CharacType5 = '5';

        if    bBatchCharact
           or bChronoCharact then
          begin
            select FAD_CHARACTERIZATION_VALUE_1
                 , FAD_CHARACTERIZATION_VALUE_2
                 , FAD_CHARACTERIZATION_VALUE_3
                 , FAD_CHARACTERIZATION_VALUE_4
                 , FAD_CHARACTERIZATION_VALUE_5
              into CharacVal1
                 , CharacVal2
                 , CharacVal3
                 , CharacVal4
                 , CharacVal5
              from FAL_LOT_DETAIL
             where FAL_LOT_ID = aFalLotId
               and C_LOT_DETAIL = '1'
               and nvl(A_CONFIRM, 0) = 1;
          exception
            when no_data_found then
              CharacVal1  := null;
              CharacVal2  := null;
              CharacVal3  := null;
              CharacVal4  := null;
              CharacVal5  := null;
          end;

          -- En chrono on prend la quantit� pass� en param�tre. Sinon, c'est la quantit� en prod de l'OF.
          if bChronoCharact is not null then
            nQty  := aQty;
          else
            nQty  := tplLotInfo.LOT_INPROD_QTY;
          end if;

          ---------- Si une premi�re caract�risation est d�finie  ----------
          if Charac1Id is not null then
            -- Recherche de sa valeur
            CharacVal0  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(Charac1Id, null, aFalLotId);

            if CharacVal0 is not null then
              CharacVal1  := CharacVal0;
            else   -- si pas de valeur
              -- Si caract�risation de type 4 (lot) et (la config FAL_INIT_LOTREFCOMPL = True ou lot = STA) --> r�f�rence du lot
              if     CharacType1 = GCO_I_LIB_CONSTANT.gcCharacTypeSet
                 and (   cInitLotRefCompl
                      or tplLotInfo.C_FAB_TYPE = FAL_BATCH_FUNCTIONS.btSubcontract) then   -- Demande de reprise de la r�f�rence du lot ou lot de sous-traitance d'achat
                CharacVal1  := tplLotInfo.LOT_REFCOMPL;
              -- si caract�risation de type 5 (chrono)
              elsif CharacType1 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
                CharacVal1  := GCO_LIB_CHARACTERIZATION.PropChronologicalFormat(Charac1Id, sysdate);
              end if;
            end if;
          end if;

          ---------- Si une deuxi�me caract�risation est d�finie  ----------
          if Charac2Id is not null then
            -- Recherche de sa valeur
            CharacVal0  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(Charac2Id, null, aFalLotId);

            if CharacVal0 is not null then
              CharacVal2  := CharacVal0;
            else   -- si pas de valeur
              -- Si caract�risation de type 4 (lot) et (la config FAL_INIT_LOTREFCOMPL = True ou lot = STA) --> r�f�rence du lot
              if     CharacType2 = GCO_I_LIB_CONSTANT.gcCharacTypeSet
                 and (   cInitLotRefCompl
                      or tplLotInfo.C_FAB_TYPE = FAL_BATCH_FUNCTIONS.btSubcontract) then   -- Demande de reprise de la r�f�rence du lot ou lot de sous-traitance d'achat
                CharacVal2  := tplLotInfo.LOT_REFCOMPL;
              -- si caract�risation de type 5 (chrono)
              elsif CharacType2 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
                CharacVal2  := GCO_LIB_CHARACTERIZATION.PropChronologicalFormat(Charac2Id, sysdate);
              end if;
            end if;
          end if;

          ---------- Si une troisi�me caract�risation est d�finie  ----------
          if Charac3Id is not null then
            -- Recherche de sa valeur
            CharacVal0  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(Charac3Id, null, aFalLotId);

            if CharacVal0 is not null then
              CharacVal3  := CharacVal0;
            else   -- si pas de valeur
              -- Si caract�risation de type 4 (lot) et (la config FAL_INIT_LOTREFCOMPL = True ou lot = STA) --> r�f�rence du lot
              if     CharacType3 = GCO_I_LIB_CONSTANT.gcCharacTypeSet
                 and (   cInitLotRefCompl
                      or tplLotInfo.C_FAB_TYPE = FAL_BATCH_FUNCTIONS.btSubcontract) then   -- Demande de reprise de la r�f�rence du lot ou lot de sous-traitance d'achat
                CharacVal3  := tplLotInfo.LOT_REFCOMPL;
              -- si caract�risation de type 5 (chrono)
              elsif CharacType3 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
                CharacVal3  := GCO_LIB_CHARACTERIZATION.PropChronologicalFormat(Charac3Id, sysdate);
              end if;
            end if;
          end if;

          ---------- Si une quatri�me caract�risation est d�finie ----------
          if Charac4Id is not null then
            -- Recherche de sa valeur
            CharacVal0  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(Charac4Id, null, aFalLotId);

            if CharacVal0 is not null then
              CharacVal4  := CharacVal0;
            else   -- si pas de valeur
              -- Si caract�risation de type 4 (lot) et (la config FAL_INIT_LOTREFCOMPL = True ou lot = STA) --> r�f�rence du lot
              if     CharacType4 = GCO_I_LIB_CONSTANT.gcCharacTypeSet
                 and (   cInitLotRefCompl
                      or tplLotInfo.C_FAB_TYPE = FAL_BATCH_FUNCTIONS.btSubcontract) then   -- Demande de reprise de la r�f�rence du lot ou lot de sous-traitance d'achat
                CharacVal4  := tplLotInfo.LOT_REFCOMPL;
              -- si caract�risation de type 5 (chrono)
              elsif CharacType4 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
                CharacVal4  := GCO_LIB_CHARACTERIZATION.PropChronologicalFormat(Charac4Id, sysdate);
              end if;
            end if;
          end if;

          ---------- Si une cinqui�me caract�risation est d�finie  ----------
          if Charac5Id is not null then
            CharacVal0  := GCO_I_LIB_CHARACTERIZATION.GetNextCharValue(Charac5Id, null, aFalLotId);

            if CharacVal0 is not null then
              CharacVal5  := CharacVal0;
            else
              if     CharacType5 = GCO_I_LIB_CONSTANT.gcCharacTypeSet
                 and (   cInitLotRefCompl
                      or tplLotInfo.C_FAB_TYPE = FAL_BATCH_FUNCTIONS.btSubcontract) then
                CharacVal5  := tplLotInfo.LOT_REFCOMPL;
              -- si caract�risation de type 5 (chrono)
              elsif CharacType5 = GCO_I_LIB_CONSTANT.gcCharacTypeChrono then
                CharacVal5  := GCO_LIB_CHARACTERIZATION.PropChronologicalFormat(Charac5Id, sysdate);
              end if;
            end if;
          end if;

          -- Si on n'a pas que des caract�risations automatiques on sort
          if    Charac1Id is null
             or (    Charac1Id is not null
                 and CharacVal1 is null)
             or (    Charac2Id is not null
                 and CharacVal2 is null)
             or (    Charac3Id is not null
                 and CharacVal3 is null)
             or (    Charac4Id is not null
                 and CharacVal4 is null)
             or (    Charac5Id is not null
                 and CharacVal5 is null) then
            return;
          end if;

          delete from FAL_LOT_DETAIL
                where FAL_LOT_ID = aFalLotId
                  and C_LOT_DETAIL = '1'
                  and nvl(A_CONFIRM, 0) = 1;

          insert into FAL_LOT_DETAIL
                      (FAL_LOT_DETAIL_ID
                     , FAL_LOT_ID
                     , GCO_CHARACTERIZATION_ID
                     , GCO_GCO_CHARACTERIZATION_ID
                     , GCO2_GCO_CHARACTERIZATION_ID
                     , GCO3_GCO_CHARACTERIZATION_ID
                     , GCO4_GCO_CHARACTERIZATION_ID
                     , FAD_CHARACTERIZATION_VALUE_1
                     , FAD_CHARACTERIZATION_VALUE_2
                     , FAD_CHARACTERIZATION_VALUE_3
                     , FAD_CHARACTERIZATION_VALUE_4
                     , FAD_CHARACTERIZATION_VALUE_5
                     , GCO_GOOD_ID
                     , C_LOT_DETAIL
                     , GCG_INCLUDE_GOOD
                     , FAD_RECEPT_SELECT
                     , FAD_QTY
                     , FAD_RECEPT_QTY
                     , FAD_BALANCE_QTY
                     , FAD_CANCEL_QTY
                     , FAD_LOT_REFCOMPL
                     , FAD_RECEPT_INPROGRESS_QTY
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (GetNewId
                     , aFalLotId
                     , Charac1Id
                     , Charac2Id
                     , Charac3Id
                     , Charac4Id
                     , Charac5Id
                     , CharacVal1
                     , CharacVal2
                     , CharacVal3
                     , CharacVal4
                     , CharacVal5
                     , tplLotInfo.GCO_GOOD_ID
                     , 1   -- C_LOT_DETAIL caract�ris�
                     , 1   -- GCG_INCLUDE_GOOD
                     , 0   -- FAD_RECEPT_SELECT
                     , nQty   -- FAD_QTY
                     , 0   -- FAD_RECEPT_QTY
                     , nQty   -- FAD_BALANCE_QTY
                     , 0   -- FAD_CANCEL_QTY
                     , tplLotInfo.LOT_REFCOMPL
                     , 0   -- FAD_RECEPT_INPROGRESS_QTY
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );
        end if;
      end if;
    end if;
  end CreateBatchDetail;

  function getLotProgressDetailId(
    iLotProgressId     FAL_LOT_PROGRESS.FAL_LOT_PROGRESS_ID%type
  , iLotDetailId       FAL_LOT_DETAIL.FAL_LOT_DETAIL_ID%type
  , iQty               FAL_LOT_PROGRESS_DETAIL.LPD_QTY%type
  , iCDetailType       FAL_LOT_PROGRESS_DETAIL.C_LOT_DETAIL_TYPE%type
  , iDicRebutId        FAL_LOT_PROGRESS_DETAIL.DIC_REBUT_ID%type default null
  , iRejectDescription FAL_LOT_PROGRESS_DETAIL.LPD_REJECT_DESCRIPTION%type default null
  )
    return FAL_LOT_PROGRESS_DETAIL.FAL_LOT_PROGRESS_DETAIL_ID%type
  as
    lErrorCode           varchar2(2000);
    lLotProgressDetailID FAL_LOT_PROGRESS_DETAIL.FAL_LOT_PROGRESS_DETAIL_ID%type;
  begin
    select max(FAL_LOT_PROGRESS_DETAIL_ID)
      into lLotProgressDetailID
      from FAL_LOT_PROGRESS_DETAIL
     where FAL_LOT_PROGRESS_ID = iLotProgressId
       and FAL_LOT_DETAIL_ID = iLotDetailId
       and C_LOT_DETAIL_TYPE = iCDetailType;

    if     nvl(lLotProgressDetailID, 0) = 0
       and nvl(iQty, 0) > 0 then
      CreateProgressTrackingDetail(aFalLotProgressId         => iLotProgressId
                                 , aFalLotDetailId           => iLotDetailId
                                 , aQty                      => iQty
                                 , aDetailType               => iCDetailType
                                 , aDicRebutId               => iDicRebutId
                                 , aRejectDescription        => iRejectDescription
                                 , aErrorCode                => lErrorCode
                                 , aFalLotProgressDetailId   => lLotProgressDetailID
                                  );
    end if;

    return lLotProgressDetailID;
  end getLotProgressDetailId;

  /**
  * procedure CreateProgressTrackingDetail
  * Description
  *   Cr�ation d'un nouveau d�tail de suivi fabrication
  * @created CLE
  * @version 2007
  * @lastUpdate
  * @public
  * @param      aFalLotProgressId             Id du suivi de fabrication
  * @param      aFalLotDetailId               Id du d�tail lot
  * @param      aQty                          Qt� du d�tail suivi
  * @param      aDetailType                   Type de d�tail suivi
  * @param      aDicRebutId                   Code rebut PT ou CPT
  * @param      aRejectDescription            Description du rebut
  * @return     aErrorCode                    Code d'erreur de retour
  * @return     aFalLotProgressDetailId       ID du nouveau d�tail de suivi cr��
  */
  procedure CreateProgressTrackingDetail(
    aFalLotProgressId              fal_lot_progress.fal_lot_progress_id%type
  , aFalLotDetailId                fal_lot_detail.fal_lot_detail_id%type default null
  , aQty                           number
  , aDetailType                    fal_lot_progress_detail.c_lot_detail_type%type
  , aDicRebutId                    fal_lot_progress_detail.dic_rebut_id%type default null
  , aRejectDescription             fal_lot_progress_detail.lpd_reject_description%type default null
  , aErrorCode              in out varchar2
  , aFalLotProgressDetailId in out number
  )
  is
    BalanceQty number;
  begin
    select (select fad_qty
              from fal_lot_detail
             where fal_lot_detail_id = aFalLotDetailId) - (select sum(lpd_qty)
                                                             from fal_lot_progress_detail
                                                            where fal_lot_progress_id = aFalLotProgressId
                                                              and fal_lot_detail_id = aFalLotDetailId)
      into BalanceQty
      from dual;

    if aQty > BalanceQty then
      raise_application_error(-20010, 'PCS - ' || excProgressTrackDetailMsg);
    end if;

    aFalLotProgressDetailId  := getNewId;

    insert into fal_lot_progress_detail
                (fal_lot_progress_detail_id
               , fal_lot_progress_id
               , fal_lot_detail_id
               , c_lot_detail_type
               , lpd_qty
               , dic_rebut_id
               , lpd_reject_description
               , a_datecre
               , a_idcre
                )
         values (aFalLotProgressDetailId
               , aFalLotProgressId
               , aFalLotDetailId
               , aDetailType
               , aQty
               , aDicRebutId
               , aRejectDescription
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    if aDetailType in(tdRejectPT, tdRejectCPT) then
      update FAL_LOT_DETAIL
         set FAD_MORPHO_REJECT_QTY = nvl(FAD_MORPHO_REJECT_QTY, 0) + aQty
           , FAD_BALANCE_QTY = nvl(FAD_BALANCE_QTY, 0) - aQty
       where FAL_LOT_DETAIL_ID = aFalLotDetailId;
    end if;
  exception
    when excProgressTrackDetail then
      aErrorCode  := 'excProgressTrackDetail';
  end;

  /**
  * procedure DeleteProgressTrackingDetail
  * Description
  *   Suppression d'un d�tail de suivi d'avancement de fabrication
  * @created CLE
  * @version 2007
  * @lastUpdate
  * @public
  * @param      aFalLotProgressDetailId   Id du d�tail de suivi d'avancement de fabrication
  */
  procedure DeleteProgressTrackingDetail(aFalLotProgressDetailId fal_lot_progress_detail.fal_lot_progress_detail_id%type)
  is
  begin
    delete from FAL_LOT_DETAIL_LINK
          where FAL_LOT_PROGRESS_DETAIL_ID = aFalLotProgressDetailId;

    delete from FAL_LOT_PROGRESS_DETAIL
          where FAL_LOT_PROGRESS_DETAIL_ID = aFalLotProgressDetailId;
  end;

  /**
  * procedure UpdateAlignementOnMvtComponent
  * Description
  *   Mise � jour d'un appairage lors d'un mouvement de composant (d�montage, retour, ...). Suppression si sa quantit� est � 0.
  * @created CLE
  * @version 2007
  * @lastUpdate
  * @public
  * @param      iSessionID  Session Oracle de mouvement de composants
  */
  procedure UpdateAlignementOnMvtComponent(iSessionID FAL_COMPONENT_LINK.FCL_SESSION%type)
  is
    cursor crComponentLink
    is
      select DET.FAL_LOT_DETAIL_LINK_ID
           , nvl(FCL.FCL_HOLD_QTY, 0) + nvl(FCL.FCL_RETURN_QTY, 0) + nvl(FCL.FCL_TRASH_QTY, 0) FCL_QTY
           , DET.LDL_QTY
        from FAL_COMPONENT_LINK FCL
           , FAL_LOT_DETAIL_LINK DET
       where FCL_SESSION = iSessionId
         and FCL.FAL_FACTORY_IN_ID = DET.FAL_FACTORY_IN_ID;
  begin
    for tplComponentLink in crComponentLink loop
      if tplComponentLink.FCL_QTY < tplComponentLink.LDL_QTY then
        update FAL_LOT_DETAIL_LINK
           set LDL_QTY = LDL_QTY - tplComponentLink.FCL_QTY
         where FAL_LOT_DETAIL_LINK_ID = tplComponentLink.FAL_LOT_DETAIL_LINK_ID;
      else
        delete      FAL_LOT_DETAIL_LINK
              where FAL_LOT_DETAIL_LINK_ID = tplComponentLink.FAL_LOT_DETAIL_LINK_ID;
      end if;
    end loop;
  end;
end FAL_LOT_DETAIL_FUNCTIONS;
