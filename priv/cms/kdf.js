/**
 * ANS X9.63 Key Derivation Function having a "Counter" as a parameter
 * @param hashFunction Used hash function
 * @param zBuffer ArrayBuffer containing ECDH shared secret to derive from
 * @param Counter
 * @param SharedInfo Usually DER encoded "ECC_CMS_SharedInfo" structure
 * @param crypto Crypto engine
 */
async function kdfWithCounter(hashFunction: string, zBuffer: ArrayBuffer, Counter: number, SharedInfo: ArrayBuffer, crypto: ICryptoEngine): Promise<{ counter: number; result: ArrayBuffer; }> {
  //#region Check of input parameters
  switch (hashFunction.toUpperCase()) {
    case "SHA-1":
    case "SHA-256":
    case "SHA-384":
    case "SHA-512":
      break;
    default:
      throw new ArgumentError(`Unknown hash function: ${hashFunction}`);
  }

  ArgumentError.assert(zBuffer, "zBuffer", "ArrayBuffer");
  if (zBuffer.byteLength === 0)
    throw new ArgumentError("'zBuffer' has zero length, error");

  ArgumentError.assert(SharedInfo, "SharedInfo", "ArrayBuffer");
  if (Counter > 255)
    throw new ArgumentError("Please set 'Counter' argument to value less or equal to 255");
  //#endregion

  //#region Initial variables
  const counterBuffer = new ArrayBuffer(4);
  const counterView = new Uint8Array(counterBuffer);
  counterView[0] = 0x00;
  counterView[1] = 0x00;
  counterView[2] = 0x00;
  counterView[3] = Counter;

  let combinedBuffer = EMPTY_BUFFER;
  //#endregion

  //#region Create a combined ArrayBuffer for digesting
  combinedBuffer = pvutils.utilConcatBuf(combinedBuffer, zBuffer);
  combinedBuffer = pvutils.utilConcatBuf(combinedBuffer, counterBuffer);
  combinedBuffer = pvutils.utilConcatBuf(combinedBuffer, SharedInfo);
  //#endregion

  //#region Return digest of combined ArrayBuffer and information about current counter
  const result = await crypto.digest(
    { name: hashFunction },
    combinedBuffer);

  return {
    counter: Counter,
    result
  };
  //#endregion
}

/**
 * ANS X9.63 Key Derivation Function
 * @param hashFunction Used hash function
 * @param Zbuffer ArrayBuffer containing ECDH shared secret to derive from
 * @param keydatalen Length (!!! in BITS !!!) of used kew derivation function
 * @param SharedInfo Usually DER encoded "ECC_CMS_SharedInfo" structure
 * @param crypto Crypto engine
 */
export async function kdf(hashFunction: string, Zbuffer: ArrayBuffer, keydatalen: number, SharedInfo: ArrayBuffer, crypto = getCrypto(true)) {
  //#region Initial variables
  let hashLength = 0;
  let maxCounter = 1;
  //#endregion

  //#region Check of input parameters
  switch (hashFunction.toUpperCase()) {
    case "SHA-1":
      hashLength = 160; // In bits
      break;
    case "SHA-256":
      hashLength = 256; // In bits
      break;
    case "SHA-384":
      hashLength = 384; // In bits
      break;
    case "SHA-512":
      hashLength = 512; // In bits
      break;
    default:
      throw new ArgumentError(`Unknown hash function: ${hashFunction}`);
  }

  ArgumentError.assert(Zbuffer, "Zbuffer", "ArrayBuffer");
  if (Zbuffer.byteLength === 0)
    throw new ArgumentError("'Zbuffer' has zero length, error");
  ArgumentError.assert(SharedInfo, "SharedInfo", "ArrayBuffer");
  //#endregion

  //#region Calculated maximum value of "Counter" variable
  const quotient = keydatalen / hashLength;

  if (Math.floor(quotient) > 0) {
    maxCounter = Math.floor(quotient);

    if ((quotient - maxCounter) > 0)
      maxCounter++;
  }
  //#endregion

  //#region Create an array of "kdfWithCounter"
  const incomingResult = [];
  for (let i = 1; i <= maxCounter; i++)
    incomingResult.push(await kdfWithCounter(hashFunction, Zbuffer, i, SharedInfo, crypto));
  //#endregion

  //#region Return combined digest with specified length
  //#region Initial variables
  let combinedBuffer = EMPTY_BUFFER;
  let currentCounter = 1;
  let found = true;
  //#endregion

  //#region Combine all buffer together
  while (found) {
    found = false;

    for (const result of incomingResult) {
      if (result.counter === currentCounter) {
        combinedBuffer = pvutils.utilConcatBuf(combinedBuffer, result.result);
        found = true;
        break;
      }
    }

    currentCounter++;
  }
  //#endregion

  //#region Create output buffer with specified length
  keydatalen >>= 3; // Divide by 8 since "keydatalen" is in bits

  if (combinedBuffer.byteLength > keydatalen) {
    const newBuffer = new ArrayBuffer(keydatalen);
    const newView = new Uint8Array(newBuffer);
    const combinedView = new Uint8Array(combinedBuffer);

    for (let i = 0; i < keydatalen; i++)
      newView[i] = combinedView[i];

    return newBuffer;
  }

  return combinedBuffer; // Since the situation when "combinedBuffer.byteLength < keydatalen" here we have only "combinedBuffer.byteLength === keydatalen"
  //#endregion
  //#endregion
}
//#endregion
