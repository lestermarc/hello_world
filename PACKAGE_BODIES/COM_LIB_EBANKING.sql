--------------------------------------------------------
--  DDL for Package Body COM_LIB_EBANKING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_LIB_EBANKING" 
/**
 * fonctions utilitaires pour e-banking.
 *
 * @version 1.0
 * @date 04/2011
 * @author pyvoirol
 * @author spfister
 *
 * Copyright 1997-2011 SolvAxis SA. Tous droits réservés.
 */
AS

function isDocumentMatched(
  in_document_id IN act_document.act_document_id%TYPE)
  return BOOLEAN
is
  ln_result NUMBER;
begin
  select Sign(Count(DOC.ACT_DOCUMENT_ID))
    into ln_result
    from ACT_DOCUMENT DOC
       , ACT_EXPIRY EXP
   where DOC.ACT_DOCUMENT_ID = in_document_id
     and DOC.ACT_DOCUMENT_ID = EXP.ACT_DOCUMENT_ID
     and Exists(select 1
                  from ACT_DET_PAYMENT
                 where ACT_EXPIRY_ID = EXP.ACT_EXPIRY_ID);

  return ln_result > 0;
end;

function isExchangeSystemActive(
  in_exchange_system_id IN pcs.pc_exchange_system.pc_exchange_system_id%TYPE)
  return BOOLEAN
is
  ln_result pcs.pc_exchange_system.pc_exchange_system_id%TYPE;
begin
  select Max(PC_EXCHANGE_SYSTEM_ID)
    into ln_result
    from PCS.PC_EXCHANGE_SYSTEM
   where PC_EXCHANGE_SYSTEM_ID = in_exchange_system_id
     and C_ECS_STATUS = '01';

  return ln_result is not null;
end;

function isEbppReferenceActive(
  in_ebpp_reference_id IN pac_ebpp_reference.pac_ebpp_reference_id%TYPE)
  return BOOLEAN
is
  ln_result pac_ebpp_reference.pac_ebpp_reference_id%TYPE;
begin
  select Max(PAC_EBPP_REFERENCE_ID)
    into ln_result
    from PAC_EBPP_REFERENCE
   where PAC_EBPP_REFERENCE_ID = in_ebpp_reference_id
     and C_EBPP_STATUS = '1'
     and Trunc(Sysdate) between Trunc(EBP_VALID_FROM) and Trunc(EBP_VALID_TO);

  return ln_result is not null;
end;

function GetDeliveryDate(
  in_ebanking_id IN com_ebanking.com_ebanking_id%TYPE)
  return DATE
is
  ln_document_id NUMBER;
  lv_origine com_ebanking.c_ceb_document_origin%TYPE;
  lv_Provider pcs.pc_exchange_system.c_ecs_bsp%TYPE;
  lv_Version pcs.pc_exchange_system.c_ecs_version%TYPE;
begin
  begin
    select CEB.C_CEB_DOCUMENT_ORIGIN
         , case CEB.C_CEB_DOCUMENT_ORIGIN
             when '01' then CEB.DOC_DOCUMENT_ID   -- Logistique ERP
             when '02' then CEB.ACT_DOCUMENT_ID   -- Finance interne
             when '03' then CEB.ACT_DOCUMENT_ID   -- Finance externe
           end DOCUMENT_ID
         , ECS.C_ECS_BSP
         , ECS.C_ECS_VERSION
      into lv_origine
         , ln_document_id
         , lv_Provider
         , lv_Version
      from COM_EBANKING CEB
         , PCS.PC_EXCHANGE_SYSTEM ECS
     where CEB.COM_EBANKING_ID = in_ebanking_id
       and CEB.C_CEB_EBANKING_STATUS >= '004'
       and ECS.PC_EXCHANGE_SYSTEM_ID = CEB.PC_EXCHANGE_SYSTEM_ID;
  exception
    when NO_DATA_FOUND then
      return null;
  end;

  case lv_Provider
    when '00' then
      -- YellowBill
      if (lv_Version = '001') then
        case lv_origine
          when '01' then   -- Logistique ERP
            return com_lib_ebanking_utl.GetDeliveryDate(ln_document_id, 'DOC');
          when '02' then   -- Finance interne
            return com_lib_ebanking_utl.GetDeliveryDate(ln_document_id, 'ACT');
          when '03' then   -- Finance externe
            return com_lib_ebanking_utl.GetDeliveryDate(ln_document_id, 'ACT');
          else
            return null;
        end case;
      end if;
    when '01' then
      -- PayNet
      case lv_origine
        when '01' then   -- Logistique ERP
          return com_lib_ebanking_utl.GetDeliveryDate(ln_document_id, 'DOC');
        when '02' then   -- Finance interne
          return com_lib_ebanking_utl.GetDeliveryDate(ln_document_id, 'ACT');
        when '03' then   -- Finance externe
          return com_lib_ebanking_utl.GetDeliveryDate(ln_document_id, 'ACT');
        else
          return null;
      end case;
    else
      return null;
  end case;
  return null;
end;

function NextEBankingTransactionId
  return com_ebanking.ceb_transaction_id%TYPE
is
  lv_result VARCHAR2(16);
begin
  select to_char(com_ebanking_transaction_seq.NextVal,'FM000000000009')
    into lv_result
    from dual;
  return lv_result;
end;

END COM_LIB_EBANKING;
