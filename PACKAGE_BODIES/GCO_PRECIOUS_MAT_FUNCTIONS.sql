--------------------------------------------------------
--  DDL for Package Body GCO_PRECIOUS_MAT_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_PRECIOUS_MAT_FUNCTIONS" 
is
  /**
  * Description
  *     Recherche l'ID de nomenclature pour un bien
  */
  function GetNomenclature(aGoodID number)
    return number
  is
    NomenclatureID number;
  begin
    select nvl(max(PPS_NOMENCLATURE_ID), 0) PPS_NOMENCLATURE_ID
      into NomenclatureID
      from PPS_NOMENCLATURE
     where GCO_GOOD_ID = aGoodID
       and NOM_DEFAULT = 1
       and C_TYPE_NOM in('2', '3', '4');

    return NomenclatureID;
  end GetNomenclature;

  /**
  * Description
  *     M�j des poids investis et copeaux
  */
  procedure UpdateWeightAndChip(iInactivePDT in integer default 0, iSuspendedPdt in integer default 0)
  is
    -- Liste de tous les GCO_GOOD_ID de GCO_PRECIOUS_LEVEL pour le niveau 1000
    cursor crGetGoodLevel_1000
    is
      select GOO.GCO_GOOD_ID
           , GPM.GPM_WEIGHT_DELIVER
           , GPM.GPM_WEIGHT_DELIVER_VALUE
           , GPM.GPM_WEIGHT_INVEST
           , GPM.GPM_WEIGHT_INVEST_VALUE
           , GPM.GPM_WEIGHT_INVEST_TOTAL
           , GPM.GPM_WEIGHT_INVEST_TOTAL_VALUE
           , GPM.GPM_WEIGHT_CHIP
           , GPM.GPM_WEIGHT_CHIP_TOTAL
           , GPM.GPM_LOSS_TOTAL
           , GPM.GPM_LOSS_UNIT
           , GPM.GPM_STONE_NUMBER
           , GPM.GCO_ALLOY_ID
        from GCO_GOOD GOO
           , PPS_INTERRO_ALLOY GPM
       where GOO.GCO_GOOD_ID = GPM.GCO_GOOD_ID
         and (    (    iSuspendedPdt = 0
                   and GOO.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive)
              or (    iSuspendedPdt = 1
                  and GOO.C_GOOD_STATUS in(GCO_I_LIB_CONSTANT.gcGoodStatusActive, GCO_I_LIB_CONSTANT.gcGoodStatusSuspended) )
             )
         and GOO.GOO_PRECIOUS_MAT = 1
         and not exists(select GSV.GCO_GOOD_ID
                          from GCO_SERVICE GSV
                         where GSV.GCO_GOOD_ID = GOO.GCO_GOOD_ID)
         and not exists(select NOM.GCO_GOOD_ID
                          from PPS_NOMENCLATURE NOM
                         where NOM.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                           and NOM.C_TYPE_NOM = '2')
         and GOO.GCO_GOOD_ID in(select GCO_GOOD_ID
                                  from PPS_INTERROGATION);

    -- Liste de tous les GCO_GOOD_ID de GCO_PRECIOUS_LEVEL pour le niveau  <> 1000
    cursor crGetGoodLevelNot1000
    is
      select   GPL.GCO_GOOD_ID
             , GCO.C_SUPPLY_MODE
          from PPS_INTERROGATION GPL
             , GCO_PRODUCT GCO
         where GPL.GCO_GOOD_ID = GCO.GCO_GOOD_ID
           and GCO.GCO_GOOD_ID not in(
                 select GOO.GCO_GOOD_ID
                   from GCO_GOOD GOO
                  where (    (    iSuspendedPdt = 0
                              and GOO.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive)
                         or (    iSuspendedPdt = 1
                             and GOO.C_GOOD_STATUS in(GCO_I_LIB_CONSTANT.gcGoodStatusActive, GCO_I_LIB_CONSTANT.gcGoodStatusSuspended) )
                        )
                    and GOO.GOO_PRECIOUS_MAT = 1
                    and not exists(select GSV.GCO_GOOD_ID
                                     from GCO_SERVICE GSV
                                    where GSV.GCO_GOOD_ID = GOO.GCO_GOOD_ID)
                    and not exists(select NOM.GCO_GOOD_ID
                                     from PPS_NOMENCLATURE NOM
                                    where NOM.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                                      and NOM.C_TYPE_NOM = '2')
                    and GOO.GCO_GOOD_ID in(select GCO_GOOD_ID
                                             from PPS_INTERROGATION) )
      order by GPL.PPI_LEVEL desc
             , GPL.PPS_INTERROGATION_ID asc;

    -- Liste de toutes les mati�res pr�c. pour le GCO_GOOD_ID donn�
    cursor crGetPreciousMat(cGoodID number)
    is
      select GCO_ALLOY_ID
           , GPM_WEIGHT_DELIVER_AUTO
           , GPM_WEIGHT_DELIVER
           , GPM_LOSS_TOTAL
           , GPM_STONE_NUMBER
        from PPS_INTERRO_ALLOY
       where GCO_GOOD_ID = cGoodID;

    -- Liste des cpt du bien avec la m�me mati�re
    cursor crCptPreciousMat(cNomenclatureID number, cAlloyID number)
    is
      select nvl(GPM.GPM_WEIGHT_DELIVER, 0) GPM_WEIGHT_DELIVER
           , nvl(GPM.GPM_WEIGHT_INVEST_TOTAL, 0) GPM_WEIGHT_INVEST_TOTAL
           , nvl(GPM.GPM_WEIGHT_CHIP_TOTAL, 0) GPM_WEIGHT_CHIP_TOTAL
           , nvl(GPM.GPM_LOSS_TOTAL, 0) GPM_LOSS_TOTAL
           , nvl(GPM.GPM_WEIGHT_DELIVER_VALUE, 0) GPM_WEIGHT_DELIVER_VALUE
           , nvl(GPM.GPM_WEIGHT_INVEST_TOTAL_VALUE, 0) GPM_WEIGHT_INVEST_TOTAL_VALUE
           , nvl(GPM.GPM_STONE_NUMBER, 0) GPM_STONE_NUMBER
           , nvl(nvl(CPU.CDA_NUMBER_OF_DECIMAL, GOO.GOO_NUMBER_OF_DECIMAL), 0) NUMBER_DECIMAL
           , nvl(COM.COM_UTIL_COEFF, 1) COM_UTIL_COEFF
           , nvl(COM.COM_REF_QTY, 1) COM_REF_QTY
           , GPM.GCO_ALLOY_ID
        from PPS_NOM_BOND COM
           , PPS_INTERRO_ALLOY GPM
           , GCO_GOOD GOO
           , GCO_COMPL_DATA_PURCHASE CPU
       where COM.PPS_NOMENCLATURE_ID = cNomenclatureID
         and COM.C_KIND_COM in('1', '3')
         and COM.C_TYPE_COM = '1'
         and GPM.GCO_GOOD_ID = COM.GCO_GOOD_ID
         and GPM.GCO_ALLOY_ID = cAlloyID
         and COM.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and GOO.GCO_GOOD_ID = CPU.GCO_GOOD_ID(+)
         and GOO.GOO_PRECIOUS_MAT = 1
         and CPU.CPU_DEFAULT_SUPPLIER(+) = 1
         and nvl(GPM.C_GPM_UPDATE_TYPE, 0) <> PPS_LIB_INTERRO.cGpmUpdateTypeDelete;

    NomenclatureID              number;
    iCpuPrecMatValue            integer;
    vQuantity                   number;
    vPIT                        number;   -- Poids livr� th�orique                      GPM_WEIGHT_DELIVER
    vPITT                       number;   -- Poids investi th�orique total              GPM_WEIGHT_INVEST_TOTAL
    vPCTT                       number;   -- Poids copeaux th�orique total              GPM_WEIGHT_CHIP_TOTAL
    vPTT                        number;   -- Perte th�orique totale                     GPM_LOSS_TOTAL
    vPITV                       number;   -- Poids livr� th�orique valorisable          GPM_WEIGHT_DELIVER_VALUE
    vPITTV                      number;   -- Poids investi th�orique total valorisable  GPM_WEIGHT_INVEST_TOTAL_VALUE
    VSN                         number;   -- Nombre de pierre                           GPM_STONE_NUMBER
    newGPM_WEIGHT_DELIVER       GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER%type;
    newGPM_WEIGHT_DELIVER_VALUE GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER_VALUE%type;
    newGPM_WEIGHT_INVEST        GCO_PRECIOUS_MAT.GPM_WEIGHT_INVEST%type;
    newGPM_WEIGHT_INVEST_VALUE  GCO_PRECIOUS_MAT.GPM_WEIGHT_INVEST_VALUE%type;
    newGPM_WEIGHT_CHIP          GCO_PRECIOUS_MAT.GPM_WEIGHT_CHIP%type;
    newGPM_WEIGHT_INVEST_TOTAL  GCO_PRECIOUS_MAT.GPM_WEIGHT_INVEST_TOTAL%type;
    newGPM_WEIGHT_INVEST_TOT_V  GCO_PRECIOUS_MAT.GPM_WEIGHT_INVEST_TOTAL_VALUE%type;
    newGPM_WEIGHT_CHIP_TOTAL    GCO_PRECIOUS_MAT.GPM_WEIGHT_CHIP_TOTAL%type;
    newGPM_LOSS_TOTAL           GCO_PRECIOUS_MAT.GPM_LOSS_TOTAL%type;
    newGPM_STONE_NUMBER         GCO_PRECIOUS_MAT.GPM_STONE_NUMBER%type;
    valGPM_WEIGHT_DELIVER_AUTO  GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER_AUTO%type;
    valGPM_WEIGHT_DELIVER       GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER%type;
    valGPM_LOSS_UNIT            GCO_PRECIOUS_MAT.GPM_LOSS_UNIT%type;
    valGPM_STONE_NUMBER         GCO_PRECIOUS_MAT.GPM_STONE_NUMBER%type;
    lbMatFounded                boolean;
  begin
    newGPM_WEIGHT_DELIVER        := 0;
    newGPM_WEIGHT_DELIVER_VALUE  := 0;
    newGPM_WEIGHT_INVEST         := 0;
    newGPM_WEIGHT_INVEST_VALUE   := 0;
    newGPM_WEIGHT_CHIP           := 0;
    newGPM_WEIGHT_INVEST_TOTAL   := 0;
    newGPM_WEIGHT_INVEST_TOT_V   := 0;
    newGPM_WEIGHT_CHIP_TOTAL     := 0;
    newGPM_LOSS_TOTAL            := 0;
    newGPM_STONE_NUMBER          := 0;

    -- Tous les bien de la table des niveaux avec le niveau � 1000
    for tplGoodLevel in crGetGoodLevel_1000 loop
      select nvl(max(CPU_PRECIOUS_MAT_VALUE), 0)
        into iCpuPrecMatValue
        from GCO_COMPL_DATA_PURCHASE
       where GCO_GOOD_ID = tplGoodLevel.GCO_GOOD_ID
         and CPU_DEFAULT_SUPPLIER = 1;

      PPS_I_PRC_INTERRO.MergeGoodInterroAlloy(iGcoGoodId                       => tplGoodLevel.GCO_GOOD_ID
                                            , iGcoAlloyId                      => tplGoodLevel.GCO_ALLOY_ID
                                            , iGPM_WEIGHT_DELIVER              => tplGoodLevel.GPM_WEIGHT_DELIVER
                                            , iGPM_WEIGHT_DELIVER_VALUE        => (case
                                                                                     when iCpuPrecMatValue = 1 then 0
                                                                                     else tplGoodLevel.GPM_WEIGHT_DELIVER
                                                                                   end)
                                            , iGPM_WEIGHT_INVEST               => tplGoodLevel.GPM_WEIGHT_DELIVER +
                                                                                  tplGoodLevel.GPM_LOSS_UNIT +
                                                                                  nvl(tplGoodLevel.GPM_WEIGHT_CHIP, 0)
                                            , iGPM_WEIGHT_INVEST_VALUE         => (case
                                                                                     when iCpuPrecMatValue = 1 then 0
                                                                                     else tplGoodLevel.GPM_WEIGHT_DELIVER +
                                                                                          tplGoodLevel.GPM_LOSS_UNIT +
                                                                                          nvl(tplGoodLevel.GPM_WEIGHT_CHIP, 0)
                                                                                   end
                                                                                  )
                                            , iGPM_WEIGHT_INVEST_TOTAL         => tplGoodLevel.GPM_WEIGHT_DELIVER +
                                                                                  tplGoodLevel.GPM_LOSS_UNIT +
                                                                                  nvl(tplGoodLevel.GPM_WEIGHT_CHIP, 0)
                                            , iGPM_WEIGHT_INVEST_TOTAL_VALUE   => (case
                                                                                     when iCpuPrecMatValue = 1 then 0
                                                                                     else tplGoodLevel.GPM_WEIGHT_DELIVER +
                                                                                          tplGoodLevel.GPM_LOSS_UNIT +
                                                                                          nvl(tplGoodLevel.GPM_WEIGHT_CHIP, 0)
                                                                                   end
                                                                                  )
                                            , iGPM_WEIGHT_CHIP                 => tplGoodLevel.GPM_WEIGHT_CHIP
                                            , iGPM_WEIGHT_CHIP_TOTAL           => tplGoodLevel.GPM_WEIGHT_CHIP_TOTAL
                                            , iGPM_LOSS_TOTAL                  => tplGoodLevel.GPM_LOSS_UNIT
                                            , iGPM_STONE_NUMBER                => tplGoodLevel.GPM_STONE_NUMBER
                                             );
    end loop;

    -- Tous les biens de la table des niveaux avec le niveau <> 1000
    for tplGoodLevel in crGetGoodLevelNot1000 loop
      -- Si le mode d'appro du produit est diff�rent de achet�
      if tplGoodLevel.C_SUPPLY_MODE <> '1' then
        -- Recherche la nomenclature par d�faut du bien
        NomenclatureID  := GetNomenclature(tplGoodLevel.GCO_GOOD_ID);

        -- Pour chaque mati�re du bien
        for tplPreciousMat in crGetPreciousMat(tplGoodLevel.GCO_GOOD_ID) loop
          vPIT                        := 0;   -- Poids livr� th�orique
          vPITT                       := 0;   -- Poids investi th�orique total
          vPCTT                       := 0;   -- Poids copeaux th�orique total
          vPTT                        := 0;   -- Perte th�orique totale
          vPITV                       := 0;   -- Poids livr� th�orique valorisable
          vPITTV                      := 0;   -- Poids investi th�orique total valorisable
          vSN                         := 0;   -- Nombre de pierres
          -- Pour chaque composant avec la mati�re donn�e
          lbMatFounded                := false;

          for tplCptPreciousMat in crCptPreciousMat(NomenclatureID, tplPreciousMat.GCO_ALLOY_ID) loop
            lbMatFounded  := true;
            -- Qt� = Coeff. Utilisation / Qt� R�f. Nomenclature  => Arrondi inf�rieur
            vQuantity     := tplCptPreciousMat.COM_UTIL_COEFF / tplCptPreciousMat.COM_REF_QTY;
            -- Poids livr� th�orique
            vPIT          := vPIT +(tplCptPreciousMat.GPM_WEIGHT_DELIVER * vQuantity);
            -- Poids investi th�orique total
            vPITT         := vPITT +(tplCptPreciousMat.GPM_WEIGHT_INVEST_TOTAL * vQuantity);
            -- Poids copeaux th�orique total
            vPCTT         := vPCTT +(tplCptPreciousMat.GPM_WEIGHT_CHIP_TOTAL * vQuantity);
            -- Perte th�orique totale
            vPTT          := vPTT +(tplCptPreciousMat.GPM_LOSS_TOTAL * vQuantity);
            -- Poids livr� th�orique valorisable
            vPITV         := vPITV +(tplCptPreciousMat.GPM_WEIGHT_DELIVER_VALUE * vQuantity);
            -- Poids investi th�orique total valorisable
            vPITTV        := vPITTV +(tplCptPreciousMat.GPM_WEIGHT_INVEST_TOTAL_VALUE * vQuantity);
            -- Nombre de pierre
            vSN           := vSN +(tplCptPreciousMat.GPM_STONE_NUMBER * vQuantity);
          end loop;

          -- Recherche certaine valeur sur le mati�re pr�cieuse � m�j
          select nvl(GPM_WEIGHT_DELIVER_AUTO, 0) GPM_WEIGHT_DELIVER_AUTO
               , nvl(GPM_WEIGHT_DELIVER, 0) GPM_WEIGHT_DELIVER
               , nvl(GPM_LOSS_UNIT, 0) GPM_LOSS_UNIT
               , nvl(GPM_STONE_NUMBER, 0) GPM_STONE_NUMBER
            into valGPM_WEIGHT_DELIVER_AUTO
               , valGPM_WEIGHT_DELIVER
               , valGPM_LOSS_UNIT
               , valGPM_STONE_NUMBER
            from PPS_INTERRO_ALLOY
           where GCO_ALLOY_ID = tplPreciousMat.GCO_ALLOY_ID
             and GCO_GOOD_ID = tplGoodLevel.GCO_GOOD_ID;

          -- Mati�re non pr�sente sur les composants et poids calcul� -> Suppression
          if     not lbMatFounded
             and valGPM_WEIGHT_DELIVER_AUTO = 1 then
            update PPS_INTERRO_ALLOY
               set C_GPM_UPDATE_TYPE = PPS_LIB_INTERRO.cGpmUpdateTypeDelete
             where GCO_GOOD_ID = tplGoodLevel.GCO_GOOD_ID
               and GCO_ALLOY_ID = tplPreciousMat.GCO_ALLOY_ID;
          end if;

          if valGPM_WEIGHT_DELIVER_AUTO = 1 then
            newGPM_WEIGHT_DELIVER        := vPIT;   -- Poids livr� th�orique
            newGPM_WEIGHT_DELIVER_VALUE  := VPITV;   -- Poids livr� th�orique valorisable
            newGPM_STONE_NUMBER          := vSN;   -- Nombre de pierres
          else
            newGPM_WEIGHT_DELIVER  := valGPM_WEIGHT_DELIVER;   -- Poids livr� th�orique
            newGPM_STONE_NUMBER    := valGPM_STONE_NUMBER;   -- Nombre de pierres

            -- Poids livr� th�orique valorisable
            if vPITV = vPIT then
              newGPM_WEIGHT_DELIVER_VALUE  := newGPM_WEIGHT_DELIVER;
            else
              newGPM_WEIGHT_DELIVER_VALUE  := (vPITV / vPIT) * newGPM_WEIGHT_DELIVER;
            end if;
          end if;

          -- Poids investi th�orique
          newGPM_WEIGHT_INVEST        := vPIT;
          -- Poids investi th�orique valorisable
          newGPM_WEIGHT_INVEST_VALUE  := vPITV;
          -- Poids copeaux th�orique
          newGPM_WEIGHT_CHIP          := newGPM_WEIGHT_INVEST - newGPM_WEIGHT_DELIVER - valGPM_LOSS_UNIT;
          -- Poids investi th�orique total
          newGPM_WEIGHT_INVEST_TOTAL  := vPITT;
          -- Poids investi th�orique total valorisable
          newGPM_WEIGHT_INVEST_TOT_V  := VPITTV;
          -- Poids  copeaux th�orique total
          newGPM_WEIGHT_CHIP_TOTAL    := newGPM_WEIGHT_CHIP + vPCTT;
          -- Perte th�orique totale
          newGPM_LOSS_TOTAL           := valGPM_LOSS_UNIT + vPTT;
          -- Mise � jour compteur mati�re du produit termin�
          PPS_I_PRC_INTERRO.MergeGoodInterroAlloy(iGcoGoodId                       => tplGoodLevel.GCO_GOOD_ID
                                                , iGcoAlloyId                      => tplPreciousMat.GCO_ALLOY_ID
                                                , iGPM_WEIGHT_DELIVER              => newGPM_WEIGHT_DELIVER
                                                , iGPM_WEIGHT_DELIVER_VALUE        => newGPM_WEIGHT_DELIVER_VALUE
                                                , iGPM_WEIGHT_INVEST               => newGPM_WEIGHT_INVEST
                                                , iGPM_WEIGHT_INVEST_VALUE         => newGPM_WEIGHT_INVEST_VALUE
                                                , iGPM_WEIGHT_INVEST_TOTAL         => newGPM_WEIGHT_INVEST_TOTAL
                                                , iGPM_WEIGHT_INVEST_TOTAL_VALUE   => newGPM_WEIGHT_INVEST_TOT_V
                                                , iGPM_WEIGHT_CHIP                 => greatest(0, newGPM_WEIGHT_CHIP)
                                                , iGPM_WEIGHT_CHIP_TOTAL           => greatest(0, newGPM_WEIGHT_CHIP_TOTAL)
                                                , iGPM_LOSS_TOTAL                  => newGPM_LOSS_TOTAL
                                                , iGPM_STONE_NUMBER                => newGPM_STONE_NUMBER
                                                 );
        end loop;
      -- Si le mode d'appro du produit est "achet�"
      else
        -- Pour chaque mati�re du produit
        for tplGetPreciousMat in crGetPreciousMat(tplGoodLevel.GCO_GOOD_ID) loop
          -- Produit valorisable ou pas ?
          select nvl(max(CPU_PRECIOUS_MAT_VALUE), 0)
            into iCpuPrecMatValue
            from GCO_COMPL_DATA_PURCHASE
           where GCO_GOOD_ID = tplGoodLevel.GCO_GOOD_ID
             and CPU_DEFAULT_SUPPLIER = 1;

          -- Poids investi th�orique
          newGPM_WEIGHT_INVEST        := tplGetPreciousMat.GPM_WEIGHT_DELIVER;
          -- Poids investi th�orique total
          newGPM_WEIGHT_INVEST_TOTAL  := tplGetPreciousMat.GPM_WEIGHT_DELIVER;
          -- Poids  copeaux th�orique
          newGPM_WEIGHT_CHIP          := 0;
          -- Poids  copeaux th�orique total
          newGPM_WEIGHT_CHIP_TOTAL    := 0;

          if iCpuPrecMatValue = 0 then
            -- Poids investi th�orique valorisable
            newGPM_WEIGHT_INVEST_VALUE   := tplGetPreciousMat.GPM_WEIGHT_DELIVER;
            -- Poids investi th�orique total valorisable
            newGPM_WEIGHT_INVEST_TOT_V   := tplGetPreciousMat.GPM_WEIGHT_DELIVER;
            -- Poids livr� th�orique valorisable
            newGPM_WEIGHT_DELIVER_VALUE  := tplGetPreciousMat.GPM_WEIGHT_DELIVER;
          else
            -- Poids investi th�orique valorisable
            newGPM_WEIGHT_INVEST_VALUE   := 0;
            -- Poids investi th�orique total valorisable
            newGPM_WEIGHT_INVEST_TOT_V   := 0;
            -- Poids livr� th�orique valorisable
            newGPM_WEIGHT_DELIVER_VALUE  := 0;
          end if;

          PPS_I_PRC_INTERRO.MergeGoodInterroAlloy(iGcoGoodId                       => tplGoodLevel.GCO_GOOD_ID
                                                , iGcoAlloyId                      => tplGetPreciousMat.GCO_ALLOY_ID
                                                , iGPM_WEIGHT_DELIVER              => nvl(tplGetPreciousMat.GPM_WEIGHT_DELIVER, 0)
                                                , iGPM_WEIGHT_DELIVER_VALUE        => nvl(newGPM_WEIGHT_DELIVER_VALUE, 0)
                                                , iGPM_WEIGHT_INVEST               => nvl(newGPM_WEIGHT_INVEST, 0)
                                                , iGPM_WEIGHT_INVEST_VALUE         => nvl(newGPM_WEIGHT_INVEST_VALUE, 0)
                                                , iGPM_WEIGHT_INVEST_TOTAL         => nvl(newGPM_WEIGHT_INVEST_TOTAL, 0)
                                                , iGPM_WEIGHT_INVEST_TOTAL_VALUE   => nvl(newGPM_WEIGHT_INVEST_TOT_V, 0)
                                                , iGPM_WEIGHT_CHIP                 => nvl(greatest(0, newGPM_WEIGHT_CHIP), 0)
                                                , iGPM_WEIGHT_CHIP_TOTAL           => nvl(greatest(0, newGPM_WEIGHT_CHIP_TOTAL), 0)
                                                , iGPM_LOSS_TOTAL                  => nvl(tplGetPreciousMat.GPM_LOSS_TOTAL, 0)
                                                , iGPM_STONE_NUMBER                => nvl(tplGetPreciousMat.GPM_STONE_NUMBER, 0)
                                                 );
        end loop;
      end if;
    end loop;
  end UpdateWeightAndChip;

  /**
  *  Description
  *     Copie une date de cours avec les cours correspondants
  *
  */
  procedure DuplicateRateDate(
    aSrcRateDateID                    number
  , aRateDate                         date
  , aDstRateDateID             out    number
  , aDIC_FREE_CODE1_ID                DIC_FREE_CODE1.DIC_FREE_CODE1_ID%type
  , aDIC_COMPLEMENTARY_DATA_ID        DIC_COMPLEMENTARY_DATA.DIC_COMPLEMENTARY_DATA_ID%type
  , iGcoAlloyId                in     number default 0
  , iThirdMaterialRelation     in     GCO_PRECIOUS_RATE_DATE.C_THIRD_MATERIAL_RELATION_TYPE%type default null
  , iReference                 in     GCO_PRECIOUS_RATE_DATE.GPR_REFERENCE%type default null
  , iDescription               in     GCO_PRECIOUS_RATE_DATE.GPR_DESCRIPTION%type default null
  )
  is
  begin
    -- Recherche l'ID pour le nouvelle date de cours
    select INIT_ID_SEQ.nextval
      into aDstRateDateID
      from dual;

    -- Copie de la nouvelle date de cours
    insert into GCO_PRECIOUS_RATE_DATE
                (GCO_PRECIOUS_RATE_DATE_ID
               , GPR_START_VALIDITY
               , DIC_FREE_CODE1_ID
               , DIC_COMPLEMENTARY_DATA_ID
               , GCO_ALLOY_ID
               , DIC_BASIS_MATERIAL_ID
               , GPR_BASE_COST
               , GPR_BASE2_COST
               , GPR_REFERENCE
               , GPR_DESCRIPTION
               , GPR_TABLE_MODE
               , C_THIRD_MATERIAL_RELATION_TYPE
               , A_DATECRE
               , A_IDCRE
                )
      select aDstRateDateID as GCO_PRECIOUS_RATE_DATE_ID
           , aRateDate as GPR_START_VALIDITY
           , aDIC_FREE_CODE1_ID
           , aDIC_COMPLEMENTARY_DATA_ID
           , case
               when GPR_TABLE_MODE = 1 then   -- Vider l'alliage en mode Cotes � prix stabilis�s
                                           case
                                             when iGcoAlloyId = 0 then null
                                             else iGcoAlloyId
                                           end
               else GCO_ALLOY_ID
             end as GCO_ALLOY_ID
           , DIC_BASIS_MATERIAL_ID
           , GPR_BASE_COST
           , GPR_BASE2_COST
           , case
               when GPR_TABLE_MODE = 1 then iReference
               else GPR_REFERENCE
             end as GPR_REFERENCE
           , case
               when GPR_TABLE_MODE = 1 then iDescription
               else GPR_DESCRIPTION
             end as GPR_DESCRIPTION
           , GPR_TABLE_MODE
           , case
               when GPR_TABLE_MODE = 1 then iThirdMaterialRelation
               else C_THIRD_MATERIAL_RELATION_TYPE
             end as C_THIRD_MATERIAL_RELATION_TYPE
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_PRECIOUS_RATE_DATE
       where GCO_PRECIOUS_RATE_DATE_ID = aSrcRateDateID;

    -- Copie des cours pour la nouvelle date de cours
    insert into GCO_PRECIOUS_RATE
                (GCO_PRECIOUS_RATE_ID
               , GCO_PRECIOUS_RATE_DATE_ID
               , DIC_TYPE_RATE_ID
               , GPR_RATE
               , GPR_COMMENT
               , GPR_START_RANGE
               , GPR_END_RANGE
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   -- GCO_PRECIOUS_RATE_ID
           , aDstRateDateID   -- GCO_PRECIOUS_RATE_DATE_ID
           , DIC_TYPE_RATE_ID
           , GPR_RATE
           , GPR_COMMENT
           , GPR_START_RANGE
           , GPR_END_RANGE
           , sysdate   -- A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
        from GCO_PRECIOUS_RATE
       where GCO_PRECIOUS_RATE_DATE_ID = aSrcRateDateID;
  end DuplicateRateDate;

  /**
  *     Cr�ation d' une mati�re pr�cieuse de base (Contr�le des nomenclatures)
  */
  procedure PreciousMatCreate(
    aGCO_ALLOY_ID            GCO_ALLOY.GCO_ALLOY_ID%type
  , aGCO_GOOD_ID             GCO_GOOD.GCO_GOOD_ID%type
  , aGPM_WEIGHT              GCO_PRECIOUS_MAT.GPM_WEIGHT%type
  , aGPM_REAL_WEIGHT         GCO_PRECIOUS_MAT.GPM_REAL_WEIGHT%type
  , aGPM_THEORICAL_WEIGHT    GCO_PRECIOUS_MAT.GPM_THEORICAL_WEIGHT%type
  , aGPM_WEIGHT_DELIVER_AUTO GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER_AUTO%type
  , aGPM_WEIGHT_DELIVER      GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER%type
  , aGPM_LOSS_UNIT           GCO_PRECIOUS_MAT.GPM_LOSS_UNIT%type
  , aGPM_LOSS_PERCENT        GCO_PRECIOUS_MAT.GPM_LOSS_PERCENT%type
  , aGPM_STONE_NUMBER        GCO_PRECIOUS_MAT.GPM_STONE_NUMBER%type
  )
  is
  begin
    -- Cr�ation de la mati�re pr�cieuse
    insert into GCO_PRECIOUS_MAT
                (GCO_PRECIOUS_MAT_ID
               , GCO_ALLOY_ID
               , GCO_GOOD_ID
               , GPM_WEIGHT
               , GPM_REAL_WEIGHT
               , GPM_THEORICAL_WEIGHT
               , GPM_WEIGHT_DELIVER_AUTO
               , GPM_WEIGHT_DELIVER
               , GPM_LOSS_UNIT
               , GPM_LOSS_PERCENT
               , GPM_STONE_NUMBER
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , aGCO_ALLOY_ID
               , aGCO_GOOD_ID
               , aGPM_WEIGHT
               , aGPM_REAL_WEIGHT
               , aGPM_THEORICAL_WEIGHT
               , aGPM_WEIGHT_DELIVER_AUTO
               , aGPM_WEIGHT_DELIVER
               , aGPM_LOSS_UNIT
               , aGPM_LOSS_PERCENT
               , aGPM_STONE_NUMBER
               , sysdate   -- A_DATECRE
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );   -- A_IDCRE

    -- Update du champ Gestion mati�re pr�cieuse au niveau du produit
    update GCO_GOOD
       set GOO_PRECIOUS_MAT = 1
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where GCO_GOOD_ID = aGCO_GOOD_ID
       and nvl(GOO_PRECIOUS_MAT, 0) = 0;
  end PreciousMatCreate;

  /**
  * Function IsProductWithPMatWithWeighing
  * Description
  *
  *   Fonction qui indique si le produit pass� en param�tre est un produit avec gestion des mati�res pr�cieuses
  *     avec au moins un alliage avec pes�e r�elle.
  *
  * @author  Emmanuel Cassis
  * @version 11.09.2003
  * @public
  * @Param   aGCO_GOOD_ID  Produit
  */
  function IsProductWithPMatWithWeighing(aGCO_GOOD_ID number)
    return integer
  is
    cursor CUR_GCO_PRODUCT
    is
      select GPM.GCO_ALLOY_ID
        from GCO_GOOD GCO
           , GCO_PRECIOUS_MAT GPM
       where GCO.GCO_GOOD_ID = aGCO_GOOD_ID
         and GCO.GCO_GOOD_ID = GPM.GCO_GOOD_ID
         and GCO.GOO_PRECIOUS_MAT = 1
         and GPM.GPM_WEIGHT = 1
         and GPM.GPM_REAL_WEIGHT = 1;

    CurGcoProduct CUR_GCO_PRODUCT%rowtype;
  begin
    open CUR_GCO_PRODUCT;

    fetch CUR_GCO_PRODUCT
     into CurGcoProduct;

    if CUR_GCO_PRODUCT%found then
      close CUR_GCO_PRODUCT;

      return 1;
    else
      close CUR_GCO_PRODUCT;

      return 0;
    end if;
  exception
    when others then
      close CUR_GCO_PRODUCT;

      return 0;
  end;

  /**
  *     Valorisation des Poids livr�s th�oriques des Alliages ramen�s en mati�res de base x Cours de.la mati�re de base de type BV
  *     avec code tiers correspondant au client et si inexistant pour le cours sans code tiers
  */
  function CalcGoodPreciousMatPrice(
    aGCO_GOOD_ID               GCO_GOOD.GCO_GOOD_ID%type
  , aDIC_FREE_CODE1_ID         DIC_FREE_CODE1.DIC_FREE_CODE1_ID%type
  , aGPR_START_VALIDITY        GCO_PRECIOUS_RATE_DATE.GPR_START_VALIDITY%type
  , aDIC_COMPLEMENTARY_DATA_ID DIC_COMPLEMENTARY_DATA.DIC_COMPLEMENTARY_DATA_ID%type default null
  )
    return number
  is
    cursor CUR_GCO_ALLOY
    is
      select GPM.GCO_ALLOY_ID
           , nvl(GAL_CONVERT_FACTOR_GR, 1) GAL_CONVERT_FACTOR_GR
           , nvl(GPM_WEIGHT_DELIVER, 0) GPM_WEIGHT_DELIVER
        from GCO_PRECIOUS_MAT GPM
           , GCO_ALLOY GA
       where GA.GCO_ALLOY_ID = GPM.GCO_ALLOY_ID
         and GPM.GCO_GOOD_ID = aGCO_GOOD_ID;

    cursor CUR_BASIS_MATERIAL(aGCO_ALLOY_ID GCO_ALLOY.GCO_ALLOY_ID%type)
    is
      select DIC_BASIS_MATERIAL_ID
           , GAC_RATE
        from GCO_ALLOY_COMPONENT
       where GCO_ALLOY_ID = aGCO_ALLOY_ID;

    CurGcoAlloy      CUR_GCO_ALLOY%rowtype;
    CurBasisMaterial CUR_BASIS_MATERIAL%rowtype;
    nAlloyMatCost    number;
    nTotalMatCost    number;
    nPreciousMatCost number;
    blnFounded       boolean;
  begin
    nPreciousMatCost  := 0;
    nTotalMatCost     := 0;

    for CurGcoAlloy in CUR_GCO_ALLOY loop
      blnFounded        := false;
      nPreciousMatCost  :=
        (CurGcoAlloy.GPM_WEIGHT_DELIVER *
         FAL_PRECALC_TOOLS.GETQUOTEDPRICE(CurGcoAlloy.GCO_ALLOY_ID
                                        , null
                                        , aGPR_START_VALIDITY
                                        , 'BV'
                                        , blnFounded
                                        , aDIC_FREE_CODE1_ID
                                        , aDIC_COMPLEMENTARY_DATA_ID
                                         )
        );

      if blnFounded = false then
        nPreciousMatCost  := 0;

        for CurBasisMaterial in CUR_BASIS_MATERIAL(CurGcoAlloy.GCO_ALLOY_ID) loop
          nPreciousMatCost  :=
            nPreciousMatCost +
            (CurGcoAlloy.GPM_WEIGHT_DELIVER *
             (CurBasisMaterial.GAC_RATE / 100) *
             CurGcoAlloy.GAL_CONVERT_FACTOR_GR *
             FAL_PRECALC_TOOLS.GETQUOTEDPRICE(null
                                            , CurBasisMaterial.DIC_BASIS_MATERIAL_ID
                                            , aGPR_START_VALIDITY
                                            , 'BV'
                                            , blnFounded
                                            , aDIC_FREE_CODE1_ID
                                            , aDIC_COMPLEMENTARY_DATA_ID
                                             )
            );
        end loop;
      end if;

      nTotalMatCost     := nTotalMatCost + nPreciousMatCost;
    end loop;

    return nTotalMatCost;
  end CalcGoodPreciousMatPrice;

  /**
  * procedure CalcPreciousMatPrice
  * Description
  *
  *        Calcul du prix d'un alliage pour le poids pass� en param�tre, avec recherche du cours d'abord sur l'alliage
  *            puis si inexistant, sur les mati�res pr�ciseuses qui le compose
  *
  * @author  Emmanuel Cassis
  * @version 12.09.2003
  * @public
  */
  function CalcAlloyPreciousMatPrice(
    aGCO_ALLOY_ID                 GCO_ALLOY.GCO_ALLOY_ID%type
  , aDIC_FREE_CODE1_ID            DIC_FREE_CODE1.DIC_FREE_CODE1_ID%type
  , aGPR_START_VALIDITY           GCO_PRECIOUS_RATE_DATE.GPR_START_VALIDITY%type
  , aDIC_TYPE_RATE_ID          in GCO_PRECIOUS_RATE.DIC_TYPE_RATE_ID%type
  , aALLOY_WEIGHT                 number
  , aDIC_COMPLEMENTARY_DATA_ID    DIC_COMPLEMENTARY_DATA.DIC_COMPLEMENTARY_DATA_ID%type default null
  )
    return number
  is
    cursor CUR_GCO_ALLOY
    is
      select GAL.GCO_ALLOY_ID
           , nvl(GAL.GAL_CONVERT_FACTOR_GR, 1) GAL_CONVERT_FACTOR_GR
        from GCO_ALLOY GAL
       where GAL.GCO_ALLOY_ID = aGCO_ALLOY_ID;

    cursor CUR_BASIS_MATERIAL
    is
      select DIC_BASIS_MATERIAL_ID
           , GAC_RATE
        from GCO_ALLOY_COMPONENT
       where GCO_ALLOY_ID = aGCO_ALLOY_ID;

    CurGcoAlloy      CUR_GCO_ALLOY%rowtype;
    CurBasisMaterial CUR_BASIS_MATERIAL%rowtype;
    nAlloyMatCost    number;
    nTotalMatCost    number;
    nPreciousMatCost number;
    blnFounded       boolean;
  begin
    nPreciousMatCost  := 0;
    nTotalMatCost     := 0;

    for CurGcoAlloy in CUR_GCO_ALLOY loop
      blnFounded        := false;
      nPreciousMatCost  :=
        (aALLOY_WEIGHT *
         FAL_PRECALC_TOOLS.GETQUOTEDPRICE(CurGcoAlloy.GCO_ALLOY_ID
                                        , null
                                        , aGPR_START_VALIDITY
                                        , aDIC_TYPE_RATE_ID
                                        , blnFounded
                                        , aDIC_FREE_CODE1_ID
                                        , aDIC_COMPLEMENTARY_DATA_ID
                                         )
        );

      if blnFounded = false then
        nPreciousMatCost  := 0;

        for CurBasisMaterial in CUR_BASIS_MATERIAL loop
          nPreciousMatCost  :=
            nPreciousMatCost +
            (aALLOY_WEIGHT *
             (CurBasisMaterial.GAC_RATE / 100) *
             CurGcoAlloy.GAL_CONVERT_FACTOR_GR *
             FAL_PRECALC_TOOLS.GETQUOTEDPRICE(null
                                            , CurBasisMaterial.DIC_BASIS_MATERIAL_ID
                                            , aGPR_START_VALIDITY
                                            , aDIC_TYPE_RATE_ID
                                            , blnFounded
                                            , aDIC_FREE_CODE1_ID
                                            , aDIC_COMPLEMENTARY_DATA_ID
                                             )
            );
        end loop;
      end if;

      nTotalMatCost     := nTotalMatCost + nPreciousMatCost;
    end loop;

    return nTotalMatCost;
  end CalcAlloyPreciousMatPrice;

  /**
  * function CtrlNomIntegrity
  * Description : Contr�le de l'int�grit� des "nomenclatures" d'alliage pour les biens
  *               avec gestion des mati�res pr�cieuses.
  * @author  Emmanuel Cassis
  * @version 12.09.2003
  * @public
  * @param  iCheckPurchaseProduct : Contr�le des nomenclatures des produits achet�s
  * @param  iCheckSubcontractProduct : Contr�le des nomenclatures des produits sous-trait�s
  * @return 0 -> Ok; 1 -> Des mati�res pr�cieuses sont manquantes
  */
  function CtrlNomIntegrity(iCheckPurchaseProduct in integer default 1, iCheckSubcontractProduct in integer default 1)
    return integer
  is
    aresult integer;
  begin
    select count(*)
      into aresult
      from PPS_NOMENCLATURE NOM
         , PPS_NOM_BOND COM
         , GCO_PRECIOUS_MAT GPM
         , GCO_GOOD GOO_NOM
         , GCO_GOOD GOO_COM
         , GCO_PRODUCT PRD_NOM
     where NOM.PPS_NOMENCLATURE_ID = COM.PPS_NOMENCLATURE_ID
       and COM.C_TYPE_COM = '1'
       and (   COM.C_KIND_COM = '1'
            or COM.C_KIND_COM = '3')
       and GOO_NOM.GCO_GOOD_ID = NOM.GCO_GOOD_ID
       and GOO_COM.GCO_GOOD_ID = COM.GCO_GOOD_ID
       and GOO_COM.GOO_PRECIOUS_MAT = 1
       and GPM.GCO_GOOD_ID = COM.GCO_GOOD_ID
       and GPM.GCO_ALLOY_ID is not null
       and GOO_NOM.GCO_GOOD_ID = PRD_NOM.GCO_GOOD_ID
       and GOO_NOM.GOO_PRECIOUS_MAT = 1
       and NOM.NOM_DEFAULT = 1   --nomenclature par d�faut
       and (   PRD_NOM.C_SUPPLY_MODE = '2'   -- contr�le produits fabriqu�s, achet�s, sous-trait�s
            or (    iCheckPurchaseProduct = 1
                and PRD_NOM.C_SUPPLY_MODE = '1')
            or (    iCheckSubcontractProduct = 1
                and PRD_NOM.C_SUPPLY_MODE = '4')
           )
       -- seulement les articles actifs
       and GOO_NOM.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive
       -- seulement les composants actifs
       and GOO_COM.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive
       and not exists(select GPM2.GCO_ALLOY_ID
                        from GCO_PRECIOUS_MAT GPM2
                       where GPM2.GCO_ALLOY_ID = GPM.GCO_ALLOY_ID
                         and GPM2.GCO_GOOD_ID = NOM.GCO_GOOD_ID);

    if nvl(aResult, 0) > 0 then
      return 1;
    else
      return 0;
    end if;
  exception
    when no_data_found then
      return 0;
  end CtrlNomIntegrity;

  /**
  * function CtrlAlloyWeight
  * Description : Contr�le des valeurs des poids mati�res pr�cieuses, sur les produits
  *               avec gestion des mati�res pr�cieuses et poids calcul� n'ont pas un
  *               poids livr� th�orique = 0
  * @author  Emmanuel Cassis
  * @version 12.09.2003
  * @public
  * @return 0 -> Ok; 1 -> Des mati�res pr�cieuses sont manquantes
  */
  function CtrlAlloyWeight
    return integer
  is
    aresult integer;
  begin
    select count(*)
      into aresult
      from GCO_GOOD GOO
         , GCO_PRECIOUS_MAT GPM
         , GCO_ALLOY GAL
     where GPM.GCO_GOOD_ID = GOO.GCO_GOOD_ID
       and GOO.GOO_PRECIOUS_MAT = 1
       and GOO.C_GOOD_STATUS = GCO_I_LIB_CONSTANT.gcGoodStatusActive
       and GOO.GCO_GOOD_ID not in(select GSV.GCO_GOOD_ID
                                    from GCO_SERVICE GSV
                                   where GSV.GCO_GOOD_ID = GOO.GCO_GOOD_ID)
       and GPM.GCO_ALLOY_ID = GAL.GCO_ALLOY_ID
       and GPM.GPM_WEIGHT_DELIVER_AUTO = 0
       and nvl(GPM.GPM_WEIGHT_DELIVER, 0) = 0;

    if nvl(aResult, 0) > 0 then
      return 1;
    else
      return 0;
    end if;
  exception
    when no_data_found then
      return 0;
  end CtrlAlloyWeight;

  /**
  * function InternalGetUshBasisMatRate
  * Description
  *   M�thode interne (aiguillage pour l'appel au standard ou indiv) pour la recherche du cours de la mati�re de base
  * @created ngv 28.03.2011
  * @lastUpdate
  * @public
  * @param iDicBasisMaterialID : Mati�re de base
  * @param iDateRef            : Date pour la recherche du cours
  * @param iDicTypeRateID      : Type de cours
  * @param iDicFreeCode1ID     : Dico libre 1
  * @param iDicComplDataID     : Dico Code donn�e compl�mentaire
  * @return le cours de mati�re de base
  */
  function InternalGetUshBasisMatRate(
    iDicBasisMaterialID in GCO_PRECIOUS_RATE_DATE.DIC_BASIS_MATERIAL_ID%type
  , iDateRef            in GCO_PRECIOUS_RATE_DATE.GPR_START_VALIDITY%type
  , iDicTypeRateID      in GCO_PRECIOUS_RATE.DIC_TYPE_RATE_ID%type
  , iDicFreeCode1ID     in GCO_PRECIOUS_RATE_DATE.DIC_FREE_CODE1_ID%type
  , iDicComplDataID     in GCO_PRECIOUS_RATE_DATE.DIC_COMPLEMENTARY_DATA_ID%type
  )
    return number
  is
    lnRate     GCO_PRECIOUS_RATE.GPR_RATE%type;
    lvSqlIndiv clob;
  begin
    lnRate      := null;
    lvSqlIndiv  := PCS.PC_FUNCTIONS.GetSql('GCO_PRECIOUS_RATE', 'GET_USH_BASIS_MAT_RATE', 'GET_USH_BASIS_MAT_RATE');

    -- Executer la m�thode indiv si d�finie
    if PCS.PC_LIB_SQL.IsSqlEmpty(lvSqlIndiv) = 0 then
      lnRate  :=
        GetIndivUshBasisMatRate(iDicBasisMaterialID   => iDicBasisMaterialID
                              , iDateRef              => iDateRef
                              , iDicTypeRateID        => iDicTypeRateID
                              , iDicFreeCode1ID       => iDicFreeCode1ID
                              , iDicComplDataID       => iDicComplDataID
                              , iSql                  => lvSqlIndiv
                               );
    end if;

    -- le cours n'est pas encore d�fini
    if lnRate is null then
      -- Effectuer la recherche "Standard"
      lnRate  :=
        GetUshBasisMatRate(iDicBasisMaterialID   => iDicBasisMaterialID
                         , iDateRef              => iDateRef
                         , iDicTypeRateID        => iDicTypeRateID
                         , iDicFreeCode1ID       => iDicFreeCode1ID
                         , iDicComplDataID       => iDicComplDataID
                          );
    end if;

    return lnRate;
  end InternalGetUshBasisMatRate;

  /**
  * function GetUshBasisMatRate
  * Description
  *   M�thode standard pour la recherche du cours de la mati�re de base
  * @created ngv 28.03.2011
  * @lastUpdate
  * @public
  * @param iDicBasisMaterialID : Mati�re de base
  * @param iDateRef            : Date pour la recherche du cours
  * @param iDicTypeRateID      : Type de cours
  * @param iDicFreeCode1ID     : Dico libre 1
  * @param iDicComplDataID     : Dico Code donn�e compl�mentaire
  * @return le cours de mati�re de base
  */
  function GetUshBasisMatRate(
    iDicBasisMaterialID in GCO_PRECIOUS_RATE_DATE.DIC_BASIS_MATERIAL_ID%type
  , iDateRef            in GCO_PRECIOUS_RATE_DATE.GPR_START_VALIDITY%type
  , iDicTypeRateID      in GCO_PRECIOUS_RATE.DIC_TYPE_RATE_ID%type
  , iDicFreeCode1ID     in GCO_PRECIOUS_RATE_DATE.DIC_FREE_CODE1_ID%type
  , iDicComplDataID     in GCO_PRECIOUS_RATE_DATE.DIC_COMPLEMENTARY_DATA_ID%type
  )
    return number
  is
    cursor lcrGetRate(lvDicFreeCode1ID in varchar2, lvDicComplDataID in varchar2)
    is
      select   GPR.GPR_RATE
          from GCO_PRECIOUS_RATE GPR
             , GCO_PRECIOUS_RATE_DATE GPD
         where GPR.GCO_PRECIOUS_RATE_DATE_ID = GPD.GCO_PRECIOUS_RATE_DATE_ID
           and GPD.GPR_TABLE_MODE = 0
           and GPD.DIC_BASIS_MATERIAL_ID = iDicBasisMaterialID
           and GPD.GCO_ALLOY_ID is null
           and GPR.DIC_TYPE_RATE_ID = iDicTypeRateID
           and iDateRef >= GPD.GPR_START_VALIDITY
           and (    (    lvDicFreeCode1ID is null
                     and lvDicComplDataID is null
                     and GPD.DIC_FREE_CODE1_ID is null
                     and GPD.DIC_COMPLEMENTARY_DATA_ID is null)
                or (    lvDicFreeCode1ID is null
                    and lvDicComplDataID is not null
                    and GPD.DIC_COMPLEMENTARY_DATA_ID = lvDicComplDataID)
                or (    lvDicFreeCode1ID is not null
                    and GPD.DIC_FREE_CODE1_ID = lvDicFreeCode1ID)
               )
      order by GPD.GPR_START_VALIDITY desc;

    ltplGetRate lcrGetRate%rowtype;
    lnRate      GCO_PRECIOUS_RATE.GPR_RATE%type;
    lbFound     boolean;
  begin
    lbFound  := false;
    lnRate   := null;

    -- Cascade de recherche :
    --   1. Avec DIC_FREE_CODE1_ID et DIC_COMPLEMENTARY_DATA_ID tels qu'ils ont �t� pass�s � la fonction
    --   2. Si pas trouv� Et que le DIC_FREE_CODE1_ID n'�tait pas null, effectuer une nouvelle recherche en for�ant ce champ � null
    --   3. Si pas trouv� Et que le DIC_FREE_CODE1_ID �tait null
    --                    Et que le DIC_COMPLEMENTARY_DATA_ID n'�tait pas null, effectuer une nouvelle recherche en for�ant ces 2 champs � null
    open lcrGetRate(iDicFreeCode1ID, iDicComplDataID);

    fetch lcrGetRate
     into ltplGetRate;

    if lcrGetRate%found then
      lbFound  := true;
      lnRate   := ltplGetRate.GPR_RATE;
    end if;

    close lcrGetRate;

    -- Si le cours n'a pas �t� trouv� alors qu'on le recherchait avait Code libre
    --   on fait la recherche sans code libre
    if     not lbFound
       and (iDicFreeCode1ID is not null) then
      open lcrGetRate(null, iDicComplDataID);

      fetch lcrGetRate
       into ltplGetRate;

      if lcrGetRate%found then
        lbFound  := true;
        lnRate   := ltplGetRate.GPR_RATE;
      end if;

      close lcrGetRate;
    end if;

    -- Si le cours n'a pas �t� trouv� alors qu'on le recherchait avait Code donn�e compl�mentaire
    --   on fait la recherche sans code code donn�e compl�mentaire
    if     not lbFound
       and (iDicFreeCode1ID is null)
       and (iDicComplDataID is not null) then
      open lcrGetRate(null, null);

      fetch lcrGetRate
       into ltplGetRate;

      if lcrGetRate%found then
        lbFound  := true;
        lnRate   := ltplGetRate.GPR_RATE;
      end if;

      close lcrGetRate;
    end if;

    return lnRate;
  end GetUshBasisMatRate;

  /**
  * function GetIndivUshBasisMatRate
  * Description
  *   M�thode indiv pour la recherche du cours d'un alliage en fonction d'un cour d'une mati�re de base
  *     pour la norme USH
  * @created ngv 28.03.2011
  * @lastUpdate
  * @public
  * @param iDicBasisMaterialID : Mati�re de base
  * @param iDateRef            : Date pour la recherche du cours
  * @param iDicTypeRateID      : Type de cours
  * @param iDicFreeCode1ID     : Dico libre 1
  * @param iDicComplDataID     : Dico Code donn�e compl�mentaire
  * @param iSql                : cmd sql indiv � executer
  * @return le cours de mati�re de base
  */
  function GetIndivUshBasisMatRate(
    iDicBasisMaterialID in GCO_PRECIOUS_RATE_DATE.DIC_BASIS_MATERIAL_ID%type
  , iDateRef            in GCO_PRECIOUS_RATE_DATE.GPR_START_VALIDITY%type
  , iDicTypeRateID      in GCO_PRECIOUS_RATE.DIC_TYPE_RATE_ID%type
  , iDicFreeCode1ID     in GCO_PRECIOUS_RATE_DATE.DIC_FREE_CODE1_ID%type
  , iDicComplDataID     in GCO_PRECIOUS_RATE_DATE.DIC_COMPLEMENTARY_DATA_ID%type
  , iSql                in clob
  )
    return number
  is
    lnRate GCO_PRECIOUS_RATE.GPR_RATE%type;
    lvSql  clob;
  begin
    lvSql  := upper(replace(iSql, '[COMPANY_OWNER' || '].', '') );
    lvSql  := replace(lvSql, '[CO' || '].', '');
    lvSql  := replace(lvSql, ':DIC_BASIS_MATERIAL_ID', '''' || iDicBasisMaterialID || '''');
    lvSql  := replace(lvSql, ':DATE_REF', 'to_date(''' || to_char(iDateRef, 'DD.MM.YYYY') || ''', ''DD.MM.YYYY'')');

    if iDicTypeRateID is null then
      lvSql  := replace(lvSql, ':DIC_TYPE_RATE_ID', 'null');
    else
      lvSql  := replace(lvSql, ':DIC_TYPE_RATE_ID', '''' || iDicTypeRateID || '''');
    end if;

    if iDicFreeCode1ID is null then
      lvSql  := replace(lvSql, ':DIC_FREE_CODE1_ID', 'null');
    else
      lvSql  := replace(lvSql, ':DIC_FREE_CODE1_ID', '''' || iDicFreeCode1ID || '''');
    end if;

    if iDicComplDataID is null then
      lvSql  := replace(lvSql, ':DIC_COMPLEMENTARY_DATA_ID', 'null');
    else
      lvSql  := replace(lvSql, ':DIC_COMPLEMENTARY_DATA_ID', '''' || iDicComplDataID || '''');
    end if;

    execute immediate lvSql
                 into lnRate;

    return lnRate;
  end GetIndivUshBasisMatRate;

  /**
  * function GetUshAlloyRate
  * Description
  *   Renvoie le cours d'un alliage en fonction d'un cours d'une mati�re de base
  *     pour la norme USH
  */
  function GetUshAlloyRate(
    iBasisMaterialRate  in GCO_PRECIOUS_RATE.GPR_START_RANGE%type
  , iDicBasisMaterialID in GCO_PRECIOUS_RATE_DATE.DIC_BASIS_MATERIAL_ID%type
  , iAlloyID            in GCO_PRECIOUS_RATE_DATE.GCO_ALLOY_ID%type
  , iDateRef            in GCO_PRECIOUS_RATE_DATE.GPR_START_VALIDITY%type
  , iThirdMatRelType    in GCO_PRECIOUS_RATE_DATE.C_THIRD_MATERIAL_RELATION_TYPE%type
  , iDicFreeCode1ID     in GCO_PRECIOUS_RATE_DATE.DIC_FREE_CODE1_ID%type
  , iDicComplDataID     in GCO_PRECIOUS_RATE_DATE.DIC_COMPLEMENTARY_DATA_ID%type
  )
    return number
  is
    cursor lcrGetRate(lvDicFreeCode1ID in varchar2, lvDicComplDataID in varchar2)
    is
      select   GPR.GPR_RATE
             , nvl(GPD.GPR_BASE2_COST, 0) GPR_BASE2_COST
          from GCO_PRECIOUS_RATE GPR
             , GCO_PRECIOUS_RATE_DATE GPD
         where GPR.GCO_PRECIOUS_RATE_DATE_ID = GPD.GCO_PRECIOUS_RATE_DATE_ID
           and GPD.GPR_TABLE_MODE = 1
           and GPD.DIC_BASIS_MATERIAL_ID = iDicBasisMaterialID
           and GPD.GCO_ALLOY_ID = iAlloyID
           and GPD.C_THIRD_MATERIAL_RELATION_TYPE = iThirdMatRelType
           and iBasisMaterialRate between GPR.GPR_START_RANGE and GPR.GPR_END_RANGE
           and iDateRef >= GPD.GPR_START_VALIDITY
           and (    (    lvDicFreeCode1ID is null
                     and lvDicComplDataID is null
                     and GPD.DIC_FREE_CODE1_ID is null
                     and GPD.DIC_COMPLEMENTARY_DATA_ID is null)
                or (    lvDicFreeCode1ID is null
                    and lvDicComplDataID is not null
                    and GPD.DIC_COMPLEMENTARY_DATA_ID = lvDicComplDataID)
                or (    lvDicFreeCode1ID is not null
                    and GPD.DIC_FREE_CODE1_ID = lvDicFreeCode1ID)
               )
      order by GPD.GPR_START_VALIDITY desc;

    ltplGetRate lcrGetRate%rowtype;
    lnRate      GCO_PRECIOUS_RATE.GPR_RATE%type;
    lbFound     boolean;
  begin
    lbFound  := false;
    lnRate   := null;

    -- Cascade de recherche :
    --   1. Avec DIC_FREE_CODE1_ID et DIC_COMPLEMENTARY_DATA_ID tels qu'ils ont �t� pass�s � la fonction
    --   2. Si pas trouv� Et que le DIC_FREE_CODE1_ID n'�tait pas null, effectuer une nouvelle recherche en for�ant ce champ � null
    --   3. Si pas trouv� Et que le DIC_FREE_CODE1_ID �tait null
    --                    Et que le DIC_COMPLEMENTARY_DATA_ID n'�tait pas null, effectuer une nouvelle recherche en for�ant ces 2 champs � null
    open lcrGetRate(iDicFreeCode1ID, iDicComplDataID);

    fetch lcrGetRate
     into ltplGetRate;

    if lcrGetRate%found then
      lbFound  := true;

      if ltplGetRate.GPR_BASE2_COST <> 0 then
        lnRate  :=(ltplGetRate.GPR_RATE / ltplGetRate.GPR_BASE2_COST);
      else
        lnRate  := ltplGetRate.GPR_RATE;
      end if;
    end if;

    close lcrGetRate;

    -- Si le cours n'a pas �t� trouv� alors qu'on le recherchait avait Code libre
    --   on fait la recherche sans code libre
    if     not lbFound
       and (iDicFreeCode1ID is not null) then
      open lcrGetRate(null, iDicComplDataID);

      fetch lcrGetRate
       into ltplGetRate;

      if lcrGetRate%found then
        lbFound  := true;

        if ltplGetRate.GPR_BASE2_COST <> 0 then
          lnRate  :=(ltplGetRate.GPR_RATE / ltplGetRate.GPR_BASE2_COST);
        else
          lnRate  := ltplGetRate.GPR_RATE;
        end if;
      end if;

      close lcrGetRate;
    end if;

    -- Si le cours n'a pas �t� trouv� alors qu'on le recherchait avait Code donn�e compl�mentaire
    --   on fait la recherche sans code code donn�e compl�mentaire
    if     not lbFound
       and (iDicFreeCode1ID is null)
       and (iDicComplDataID is not null) then
      open lcrGetRate(null, null);

      fetch lcrGetRate
       into ltplGetRate;

      if lcrGetRate%found then
        lbFound  := true;

        if ltplGetRate.GPR_BASE2_COST <> 0 then
          lnRate  :=(ltplGetRate.GPR_RATE / ltplGetRate.GPR_BASE2_COST);
        else
          lnRate  := ltplGetRate.GPR_RATE;
        end if;
      end if;

      close lcrGetRate;
    end if;

    return lnRate;
  end GetUshAlloyRate;

  /**
  * function GetUshRate
  * Description
  *   Renvoie le cours d'un alliage pour la norme USH
  */
  function GetUshRate(
    iAlloyID         in GCO_ALLOY.GCO_ALLOY_ID%type
  , iDateRef         in date
  , iThirdMatRelType in GCO_PRECIOUS_RATE_DATE.C_THIRD_MATERIAL_RELATION_TYPE%type
  , iDicTypeRateID   in GCO_PRECIOUS_RATE.DIC_TYPE_RATE_ID%type
  , iDicFreeCode1ID  in GCO_PRECIOUS_RATE_DATE.DIC_FREE_CODE1_ID%type
  , iDicComplDataID  in GCO_PRECIOUS_RATE_DATE.DIC_COMPLEMENTARY_DATA_ID%type
  )
    return number
  is
    lvDicBasisMaterialID GCO_PRECIOUS_RATE_DATE.DIC_BASIS_MATERIAL_ID%type;
    lnBasisMatRate       GCO_PRECIOUS_RATE.GPR_RATE%type;
    lnRate               GCO_PRECIOUS_RATE.GPR_RATE%type;
  begin
    lnBasisMatRate  := null;
    lnRate          := null;

    -- Identifier la mati�re de base de r�f�rence de l'alliage
    select max(DIC_BASIS_MATERIAL_ID)
      into lvDicBasisMaterialID
      from GCO_PRECIOUS_RATE_DATE
     where GCO_ALLOY_ID = iAlloyID
       and GPR_TABLE_MODE = 1;

    if lvDicBasisMaterialID is not null then
      -- Rechercher le cout de la mat�rie de base de r�f�rence selon la norme USH
      lnBasisMatRate  :=
        InternalGetUshBasisMatRate(iDicBasisMaterialID   => lvDicBasisMaterialID
                                 , iDateRef              => iDateRef
                                 , iDicTypeRateID        => iDicTypeRateID
                                 , iDicFreeCode1ID       => iDicFreeCode1ID
                                 , iDicComplDataID       => iDicComplDataID
                                  );

      if lnBasisMatRate is not null then
        -- Rechercher le cout de l'alliage de type cote � prix stabilis�
        lnRate  :=
          GetUshAlloyRate(iBasisMaterialRate    => lnBasisMatRate
                        , iDicBasisMaterialID   => lvDicBasisMaterialID
                        , iAlloyID              => iAlloyID
                        , iDateRef              => iDateRef
                        , iThirdMatRelType      => iThirdMatRelType
                        , iDicFreeCode1ID       => iDicFreeCode1ID
                        , iDicComplDataID       => iDicComplDataID
                         );
      end if;
    end if;

    return lnRate;
  end GetUshRate;
end GCO_PRECIOUS_MAT_FUNCTIONS;
