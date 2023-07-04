    const SubKEKRecipientEncrypt = async (index: number) => {
      //#region Initial variables
      const recipientInfo = this.recipientInfos[index].value as KEKRecipientInfo; // TODO Remove `as KEKRecipientInfo`
      //#endregion

      //#region Import KEK from pre-defined data

      //#region Get WebCrypto form of "keyEncryptionAlgorithm"
      const kekAlgorithm = crypto.getAlgorithmByOID(recipientInfo.keyEncryptionAlgorithm.algorithmId, true, "kekAlgorithm");
      //#endregion

      const kekKey = await crypto.importKey("raw",
        new Uint8Array(recipientInfo.preDefinedKEK),
        kekAlgorithm,
        true,
        ["wrapKey"]); // Too specific for AES-KW
      //#endregion

      //#region Wrap previously exported session key

      const wrappedKey = await crypto.wrapKey("raw", sessionKey, kekKey, kekAlgorithm);
      //#endregion
      //#region Append all necessary data to current CMS_RECIPIENT_INFO object
      //#region RecipientEncryptedKey
      recipientInfo.encryptedKey = new asn1js.OctetString({ valueHex: wrappedKey });
      //#endregion
      //#endregion
    };
