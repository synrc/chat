    const SubPasswordRecipientEncrypt = async (index: number) => {
      //#region Initial variables
      const recipientInfo = this.recipientInfos[index].value as PasswordRecipientinfo; // TODO Remove `as PasswordRecipientinfo`
      let pbkdf2Params: PBKDF2Params;
      //#endregion

      //#region Check that we have encoded "keyDerivationAlgorithm" plus "PBKDF2_params" in there

      if (!recipientInfo.keyDerivationAlgorithm)
        throw new Error("Please append encoded \"keyDerivationAlgorithm\"");

      if (!recipientInfo.keyDerivationAlgorithm.algorithmParams)
        throw new Error("Incorrectly encoded \"keyDerivationAlgorithm\"");

      try {
        pbkdf2Params = new PBKDF2Params({ schema: recipientInfo.keyDerivationAlgorithm.algorithmParams });
      }
      catch (ex) {
        throw new Error("Incorrectly encoded \"keyDerivationAlgorithm\"");
      }

      //#endregion
      //#region Derive PBKDF2 key from "password" buffer
      const passwordView = new Uint8Array(recipientInfo.password);

      const derivationKey = await crypto.importKey("raw",
        passwordView,
        "PBKDF2",
        false,
        ["deriveKey"]);
      //#endregion
      //#region Derive key for "keyEncryptionAlgorithm"
      //#region Get WebCrypto form of "keyEncryptionAlgorithm"
      const kekAlgorithm = crypto.getAlgorithmByOID<any>(recipientInfo.keyEncryptionAlgorithm.algorithmId, true, "kekAlgorithm");

      //#endregion

      //#region Get HMAC hash algorithm
      let hmacHashAlgorithm = "SHA-1";

      if (pbkdf2Params.prf) {
        const prfAlgorithm = crypto.getAlgorithmByOID<any>(pbkdf2Params.prf.algorithmId, true, "prfAlgorithm");
        hmacHashAlgorithm = prfAlgorithm.hash.name;
      }
      //#endregion

      //#region Get PBKDF2 "salt" value
      const saltView = new Uint8Array(pbkdf2Params.salt.valueBlock.valueHex);
      //#endregion

      //#region Get PBKDF2 iterations count
      const iterations = pbkdf2Params.iterationCount;
      //#endregion

      const derivedKey = await crypto.deriveKey({
        name: "PBKDF2",
        hash: {
          name: hmacHashAlgorithm
        },
        salt: saltView,
        iterations
      },
        derivationKey,
        kekAlgorithm,
        true,
        ["wrapKey"]); // Usages are too specific for KEK algorithm

      //#endregion
      //#region Wrap previously exported session key (Also too specific for KEK algorithm)
      const wrappedKey = await crypto.wrapKey("raw", sessionKey, derivedKey, kekAlgorithm);
      //#endregion
      //#region Append all necessary data to current CMS_RECIPIENT_INFO object
      //#region RecipientEncryptedKey
      recipientInfo.encryptedKey = new asn1js.OctetString({ valueHex: wrappedKey });
      //#endregion
      //#endregion
    };

    //#endregion
