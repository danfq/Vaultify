import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/asn1.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vaultify/util/services/account/handler.dart';

///Encryption Handler
class EncryptionHandler {
  ///Flutter Secure Storage
  static const _secureStorage = FlutterSecureStorage();

  ///Public Key
  static Future<String?> get publicKey async =>
      await _secureStorage.read(key: "publicKey") ??
      await publicKeyFromServer();

  ///Private Key
  static Future<String?> get privateKey async =>
      await _secureStorage.read(key: "privateKey");

  ///Get Public Key from Server
  static Future<String?> publicKeyFromServer() async {
    //Get User
    final supabaseUser = AccountHandler.currentUser;
    final cachedUser = AccountHandler.cachedUser;

    //Return Public Key
    return supabaseUser != null
        ? supabaseUser.userMetadata!["public_key"]
        : cachedUser["public_key"];
  }

  ///Import Key
  static Future<void> importKey({required File file}) async {
    //Read File
    final bytes = await file.readAsBytes();

    //Convert bytes to string
    final pemString = String.fromCharCodes(bytes);

    //Validate and parse private key
    try {
      await _secureStorage.write(key: "privateKey", value: pemString);
    } catch (e) {
      throw Exception('Invalid private key format: $e');
    }
  }

  ///Export Key
  static Future<bool> exportKey() async {
    try {
      //Request Permissions for Android
      if (Platform.isAndroid) {
        //Permission Status
        final status = await Permission.storage.status;

        //Check if Permission is Granted
        if (!status.isGranted) {
          //Request Permission
          final result = await Permission.storage.request();

          //Check if Permission is Granted
          if (!result.isGranted) {
            throw Exception("Storage permission denied");
          }
        }
      }

      //Private Key
      final privateKey = await _secureStorage.read(key: "privateKey");

      //Check if Private Key is Null or Empty
      if (privateKey == null || privateKey.isEmpty) {
        throw Exception("No Private Key Found");
      }

      //Bytes
      final bytes = utf8.encode(privateKey);

      //Check if Bytes are Empty
      if (bytes.isEmpty) {
        throw Exception("Failed to Encode Private Key: Empty Bytes");
      }

      String path;
      if (Platform.isAndroid) {
        path = await _saveFileAndroid();
      } else if (Platform.isIOS) {
        path = await _saveFileIOS();
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        path = (await _saveFileDesktop()) ?? "";
      } else {
        throw Exception("Platform Not Supported");
      }

      debugPrint("Save location selected: $path");

      //Write Bytes to File
      final file = await File(path).writeAsBytes(bytes);

      //Check if File was Saved
      if (!await file.exists()) {
        throw Exception("Failed to Save Private Key: File Does Not Exist");
      }

      //Return True
      return true;
    } catch (error) {
      throw Exception("Error Exporting Private Key: $error");
    }
  }

  ///Save File on Android
  static Future<String> _saveFileAndroid() async {
    //Directory
    final directory = await getApplicationDocumentsDirectory();

    //Check if Directory Exists
    if (!await directory.exists()) {
      //Create Directory
      await directory.create(recursive: true);
    }

    //Path
    final path = "${directory.path}/Vaultify_Private_Key.pem";

    //Return Path
    return path;
  }

  ///Save File on iOS
  static Future<String> _saveFileIOS() async {
    //Directory
    final directory = await getApplicationDocumentsDirectory();

    //Path
    final path = "${directory.path}/Vaultify_Private_Key.pem";

    //Return Path
    return path;
  }

  ///Save File on Desktop Platforms
  static Future<String?> _saveFileDesktop() async {
    return await FilePicker.platform.saveFile(
      dialogTitle: "Choose Where to Save Private Key",
      fileName: "Vaultify_Private_Key.pem",
      type: FileType.custom,
      allowedExtensions: ["pem"],
      lockParentWindow: true,
    );
  }

  ///Encrypt Message
  static Future<String> encryptPassword({
    required String message,
    required RSAPublicKey publicKey,
  }) async {
    //Encryptor
    final encryptor = RSAEngine();

    //Init Encryptor
    encryptor.init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    //Encrypt Message
    final encrypted = encryptor.process(
      Uint8List.fromList(utf8.encode(message)),
    );

    //Return Encrypted Message
    return base64.encode(encrypted);
  }

  ///Decrypt Message
  static Future<String> decryptPassword({
    required String encryptedMessage,
    required RSAPrivateKey privateKey,
  }) async {
    try {
      //Decryptor
      final decryptor = RSAEngine();

      //Init Decryptor
      decryptor.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

      //Decrypt Message
      final decrypted = decryptor.process(base64.decode(encryptedMessage));

      //Return Decrypted Message
      return utf8.decode(decrypted);
    } catch (e) {
      debugPrint("Decryption error: $e");
      throw Exception("Failed to decrypt message: $e");
    }
  }

  ///Save Key Pair Securely
  static Future<void> saveKeyPairSecurely({
    required String publicKey,
    required String privateKey,
  }) async {
    await _secureStorage.write(key: "publicKey", value: publicKey);
    await _secureStorage.write(key: "privateKey", value: privateKey);
  }

  ///Get Key Pair Securely
  static Future<Map<String, String>> getKeyPairSecurely() async {
    //Public Key
    final publicKey = await _secureStorage.read(key: "publicKey");

    //Private Key
    final privateKey = await _secureStorage.read(key: "privateKey");

    //Return Keys
    return {
      "publicKey": publicKey ?? "",
      "privateKey": privateKey ?? "",
    };
  }

  ///Generate Key Pair
  static Future<Map<String, String>> generateKeyPair() async {
    //Secure Random Number
    final secureRandom = FortunaRandom();

    //Seed
    final seedSource = Random.secure();

    //Seeds
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(255));

    //Seed Secure Random
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    //RSA Key Parameters
    final keyParams = RSAKeyGeneratorParameters(
      BigInt.parse("65537"),
      2048,
      64,
    );

    //Parameters With Random
    final paramGen = ParametersWithRandom(keyParams, secureRandom);

    //Key Generator
    final keyGenerator = KeyGenerator('RSA');
    keyGenerator.init(paramGen);

    //Key Pair
    final pair = keyGenerator.generateKeyPair();

    //Keys
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;

    //Public Key PEM
    final publicKeyPem = encodePublicKeyToPem(publicKey);

    //Private Key PEM
    final privateKeyPem = encodePrivateKeyToPem(privateKey);

    //Return Keys
    return {
      "publicKey": publicKeyPem,
      "privateKey": privateKeyPem,
    };
  }

  ///Encode RSA Public Key to PEM format
  static String encodePublicKeyToPem(RSAPublicKey publicKey) {
    //ASN1 Sequence
    var topLevel = ASN1Sequence();
    topLevel.add(ASN1Integer(publicKey.modulus!));
    topLevel.add(ASN1Integer(publicKey.exponent!));

    //Encode ASN1 Sequence
    var dataBase64 = base64.encode(topLevel.encode());

    //Format with PEM Header and Footer
    return '''-----BEGIN PUBLIC KEY-----\n$dataBase64\n-----END PUBLIC KEY-----''';
  }

  ///Encode RSA Private Key to PEM format
  static String encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    //ASN1 Sequence
    var topLevel = ASN1Sequence();

    //Add All Private Key Components
    topLevel.add(ASN1Integer(BigInt.from(0))); // Version
    topLevel.add(ASN1Integer(privateKey.modulus!));
    topLevel.add(ASN1Integer(privateKey.exponent!));
    topLevel.add(ASN1Integer(privateKey.privateExponent!));
    topLevel.add(ASN1Integer(privateKey.p!));
    topLevel.add(ASN1Integer(privateKey.q!));
    topLevel.add(
      ASN1Integer(privateKey.privateExponent! % (privateKey.p! - BigInt.one)),
    );
    topLevel.add(
      ASN1Integer(privateKey.privateExponent! % (privateKey.q! - BigInt.one)),
    );
    topLevel.add(ASN1Integer(privateKey.q!.modInverse(privateKey.p!)));

    //Encode ASN1 Sequence
    var dataBase64 = base64.encode(topLevel.encode());

    //Format with PEM Header and Footer
    return '''-----BEGIN RSA PRIVATE KEY-----\n$dataBase64\n-----END RSA PRIVATE KEY-----''';
  }

  ///PEM to Public Key
  static RSAPublicKey pemToPublicKey(String pemString) {
    if (pemString.isEmpty) {
      throw Exception("Public key PEM string is empty");
    }

    try {
      //Remove Headers & Footers
      final rows = pemString.split('\n');
      final key = rows
          .where(
              (row) => !row.contains("-----BEGIN") && !row.contains("-----END"))
          .join("");

      if (key.isEmpty) {
        throw Exception("Invalid public key format");
      }

      //Decode Base64
      final bytes = base64.decode(key);
      if (bytes.isEmpty) {
        throw Exception("Invalid base64 encoding");
      }

      final asn1Parser = ASN1Parser(bytes);
      final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

      //Extract Modulus & Exponent
      final modulus = (topLevelSeq.elements![0] as ASN1Integer).integer;
      final exponent = (topLevelSeq.elements![1] as ASN1Integer).integer;

      if (modulus == null || exponent == null) {
        throw Exception("Invalid RSA key components");
      }

      //Return Public Key
      return RSAPublicKey(modulus, exponent);
    } catch (e) {
      debugPrint("Error parsing public key: $e");
      throw Exception("Failed to parse public key: $e");
    }
  }

  ///PEM to Private Key
  static RSAPrivateKey pemToPrivateKey(String pemString) {
    try {
      final rows = pemString.split("\n");
      final key = rows
          .where(
              (row) => !row.contains("-----BEGIN") && !row.contains("-----END"))
          .join("");

      final bytes = base64.decode(key);
      final asn1Parser = ASN1Parser(bytes);
      final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

      // Extract Components
      final modulus = (topLevelSeq.elements![1] as ASN1Integer).integer!;
      final privateExponent =
          (topLevelSeq.elements![3] as ASN1Integer).integer!;
      final p = (topLevelSeq.elements![4] as ASN1Integer).integer!;
      final q = (topLevelSeq.elements![5] as ASN1Integer).integer!;

      // Return Private Key
      return RSAPrivateKey(modulus, privateExponent, p, q);
    } catch (e) {
      debugPrint("Error parsing private key: $e");
      throw Exception("Failed to parse private key: $e");
    }
  }
}
