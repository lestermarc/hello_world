--------------------------------------------------------
--  DDL for Package Body FAL_PROGRAM_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PROGRAM_FUNCTIONS" 
is
  /**
  * function GetNewJopReference
  * Description
  *   Obtention d'une nouvelle r�f�rence de programme.
  * @author CLE
  * @return La nouvelle r�f�rence de programme
  */
  function GetNewJopReference(aStartValue integer default null)
    return fal_job_program.jop_reference%type
  is
    MaxJopReference        integer;
    CfgFalProgramNumbering integer;
  begin
    CfgFalProgramNumbering  := to_number(PCS.PC_CONFIG.GetConfig('FAL_PROGRAM_NUMBERING') );

    if aStartValue is null then
      -- S�lection du plus grand JOP_REFERENCE des tables FAL_JOB_PROGRAM et FAL_JOB_PROGRAM_HIST
      select greatest( (select nvl(max(JOP_REFERENCE), 0)
                          from FAL_JOB_PROGRAM), (select nvl(max(JOP_REFERENCE), 0)
                                                    from FAL_JOB_PROGRAM_HIST) )
        into MaxJopReference
        from dual;
    else
      MaxJopReference  := aStartValue;
    end if;

    -- Il faut incr�menter � la dizaine sup�rieure la plus proche
    if (MaxJopReference mod CfgFalProgramNumbering) <> 0 then
      MaxJopReference  := (round(MaxJopReference / CfgFalProgramNumbering) * CfgFalProgramNumbering) + CfgFalProgramNumbering;
    else
      MaxJopReference  := MaxJopReference + CfgFalProgramNumbering;
    end if;

    if MaxJopReference >= power(10, to_number(PCS.PC_CONFIG.GetConfig('FAL_PGM_REF_LENGTH') ) ) then
      raise_application_error(-20001, PCS.PC_FUNCTIONS.TranslateWord('PCS - La valeur de la configuration FAL_PGM_REF_LENGTH n''est pas assez �lev�e !') );
    end if;

    return MaxJopReference;
  end;

  /**
  * procedure InsertProgram
  * Description
  *   Cr�ation d'un nouveau programme de fabrication
  * @author CLE
  * @return     True si programme cr��, False sinon.
  */
  function InsertProgram(
    aFAL_JOB_PROGRAM_ID fal_job_program.fal_job_program_id%type
  , aJOP_REFERENCE      fal_job_program.jop_reference%type
  , aJOP_SHORT_DESCR    fal_job_program.jop_short_descr%type
  , aDOC_RECORD_ID      fal_job_program.doc_record_id%type
  , aC_FAB_TYPE         fal_job_program.C_FAB_TYPE%type default 0
  )
    return boolean
  is
  begin
    insert into FAL_JOB_PROGRAM
                (FAL_JOB_PROGRAM_ID
               , JOP_REFERENCE
               , JOP_SHORT_DESCR
               , DOC_RECORD_ID
               , C_FAB_TYPE
               , A_DATECRE
               , A_IDCRE
                )
         values (aFAL_JOB_PROGRAM_ID
               , aJOP_REFERENCE
               , aJOP_SHORT_DESCR
               , aDOC_RECORD_ID
               , aC_FAB_TYPE
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    return true;
  exception
    when dup_val_on_index then
      return false;
  end;

  /**
  * procedure CreateManufactureProgram
  * Description
  *   Cr�ation d'un nouveau programme de fabrication
  * @author CLE
  * @lastUpdate
  * @public
  * @param      aJopShortDescr  Description courte du programme
  * @param      aDocRecordId    Dossier
  * @return     Id du programme cr��
  */
  function CreateManufactureProgram(aJopShortDescr fal_job_program.jop_short_descr%type, aDocRecordId fal_job_program.doc_record_id%type default null)
    return fal_job_program.fal_job_program_id%type
  is
    FalJobProgramId fal_job_program.fal_job_program_id%type;
    JopReference    fal_job_program.jop_reference%type;
  begin
    FalJobProgramId := GetNewId;
    JopReference  := null;

    loop
      JopReference  := GetNewJopReference(JopReference);
      exit when InsertProgram(FalJobProgramId, JopReference, aJopShortDescr, aDocRecordId) = true;
    end loop;

    return FalJobProgramId;
  end;

  /**
  * Description
  *   Cr�ation d'un nouveau programme de sous-traitance
  */
  function CreateSubContractProgram(iJopReference in fal_job_program.jop_reference%type, iJopShortDescr in fal_job_program.jop_short_descr%type)
    return fal_job_program.fal_job_program_id%type
  is
    FalJobProgramId fal_job_program.fal_job_program_id%type;
    JopReference    fal_job_program.jop_reference%type;
  begin
    FalJobProgramId  := getNewId;

    if InsertProgram(FalJobProgramId, iJopReference, iJopShortDescr, null, '4') then
      return FalJobProgramId;
    else
      return null;
    end if;
  end CreateSubContractProgram;

  /**
  * procedure CreateManufactureProgram
  * Description
  *   Cr�ation d'un nouveau programme de fabrication
  * @author CLE
  * @lastUpdate
  * @public
  * @param      aJopShortDescr    Description courte du programme
  * @param      aDocRecordId      Dossier
  * @param      aFalJobProgramId  param�tre de sortie Id de l'ordre cr��
  */
  procedure CreateManufactureProgram(
    aJopShortDescr          fal_job_program.jop_short_descr%type
  , aDocRecordId            fal_job_program.doc_record_id%type default null
  , aFalJobProgramId in out fal_job_program.fal_job_program_id%type
  )
  is
  begin
    aFalJobProgramId  := CreateManufactureProgram(aJopShortDescr, aDocRecordId);
  end;

  /**
  * procedure UpdateManufactureProgram
  * Description
  *   Mise � jour programme. Le d�lai sup�rieur est �gal au plus grand d�lai des ordres du programme
  * @author CLE
  * @lastUpdate
  * @public
  * @param      aFalJobProgramId  Id du programme
  * @param      aFalOrderId       Ordre dont le programme doit �tre mis � jour
  */
  procedure UpdateManufactureProgram(aFalJobProgramId number default null, aFalOrderId number default null)
  is
  begin
    update FAL_JOB_PROGRAM
       set JOP_LARGEST_END_DATE =
             (select max(ORD_END_DATE)
                from FAL_ORDER
               where (    aFalJobProgramId is not null
                      and FAL_JOB_PROGRAM_ID = aFalJobProgramId)
                  or (    aFalJobProgramId is null
                      and FAL_JOB_PROGRAM_ID = (select FAL_JOB_PROGRAM_ID
                                                  from FAL_ORDER
                                                 where FAL_ORDER_ID = aFalOrderId) ) )
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where (    aFalJobProgramId is not null
            and FAL_JOB_PROGRAM_ID = aFalJobProgramId)
        or (    aFalJobProgramId is null
            and FAL_JOB_PROGRAM_ID = (select FAL_JOB_PROGRAM_ID
                                        from FAL_ORDER
                                       where FAL_ORDER_ID = aFalOrderId) );
  end;

  /**
  * Procedure DeleteProgram
  * Description
  *   Suppression d'un programme de fabrication (s'il ne poss�de plus de lots non planifi�s)
  * @author ECA
  * @public
  * @param     aFAL_JOB_PROGRAM_ID   Id de l'ordre
  * @return    True si l'ordre � pu �tre supprim�
  */
  function DeleteProgram(aFAL_JOB_PROGRAM_ID number)
    return boolean
  is
    NbLots integer;
  begin
    select count(*)
      into NbLots
      from FAL_LOT LOT
         , FAL_ORDER ORD
     where LOT.FAL_ORDER_ID = ORD.FAL_ORDER_ID
       and ORD.FAL_JOB_PROGRAM_ID = aFAL_JOB_PROGRAM_ID
       and LOT.C_LOT_STATUS <> 1;

    if NbLots = 0 then
      delete from FAL_JOB_PROGRAM
            where FAL_JOB_PROGRAM_ID = aFAL_JOB_PROGRAM_ID;

      return true;
    else
      return false;
    end if;
  exception
    when others then
      return false;
  end;

  /**
  * Procedure DeleteOrderCascade
  * Description
  *   Suppression d'un programme de fabrication et des ordres qu'il comporte
  * @author CLE
  * @public
  * @param     aFalJobProgramId   Id du programme
  */
  procedure DeleteProgramCascade(aFalJobProgramId number, aErrorCode in out varchar2)
  is
    cursor crOrders
    is
      select fal_order_id
        from fal_order
       where fal_job_program_id = aFalJobProgramId;

    blnDeleted boolean;
  begin
    for tplOrders in crOrders loop
      FAL_ORDER_FUNCTIONS.DeleteOrderCascade(tplOrders.FAL_ORDER_ID, aErrorCode);
    end loop;

    blnDeleted  := DeleteProgram(aFalJobProgramId);
  exception
    when FAL_BATCH_FUNCTIONS.excNotPlannedBatch then
      aErrorCode  := 'excNotPlannedBatch';
    when FAL_BATCH_FUNCTIONS.excUsedInTracablity then
      aErrorCode  := 'excUsedInTracablity';
    when FAL_BATCH_FUNCTIONS.excUnknownBatch then
      aErrorCode  := 'excUnknownBatch';
    when others then
      raise;
  end;
end FAL_PROGRAM_FUNCTIONS;
