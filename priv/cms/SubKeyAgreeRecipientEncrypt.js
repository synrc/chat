    //#region Special sub-functions to work with each recipient's type
    const SubKeyAgreeRecipientEncrypt = async (index: number) => {
      //#region Initial variables
      const recipientInfo = this.recipientInfos[index].value as KeyAgreeRecipientInfo;
      let recipientCurve: string;
      //#endregion

      //#region Get public key and named curve from recipient's certificate or public key
      let recipientPublicKey: CryptoKey;
      if (recipientInfo.recipientPublicKey) {
        recipientCurve = (recipientInfo.recipientPublicKey.algorithm as EcKeyAlgorithm).namedCurve;
        recipientPublicKey = recipientInfo.recipientPublicKey;
      } else if (recipientInfo.recipientCertificate) {
        const curveObject = recipientInfo.recipientCertificate.subjectPublicKeyInfo.algorithm.algorithmParams;

        if (curveObject.constructor.blockName() !== asn1js.ObjectIdentifier.blockName())
          throw new Error(`Incorrect "recipientCertificate" for index ${index}`);

        const curveOID = curveObject.valueBlock.toString();

        switch (curveOID) {
          case "1.2.840.10045.3.1.7":
            recipientCurve = "P-256";
            break;
          case "1.3.132.0.34":
            recipientCurve = "P-384";
            break;
          case "1.3.132.0.35":
            recipientCurve = "P-521";
            break;
          default:
            throw new Error(`Incorrect curve OID for index ${index}`);
        }

        recipientPublicKey = await recipientInfo.recipientCertificate.getPublicKey({
          algorithm: {
            algorithm: {
              name: "ECDH",
              namedCurve: recipientCurve
            } as EcKeyAlgorithm,
            usages: []
          }
        }, crypto);
      } else {
        throw new Error("Unsupported RecipientInfo");
      }
      //#endregion

      //#region Generate ephemeral ECDH key
      const recipientCurveLength = curveLengthByName[recipientCurve];

      const ecdhKeys = await crypto.generateKey(
        { name: "ECDH", namedCurve: recipientCurve } as EcKeyGenParams,
        true,
        ["deriveBits"]
      );
      //#endregion
      //#region Export public key of ephemeral ECDH key pair

      const exportedECDHPublicKey = await crypto.exportKey("spki", ecdhKeys.publicKey);
      //#endregion

      //#region Create shared secret
      const derivedBits = await crypto.deriveBits({
        name: "ECDH",
        public: recipientPublicKey
      },
        ecdhKeys.privateKey,
        recipientCurveLength);
      //#endregion

      //#region Apply KDF function to shared secret

      //#region Get length of used AES-KW algorithm
      const aesKWAlgorithm = new AlgorithmIdentifier({ schema: recipientInfo.keyEncryptionAlgorithm.algorithmParams });

      const kwAlgorithm = crypto.getAlgorithmByOID<AesKeyAlgorithm>(aesKWAlgorithm.algorithmId, true, "aesKWAlgorithm");
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
      const eccInfo = new ECCCMSSharedInfo({
        keyInfo: new AlgorithmIdentifier({
          algorithmId: aesKWAlgorithm.algorithmId
        }),
        entityUInfo: (recipientInfo as KeyAgreeRecipientInfo).ukm, // TODO remove `as KeyAgreeRecipientInfo`
        suppPubInfo: new asn1js.OctetString({ valueHex: kwLengthBuffer })
      });

      const encodedInfo = eccInfo.toSchema().toBER(false);
      //#endregion

      //#region Get SHA algorithm used together with ECDH
      const ecdhAlgorithm = crypto.getAlgorithmByOID<any>(recipientInfo.keyEncryptionAlgorithm.algorithmId, true, "ecdhAlgorithm");
      //#endregion

      const derivedKeyRaw = await common.kdf(ecdhAlgorithm.kdf, derivedBits, kwAlgorithm.length, encodedInfo, crypto);
      //#endregion
      //#region Import AES-KW key from result of KDF function
      const awsKW = await crypto.importKey("raw", derivedKeyRaw, { name: "AES-KW" }, true, ["wrapKey"]);
      //#endregion
      //#region Finally wrap session key by using AES-KW algorithm
      const wrappedKey = await crypto.wrapKey("raw", sessionKey, awsKW, { name: "AES-KW" });
      //#endregion
      //#region Append all necessary data to current CMS_RECIPIENT_INFO object
      //#region OriginatorIdentifierOrKey
      const originator = new OriginatorIdentifierOrKey();
      originator.variant = 3;
      originator.value = OriginatorPublicKey.fromBER(exportedECDHPublicKey);

      recipientInfo.originator = originator;
      //#endregion

      //#region RecipientEncryptedKey
      /*
       We will not support using of same ephemeral key for many recipients
       */
      recipientInfo.recipientEncryptedKeys.encryptedKeys[0].encryptedKey = new asn1js.OctetString({ valueHex: wrappedKey });
      //#endregion

      return { ecdhPrivateKey: ecdhKeys.privateKey };
      //#endregion
    };
