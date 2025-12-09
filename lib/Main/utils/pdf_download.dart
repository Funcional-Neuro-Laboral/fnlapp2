// Importación condicional para descarga de PDF
// En web usa dart:html, en otras plataformas usa stub
export 'pdf_download_stub.dart' if (dart.library.html) 'pdf_download_web.dart';
