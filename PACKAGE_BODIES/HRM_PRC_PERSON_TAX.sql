--------------------------------------------------------
--  DDL for Package Body HRM_PRC_PERSON_TAX
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_PRC_PERSON_TAX" 
as
  /**
  * procedure InsertPersonTax
  * description :
  *    Ajout d'un certificat de salaire pour l'année de la période active (si pas déjà existant)
  */
  procedure InsertPersonTax(
    iEmployeeID in HRM_PERSON.HRM_PERSON_ID%type default null
  , ivTaxYear   in HRM_PERSON_TAX.EMP_TAX_YEAR%type default to_char(HRM_DATE.BeginOfYear, 'yyyy')
  )
  is
    lnExist       number(1);
    lvLastTaxYear HRM_PERSON_TAX.EMP_TAX_YEAR%type;
    ltPersonTax   FWK_I_TYP_DEFINITION.t_crud_def;
    lPersonTaxID  HRM_PERSON_TAX.HRM_PERSON_TAX_ID%type;
  begin
    -- Recherche si les données de certificats existent
    select sign(count(*) )
      into lnExist
      from HRM_PERSON_TAX
     where nvl(HRM_PERSON_ID, -1) = nvl(iEmployeeID, -1)
       and EMP_TAX_YEAR = ivTaxYear;

    -- Ajouter un certificat de salaire pour l'année de la période active si pas encore existant pour l'employé
    if lnExist = 0 then
      -- Recherche l'année du dernier Certificat de salaire de l'employé
      select max(EMP_TAX_YEAR)
        into lvLastTaxYear
        from HRM_PERSON_TAX
       where nvl(HRM_PERSON_ID, -1) = nvl(iEmployeeID, -1);

      -- Si l'employé ne possède aucun certificat de salaire
      --  on en ajouter pour l'année de la période active avec toutes les valeurs à null
      if lvLastTaxYear is null then
        FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmPersonTax, ltPersonTax, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPersonTax, 'HRM_PERSON_ID', iEmployeeID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPersonTax, 'EMP_TAX_YEAR', ivTaxYear);
        FWK_I_MGT_ENTITY.InsertEntity(ltPersonTax);
        FWK_I_MGT_ENTITY.Release(ltPersonTax);
      else
        -- Recherche l'id du dernier certificat de salaire de l'employé
        select HRM_PERSON_TAX_ID
          into lPersonTaxID
          from HRM_PERSON_TAX
         where nvl(HRM_PERSON_ID, -1) = nvl(iEmployeeID, -1)
           and EMP_TAX_YEAR = lvLastTaxYear;

        -- Ajouter un certificat de salaire pour l'année de la période active en recopiant
        -- les données du dernier certificat de salaire de l'employé
        FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmPersonTax, ltPersonTax);
        FWK_I_MGT_ENTITY.PrepareDuplicate(ltPersonTax, true, lPersonTaxID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPersonTax, 'EMP_TAX_YEAR', ivTaxYear);
        FWK_I_MGT_ENTITY.InsertEntity(ltPersonTax);
        FWK_I_MGT_ENTITY.Release(ltPersonTax);
      end if;
    end if;
  end InsertPersonTax;
end HRM_PRC_PERSON_TAX;
