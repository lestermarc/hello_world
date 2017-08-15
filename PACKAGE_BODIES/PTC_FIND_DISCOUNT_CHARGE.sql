--------------------------------------------------------
--  DDL for Package Body PTC_FIND_DISCOUNT_CHARGE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PTC_FIND_DISCOUNT_CHARGE" 
is
  -- Retoune le résultat mis à jour par la dernière procedure appelée
  -- Ceci car un paramètre OUT de type varchar2 ne peut retourner plus de 255 caratères
  -- Et qu'il n'est pas possible de faire une fonction suite a un pragma incompatible
  -- avec le package DBMS_SQL.
  -- Mais la valeur de retour d'une fonction étant limitée à 2000 caratères,
  -- le principe de cette fonction est de renvoyer le résultat par paquets
  -- de 2000 caractères au maximum.
  -- Lors du premier appel de la fonction, on enverra les 2000 premiers caractères,
  -- puis lors de l'appel suivant les 2000 suivant jusqu'à ce qu'il n'y en ait plus.
  function GetResultList
    return varchar2
  is
    result varchar2(2000);
    i      integer;
  begin
    -- teste si la valeur à renvoyer est plus grande que 2000 caractères
    if length(ResultList) > 2000 then
      i                                    := 2000;

      -- recherche de la position de la dernière virgule avant le 2000ème caractère
      while substr(ResultList, i, 1) <> ',' loop
        i  := i - 1;
      end loop;

      -- Assignation de la chaine de résultat au paramètre de retour de valeur
      result                               := substr(ResultList, 1, i);
      -- Mise à jour de la variable globale de résultat en enlevant les valeurs
      -- que la fonction va retourner
      PTC_FIND_DISCOUNT_CHARGE.ResultList  := substr(ResultList, i + 1);
    else
      -- Si le résultat est plus peiti que 2000 caratère, on renvoie le résultat
      -- sans aucun traitement
      result                               := ResultList;
      -- Mise à zéro de la variable globale
      PTC_FIND_DISCOUNT_CHARGE.ResultList  := '';
    end if;

    return result;
  end GetResultList;

  /**
  * Description
  *    Retourne le résultat par paquets de 2000 caractères
  *    Appeler cette fonction après avoir appelé la procédure de recherche
  *    des remises/taxes (TestDetDiscountCharge, TestGrpDiscountCharge, TestTotDiscountCharge)
  */
  function GetDCResultList(aDC in varchar2, aType in PTC_CHARGE.C_CHARGE_TYPE%type)
    return varchar2
  is
    tmpList varchar2(32000);
    result  varchar2(2000);
    i       integer;
  begin
    if aDC = 'DISCOUNT' then
      if aType = 'DET' then
        tmpList  := ResDetDiscountList;
      elsif aType = 'GRP' then
        tmpList  := ResGrpDiscountList;
      elsif aType = 'PMM' then
        tmpList  := ResPmmDiscountList;
      elsif aType = 'POR' then
        tmpList  := ResPorDiscountList;
      elsif aType = 'DOR' then
        tmpList  := ResDorDiscountList;
      else
        tmpList  := ResTotDiscountList;
      end if;
    else
      if aType = 'DET' then
        tmpList  := ResDetChargeList;
      elsif aType = 'GRP' then
        tmpList  := ResGrpChargeList;
      elsif aType = 'PMM' then
        tmpList  := ResPmmChargeList;
      elsif aType = 'POR' then
        tmpList  := ResPorChargeList;
      elsif aType = 'DOR' then
        tmpList  := ResDorChargeList;
      else
        tmpList  := ResTotChargeList;
      end if;
    end if;

    -- teste si la valeur à renvoyer est plus grande que 2000 caractères
    if length(tmpList) > 2000 then
      i        := 2000;

      -- recherche de la position de la dernière virgule avant le 2000ème caractère
      while substr(tmpList, i, 1) <> ',' loop
        i  := i - 1;
      end loop;

      -- Assignation de la chaine de résultat au paramètre de retour de valeur
      result   := substr(TmpList, 1, i);
      -- Mise à jour de la variable globale de résultat en enlevant les valeurs
      -- que la fonction va retourner
      TmpList  := substr(TmpList, i + 1);
    else
      -- Si le résultat est plus peiti que 2000 caratère, on renvoie le résultat
      -- sans aucun traitement
      result   := tmpList;
      -- Mise à zéro de la variable globale
      TmpList  := '';
    end if;

    if aDC = 'DISCOUNT' then
      if aType = 'DET' then
        ResDetDiscountList  := tmpList;
      elsif aType = 'GRP' then
        ResGrpDiscountList  := tmpList;
      elsif aType = 'PMM' then
        ResPmmDiscountList  := tmpList;
      elsif aType = 'POR' then
        ResPorDiscountList  := tmpList;
      elsif aType = 'DOR' then
        ResDorDiscountList  := tmpList;
      else
        ResTotDiscountList  := tmpList;
      end if;
    else
      if aType = 'DET' then
        ResDetChargeList  := TmpList;
      elsif aType = 'GRP' then
        ResGrpChargeList  := tmpList;
      elsif aType = 'PMM' then
        ResPmmChargeList  := tmpList;
      elsif aType = 'POR' then
        ResPorChargeList  := tmpList;
      elsif aType = 'DOR' then
        ResDorChargeList  := tmpList;
      else
        ResTotChargeList  := TmpList;
      end if;
    end if;

    return result;
  end GetDCResultList;

  /**
  * Description
  *     Recherche les remises applicables à un gabarit, un tiers et un bien en mode DETAIL (remises de position)
  *     Mise à jour des variables globales ResDetDiscountList et ResDetChargeList dont les valeurs doivent être récupérée
  *     par les fonctions GetDCResultList
  */
  procedure TestDetDiscountCharge(
    GaugeId     in     DOC_GAUGE.DOC_GAUGE_ID%type
  , ThirdId     in     PAC_THIRD.PAC_THIRD_ID%type
  , RecordId    in     DOC_RECORD.DOC_RECORD_ID%type
  , GoodId      in     GCO_GOOD.GCO_GOOD_ID%type
  , CDType      in     PTC_CHARGE.C_CHARGE_TYPE%type
  , Dateref     in     date
  , blnCharge   in     DOC_GAUGE_STRUCTURED.GAS_CHARGE%type
  , blnDiscount in     DOC_GAUGE_STRUCTURED.GAS_DISCOUNT%type
  , Changed     in out number
  , Recalc      in     number default 0
  )
  is
    Filter varchar2(2000);
  begin
    Changed             := 0;

    -- Si on a changé de gabarit, de type ou de genre on recherche tout
    if    Recalc = 1
       or GaugeId <> OldDetGaugeId
       or CDType <> OldDetType
       or DateRef <> OldDetDateRef then
      -- si on fait la recherche des remises
      if blnDiscount = 1 then
        TestDiscountGauge(GaugeId, '', DateRef, 'DET', CDType);
        DetDiscountGaugeList  := ResultList;
      end if;

      -- si on fait la recherche des taxes
      if blnCharge = 1 then
        TestChargeGauge(GaugeId, '', DateRef, 'DET', CDType);
        DetChargeGaugeList  := ResultList;
      end if;

      DetDiscountThirdList   := '';
      DetDiscountRecordList  := '';
      DetDiscountGoodList    := '';
      DetDiscountList        := '';
      ResDetDiscountList     := '';
      DetChargeThirdList     := '';
      DetChargeRecordList    := '';
      DetChargeGoodList      := '';
      DetChargeList          := '';
      ResDetChargeList       := '';
      OldDetThirdId          := -1;
      OldDetRecordId         := -1;
      OldDetGoodId           := -1;
      OldDetDateRef          := null;
    end if;

    -- Si on a changé de tiers, on garde les remises/taxes présélectionnées
    -- pour le gabarit
    if ThirdId <> OldDetThirdId then
      -- si on fait la recherche des remises
      if blnDiscount = 1 then
        TestDiscountThird(ThirdId, DetDiscountGaugeList, DateRef, 'DET', CDType);
        DetDiscountThirdList  := ResultList;
      end if;

      -- si on fait la recherche des taxes
      if blnCharge = 1 then
        TestChargeThird(ThirdId, DetChargeGaugeList, DateRef, 'DET', CDType);
        DetChargeThirdList  := ResultList;
      end if;

      OldDetRecordId  := -1;
      OldDetGoodId    := -1;
    end if;

    -- Si on a changé de dossier, on garde les remises/taxes présélectionnées
    -- pour le gabarit
    if RecordId <> OldDetRecordId then
      -- si on fait la recherche des remises
      if blnDiscount = 1 then
        TestDiscountRecord(RecordId, DetDiscountThirdList, DateRef, 'DET', CDType);
        DetDiscountRecordList  := ResultList;
      end if;

      -- si on fait la recherche des taxes
      if blnCharge = 1 then
        TestChargeRecord(RecordId, DetChargeThirdList, DateRef, 'DET', CDType);
        DetChargeRecordList  := ResultList;
      end if;

      OldDetGoodId  := -1;
    end if;

    -- Si on a changé de bien, on garde les remises/taxes présélectionnées
    -- pour le gabarit et le tiers
    if GoodId <> OldDetGoodId then
      -- si on fait la recherche des remises
      if blnDiscount = 1 then
        TestDiscountGood(GoodId, DetDiscountRecordList, DateRef, 'DET', CDType);
        DetDiscountGoodList  := ResultList;
      end if;

      -- si on fait la recherche des taxes
      if blnCharge = 1 then
        TestChargeGood(GoodId, DetChargeRecordList, DateRef, 'DET', CDType);
        DetChargeGoodList  := ResultList;
      end if;

      -- Indique qu'il y a eu un changement
      if not(    DetChargeList = DetChargeGoodList
             and DetDiscountList = DetDiscountGoodList) then
        Changed  := 1;
      end if;

      DetChargeList    := DetChargeGoodList;
      DetDiscountList  := DetDiscountGoodList;
    end if;

    -- mise à jour des anciennes valeurs pour le prochain passage
    OldDetGaugeId       := GaugeId;
    OldDetThirdId       := ThirdId;
    OldDetRecordId      := RecordId;
    OldDetGoodId        := GoodId;
    OldDetType          := CDType;
    OldDetDateRef       := DateRef;
    -- Assignation des variables résultats
    ResDetChargeList    := DetChargeList;
    ResDetDiscountList  := DetDiscountList;
  end TestDetDiscountCharge;

  /**
  * Description
  *     Recherche des remises par groupes de biens
  *     Recherche les remises applicables à un gabarit, un tiers , un dossier et un groupe de biens (remises de position)
  *     Mise à jour des variables globales ResGrpDiscountList et ResGrpChargeList dont les valeurs doivent être récupérée
  *     par les fonctions GetDCResultList
  */
  procedure TestGrpDiscountCharge(
    GaugeId     in     DOC_GAUGE.DOC_GAUGE_ID%type
  , ThirdId     in     PAC_THIRD.PAC_THIRD_ID%type
  , RecordId    in     DOC_RECORD.DOC_RECORD_ID%type
  , dicGroup    in     ptc_charge.DIC_PTC_GOOD_GROUP_ID%type
  , CDType      in     PTC_CHARGE.C_CHARGE_TYPE%type
  , Dateref     in     date
  , blnCharge   in     DOC_GAUGE_STRUCTURED.GAS_CHARGE%type
  , blnDiscount in     DOC_GAUGE_STRUCTURED.GAS_DISCOUNT%type
  , Changed     in out number
  , Recalc      in     number default 0
  )
  is
    Filter varchar2(2000);
  begin
    Changed             := 0;

    -- Si on a changé de gabarit, de type ou de genre on recherche tout
    if    Recalc = 1
       or GaugeId <> OldGrpGaugeId
       or CDType <> OldGrpType
       or DateRef <> OldGrpDateRef then
      -- si on fait la recherche des remises
      if blnDiscount = 1 then
        TestDiscountGauge(GaugeId, '', DateRef, 'GRP', CDType);
        GrpDiscountGaugeList  := ResultList;
      end if;

      -- si on fait la recherche des taxes
      if blnCharge = 1 then
        TestChargeGauge(GaugeId, '', DateRef, 'GRP', CDType);
        GrpChargeGaugeList  := ResultList;
      end if;

      OldGrpThirdId          := -1;
      OldGrpRecordId         := -1;
      OldGrpDicGroup         := 'NULL';
      OldGrpDateRef          := null;
      GrpDiscountThirdList   := '';
      GrpDiscountRecordList  := '';
      GrpDiscountGoodList    := '';
      GrpDiscountList        := '';
      ResGrpDiscountList     := '';
      GrpChargeThirdList     := '';
      GrpChargeRecordList    := '';
      GrpChargeGoodList      := '';
      GrpChargeList          := '';
      ResGrpChargeList       := '';
    end if;

    -- Si on a changé de tiers, on garde les remises/taxes présélectionnées
    -- pour le gabarit
    if ThirdId <> OldGrpThirdId then
      -- si on fait la recherche des remises
      if blnDiscount = 1 then
        TestDiscountThird(ThirdId, GrpDiscountGaugeList, DateRef, 'GRP', CDType);
        GrpDiscountThirdList  := ResultList;
      end if;

      -- si on fait la recherche des taxes
      if blnCharge = 1 then
        TestChargeThird(ThirdId, GrpChargeGaugeList, DateRef, 'GRP', CDType);
        GrpChargeThirdList  := ResultList;
      end if;

      OldGrpRecordId  := -1;
      OldGrpDicGroup  := 'NULL';
    end if;

    -- Si on a changé de dossier, on garde les remises/taxes présélectionnées
    -- pour le gabarit
    if RecordId <> OldGrpRecordId then
      -- si on fait la recherche des remises
      if blnDiscount = 1 then
        TestDiscountRecord(RecordId, GrpDiscountThirdList, DateRef, 'GRP', CDType);
        GrpDiscountRecordList  := ResultList;
      end if;

      -- si on fait la recherche des taxes
      if blnCharge = 1 then
        TestChargeRecord(RecordId, GrpChargeThirdList, DateRef, 'GRP', CDType);
        GrpChargeRecordList  := ResultList;
      end if;

      OldGrpDicGroup  := 'NULL';
    end if;

    -- Si on a changé de bien, on garde les remises/taxes présélectionnées
    -- pour le gabarit et le tiers
    if dicGroup <> OldGrpDicGroup then
      -- si on fait la recherche des remises
      if blnDiscount = 1 then
        TestDiscountGoodGroup(dicGroup, GrpDiscountRecordList, DateRef, CDType);
        GrpDiscountGoodList  := ResultList;
      end if;

      -- si on fait la recherche des taxes
      if blnCharge = 1 then
        TestChargeGoodGroup(dicGroup, GrpChargeRecordList, DateRef, CDType);
        GrpChargeGoodList  := ResultList;
      end if;

      -- Indique qu'il y a eu un changement
      if not(    GrpChargeList = GrpChargeGoodList
             and GrpDiscountList = GrpDiscountGoodList) then
        Changed  := 1;
      end if;

      GrpChargeList    := GrpChargeGoodList;
      GrpDiscountList  := GrpDiscountGoodList;
    end if;

    -- mise à jour des anciennes valeurs pour le prochain passage
    OldGrpGaugeId       := GaugeId;
    OldGrpThirdId       := ThirdId;
    OldGrpRecordId      := RecordId;
    OldGrpDicGroup      := dicGroup;
    OldGrpType          := CDType;
    OldGrpDateRef       := DateRef;
    -- Assignation des variables résultats
    ResGrpChargeList    := GrpChargeList;
    ResGrpDiscountList  := GrpDiscountList;
  end TestGrpDiscountCharge;

  /**
  * Description
  *     Recherche des remises/taxes de type arrondi position
  *     Mise à jour des variables globales PorDiscountList et PorChargeList dont les valeurs doivent être récupérée
  *     par les fonctions GetDCResultList
  */
  procedure TestPorDiscountCharge(
    GaugeId     in     DOC_GAUGE.DOC_GAUGE_ID%type
  , ThirdId     in     PAC_THIRD.PAC_THIRD_ID%type
  , RecordId    in     DOC_RECORD.DOC_RECORD_ID%type
  , GoodId      in     GCO_GOOD.GCO_GOOD_ID%type
  , vChargeType in     PTC_CHARGE.C_CHARGE_TYPE%type
  , Dateref     in     date
  , Changed     in out number
  , Recalc      in     number default 0
  )
  is
  begin
    Changed             := 0;

    -- Si on a changé de gabarit, de type ou de genre on recherche tout
    if    Recalc = 1
       or GaugeId <> OldPorGaugeId
       or RecordId <> OldPorRecordId
       or GoodId <> OldPorGoodId
       or DateRef <> OldPorDateRef then
      TestDiscountGauge(GaugeId, '', DateRef, 'POR', vChargeType);
      PorDiscountGaugeList   := ResultList;
      TestChargeGauge(GaugeId, '', DateRef, 'POR', vChargeType);
      PorChargeGaugeList     := ResultList;
      OldPorThirdId          := -1;
      OldPorRecordId         := -1;
      OldPorGoodId           := -1;
      OldPorDateRef          := null;
      PorDiscountThirdList   := '';
      PorDiscountRecordList  := '';
      PorDiscountGoodList    := '';
      PorDiscountList        := '';
      ResPorDiscountList     := '';
      PorChargeThirdList     := '';
      PorChargeRecordList    := '';
      PorChargeGoodList      := '';
      PorChargeList          := '';
      ResPorChargeList       := '';
    end if;

    -- Si on a changé de tiers, on garde les remises/taxes présélectionnées
    -- pour le gabarit
    if ThirdId <> OldPorThirdId then
      TestDiscountThird(ThirdId, PorDiscountGaugeList, DateRef, 'POR', vChargeType);
      PorDiscountThirdList  := ResultList;
      TestChargeThird(ThirdId, PorChargeGaugeList, DateRef, 'POR', vChargeType);
      PorChargeThirdList    := ResultList;
      OldPorRecordId        := -1;
    end if;

    -- Si on a changé de dossier, on garde les remises/taxes présélectionnées
    -- pour le gabarit
    if RecordId <> OldPorRecordId then
      TestDiscountRecord(RecordId, PorDiscountThirdList, DateRef, 'POR', vChargeType);
      PorDiscountRecordList  := ResultList;
      TestChargeRecord(RecordId, PorChargeThirdList, DateRef, 'POR', vChargeType);
      PorChargeRecordList    := ResultList;
      OldPorGoodId           := -1;
    end if;

    -- Si on a changé de dossier, on garde les remises/taxes présélectionnées
    -- pour le gabarit
    if GoodId <> OldPorGoodId then
      TestDiscountGood(GoodId, PorDiscountRecordList, DateRef, 'POR', vChargeType);
      PorDiscountGoodList  := ResultList;
      TestChargeRecord(RecordId, PorChargeRecordList, DateRef, 'POR', vChargeType);
      PorChargeGoodList    := ResultList;
      PorChargeList        := PorChargeGoodList;
      PorDiscountList      := PorDiscountGoodList;
    end if;

    -- mise à jour des anciennes valeurs pour le prochain passage
    OldPorGaugeId       := GaugeId;
    OldPorThirdId       := ThirdId;
    OldPorRecordId      := RecordId;
    OldPorGoodId        := GoodId;
    OldPorDateRef       := DateRef;
    -- Assignation des variables résultats (un seul résultat)
    ResPorChargeList    := '';
    ResPorDiscountList  := '';

    if PorDiscountList <> ',0,' then
      ResPorDiscountList  := ',' || ExtractLine(PorDiscountList, 2, ',') || ',';
    elsif PorChargeList <> ',0,' then
      ResPorChargeList  := ',' || ExtractLine(PorChargeList, 2, ',') || ',';
    end if;
  end TestPorDiscountCharge;

  /**
  * Description
  *     Recherche des remises/taxes de type arrondi position
  *     Mise à jour des variables globales DorDiscountList et DorChargeList dont les valeurs doivent être récupérée
  *     par les fonctions GetDCResultList
  */
  procedure TestDorDiscountCharge(
    GaugeId     in     DOC_GAUGE.DOC_GAUGE_ID%type
  , ThirdId     in     PAC_THIRD.PAC_THIRD_ID%type
  , RecordId    in     DOC_RECORD.DOC_RECORD_ID%type
  , vChargeType in     PTC_CHARGE.C_CHARGE_TYPE%type
  , Dateref     in     date
  , Changed     in out number
  , Recalc      in     number default 0
  )
  is
  begin
    Changed             := 0;

    -- Si on a changé de gabarit, de type ou de genre on recherche tout
    if    Recalc = 1
       or GaugeId <> OldDorGaugeId
       or DateRef <> OldDorDateRef then
      TestDiscountGauge(GaugeId, '', DateRef, 'DOR', vChargeType);
      DorDiscountGaugeList   := ResultList;
      TestChargeGauge(GaugeId, '', DateRef, 'DOR', vChargeType);
      DorChargeGaugeList     := ResultList;
      OldDorThirdId          := -1;
      OldDorRecordId         := -1;
      OldDorDateRef          := null;
      DorDiscountThirdList   := '';
      DorDiscountRecordList  := '';
      DorDiscountList        := '';
      ResDorDiscountList     := '';
      DorChargeThirdList     := '';
      DorChargeRecordList    := '';
      DorChargeList          := '';
      ResDorChargeList       := '';
    end if;

    -- Si on a changé de tiers, on garde les remises/taxes présélectionnées
    -- pour le gabarit
    if ThirdId <> OldDorThirdId then
      TestDiscountThird(ThirdId, DorDiscountGaugeList, DateRef, 'DOR', vChargeType);
      DorDiscountThirdList  := ResultList;
      TestChargeThird(ThirdId, DorChargeGaugeList, DateRef, 'DOR', vChargeType);
      DorChargeThirdList    := ResultList;
      OldDorRecordId        := -1;
    end if;

    -- Si on a changé de dossier, on garde les remises/taxes présélectionnées
    -- pour le gabarit
    if RecordId <> OldDorRecordId then
      TestDiscountRecord(RecordId, DorDiscountThirdList, DateRef, 'DOR', vChargeType);
      DorDiscountRecordList  := ResultList;
      TestChargeRecord(RecordId, DorChargeThirdList, DateRef, 'DOR', vChargeType);
      DorChargeRecordList    := ResultList;
      DorChargeList          := DorChargeRecordList;
      DorDiscountList        := DorDiscountRecordList;
    end if;

    -- mise à jour des anciennes valeurs pour le prochain passage
    OldDorGaugeId       := GaugeId;
    OldDorThirdId       := ThirdId;
    OldDorRecordId      := RecordId;
    OldDorDateRef       := DateRef;
    -- Assignation des variables résultats (un seul résultat)
    ResDorChargeList    := '';
    ResDorDiscountList  := '';

    if DorDiscountList <> ',0,' then
      ResDorDiscountList  := ',' || ExtractLine(DorDiscountList, 2, ',') || ',';
    elsif DorChargeList <> ',0,' then
      ResDorChargeList  := ',' || ExtractLine(DorChargeList, 2, ',') || ',';
    end if;
  end TestDorDiscountCharge;

  /**
  * Description
  *     Recherche des remises pour les marges matières précieuses
  *     Recherche les remises applicables à un gabarit, un tiers , un dossier et un groupe de biens (remises de position)
  *     Mise à jour des variables globales ResPmmDiscountList et ResPmmChargeList dont les valeurs doivent être récupérée
  *     par les fonctions GetDCResultList
  */
  procedure TestPmmDiscountCharge(
    aGaugeId        in     DOC_GAUGE.DOC_GAUGE_ID%type
  , aThirdId        in     PAC_THIRD.PAC_THIRD_ID%type
  , aRecordId       in     DOC_RECORD.DOC_RECORD_ID%type
  , aPreciousGoodID in     GCO_GOOD.GCO_GOOD_ID%type
  , aCDType         in     PTC_CHARGE.C_CHARGE_TYPE%type
  , aDateref        in     date
--  , ablnCharge   in     DOC_GAUGE_STRUCTURED.GAS_CHARGE%type
--  , ablnDiscount in     DOC_GAUGE_STRUCTURED.GAS_DISCOUNT%type
  , aChanged        in out number
  , aRecalc         in     number default 0
  )
  is
    Filter varchar2(2000);
  begin
    aChanged              := 0;

    -- Si on a changé de gabarit, de type ou de genre on recherche tout
    if    aRecalc = 1
       or aGaugeId <> OldPmmGaugeId
       or aCDType <> OldPmmType
       or aDateRef <> OldPmmDateRef then
      -- si on fait la recherche des remises
      --if aBlnDiscount = 1 then
      TestDiscountGauge(aGaugeId, '', aDateRef, 'PMM', aCDType);
      PmmDiscountGaugeList   := ResultList;
      --end if;

      -- si on fait la recherche des taxes
      --if aBlnCharge = 1 then
      TestChargeGauge(aGaugeId, '', aDateRef, 'PMM', aCDType);
      PmmChargeGaugeList     := ResultList;
      --end if;
      OldPmmThirdId          := -1;
      OldPmmRecordId         := -1;
      OldPmmPreciousGoodId   := -1;
      OldPmmDateRef          := null;
      PmmDiscountThirdList   := '';
      PmmDiscountRecordList  := '';
      PmmDiscountGoodList    := '';
      PmmDiscountList        := '';
      ResPmmDiscountList     := '';
      PmmChargeThirdList     := '';
      PmmChargeRecordList    := '';
      PmmChargeGoodList      := '';
      PmmChargeList          := '';
      ResPmmChargeList       := '';
    end if;

    -- Si on a changé de tiers, on garde les remises/taxes présélectionnées
    -- pour le gabarit
    if aThirdId <> OldPmmThirdId then
      -- si on fait la recherche des remises
      --if aBlnDiscount = 1 then
      TestDiscountThird(aThirdId, PmmDiscountGaugeList, aDateRef, 'PMM', aCDType);
      PmmDiscountThirdList  := ResultList;
      --end if;

      -- si on fait la recherche des taxes
      --if aBlnCharge = 1 then
      TestChargeThird(aThirdId, PmmChargeGaugeList, aDateRef, 'PMM', aCDType);
      PmmChargeThirdList    := ResultList;
      --end if;
      OldPmmRecordId        := -1;
      OldPmmPreciousGoodId  := -1;
    end if;

    -- Si on a changé de dossier, on garde les remises/taxes présélectionnées
    -- pour le gabarit
    if aRecordId <> OldPmmRecordId then
      -- si on fait la recherche des remises
      --if aBlnDiscount = 1 then
      TestDiscountRecord(aRecordId, PmmDiscountThirdList, aDateRef, 'PMM', aCDType);
      PmmDiscountRecordList  := ResultList;
      --end if;

      -- si on fait la recherche des taxes
      --if aBlnCharge = 1 then
      TestChargeRecord(aRecordId, PmmChargeThirdList, aDateRef, 'PMM', aCDType);
      PmmChargeRecordList    := ResultList;
      --end if;
      OldPmmPreciousGoodId   := -1;
    end if;

    -- Si on a changé de bien, on garde les remises/taxes présélectionnées
    -- pour le gabarit et le tiers
    if aPreciousGoodId <> OldPmmPreciousGoodId then
      -- si on fait la recherche des remises
      --if aBlnDiscount = 1 then
      TestDiscountGood(aPreciousGoodID, PmmDiscountRecordList, aDateRef, 'PMM', aCDType);
      PmmDiscountGoodList  := ResultList;
      --end if;

      -- si on fait la recherche des taxes
      --if aBlnCharge = 1 then
      TestChargeGood(aPreciousGoodID, PmmChargeRecordList, aDateRef, 'PMM', aCDType);
      PmmChargeGoodList    := ResultList;

      --end if;

      -- Indique qu'il y a eu un changement
      if not(    PmmChargeList = PmmChargeGoodList
             and PmmDiscountList = PmmDiscountGoodList) then
        aChanged  := 1;
      end if;

      PmmChargeList        := PmmChargeGoodList;
      PmmDiscountList      := PmmDiscountGoodList;
    end if;

    -- mise à jour des anciennes valeurs pour le prochain passage
    OldPmmGaugeId         := aGaugeId;
    OldPmmThirdId         := aThirdId;
    OldPmmRecordId        := aRecordId;
    OldPmmPreciousGoodId  := aPreciousGoodID;
    OldPmmType            := aCDType;
    OldPmmDateRef         := aDateRef;
    -- Assignation des variables résultats
    ResPmmChargeList      := PmmChargeList;
    ResPmmDiscountList    := PmmDiscountList;
  end TestPmmDiscountCharge;

  /**
  * Description
  *    Recherche les taxes applicables à un gabarit, un tiers et un dossier en mode TOTAL (taxes de pied)
  *     Mise à jour des variables globales ResTotDiscountList et ResTotChargeList dont les valeurs doivent être récupérée
  *     par les fonctions GetDCResultList
  */
  procedure TestTotDiscountCharge(
    GaugeId     in     DOC_GAUGE.DOC_GAUGE_ID%type
  , ThirdId     in     PAC_THIRD.PAC_THIRD_ID%type
  , RecordId    in     DOC_RECORD.DOC_RECORD_ID%type
  , CDType      in     PTC_CHARGE.C_CHARGE_TYPE%type
  , Dateref     in     date
  , blnCharge   in     DOC_GAUGE_STRUCTURED.GAS_CHARGE%type
  , blnDiscount in     DOC_GAUGE_STRUCTURED.GAS_DISCOUNT%type
  , Changed     in out number
  , Recalc      in     number default 0
  )
  is
    Filter varchar2(2000);
  begin
    Changed             := 0;

    -- Si on a changé de gabarit, de type ou de genre on recherche tout
    if    Recalc = 1
       or GaugeId <> OldTotGaugeId
       or CDType <> OldTotType
       or DateRef <> OldTotDateRef then
      -- si on fait la recherche des remises
      if blnDiscount = 1 then
        TestDiscountGauge(GaugeId, '', DateRef, 'TOT', CDType);
        TotDiscountGaugeList  := ResultList;
      end if;

      -- si on fait la recherche des taxes
      if blnCharge = 1 then
        TestChargeGauge(GaugeId, '', DateRef, 'TOT', CDType);
        TotChargeGaugeList  := ResultList;
      end if;

      OldTotThirdId          := -1;
      OldTotRecordId         := -1;
      OldTotDateRef          := null;
      TotDiscountThirdList   := '';
      TotDiscountRecordList  := '';
      TotDiscountList        := '';
      ResTotDiscountList     := '';
      TotChargeThirdList     := '';
      TotChargeRecordList    := '';
      TotChargeList          := '';
      ResTotChargeList       := '';
    end if;

    -- Si on a changé de tiers, on garde les remises/taxes présélectionnées
    -- pour le gabarit
    if ThirdId <> OldTotThirdId then
      -- si on fait la recherche des remises
      if blnDiscount = 1 then
        TestDiscountThird(ThirdId, TotDiscountGaugeList, DateRef, 'TOT', CDType);
        TotDiscountThirdList  := ResultList;
      end if;

      -- si on fait la recherche des taxes
      if blnCharge = 1 then
        TestChargeThird(ThirdId, TotChargeGaugeList, DateRef, 'TOT', CDType);
        TotChargeThirdList  := ResultList;
      end if;

      OldTotRecordId  := -1;
    end if;

    -- Si on a changé de dossiers, on garde les remises/taxes présélectionnées
    -- pour le gabarit
    if RecordId <> OldTotRecordId then
      -- si on fait la recherche des remises
      if blnDiscount = 1 then
        TestDiscountRecord(RecordId, TotDiscountThirdList, DateRef, 'TOT', CDType);
        TotDiscountRecordList  := ResultList;
      end if;

      -- si on fait la recherche des taxes
      if blnCharge = 1 then
        TestChargeRecord(RecordId, TotChargeThirdList, DateRef, 'TOT', CDType);
        TotChargeRecordList  := ResultList;
      end if;

      -- Indique qu'il y a eu un changement
      if not(    TotChargeList = TotChargeRecordList
             and TotDiscountList = TotDiscountRecordList) then
        Changed  := 1;
      end if;

      TotChargeList    := TotChargeRecordList;
      TotDiscountList  := TotDiscountRecordList;
    end if;

    -- mise à jour des anciennes valeurs pour le prochain passage
    OldTotGaugeId       := GaugeId;
    OldTotThirdId       := ThirdId;
    OldTotRecordId      := RecordId;
    OldTotType          := CDType;
    OldTotDateRef       := DateRef;
    -- Assignation des variables résultats
    ResTotChargeList    := TotChargeList;
    ResTotDiscountList  := TotDiscountList;
  end TestTotDiscountCharge;

  /**
  * Description
  *     Recherche les taxes applicables à un gabarit
  */
  procedure TestChargeGauge(
    GaugeId     in DOC_GAUGE.DOC_GAUGE_ID%type
  , Filter      in varchar2
  , Dateref     in date
  , charge_kind in PTC_CHARGE.C_CHARGE_KIND%type
  , charge_type in PTC_CHARGE.C_CHARGE_TYPE%type
  )
  is
    cursor test(filter number, charge_kind varchar2, charge_type varchar2)
    is
      select PTC_CHARGE_ID
           , C_GAUGERELATION_TYPE
           , CRG_GAUGE_CONDITION
        from PTC_CHARGE
       where (   PTC_FIND_DISCOUNT_CHARGE.PCSINSTR(',' || to_char(PTC_CHARGE_ID) || ',') > 0
              or filter = 0)
         and dateref between nvl(crg_date_from, to_date('01.01.0001', 'DD.MM.YYYY') ) and nvl(crg_date_to, to_date('31.12.2999', 'DD.MM.YYYY') )
         and C_CHARGE_KIND = charge_kind
         and C_CHARGE_TYPE = charge_type;

    charge_id       number(12);
    temp_id         number(12);
    Gauge_condition varchar2(2000);
    rel_type        varchar2(1);
    nb_cond         integer;
  begin
    --Initialisation du résultat
    ResultList   := '';
    -- Assignation de la chaine de caractère pour la fonction PCSInstr
    instrString  := Filter;

    -- Recherche si il y a des taxes d'un autre type que "Tous"
    select count(*)
      into nb_cond
      from PTC_CHARGE
     where (   PTC_FIND_DISCOUNT_CHARGE.PCSINSTR(',' || to_char(PTC_CHARGE_ID) || ',') > 0
            or filter is null)
       and C_CHARGE_KIND = charge_kind
       and C_CHARGE_TYPE = charge_type
       and c_gaugerelation_type <> '3';

    -- Si on des des taxes d'un autre type que "Tous"
    if nb_cond <> 0 then
      -- Assignation de la chaine de caractère pour la fonction PCSInstr
      instrString  := Filter;

      -- Ouverture d'un curseur sur toutes les taxes
      open test(sign(nvl(length(filter), 0) ), charge_kind, charge_type);

      fetch test
       into charge_id
          , rel_type
          , Gauge_condition;

      -- Pour chaque taxe
      while test%found loop
        -- Relation conditionnelle
        if rel_type = '1' then
          if ConditionTest(Gaugeid, Gauge_condition) = 1 then
            ResultList  := ResultList || ',' || to_char(charge_id);
          end if;
        -- Relation directe
        elsif rel_type = '2' then
          select max(ptc_charge_id)
            into temp_id
            from PTC_CHARGE_S_GAUGE
           where PTC_CHARGE_ID = charge_id
             and DOC_GAUGE_ID = Gaugeid;

          if temp_id is not null then
            ResultList  := ResultList || ',' || to_char(charge_id);
          end if;
        -- Sans condition
        elsif rel_type = '3' then
          ResultList  := ResultList || ',' || to_char(charge_id);
        end if;

        -- taxe suivante
        fetch test
         into charge_id
            , rel_type
            , Gauge_condition;
      end loop;

      -- si on a quelque chose dans le résultat, on met une vigule à la fin
      -- sinon on initialise avec ',0,' afin de bien préciser qu'il n'y a rien
      if ResultList is not null then
        ResultList  := ResultList || ',';
      else
        ResultList  := ',0,';
      end if;

      -- fermeture du curseur
      close test;
    else
      ResultList  := Filter;
    end if;
  end TestChargeGauge;

  /**
  * Description
  *   Recherche les taxes applicables à un tiers
  */
  procedure TestChargeThird(
    ThirdId     in PAC_THIRD.PAC_THIRD_ID%type
  , Filter      in varchar2
  , Dateref     in date
  , charge_kind in PTC_CHARGE.C_CHARGE_KIND%type
  , charge_type in PTC_CHARGE.C_CHARGE_TYPE%type
  )
  is
    cursor test(filter number, charge_kind varchar2, charge_type varchar2)
    is
      select PTC_CHARGE_ID
           , C_THIRDRELATION_TYPE
           , CRG_THIRD_CONDITION
        from PTC_CHARGE
       where (   PTC_FIND_DISCOUNT_CHARGE.PCSINSTR(',' || to_char(PTC_CHARGE_ID) || ',') > 0
              or filter = 0)
         and dateref between nvl(crg_date_from, to_date('01.01.0001', 'DD.MM.YYYY') ) and nvl(crg_date_to, to_date('31.12.2999', 'DD.MM.YYYY') )
         and C_CHARGE_KIND = charge_kind
         and C_CHARGE_TYPE = charge_type;

    charge_id       number(12);
    temp_id         number(12);
    third_condition varchar2(2000);
    rel_type        varchar2(1);
  begin
    --Initialisation du résultat
    ResultList   := '';
    -- Ouverture d'un curseur sur toutes les taxes
    -- Assignation de la chaine de caractère pour la fonction PCSInstr
    instrString  := Filter;

    open test(sign(nvl(length(filter), 0) ), charge_kind, charge_type);

    fetch test
     into charge_id
        , rel_type
        , third_condition;

    -- Pour chaque taxe
    while test%found loop
      -- Relation conditionnelle
      if rel_type = '1' then
        if ConditionTest(thirdid, third_condition) = 1 then
          ResultList  := ResultList || ',' || to_char(charge_id);
        end if;
      -- Relation directe
      elsif rel_type = '2' then
        select max(ptc_charge_id)
          into temp_id
          from PTC_CHARGE_S_PARTNERS
         where PTC_CHARGE_ID = charge_id
           and PAC_THIRD_ID = thirdid;

        if temp_id is not null then
          ResultList  := ResultList || ',' || to_char(charge_id);
        end if;
      -- Sans condition
      elsif rel_type = '3' then
        ResultList  := ResultList || ',' || to_char(charge_id);
      -- Groupe de partenaires
      elsif rel_type = '4' then
        if charge_type = '1' then
          select max(ptc_charge_id)
            into temp_id
            from PTC_CHARGE CRG
               , PAC_CUSTOM_PARTNER CUS
           where CRG.PTC_CHARGE_ID = charge_id
             and CUS.PAC_CUSTOM_PARTNER_ID = thirdid
             and CUS.DIC_PTC_THIRD_GROUP_ID = CRG.DIC_PTC_THIRD_GROUP_ID;
        elsif charge_type = '2' then
          select max(ptc_charge_id)
            into temp_id
            from PTC_CHARGE CRG
               , PAC_SUPPLIER_PARTNER SUP
           where CRG.PTC_CHARGE_ID = charge_id
             and SUP.PAC_SUPPLIER_PARTNER_ID = thirdid
             and SUP.DIC_PTC_THIRD_GROUP_ID = CRG.DIC_PTC_THIRD_GROUP_ID;
        end if;

        if temp_id is not null then
          ResultList  := ResultList || ',' || to_char(charge_id);
        end if;
      end if;

      -- taxe suivante
      fetch test
       into charge_id
          , rel_type
          , third_condition;
    end loop;

    -- si on a quelque chose dans le résultat, on met une vigule à la fin
    if ResultList is not null then
      ResultList  := ResultList || ',';
    else
      ResultList  := ',0,';
    end if;

    -- fermeture du curseur
    close test;
  end TestChargeThird;

  /**
  * Description
  *   Recherche les taxes applicables à un dossier
  */
  procedure TestChargeRecord(
    RecordId    in DOC_RECORD.DOC_RECORD_ID%type
  , Filter      in varchar2
  , Dateref     in date
  , charge_kind in PTC_CHARGE.C_CHARGE_KIND%type
  , charge_type in PTC_CHARGE.C_CHARGE_TYPE%type
  )
  is
    cursor test(filter number, charge_kind varchar2, charge_type varchar2)
    is
      select PTC_CHARGE_ID
           , C_RECORDRELATION_TYPE
           , CRG_RECORD_CONDITION
        from PTC_CHARGE
       where (   PTC_FIND_DISCOUNT_CHARGE.PCSINSTR(',' || to_char(PTC_CHARGE_ID) || ',') > 0
              or filter = 0)
         and dateref between nvl(crg_date_from, to_date('01.01.0001', 'DD.MM.YYYY') ) and nvl(crg_date_to, to_date('31.12.2999', 'DD.MM.YYYY') )
         and C_CHARGE_KIND = charge_kind
         and C_CHARGE_TYPE = charge_type;

    charge_id        number(12);
    temp_id          number(12);
    record_condition varchar2(2000);
    rel_type         varchar2(1);
  begin
    --Initialisation du résultat
    ResultList   := '';
    -- Ouverture d'un curseur sur toutes les taxes
    -- Assignation de la chaine de caractère pour la fonction PCSInstr
    instrString  := Filter;

    open test(sign(nvl(length(filter), 0) ), charge_kind, charge_type);

    fetch test
     into charge_id
        , rel_type
        , record_condition;

    -- Pour chaque taxe
    while test%found loop
      -- Relation conditionnelle
      if rel_type = '1' then
        if ConditionTest(recordid, record_condition) = 1 then
          ResultList  := ResultList || ',' || to_char(charge_id);
        end if;
      -- Relation directe
      elsif rel_type = '2' then
        select max(ptc_charge_id)
          into temp_id
          from PTC_CHARGE_S_RECORD
         where PTC_CHARGE_ID = charge_id
           and DOC_RECORD_ID = recordid;

        if temp_id is not null then
          ResultList  := ResultList || ',' || to_char(charge_id);
        end if;
      -- Sans condition
      elsif rel_type = '3' then
        ResultList  := ResultList || ',' || to_char(charge_id);
      end if;

      -- taxe suivante
      fetch test
       into charge_id
          , rel_type
          , record_condition;
    end loop;

    -- si on a quelque chose dans le résultat, on met une vigule à la fin
    if ResultList is not null then
      ResultList  := ResultList || ',';
    else
      ResultList  := ',0,';
    end if;

    -- fermeture du curseur
    close test;
  end TestChargeRecord;

  /**
  * Description
  *    Recherche les taxes applicables à un bien
  */
  procedure TestChargeGood(
    GoodId      in GCO_GOOD.GCO_GOOD_ID%type
  , Filter      in varchar2
  , Dateref     in date
  , charge_kind in PTC_CHARGE.C_CHARGE_KIND%type
  , charge_type in PTC_CHARGE.C_CHARGE_TYPE%type
  )
  is
    cursor test(filter number, charge_kind varchar2, charge_type varchar2)
    is
      select PTC_CHARGE_ID
           , C_GOODRELATION_TYPE
           , CRG_GOOD_CONDITION
        from PTC_CHARGE
       where (   PTC_FIND_DISCOUNT_CHARGE.PCSINSTR(',' || to_char(PTC_CHARGE_ID) || ',') > 0
              or filter = 0)
         and dateref between nvl(crg_date_from, to_date('01.01.0001', 'DD.MM.YYYY') ) and nvl(crg_date_to, to_date('31.12.2999', 'DD.MM.YYYY') )
         and C_CHARGE_KIND = charge_kind
         and C_CHARGE_TYPE = charge_type;

    charge_id      number(12);
    temp_id        number(12);
    Good_condition varchar2(2000);
    rel_type       varchar2(1);
  begin
    --Initialisation du résultat
    ResultList   := '';
    -- Assignation de la chaine de caractère pour la fonction PCSInstr
    instrString  := Filter;

    -- Ouverture d'un curseur sur toutes les taxes
    open test(sign(nvl(length(filter), 0) ), charge_kind, charge_type);

    fetch test
     into charge_id
        , rel_type
        , Good_condition;

    -- Pour chaque taxe
    while test%found loop
      -- Relation conditionnelle
      if rel_type = '1' then
        if ConditionTest(GoodId, Good_condition) = 1 then
          ResultList  := ResultList || ',' || to_char(charge_id);
        end if;
      -- Relation directe
      elsif rel_type = '2' then
        select max(ptc_charge_id)
          into temp_id
          from PTC_CHARGE_S_GOODS
         where PTC_CHARGE_ID = charge_id
           and GCO_GOOD_ID = GoodId;

        if temp_id is not null then
          ResultList  := ResultList || ',' || to_char(charge_id);
        end if;
      -- Sans condition
      elsif rel_type = '3' then
        ResultList  := ResultList || ',' || to_char(charge_id);
      elsif rel_type = '4' then
        select max(ptc_charge_id)
          into temp_id
          from PTC_CHARGE CRG
             , GCO_GOOD GOO
         where CRG.PTC_CHARGE_ID = charge_id
           and GOO.GCO_GOOD_ID = GoodId
           and GOO.DIC_PTC_GOOD_GROUP_ID = CRG.DIC_PTC_GOOD_GROUP_ID;

        if temp_id is not null then
          ResultList  := ResultList || ',' || to_char(charge_id);
        end if;
      end if;

      -- taxe suivante
      fetch test
       into charge_id
          , rel_type
          , Good_condition;
    end loop;

    -- si on a quelque chose dans le résultat, on met une vigule à la fin
    if ResultList is not null then
      ResultList  := ResultList || ',';
    else
      ResultList  := ',0,';
    end if;

    -- fermeture du curseur
    close test;
  end TestChargeGood;

  /**
  * Description
  *    Recherche les taxes applicables à un groupe de bien
  */
  procedure TestChargeGoodGroup(
    aGoodGroupId in GCO_GOOD.DIC_PTC_GOOD_GROUP_ID%type
  , Filter       in varchar2
  , Dateref      in date
  , charge_type  in PTC_CHARGE.C_CHARGE_TYPE%type
  )
  is
    cursor test(filter number, charge_type PTC_CHARGE.C_CHARGE_TYPE%type, cGoodGroupId GCO_GOOD.DIC_PTC_GOOD_GROUP_ID%type)
    is
      select PTC_CHARGE_ID
        from PTC_CHARGE
       where (   PTC_FIND_DISCOUNT_CHARGE.PCSINSTR(',' || to_char(PTC_CHARGE_ID) || ',') > 0
              or filter = 0)
         and dateref between nvl(crg_date_from, to_date('01.01.0001', 'DD.MM.YYYY') ) and nvl(crg_date_to, to_date('31.12.2999', 'DD.MM.YYYY') )
         and C_CHARGE_TYPE = charge_type
         and C_CHARGE_KIND = 'GRP'
         and C_GOODRELATION_TYPE = '4'
         and DIC_PTC_GOOD_GROUP_ID = cGoodGroupId;

    charge_id number(12);
    temp_id   number(12);
  begin
    --Initialisation du résultat
    ResultList   := '';
    -- Assignation de la chaine de caractère pour la fonction PCSInstr
    instrString  := Filter;

    -- Ouverture d'un curseur sur toutes les taxes
    open test(sign(nvl(length(filter), 0) ), charge_type, aGoodGroupId);

    fetch test
     into charge_id;

    -- Pour chaque taxe
    while test%found loop
      ResultList  := ResultList || ',' || to_char(charge_id);

      -- taxe suivante
      fetch test
       into charge_id;
    end loop;

    -- si on a quelque chose dans le résultat, on met une vigule à la fin
    if ResultList is not null then
      ResultList  := ResultList || ',';
    else
      ResultList  := ',0,';
    end if;

    -- fermeture du curseur
    close test;
  end TestChargeGoodGroup;

  /**
  * Description
  *    Recherche les remises applicables à un gabarit
  */
  procedure TestDiscountGauge(
    GaugeId     in DOC_GAUGE.DOC_GAUGE_ID%type
  , Filter      in varchar2
  , Dateref     in date
  , charge_kind in PTC_CHARGE.C_CHARGE_KIND%type
  , charge_type in PTC_CHARGE.C_CHARGE_TYPE%type
  )
  is
    cursor test(filter number, charge_kind varchar2, charge_type varchar2)
    is
      select PTC_DISCOUNT_ID
           , C_GAUGERELATION_TYPE
           , DNT_GAUGE_CONDITION
        from PTC_DISCOUNT
       where (   PTC_FIND_DISCOUNT_CHARGE.PCSINSTR(',' || to_char(PTC_DISCOUNT_ID) || ',') > 0
              or filter = 0)
         and dateref between nvl(dnt_date_from, to_date('01.01.0001', 'DD.MM.YYYY') ) and nvl(dnt_date_to, to_date('31.12.2999', 'DD.MM.YYYY') )
         and C_DISCOUNT_KIND = charge_kind
         and C_DISCOUNT_TYPE = charge_type;

    discount_id     number(12);
    temp_id         number(12);
    Gauge_condition varchar2(2000);
    rel_type        varchar2(1);
    nb_cond         integer;
  begin
    --Initialisation du résultat
    ResultList   := '';
    -- Assignation de la chaine de caractère pour la fonction PCSInstr
    instrString  := Filter;

    select count(*)
      into nb_cond
      from PTC_DISCOUNT
     where (   PTC_FIND_DISCOUNT_CHARGE.PCSINSTR(',' || to_char(PTC_DISCOUNT_ID) || ',') > 0
            or filter is null)
       and C_DISCOUNT_KIND = charge_kind
       and C_DISCOUNT_TYPE = charge_type
       and C_GAUGERELATION_TYPE <> '3';

    if nb_cond > 0 then
      -- Ouverture d'un curseur sur toutes les remises
      open test(sign(nvl(length(filter), 0) ), charge_kind, charge_type);

      fetch test
       into discount_id
          , rel_type
          , Gauge_condition;

      -- Pour chaque remise
      while test%found loop
        -- Relation conditionnelle
        if rel_type = '1' then
          if ConditionTest(Gaugeid, Gauge_condition) = 1 then
            ResultList  := ResultList || ',' || to_char(discount_id);
          end if;
        -- Relation directe
        elsif rel_type = '2' then
          select max(ptc_discount_id)
            into temp_id
            from PTC_DISCOUNT_S_GAUGE
           where PTC_DISCOUNT_ID = discount_id
             and DOC_GAUGE_ID = Gaugeid;

          if temp_id is not null then
            ResultList  := ResultList || ',' || to_char(discount_id);
          end if;
        -- Sans condition
        elsif rel_type = '3' then
          ResultList  := ResultList || ',' || to_char(discount_id);
        end if;

        -- remise suivante
        fetch test
         into discount_id
            , rel_type
            , Gauge_condition;
      end loop;

      -- si on a quelque chose dans le résultat, on met une vigule à la fin
      -- sinon on initialise avec ',0,' afin de bien préciser qu'il n'y a rien
      if ResultList is not null then
        ResultList  := ResultList || ',';
      else
        ResultList  := ResultList || ',0,';
      end if;

      -- fermeture du curseur
      close test;
    else
      ResultList  := Filter;
    end if;
  end TestDiscountGauge;

  /**
  * Description
  *   Recherche les remises applicables à un tiers
  */
  procedure TestDiscountThird(
    ThirdId     in PAC_THIRD.PAC_THIRD_ID%type
  , Filter      in varchar2
  , Dateref     in date
  , charge_kind in PTC_CHARGE.C_CHARGE_KIND%type
  , charge_type in PTC_CHARGE.C_CHARGE_TYPE%type
  )
  is
    cursor test(filter number, charge_kind varchar2, charge_type varchar2)
    is
      select PTC_DISCOUNT_ID
           , C_THIRDRELATION_TYPE
           , DNT_THIRD_CONDITION
        from PTC_DISCOUNT
       where (   PTC_FIND_DISCOUNT_CHARGE.PCSINSTR(',' || to_char(PTC_DISCOUNT_ID) || ',') > 0
              or filter = 0)
         and dateref between nvl(dnt_date_from, to_date('01.01.0001', 'DD.MM.YYYY') ) and nvl(dnt_date_to, to_date('31.12.2999', 'DD.MM.YYYY') )
         and C_DISCOUNT_KIND = charge_kind
         and C_DISCOUNT_TYPE = charge_type;

    discount_id     number(12);
    temp_id         number(12);
    third_condition varchar2(2000);
    rel_type        varchar2(1);
  begin
    --Initialisation du résultat
    ResultList   := '';
    -- Assignation de la chaine de caractère pour la fonction PCSInstr
    instrString  := Filter;

    -- Ouverture d'un curseur sur toutes les remises
    open test(sign(nvl(length(filter), 0) ), charge_kind, charge_type);

    fetch test
     into discount_id
        , rel_type
        , third_condition;

    -- Pour chaque remise
    while test%found loop
      -- Relation conditionnelle
      if rel_type = '1' then
        if ConditionTest(thirdid, third_condition) = 1 then
          ResultList  := ResultList || ',' || to_char(discount_id);
        end if;
      -- Relation directe
      elsif rel_type = '2' then
        select max(ptc_discount_id)
          into temp_id
          from PTC_DISCOUNT_S_THIRD
         where PTC_DISCOUNT_ID = discount_id
           and PAC_THIRD_ID = thirdid;

        if temp_id is not null then
          ResultList  := ResultList || ',' || to_char(discount_id);
        end if;
      -- Sans condition
      elsif rel_type = '3' then
        ResultList  := ResultList || ',' || to_char(discount_id);
      -- Groupe de partenaires
      elsif rel_type = '4' then
        if charge_type = '1' then
          select max(ptc_discount_id)
            into temp_id
            from PTC_DISCOUNT DNT
               , PAC_CUSTOM_PARTNER CUS
           where DNT.PTC_DISCOUNT_ID = discount_id
             and CUS.PAC_CUSTOM_PARTNER_ID = thirdid
             and CUS.DIC_PTC_THIRD_GROUP_ID = DNT.DIC_PTC_THIRD_GROUP_ID;
        elsif charge_type = '2' then
          select max(ptc_discount_id)
            into temp_id
            from PTC_DISCOUNT DNT
               , PAC_SUPPLIER_PARTNER SUP
           where DNT.PTC_DISCOUNT_ID = discount_id
             and SUP.PAC_SUPPLIER_PARTNER_ID = thirdid
             and SUP.DIC_PTC_THIRD_GROUP_ID = DNT.DIC_PTC_THIRD_GROUP_ID;
        end if;

        if temp_id is not null then
          ResultList  := ResultList || ',' || to_char(discount_id);
        end if;
      end if;

      -- remise suivante
      fetch test
       into discount_id
          , rel_type
          , third_condition;
    end loop;

    -- si on a quelque chose dans le résultat, on met une vigule à la fin
    if ResultList is not null then
      ResultList  := ResultList || ',';
    else
      ResultList  := ',0,';
    end if;

    -- fermeture du curseur
    close test;
  end TestDiscountThird;

  /**
  * Description
  *    Recherche les remises applicables à un dossier
  */
  procedure TestDiscountRecord(
    RecordId    in DOC_RECORD.DOC_RECORD_ID%type
  , Filter      in varchar2
  , Dateref     in date
  , charge_kind in PTC_CHARGE.C_CHARGE_KIND%type
  , charge_type in PTC_CHARGE.C_CHARGE_TYPE%type
  )
  is
    cursor test(filter number, charge_kind varchar2, charge_type varchar2)
    is
      select PTC_DISCOUNT_ID
           , C_RECORDRELATION_TYPE
           , DNT_RECORD_CONDITION
        from PTC_DISCOUNT
       where (   PTC_FIND_DISCOUNT_CHARGE.PCSINSTR(',' || to_char(PTC_DISCOUNT_ID) || ',') > 0
              or filter = 0)
         and dateref between nvl(dnt_date_from, to_date('01.01.0001', 'DD.MM.YYYY') ) and nvl(dnt_date_to, to_date('31.12.2999', 'DD.MM.YYYY') )
         and C_DISCOUNT_KIND = charge_kind
         and C_DISCOUNT_TYPE = charge_type;

    discount_id      number(12);
    temp_id          number(12);
    record_condition varchar2(2000);
    rel_type         varchar2(1);
  begin
    --Initialisation du résultat
    ResultList   := '';
    -- Assignation de la chaine de caractère pour la fonction PCSInstr
    instrString  := Filter;

    -- Ouverture d'un curseur sur toutes les remises
    open test(sign(nvl(length(filter), 0) ), charge_kind, charge_type);

    fetch test
     into discount_id
        , rel_type
        , record_condition;

    -- Pour chaque remise
    while test%found loop
      -- Relation conditionnelle
      if rel_type = '1' then
        if ConditionTest(recordid, record_condition) = 1 then
          ResultList  := ResultList || ',' || to_char(discount_id);
        end if;
      -- Relation directe
      elsif rel_type = '2' then
        select max(ptc_discount_id)
          into temp_id
          from PTC_DISCOUNT_S_RECORD
         where PTC_DISCOUNT_ID = discount_id
           and DOC_RECORD_ID = recordid;

        if temp_id is not null then
          ResultList  := ResultList || ',' || to_char(discount_id);
        end if;
      -- Sans condition
      elsif rel_type = '3' then
        ResultList  := ResultList || ',' || to_char(discount_id);
      end if;

      -- remise suivante
      fetch test
       into discount_id
          , rel_type
          , record_condition;
    end loop;

    -- si on a quelque chose dans le résultat, on met une vigule à la fin
    if ResultList is not null then
      ResultList  := ResultList || ',';
    else
      ResultList  := ',0,';
    end if;

    -- fermeture du curseur
    close test;
  end TestDiscountRecord;

  /**
  * Description
  *    Recherche les remises applicables à un bien
  */
  procedure TestDiscountGood(
    GoodId      in GCO_GOOD.GCO_GOOD_ID%type
  , Filter      in varchar2
  , Dateref     in date
  , charge_kind in PTC_CHARGE.C_CHARGE_KIND%type
  , charge_type in PTC_CHARGE.C_CHARGE_TYPE%type
  )
  is
    cursor test(filter number, charge_kind varchar2, charge_type varchar2)
    is
      select PTC_DISCOUNT_ID
           , C_GOODRELATION_TYPE
           , DNT_GOOD_CONDITION
        from PTC_DISCOUNT
       where (   PTC_FIND_DISCOUNT_CHARGE.PCSINSTR(',' || to_char(PTC_DISCOUNT_ID) || ',') > 0
              or filter = 0)
         and dateref between nvl(dnt_date_from, to_date('01.01.0001', 'DD.MM.YYYY') ) and nvl(dnt_date_to, to_date('31.12.2999', 'DD.MM.YYYY') )
         and C_DISCOUNT_KIND = charge_kind
         and C_DISCOUNT_TYPE = charge_type;

    discount_id    number(12);
    temp_id        number(12);
    Good_condition varchar2(2000);
    rel_type       varchar2(1);
  begin
    --Initialisation du résultat
    ResultList   := '';
    -- Assignation de la chaine de caractère pour la fonction PCSInstr
    instrString  := Filter;

    -- Ouverture d'un curseur sur toutes les remises
    open test(sign(nvl(length(filter), 0) ), charge_kind, charge_type);

    fetch test
     into discount_id
        , rel_type
        , Good_condition;

    -- Pour chaque remise
    while test%found loop
      -- Relation conditionnelle
      if rel_type = '1' then
        if ConditionTest(GoodId, Good_condition) = 1 then
          ResultList  := ResultList || ',' || to_char(discount_id);
        end if;
      -- Relation directe
      elsif rel_type = '2' then
        select max(ptc_discount_id)
          into temp_id
          from PTC_DISCOUNT_S_GOOD
         where PTC_DISCOUNT_ID = discount_id
           and GCO_GOOD_ID = GoodId;

        if temp_id is not null then
          ResultList  := ResultList || ',' || to_char(discount_id);
        end if;
      -- Sans condition
      elsif rel_type = '3' then
        ResultList  := ResultList || ',' || to_char(discount_id);
      -- Groupe de biens
      elsif rel_type = '4' then
        select max(ptc_discount_id)
          into temp_id
          from PTC_DISCOUNT DNT
             , GCO_GOOD GOO
         where DNT.PTC_DISCOUNT_ID = discount_id
           and GOO.GCO_GOOD_ID = GoodId
           and GOO.DIC_PTC_GOOD_GROUP_ID = DNT.DIC_PTC_GOOD_GROUP_ID;

        if temp_id is not null then
          ResultList  := ResultList || ',' || to_char(discount_id);
        end if;
      end if;

      -- remise suivante
      fetch test
       into discount_id
          , rel_type
          , Good_condition;
    end loop;

    -- si on a quelque chose dans le résultat, on met une vigule à la fin
    if ResultList is not null then
      ResultList  := ResultList || ',';
    else
      ResultList  := ',0,';
    end if;

    -- fermeture du curseur
    close test;
  end TestDiscountGood;

  /**
  * Description
  *    Recherche les remises applicables à un groupe de bien
  */
  procedure TestDiscountGoodGroup(
    aGoodGroupId in GCO_GOOD.DIC_PTC_GOOD_GROUP_ID%type
  , Filter       in varchar2
  , Dateref      in date
  , charge_type  in PTC_CHARGE.C_CHARGE_TYPE%type
  )
  is
    cursor test(filter number, charge_type PTC_CHARGE.C_CHARGE_TYPE%type, cGoodGroupId GCO_GOOD.DIC_PTC_GOOD_GROUP_ID%type)
    is
      select PTC_DISCOUNT_ID
        from PTC_DISCOUNT
       where (   PTC_FIND_DISCOUNT_CHARGE.PCSINSTR(',' || to_char(PTC_DISCOUNT_ID) || ',') > 0
              or filter = 0)
         and dateref between nvl(dnt_date_from, to_date('01.01.0001', 'DD.MM.YYYY') ) and nvl(dnt_date_to, to_date('31.12.2999', 'DD.MM.YYYY') )
         and C_DISCOUNT_TYPE = charge_type
         and C_DISCOUNT_KIND = 'GRP'
         and C_GOODRELATION_TYPE = '4'
         and DIC_PTC_GOOD_GROUP_ID = cGoodGroupId;

    discount_id number(12);
    temp_id     number(12);
  begin
    --Initialisation du résultat
    ResultList   := '';
    -- Assignation de la chaine de caractère pour la fonction PCSInstr
    instrString  := Filter;

    -- Ouverture d'un curseur sur toutes les remises
    open test(sign(nvl(length(filter), 0) ), charge_type, aGoodGroupId);

    fetch test
     into discount_id;

    -- Pour chaque remise
    while test%found loop
      ResultList  := ResultList || ',' || to_char(discount_id);

      -- remise suivante
      fetch test
       into discount_id;
    end loop;

    -- si on a quelque chose dans le résultat, on met une vigule à la fin
    if ResultList is not null then
      ResultList  := ResultList || ',';
    else
      ResultList  := ',0,';
    end if;

    -- fermeture du curseur
    close test;
  end TestDiscountGoodGroup;

  /**
  * Description
  *    Teste une condition SQL et renvoie 1 si la commande sql renvoie des records
  */
  function ConditionTest(aId GCO_GOOD.GCO_GOOD_ID%type, aDEF_CONDITION PTC_CHARGE.CRG_THIRD_CONDITION%type)
    return number
  is
    SqlCommand    ACS_DEFAULT_ACCOUNT.DEF_CONDITION%type;
    ReturnValue   number(1)                                default 0;
    DynamicCursor integer;
    ErrorCursor   integer;

    -- Remplace les paramètres dans une requête SQl
    function ReplaceParam(aSqlCommand varchar2, aId number)
      return varchar2
    is
      ParamPos     number(4);
      ParamLength1 number(4);
      ParamLength2 number(4);
      ParamLength  number(4);
      Parameter    varchar2(30);
      SqlCommand   ACS_DEFAULT_ACCOUNT.DEF_CONDITION%type;
    begin
      SqlCommand  := aSqlCommand;
      ParamPos    := instr(aSqlCommand, ':');

      if ParamPos > 0 then
        ParamLength1  := instr(substr(aSqlCommand, ParamPos), ' ');

        if instr(substr(aSqlCommand, ParamPos), chr(13) || chr(10) ) > 0 then
          ParamLength2  := instr(substr(aSqlCommand, ParamPos), chr(13) || chr(10) );
        else
          ParamLength2  := length(aSqlCommand) - ParamPos + 2;
        end if;

        if     (ParamLength1 > ParamLength2)
           and (ParamLength2 > 0) then
          ParamLength  := ParamLength2;
        elsif     (ParamLength1 > ParamLength2)
              and (ParamLength2 = 0) then
          ParamLength  := ParamLength1;
        elsif     (ParamLength1 < ParamLength2)
              and (ParamLength1 > 0) then
          ParamLength  := ParamLength1;
        elsif     (ParamLength1 < ParamLength2)
              and (ParamLength1 = 0) then
          ParamLength  := ParamLength2;
        else
          ParamLength  := 0;
        end if;

        if ParamLength > 0 then
          Parameter  := substr(aSqlCommand, ParamPos, ParamLength - 1);
        else
          Parameter  := substr(aSqlCommand, ParamPos);
        end if;

        SqlCommand    := replace(aSqlCommand, Parameter, to_char(aId) );
      end if;

      return SqlCommand;
    end ReplaceParam;
  begin
    begin
      SqlCommand     := ReplaceParam(aDEF_CONDITION, aId);
      --raise_application_error(-20000, SqlCommand);

      -- Attribution d'un Handle de curseur
      DynamicCursor  := DBMS_SQL.open_cursor;
      -- Vérification de la syntaxe de la commande SQL
      DBMS_SQL.Parse(DynamicCursor, SqlCommand, DBMS_SQL.V7);
      -- Exécution de la commande SQL
      ErrorCursor    := DBMS_SQL.execute(DynamicCursor);

      -- Obtenir le tuple suivant
      if DBMS_SQL.fetch_rows(DynamicCursor) > 0 then
        ReturnValue  := 1;
      end if;

      -- Ferme le curseur
      DBMS_SQL.close_cursor(DynamicCursor);
    exception
      when others then
        if DBMS_SQL.is_open(DynamicCursor) then
          DBMS_SQL.close_cursor(DynamicCursor);
          raise_application_error(-20000, 'Mauvaise commande : ' || aDef_Condition);
        end if;
    end;

    return ReturnValue;
  end ConditionTest;

  /**
  * Description
  *   Idem fonction INSTR mais pour un string > 2000. Si trouvé renvoie 1 sinon 0.
  *   mettre à jour la valeur instrString avant d'appeler la fonction
  */
  function PcsInstr(aSubString in varchar2)
    return number
  is
    tmpString varchar2(32000);
    tmpList   varchar2(2000);
    result    number(1);
    i         number(10);
  begin
    result     := 0;
    tmpString  := instrString;

    while tmpString is not null
     and result = 0 loop
      -- teste si la valeur à renvoyer est plus grande que 2000 caractères
      if length(tmpString) > 1000 then
        i          := 1000;

        -- recherche de la position de la dernière virgule avant le 2000ème caractère
        while substr(tmpString, i, 1) <> ',' loop
          i  := i - 1;
        end loop;

        -- Assignation de la chaine de résultat au paramètre de retour de valeur
        tmpList    := substr(tmpString, 1, i + 1);
        -- Mise à jour de la variable globale de résultat en enlevant les valeurs
        -- que la fonction va retourner
        tmpString  := substr(tmpString, i);
      else
        -- Si le résultat est plus petit que 2000 caratères, on renvoie le résultat
        -- sans aucun traitement
        tmpList    := tmpString;
        -- Mise à zéro de la variable globale
        tmpString  := '';
      end if;

      result  := sign(instr(tmpList, aSubstring) );
    end loop;

    return result;
  end PcsInstr;
end PTC_FIND_DISCOUNT_CHARGE;
