--------------------------------------------------------
--  DDL for Package Body HRM_XML
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_XML" is

function hasChildrenWithValues(vEmp_id number,xml_seq_id number) return number is
  Cursor c1(empId number, xmlId number) is
  Select 1 from hrm_person_xml b where xml_value is not null
  START WITH hrm_person_id = empId and b.xml_seq_id = xmlid
  CONNECT BY prior hrm_person_id=hrm_person_id and prior xml_seq_id  = xml_parent_id;
  tmp integer;
begin
  open c1(vEmp_id,xml_seq_id );
  FETCH c1 INTO tmp;
  if tmp > 0 Then return tmp; else return 0; end if;
  exception
    when others then return 0;
end hasChildrenWithValues;

function xmlValue(vEmp_id number, vTag varchar2) return varchar2 is
 tmp hrm_person_xml.xml_value%type;
 cursor cs(Emp_id number, Tag varchar2)is select xml_value from hrm_person_xml where
   hrm_person_id = Emp_id and upper(xml_tag) = upper(Tag) and xml_Value is not null
   order by xml_seq_id;
begin
  open cs(vEmp_id,vTag);
  FETCH cs INTO tmp;
  if cs%notFound then return ''; else return tmp; end if;
  exception
    when others then return '';
end;

end hrm_xml;
