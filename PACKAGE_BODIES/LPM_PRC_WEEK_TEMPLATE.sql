--------------------------------------------------------
--  DDL for Package Body LPM_PRC_WEEK_TEMPLATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LPM_PRC_WEEK_TEMPLATE" 
as
  /**
  * procedure InitReferentsWeekTemplate
  * description :
  *    Initialise pour une appartenance tous les records dans la planification
  *    des prestations en cascade.
  */
  procedure InitReferentsWeekTemplate(iReferentsID in LPM_REFERENTS.LPM_REFERENTS_ID%type)
  is
    weekTemplateID LPM_WEEK_TEMPLATE.LPM_WEEK_TEMPLATE_ID%type;
    beneficiaryID  SCH_STUDENT.SCH_STUDENT_ID%type;
    divisionID     HRM_DIVISION.HRM_DIVISION_ID%type;
  begin
    select SCH_STUDENT_ID
         , HRM_DIVISION_ID
      into beneficiaryID
         , divisionID
      from LPM_REFERENTS
     where LPM_REFERENTS_ID = iReferentsID;

    -- Il se peut que la division ait changé, on vérifie et supprime le cas échéant
    -- les templates liés à l'ancienne division.
    CleanReferentsWeekTemplate(iReferentsID);

    -- liste toutes les possibilités manquantes pour une appartenance pour chaque
    -- prestations et chaque jours
    for ltplMissingWeekTmpl in
      (select DEF.LPM_DIVISION_OUTLAY_ID
            , DEF.day
            , LWT.LWT_LDO_VALUE
            , DEF.LDO_DEFAULT_VALUE
         -- produit cartésien entre les jours (1-7) et la valeur par défaut de la catégorie
       from   (select *
                 from (select     level day
                             from dual
                       connect by level <= 7)
                    , (select LDO.LPM_DIVISION_OUTLAY_ID
                            , LDO.LDO_DEFAULT_VALUE
                         from LPM_OUTLAY_CATEGORY COU
                            , LPM_DIVISION_OUTLAY LDO
                        where COU.SCH_OUTLAY_CATEGORY_ID = LDO.SCH_OUTLAY_CATEGORY_ID(+)
                          and LDO.HRM_DIVISION_ID = DivisionID
                          and COU.OUT_ACTIVE = 1) ) DEF
            -- Liste des valeurs existante dans LPM_WEEK_TEMPLATE
       ,      (select *
                 from (select *
                         from LPM_WEEK_TEMPLATE
                        where LPM_WEEK_TEMPLATE_ID in(
                                select distinct first_value(LPM_WEEK_TEMPLATE_ID) over(partition by LPM_DIVISION_OUTLAY_ID, LWT_DAY order by LPM_REFERENTS_ID
                                               , SCH_STUDENT_ID)
                                           from LPM_WEEK_TEMPLATE
                                          where (   SCH_STUDENT_ID = BeneficiaryID
                                                 or SCH_STUDENT_ID is null)
                                            and (   LPM_REFERENTS_ID = iReferentsID
                                                 or LPM_REFERENTS_ID is null) ) ) ) LWT
        where DEF.day = LWT.LWT_DAY(+)
          and DEF.LPM_DIVISION_OUTLAY_ID = LWT.LPM_DIVISION_OUTLAY_ID(+)
          and LWT.LPM_REFERENTS_ID is null) loop
      -- Pour la valeur, on se base soit sur la valeur d'un template existant, soit sur la valeur par défaut
      InsertReferentsWeekTemplate(ltplMissingWeekTmpl.LPM_DIVISION_OUTLAY_ID
                                , BeneficiaryID
                                , DivisionID
                                , iReferentsID
                                , ltplMissingWeekTmpl.day
                                , nvl(ltplMissingWeekTmpl.LWT_LDO_VALUE, ltplMissingWeekTmpl.LDO_DEFAULT_VALUE)
                                , weekTemplateID
                                 );
    end loop;
  end InitReferentsWeekTemplate;

/**
  * procedure InsertReferentsWeekTemplate
  * description :
  *    Ajout d'une ligne de configuration par défaut pour une appartenance. On
  *    appelle en cascade la création pour le bénéficiaire si inexistant
  */
  procedure InsertReferentsWeekTemplate(
    iDivisionOutlayID in     LPM_DIVISION_OUTLAY.LPM_DIVISION_OUTLAY_ID%type
  , iBeneficiaryID    in     SCH_STUDENT.SCH_STUDENT_ID%type
  , iDivisionID       in     HRM_DIVISION.HRM_DIVISION_ID%type
  , iReferentsID      in     LPM_REFERENTS.LPM_REFERENTS_ID%type
  , iDayNum           in     LPM_WEEK_TEMPLATE.LWT_DAY%type
  , iValue            in     LPM_WEEK_TEMPLATE.LWT_LDO_VALUE%type
  , oWeekTemplateID   out    LPM_WEEK_TEMPLATE.LPM_WEEK_TEMPLATE_ID%type
  )
  is
  begin
    -- On créé le template de la division si inexistant
    if LPM_LIB_WEEK_TEMPLATE.IsWeekTemplateDefined(iDivisionOutlayID, iBeneficiaryID, iDivisionID, iDayNum) = 0 then
      InsertBeneficiaryWeekTemplate(iDivisionOutlayID, iBeneficiaryID, iDivisionID, iDayNum, iValue, oWeekTemplateID);
    end if;

    -- Puis on crée le template du bénéficiaire
    InsertWeekTemplate(iDivisionOutlayID, iBeneficiaryID, iDivisionID, iReferentsID, iDayNum, iValue, oWeekTemplateID);
  end InsertReferentsWeekTemplate;

   /**
  * procedure InsertBeneficiaryWeekTemplate
  * description :
  *    Ajout d'une ligne de configuration par défaut pour un bénéficiaire. Si
  *    la configuration de la division n'existe pas, on créé celle-ci avec
  *    la même valeur que pour le bénéficiaire.
  */
  procedure InsertBeneficiaryWeekTemplate(
    iDivisionOutlayID in     LPM_DIVISION_OUTLAY.LPM_DIVISION_OUTLAY_ID%type
  , iBeneficiaryID    in     SCH_STUDENT.SCH_STUDENT_ID%type
  , iDivisionID       in     HRM_DIVISION.HRM_DIVISION_ID%type
  , iDayNum           in     LPM_WEEK_TEMPLATE.LWT_DAY%type
  , iValue            in     LPM_WEEK_TEMPLATE.LWT_LDO_VALUE%type
  , oWeekTemplateID   out    LPM_WEEK_TEMPLATE.LPM_WEEK_TEMPLATE_ID%type
  )
  is
  begin
    -- On créé le template de la division si inexistant
    if LPM_LIB_WEEK_TEMPLATE.IsWeekTemplateDefined(iDivisionOutlayID, null, iDivisionID, iDayNum) = 0 then
      InsertWeekTemplate(iDivisionOutlayID, null, iDivisionID, null, iDayNum, iValue, oWeekTemplateID);
    end if;

    -- Puis on crée le template du bénéficiaire
    InsertWeekTemplate(iDivisionOutlayID, iBeneficiaryID, iDivisionID, null, iDayNum, iValue, oWeekTemplateID);
  end InsertBeneficiaryWeekTemplate;

  /**
  * procedure InsertWeekTemplate
  * description :
  *    Ajout d'une ligne de configuration par défaut.
  */
  procedure InsertWeekTemplate(
    iDivisionOutlayID in     LPM_DIVISION_OUTLAY.LPM_DIVISION_OUTLAY_ID%type
  , iBeneficiaryID    in     SCH_STUDENT.SCH_STUDENT_ID%type
  , iDivisionID       in     HRM_DIVISION.HRM_DIVISION_ID%type
  , iReferentsID      in     LPM_REFERENTS.LPM_REFERENTS_ID%type
  , iDayNum           in     LPM_WEEK_TEMPLATE.LWT_DAY%type
  , iValue            in     LPM_WEEK_TEMPLATE.LWT_LDO_VALUE%type
  , oWeekTemplateID   out    LPM_WEEK_TEMPLATE.LPM_WEEK_TEMPLATE_ID%type
  )
  is
    ltWeekTemplate FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Init des données du tuple LPM_WEEK_TEMPLATE
    FWK_I_MGT_ENTITY.new(FWK_TYP_LPM_ENTITY.gcLpmWeekTemplate, ltWeekTemplate, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltWeekTemplate, 'LPM_DIVISION_OUTLAY_ID', iDivisionOutlayID);

    if iBeneficiaryID = null then
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltWeekTemplate, 'SCH_STUDENT_ID');
    else
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltWeekTemplate, 'SCH_STUDENT_ID', iBeneficiaryID);
    end if;

    if iReferentsID = null then
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltWeekTemplate, 'LPM_REFERENTS_ID');
    else
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltWeekTemplate, 'LPM_REFERENTS_ID', iReferentsID);
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltWeekTemplate, 'HRM_DIVISION_ID', iDivisionID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltWeekTemplate, 'LWT_DAY', iDayNum);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltWeekTemplate, 'LWT_LDO_VALUE', iValue);
    FWK_I_MGT_ENTITY.InsertEntity(ltWeekTemplate);
    -- Id du record crée
    oWeekTemplateID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltWeekTemplate, 'LPM_WEEK_TEMPLATE_ID');
    FWK_I_MGT_ENTITY.Release(ltWeekTemplate);
  end InsertWeekTemplate;

  /**
  * procedure UpdateWeekTemplate
  * description :
  *    Mise à jour d'une ligne de configuration par défaut.
  */
  procedure UpdateWeekTemplate(iWeekTemplateID in LPM_WEEK_TEMPLATE.LPM_WEEK_TEMPLATE_ID%type, iValue in LPM_WEEK_TEMPLATE.LWT_LDO_VALUE%type)
  is
    ltWeekTemplate FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Init des données du tuple LPM_WEEK_TEMPLATE
    FWK_I_MGT_ENTITY.new(FWK_TYP_LPM_ENTITY.gcLpmWeekTemplate, ltWeekTemplate, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltWeekTemplate, 'LPM_WEEK_TEMPLATE_ID', iWeekTemplateID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltWeekTemplate, 'LWT_LDO_VALUE', iValue);
    FWK_I_MGT_ENTITY.UpdateEntity(ltWeekTemplate);
    FWK_I_MGT_ENTITY.Release(ltWeekTemplate);
  end UpdateWeekTemplate;

/**
  * procedure CleanReferentsWeekTemplate
  * description :
  *    Supprime les templates liés à une appartenance et qui ne serait plus dans
  *    la meme division (si on change de division sur l'appartenance)
  */
  procedure CleanReferentsWeekTemplate(iReferentsID in LPM_REFERENTS.LPM_REFERENTS_ID%type)
  is
    beneficiaryID  SCH_STUDENT.SCH_STUDENT_ID%type;
    divisionID     HRM_DIVISION.HRM_DIVISION_ID%type;
    ltWeekTemplate FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    select SCH_STUDENT_ID
         , HRM_DIVISION_ID
      into beneficiaryID
         , divisionID
      from LPM_REFERENTS
     where LPM_REFERENTS_ID = iReferentsID;

    for ltplMissingWeekTmpl in (select LPM_WEEK_TEMPLATE_ID
                                  from LPM_WEEK_TEMPLATE
                                 where SCH_STUDENT_ID = beneficiaryID
                                   and LPM_REFERENTS_ID = iReferentsID
                                   and HRM_DIVISION_ID <> divisionID) loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_LPM_ENTITY.gcLpmWeekTemplate, ltWeekTemplate);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltWeekTemplate, 'LPM_WEEK_TEMPLATE_ID', ltplMissingWeekTmpl.LPM_WEEK_TEMPLATE_ID);
      FWK_I_MGT_ENTITY.DeleteEntity(ltWeekTemplate);
      FWK_I_MGT_ENTITY.Release(ltWeekTemplate);
    end loop;
  end CleanReferentsWeekTemplate;
end LPM_PRC_WEEK_TEMPLATE;
