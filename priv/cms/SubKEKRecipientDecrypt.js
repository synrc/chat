    const SubKEKRecipientDecrypt = async (index: number) => {
      //#region Initial variables
      const recipientInfo = this.recipientInfos[index].value as KEKRecipientInfo; // TODO Remove `as KEKRecipientInfo`
      //#endregion

      //#region Import KEK from pre-defined data
      if (!decryptionParameters.preDefinedData)
        throw new Error("Parameter \"preDefinedData\" is mandatory for \"KEKRecipientInfo\"");

      //#region Get WebCrypto form of "keyEncryptionAlgorithm"
      const kekAlgorithm = crypto.getAlgorithmByOID<any>(recipientInfo.keyEncryptionAlgorithm.algorithmId, true, "kekAlgorithm");
      //#endregion

      const importedKey = await crypto.importKey("raw",
        decryptionParameters.preDefinedData,
        kekAlgorithm,
        true,
        ["unwrapKey"]); // Too specific for AES-KW

      //#endregion
      //#region Unwrap previously exported session key
      //#region Get WebCrypto form of content encryption algorithm
      const algorithmId = this.encryptedContentInfo.contentEncryptionAlgorithm.algorithmId;
      const contentEncryptionAlgorithm = crypto.getAlgorithmByOID<any>(algorithmId, true, "contentEncryptionAlgorithm");
      if (!contentEncryptionAlgorithm.name) {
        throw new Error(`Incorrect "contentEncryptionAlgorithm": ${algorithmId}`);
      }
      //#endregion

      return crypto.unwrapKey("raw",
        recipientInfo.encryptedKey.valueBlock.valueHexView,
        importedKey,
        kekAlgorithm,
        contentEncryptionAlgorithm,
        true,
        ["decrypt"]);
      //#endregion
    };
