--------------------------------------------------------
--  DDL for Package Body WEB_IMAGES_FILE_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_IMAGES_FILE_FCT" 
AS
  /**
   * Implémentation du package web_images_file_fct
   */

  /**
   *
   */
  TYPE mime_mapping_type IS TABLE OF VARCHAR2(512) INDEX BY VARCHAR2(256);

  g_mime_mappings mime_mapping_type;

  /**
   * Retourne le mime-type en fonction de l'extension du fichier. Si l'extension
   * n'est pas trouvée, on retourne null.
   * @param p_file nom du fichier
   * @return le mime-type correspondant à l'extension ou null
   */
  FUNCTION retrieve_content_type(
   p_file IN VARCHAR2
  )
    RETURN VARCHAR2
  IS
    s_ext VARCHAR2(4000) := p_file;
    n_pos NUMBER(6);
  BEGIN
    n_pos := InStr(p_file, '.', -1);
    IF n_pos > 0 THEN
      s_ext := SubStr(p_file, n_pos+1);
      IF g_mime_mappings.Exists(s_ext) THEN
        RETURN g_mime_mappings(s_ext);
      END IF;
    END IF;
    RETURN NULL;
  END retrieve_content_type;

  /**
   * Voir spécification
   */
  FUNCTION retrieve_web_resource(
    p_url           IN VARCHAR2
  , p_user_agent    IN VARCHAR2
  , p_download      IN NUMBER DEFAULT 0
  )
    RETURN Web_Resource_Table PIPELINED
  IS
   s_imf_table com_image_files.imf_table%TYPE;
   n_imf_rec_id com_image_files.imf_rec_id%TYPE;
   n_imf_id com_image_files.com_image_files_id%TYPE;
   s_imf_file com_image_files.imf_file%TYPE;
   s_url VARCHAR2(4000);
   n_index NUMBER(5);
   n_pos NUMBER(2);
   s_content_type VARCHAR(4000);
   rec_resource Web_Resource_RECORD;
  BEGIN
    /* Controle si l'URL a le format attendu */
    IF NOT regexp_like(p_url, '^([A-Z_]{1,30})/([0-9]{1,15}):([0-9]{1,15})$') THEN
      RETURN;
    END IF;

    /* Oracle ne fournit pas de fonction pour retourner la part de la chaîne
     * trouvée par un groupe de capture. On récupère tout "à la main"
     */
    s_url := p_url;
    /* Récupère la valeur de ifm_table */
    n_pos := 1;
    n_index := InStr(s_url, '/', n_pos, 1);
    s_imf_table := SubStr(s_url, n_pos, n_index-n_pos);
    /* Récupère le rec id*/
    n_pos := n_index + 1;
    n_index := InStr(s_url, ':', n_pos, 1);
    n_imf_rec_id := to_number(substr(p_url, n_pos, n_index - n_pos));
    /* Récupère l'id de l'object */
    n_pos := n_index + 1;
    n_imf_id := to_number(substr(p_url, n_pos));

    /* Sélectionne l'objet à retourner */
    SELECT cif.com_image_files_id
         , co.OLE_OLE
         , Greatest(coalesce(cif.a_datemod,cif.a_datecre),coalesce(co.a_datemod,co.a_datecre))
         , cif.imf_file
      INTO rec_resource.id, rec_resource.data, rec_resource.last_modified, s_imf_file
      FROM com_image_files cif, com_ole co
     WHERE cif.com_image_files_id = n_imf_id
       AND cif.imf_table = s_imf_table
       AND cif.imf_rec_id = n_imf_rec_id
       AND cif.com_ole_id = co.com_ole_id;

    rec_resource.content_type := retrieve_content_type(s_imf_file);
    IF p_download != 0 THEN
      rec_resource.headers := 'Content-Disposition:attachment;filename='||s_imf_file;
    END IF;

    PIPE ROW(rec_resource);

    EXCEPTION
       WHEN NO_DATA_FOUND THEN
         DBMS_OUTPUT.PUT_LINE('No Data Found');
       WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('Others Errors : ' || SQLCODE() || ' - ' || SQLERRM());
  END retrieve_web_resource;

  /**
   * Voir spécification.
   */
  FUNCTION build_url(
    p_id  IN NUMBER
  )
    RETURN VARCHAR2
  IS
   s_url_part VARCHAR2(4000);
  BEGIN
    SELECT cif.imf_table  || '/' ||
           cif.imf_rec_id || ':' ||
           cif.com_image_files_id
      INTO s_url_part
      FROM com_image_files cif, com_ole co
     WHERE p_id = cif.com_image_files_id
       AND cif.com_ole_id = co.com_ole_id
       AND cif.imf_stored_in = 'DB';
    RETURN s_url_part;
  END build_url;

BEGIN
  g_mime_mappings('au')    := 'audio/basic';
  g_mime_mappings('avi')   := 'video/x-msvideo';
  g_mime_mappings('bin')   := 'application/octet-stream';
  g_mime_mappings('bmp')   := 'image/bmp';
  g_mime_mappings('doc')   := 'application/msword';
  g_mime_mappings('eml')   := 'message/rfc822';
  g_mime_mappings('gif')   := 'image/gif';
  g_mime_mappings('htm')   := 'text/html';
  g_mime_mappings('html')  := 'text/html';
  g_mime_mappings('jpe')   := 'image/jpeg';
  g_mime_mappings('jpeg')  := 'image/jpeg';
  g_mime_mappings('jpg')   := 'image/jpeg';
  g_mime_mappings('jsp')   := 'text/html';
  g_mime_mappings('mid')   := 'audio/mid';
  g_mime_mappings('mov')   := 'video/quicktime';
  g_mime_mappings('movie') := 'video/x-sgi-movie';
  g_mime_mappings('mp3')   := 'audio/mpeg';
  g_mime_mappings('mpe')   := 'video/mpg';
  g_mime_mappings('mpeg')  := 'video/mpg';
  g_mime_mappings('mpg')   := 'video/mpg';
  g_mime_mappings('msa')   := 'application/x-msaccess';
  g_mime_mappings('msw')   := 'application/x-msworks-wp';
  g_mime_mappings('pcx')   := 'application/x-pc-paintbrush';
  g_mime_mappings('pdf')   := 'application/pdf';
  g_mime_mappings('ppt')   := 'application/vnd.ms-powerpoint';
  g_mime_mappings('ps')    := 'application/postscript';
  g_mime_mappings('qt')    := 'video/quicktime';
  g_mime_mappings('ra')    := 'audio/x-realaudio';
  g_mime_mappings('ram')   := 'audio/x-realaudio';
  g_mime_mappings('rm')    := 'audio/x-realaudio';
  g_mime_mappings('rtf')   := 'application/rtf';
  g_mime_mappings('rv')    := 'video/x-realvideo';
  g_mime_mappings('sgml')  := 'text/sgml';
  g_mime_mappings('tif')   := 'image/tiff';
  g_mime_mappings('tiff')  := 'image/tiff';
  g_mime_mappings('txt')   := 'text/plain';
  g_mime_mappings('url')   := 'text/plain';
  g_mime_mappings('vrml')  := 'x-world/x-vrml';
  g_mime_mappings('wav')   := 'audio/wav';
  g_mime_mappings('wpd')   := 'application/wordperfect5.1';
  g_mime_mappings('xls')   := 'application/vnd.ms-excel';
  g_mime_mappings('xml')   := 'text/xml';
  g_mime_mappings('zip')   := 'application/x-zip-compressed';
END web_images_file_fct;
