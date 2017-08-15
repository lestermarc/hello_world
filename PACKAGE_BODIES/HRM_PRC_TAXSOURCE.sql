--------------------------------------------------------
--  DDL for Package Body HRM_PRC_TAXSOURCE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_PRC_TAXSOURCE" 
as
  /**
  * procedure UpdateEmpTaxSourceDateOut
  * description :
  *    Ajout d'une ligne de journalisation de l'impôt à la source
  */
  procedure UpdateEmpTaxSourceDateOut(iHRM_PERSON_ID in HRM_PERSON.HRM_PERSON_ID%type, iINO_OUT in HRM_IN_OUT.INO_OUT%type)
  is
    ltTaxSource FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    if HRM_LIB_TAXSOURCE.HasTaxSourceEndedPeriod(iHRM_PERSON_ID, iINO_OUT) > 0 then
      raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('Veuillez vérifier les périodes d''assujettissement') );
    end if;

    for tplTaxSrc in (select HRM_EMPLOYEE_TAXSOURCE_ID
                        from HRM_EMPLOYEE_TAXSOURCE
                       where HRM_PERSON_ID = iHRM_PERSON_ID
                         and EMT_TO is null
                         and EMT_FROM < iINO_OUT) loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_HRM_ENTITY.gcHrmEmployeeTaxsource, ltTaxSource, true);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSource, 'HRM_EMPLOYEE_TAXSOURCE_ID', tplTaxSrc.HRM_EMPLOYEE_TAXSOURCE_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSource, 'EMT_TO', iINO_OUT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTaxSource, 'C_HRM_TAX_OUT', '01');
      FWK_I_MGT_ENTITY.UpdateEntity(ltTaxSource);
      FWK_I_MGT_ENTITY.Release(ltTaxSource);
    end loop;
  end UpdateEmpTaxSourceDateOut;
end HRM_PRC_TAXSOURCE;
