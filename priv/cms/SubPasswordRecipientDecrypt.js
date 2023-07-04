    const SubPasswordRecipientDecrypt = async (index: number) => {
      //#region Initial variables
      const recipientInfo = this.recipientInfos[index].value as PasswordRecipientinfo; // TODO Remove `as PasswordRecipientinfo`
      let pbkdf2Params: PBKDF2Params;
      //#endregion

      //#region Derive PBKDF2 key from "password" buffer

      if (!decryptionParameters.preDefinedData) {
        throw new Error("Parameter \"preDefinedData\" is mandatory for \"KEKRecipientInfo\"");
      }

      if (!recipientInfo.keyDerivationAlgorithm) {
        throw new Error("Please append encoded \"keyDerivationAlgorithm\"");
      }

      if (!recipientInfo.keyDerivationAlgorithm.algorithmParams) {
        throw new Error("Incorrectly encoded \"keyDerivationAlgorithm\"");
      }

      try {
        pbkdf2Params = new PBKDF2Params({ schema: recipientInfo.keyDerivationAlgorithm.algorithmParams });
      }
      catch (ex) {
        throw new Error("Incorrectly encoded \"keyDerivationAlgorithm\"");
      }

      const pbkdf2Key = await crypto.importKey("raw",
        decryptionParameters.preDefinedData,
        "PBKDF2",
        false,
        ["deriveKey"]);
      //#endregion
      //#region Derive key for "keyEncryptionAlgorithm"
      //#region Get WebCrypto form of "keyEncryptionAlgorithm"
      const kekAlgorithm = crypto.getAlgorithmByOID<any>(recipientInfo.keyEncryptionAlgorithm.algorithmId, true, "keyEncryptionAlgorithm");
      //#endregion

      // Get HMAC hash algorithm
      const hmacHashAlgorithm = pbkdf2Params.prf
        ? crypto.getAlgorithmByOID<any>(pbkdf2Params.prf.algorithmId, true, "prfAlgorithm").hash.name
        : "SHA-1";

      //#region Get PBKDF2 "salt" value
      const saltView = new Uint8Array(pbkdf2Params.salt.valueBlock.valueHex);
      //#endregion

      //#region Get PBKDF2 iterations count
      const iterations = pbkdf2Params.iterationCount;
      //#endregion

      const kekKey = await crypto.deriveKey({
        name: "PBKDF2",
        hash: {
          name: hmacHashAlgorithm
        },
        salt: saltView,
        iterations
      },
        pbkdf2Key,
        kekAlgorithm,
        true,
        ["unwrapKey"]); // Usages are too specific for KEK algorithm
      //#endregion
      //#region Unwrap previously exported session key
      //#region Get WebCrypto form of content encryption algorithm
      const algorithmId = this.encryptedContentInfo.contentEncryptionAlgorithm.algorithmId;
      const contentEncryptionAlgorithm = crypto.getAlgorithmByOID<any>(algorithmId, true, "contentEncryptionAlgorithm");
      //#endregion

      return crypto.unwrapKey("raw",
        recipientInfo.encryptedKey.valueBlock.valueHexView,
        kekKey,
        kekAlgorithm,
        contentEncryptionAlgorithm,
        true,
        ["decrypt"]);
      //#endregion
    };
