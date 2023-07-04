    //#region Special sub-functions to work with each recipient's type
    const SubKeyAgreeRecipientDecrypt = async (index: number) => {
      //#region Initial variables
      const recipientInfo = this.recipientInfos[index].value as KeyAgreeRecipientInfo; // TODO Remove `as KeyAgreeRecipientInfo`
      //#endregion

      let curveOID: string;
      let recipientCurve: string;
      let recipientCurveLength: number;
      const originator = recipientInfo.originator;

      //#region Get "namedCurve" parameter from recipient's certificate

      if (decryptionParameters.recipientCertificate) {
        const curveObject = decryptionParameters.recipientCertificate.subjectPublicKeyInfo.algorithm.algorithmParams;
        if (curveObject.constructor.blockName() !== asn1js.ObjectIdentifier.blockName()) {
          throw new Error(`Incorrect "recipientCertificate" for index ${index}`);
        }
        curveOID = curveObject.valueBlock.toString();
      } else if (originator.value.algorithm.algorithmParams) {
        const curveObject = originator.value.algorithm.algorithmParams;
        if (curveObject.constructor.blockName() !== asn1js.ObjectIdentifier.blockName()) {
          throw new Error(`Incorrect originator for index ${index}`);
        }
        curveOID = curveObject.valueBlock.toString();
      } else {
        throw new Error("Parameter \"recipientCertificate\" is mandatory for \"KeyAgreeRecipientInfo\" if algorithm params are missing from originator");
      }

      if (!decryptionParameters.recipientPrivateKey)
        throw new Error("Parameter \"recipientPrivateKey\" is mandatory for \"KeyAgreeRecipientInfo\"");

      switch (curveOID) {
        case "1.2.840.10045.3.1.7":
          recipientCurve = "P-256";
          recipientCurveLength = 256;
          break;
        case "1.3.132.0.34":
          recipientCurve = "P-384";
          recipientCurveLength = 384;
          break;
        case "1.3.132.0.35":
          recipientCurve = "P-521";
          recipientCurveLength = 528;
          break;
        default:
          throw new Error(`Incorrect curve OID for index ${index}`);
      }

      let ecdhPrivateKey: CryptoKey;
      let keyCrypto: SubtleCrypto = crypto;
      if (BufferSourceConverter.isBufferSource(decryptionParameters.recipientPrivateKey)) {
        ecdhPrivateKey = await crypto.importKey("pkcs8",
          decryptionParameters.recipientPrivateKey,
          {
            name: "ECDH",
            namedCurve: recipientCurve
          } as EcKeyImportParams,
          true,
          ["deriveBits"]
        );
      } else {
        ecdhPrivateKey = decryptionParameters.recipientPrivateKey;
        if ("crypto" in decryptionParameters && decryptionParameters.crypto) {
          keyCrypto = decryptionParameters.crypto.subtle;
        }
      }
      //#endregion
      //#region Import sender's ephemeral public key
      //#region Change "OriginatorPublicKey" if "curve" parameter absent
      if (("algorithmParams" in originator.value.algorithm) === false)
        originator.value.algorithm.algorithmParams = new asn1js.ObjectIdentifier({ value: curveOID });
      //#endregion

      //#region Create ArrayBuffer with sender's public key
      const buffer = originator.value.toSchema().toBER(false);
      //#endregion

      const ecdhPublicKey = await crypto.importKey("spki",
        buffer,
        {
          name: "ECDH",
          namedCurve: recipientCurve
        } as EcKeyImportParams,
        true,
        []);

      //#endregion
      //#region Create shared secret
      const sharedSecret = await keyCrypto.deriveBits({
        name: "ECDH",
        public: ecdhPublicKey
      },
        ecdhPrivateKey,
        recipientCurveLength);
      //#endregion
      //#region Apply KDF function to shared secret
      async function applyKDF(includeAlgorithmParams?: boolean) {
        includeAlgorithmParams = includeAlgorithmParams || false;

        //#region Get length of used AES-KW algorithm
        const aesKWAlgorithm = new AlgorithmIdentifier({ schema: recipientInfo.keyEncryptionAlgorithm.algorithmParams });

        const kwAlgorithm = crypto.getAlgorithmByOID<any>(aesKWAlgorithm.algorithmId, true, "kwAlgorithm");
        //#endregion

        //#region Translate AES-KW length to ArrayBuffer
        let kwLength = kwAlgorithm.length;

        const kwLengthBuffer = new ArrayBuffer(4);
        const kwLengthView = new Uint8Array(kwLengthBuffer);

        for (let j = 3; j >= 0; j--) {
          kwLengthView[j] = kwLength;
          kwLength >>= 8;
        }
        //#endregion

        //#region Create and encode "ECC-CMS-SharedInfo" structure
        const keyInfoAlgorithm: AlgorithmIdentifierParameters = {
          algorithmId: aesKWAlgorithm.algorithmId
        };
        if (includeAlgorithmParams) {
          keyInfoAlgorithm.algorithmParams = new asn1js.Null();
        }
        const eccInfo = new ECCCMSSharedInfo({
          keyInfo: new AlgorithmIdentifier(keyInfoAlgorithm),
          entityUInfo: recipientInfo.ukm,
          suppPubInfo: new asn1js.OctetString({ valueHex: kwLengthBuffer })
        });

        const encodedInfo = eccInfo.toSchema().toBER(false);
        //#endregion

        //#region Get SHA algorithm used together with ECDH
        const ecdhAlgorithm = crypto.getAlgorithmByOID<any>(recipientInfo.keyEncryptionAlgorithm.algorithmId, true, "ecdhAlgorithm");
        if (!ecdhAlgorithm.name) {
          throw new Error(`Incorrect OID for key encryption algorithm: ${recipientInfo.keyEncryptionAlgorithm.algorithmId}`);
        }
        //#endregion

        return common.kdf(ecdhAlgorithm.kdf, sharedSecret, kwAlgorithm.length, encodedInfo, crypto);
      }

      const kdfResult = await applyKDF();
      //#endregion
      //#region Import AES-KW key from result of KDF function
      const importAesKwKey = async (kdfResult: ArrayBuffer) => {
        return crypto.importKey("raw",
          kdfResult,
          { name: "AES-KW" },
          true,
          ["unwrapKey"]
        );
      };

      const aesKwKey = await importAesKwKey(kdfResult);

      //#endregion
      //#region Finally unwrap session key
      const unwrapSessionKey = async (aesKwKey: CryptoKey) => {
        //#region Get WebCrypto form of content encryption algorithm
        const algorithmId = this.encryptedContentInfo.contentEncryptionAlgorithm.algorithmId;
        const contentEncryptionAlgorithm = crypto.getAlgorithmByOID<any>(algorithmId, true, "contentEncryptionAlgorithm");
        //#endregion

        return crypto.unwrapKey("raw",
          recipientInfo.recipientEncryptedKeys.encryptedKeys[0].encryptedKey.valueBlock.valueHexView,
          aesKwKey,
          { name: "AES-KW" },
          contentEncryptionAlgorithm,
          true,
          ["decrypt"]);
      };

      try {
        return await unwrapSessionKey(aesKwKey);
      } catch {
        const kdfResult = await applyKDF(true);
        const aesKwKey = await importAesKwKey(kdfResult);
        return unwrapSessionKey(aesKwKey);
      }
    };
    //#endregion
