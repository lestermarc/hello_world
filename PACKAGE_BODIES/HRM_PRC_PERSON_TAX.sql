--------------------------------------------------------
--  DDL for Package Body HRM_PRC_PERSON_TAX
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_PRC_PERSON_TAX" 
as
  /**
  * procedure InsertPersonTax
  * description :
  *    Ajout d'un certificat de salaire pour l'ann�e de la p�riode active (si pas d�j� existant)
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
    -- Recherche si les donn�es de certificats existent
    select sign(count(*) )
      into lnExist
      from HRM_PERSON_TAX
     where nvl(HRM_PERSON_ID, -1) = nvl(iEmployeeID, -1)
       and EMP_TAX_YEAR = ivTaxYear;

    -- Ajouter un certificat de salaire pour l'ann�e de la p�riode active si pas encore existant pour l'employ�
    if lnExist = 0 then
      -- Recherche l'ann�e du dernier Certificat de salaire de l'employ�
      select max(EMP_TAX_YEAR)
        into lvLastTaxYear
        from HRM_PERSON_TAX
       where nvl(HRM_PERSON_ID, -1) = nvl(iEmployeeID, -1);

      -- Si l'employ� ne poss�de aucun certificat de salaire
      --  on en ajouter pour l'ann�e de la p�riode active avec toutes les valeurs � null
      if lvLastTaxYear is null then
        FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmPersonTax, ltPersonTax, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPersonTax, 'HRM_PERSON_ID', iEmployeeID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPersonTax, 'EMP_TAX_YEAR', ivTaxYear);
        FWK_I_MGT_ENTITY.InsertEntity(ltPersonTax);
        FWK_I_MGT_ENTITY.Release(ltPersonTax);
      else
        -- Recherche l'id du dernier certificat de salaire de l'employ�
        select HRM_PERSON_TAX_ID
          into lPersonTaxID
          from HRM_PERSON_TAX
         where nvl(HRM_PERSON_ID, -1) = nvl(iEmployeeID, -1)
           and EMP_TAX_YEAR = lvLastTaxYear;

        -- Ajouter un certificat de salaire pour l'ann�e de la p�riode active en recopiant
        -- les donn�es du dernier certificat de salaire de l'employ�
        FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmPersonTax, ltPersonTax);
        FWK_I_MGT_ENTITY.PrepareDuplicate(ltPersonTax, true, lPersonTaxID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPersonTax, 'EMP_TAX_YEAR', ivTaxYear);
        FWK_I_MGT_ENTITY.InsertEntity(ltPersonTax);
        FWK_I_MGT_ENTITY.Release(ltPersonTax);
      end if;
    end if;
  end InsertPersonTax;
end HRM_PRC_PERSON_TAX;
