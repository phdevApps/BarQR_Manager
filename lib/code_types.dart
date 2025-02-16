// #barcode228 BarcodeType
//
// CodeITF16
// CodeITF14
// CodeEAN13
// CodeEAN8
// CodeEAN5
// CodeEAN2
// CodeISBN
// Code39
// Code93
// CodeUPCA
// CodeUPCE
// Code128
// GS128
// Telepen
// QrCode
// Codabar
// PDF417
// DataMatrix
// Aztec
// Rm4scc
// Itf
//
//
// #mobilescanner357__BarcodeFormat
// code128
// code39
// code93
// codebar
// dataMatrix
// ean13
// ean8
// itf
// qrCode
// upcA
// upcE
// pdf417
// aztec
//
// #common
//
// code128
// code39
// code93
// dataMatrix
// itf
// qrCode
// pdf417
// aztec
//
// upcA=CodeUPCA
// upcE=CodeUPCE
// ean13=CodeEAN13
// ean8=CodeEAN8
// codebar=codabar
//



class commonTypes {

  Map<String, String> types = {
    "code128": "code128",
    "code39": "code39",
    "code93": "code93",
    "dataMatrix": "dataMatrix",
    "itf": "itf",
    "qrCode": "qrCode",
    "pdf417": "pdf417",
    "aztec": "aztec",
    "upcA": "CodeUPCA",
    "upcE": "CodeUPCE",
    "ean13": "CodeEAN13",
    "ean8": "CodeEAN8",
    "codebar": "codabar"
  };
  final bool widget;
  final String formatName;
  final List<dynamic> objFormats;
  commonTypes({this.widget=false, required this.formatName, required this.objFormats});

  getFormatIndex(){
    return objFormats.indexWhere((it){
      return types[formatName]?.toLowerCase() == it?.toString().split('.')[1].toLowerCase();
    });
  }
}