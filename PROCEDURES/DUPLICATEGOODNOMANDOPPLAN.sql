--------------------------------------------------------
--  DDL for Procedure DUPLICATEGOODNOMANDOPPLAN
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "DUPLICATEGOODNOMANDOPPLAN" (lMainPart in varchar2, lNewMainPart in varchar2)
/**
* Description
*    Méthode interne non publiée chez nos clients
*    Duplique un bien, sa nom de prod par défaut avec duplication des composants et également duplication de la gamme
*    dans le but de faire des tests
*    Principe Bien racine    XXXXXXXXX composants XXXXXXXXX1, XXXXXXXXX2... XXXXXXXXXn  Gamme XXXXXXXXX
*             nouvelle racine  YYYYYYY composants YYYYYYY1, YYYYYYY2... YYYYYYYn  Gamme YYYYYYY
*    Il est impératif d'avoir un bien racin organisé comme expliqué ci-dessus
*    Dans DEVELOP, il y a l'article 1000.05.STO qui est fait selon cette règle
* @created fp 20.06.2012
* @lastUpdate
* @public
* @param iMainPart : partie racine du bien à copier
* @param iNewMainPart : partie rtacine des nouveau biens créés
*/
is
  lMainGoodId    number;
  lNewMainGoodId number;
  lNewNomId      number                     := GetNewId;
  lNewPlanId     number(12)                 := GetNewId;
  lOldPlanId     number(12);
  ltplNom        PPS_NOMENCLATURE%rowtype;
begin
  -- Copie de la gamme opératoire
  declare
    ltplPlan fal_schedule_plan%rowtype;
  begin
    select *
      into ltplPlan
      from fal_schedule_plan
     where SCH_REF = lMainPart;

    lOldPlanId                     := ltplPlan.FAL_SCHEDULE_PLAN_ID;
    ltplPlan.FAL_SCHEDULE_PLAN_ID  := lNewPlanId;
    ltplPlan.SCH_REF               := lNewMainPart;
    ltplPlan.A_DATECRE             := sysdate;
    ltplPlan.A_DATEMOD             := null;
    ltplPlan.A_IDCRE               := PCS.PC_INIT_SESSION.GetUserIni;
    ltplPlan.A_IDMOD               := null;

    insert into fal_schedule_plan
         values ltplPlan;

    for ltplOperation in (select LSL.*
                            from fal_list_step_link LSL
                           where FAL_SCHEDULE_PLAN_ID = lOldPlanId) loop
      ltplOperation.FAL_SCHEDULE_STEP_ID  := GetNewId;
      ltplOperation.FAL_SCHEDULE_PLAN_ID  := lNewPlanId;
      ltplOperation.A_DATECRE             := sysdate;
      ltplOperation.A_DATEMOD             := null;
      ltplOperation.A_IDCRE               := PCS.PC_INIT_SESSION.GetUserIni;
      ltplOperation.A_IDMOD               := null;

      insert into fal_list_step_link
           values ltplOperation;
    end loop;
  exception
    when no_data_found then
      null;
  end;

  -- Copie du produit principal
  select GCO_GOOD_ID
    into lMainGoodId
    from GCO_GOOD
   where GOO_MAJOR_REFERENCE = lMainPart;

  GCO_PRC_GOOD.DuplicateProduct(iSourceGoodID      => lMainGoodId
                              , iNewGoodID         => lNewMainGoodId
                              , iNewMajorRef       => lNewMainPart
                              , iNewSecRef         => lNewMainPart
                              , iDuplStock         => 1
                              , iDuplPurchase      => 1
                              , iDuplManufacture   => 1
                              , iDuplSubcontract   => 1
                              , iDuplTariff        => 1
                               );

  -- Mise à jour de la gamme dans les données compl de fabrication
  update GCO_COMPL_DATA_MANUFACTURE
     set FAL_SCHEDULE_PLAN_ID = lNewPlanId
   where GCO_GOOD_ID = lNewMainGoodId;

  --Copie de la nomenclature
  select *
    into ltplNom
    from PPS_NOMENCLATURE
   where PPS_NOMENCLATURE_ID = PPS_I_LIB_FUNCTIONS.GetDefaultNomenclature(lMainGoodId, '2');

  ltplNom.PPS_NOMENCLATURE_ID  := lNewNomId;
  ltplNom.GCO_GOOD_ID          := lNewMainGoodId;
  ltplNom.A_DATECRE            := sysdate;
  ltplNom.A_DATEMOD            := null;
  ltplNom.A_IDCRE              := PCS.PC_INIT_SESSION.GetUserIni;
  ltplNom.A_IDMOD              := null;

  insert into PPS_NOMENCLATURE
       values ltplNom;

  -- Copie et duplication des composants de nomenclature
  for ltplComp in (select NOM.*
                     from PPS_NOM_BOND NOM
                    where PPS_NOMENCLATURE_ID = PPS_I_LIB_FUNCTIONS.GetDefaultNomenclature(lMainGoodId, '2') ) loop
    declare
      lNewCptId number;
      lCptRef   varchar2(30) := FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', ltplComp.GCO_GOOD_ID);
    begin
      GCO_PRC_GOOD.DuplicateProduct(iSourceGoodID       => ltplComp.GCO_GOOD_ID
                                  , iNewGoodID          => lNewCptId
                                  , iNewMajorRef        => lNewMainPart || substr(lCptRef, -1, 1)
                                  , iNewSecRef          => lNewMainPart || substr(lCptRef, -1, 1)
                                  , iDuplStock          => 1
                                  , iDuplPurchase       => 1
                                  , iDuplManufacture    => 1
                                  , iDuplSubcontract    => 1
                                  , iDuplTariff         => 1
                                  , iDuplNomenclature   => 1
                                   );
      ltplComp.PPS_NOM_BOND_ID      := GetNewId;
      ltplComp.PPS_NOMENCLATURE_ID  := lNewNomId;
      ltplComp.GCO_GOOD_ID          := lNewCptId;
      ltplComp.A_DATECRE            := sysdate;
      ltplComp.A_DATEMOD            := null;
      ltplComp.A_IDCRE              := PCS.PC_INIT_SESSION.GetUserIni;
      ltplComp.A_IDMOD              := null;

      insert into PPS_NOM_BOND
           values ltplComp;
    end;
  end loop;
end DuplicateGoodNomAndOpPlan;
