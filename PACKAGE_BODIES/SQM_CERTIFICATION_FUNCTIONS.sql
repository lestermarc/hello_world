--------------------------------------------------------
--  DDL for Package Body SQM_CERTIFICATION_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SQM_CERTIFICATION_FUNCTIONS" 
is
  cCerLidCode constant varchar2(18) := 'CER_GOOD_CONDITION';

  /**
  * Description
  *    procedure
  */
  procedure UpdateGoodListOfCondCertifs(aParam varchar2)
  is
    cursor crCertifications
    is
      select CER.SQM_CERTIFICATION_ID
           , CER.CER_GOOD_CONDITION
        from SQM_CERTIFICATION CER
       where CER.C_GOOD_RELATION_TYPE = '2'
         and CER.CER_GOOD_CONDITION is not null;

    cursor crGoods(aParam varchar2)
    is
      select GOO.GCO_GOOD_ID
        from GCO_GOOD GOO
       where GOO.GOO_MAJOR_REFERENCE like LIKE_PARAM(aParam);

    tplCertification crCertifications%rowtype;
    tplGood          crGoods%rowtype;
    vApplicable      number;
  begin
    delete from COM_LIST_ID_TEMP
          where LID_CODE = cCerLidCode;

    begin
      for tplGood in crGoods(aParam) loop
        begin
          for tplCertification in crCertifications loop
            begin
              execute immediate to_char(tplCertification.CER_GOOD_CONDITION)
                           into vApplicable
                          using in tplGood.GCO_GOOD_ID;

              if (nvl(vApplicable, 0) <> 0) then
                insert into COM_LIST_ID_TEMP
                            (COM_LIST_ID_TEMP_ID
                           , LID_CODE
                           , LID_FREE_NUMBER_1
                           , LID_FREE_NUMBER_2
                            )
                     values (init_temp_id_seq.nextval
                           , cCerLidCode
                           , tplCertification.SQM_CERTIFICATION_ID
                           , tplGood.GCO_GOOD_ID
                            );
              end if;
            exception
              when no_data_found then
                null;
            end;
          end loop;
        exception
          when no_data_found then
            null;
        end;
      end loop;
    exception
      when no_data_found then
        null;
    end;
  end UpdateGoodListOfCondCertifs;

  /**
  * Description
  *    procedure
  */
  procedure UpdateListOfConditionalCertifs(aGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    cursor crCertifications
    is
      select CER.SQM_CERTIFICATION_ID
           , CER.CER_GOOD_CONDITION
        from SQM_CERTIFICATION CER
       where CER.C_GOOD_RELATION_TYPE = '2'
         and CER.CER_GOOD_CONDITION is not null;

    tplCertification crCertifications%rowtype;
    vApplicable      number;
  begin
    delete from COM_LIST_ID_TEMP
          where LID_CODE = cCerLidCode;

    begin
      for tplCertification in crCertifications loop
        execute immediate to_char(tplCertification.CER_GOOD_CONDITION)
                     into vApplicable
                    using in aGoodID;

        if (nvl(vApplicable, 0) <> 0) then
          insert into COM_LIST_ID_TEMP
                      (COM_LIST_ID_TEMP_ID
                     , LID_CODE
                      )
               values (tplCertification.SQM_CERTIFICATION_ID
                     , cCerLidCode
                      );
        end if;
      end loop;
    exception
      when no_data_found then
        null;
    end;
  end UpdateListOfConditionalCertifs;
end SQM_CERTIFICATION_FUNCTIONS;
