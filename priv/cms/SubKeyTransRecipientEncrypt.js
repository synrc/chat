    const SubKeyTransRecipientEncrypt = async (index: number) => {
      const recipientInfo = this.recipientInfos[index].value as KeyTransRecipientInfo; // TODO Remove `as KeyTransRecipientInfo`
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

      try {
        const publicKey = await recipientInfo.recipientCertificate.getPublicKey({
          algorithm: {
            algorithm: algorithmParameters,
            usages: ["encrypt", "wrapKey"]
          }
        }, crypto);

        const encryptedKey = await crypto.encrypt(publicKey.algorithm, publicKey, exportedSessionKey);

        //#region RecipientEncryptedKey
        recipientInfo.encryptedKey = new asn1js.OctetString({ valueHex: encryptedKey });
        //#endregion
      }
      catch {
        // nothing
      }
    };
