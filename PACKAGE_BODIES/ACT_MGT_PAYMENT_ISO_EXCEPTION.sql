--------------------------------------------------------
--  DDL for Package Body ACT_MGT_PAYMENT_ISO_EXCEPTION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_MGT_PAYMENT_ISO_EXCEPTION" 
/**
 * Gestion des exceptions pour les paiements selon ISO 20022.
 *
 * @date 03.2012
 * @author spfister
 *
 * Copyright 1997-2012 SolvAxis SA. Tous droits réservés.
 */
IS

procedure raise_exception(
  in_error_code IN NUMBER,
  iv_message IN VARCHAR2)
is
  lt_exception fwk_i_mgt_exception.T_EXCEPTION;
begin
  lt_exception.message := iv_message;
  lt_exception.stack_trace := dbms_utility.format_error_backtrace;
  fwk_i_mgt_exception.raise_exception(in_error_code, lt_exception);
end;

END ACT_MGT_PAYMENT_ISO_EXCEPTION;
