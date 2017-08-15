--------------------------------------------------------
--  DDL for Package Body DOC_PRC_PALLET
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_PALLET" 
is
  /**
  * procedure UpdateMeasurePallet
  * Description
  *   Calcul du poids net et brut de la palette en fonction des colis sélectionnés
  */
  procedure UpdateMeasurePallet(iPalletID in DOC_PACKING_PALLET.DOC_PACKING_PALLET_ID%type)
  is
    l_weight DOC_PACKING_PALLET.DPP_NET_WEIGHT_CALC%type;
    l_gross  DOC_PACKING_PALLET.DPP_GROSS_WEIGHT_CALC%type;
  begin
    -- Calculer la somme des poids net et brut des colis présents sur la palette
    select nvl(sum(PAR_NET_WEIGHT_CALC), 0)
         , nvl(sum(PAR_GROSS_WEIGHT_CALC), 0)
      into l_weight
         , l_gross
      from DOC_PACKING_PARCEL
     where DOC_PACKING_PALLET_ID = iPalletID;

    -- Mise à jour des nouvelles valeurs calculées
    update DOC_PACKING_PALLET
       set DPP_NET_WEIGHT_CALC = l_weight
         , DPP_GROSS_WEIGHT_CALC = l_gross
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_PACKING_PALLET_ID = iPalletID;
  end UpdateMeasurePallet;

  /**
  * procedure PurgePallet
  * Description
  *   Supprimer les palettes sans détail
  */
  procedure PurgePallet(iPackingListID in DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type)
  is
  begin
    delete from DOC_PACKING_PALLET DPP
          where not exists(select 1
                             from DOC_PACKING_PARCEL PAR
                            where PAR.DOC_PACKING_PALLET_ID = DPP.DOC_PACKING_PALLET_ID)
            and DPP.DOC_PACKING_LIST_ID = iPackingListID;
  end PurgePallet;

  /**
  * procedure RenumberPallet
  * Description
  *   Renuméroter les palettes
  */
  procedure RenumberPallet(iPackingListID in DOC_PACKING_LIST.DOC_PACKING_LIST_ID%type)
  is
    l_ParcelNumber DOC_PACKING_PALLET.DPP_NUMBER%type;
  begin
    l_ParcelNumber  := 1;

    for tplPallet in (select   DPP.DPP_NUMBER
                             , DPP.DOC_PACKING_PALLET_ID
                          from DOC_PACKING_PALLET DPP
                         where DPP.DOC_PACKING_LIST_ID = iPackingListID
                      order by DPP.DPP_NUMBER) loop
      update DOC_PACKING_PALLET
         set DPP_NUMBER = l_ParcelNumber
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_PACKING_PALLET_ID = tplPallet.DOC_PACKING_PALLET_ID;

      l_ParcelNumber  := l_ParcelNumber + 1;
    end loop;
  end RenumberPallet;

  /**
  * function
  * Description getPalletId
  *   Retourne l'id de la palette contenant le colis
  */
  function getPalletId(iParcelID in DOC_PACKING_PARCEL.DOC_PACKING_PARCEL_ID%type)
    return DOC_PACKING_PALLET.DOC_PACKING_PALLET_ID%type
  is
    l_PalletID DOC_PACKING_PALLET.DOC_PACKING_PALLET_ID%type;
  begin
    select DOC_PACKING_PALLET_ID
      into l_PalletID
      from DOC_PACKING_PARCEL
     where DOC_PACKING_PARCEL_ID = iParcelID;

    return l_PalletID;
  end getPalletId;

  /**
  * procedure CreateLinkPallet
  * Description
  *   Création d'un lien entre un colis et une palette
  */
  procedure CreateLinkPallet(iPalletID in DOC_PACKING_PALLET.DOC_PACKING_PALLET_ID%type, iParcelID in DOC_PACKING_PARCEL.DOC_PACKING_PARCEL_ID%type)
  is
  begin
    -- Création du lien
    update DOC_PACKING_PARCEL
       set DOC_PACKING_PALLET_ID = iPalletID
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_PACKING_PARCEL_ID = iParcelID;

    -- Mise à jour des poids de la palette
    UpdateMeasurePallet(iPalletID);
  end CreateLinkPallet;

  /**
  * procedure DeleteLinkPallet
  * Description
  *   Effacement d'un lien entre un colis et une palette
  */
  procedure DeleteLinkPallet(iPalletID in DOC_PACKING_PALLET.DOC_PACKING_PALLET_ID%type, iParcelID in DOC_PACKING_PARCEL.DOC_PACKING_PARCEL_ID%type)
  is
  begin
    -- Effacement du lien
    update DOC_PACKING_PARCEL
       set DOC_PACKING_PALLET_ID = null
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_PACKING_PARCEL_ID = iParcelID;

    -- Mise à jour des poids de la palette
    UpdateMeasurePallet(iPalletID);
  end DeleteLinkPallet;
end DOC_PRC_PALLET;
