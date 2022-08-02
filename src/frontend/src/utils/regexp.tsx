import { Principal } from "@dfinity/principal";

const bigIntRegExp = new RegExp('^\\d+$');
const floatRegExp = new RegExp('^([0-9]*[.])?[0-9]+$');

export const isBigInt = (str: string) => {
  if (!bigIntRegExp.test(str)){
    throw Error("The input shall be a natural number");
  }
}

export const isBigIntOrNull = (str: string) => {
  if (str.length > 0 && !bigIntRegExp.test(str)){
    throw Error("The input shall be a natural number");
  }
}

export const isPositiveFloat = (str: string) => {
  if (!floatRegExp.test(str)){
    throw Error("The input shall be a positive floating point number");
  }
}

export const isPrincipal = (str: string) => {
  try {
    Principal.fromText(str);
  } catch {
    throw Error("The input shall be a principal");
  }
}

export const isPrincipalOrNull = (str: string) => {
  if (str.length > 0){
    try {
      Principal.fromText(str);
    } catch {
      throw Error("The input shall be a principal");
    }
  }  
}
