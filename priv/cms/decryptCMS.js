  async decryptCMS(recipientIndex: number, parameters: EnvelopedDataDecryptParams, crypto = common.getCrypto(true)) {
    //#region Initial variables
    const decryptionParameters = parameters || {};
    //#endregion

    //#region Check for input parameters
    if ((recipientIndex + 1) > this.recipientInfos.length) {
      throw new Error(`Maximum value for "index" is: ${this.recipientInfos.length - 1}`);
    }
    //#endregion

    //#region Perform steps, specific to each type of session key encryption
    let unwrappedKey: CryptoKey;
    switch (this.recipientInfos[recipientIndex].variant) {
      case 1: // KeyTransRecipientInfo
        unwrappedKey = await SubKeyTransRecipientDecrypt(recipientIndex);
        break;
      case 2: // KeyAgreeRecipientInfo
        unwrappedKey = await SubKeyAgreeRecipientDecrypt(recipientIndex);
        break;
      case 3: // KEKRecipientInfo
        unwrappedKey = await SubKEKRecipientDecrypt(recipientIndex);
        break;
      case 4: // PasswordRecipientinfo
        unwrappedKey = await SubPasswordRecipientDecrypt(recipientIndex);
        break;
      default:
        throw new Error(`Unknown recipient type in array with index ${recipientIndex}`);
    }
    //#endregion

    //#region Finally decrypt data by session key
    //#region Get WebCrypto form of content encryption algorithm
    const algorithmId = this.encryptedContentInfo.contentEncryptionAlgorithm.algorithmId;
    const contentEncryptionAlgorithm = crypto.getAlgorithmByOID(algorithmId, true, "contentEncryptionAlgorithm");
    //#endregion

    //#region Get "initialization vector" for content encryption algorithm
    const ivBuffer = this.encryptedContentInfo.contentEncryptionAlgorithm.algorithmParams.valueBlock.valueHex;
    const ivView = new Uint8Array(ivBuffer);
    //#endregion

    //#region Create correct data block for decryption
    if (!this.encryptedContentInfo.encryptedContent) {
      throw new Error("Required property `encryptedContent` is empty");
    }
    const dataBuffer = this.encryptedContentInfo.getEncryptedContent();
    //#endregion

    return crypto.decrypt(
      {
        name: (contentEncryptionAlgorithm as any).name,
        iv: ivView
      },
      unwrappedKey,
      dataBuffer);
    //#endregion
  }
