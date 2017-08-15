--------------------------------------------------------
--  DDL for Package Body FAL_LIB_TASK_CHIP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_TASK_CHIP" 
is
  /**
  * Description
  *    Retourne la d�finition d'alliage li�e � la d�finition de r�cup. de copeaux
  */
  function pGetGcoAlloyID(inFalTaskChipDetailID in FAL_TASK_CHIP_DETAIL.FAL_TASK_CHIP_DETAIL_ID%type)
    return FAL_TASK_CHIP_DETAIL.GCO_ALLOY_ID%type
  as
    lnGcoAlloyID FAL_TASK_CHIP_DETAIL.GCO_ALLOY_ID%type;
  begin
    select GCO_ALLOY_ID
      into lnGcoAlloyID
      from FAL_TASK_CHIP_DETAIL
     where FAL_TASK_CHIP_DETAIL_ID = inFalTaskChipDetailID;
  exception
    when no_data_found then
      return null;
  end pGetGcoAlloyID;

  /**
  * Description
  *    Retourne l'op�ration de lot li�e � la d�finition de r�cup. de copeaux
  */
  function pGetFalTaskLinkID(inFalTaskChipDetailID in FAL_TASK_CHIP_DETAIL.FAL_TASK_CHIP_DETAIL_ID%type)
    return FAL_TASK_CHIP_DETAIL.FAL_TASK_LINK_ID%type
  as
    lnFalTaskLinkID FAL_TASK_CHIP_DETAIL.FAL_TASK_LINK_ID%type;
  begin
    select FAL_TASK_LINK_ID
      into lnFalTaskLinkID
      from FAL_TASK_CHIP_DETAIL
     where FAL_TASK_CHIP_DETAIL_ID = inFalTaskChipDetailID;
  exception
    when no_data_found then
      return null;
  end pGetFalTaskLinkID;

  /**
  * Description
  *    Retourne la date de r�cup�ration des copeaux. Celle-ci est calcul�e en fonction
  *    de la valeur de configuration GMP_WORKSHOP_CLEANING_DATE si pas null, sinon date
  *    de r�cup�ration = date de fin de l'op�ration.
  *    Format de la configuration :
  *    - WEEK3 = 3�me jour de la semaine ou MONTH21 = 21�me jour du mois.
  */
  function getChipRecoveryDate(
    iTaskLinkID     in FAL_TASK_CHIP_DETAIL.FAL_TASK_LINK_ID%type default null
  , iTaskLinkPropID in FAL_TASK_CHIP_DETAIL.FAL_TASK_LINK_ID%type default null
  )
    return date
  as
    lTaskEndDate              date;
    lvGmpWorkshopCleaningDate PCS.PC_CBASE.CBACNAME%type;
    lvWeekStart               PCS.PC_CBASE.CBACNAME%type;
    lnDecalage                number                       := 0;
    lnTaskEndDateDayNumber    number;
  begin
    if iTaskLinkID is not null then
      /* R�cup�ration de la date de fin de l'op�ration */
      lTaskEndDate  := trunc(FAL_LIB_TASK_LINK.getEndDate(inFalTaskLinkID => iTaskLinkID) );
    else
      /* R�cup�ration de la date de fin de l'op�ration */
      lTaskEndDate  := trunc(FAL_LIB_TASK_LINK_PROP.getEndDate(iTaskLinkPropID => iTaskLinkPropID) );
    end if;

    if lTaskEndDate is not null then
      /* R�cup�ration de la valeur de la configuration "GMP_WORKSHOP_CLEANING_DATE" (date de nettoyage des machines :
      jour de la semaine ou jour du mois. Format WEEK2 = 2�me jour de la semaine ou  MONTH21 = 21�me jour du mois) */
      lvGmpWorkshopCleaningDate  := PCS.PC_CONFIG.GetConfig(aConfigName => 'GMP_WORKSHOP_CLEANING_DATE');

      if lvGmpWorkshopCleaningDate is null then   /* Si la valeur de la config est null, r�cup�ration des copeaux � la fin de l'op�ration */
        return lTaskEndDate;
      else
        if instr(lvGmpWorkshopCleaningDate, 'WEEK') = 1 then
          /* Premier jour de la semaine selon config (1 = DIMANCHE) */
          lvWeekStart             := PCS.PC_CONFIG.GetConfig(aConfigName => 'DOC_DELAY_WEEKSTART');
          /* On veut le jour de la semaine de la date de fin de l'op�ration � partir du premier jour de la semaine
             d�fini dans le param�tre de configuration "DOC_DELAY_WEEKSTART". Oracle : 1 = DIMANCHE selon param�tre
             d'installation des instance ProConcept. */
          lnTaskEndDateDayNumber  := to_char(lTaskEndDate, 'D') - lvWeekStart + 1;

          if sign(lnTaskEndDateDayNumber) <> 1 then
            lnTaskEndDateDayNumber  := lnTaskEndDateDayNumber + 7;
          end if;

          /* Calcul du d�calage : jour semaine du nettoyage moins jour de semaine fin op�ration */
          lnDecalage              := substr(lvGmpWorkshopCleaningDate, 5) - lnTaskEndDateDayNumber;

          if sign(lnDecalage) <> 1 then   /* Si jour de semaine d�pass�, semaine suivante */
            lnDecalage  := lnDecalage + 7;
          end if;
        elsif instr(lvGmpWorkshopCleaningDate, 'MONTH') = 1 then
          /* Calcul du d�calage : jour mois nettoyage moins jour du mois fin op�ration */
          lnDecalage  := substr(lvGmpWorkshopCleaningDate, 6) - to_char(lTaskEndDate, 'DD');

          if sign(lnDecalage) <> 1 then
            /* Si jour du mois d�pass�, d�calage = nb jour jusqu'� la fin du mois + jour du mois de la config. */
            lnDecalage  := last_day(lTaskEndDate) - lTaskEndDate + substr(lvGmpWorkshopCleaningDate, 6);
          end if;
        end if;

        /* Prochaine occurence du jour de nettoyage selon calendrier. Si pas ouvr�, on prend le prochain jour ouvr� */
        return PAC_I_LIB_SCHEDULE.getGivenMoreDaysNextOpenDate(idDate => lTaskEndDate, inDecalage => lnDecalage);
      end if;
    else
      return null;
    end if;
  end getChipRecoveryDate;

  /**
  * Description
  *    En fonction du calendrier par d�faut, cette fonction retourne la date de fin
  *    du recyclage de l'information copeaux re�ue en param�tre ainsi que du type
  *    de recyclage : INT = interne, EXT = externe TOT = total (INT + EXT).
  */
  function getEndRecyclingDate(
    iTaskLinkID     in FAL_TASK_CHIP_DETAIL.FAL_TASK_LINK_ID%type default null
  , iTaskLinkPropID in FAL_TASK_CHIP_DETAIL.FAL_TASK_LINK_PROP_ID%type
  , iAlloyID        in FAL_TASK_CHIP_DETAIL.GCO_ALLOY_ID%type
  , ivRecyclingType in varchar2
  )
    return date deterministic
  as
    lnChipRecyclingTime number;
    lTaskEndDate        date;
  begin
    /* R�cup�ration de la date de fin de l'op�ration */
    if iTaskLinkID is not null then
      lTaskEndDate  := FAL_LIB_TASK_LINK.getEndDate(inFalTaskLinkID => iTaskLinkID);
    else
      lTaskEndDate  := FAL_LIB_TASK_LINK_PROP.getEndDate(iTaskLinkPropID => iTaskLinkPropID);
    end if;

    /* R�cup�ration du temps en fonction du type de recyclage */
    if ivRecyclingType = 'INT' then
      lnChipRecyclingTime  := GCO_I_LIB_ALLOY.getChipInternalRecyclingTime(inGcoAlloyID => iAlloyID);
    elsif ivRecyclingType = 'EXT' then
      lnChipRecyclingTime  := GCO_I_LIB_ALLOY.getChipExternalRecyclingTime(inGcoAlloyID => iAlloyID);
    elsif ivRecyclingType = 'TOT' then
      lnChipRecyclingTime  :=
                 GCO_I_LIB_ALLOY.getChipInternalRecyclingTime(inGcoAlloyID => iAlloyID)
                 + GCO_I_LIB_ALLOY.getChipExternalRecyclingTime(inGcoAlloyID => iAlloyID);
    else
      lnChipRecyclingTime  := 0;
    end if;

    return FAL_SCHEDULE_FUNCTIONS.GetDecalageForwardDate(aFAL_FACTORY_FLOOR_ID      => 0
                                                       , aPAC_SUPPLIER_PARTNER_ID   => 0
                                                       , aPAC_CUSTOM_PARTNER_ID     => 0
                                                       , aPAC_DEPARTMENT_ID         => 0
                                                       , aHRM_PERSON_ID             => 0
                                                       , aCalendarID                => 0
                                                       , aFromDate                  => lTaskEndDate   --FAL_LIB_TASK_LINK.getEndDate(inFalTaskLinkID => lnFalTaskLinkID)
                                                       , aDecalage                  => ceil(lnChipRecyclingTime)   /* Arrondi sup., car sinon retourne null */
                                                        );
  end getEndRecyclingDate;

  /**
  * Description
  *    Retourne le poids r�el de copeaux de mati�re de base r�cup�r�e � l'op�ration.
  */
  function getRealRecupWeight(
    inFalTaskLinkID    in FAL_TASK_CHIP_DETAIL.FAL_TASK_LINK_ID%type
  , inGcoAlloyID       in FAL_TASK_CHIP_DETAIL.GCO_ALLOY_ID%type
  , inPercentBasisMat  in GCO_ALLOY_COMPONENT.GAC_RATE%type
  , inPercentRecovered in FAL_TASK_CHIP_DETAIL.TCH_PERCENT%type default 100
  )
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnRealRecupWeight FAL_WEIGH.FWE_WEIGHT_MAT%type;
  begin
    /* Somme des pes�es � l'op�ration en sortie pour l'alliage et l'op�ration */
    lnRealRecupWeight  :=
      (FAL_LIB_WEIGH.getSumWeightMatOut(inFalTaskLinkID   => inFalTaskLinkID
                                      , inGcoAlloyID      => inGcoAlloyID
                                      , inFweWaste        => 0
                                      , inFweTurnings     => 1
                                      , inCWeighType      => 2
                                       ) +
       FAL_LIB_WEIGH.getSumWeightMatOut(inFalTaskLinkID   => inFalTaskLinkID
                                      , inGcoAlloyID      => inGcoAlloyID
                                      , inFweWaste        => 0
                                      , inFweTurnings     => 1
                                      , inCWeighType      => 11
                                       )
      ) *
      (inPercentBasisMat * 0.01) *
      (inPercentRecovered * 0.01);
    return nvl(lnRealRecupWeight, 0);
  end getRealRecupWeight;

  /**
  * Description
  *    Retourne le poids th�orique de copeaux de mati�re de base r�cup�r�e � l'op�ration.
  */
  function getTheoRecupWeight(
    iLotID              in FAL_LOT.FAL_LOT_ID%type default null
  , iLotPropID          in FAL_LOT_PROP.FAL_LOT_PROP_ID%type default null
  , inLotTotalQty       in FAL_LOT.LOT_TOTAL_QTY%type
  , iGoodID             in FAL_LOT.GCO_GOOD_ID%type
  , iAlloyID            in FAL_TASK_CHIP_DETAIL.GCO_ALLOY_ID%type
  , inPercentBasisMat   in GCO_ALLOY_COMPONENT.GAC_RATE%type
  , inPercentRecovered  in FAL_TASK_CHIP_DETAIL.TCH_PERCENT%type
  , ivCWeightCalculMode in FAL_TASK_CHIP_DETAIL.C_WEIGHT_CALCUL_MODE%type
  )
    return FAL_WEIGH.FWE_WEIGHT_MAT%type
  as
    lnTheoRecupWeight FAL_WEIGH.FWE_WEIGHT_MAT%type;
    lCptGoodID        FAL_LOT_MATERIAL_LINK.GCO_GOOD_ID%type;
    lnLomFullReqQty   FAL_LOT_MATERIAL_LINK.LOM_FULL_REQ_QTY%type;
  begin
    /* Calcul du pourcentage r�cup�r� � l'op�ration */
    case ivCWeightCalculMode
      when '1' then   /* %Age poids investi produit termin� */
        lnTheoRecupWeight  :=
          inLotTotalQty *
          GCO_I_LIB_PRECIOUS_MAT.getWeightInvest(inGcoGoodID => iGoodID, inGcoAlloyID => iAlloyID) *
          (inPercentBasisMat * 0.01) *
          (inPercentRecovered * 0.01);
      when '2' then   /* %Age poids copeaux th�orique produit termin� */
        lnTheoRecupWeight  :=
          inLotTotalQty *
          GCO_I_LIB_PRECIOUS_MAT.getWeightChip(inGcoGoodID => iGoodID, inGcoAlloyID => iAlloyID) *
          (inPercentBasisMat * 0.01) *
          (inPercentRecovered * 0.01);
      when '3' then               /* %age du besoin total cpt d�riv� */
                      /* R�cup�ration de l'ID, de l'ID du bien et de la qt� demand�e du composant de type d�riv� comportant
                         l'alliage d�fini dans la d�finition de copeaux courante (iAlloyID) */
        if iLotID is not null then
          select lom.GCO_GOOD_ID
               , lom.LOM_FULL_REQ_QTY
            into lCptGoodID
               , lnLomFullReqQty
            from FAL_LOT_MATERIAL_LINK lom
               , FAL_LOT lot
               , FAL_TASK_LINK tal
               , FAL_TASK_CHIP_DETAIL tch
               , GCO_PRECIOUS_MAT gpm
           where lom.FAL_LOT_ID = iLotID   --60140820452
             and lom.C_KIND_COM = 2   /* Lien d�riv� */
             and lot.FAL_LOT_ID = lom.FAL_LOT_ID
             and tal.FAL_LOT_ID = lot.FAL_LOT_ID
             and tch.FAL_TASK_LINK_ID = tal.FAL_SCHEDULE_STEP_ID
             and gpm.GCO_GOOD_ID = LOM.GCO_GOOD_ID
             and gpm.GCO_ALLOY_ID = tch.GCO_ALLOY_ID
             and tch.C_WEIGHT_CALCUL_MODE = '3';
        else
          select lom.GCO_GOOD_ID
               , lom.LOM_FULL_REQ_QTY
            into lCptGoodID
               , lnLomFullReqQty
            from FAL_LOT_MAT_LINK_PROP lom
               , FAL_LOT_PROP lot
               , FAL_TASK_LINK_PROP tal
               , FAL_TASK_CHIP_DETAIL tch
               , GCO_PRECIOUS_MAT gpm
           where lom.FAL_LOT_PROP_ID = iLotPropID   --60140820452
             and lom.C_KIND_COM = 2   /* Lien d�riv� */
             and lot.FAL_LOT_PROP_ID = lom.FAL_LOT_PROP_ID
             and tal.FAL_LOT_PROP_ID = lot.FAL_LOT_PROP_ID
             and tch.FAL_TASK_LINK_PROP_ID = tal.FAL_TASK_LINK_PROP_ID
             and gpm.GCO_GOOD_ID = LOM.GCO_GOOD_ID
             and gpm.GCO_ALLOY_ID = tch.GCO_ALLOY_ID
             and tch.C_WEIGHT_CALCUL_MODE = '3';
        end if;

        lnTheoRecupWeight  :=
          lnLomFullReqQty *
          GCO_I_LIB_PRECIOUS_MAT.getWeightDeliver(inGcoGoodID => lCptGoodID, inGcoAlloyID => iAlloyID) *
          (inPercentBasisMat * 0.01) *
          (inPercentRecovered * 0.01);
    end case;

    return nvl(lnTheoRecupWeight, 0);
  exception
    when others then
      raise;
  end getTheoRecupWeight;
end FAL_LIB_TASK_CHIP;
