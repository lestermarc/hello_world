--------------------------------------------------------
--  DDL for Package Body COM_PRC_EBANKING_DET
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_PRC_EBANKING_DET" 
/**
 * Package de gestion pour e-banking.
 *
 * @version 1.0
 * @date 2004
 * @author mbartolacci
 * @author ngomes
 * @author dsaadé
 * @author skalayci
 * @author spfister
 *
 * Copyright 1997-2011 SolvAxis SA. Tous droits réservés.
 */
as
  procedure InsertEBPPDetail(
    in_ebanking_id              in com_ebanking_detail.com_ebanking_id%type
  , iv_ebanking_status          in com_ebanking_detail.c_ceb_ebanking_status%type
  , iv_ebanking_error           in com_ebanking_detail.c_ceb_ebanking_error%type default null
  , in_exchange_system_error_id in com_ebanking_detail.pc_exchange_system_error_id%type default null
  , iv_comment                  in com_ebanking_detail.ced_comment%type default null
  , ib_update                   in boolean default true
  )
  is
    ln_ebanking_detail_id com_ebanking_detail.com_ebanking_detail_id%type;
  begin
    com_prc_ebanking_det.InsertEBPPDetail(in_ebanking_id                => in_ebanking_id
                                        , iv_ebanking_status            => iv_ebanking_status
                                        , iv_ebanking_error             => iv_ebanking_error
                                        , in_exchange_system_error_id   => in_exchange_system_error_id
                                        , iv_comment                    => iv_comment
                                        , ib_update                     => ib_update
                                        , on_ebanking_detail_id         => ln_ebanking_detail_id
                                         );
  end InsertEBPPDetail;

  procedure InsertEBPPDetail(
    in_ebanking_id              in     com_ebanking_detail.com_ebanking_id%type
  , iv_ebanking_status          in     com_ebanking_detail.c_ceb_ebanking_status%type
  , iv_ebanking_error           in     com_ebanking_detail.c_ceb_ebanking_error%type default null
  , in_exchange_system_error_id in     com_ebanking_detail.pc_exchange_system_error_id%type default null
  , iv_comment                  in     com_ebanking_detail.ced_comment%type default null
  , ib_update                   in     boolean default true
  , on_ebanking_detail_id       out    com_ebanking_detail.com_ebanking_detail_id%type
  )
  is
  begin
    insert into COM_EBANKING_DETAIL
                (COM_EBANKING_DETAIL_ID
               , C_CEB_EBANKING_STATUS
               , C_CEB_EBANKING_ERROR
               , PC_EXCHANGE_SYSTEM_ERROR_ID
               , COM_EBANKING_ID
               , CED_SEQUENCE
               , CED_COMMENT
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , iv_ebanking_status
               , iv_ebanking_error
               , in_exchange_system_error_id
               , in_ebanking_id
               , (select nvl(max(CED_SEQUENCE), 0) + 1
                    from COM_EBANKING_DETAIL
                   where COM_EBANKING_ID = in_ebanking_id)
               , iv_comment
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                )
      returning COM_EBANKING_DETAIL_ID
           into on_ebanking_detail_id;

    -- La mise à jour du status des données EBPP ne peut se faire que si
    -- le traitement n'est pas appelé depuis un trigger, sinon l'exception
    -- ORA-04091: table is mutating est levée.
    if ib_update then
      update COM_EBANKING
         set C_CEB_EBANKING_STATUS = iv_ebanking_status
           , C_CEB_EBANKING_ERROR = iv_ebanking_error
       where COM_EBANKING_ID = in_ebanking_id;
    end if;
  end InsertEBPPDetail;

  /**
  * Description
  *    Cette fonction va supprimer le journal de transaction du document e-facture
  *    dont la clef primaires est transmise en paramètre.
  */
  procedure DeleteEBPPDetail(inComEbankingID in COM_EBANKING.COM_EBANKING_ID%type)
  as
  begin
    delete from COM_EBANKING_DETAIL
          where COM_EBANKING_ID = inComEbankingID;
  end DeleteEBPPDetail;

  procedure InsertEBPPFile(
    in_ebanking_id        in com_ebanking.com_ebanking_id%type
  , in_ebanking_detail_id in com_ebanking_detail.com_ebanking_detail_id%type
  , iv_ebanking_file_type in com_ebanking_files.c_ceb_ebanking_file_type%type
  , iv_file_path          in com_ebanking_files.cet_file_path%type
  , ib_signed             in com_ebanking_files.cet_signed%type
  )
  is
    ln_ebanking_files_id com_ebanking_files.com_ebanking_files_id%type;
  begin
    com_prc_ebanking_det.InsertEBPPFile(in_ebanking_id          => in_ebanking_id
                                      , in_ebanking_detail_id   => in_ebanking_detail_id
                                      , iv_ebanking_file_type   => iv_ebanking_file_type
                                      , iv_file_path            => iv_file_path
                                      , ib_signed               => ib_signed
                                      , on_ebanking_files_id    => ln_ebanking_files_id
                                       );
  end;

  procedure InsertEBPPFile(
    in_ebanking_id        in     com_ebanking.com_ebanking_id%type
  , in_ebanking_detail_id in     com_ebanking_detail.com_ebanking_detail_id%type
  , iv_ebanking_file_type in     com_ebanking_files.c_ceb_ebanking_file_type%type
  , iv_file_path          in     com_ebanking_files.cet_file_path%type
  , ib_signed             in     com_ebanking_files.cet_signed%type
  , on_ebanking_files_id  out    com_ebanking_files.com_ebanking_files_id%type
  )
  is
  begin
    if (    (    iv_ebanking_file_type = '01'
             and ib_signed = 1)
        or   -- Xml file
           (iv_ebanking_file_type = '02') ) then   -- Pdf document
      -- vérification de l'existance d'un fichier correspondant
      select count(*)
        into on_ebanking_files_id
        from dual
       where exists(
               select 1
                 from COM_EBANKING_FILES
                where COM_EBANKING_ID = in_ebanking_id
                  and COM_EBANKING_DETAIL_ID = in_ebanking_detail_id
                  and C_CEB_EBANKING_FILE_TYPE = iv_ebanking_file_type);

      if (on_ebanking_files_id > 0) then
        -- Si un fichier existe, il suffit de la mettre à jour
        -- Ne pas utiliser de MERGE dans ce cas à cause de COM_EBANKING_FILES_ID
        -- qui doit être retourné dans on_ebanking_files_id
        update    COM_EBANKING_FILES
              set CET_FILE_PATH = iv_file_path
                , CET_SIGNED = ib_signed
                , A_DATEMOD = sysdate
                , A_IDMOD = pcs.PC_I_LIB_SESSION.GetUserIni
            where COM_EBANKING_ID = in_ebanking_id
              and COM_EBANKING_DETAIL_ID = in_ebanking_detail_id
              and C_CEB_EBANKING_FILE_TYPE = iv_ebanking_file_type
        returning COM_EBANKING_FILES_ID
             into on_ebanking_files_id;

        -- sortie anticipée, car il n'y a rien de plus à faire
        return;
      end if;
    end if;

    -- Sinon il faut créer une nouvelle entrée pour le fichier
    insert into COM_EBANKING_FILES
                (COM_EBANKING_FILES_ID
               , COM_EBANKING_ID
               , COM_EBANKING_DETAIL_ID
               , C_CEB_EBANKING_FILE_TYPE
               , CET_FILE_PATH
               , CET_SIGNED
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , in_ebanking_id
               , in_ebanking_detail_id
               , iv_ebanking_file_type
               , iv_file_path
               , ib_signed
               , sysdate
               , pcs.PC_I_LIB_SESSION.GetUserIni
                )
      returning COM_EBANKING_FILES_ID
           into on_ebanking_files_id;
  end InsertEBPPFile;

  procedure InsertExchangeDataIn(
    in_exchange_system_id in pcs.pc_exchange_system.pc_exchange_system_id%type
  , iv_file_path          in pcs.pc_exchange_data_in.edi_filing_url%type
  , iv_file_name          in pcs.pc_exchange_data_in.edi_filename%type
  , it_xml_document       in clob
  )
  is
    ln_exchange_data_in_id pcs.pc_exchange_data_in.pc_exchange_data_in_id%type;
  begin
    com_prc_ebanking_det.InsertExchangeDataIn(in_exchange_system_id    => in_exchange_system_id
                                            , iv_file_path             => iv_file_path
                                            , iv_file_name             => iv_file_name
                                            , it_xml_document          => it_xml_document
                                            , on_exchange_data_in_id   => ln_exchange_data_in_id
                                             );
  end InsertExchangeDataIn;

  procedure InsertExchangeDataIn(
    in_exchange_system_id  in     pcs.pc_exchange_system.pc_exchange_system_id%type
  , iv_file_path           in     pcs.pc_exchange_data_in.edi_filing_url%type
  , iv_file_name           in     pcs.pc_exchange_data_in.edi_filename%type
  , it_xml_document        in     clob
  , on_exchange_data_in_id out    pcs.pc_exchange_data_in.pc_exchange_data_in_id%type
  )
  is
    lv_sending_mode pcs.pc_exchange_data_in.c_ecs_sending_mode%type;
  begin
    -- /!\ Pour valider le système d'échange de données "payer"
    select C_ECS_SENDING_MODE
      into lv_sending_mode
      from PCS.PC_EXCHANGE_SYSTEM
     where PC_EXCHANGE_SYSTEM_ID = in_exchange_system_id
       and C_ECS_ROLE = '02';   -- système d'échange de données "payer"

    insert into PCS.PC_EXCHANGE_DATA_IN
                (PC_EXCHANGE_DATA_IN_ID
               , PC_EXCHANGE_SYSTEM_ID
               , C_ECS_SENDING_MODE
               , C_EDI_PROCESS_STATUS
               , EDI_FILING_URL
               , EDI_FILENAME
               , EDI_IMPORTED_XML_DOCUMENT
                )
         values (init_id_seq.nextval
               , in_exchange_system_id
               , lv_sending_mode
               , '01'   -- C_EDI_PROCESS_STATUS
               , iv_file_path
               , iv_file_name
               , it_xml_document
                )
      returning PC_EXCHANGE_DATA_IN_ID
           into on_exchange_data_in_id;
  end InsertExchangeDataIn;
end COM_PRC_EBANKING_DET;
