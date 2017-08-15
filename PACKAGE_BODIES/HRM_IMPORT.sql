--------------------------------------------------------
--  DDL for Package Body HRM_IMPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_IMPORT" 
as
  type tt_element_code is table of hrm_import_log.iml_elem_code%type
    index by binary_integer;

  type tt_employee_code is table of hrm_import_log.iml_emp_code%type
    index by binary_integer;

  type tt_value is table of hrm_import_log.iml_value%type
    index by binary_integer;

  type tt_date is table of date /*hrm_import_log.iml_value_from%TYPE */
    index by binary_integer;

  type tt_array_detail is table of hrm_array_detail%rowtype
    index by binary_integer;

  type tt_pc_taxsource is table of PCS.PC_TAXSOURCE%rowtype
    index by binary_integer;

--
-- Private methods
--

  /**
 * Mise à jour du statut validé et du nombre d'erreur de validation
 * @param in_import_doc  Identifiant du document importé.
 */
  procedure p_updateValidationError(in_import_doc in hrm_import_doc.hrm_import_doc_id%type)
  is
  begin
    -- Mise à jour du nombre d'erreurs dans l'en-tête
    update HRM_IMPORT_DOC
       set IMD_VAL_ERROR_NUM = (select count(IML_IMP_ERROR_CODE)
                                  from HRM_IMPORT_LOG
                                 where HRM_IMPORT_DOC_ID = in_import_doc)
         , IMD_VALIDATED = 1
     where HRM_IMPORT_DOC_ID = in_import_doc;
  end;

/**
 * Extraction d'une partie de ligne, avec éparateur et position relative.
 * Exemple: p_substr('AEBI; 56.25; 01.01.2008', ';', 2) => 56.25
 * @param Line  Ligne
 * @param Sep  Caractère de séparation
 * @param Pos  Position dans la ligne
 * @return le texte extrait.
 */
  function p_substr(iv_line in varchar2, iv_sep in char, in_pos in binary_integer)
    return varchar2
  is
    ln_begin binary_integer;
  begin
    ln_begin  := instr(iv_line, iv_sep, 1, in_pos) + 1;
    return trim(substr(iv_line, ln_begin, instr(iv_line, iv_sep, ln_begin) - ln_begin) );
  end;

/**
 * Suppression des imporations invalides ne contenant pas de liaison
 * sur une document d'importation.
 */
  procedure p_remove_invalid_import
  is
    pragma autonomous_transaction;
  begin
    delete      HRM_IMPORT_LOG
          where HRM_IMPORT_DOC_ID is null;

    commit;
  end;

/**
 * Prochain identifiant document d'importation.
 * @return l'identifiant du prochain document d'importation à utiliser.
 */
  function p_next_document_id
    return hrm_import_doc.hrm_import_doc_id%type
  is
    ln_result hrm_import_doc.hrm_import_doc_id%type;
  begin
    -- searches the last used doc number plus one
    select nvl(max(HRM_IMPORT_DOC_ID), 0) + 1
      into ln_result
      from HRM_IMPORT_DOC;

    return ln_result;
  end;

/**
 * creates an import document header so that all transferred records
 * can be easily found (objective is to be able to delete a complete
 * document)
 */
  function p_CreateDocument(in_import_data in pcs.pc_import_data.pc_import_data_id%type, iv_transfer_name in varchar2)
    return hrm_import_doc.hrm_import_doc_id%type
  is
    ln_result hrm_import_doc.hrm_import_doc_id%type;
  begin
    -- searches the last used doc number plus one
    ln_result  := p_next_document_id();

    -- insert a new import document whose number will be used to update
    -- each imported line
    insert into HRM_IMPORT_DOC
                (HRM_IMPORT_DOC_ID
               , PC_IMPORT_DATA_ID
               , IMD_DESCR
               , IMD_VALIDATED
               , A_DATECRE
               , A_IDCRE
                )
         values (ln_result
               , in_import_data
               , iv_transfer_name
               , 1
               , sysdate
               , 'IMP'
                );

    return ln_result;
  end;

/**
 * if doc is sucessfully created we affect all imports with given structureId to Doc
 */
  procedure p_AffectAllImportToDoc(in_import_doc in hrm_import_doc.hrm_import_doc_id%type, in_import_data in pcs.pc_import_data.pc_import_data_id%type)
  is
  begin
    update HRM_IMPORT_LOG
       set HRM_IMPORT_DOC_ID = in_import_doc
     where PC_IMPORT_DATA_ID = in_import_data
       and HRM_IMPORT_DOC_ID is null;
  end;

--
-- Public methods
--
  function getIdFromName(importName in varchar2)
    return number
  is
    ln_result number;
  begin
    select PC_IMPORT_DATA_ID
      into ln_result
      from PCS.PC_IMPORT_DATA
     where IMD_IMPORT_NAME = importName;

    return ln_result;
  exception
    when no_data_found then
      return 0.0;
  end;

  procedure StandardValidate(transferDate in date, transferName in varchar2, structureId in pcs.pc_import_data.pc_import_data_id%type)
  is
    cursor csValidate(in_import_data in pcs.pc_import_data.pc_import_data_id%type, in_import_doc in hrm_import_doc.hrm_import_doc_id%type)
    is
      select I.HRM_IMPORT_LOG_ID
           , IE.HRM_ELEMENTS_ID
           , IE.EIM_TRANSFER_MODE
           , IP.HRM_PERSON_ID
           , decode(upper(F.HRM_ELEMENTS_PREFIXES_ID), 'EM', 1, 0) IS_ELEMENT
        from HRM_ELEMENTS_FAMILY F
           , HRM_ELEMENTS_IMPORT_CODE IE
           , HRM_PERSON_IMPORT_CODE IP
           , HRM_IMPORT_LOG I
       where F.HRM_ELEMENTS_ID(+) = IE.HRM_ELEMENTS_ID
         and IE.PC_IMPORT_DATA_ID(+) = in_import_data
         and IP.PC_IMPORT_DATA_ID(+) = in_import_data
         and IE.EIM_IMPORT_CODE(+) = I.IML_ELEM_CODE
         and IP.PIM_IMPORT_CODE(+) = I.IML_EMP_CODE
         and I.HRM_IMPORT_DOC_ID = in_import_doc
         and I.IML_TRANSFERRED = 0;

    ltValidate csValidate%rowtype;
    DocId      hrm_import_doc.hrm_import_doc_id%type;
    errorNb    integer                                 := 0;
    errorCode  integer;
  begin
    -- we start to create a document header
    DocId  := p_CreateDocument(structureId, transferName);
    p_AffectAllImportToDoc(DocId, structureId);

    open csValidate(structureId, docId);

    loop
      fetch csValidate
       into ltValidate;

      -- we test if we have some more records, if we d'ont we exit from the loop
      exit when csValidate%notfound;
      errorCode  := 0;

      -- we put an error code if no element is found
      if ltValidate.hrm_elements_id is null then
        ErrorCode  := ErrorCode + 1;
      end if;

      -- we put an error code if no person is found
      if ltValidate.hrm_person_id is null then
        ErrorCode  := ErrorCode + 2;
      end if;

      -- we update the corresponding import log record
      update HRM_IMPORT_LOG
         set HRM_ELEMENTS_ID = ltValidate.HRM_ELEMENTS_ID
           , HRM_EMPLOYEE_ID = ltValidate.HRM_PERSON_ID
           , IML_TRANSFER_CODE = nvl(ltValidate.EIM_TRANSFER_MODE, 1)
           , IML_IMP_ERROR_CODE = case
                                   when errorCode <> 0 then errorCode
                                   else null
                                 end
           , IML_IS_VAR = ltValidate.IS_ELEMENT
       where HRM_IMPORT_LOG_ID = ltValidate.HRM_IMPORT_LOG_ID;

      if (errorCode > 0) then
        errorNb  := errorNb + 1;
      end if;
    end loop;

    close csValidate;

    -- if we have errors we update the document with import error number
    if (errorNb > 0) then
      update HRM_IMPORT_DOC
         set IMD_VAL_ERROR_NUM = errorNb
       where HRM_IMPORT_DOC_ID = docId;
    end if;

    commit;
  exception
    when others then
      rollback;
      -- we cancel all pending imported lines which have a null doc id because we have already
      -- rolled back
      p_remove_invalid_import();
      raise;
  end StandardValidate;

  procedure StandardTransfer(docId in hrm_import_doc.hrm_import_doc_id%type)
  is
    -- cursor cs is based on a view wich return all import records that have no
    -- import errors and are'nt yet transferred (ie 0)
    cursor csTransfer(in_import_doc in hrm_import_doc.hrm_import_doc_id%type)
    is
      select 1 isVar
           , B.HRM_IMPORT_LOG_ID importId
           , D.HRM_EMPLOYEE_ELEMENTS_ID empelemId
           , B.HRM_EMPLOYEE_ID empId
           , B.HRM_ELEMENTS_ID originId
           ,
             -- Pour les variables mettre la valeur dans les 2 colonnes string et numérique
             to_char(B.IML_VALUE) elemValue
           , B.IML_VALUE elemNumValue
           , decode(C.ELE_FORMAT, 1, to_char(D.EMP_NUM_VALUE), D.EMP_VALUE) oldValue
           , C.ELE_VALID_FROM beginDate
           , C.ELE_VALID_TO endDate
           , nvl(B.IML_VALUE_FROM, hrm_date.ActivePeriod) valueFrom
           , D.EMP_VALUE_FROM oldValueFrom
           , nvl(B.IML_VALUE_TO, hrm_date.ActivePeriodEndDate) valueTo
           , D.EMP_VALUE_TO oldValueTo
           , B.IML_TRANSFER_CODE transferMode
           , B.PC_IMPORT_DATA_ID structId
        from HRM_IMPORT_LOG B
           , HRM_ELEMENTS C
           , HRM_EMPLOYEE_ELEMENTS D
       where B.HRM_IMPORT_DOC_ID = in_import_doc
         and B.IML_TRANSFERRED = 0
         and B.IML_IMP_ERROR_CODE is null
         and B.HRM_ELEMENTS_ID = C.HRM_ELEMENTS_ID
         and (    D.HRM_EMPLOYEE_ID(+) = B.HRM_EMPLOYEE_ID
              and D.HRM_ELEMENTS_ID(+) = B.HRM_ELEMENTS_ID)
         and (    B.IML_VALUE_FROM <= D.EMP_VALUE_TO(+)
              and B.IML_VALUE_TO >= D.EMP_VALUE_FROM(+))
      union all
      select 0
           , B.HRM_IMPORT_LOG_ID
           , D.HRM_EMPLOYEE_CONST_ID
           , B.HRM_EMPLOYEE_ID
           , B.HRM_ELEMENTS_ID
           ,
             -- Pour les constantes mettre les montants dans la colonne numérique,
             -- les autres valeurs dans la colonne string (ex.: codes libres)
             decode(C.C_HRM_SAL_CONST_TYPE, 3, null, to_char(B.IML_VALUE) ) elemValue
           , decode(C.C_HRM_SAL_CONST_TYPE, 3, B.IML_VALUE, null) elemNumValue
           , decode(C.C_HRM_SAL_CONST_TYPE, 3, to_char(D.EMC_NUM_VALUE), D.EMC_VALUE) oldValue
           , C.CON_FROM
           , C.CON_TO
           , nvl(B.IML_VALUE_FROM, hrm_date.ActivePeriod)
           , D.EMC_VALUE_FROM
           , nvl(B.IML_VALUE_TO, hrm_date.ActivePeriodEndDate)
           , D.EMC_VALUE_TO
           , B.IML_TRANSFER_CODE
           , B.PC_IMPORT_DATA_ID
        from hrm_import_log b
           , hrm_constants c
           , hrm_employee_const d
       where B.HRM_IMPORT_DOC_ID = in_import_doc
         and B.IML_TRANSFERRED = 0
         and B.IML_IMP_ERROR_CODE is null
         and B.HRM_ELEMENTS_ID = C.HRM_CONSTANTS_ID
         and (    D.HRM_EMPLOYEE_ID(+) = B.HRM_EMPLOYEE_ID
              and D.HRM_CONSTANTS_ID(+) = B.HRM_ELEMENTS_ID)
         and (    B.IML_VALUE_FROM <= D.EMC_VALUE_TO(+)
              and B.IML_VALUE_TO >= D.EMC_VALUE_FROM(+));

    ltTransfer csTransfer%rowtype;
    empElemId  number;
    errorNb    integer              := 0;
    errorCode  integer;
    updateMode integer;

    procedure insertEmployeeElement
    is
    begin
      empElemId   := init_id_seq.nextval;

      insert into HRM_EMPLOYEE_ELEMENTS
                  (HRM_EMPLOYEE_ELEMENTS_ID
                 , HRM_EMPLOYEE_ID
                 , HRM_ELEMENTS_ID
                 , EMP_VALUE
                 , EMP_NUM_VALUE
                 , EMP_FROM
                 , EMP_TO
                 , EMP_VALUE_FROM
                 , EMP_VALUE_TO
                 , EMP_ACTIVE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (EmpElemId
                 , ltTransfer.EmpId
                 , ltTransfer.OriginId
                 , ltTransfer.ElemValue
                 , ltTransfer.ElemNumValue
                 , ltTransfer.beginDate
                 , ltTransfer.endDate
                 , ltTransfer.ValueFrom
                 , ltTransfer.ValueTo
                 , 1
                 , sysdate
                 , 'IMP'
                  );

      -- we store the fact that we inserted the record for further rollback
      updateMode  := 1;
--     exception
--       when NO_DATA_FOUND then
--         errorCode := 10; -- No init_id_seq.curval
    end;

    procedure insertEmployeeConstant
    is
    begin
      empElemId   := init_id_seq.nextval;

      insert into HRM_EMPLOYEE_CONST
                  (HRM_EMPLOYEE_CONST_ID
                 , HRM_EMPLOYEE_ID
                 , HRM_CONSTANTS_ID
                 , EMC_VALUE
                 , EMC_NUM_VALUE
                 , EMC_FROM
                 , EMC_TO
                 , EMC_VALUE_FROM
                 , EMC_VALUE_TO
                 , EMC_ACTIVE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (EmpElemId
                 , ltTransfer.EmpId
                 , ltTransfer.OriginId
                 , ltTransfer.ElemValue
                 , ltTransfer.ElemNumValue
                 , ltTransfer.beginDate
                 , ltTransfer.endDate
                 , ltTransfer.ValueFrom
                 , ltTransfer.ValueTo
                 , 1
                 , sysdate
                 , 'IMP'
                  );

      -- we store the fact that we inserted the record for further rollback
      updateMode  := 1;
--     exception
--       when NO_DATA_FOUND then
--         errorCode := 10; -- No init_id_seq.curval
    end;

    -- updates employee elements testing if we have to override
    -- (ie transferMode =1) or Sum (ie transferMode =2)
    -- the values. If transferMode is alarm (ie 3) we will generate an
    -- error code. Error sescriptions can be found in table
    -- Dic_imp_Transfer_errors
    procedure updateEmployeeElement
    is
    begin
      case ltTransfer.transferMode
        when 1 then
          update HRM_EMPLOYEE_ELEMENTS
             set EMP_VALUE = ltTransfer.ElemValue
               , EMP_NUM_VALUE = ltTransfer.ElemNumValue
               , A_DATEMOD = sysdate
               , A_IDMOD = 'IMP'
           where HRM_EMPLOYEE_ELEMENTS_ID = ltTransfer.EmpElemId;

          -- we store the fact that we updated the record for further rollback
          updateMode  := 2;
        when 2 then
          update HRM_EMPLOYEE_ELEMENTS
             set EMP_NUM_VALUE = emp_num_value + ltTransfer.ElemNumValue
               , EMP_VALUE = to_char(emp_num_value + ltTransfer.ElemNumValue)
               , A_DATEMOD = sysdate
               , A_IDMOD = 'IMP'
           where HRM_EMPLOYEE_ELEMENTS_ID = ltTransfer.EmpElemId;

          -- we store the fact that we updated the record for further rollback
          updateMode  := 2;
        else
          errorCode  := 11;   -- Variable already exist for this employee
          errorNb    := errorNb + 1;
      end case;

      -- we store actual record id for further update
      EmpElemId  := ltTransfer.EmpElemId;
    exception
      when no_data_found then
        errorCode  := 12;   -- error updating hrm_employee_elements record
    end;

    -- updates employee constants testing if we have to override
    -- (ie transferMode =1) or Sum (ie transferMode =2)
    -- the values. If transferMode is alarm (ie 3) we will generate an
    -- error code. Error sescriptions can be found in table
    -- Dic_imp_Transfer_errors
    procedure updateEmployeeConstant
    is
    begin
      case ltTransfer.transferMode
        when 1 then
          update HRM_EMPLOYEE_CONST
             set EMC_VALUE = ltTransfer.ElemValue
               , EMC_NUM_VALUE = ltTransfer.ElemNumValue
               , A_DATEMOD = sysdate
               , A_IDMOD = 'IMP'
           where HRM_EMPLOYEE_CONST_ID = ltTransfer.EmpElemId;

          -- we store the fact that we updated the record for further rollback
          updateMode  := 2;
        when 2 then
          update HRM_EMPLOYEE_CONST
             set EMC_VALUE = to_char(to_number(emc_value) + to_number(ltTransfer.ElemValue) )
               , EMC_NUM_VALUE = emc_num_value + ltTransfer.ElemNumValue
               , A_DATEMOD = sysdate
               , A_IDMOD = 'IMP'
           where HRM_EMPLOYEE_CONST_ID = ltTransfer.EmpElemId;

          -- we store the fact that we updated the record for further rollback
          updateMode  := 2;
        else
          errorCode  := 13;   -- Constant already exist for this employee
          errorNb    := errorNb + 1;
      end case;

      -- we store actual record id for further update
      EmpElemId  := ltTransfer.EmpElemId;
    exception
      when no_data_found then
        errorCode  := 14;   -- error updating hrm_employee_const record
    end;

    -- updates hrm_import_log with error_code if any, element or constant id
    -- that was either inserted or updated, document id and status tranferred
    procedure updateImportLog
    is
    begin
      update HRM_IMPORT_LOG
         set IML_TRA_ERROR_CODE = case
                                   when errorCode <> 0 then errorCode
                                   else null
                                 end
           , HRM_EMPL_ELEMENTS_ID = case
                                     when EmpElemId <> 0.0 then EmpElemId
                                     else null
                                   end
           , IML_TRANSFERRED = 1
           , HRM_IMPORT_DOC_ID = docId
           , IML_OLD_VALUE = ltTransfer.oldValue
           , IML_OLD_VALUE_FROM = ltTransfer.oldValueFrom
           , IML_OLD_VALUE_TO = ltTransfer.oldValueTo
           , IML_TRANSFER_DATE = sysdate
           , IML_UPDATE_MODE = updateMode
       where HRM_IMPORT_LOG_ID = ltTransfer.importId;
    end;
  begin
    open csTransfer(docId);

    loop
      fetch csTransfer
       into ltTransfer;

      -- we test if we have some more records, if we d'ont we exit from the loop
      exit when csTransfer%notfound;
      errorCode   := 0;
      EmpElemId   := 0;
      updateMode  := 0;

      -- if an empElemid does not erxist it means that we have not found
      -- any variable or constant for that employee having the same validty date
      -- so we test for variable or constante and insert one
      if ltTransfer.EmpElemId is null then
        if (ltTransfer.IsVar = 1) then
          InsertEmployeeElement;
        else
          InsertEmployeeConstant;
        end if;
      -- if we found an empElemid we have a variable or a constant for an employee
      -- and we've got to update either variables or contants
      else
        if (ltTransfer.IsVar = 1) then
          updateEmployeeElement;
        else
          updateEmployeeConstant;
        end if;
      end if;

        -- we udate hrm_import_log with variable or constant id or an error_code
      -- if one and by the way we update the transfer date, the transfer doc and
      -- the boolean transfer flag even if we have an errror
      UpdateImportLog;

      update HRM_IMPORT_DOC
         set IMD_TRA_ERROR_NUM = errorNb
           , IMD_TRANSFER_DATE = sysdate
           , IMD_TRANSFERRED = 1
       where HRM_IMPORT_DOC_ID = docId;
    end loop;

    close csTransfer;

    commit;
  exception
    when others then
      -- if an error is raised we rollback
      rollback;
      raise;
  end StandardTransfer;

  procedure StandardGroupedTransfer(docId in hrm_import_doc.hrm_import_doc_id%type)
  is
    -- cursor cs is based on a view wich return all import records that have no
    -- import errors and are'nt yet transferred (ie 0)
    cursor csTransfer(in_import_doc in hrm_import_doc.hrm_import_doc_id%type)
    is
      select   1 isVar
             , min(B.HRM_IMPORT_LOG_ID) importId
             , min(D.HRM_EMPLOYEE_ELEMENTS_ID) empelemId
             , B.HRM_EMPLOYEE_ID empId
             , B.HRM_ELEMENTS_ID originId
             , to_char(sum(B.IML_VALUE) ) elemValue
             , sum(B.IML_VALUE) elemNumValue
             , decode(C.ELE_FORMAT, 1, to_char(min(D.EMP_NUM_VALUE) ), min(D.EMP_VALUE) ) oldValue
             , min(C.ELE_VALID_FROM) beginDate
             , max(C.ELE_VALID_TO) endDate
             , nvl(min(B.IML_VALUE_FROM), hrm_date.ActivePeriod) valueFrom
             , min(D.EMP_VALUE_FROM) oldValueFrom
             , nvl(max(B.IML_VALUE_TO), hrm_date.ActivePeriodEndDate) valueTo
             , max(D.EMP_VALUE_TO) oldValueTo
             , min(B.IML_TRANSFER_CODE) transferMode
             , min(B.PC_IMPORT_DATA_ID) structId
             , count(*) nbRows
          from HRM_IMPORT_LOG B
             , HRM_ELEMENTS C
             , HRM_EMPLOYEE_ELEMENTS D
         where B.HRM_IMPORT_DOC_ID = in_import_doc
           and B.IML_TRANSFERRED = 0
           and B.IML_IMP_ERROR_CODE is null
           and B.HRM_ELEMENTS_ID = C.HRM_ELEMENTS_ID
           and (    D.HRM_EMPLOYEE_ID(+) = B.HRM_EMPLOYEE_ID
                and D.HRM_ELEMENTS_ID(+) = B.HRM_ELEMENTS_ID)
           and (    B.IML_VALUE_FROM <= D.EMP_VALUE_TO(+)
                and B.IML_VALUE_TO >= D.EMP_VALUE_FROM(+))
      group by B.HRM_EMPLOYEE_ID
             , B.HRM_ELEMENTS_ID
             , C.ELE_FORMAT
      union all
      select   0
             , min(B.HRM_IMPORT_LOG_ID) importId
             , min(D.HRM_EMPLOYEE_CONST_ID) empelemId
             , B.HRM_EMPLOYEE_ID empId
             , B.HRM_ELEMENTS_ID originId
             , decode(C.C_HRM_SAL_CONST_TYPE, 3, null, to_char(sum(B.IML_VALUE) ) ) elemValue
             , decode(C.C_HRM_SAL_CONST_TYPE, 3, sum(B.IML_VALUE), null) elemNumValue
             , decode(C.C_HRM_SAL_CONST_TYPE, 3, to_char(min(D.EMC_NUM_VALUE) ), min(D.EMC_VALUE) ) oldValue
             , min(C.CON_FROM) beginDate
             , max(C.CON_TO) endDate
             , nvl(min(B.IML_VALUE_FROM), hrm_date.ActivePeriod) valueFrom
             , min(D.EMC_VALUE_FROM) oldValueFrom
             , nvl(max(B.IML_VALUE_TO), hrm_date.ActivePeriodEndDate) valueTo
             , max(D.EMC_VALUE_TO) oldValueTo
             , min(B.IML_TRANSFER_CODE) transferMode
             , min(B.PC_IMPORT_DATA_ID) structId
             , count(*) nbRows
          from HRM_IMPORT_LOG B
             , HRM_CONSTANTS C
             , HRM_EMPLOYEE_CONST D
         where B.HRM_IMPORT_DOC_ID = in_import_doc
           and B.IML_TRANSFERRED = 0
           and B.IML_IMP_ERROR_CODE is null
           and B.HRM_ELEMENTS_ID = C.HRM_CONSTANTS_ID
           and (    D.HRM_EMPLOYEE_ID(+) = B.HRM_EMPLOYEE_ID
                and D.HRM_CONSTANTS_ID(+) = B.HRM_ELEMENTS_ID)
           and (    B.IML_VALUE_FROM <= D.EMC_VALUE_TO(+)
                and B.IML_VALUE_TO >= D.EMC_VALUE_FROM(+))
      group by B.HRM_EMPLOYEE_ID
             , B.HRM_ELEMENTS_ID
             , C.C_HRM_SAL_CONST_TYPE;

    ltTransfer csTransfer%rowtype;
    empElemId  number;
    errorNb    integer              := 0;
    errorCode  integer;
    updateMode integer;

    procedure insertEmployeeElement
    is
    begin
      EmpElemId   := init_id_seq.nextval;

      insert into HRM_EMPLOYEE_ELEMENTS
                  (HRM_EMPLOYEE_ELEMENTS_ID
                 , HRM_EMPLOYEE_ID
                 , HRM_ELEMENTS_ID
                 , EMP_VALUE
                 , EMP_NUM_VALUE
                 , EMP_FROM
                 , EMP_TO
                 , EMP_VALUE_FROM
                 , EMP_VALUE_TO
                 , EMP_ACTIVE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (EmpElemId
                 , ltTransfer.EmpId
                 , ltTransfer.OriginId
                 , ltTransfer.ElemValue
                 , ltTransfer.ElemNumValue
                 , ltTransfer.beginDate
                 , ltTransfer.endDate
                 , ltTransfer.ValueFrom
                 , ltTransfer.ValueTo
                 , 1
                 , sysdate
                 , 'IMP'
                  );

      -- we store the fact that we inserted the record for further rollback
      updateMode  := 1;
--     exception
--       when NO_DATA_FOUND then
--         errorCode := 10; -- No init_id_seq.curval
    end;

    procedure insertEmployeeConstant
    is
    begin
      EmpElemId   := init_id_seq.nextval;

      insert into HRM_EMPLOYEE_CONST
                  (HRM_EMPLOYEE_CONST_ID
                 , HRM_EMPLOYEE_ID
                 , HRM_CONSTANTS_ID
                 , EMC_VALUE
                 , EMC_NUM_VALUE
                 , EMC_FROM
                 , EMC_TO
                 , EMC_VALUE_FROM
                 , EMC_VALUE_TO
                 , EMC_ACTIVE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (EmpElemId
                 , ltTransfer.EmpId
                 , ltTransfer.OriginId
                 , ltTransfer.ElemValue
                 , ltTransfer.ElemNumValue
                 , ltTransfer.beginDate
                 , ltTransfer.endDate
                 , ltTransfer.ValueFrom
                 , ltTransfer.ValueTo
                 , 1
                 , sysdate
                 , 'IMP'
                  );

      -- we store the fact that we inserted the record for further rollback
      updateMode  := 1;
--     exception
--       when NO_DATA_FOUND then
--         errorCode := 10; -- No init_id_seq.curval
    end;

    -- updates employee elements testing if we have to override
    -- (ie transferMode =1) or Sum (ie transferMode =2)
    -- the values. If transferMode is alarm (ie 3) we will generate an
    -- error code. Error sescriptions can be found in table
    -- Dic_imp_Transfer_errors
    procedure updateEmployeeElement(id in hrm_employee_elements.hrm_employee_elements_id%type)
    is
    begin
      case ltTransfer.transferMode
        when 1 then
          update HRM_EMPLOYEE_ELEMENTS
             set EMP_VALUE = ltTransfer.ElemValue
               , EMP_NUM_VALUE = ltTransfer.ElemNumValue
               , A_DATEMOD = sysdate
               , A_IDMOD = 'IMP'
           where HRM_EMPLOYEE_ELEMENTS_ID = id;

          -- we store the fact that we updated the record for further rollback
          updateMode  := 2;
        when 2 then
          update HRM_EMPLOYEE_ELEMENTS
             set EMP_VALUE = to_char(emp_num_value + ltTransfer.ElemNumValue)
               , EMP_NUM_VALUE = emp_num_value + ltTransfer.ElemNumValue
               , A_DATEMOD = sysdate
               , A_IDMOD = 'IMP'
           where HRM_EMPLOYEE_ELEMENTS_ID = id;

          -- we store the fact that we updated the record for further rollback
          updateMode  := 2;
        else
          errorCode  := 11;   -- Variable already exist for this employee
          errorNb    := errorNb + 1;
      end case;

      -- we store actual record id for further update
      EmpElemId  := id;
    exception
      when no_data_found then
        errorCode  := 12;   -- error updating hrm_employee_elements record
    end;

    -- updates employee constants testing if we have to override
    -- (ie transferMode =1) or Sum (ie transferMode =2)
    -- the values. If transferMode is alarm (ie 3) we will generate an
    -- error code. Error sescriptions can be found in table
    -- Dic_imp_Transfer_errors
    procedure updateEmployeeConstant(id in hrm_employee_const.hrm_employee_const_id%type)
    is
    begin
      case ltTransfer.transferMode
        when 1 then
          update HRM_EMPLOYEE_CONST
             set EMC_VALUE = ltTransfer.ElemValue
               , EMC_NUM_VALUE = ltTransfer.ElemNumValue
               , A_DATEMOD = sysdate
               , A_IDMOD = 'IMP'
           where HRM_EMPLOYEE_CONST_ID = id;

          -- we store the fact that we updated the record for further rollback
          updateMode  := 2;
        when 2 then
          update HRM_EMPLOYEE_CONST
             set EMC_VALUE = to_char(to_number(emc_value) + to_number(ltTransfer.ElemValue) )
               , EMC_NUM_VALUE = emc_num_value + ltTransfer.ElemNumValue
               , A_DATEMOD = sysdate
               , A_IDMOD = 'IMP'
           where HRM_EMPLOYEE_CONST_ID = id;

          -- we store the fact that we updated the record for further rollback
          updateMode  := 2;
        else
          errorCode  := 13;   -- Constant already exist for this employee
          errorNb    := errorNb + 1;
      end case;

      -- we store actual record id for further update
      EmpElemId  := id;
    exception
      when no_data_found then
        errorCode  := 14;   -- error updating hrm_employee_const record
    end;

    -- updates hrm_import_log with error_code if any, element or constant id
    -- that was either inserted or updated, document id and status tranferred
    procedure updateImportLog
    is
    begin
      update HRM_IMPORT_LOG
         set IML_TRA_ERROR_CODE = case
                                   when errorCode <> 0 then errorCode
                                   else null
                                 end
           , HRM_EMPL_ELEMENTS_ID = case
                                     when EmpElemId <> 0.0 then EmpElemId
                                     else null
                                   end
           , IML_TRANSFERRED = 1
           , HRM_IMPORT_DOC_ID = docId
           , IML_OLD_VALUE = ltTransfer.oldValue
           , IML_OLD_VALUE_FROM = ltTransfer.oldValueFrom
           , IML_OLD_VALUE_TO = ltTransfer.oldValueTo
           , IML_TRANSFER_DATE = sysdate
           , IML_UPDATE_MODE = updateMode
       where HRM_IMPORT_LOG_ID = ltTransfer.importId;

      if (ltTransfer.nbRows > 1) then
        update HRM_IMPORT_LOG
           set IML_TRA_ERROR_CODE = case
                                     when errorCode <> 0 then errorCode
                                     else null
                                   end
             , HRM_EMPL_ELEMENTS_ID = case
                                       when EmpElemId <> 0.0 then EmpElemId
                                       else null
                                     end
             , IML_TRANSFERRED = 1
             , HRM_IMPORT_DOC_ID = docId
             , IML_OLD_VALUE = ltTransfer.oldValue
             , IML_OLD_VALUE_FROM = ltTransfer.oldValueFrom
             , IML_OLD_VALUE_TO = ltTransfer.oldValueTo
             , IML_TRANSFER_DATE = sysdate
             , IML_UPDATE_MODE = 0
         where HRM_IMPORT_DOC_ID = docId
           and HRM_EMPLOYEE_ID = ltTransfer.empId
           and HRM_ELEMENTS_ID = ltTransfer.originId
           and HRM_IMPORT_LOG_ID <> ltTransfer.importId;
      end if;
    end;
  begin
    open csTransfer(docId);

    loop
      fetch csTransfer
       into ltTransfer;

      -- we test if we have some more records, if we d'ont we exit from the loop
      exit when csTransfer%notfound;
      errorCode   := 0;
      updateMode  := 0;
      EmpElemId   := 0;

      -- if an empElemid does not erxist it means that we have not found
      -- any variable or constant for that employee having the same validty date
      -- so we test for variable or constante and insert one
      if ltTransfer.EmpElemId is null then
        if (ltTransfer.IsVar = 1) then
          InsertEmployeeElement;
        else
          InsertEmployeeConstant;
        end if;
      -- if we found an empElemid we have a variable or a constant for an employee
      -- and we've got to update either variables or contants
      else
        if (ltTransfer.IsVar = 1) then
          updateEmployeeElement(ltTransfer.empElemId);
        else
          updateEmployeeConstant(ltTransfer.empElemId);
        end if;
      end if;

      -- we udate hrm_import_log with variable or constant id or an error_code
      -- if one and by the way we update the transfer date, the transfer doc and
      -- the boolean transfer flag even if we have an errror
      UpdateImportLog;

      update HRM_IMPORT_DOC
         set IMD_TRA_ERROR_NUM = errorNb
           , IMD_TRANSFER_DATE = sysdate
           , IMD_TRANSFERRED = 1
       where HRM_IMPORT_DOC_ID = docId;
    end loop;

    close csTransfer;

    commit;
  exception
    when others then
      -- if an error is raised we rollback
      rollback;
      raise;
  end StandardGroupedTransfer;

  procedure StandardRollback(docId in hrm_import_doc.hrm_import_doc_id%type)
  is
    cursor csRollback(in_import_doc in hrm_import_doc.hrm_import_doc_id%type)
    is
      select i.*
           , decode(I.IML_IS_VAR, 1, I.IML_OLD_VALUE, decode(R.C_HRM_SAL_CONST_TYPE, 3, null, I.IML_OLD_VALUE) ) OldValue
           , decode(I.IML_IS_VAR, 1, to_number(IML_OLD_VALUE), decode(R.C_HRM_SAL_CONST_TYPE, 3, to_number(I.IML_OLD_VALUE), null) ) OldNumValue
        from HRM_ELEMENTS_ROOT R
           , HRM_ELEMENTS_FAMILY F
           , HRM_IMPORT_LOG I
       where F.HRM_ELEMENTS_ID = I.HRM_ELEMENTS_ID
         and R.HRM_ELEMENTS_ROOT_ID = F.HRM_ELEMENTS_ROOT_ID
         and I.IML_TRANSFERRED = 1
         and I.HRM_IMPORT_DOC_ID = in_import_doc;

    ltRollback csRollback%rowtype;

    procedure updateEmployeeElements
    is
    begin
      if ltRollback.iml_is_var = 0 then
        update HRM_EMPLOYEE_CONST
           set EMC_VALUE = ltRollback.OldValue
             , EMC_NUM_VALUE = ltRollback.OldNumValue
             , EMC_VALUE_FROM = ltRollback.iml_Old_value_from
             , EMC_VALUE_TO = ltRollback.iml_Old_value_to
             , A_DATEMOD = sysdate
             , A_IDMOD = 'IMP'
         where HRM_EMPLOYEE_CONST_ID = ltRollback.hrm_empl_elements_id;
      else
        update hrm_employee_elements
           set EMP_VALUE = ltRollback.OldValue
             , EMP_NUM_VALUE = ltRollback.OldNumValue
             , EMP_VALUE_FROM = ltRollback.iml_Old_value_from
             , EMP_VALUE_TO = ltRollback.iml_Old_value_to
             , A_DATEMOD = sysdate
             , A_IDMOD = 'IMP'
         where HRM_EMPLOYEE_ELEMENTS_ID = ltRollback.hrm_empl_elements_id;
      end if;
    end;

    procedure deleteEmployeeElements
    is
    begin
      if ltRollback.iml_is_var = 0 then
        delete      HRM_EMPLOYEE_CONST
              where HRM_EMPLOYEE_CONST_ID = ltRollback.hrm_empl_elements_id;
      else
        delete      HRM_EMPLOYEE_ELEMENTS
              where HRM_EMPLOYEE_ELEMENTS_ID = ltRollback.hrm_empl_elements_id;
      end if;
    end;
  begin
    open csRollback(docId);

    loop
      fetch csRollback
       into ltRollback;

      exit when csRollback%notfound;

      if (ltRollback.iml_update_mode = 2) then
        updateEmployeeElements;
      elsif(ltRollback.iml_update_mode = 1) then
        deleteEmployeeElements;
      end if;

      -- we update the corresponding import log record
      update HRM_IMPORT_LOG
         set HRM_EMPL_ELEMENTS_ID = null
           , IML_TRANSFERRED = 0
           , IML_TRANSFER_DATE = null
           , IML_OLD_VALUE = null
           , IML_OLD_VALUE_FROM = null
           , IML_OLD_VALUE_TO = null
       where HRM_IMPORT_LOG_ID = ltRollback.hrm_import_log_id;
    end loop;

    close csRollback;

    -- we update the document
    update HRM_IMPORT_DOC
       set IMD_TRA_ERROR_NUM = null
         , IMD_TRANSFER_DATE = null
         , IMD_TRANSFERRED = 0
     where HRM_IMPORT_DOC_ID = docId;

    commit;
  exception
    when others then
      -- if an error is raised we rollback
      rollback;
      raise;
  end StandardRollback;

  procedure TimeSoftValidate(transferDate in date, transferName in varchar2, StructureId in pcs.pc_import_data.pc_import_data_id%type)
  is
    cursor csValidate(in_import_data in pcs.pc_import_data.pc_import_data_id%type, in_import_doc in hrm_import_doc.hrm_import_doc_id%type)
    is
      select I.HRM_IMPORT_LOG_ID
           , IE.HRM_ELEMENTS_ID
           , IE.EIM_TRANSFER_MODE
           , P.HRM_PERSON_ID
           , decode(upper(F.HRM_ELEMENTS_PREFIXES_ID), 'EM', 1, 0) is_element
        from HRM_ELEMENTS_FAMILY F
           , HRM_ELEMENTS_IMPORT_CODE IE
           , HRM_PERSON P
           , HRM_IMPORT_LOG I
       where F.HRM_ELEMENTS_ID(+) = IE.HRM_ELEMENTS_ID
         and IE.PC_IMPORT_DATA_ID(+) = in_import_data
         and IE.EIM_IMPORT_CODE(+) = i.iml_elem_code
         and P.EMP_NUMBER(+) = i.iml_emp_code
         and I.HRM_IMPORT_DOC_ID = in_import_doc
         and I.IML_TRANSFERRED = 0;

    ltValidate csValidate%rowtype;
    DocId      hrm_import_doc.hrm_import_doc_id%type;
    errorCode  integer;
    errorNb    integer                                 := 0;
  begin
    -- we start to create a document header
    DocId  := p_CreateDocument(structureId, transferName);
    p_AffectAllImportToDoc(DocId, structureId);

    open csValidate(structureId, docId);

    loop
      fetch csValidate
       into ltValidate;

      -- we test if we have some more records, if we d'ont we exit from the loop
      exit when csValidate%notfound;
      errorCode  := 0;

      -- we put an error code if no element is found
      if ltValidate.hrm_elements_id is null then
        ErrorCode  := ErrorCode + 1;
      end if;

      -- we put an error code if no person is found
      if ltValidate.hrm_person_id is null then
        ErrorCode  := ErrorCode + 2;
      end if;

      -- we update the corresponding import log record
      update HRM_IMPORT_LOG
         set HRM_ELEMENTS_ID = ltValidate.HRM_ELEMENTS_ID
           , HRM_EMPLOYEE_ID = ltValidate.HRM_PERSON_ID
           , IML_TRANSFER_CODE = nvl(ltValidate.EIM_TRANSFER_MODE, 1)
           , IML_IMP_ERROR_CODE = case
                                   when errorCode <> 0 then errorCode
                                   else null
                                 end
           , IML_IS_VAR = ltValidate.IS_ELEMENT
       where HRM_IMPORT_LOG_ID = ltValidate.HRM_IMPORT_LOG_ID;

      if (errorCode > 0) then
        errorNb  := errorNb + 1;
      end if;
    end loop;

    close csValidate;

    -- if we have errors we update the document with import error number
    if (errorNb > 0) then
      update HRM_IMPORT_DOC
         set IMD_VAL_ERROR_NUM = errorNb
       where HRM_IMPORT_DOC_ID = docId;
    end if;

    commit;
  exception
    when others then
      rollback;
      -- we cancel all pending imported lines which have a null doc id because we have already
      -- rolled back
      p_remove_invalid_import();
      raise;
  end TimeSoftValidate;

  procedure TimeSoftTransfer(docId in hrm_import_doc.hrm_import_doc_id%type)
  is
  begin
    hrm_import.StandardTransfer(docId);
  end;

  procedure MOBValidate(transferDate in date, transferName in varchar2, structureId in pcs.pc_import_data.pc_import_data_id%type)
  is
    cursor csValidate(in_import_data in pcs.pc_import_data.pc_import_data_id%type, in_import_doc in hrm_import_doc.hrm_import_doc_id%type)
    is
      select A.HRM_IMPORT_LOG_ID
           , B.HRM_ELEMENTS_ID
           , C.HRM_PERSON_ID
           , 1 IS_ELEMENT
        from HRM_ELEMENTS_DESCR B
           , HRM_PERSON C
           , HRM_IMPORT_LOG A
       where C.EMP_NUMBER(+) = A.IML_EMP_CODE
         and B.ELE_SUBST_CODE(+) = A.IML_ELEM_CODE
         and B.PC_LANG_ID = 1
         and   -- langue à utiliser par défaut
             A.PC_IMPORT_DATA_ID = in_import_data
         and HRM_IMPORT_DOC_ID = in_import_doc
         and IML_TRANSFERRED = 0
      union all
      select A.HRM_IMPORT_LOG_ID
           , B.HRM_CONSTANTS_ID
           , C.HRM_PERSON_ID
           , 0
        from HRM_CONST_DESCR B
           , HRM_PERSON C
           , HRM_IMPORT_LOG A
       where C.EMP_NUMBER(+) = A.IML_EMP_CODE
         and B.CON_SUBST_CODE(+) = A.IML_ELEM_CODE
         and B.PC_LANG_ID = 1
         and   -- langue à utiliser par défaut
             A.PC_IMPORT_DATA_ID = in_import_data
         and HRM_IMPORT_DOC_ID = in_import_doc
         and IML_TRANSFERRED = 0;

    ltValidate csValidate%rowtype;
    DocId      hrm_import_doc.hrm_import_doc_id%type;
    errorCode  integer;
    errorNb    integer                                 := 0;
  begin
    -- we start to create a document header
    DocId  := p_CreateDocument(structureId, transferName);
    p_AffectAllImportToDoc(docId, structureId);

    open csValidate(structureId, docId);

    loop
      fetch csValidate
       into ltValidate;

      -- we test if we have some more records, if we d'ont we exit from the loop
      exit when csValidate%notfound;
      errorCode  := 0;

      -- we put an error code if no element is found
      if ltValidate.HRM_ELEMENTS_ID is null then
        ErrorCode  := ErrorCode + 1;
      end if;

      -- we put an error code if no person is found
      if ltValidate.HRM_PERSON_ID is null then
        ErrorCode  := ErrorCode + 2;
      end if;

      -- we update the corresponding import log record
      update HRM_IMPORT_LOG
         set HRM_ELEMENTS_ID = ltValidate.HRM_ELEMENTS_ID
           , HRM_EMPLOYEE_ID = ltValidate.HRM_PERSON_ID
           , IML_TRANSFER_CODE = 1
           , IML_IMP_ERROR_CODE = case
                                   when errorCode <> 0 then errorCode
                                   else null
                                 end
           , IML_IS_VAR = ltValidate.IS_ELEMENT
       where HRM_IMPORT_LOG_ID = ltValidate.HRM_IMPORT_LOG_ID;

      if (errorCode > 0) then
        errorNb  := errorNb + 1;
      end if;
    end loop;

    close csValidate;

    -- if we have errors we update the document with import error number
    if (errorNb > 0) then
      update HRM_IMPORT_DOC
         set IMD_VAL_ERROR_NUM = errorNb
       where HRM_IMPORT_DOC_ID = docId;
    end if;

    commit;
  exception
    when others then
      rollback;
      -- we cancel all pending imported lines which have a null doc id because we have already
      -- rolled back
      p_remove_invalid_import();
      raise;
  end MOBValidate;

  procedure TSAValidate(transferDate in date, transferName in varchar2, structureId in pcs.pc_import_data.pc_import_data_id%type)
  is
    cursor csValidate(in_import_data in pcs.pc_import_data.pc_import_data_id%type, in_import_doc in hrm_import_doc.hrm_import_doc_id%type)
    is
      select i.hrm_import_log_id
           , ie.hrm_elements_id
           , ie.eim_transfer_mode
           , p.hrm_person_id
           , decode(upper(f.hrm_elements_prefixes_id), 'EM', 1, 0) is_element
        from HRM_ELEMENTS_FAMILY F
           , HRM_ELEMENTS_IMPORT_CODE IE
           , HRM_PERSON P
           , HRM_IMPORT_LOG I
       where F.HRM_ELEMENTS_ID(+) = IE.HRM_ELEMENTS_ID
         and IE.PC_IMPORT_DATA_ID(+) = in_import_data
         and IE.EIM_IMPORT_CODE(+) = I.IML_ELEM_CODE
         and P.EMP_SECONDARY_KEY(+) = I.IML_EMP_CODE
         and I.HRM_IMPORT_DOC_ID = in_import_doc
         and I.IML_TRANSFERRED = 0;

    ltValidate csValidate%rowtype;
    DocId      hrm_import_doc.hrm_import_doc_id%type;
    errorCode  integer;
    errorNb    integer                                 := 0;
  begin
    -- we start to create a document header
    DocId  := p_CreateDocument(structureId, transferName);
    p_AffectAllImportToDoc(DocId, structureId);

    open csValidate(structureId, docId);

    loop
      fetch csValidate
       into ltValidate;

      -- we test if we have some more records, if we d'ont we exit from the loop
      exit when csValidate%notfound;
      errorCode  := 0;

      -- we put an error code if no element is found
      if ltValidate.hrm_elements_id is null then
        ErrorCode  := ErrorCode + 1;
      end if;

      -- we put an error code if no person is found
      if ltValidate.hrm_person_id is null then
        ErrorCode  := ErrorCode + 2;
      end if;

      -- we update the corresponding import log record
      update hrm_import_log
         set HRM_ELEMENTS_ID = ltValidate.hrm_elements_id
           , HRM_EMPLOYEE_ID = ltValidate.hrm_person_id
           , IML_TRANSFER_CODE = nvl(ltValidate.eim_Transfer_mode, 1)
           , IML_IMP_ERROR_CODE = case
                                   when errorCode <> 0 then errorCode
                                   else null
                                 end
           , IML_IS_VAR = ltValidate.is_element
       where HRM_IMPORT_LOG_ID = ltValidate.hrm_import_log_id;

      if (errorCode > 0) then
        errorNb  := errorNb + 1;
      end if;
    end loop;

    close csValidate;

    -- if we have errors we update the document with import error number
    if (errorNb > 0) then
      update HRM_IMPORT_DOC
         set IMD_VAL_ERROR_NUM = errorNb
       where HRM_IMPORT_DOC_ID = docId;
    end if;

    commit;
  exception
    when others then
      rollback;
      -- we cancel all pending imported lines which have a null doc id because we have already
      -- rolled back
      p_remove_invalid_import();
      raise;
  end TSAValidate;

  procedure CalitimeValidate(transferDate in date, transferName in varchar2, structureId in pcs.pc_import_data.pc_import_data_id%type)
  is
  begin
    hrm_import.TSAValidate(transferDate, transferName, structureId);
  end CalitimeValidate;

  procedure PresentoValidate(transferDate in date, transferName in varchar2, structureId in pcs.pc_import_data.pc_import_data_id%type)
  is
    cursor csValidate(in_import_doc in hrm_import_doc.hrm_import_doc_id%type)
    is
      select I.HRM_IMPORT_LOG_ID
           , E.ELEMID HRM_ELEMENTS_ID
           , P.HRM_PERSON_ID
           , decode(E.IS_ELEMENT, 'True', 1, 0) IS_ELEMENT
        from V_HRM_ELEMENTS_SHORT E
           , HRM_PERSON P
           , HRM_IMPORT_LOG I
       where E.CODE(+) = I.IML_ELEM_CODE
         and P.EMP_NUMBER(+) = I.IML_EMP_CODE
         and I.HRM_IMPORT_DOC_ID = in_import_doc
         and IML_TRANSFERRED = 0;

    ltValidate csValidate%rowtype;
    DocId      hrm_import_doc.hrm_import_doc_id%type;
    errorCode  integer;
    errorNb    integer                                 := 0;
  begin
    -- we start to create a document header
    DocId  := p_CreateDocument(structureId, transferName);
    p_AffectAllImportToDoc(DocId, structureId);

    open csValidate(docId);

    loop
      fetch csValidate
       into ltValidate;

      -- we test if we have some more records, if we d'ont we exit from the loop
      exit when csValidate%notfound;
      errorCode  := 0;

      -- we put an error code if no element is found
      if ltValidate.hrm_elements_id is null then
        ErrorCode  := ErrorCode + 1;
      end if;

      -- we put an error code if no person is found
      if ltValidate.hrm_person_id is null then
        ErrorCode  := ErrorCode + 2;
      end if;

      -- we update the corresponding import log record
      update HRM_IMPORT_LOG
         set HRM_ELEMENTS_ID = ltValidate.hrm_elements_id
           , HRM_EMPLOYEE_ID = ltValidate.hrm_person_id
           , IML_TRANSFER_CODE = 1
           , IML_IMP_ERROR_CODE = case
                                   when errorCode <> 0 then errorCode
                                   else null
                                 end
           , IML_IS_VAR = ltValidate.is_element
       where HRM_IMPORT_LOG_ID = ltValidate.hrm_import_log_id;

      if (errorCode > 0) then
        errorNb  := errorNb + 1;
      end if;
    end loop;

    close csValidate;

    -- if we have errors we update the document with import error number
    if (errorNb > 0) then
      update HRM_IMPORT_DOC
         set IMD_VAL_ERROR_NUM = errorNb
       where HRM_IMPORT_DOC_ID = docId;
    end if;

    commit;
  exception
    when others then
      rollback;
      -- we cancel all pending imported lines which have a null doc id because we have already
      -- rolled back
      p_remove_invalid_import();
      raise;
  end PresentoValidate;

  procedure ClobStandardValidate(DocId in hrm_import_doc.hrm_import_doc_id%type)
  is
    -- par paquets de données 58 lignes de 68 caractères (67 + LF)
    -- (pour réduire le nb d'appel au DBMS_LOB = gain de performance)
    nLength  constant binary_integer   := 58 * 68;   -- 3944
    clbContent        clob;
    strLine           varchar2(32767);
    nPos              binary_integer   := 1;
    ltt_element_code  tt_element_code;
    ltt_employee_code tt_employee_code;
    ltt_value         tt_value;
    ltt_date_from     tt_date;
    cpt               binary_integer   := 1;
  begin
    select IMD_CONTENT
      into clbContent
      from HRM_IMPORT_DOC
     where HRM_IMPORT_DOC_ID = DocID;

    -- Importation du clob dans HRM_IMPORT_LOG
    -- Par paquets de données pour réduire l'appel au DBMS_LOB (gain de performance)
    loop
      strLine  := DBMS_LOB.substr(clbContent, nLength, nPos);
      exit when strLine is null;
      nPos     := nPos + nLength;   -- Pos after extracted line

      -- 'Extraire' chacune des lignes du 'paquet'
      loop
        ltt_date_from(cpt)      := to_date(substr(strLine, 1, 6), 'MMYYYY');
        ltt_employee_code(cpt)  := substr(strLine, 10, 6);
        ltt_element_code(cpt)   := substr(strLine, 25, 7);
        ltt_value(cpt)          := to_number(substr(strLine, 43, 8) );
        cpt                     := cpt + 1;
        -- Passer à la ligne suivante
        strLine                 := substr(strLine, 69);   -- 67+LF + 1
        exit when strLine is null;
      end loop;
    end loop;

    -- Insertion
    forall cpt in ltt_value.first .. ltt_value.last
      insert into HRM_IMPORT_LOG
                  (HRM_IMPORT_LOG_ID
                 , HRM_IMPORT_DOC_ID
                 , IML_EMP_CODE
                 , IML_ELEM_CODE
                 , IML_VALUE_FROM
                 , IML_VALUE_TO
                 , IML_VALUE
                 , IML_IMPORT_DATE
                 , HRM_ELEMENTS_ID
                 , HRM_EMPLOYEE_ID
                 , IML_TRANSFER_CODE
                 , IML_IS_VAR
                 , IML_IMP_ERROR_CODE
                  )
        (select (select nvl(max(HRM_IMPORT_LOG_ID), 0) + 1
                   from HRM_IMPORT_LOG)
              , DocID hrm_import_doc_id
              , ltt_employee_code(cpt) iml_emp_code
              , ltt_element_code(cpt) iml_elem_code
              , ltt_date_from(cpt) iml_value_from
              , last_day(ltt_date_from(cpt) ) iml_value_to
              , ltt_value(cpt) iml_value
              , sysdate iml_import_date
              , ie.hrm_elements_id
              , ip.hrm_person_id hrm_employee_id
              , nvl(ie.eim_transfer_mode, 1) iml_transfer_code
              , decode(upper(f.hrm_elements_prefixes_id), 'EM', 1, 0) iml_is_var
              , nvl2(ie.hrm_elements_id, nvl2(ip.hrm_person_id, null, 2), nvl2(ip.hrm_person_id, 1, 3) ) iml_imp_error_code
           from HRM_ELEMENTS_FAMILY F
              , HRM_ELEMENTS_IMPORT_CODE IE
              , HRM_PERSON_IMPORT_CODE IP
              , HRM_IMPORT_DOC D
          where F.HRM_ELEMENTS_ID(+) = IE.HRM_ELEMENTS_ID
            and IE.HRM_IMPORT_TYPE_ID(+) = D.HRM_IMPORT_TYPE_ID
            and IP.HRM_IMPORT_TYPE_ID(+) = D.HRM_IMPORT_TYPE_ID
            and IE.EIM_IMPORT_CODE(+) = ltt_element_code(cpt)
            and IP.PIM_IMPORT_CODE(+) = ltt_employee_code(cpt)
            and D.HRM_IMPORT_DOC_ID = DocId);
    -- Mise à jour du nombre d'erreurs dans l'en-tête
    p_UpdateValidationError(DocId);
  exception
    when others then
      rollback;
      raise;
  end ClobStandardValidate;

  procedure ImportAttendance(DocId in hrm_import_doc.hrm_import_doc_id%type)
  is
    -- tableaux  des valeurs importées
    ltt_employee_code tt_employee_code;
    ltt_element_code  tt_element_code;
    ltt_date_from     tt_date;
    ltt_date_to       tt_date;
    ltt_value         tt_value;
    -- variables
    strLine           varchar2(32767);
    intLen            binary_integer;
    intCurrPos        binary_integer     := 1;
    intPrevPos        binary_integer     := 1;
    intLine           binary_integer     := 1;   -- N° de la ligne dans le fichier
    cpt               binary_integer     := 1;   -- Indice de la ligne dans le tableau (sans lignes vides)

    -- configuration
    cursor csImport(in_import_doc in hrm_import_doc.hrm_import_doc_id%type)
    is
      select IMD_CONTENT CONTENT
           , nvl(C_IMPORTFILE_TYPE, '0') FileType
           ,   -- Type de fichier : 0 = CSV, 1 = fixed length
             case C_FIELD_SEPARATOR   -- Caractère de séparation
               when '0' then ';'
               when '1' then ','
               when '2' then chr(9)   -- Tab
               when '3' then chr(124)   -- (Pipe)
             end SEPARATOR
           , IMT_EMPLOYEE_POSITION EmpPos
           ,   -- Position du no d'employé ( relative ou absolue selon méthode )
             IMT_ELEMENT_POSITION ElemPos
           ,   -- Position du no d'élément ( relative ou absolue selon méthode )
             IMT_DATE_FROM_POSITION DateFromPos
           ,   -- Position de la date du ( relative ou absolue selon méthode )
             IMT_DATE_TO_POSITION DateToPos
           ,   -- Position de la date fin ( relative ou absolue selon méthode )
             IMT_AMOUNT_POSITION AmountPos
           ,   -- Position du montant ( relative ou absolue selon méthode )
             IMT_EMPLOYEE_LENGTH EmpLen
           ,   -- Longueur du code employé
             IMT_ELEMENT_LENGTH ElemLen
           ,   -- longueur du code élément
             IMT_AMOUNT_LENGTH AmountLen
           ,   -- Longueur du montant
             length(nvl(IMT_DATE_FORMAT, 'dd.mm.yyyy') ) DateLen
           ,   -- Longeur des dates
             nvl(IMT_DATE_FORMAT, 'dd.mm.yyyy') dateformat
           ,   -- Format de date (défaut dd.MM.yyyy)
             nvl(C_IMT_PERSON_NR, '0') EmpCode
           ,   -- Mode de gestion du code employé ( 0 = selon table de conversion, 1 = selon EMP_NUMBER, 2 = selon EMP_SECONDARY_KEY, 3 = selon EMP_SOCIAL_SECURITYNO )
             nvl(C_IMT_ELEMENT_NR, '0') ElemCode
           ,   -- Mode de gestion du code élément ( 0 = selon table de conversion, 1 = selon code statistique, 2 = selon nom de l'élément )
             d.HRM_IMPORT_TYPE_ID ImportTypeId
        from HRM_IMPORT_DOC D
           , HRM_IMPORT_TYPE T
       where D.HRM_IMPORT_DOC_ID = in_import_doc
         and T.HRM_IMPORT_TYPE_ID = D.HRM_IMPORT_TYPE_ID;

    rImport           csImport%rowtype;
  begin
    open csImport(DocId);

    fetch csImport
     into rImport;

    close csImport;

    intLen  := DBMS_LOB.GetLength(rImport.Content);

    loop
      intCurrPos  := DBMS_LOB.instr(rImport.Content, chr(10), intPrevPos);

      -- Prendre en compte dernière ligne si celle-ci ne se termine pas par CHR(10)
      if (intCurrPos = 0) then
        intCurrPos  := intLen + 1;
      end if;

      strLine     := trim(DBMS_LOB.substr(rImport.Content, intCurrPos - intPrevPos, intPrevPos) );

      if length(strLine) > 0 then
        if rImport.FileType = '1' then
          --
          -- FIXED LENGTH FILE
          --
          ltt_employee_code(cpt)  := substr(strLine, rImport.EmpPos, rImport.EmpLen);
          ltt_element_code(cpt)   := substr(strLine, rImport.ElemPos, rImport.ElemLen);

          begin
            if (rImport.DateFromPos is not null) then
              ltt_date_from(cpt)  := to_date(substr(strLine, rImport.DateFromPos, rImport.DateLen), rImport.dateformat);
            else
              ltt_date_from(cpt)  := hrm_date.ActivePeriod;
            end if;

            if (rImport.DateToPos is not null) then
              ltt_date_to(cpt)  := to_date(substr(strLine, rImport.DateToPos, rImport.DateLen), rImport.dateformat);
            else
              ltt_date_to(cpt)  := last_day(ltt_date_from(cpt) );
            end if;
          exception
            when others then
              raise_application_error(-20000
                                    , pcs.pc_functions.TranslateWord('Ligne :') || ' ' || to_char(intLine) || pcs.pc_functions.TranslateWord('Date invalide')
                                     );
          end;

          begin
            ltt_value(cpt)  := to_number(substr(strLine, rImport.AmountPos, rImport.AmountLen) );
          exception
            when others then
              raise_application_error(-20000
                                    , pcs.pc_functions.TranslateWord('Ligne :') ||
                                      ' ' ||
                                      to_char(intLine) ||
                                      pcs.pc_functions.TranslateWord('Valeur non-numérique pour le montant')
                                     );
          end;
        else
          --
          -- CHARACTER DELIMITED FILE
          --

          -- forcer début et fin par le caractère de séparation
          -- pour s'assurer même traitement pour toutes les positions (1ère, dernière...)
          strLine                 := rImport.Separator || strLine || rImport.Separator;
          -- Extractions selon position
          ltt_employee_code(cpt)  := p_substr(strLine, rImport.Separator, rImport.EmpPos);
          ltt_element_code(cpt)   := p_substr(strLine, rImport.Separator, rImport.ElemPos);

          begin
            if (rImport.DateFromPos is not null) then
              ltt_date_from(cpt)  := to_date(p_substr(strLine, rImport.Separator, rImport.DateFromPos), rImport.dateformat);
            else
              ltt_date_from(cpt)  := hrm_date.ActivePeriod;
            end if;

            if (rImport.DateToPos is not null) then
              ltt_date_to(cpt)  := to_date(p_substr(strLine, rImport.Separator, rImport.DateToPos), rImport.dateformat);
            else
              ltt_date_to(cpt)  := last_day(ltt_date_from(cpt) );
            end if;
          exception
            when others then
              raise_application_error(-20000
                                    , pcs.pc_functions.TranslateWord('Ligne :') || ' ' || to_char(intLine) || pcs.pc_functions.TranslateWord('Date invalide')
                                     );
          end;

          begin
            ltt_value(cpt)  := to_number(p_substr(strLine, rImport.Separator, rImport.AmountPos) );
          exception
            when others then
              raise_application_error(-20000
                                    , pcs.pc_functions.TranslateWord('Ligne :') ||
                                      ' ' ||
                                      to_char(intLine) ||
                                      pcs.pc_functions.TranslateWord('Valeur non-numérique pour le montant')
                                     );
          end;
        end if;

        if ltt_employee_code(cpt) is null then
          raise_application_error(-20000
                                , pcs.pc_functions.TranslateWord('Ligne :') || ' ' || to_char(intLine)
                                  || pcs.pc_functions.TranslateWord('Code employé manquant')
                                 );
        end if;

        if ltt_element_code(cpt) is null then
          raise_application_error(-20000
                                , pcs.pc_functions.TranslateWord('Ligne :') || ' ' || to_char(intLine)
                                  || pcs.pc_functions.TranslateWord('Code élément manquant')
                                 );
        end if;

        cpt  := cpt + 1;
      end if;

      exit when intCurrPos >= intLen;
      intPrevPos  := intCurrPos + 1;
      intLine     := intLine + 1;
    end loop;

    forall cpt in ltt_employee_code.first .. ltt_employee_code.last
      insert into HRM_IMPORT_LOG
                  (HRM_IMPORT_LOG_ID
                 , HRM_IMPORT_DOC_ID
                 , IML_TRANSFER_CODE
                 ,   -- 1 = remplace, 2 = ajoute, 3 = insère
                   IML_EMP_CODE
                 ,   -- Code employé
                   HRM_EMPLOYEE_ID
                 , IML_ELEM_CODE
                 ,   -- Code élément
                   HRM_ELEMENTS_ID
                 , IML_VALUE_FROM
                 , IML_VALUE_TO
                 , IML_VALUE
                 , IML_IMPORT_DATE
                 , IML_IMP_ERROR_CODE
                 ,   -- Code erreur (1 = Elément null, 2 = Personne null, 3 = Elément+Person null)
                   IML_IS_VAR
                  )
        (select init_id_seq.nextval
              , DocId
              , nvl(ie.eim_transfer_mode, 1)
              , ltt_employee_code(cpt)
              , ip.HRM_PERSON_ID
              , ltt_element_code(cpt)
              , IE.HRM_ELEMENTS_ID
              , ltt_date_from(cpt)
              , ltt_date_to(cpt)
              , ltt_value(cpt)
              , sysdate
              , case
                  when IP.HRM_PERSON_ID is null then case
                                                      when IE.HRM_ELEMENTS_ID is not null then 2
                                                      else 3
                                                    end
                  when IE.HRM_ELEMENTS_ID is null then 1
                end
              , case
                  when upper(HRM_ELEMENTS_PREFIXES_ID) = 'EM' then 1
                  else 0
                end
           from HRM_ELEMENTS_FAMILY F
              ,
                -- Union all pour pouvoir utiliser la table de conversion ou le code stat / code de l'élément
                (select HRM_ELEMENTS_ID
                      , EIM_IMPORT_CODE
                      , EIM_TRANSFER_MODE
                      , HRM_IMPORT_TYPE_ID
                   from HRM_ELEMENTS_IMPORT_CODE
                  where HRM_IMPORT_TYPE_ID = rImport.ImportTypeId
                    and rImport.ElemCode = '0'
                 union all
                 select HRM_ELEMENTS_ID
                      , case rImport.ElemCode
                          when '1' then ELE_STAT_CODE
                          when '2' then ELE_CODE
                        end EIM_IMPORT_CODE
                      , null EIM_TRANFER_MODE
                      , rImport.ImportTypeId HRM_IMPORT_TYPE_ID
                   from HRM_ELEMENTS
                  where ELE_VARIABLE = 1) IE
              ,
                -- Union all pour pouvoir utiliser la table de conversion ou le numéro d'employé / clé secondaire
                (select HRM_PERSON_ID
                      , PIM_IMPORT_CODE
                      , HRM_IMPORT_TYPE_ID
                   from HRM_PERSON_IMPORT_CODE
                  where HRM_IMPORT_TYPE_ID = rImport.ImportTypeId
                    and rImport.EmpCode = '0'
                 union all
                 select HRM_PERSON_ID
                      , case rImport.EmpCode
                          when '1' then EMP_NUMBER
                          when '2' then EMP_SECONDARY_KEY
                          when '3' then EMP_SOCIAL_SECURITYNO
                        end PIM_IMPORT_CODE
                      , rImport.ImportTypeId
                   from HRM_PERSON) IP
              , HRM_IMPORT_TYPE T
          where F.HRM_ELEMENTS_ID(+) = IE.HRM_ELEMENTS_ID
            and IE.EIM_IMPORT_CODE(+) = ltt_element_code(cpt)
            and   -- Code élément
                IP.PIM_IMPORT_CODE(+) = ltt_employee_code(cpt)
            and   -- Code employé
                -- jointure avec la table hrm_import_type, juste pour forcer le retour d'1 record
                -- même si aucun liens avec personnes ni éléments
                IE.HRM_IMPORT_TYPE_ID(+) = T.HRM_IMPORT_TYPE_ID
            and IP.HRM_IMPORT_TYPE_ID(+) = T.HRM_IMPORT_TYPE_ID
            and T.HRM_IMPORT_TYPE_ID = rImport.ImportTypeId);
    -- Mise à jour du nombre d'erreurs dans l'en-tête
    p_UpdateValidationError(DocId);
  exception
    when others then
      rollback;
      raise;
  end ImportAttendance;

  procedure TaxSourceTransfer(DocId in hrm_import_doc.hrm_import_doc_id%type)
  is
    cursor csContent(in_import_doc in hrm_import_doc.hrm_import_doc_id%type)
    is
      select IMD_CONTENT
        from HRM_IMPORT_DOC
       where HRM_IMPORT_DOC_ID = in_import_doc;

    rContent         csContent%rowtype;
    strTaxCode       PCS.PC_TAXSOURCE.C_HRM_CANTON%type;
    ltt_pc_taxsource tt_pc_taxsource;
    strLine          varchar2(32767);
    nPos             binary_integer                       := 1;
    nLength          binary_integer;
    nYMin            number;
    nYMax            number;
    cpt              binary_integer                       := 1;
    dtUpdate         date;
    ln_line_count    binary_integer                       := 0;
    ln_count_ctrl    binary_integer;
  begin
    open csContent(DocID);

    fetch csContent
     into rContent;

    if (csContent%found) then
      -- Création de l'en-tête
      nLength  := 110 + 1;
      strLine  := DBMS_LOB.substr(rContent.IMD_CONTENT, nLength, nPos);
      nPos     := nPos + nLength;   -- Pos After extracted line

      if substr(strLine, 1, 2) = '00' then
        strTaxCode    := substr(strLine, 3, 2);   -- HRM_ARRAY_ID
        dtUpdate      := to_date(substr(strLine, 20, 8), 'YYYYMMDD');   -- ARR_UPDATE_DATE
        -- Par paquets de données pour réduire l'appel au DBMS_LOB (gain de performance)
        nLength       := 63 * 63;   -- par paquets de 63 lignes de 63 caractères (62 + LF)
                                    -- FirstLine's Length > Detail's Length
        strLine       := DBMS_LOB.substr(rContent.IMD_CONTENT, nLength, nPos);
        nPos          := nPos + nLength;   -- Pos After extracted line
        ln_line_count := ln_line_count +1;
      end if;

      loop
        loop
          if (substr(strLine, 1, 2) IN ( '06','11')) then
            ltt_pc_taxsource(cpt).pc_taxsource_id  := PCS.init_id_seq.nextval;
            ltt_pc_taxsource(cpt).a_datecre        := dtUpdate;
            ltt_pc_taxsource(cpt).a_idcre          := pcs.PC_I_LIB_SESSION.getuserini;
            ltt_pc_taxsource(cpt).C_HRM_CANTON     := strTaxCode;
            ltt_pc_taxsource(cpt).TAX_SCALE        := upper(rtrim(substr(strLine, 5, 12) ) || rtrim(substr(strLine, 43, 1) ) );
            nYMin                                  := to_number(substr(strLine, 25, 9) ) / 100;
            nYMax                                  := to_number(substr(strLine, 34, 9) ) / 100;
            ltt_pc_taxsource(cpt).TAX_IND_Y_MIN    := to_char(nYMin);
            ltt_pc_taxsource(cpt).TAX_IND_Y_MAX    := to_char(nYMin + nYMax - 0.001);
            ltt_pc_taxsource(cpt).TAX_RATE         := to_number(substr(strLine, 55, 5) ) / 100;
            ltt_pc_taxsource(cpt).TAX_AMOUNT       := to_number(substr(strLine, 46, 9) ) / 100;
            cpt                                    := cpt + 1;
            ln_line_count                          := ln_line_count + 1;
          elsif (substr(strLine, 1, 2) = '12') then
            /* Commission de perception, non géré pour l'heure */
            ln_line_count                          := ln_line_count + 1;
          elsif (substr(strLine, 1, 2) ='99') then
            /* Ligne de contrôle */
            if ln_line_count+1 <> to_number(substr(strLine,20, 8)) then
              raise_application_error(-20000,PCS.PC_PUBLIC.TRANSLATEWORD('Nombre de lignes importées incohérentes')||' '||ln_line_count||' vs '||substr(strline,20,8));
            end if;
          else
            raise_application_error(-20000,PCS.PC_PUBLIC.TRANSLATEWORD('Format de fichier incorrect')||' line :'||cpt);
          end if;

          -- Suppression de la ligne actuelle pour passer au reste
          strLine  := substr(strLine, 64);   -- 62+LF + 1
          exit when strLine is null;
        end loop;

        -- Bloc suivant
        strLine  := DBMS_LOB.substr(rContent.IMD_CONTENT, nLength, nPos);
        exit when strLine is null;
        nPos     := nPos + nLength;   -- Pos After extracted line
      end loop;
    end if;

    close csContent;

    -- Insertion du Détail dans PCS.PC_TAXSOURCE
    forall cpt in ltt_pc_taxsource.first .. ltt_pc_taxsource.last
      insert into PCS.PC_TAXSOURCE
           values ltt_pc_taxsource(cpt);

    -- Ajout d'un record supplémentaire pour chaque barème
    -- pour ne pas avoir de plafond et qu'un taux soit retourné dans tous les cas.
    insert into PCS.PC_TAXSOURCE
                (PC_TAXSOURCE_id
               , C_HRM_CANTON
               , TAX_SCALE
               , TAX_IND_Y_MIN
               , TAX_IND_Y_MAX
               , TAX_RATE
               , TAX_AMOUNT
               , A_DATECRE
               , A_IDCRE
                )
      (select PCS.init_id_seq.nextval
            , B.C_HRM_CANTON
            , B.TAX_SCALE
            , to_char(to_number(TAX_IND_Y_MAX, '9999999999D999') + 0.001)
            , '1000000000'
            , TAX_RATE
            , TAX_AMOUNT
            , sysdate   -- A_DATECRE
            , pcs.PC_I_LIB_SESSION.getuserini
         from PCS.PC_TAXSOURCE B
            , (select   max(to_number(TAX_IND_Y_MAX) ) MAXI
                      , C_HRM_CANTON
                      , TAX_SCALE
                   from PCS.PC_TAXSOURCE
                  where C_HRM_CANTON = strTaxCode
               group by C_HRM_CANTON
                      , TAX_SCALE) A
        where B.C_HRM_CANTON = A.C_HRM_CANTON
          and B.TAX_IND_Y_MAX = A.MAXI
          and B.TAX_SCALE = A.TAX_SCALE);
--  exception
--    when others then
--      rollback;
--      raise;
  end TaxSourceTransfer;

  procedure TaxSourceTransferGE(DocId in hrm_import_doc.hrm_import_doc_id%type)
  is
    -- Par paquets de données pour réduire l'appel au DBMS_LOB (gain de performance)
    nLength constant binary_integer                        := 54 * 73;   -- 3942

    cursor csContent(in_import_doc in hrm_import_doc.hrm_import_doc_id%type)
    is
      select IMD_CONTENT
        from HRM_IMPORT_DOC
       where HRM_IMPORT_DOC_ID = in_import_doc;

    rContent         csContent%rowtype;
    ltt_array_detail tt_array_detail;
    strYMin          hrm_array_detail.ard_ind_y_min%type;
    strYMax          hrm_array_detail.ard_ind_y_min%type;
    strLine          varchar2(32767);
    nPos             binary_integer                        := 1;
    strVal           varchar2(4);
    cpt              binary_integer                        := 1;
    nYMin            number;
  begin
    open csContent(DocID);

    fetch csContent
     into rContent;

    if (csContent%found) then
      strLine  := DBMS_LOB.substr(rContent.IMD_CONTENT, nLength, nPos);
      nPos     := nPos + nLength;   -- new offset after extracted line

      -- Création de l'entête HRM_ARRAY, l'année est contenue au début de la ligne
      insert into HRM_ARRAY
                  (HRM_ARRAY_ID
                 , ARR_UPDATE_DATE
                 , ARR_DESCR
                 , A_IDCRE
                 , A_DATECRE
                  )
           values ('GE'
                 ,   -- HRM_ARRAY_ID
                   sysdate
                 ,   -- ARR_UPDATE_DATE
                   to_char(to_date('0101' || substr(strLine, 1, 2), 'DDMMYY'), 'DD/MM/YYYY')
                 ,   -- ARR_DESCR
                   'AUTO'
                 ,   -- A_IDCRE
                   sysdate
                  );   -- A_DATECRE

      -- Création du détail HRM_ARRAY_DETAIL
      loop
        loop
          nYMin    := to_number(substr(strLine, 17, 7) ) / 100;

          if (nYMin > 0.0) then
            nYMin  := nYMin - 0.049;
          end if;

          strYMin  := to_char(nYMin);
          strYMax  := to_char(to_number(substr(strLine, 24, 7) ) );
          -- Création des différents taux (si <> 0) pour la ligne en cours
          strVal   := substr(strLine, 45, 4);

          if (strVal <> '0000') then
            ltt_array_detail(cpt).ARD_IND_X      := 'GEA';
            ltt_array_detail(cpt).ARD_VALUE      := to_number(strVal) / 100;
            ltt_array_detail(cpt).ARD_IND_Y_MIN  := strYMin;
            ltt_array_detail(cpt).ARD_IND_Y_MAX  := strYMax;
            ltt_array_detail(cpt).HRM_ARRAY_ID   := 'GE';
            cpt                                  := cpt + 1;
          end if;

          strVal   := substr(strLine, 49, 4);

          if (strVal <> '0000') then
            ltt_array_detail(cpt).ARD_IND_X      := 'GEB';
            ltt_array_detail(cpt).ARD_VALUE      := to_number(strVal) / 100;
            ltt_array_detail(cpt).ARD_IND_Y_MIN  := strYMin;
            ltt_array_detail(cpt).ARD_IND_Y_MAX  := strYMax;
            ltt_array_detail(cpt).HRM_ARRAY_ID   := 'GE';
            cpt                                  := cpt + 1;
          end if;

          strVal   := substr(strLine, 53, 4);

          if (strVal <> '0000') then
            ltt_array_detail(cpt).ARD_IND_X      := 'GEB1';
            ltt_array_detail(cpt).ARD_VALUE      := to_number(strVal) / 100;
            ltt_array_detail(cpt).ARD_IND_Y_MIN  := strYMin;
            ltt_array_detail(cpt).ARD_IND_Y_MAX  := strYMax;
            ltt_array_detail(cpt).HRM_ARRAY_ID   := 'GE';
            cpt                                  := cpt + 1;
          end if;

          strVal   := substr(strLine, 57, 4);

          if (strVal <> '0000') then
            ltt_array_detail(cpt).ARD_IND_X      := 'GEB2';
            ltt_array_detail(cpt).ARD_VALUE      := to_number(strVal) / 100;
            ltt_array_detail(cpt).ARD_IND_Y_MIN  := strYMin;
            ltt_array_detail(cpt).ARD_IND_Y_MAX  := strYMax;
            ltt_array_detail(cpt).HRM_ARRAY_ID   := 'GE';
            cpt                                  := cpt + 1;
          end if;

          strVal   := substr(strLine, 61, 4);

          if (strVal <> '0000') then
            ltt_array_detail(cpt).ARD_IND_X      := 'GEB3';
            ltt_array_detail(cpt).ARD_VALUE      := to_number(strVal) / 100;
            ltt_array_detail(cpt).ARD_IND_Y_MIN  := strYMin;
            ltt_array_detail(cpt).ARD_IND_Y_MAX  := strYMax;
            ltt_array_detail(cpt).HRM_ARRAY_ID   := 'GE';
            cpt                                  := cpt + 1;
          end if;

          strVal   := substr(strLine, 65, 4);

          if (strVal <> '0000') then
            ltt_array_detail(cpt).ARD_IND_X      := 'GEB4';
            ltt_array_detail(cpt).ARD_VALUE      := to_number(strVal) / 100;
            ltt_array_detail(cpt).ARD_IND_Y_MIN  := strYMin;
            ltt_array_detail(cpt).ARD_IND_Y_MAX  := strYMax;
            ltt_array_detail(cpt).HRM_ARRAY_ID   := 'GE';
            cpt                                  := cpt + 1;
          end if;

          strVal   := substr(strLine, 69, 4);

          if (strVal <> '0000') then
            ltt_array_detail(cpt).ARD_IND_X      := 'GEB5';
            ltt_array_detail(cpt).ARD_VALUE      := to_number(strVal) / 100;
            ltt_array_detail(cpt).ARD_IND_Y_MIN  := strYMin;
            ltt_array_detail(cpt).ARD_IND_Y_MAX  := strYMax;
            ltt_array_detail(cpt).HRM_ARRAY_ID   := 'GE';
            cpt                                  := cpt + 1;
          end if;

          strLine  := substr(strLine, 74);   -- 72+LF +1
          exit when strLine is null;
        end loop;

        strLine  := DBMS_LOB.substr(rContent.IMD_CONTENT, nLength, nPos);
        exit when strLine is null;
        nPos     := nPos + nLength;
      end loop;
    end if;

    close csContent;

    -- Insertion du Détail dans HRM_ARRAY_DETAIL
    forall cpt in ltt_array_detail.first .. ltt_array_detail.last
      insert into HRM_ARRAY_DETAIL
           values ltt_array_detail(cpt);

    -- Ajout d'un record supplémentaire pour chaque barème
    -- pour ne pas avoir de plafond et qu'un taux soit retourné dans tous les cas.
    insert into HRM_ARRAY_DETAIL
                (HRM_ARRAY_ID
               , ARD_IND_X
               , ARD_IND_Y_MIN
               , ARD_IND_Y_MAX
               , ARD_VALUE
                )
      (select B.HRM_ARRAY_ID
            , B.ARD_IND_X
            , to_char(to_number(ARD_IND_Y_MAX, '9999999999D999') + 0.001)
            , '1000000000'
            , ARD_VALUE
         from HRM_ARRAY_DETAIL B
            , (select   max(to_number(ARD_IND_Y_MAX) ) MAXI
                      , HRM_ARRAY_ID
                      , ARD_IND_X
                   from HRM_ARRAY_DETAIL
                  where HRM_ARRAY_ID = 'GE'
               group by HRM_ARRAY_ID
                      , ARD_IND_X) A
        where B.HRM_ARRAY_ID = A.HRM_ARRAY_ID
          and B.ARD_IND_Y_MAX = A.MAXI
          and B.ARD_IND_X = A.ARD_IND_X);
  exception
    when others then
      rollback;
      raise;
  end TaxSourceTransferGE;
end HRM_IMPORT;
