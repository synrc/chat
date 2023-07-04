  public async encryptCMS(contentEncryptionAlgorithm: Algorithm, contentToEncrypt: ArrayBuffer, crypto = common.getCrypto(true)): Promise<(void | { ecdhPrivateKey: CryptoKey; })[]> {
    //#region Initial variables
    const ivBuffer = new ArrayBuffer(16); // For AES we need IV 16 bytes long
    const ivView = new Uint8Array(ivBuffer);
    crypto.getRandomValues(ivView);

    const contentView = new Uint8Array(contentToEncrypt);
    //#endregion

    // Check for input parameters
    const contentEncryptionOID = crypto.getOIDByAlgorithm(contentEncryptionAlgorithm, true, "contentEncryptionAlgorithm");

    //#region Generate new content encryption key
    const sessionKey = await crypto.generateKey(contentEncryptionAlgorithm as AesKeyAlgorithm, true, ["encrypt"]);
    //#endregion
    //#region Encrypt content

    const encryptedContent = await crypto.encrypt({
      name: contentEncryptionAlgorithm.name,
      iv: ivView
    },
      sessionKey,
      contentView);
    //#endregion
    //#region Export raw content of content encryption key
    const exportedSessionKey = await crypto.exportKey("raw", sessionKey);

    //#endregion
    //#region Append common information to CMS_ENVELOPED_DATA
    this.version = 2;
    this.encryptedContentInfo = new EncryptedContentInfo({
      disableSplit: this.policy.disableSplit,
      contentType: "1.2.840.113549.1.7.1", // "data"
      contentEncryptionAlgorithm: new AlgorithmIdentifier({
        algorithmId: contentEncryptionOID,
        algorithmParams: new asn1js.OctetString({ valueHex: ivBuffer })
      }),
      encryptedContent: new asn1js.OctetString({ valueHex: encryptedContent })
    });
    //#endregion


    const res = [];
    //#region Create special routines for each "recipient"
    for (let i = 0; i < this.recipientInfos.length; i++) {
      switch (this.recipientInfos[i].variant) {
        case 1: // KeyTransRecipientInfo
          res.push(await SubKeyTransRecipientEncrypt(i));
          break;
        case 2: // KeyAgreeRecipientInfo
          res.push(await SubKeyAgreeRecipientEncrypt(i));
          break;
        case 3: // KEKRecipientInfo
          res.push(await SubKEKRecipientEncrypt(i));
          break;
        case 4: // PasswordRecipientinfo
          res.push(await SubPasswordRecipientEncrypt(i));
          break;
        default:
          throw new Error(`Unknown recipient type in array with index ${i}`);
      }
    }
    //#endregion
    return res;
  }

