--------------------------------------------------------
--  DDL for Package Body SCH_STUDENT_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SCH_STUDENT_MANAGEMENT" 
is
  /***
  * procedure : UpdateEducationDegree
  * Description : Procedure qui change le degr� d'enseignement et l'ann�e de scolarit� pour l'�l�ve pass� en param�tre
  *
  * @created ECA
  * @lastUpdate
  * @private
  */
  procedure UpdateEducationDegree(iSchStudentId number, iYearMax number)
  is
    -- Curseur sur la table des degr�s d'enseignement
    cursor crEducationDegree(iYear number)
    is
      select   SCH_EDUCATION_DEGREE_ID
             , DEG_MIN_YEAR
          from SCH_EDUCATION_DEGREE
         where DEG_MAX_YEAR > iYear
      order by DEG_MAX_YEAR;

    tplEducationDegree crEducationDegree%rowtype;
  begin
    open crEducationDegree(iYearMax);

    fetch crEducationDegree
     into tplEducationDegree;

    if crEducationDegree%found then
      update SCH_STUDENT
         set STU_SCHOOL_YEAR = tplEducationDegree.DEG_MIN_YEAR
           , SCH_EDUCATION_DEGREE_ID = tplEducationDegree.SCH_EDUCATION_DEGREE_ID
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , STU_DEGREE_DATEMOD = sysdate
       where SCH_STUDENT_ID = iSchStudentId;
    end if;

    close crEducationDegree;
  end UpdateEducationDegree;

  /***
  * procedure : AddSchoolYear
  * Description : Procedure de modification de l'ann�e de scolarit� et du degr� de scolarit�
  *               correspondant si n�cessaire. ( R�alise le passage � l'ann�e sup�rieure)
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure AddSchoolYear
  is
    -- Curseur sur la table des ann�es
    cursor CUR_SCH_SCHOOL_YEAR
    is
      select   SCO_BEGIN_DATE
             , SCO_END_DATE
             , SCO_CURRENT_YEAR
          from SCH_SCHOOL_YEAR
      order by SCO_BEGIN_DATE asc;

    -- Curseur sur la table des �tudiants
    cursor CUR_SCH_STUDENT
    is
      select SS.SCH_STUDENT_ID
           , SS.SCH_EDUCATION_DEGREE_ID
           , SS.STU_SCHOOL_YEAR
           , SS.STU_ENTRY_DATE
           , SS.STU_EXIT_DATE
           , SED.DEG_MIN_YEAR
           , SED.DEG_MAX_YEAR
        from SCH_STUDENT SS
           , SCH_EDUCATION_DEGREE SED
       where SS.SCH_EDUCATION_DEGREE_ID = SED.SCH_EDUCATION_DEGREE_ID
         and nvl(SS.SCH_EDUCATION_DEGREE_ID, 0) <> 0
         and nvl(SS.STU_SCHOOL_YEAR, 1000) <> 1000;

    -- D�claration des variables
    CurSchStudent         CUR_SCH_STUDENT%rowtype;
    CurSchSchoolYear      CUR_SCH_SCHOOL_YEAR%rowtype;
    Current_Year_Begining date;
    Current_Year_Ending   date;
    Prior_Year_begining   date;
    Prior_Year_ending     date;
    Save_Year_begining    date;
    Save_Year_Ending      date;
  begin
    -- On r�cup�re les dates de d�but et fin de l'ann�e courante
    -- et de l'ann�e qui la pr�c�de
    open CUR_SCH_SCHOOL_YEAR;

    fetch CUR_SCH_SCHOOL_YEAR
     into CurSchSchoolYear;

    Save_Year_Begining  := CurSchSchoolYear.SCO_BEGIN_DATE;
    Save_Year_Ending    := CurSchSchoolYear.SCO_END_DATE;

    loop
      if CurSchSchoolYear.SCO_CURRENT_YEAR = 1 then
        Current_Year_Begining  := CurSchSchoolYear.SCO_BEGIN_DATE;
        Current_Year_Ending    := CurSchSchoolYear.SCO_END_DATE;
        Prior_Year_Begining    := Save_Year_Begining;
        Prior_Year_Ending      := Save_Year_Ending;
      end if;

      exit when CUR_SCH_SCHOOL_YEAR%notfound
            or CurSchSchoolYear.SCO_CURRENT_YEAR = 1;
      Save_Year_Begining  := CurSchSchoolYear.SCO_BEGIN_DATE;
      Save_Year_Ending    := CurSchSchoolYear.SCO_END_DATE;

      fetch CUR_SCH_SCHOOL_YEAR
       into CurSchSchoolYear;
    end loop;

    close CUR_SCH_SCHOOL_YEAR;

    /* Pour chaque �tudiant : On incr�mente l'ann�e de scolarit� et l'on met le degr� d'enseignement � jour
       seulement si l'�l�ve est inscrit pour l'ann�e en cours, et qu'il l'�tait �galement
       pour l'ann�e pr�c�dant cette ann�e en cours */
    for CurSchStudent in CUR_SCH_STUDENT loop
      if     (CurSchStudent.STU_ENTRY_DATE < Prior_Year_Ending)
         and (    (CurSchStudent.STU_EXIT_DATE is null)
              or (CurSchStudent.STU_EXIT_DATE > Current_Year_Begining) ) then
        /* Si son ann�e de scolarit� est �gale � l'ann�e max de son degr� d'enseignement alors
        on modifie son degr� d'enseignement et son ann�e de scolarit� est l'ann�e min
        de ce degr� d'enseignement */
        if CurSchStudent.STU_SCHOOL_YEAR = CurSchStudent.DEG_MAX_YEAR then
          UpdateEducationDegree(CurSchStudent.SCH_STUDENT_ID, CurSchStudent.DEG_MAX_YEAR);
        -- Sinon on incr�mente l'ann�e de scolarit� de 1
        else
          update SCH_STUDENT
             set STU_SCHOOL_YEAR = CurSchStudent.STU_SCHOOL_YEAR + 1
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
               , STU_DEGREE_DATEMOD = sysdate
           where SCH_STUDENT_ID = CurSchStudent.SCH_STUDENT_ID;
        end if;
      end if;
    end loop;
  end AddSchoolYear;

  /***
  * procedure : InsertDocRecord
  * Description : Procedure de cr�ation d'un dossier correspondant � un �l�ve
  *              (Num�ro de dossier = Num�ro de compte �l�ve)
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iRCO_TITLE : Dossier
  * @param   iDescription : Description dossier
  */
  procedure InsertDocRecord(iRCO_TITLE varchar2, iDescription varchar2)
  is
    -- Curseur sur les dossiers
    cursor crDocRecord
    is
      select DOC_RECORD_ID
        from DOC_RECORD
       where RCO_TITLE = iRCO_TITLE;

    tplDocRecord  crDocRecord%rowtype;
    lnDocRecordId DOC_RECORD.DOC_RECORD_ID%type;
    lnRcoNumber   number;
  begin
    -- V�rification de l'inexistance du dossier qui va �tre cr��
    lnDocRecordId  := 0;

    for tplDocRecord in crDocRecord loop
      lnDocRecordId  := tplDocRecord.DOC_RECORD_ID;
    end loop;

    if lnDocRecordId <> 0 then
      raise_application_error(-20000
                            , 'Erreur lors de la cr�ation automatique du dossier, dossier ' ||
                              iRCO_TITLE ||
                              'existant. Veuillez choisir un autre Num�ro de compte �l�ve pour cet �l�ve.'
                             );
    end if;

    -- Cr�ation du dossier correspondant au num�ro d'�l�ve pass� en param�tre
    select INIT_ID_SEQ.nextval
         , RCO_NUMBER_SEQ.nextval
      into lnDocRecordId
         , lnRcoNumber
      from dual;

    declare
      ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    begin
      FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocRecord, ltCRUD_DEF, true);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_RECORD_ID', lnDocRecordId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'RCO_TITLE', iRCO_TITLE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'RCO_NUMBER', lnRcoNumber);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'RCO_DESCRIPTION', iDescription);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATECRE', sysdate);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDCRE', PCS.PC_I_LIB_SESSION.GetUserINI);
      FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end;
  end InsertDocRecord;

  /***
  * procedure : UpdateDocRecord
  * Description : Procedure de mise � jour du nom d'un dossier correspondant � un �l�ve
  *              (Num�ro de dossier = Num�ro de compte �l�ve)
  *
  * @created RBA
  * @lastUpdate
  * @public
  * @param   iRCO_TITLE : Dossier
  * @param   iDescription : Description dossier
  */
  procedure UpdateDocRecord(iRCO_TITLE varchar2, iDescription varchar2)
  is
    lnDocRecordId DOC_RECORD.DOC_RECORD_ID%type;
    ltCRUD_DEF    FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- r�cup�re l'id du dossier
    select DOC_RECORD_ID
      into lnDocRecordId
      from DOC_RECORD
     where RCO_TITLE = iRCO_TITLE;

    -- met � jour la description du dossier
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocRecord, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_RECORD_ID', lnDocRecordId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'RCO_DESCRIPTION', iDescription);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end UpdateDocRecord;

  /***
  * procedure : DeleteDocRecord
  * Description : Suppression d'un dossier
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iRCO_TITLE : Dossier
  */
  procedure DeleteDocRecord(iRCO_TITLE DOC_RECORD.RCO_TITLE%type)
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplDocRecord in (select DOC_RECORD_ID
                           from DOC_RECORD
                          where RCO_TITLE = iRCO_TITLE) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocRecord, ltCRUD_DEF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_RECORD_ID', tplDocRecord.DOC_RECORD_ID);
      FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      exit;
    end loop;
  end DeleteDocRecord;

  /***
  * procedure : DeleteLinkedCustomer
  * Description : Suppression d'un d�biteur li�
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSCH_STUDENT_S_CUSTOMER_ID : Lien �l�ve / d�biteur
  */
  procedure DeleteLinkedCustomer(iSCH_STUDENT_S_CUSTOMER_ID in number)
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplStudentSCustomer in (select SCU.SCH_STUDENT_S_CUSTOMER_ID
                                     , SCU.SCH_STUDENT_ID
                                     , SCU.PAC_CUSTOM_PARTNER_ID
                                     , STU.PAC_CUSTOM_PARTNER1_ID
                                     , STU.PAC_CUSTOM_PARTNER2_ID
                                  from SCH_STUDENT_S_CUSTOMER SCU
                                     , SCH_STUDENT STU
                                 where SCU.SCH_STUDENT_S_CUSTOMER_ID = iSCH_STUDENT_S_CUSTOMER_ID
                                   and SCU.SCH_STUDENT_ID = STU.SCH_STUDENT_ID) loop
      -- Mise � nul du d�biteur Ecolage par d�faut
      if    (tplStudentSCustomer.PAC_CUSTOM_PARTNER1_ID = tplStudentSCustomer.PAC_CUSTOM_PARTNER_ID)
         or (tplStudentSCustomer.PAC_CUSTOM_PARTNER2_ID = tplStudentSCustomer.PAC_CUSTOM_PARTNER_ID) then
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_SCH_ENTITY.gcSchStudent, ltCRUD_DEF);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_STUDENT_ID', tplStudentSCustomer.SCH_STUDENT_ID);

        if (tplStudentSCustomer.PAC_CUSTOM_PARTNER1_ID = tplStudentSCustomer.PAC_CUSTOM_PARTNER_ID) then
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_CUSTOM_PARTNER1_ID', cast(null as number) );
        end if;

        if (tplStudentSCustomer.PAC_CUSTOM_PARTNER2_ID = tplStudentSCustomer.PAC_CUSTOM_PARTNER_ID) then
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_CUSTOM_PARTNER2_ID', cast(null as number) );
        end if;

        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATEMOD', sysdate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDMOD', PCS.PC_I_LIB_SESSION.GetUserIni);
        FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end if;

      -- Suppression des associations
      for tplAssociations in (select SCH_CUSTOMERS_ASSOCIATION_ID
                                from SCH_CUSTOMERS_ASSOCIATION
                               where SCH_STUDENT_ID = tplStudentSCustomer.SCH_STUDENT_ID
                                 and PAC_CUSTOM_PARTNER_ID = tplStudentSCustomer.PAC_CUSTOM_PARTNER_ID) loop
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_SCH_ENTITY.gcSchCustomersAssociation, ltCRUD_DEF);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_CUSTOMERS_ASSOCIATION_ID', tplAssociations.SCH_CUSTOMERS_ASSOCIATION_ID);
        FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end loop;

      -- Suppression du lien d�biteur / �l�ve correspondant
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_SCH_ENTITY.gcSchStudentSCustomer, ltCRUD_DEF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_STUDENT_S_CUSTOMER_ID', tplStudentSCustomer.SCH_STUDENT_S_CUSTOMER_ID);
      FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      exit;
    end loop;
  end DeleteLinkedCustomer;

  /***
  * procedure : UpdateLinkedCustomer
  * Description : Modification d'un d�biteur li�
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSCH_STUDENT_S_CUSTOMER_ID : Lien �l�ve / d�biteur
  * @param   iNewPacCustomPartnerId : Nouveau d�biteur
  */
  procedure UpdateLinkedCustomer(iSCH_STUDENT_S_CUSTOMER_ID in number, iNewPacCustomPartnerId in number)
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplStudentSCustomer in (select SCU.SCH_STUDENT_S_CUSTOMER_ID
                                     , SCU.SCH_STUDENT_ID
                                     , SCU.PAC_CUSTOM_PARTNER_ID
                                     , STU.PAC_CUSTOM_PARTNER1_ID
                                     , STU.PAC_CUSTOM_PARTNER2_ID
                                  from SCH_STUDENT_S_CUSTOMER SCU
                                     , SCH_STUDENT STU
                                 where SCU.SCH_STUDENT_S_CUSTOMER_ID = iSCH_STUDENT_S_CUSTOMER_ID
                                   and SCU.SCH_STUDENT_ID = STU.SCH_STUDENT_ID) loop
      -- Mise � jour du d�biteur Ecolage par d�faut
      if (tplStudentSCustomer.PAC_CUSTOM_PARTNER1_ID = tplStudentSCustomer.PAC_CUSTOM_PARTNER_ID) then
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_SCH_ENTITY.gcSchStudent, ltCRUD_DEF);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_STUDENT_ID', tplStudentSCustomer.SCH_STUDENT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_CUSTOM_PARTNER1_ID', iNewPacCustomPartnerId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATEMOD', sysdate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDMOD', PCS.PC_I_LIB_SESSION.GetUserIni);
        FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end if;

      -- Mise � jour du d�biteur d�bours par d�faut
      if (tplStudentSCustomer.PAC_CUSTOM_PARTNER2_ID = tplStudentSCustomer.PAC_CUSTOM_PARTNER_ID) then
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_SCH_ENTITY.gcSchStudent, ltCRUD_DEF);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_STUDENT_ID', tplStudentSCustomer.SCH_STUDENT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_CUSTOM_PARTNER2_ID', iNewPacCustomPartnerId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATEMOD', sysdate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDMOD', PCS.PC_I_LIB_SESSION.GetUserIni);
        FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end if;

      -- Modification des associations
      for tplAssociations in (select SCH_CUSTOMERS_ASSOCIATION_ID
                                from SCH_CUSTOMERS_ASSOCIATION
                               where SCH_STUDENT_ID = tplStudentSCustomer.SCH_STUDENT_ID
                                 and PAC_CUSTOM_PARTNER_ID = tplStudentSCustomer.PAC_CUSTOM_PARTNER_ID) loop
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_SCH_ENTITY.gcSchCustomersAssociation, ltCRUD_DEF);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_CUSTOMERS_ASSOCIATION_ID', tplAssociations.SCH_CUSTOMERS_ASSOCIATION_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_CUSTOM_PARTNER_ID', iNewPacCustomPartnerId);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_DATEMOD', sysdate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'A_IDMOD', PCS.PC_I_LIB_SESSION.GetUserIni);
        FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end loop;

      -- Modification du lien d�biteur / �l�ve correspondant
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_SCH_ENTITY.gcSchStudentSCustomer, ltCRUD_DEF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCH_STUDENT_S_CUSTOMER_ID', tplStudentSCustomer.SCH_STUDENT_S_CUSTOMER_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_CUSTOM_PARTNER_ID', iNewPacCustomPartnerId);
      FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      exit;
    end loop;
  end UpdateLinkedCustomer;

  /***
  * procedure : DeletePhoto
  * Description : Suppression d'une photo de l'album
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iCOM_IMAGE_FILES_ID : Photo
  */
  procedure DeletePhoto(iCOM_IMAGE_FILES_ID in number)
  is
    lnCOM_OLE_ID number;
  begin
    -- Si stockage en BD, Suppresion du COM_OLE
    select COM_OLE_ID
      into lnCOM_OLE_ID
      from COM_IMAGE_FILES
    where  COM_IMAGE_FILES_ID = iCOM_IMAGE_FILES_ID;

    delete from COM_IMAGE_FILES
     where COM_IMAGE_FILES_ID = iCOM_IMAGE_FILES_ID;

    delete from COM_OLE
     where COM_OLE_ID = lnCOM_OLE_ID;

  exception
    when others then
      null;
  end DeletePhoto;

  /***
  * procedure : InsertPresenceHistory
  * Description : Insertion d'un historique des dates entr�es et sorties
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSchStudentId : El�ve
  * @param   iNewEntryDate : Nouvelle date d'ent�re
  * @param   iOldEntryDate : Ancienne date d'entr�e
  * @param   iNewExitDate : Nouvelle date de sortie
  * @param   iOldExitDate : Ancienne date de sortie
  */
  procedure InsertPresenceHistory(iSchStudentId in number, iNewEntryDate in date, iOldEntryDate in date, iNewExitDate in date, iOldExitDate in date)
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_SCH_ENTITY.gcSchPresenceHistory, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'SCH_STUDENT_ID', iSchStudentId);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'SPH_NEW_ENTRY_DATE', iNewEntryDate);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'SPH_OLD_ENTRY_DATE', iOldEntryDate);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'SPH_NEW_EXIT_DATE', iNewExitDate);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_DEF, 'SPH_OLD_EXIT_DATE', iOldExitDate);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end InsertPresenceHistory;
end;
