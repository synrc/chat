    const SubKeyTransRecipientDecrypt = async (index: number) => {
      const recipientInfo = this.recipientInfos[index].value as KeyTransRecipientInfo; // TODO Remove `as KeyTransRecipientInfo`
      if (!decryptionParameters.recipientPrivateKey) {
        throw new Error("Parameter \"recipientPrivateKey\" is mandatory for \"KeyTransRecipientInfo\"");
      }

      const algorithmParameters = crypto.getAlgorithmByOID<any>(recipientInfo.keyEncryptionAlgorithm.algorithmId, true, "keyEncryptionAlgorithm");

      //#region RSA-OAEP case
      if (algorithmParameters.name === "RSA-OAEP") {
        const schema = recipientInfo.keyEncryptionAlgorithm.algorithmParams;
        const rsaOAEPParams = new RSAESOAEPParams({ schema });

        algorithmParameters.hash = crypto.getAlgorithmByOID(rsaOAEPParams.hashAlgorithm.algorithmId);
        if (("name" in algorithmParameters.hash) === false)
          throw new Error(`Incorrect OID for hash algorithm: ${rsaOAEPParams.hashAlgorithm.algorithmId}`);
      }
      //#endregion

      let privateKey: CryptoKey;
      let keyCrypto: SubtleCrypto = crypto;
      if (BufferSourceConverter.isBufferSource(decryptionParameters.recipientPrivateKey)) {
        privateKey = await crypto.importKey(
          "pkcs8",
          decryptionParameters.recipientPrivateKey,
          algorithmParameters,
          true,
          ["decrypt"]
        );
      } else {
        privateKey = decryptionParameters.recipientPrivateKey;
        if ("crypto" in decryptionParameters && decryptionParameters.crypto) {
          keyCrypto = decryptionParameters.crypto.subtle;
        }
      }

      const sessionKey = await keyCrypto.decrypt(
        privateKey.algorithm,
        privateKey,
        recipientInfo.encryptedKey.valueBlock.valueHexView
      );

      //#region Get WebCrypto form of content encryption algorithm
      const algorithmId = this.encryptedContentInfo.contentEncryptionAlgorithm.algorithmId;
      const contentEncryptionAlgorithm = crypto.getAlgorithmByOID(algorithmId, true, "contentEncryptionAlgorithm");
      if (("name" in contentEncryptionAlgorithm) === false)
        throw new Error(`Incorrect "contentEncryptionAlgorithm": ${algorithmId}`);
      //#endregion

      return crypto.importKey("raw",
        sessionKey,
        contentEncryptionAlgorithm,
        true,
        ["decrypt"]
      );
    };
