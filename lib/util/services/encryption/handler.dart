class EncryptionHandler {
  ///Decrypt Hex to Readable String
  static String? decodeASCII({required String? ascii}) {
    // Return an empty string if the input is null or empty
    if (ascii == null || ascii.isEmpty) {
      return null;
    }

    // Remove \x Prefix
    ascii = ascii.replaceAll(r"\x", "");

    // Bytes Buffer
    List<int> bytes = [];

    // Convert Every Two Hexadecimal Characters into a Byte
    for (int i = 0; i < ascii.length; i += 2) {
      // Hex Byte
      String hexByte = ascii.substring(i, i + 2);

      // Byte
      int byte = int.parse(hexByte, radix: 16);

      // Add Byte to Buffer
      bytes.add(byte);
    }

    // Return Readable String
    return String.fromCharCodes(bytes);
  }
}
