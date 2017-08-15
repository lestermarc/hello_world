--------------------------------------------------------
--  DDL for Package Body ACS_PRC_ALTERNATIVE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_PRC_ALTERNATIVE" 
is
  /**
  * Description Fonctions principale d'imporation des comptes financier dans la présentation alternative
  **/
  procedure ImportAccIntoAlternative(
    in_AlternativeId     in     ACS_ALTERNATIVE.ACS_ALTERNATIVE_ID%type
  , in_SubSetId          in     ACS_SUB_SET.ACS_SUB_SET_ID%type
  , in_ImportDescription in     number
  , on_ImportedAcc       out    number
  )
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    on_ImportedAcc  := 0;
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACS_ENTITY.gcAcsSynonymData, lt_crud_def);

    for tplAccount in (select ACC.ACS_ACCOUNT_ID
                            , ACC.ACC_NUMBER
                         from ACS_ACCOUNT ACC
                        where ACC.ACS_SUB_SET_ID = in_SubSetId
                          and not exists(select 1
                                           from ACS_SYNONYM_DATA SYN
                                          where SYN.ACS_ALTERNATIVE_ID = in_AlternativeId
                                            and ACC.ACS_ACCOUNT_ID = SYN.ACS_ACCOUNT_ID) ) loop
      on_ImportedAcc  := on_ImportedAcc + 1;
      FWK_I_MGT_ENTITY.clear(lt_crud_def);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_ALTERNATIVE_ID', in_AlternativeId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_ACCOUNT_ID', tplAccount.ACS_ACCOUNT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'SYN_NUMBER', tplAccount.ACC_NUMBER);
      FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
    end loop;

    if in_ImportDescription = 1 then
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACS_ENTITY.gcAcsAltDescription, lt_crud_def);

      for tplDescription in (select DES.DES_DESCRIPTION_SUMMARY
                                  , DES.DES_DESCRIPTION_LARGE
                                  , DES.PC_LANG_ID
                                  , SYN.ACS_SYNONYM_DATA_ID
                               from ACS_DESCRIPTION DES
                                  , ACS_SYNONYM_DATA SYN
                              where SYN.ACS_ALTERNATIVE_ID = in_AlternativeId
                                and DES.ACS_ACCOUNT_ID = SYN.ACS_ACCOUNT_ID
                                and not exists(select 1
                                                 from ACS_ALT_DESCRIPTION DES2
                                                    , ACS_SYNONYM_DATA SYN2
                                                where SYN2.ACS_SYNONYM_DATA_ID = DES2.ACS_SYNONYM_DATA_ID
                                                  and SYN.ACS_SYNONYM_DATA_ID = SYN2.ACS_SYNONYM_DATA_ID) ) loop
        FWK_I_MGT_ENTITY.clear(lt_crud_def);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_ALTERNATIVE_ID', in_AlternativeId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_SYNONYM_DATA_ID', tplDescription.ACS_SYNONYM_DATA_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ALT_DESCRIPTION', tplDescription.DES_DESCRIPTION_SUMMARY);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ALT_LONG_DESCRIPTION', tplDescription.DES_DESCRIPTION_LARGE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'PC_LANG_ID', tplDescription.PC_LANG_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ALT_DESCRIPTION', tplDescription.DES_DESCRIPTION_SUMMARY);
        FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
      end loop;
    end if;
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end ImportAccIntoAlternative;
end ACS_PRC_ALTERNATIVE;
