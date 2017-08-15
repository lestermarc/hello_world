--------------------------------------------------------
--  DDL for Package Body SCH_ECOLAGE_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SCH_ECOLAGE_FUNCTIONS" 
is
  /**
  * procedure SelectEcolage
  * Description : Sélection des écolages via la table COM_LIST_ID_TEMP pour les
  *               traitements de génération des associations écolages - débiteurs
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aECO_MAJOR_REF_FROM : référence principale de
  * @param   aECO_MAJOR_REF_TO : référence principale à
  * @param   aECO_SECOND_REF_FROM : référence secondaire de
  * @param   aECO_SECOND_REF_TO varchar2 : référence secondaire à
  */
  procedure SelectEcolage(aECO_MAJOR_REF_FROM varchar2, aECO_MAJOR_REF_TO varchar2, aECO_SECOND_REF_FROM varchar2, aECO_SECOND_REF_TO varchar2)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'SCH_ECOLAGE_ID';

    -- Sélection des ID de produits à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct ECO.SCH_ECOLAGE_ID
                    , 'SCH_ECOLAGE_ID'
                 from SCH_ECOLAGE ECO
                where (    (    aECO_MAJOR_REF_FROM is null
                            and aECO_MAJOR_REF_TO is null)
                       or ECO.ECO_MAJOR_REFERENCE between nvl(aECO_MAJOR_REF_FROM, ECO.ECO_MAJOR_REFERENCE) and nvl(aECO_MAJOR_REF_TO, ECO.ECO_MAJOR_REFERENCE)
                      )
                  and (    (    aECO_SECOND_REF_FROM is null
                            and aECO_SECOND_REF_TO is null)
                       or ECO.ECO_SECONDARY_REFERENCE between nvl(aECO_SECOND_REF_FROM, ECO.ECO_SECONDARY_REFERENCE)
                                                          and nvl(aECO_SECOND_REF_TO, ECO.ECO_SECONDARY_REFERENCE)
                      );
  end SelectEcolage;

  /**
  * procedure SelectEcolageCategory
  * Description : Sélection des catégories d'écolage via la table COM_LIST_ID_TEMP pour les
  *              traitements de génération des associations écolages - débiteurs
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aCAT_MAJOR_REF_FROM : référence principale de
  * @param   aCAT_MAJOR_REF_TO : référence principale à
  * @param   aCAT_COU_SECOND_REF_FROM : référence secondaire de
  * @param   aCAT_COU_SECOND_REF_TO varchar2 : référence secondaire à
  */
  procedure SelectEcolageCategory(aCAT_MAJOR_REF_FROM varchar2, aCAT_MAJOR_REF_TO varchar2, aCAT_SECOND_REF_FROM varchar2, aCAT_SECOND_REF_TO varchar2)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'SCH_ECOLAGE_CATEGORY_ID';

    -- Sélection des ID de produits à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct CAT.SCH_ECOLAGE_CATEGORY_ID
                    , 'SCH_ECOLAGE_CATEGORY_ID'
                 from SCH_ECOLAGE_CATEGORY CAT
                where CAT.SCH_ECOLAGE_ID in(select COM_LIST_ID_TEMP_ID
                                              from COM_LIST_ID_TEMP
                                             where LID_CODE = 'SCH_ECOLAGE_ID')
                  and (    (    aCAT_MAJOR_REF_FROM is null
                            and aCAT_MAJOR_REF_TO is null)
                       or CAT.CAT_MAJOR_REFERENCE between nvl(aCAT_MAJOR_REF_FROM, CAT.CAT_MAJOR_REFERENCE) and nvl(aCAT_MAJOR_REF_TO, CAT.CAT_MAJOR_REFERENCE)
                      )
                  and (    (    aCAT_SECOND_REF_FROM is null
                            and aCAT_SECOND_REF_TO is null)
                       or CAT.CAT_SECONDARY_REFERENCE between nvl(aCAT_SECOND_REF_FROM, CAT.CAT_SECONDARY_REFERENCE)
                                                          and nvl(aCAT_SECOND_REF_TO, CAT.CAT_SECONDARY_REFERENCE)
                      );
  end SelectEcolageCategory;

  /**
  * procedure GenTemporaryAssociations
  * Description : Génération des associations temporaires
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aUseStudents : Génération associations par élèves
  * @param   aUseEcolageCategory : Génération associations par catégorie d'écolages
  * @param   aDefaultSelected : Enregistrement sélectionnés par défaut
  * @param   aForCreate : Génération pour génération de nouvelles associations, sinon
  *          sélection pour suppression
  * @param   aValidDateFrom : date de validité
  * @param   aValidDateTo : date de validité
  * @param   aPercent : % de prise en charge
  * @param   aConvertFactor : Facteur de conversion
  * @param   aAcsAccountId : Centre d'analyse
  */
  procedure GenTemporaryAssociations(
    aUseStudents        integer
  , aUseEcolageCategory integer
  , aDefaultSelected    integer default 1
  , aForCreate          integer default 1
  , aValidDateFrom      date default null
  , aValidDateTo        date default null
  , aPercent            number default null
  , aConvertFactor      number default null
  , aAcsAccountId       number default null
  )
  is
  begin
    SCH_OUTLAY_FUNCTIONS.GenTemporaryAssociations(aUseStudents          => aUseStudents
                                                , aUseOutlayCategory    => 0
                                                , aUseEcolageCategory   => aUseEcolageCategory
                                                , aOutlayAssociation    => 0
                                                , aDefaultSelected      => aDefaultSelected
                                                , aForCreate            => aForCreate
                                                , aValidDateFrom        => aValidDateFrom
                                                , aValidDateTo          => aValidDateTo
                                                , aPercent              => aPercent
                                                , aConvertFactor        => aConvertFactor
                                                , aAcsAccountId         => aAcsAccountId
                                                 );
  end GenTemporaryAssociations;

  /**
  * procedure CopyFreeDataFromEcolage
  * Description : Copie des données libres depuis les écolages si besoin
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSCH_ECOLAGE_ID : Débours
  * @param   aSCH_ECOLAGE_CATEGORY_ID : Catégorie de débours
  */
  procedure CopyFreeDataFromEcolage(aSCH_ECOLAGE_ID in number, aSCH_ECOLAGE_CATEGORY_ID in number)
  is
  begin
    insert into SCH_FREE_DATA
                (SCH_FREE_DATA_ID
               , SCH_ECOLAGE_CATEGORY_ID
               , DIC_SCH_FREE_TABLE1_ID
               , DIC_SCH_FREE_TABLE2_ID
               , DIC_SCH_FREE_TABLE3_ID
               , DIC_SCH_FREE_TABLE4_ID
               , DIC_SCH_FREE_TABLE5_ID
               , SFD_ALPHA_SHORT_1
               , SFD_ALPHA_SHORT_2
               , SFD_ALPHA_SHORT_3
               , SFD_ALPHA_SHORT_4
               , SFD_ALPHA_SHORT_5
               , SFD_ALPHA_LONG_1
               , SFD_ALPHA_LONG_2
               , SFD_ALPHA_LONG_3
               , SFD_ALPHA_LONG_4
               , SFD_ALPHA_LONG_5
               , SFD_INTEGER_1
               , SFD_INTEGER_2
               , SFD_INTEGER_3
               , SFD_INTEGER_4
               , SFD_INTEGER_5
               , SFD_BOOLEAN_1
               , SFD_BOOLEAN_2
               , SFD_BOOLEAN_3
               , SFD_BOOLEAN_4
               , SFD_BOOLEAN_5
               , SFD_DECIMAL_1
               , SFD_DECIMAL_2
               , SFD_DECIMAL_3
               , SFD_DECIMAL_4
               , SFD_DECIMAL_5
               , SFD_DATE_1
               , SFD_DATE_2
               , SFD_DATE_3
               , SFD_DATE_4
               , SFD_DATE_5
               , A_DATECRE
               , A_IDCRE
               , SFD_CATEGORY_COPY
               , SFD_TRANSFERT
                )
      select GetNewId
           , aSCH_ECOLAGE_CATEGORY_ID
           , DIC_SCH_FREE_TABLE1_ID
           , DIC_SCH_FREE_TABLE2_ID
           , DIC_SCH_FREE_TABLE3_ID
           , DIC_SCH_FREE_TABLE4_ID
           , DIC_SCH_FREE_TABLE5_ID
           , SFD_ALPHA_SHORT_1
           , SFD_ALPHA_SHORT_2
           , SFD_ALPHA_SHORT_3
           , SFD_ALPHA_SHORT_4
           , SFD_ALPHA_SHORT_5
           , SFD_ALPHA_LONG_1
           , SFD_ALPHA_LONG_2
           , SFD_ALPHA_LONG_3
           , SFD_ALPHA_LONG_4
           , SFD_ALPHA_LONG_5
           , SFD_INTEGER_1
           , SFD_INTEGER_2
           , SFD_INTEGER_3
           , SFD_INTEGER_4
           , SFD_INTEGER_5
           , SFD_BOOLEAN_1
           , SFD_BOOLEAN_2
           , SFD_BOOLEAN_3
           , SFD_BOOLEAN_4
           , SFD_BOOLEAN_5
           , SFD_DECIMAL_1
           , SFD_DECIMAL_2
           , SFD_DECIMAL_3
           , SFD_DECIMAL_4
           , SFD_DECIMAL_5
           , SFD_DATE_1
           , SFD_DATE_2
           , SFD_DATE_3
           , SFD_DATE_4
           , SFD_DATE_5
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
           , 0
           , 0
        from SCH_FREE_DATA
       where SCH_ECOLAGE_ID = aSCH_ECOLAGE_ID
         and SFD_CATEGORY_COPY = 1
         and aSCH_ECOLAGE_ID is not null
         and aSCH_ECOLAGE_CATEGORY_ID is not null;
  end CopyFreeDataFromEcolage;
end SCH_ECOLAGE_FUNCTIONS;
