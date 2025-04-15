// main index.js

import { NativeModules, NativeEventEmitter } from "react-native";

const { ReactNativeBrotherPrinters } = NativeModules || {};

export const LabelSizeDieCutW17H54 = 0;
export const LabelSizeDieCutW17H87 = 1;
export const LabelSizeDieCutW23H23 = 2;
export const LabelSizeDieCutW29H42 = 3;
export const LabelSizeDieCutW29H90 = 4;
export const LabelSizeDieCutW38H90 = 5;
export const LabelSizeDieCutW39H48 = 6;
export const LabelSizeDieCutW52H29 = 7;
export const LabelSizeDieCutW62H29 = 8;
export const LabelSizeDieCutW62H100 = 9;
export const LabelSizeDieCutW60H86 = 10;
export const LabelSizeDieCutW54H29 = 11;
export const LabelSizeDieCutW102H51 = 12;
export const LabelSizeDieCutW102H152 = 13;
export const LabelSizeDieCutW103H164 = 14;
export const LabelSizeRollW12 = 15;
export const LabelSizeRollW29 = 16;
export const LabelSizeRollW38 = 17;
export const LabelSizeRollW50 = 18;
export const LabelSizeRollW54 = 19;
export const LabelSizeRollW62 = 20;
export const LabelSizeRollW62RB = 21;
export const LabelSizeRollW102 = 22;
export const LabelSizeRollW103 = 23;
export const LabelSizeDTRollW90 = 24;
export const LabelSizeDTRollW102 = 25;
export const LabelSizeDTRollW102H51 = 26;
export const LabelSizeDTRollW102H152 = 27;

export const LabelSize = {
  LabelSizeDieCutW17H54,
  LabelSizeDieCutW17H87,
  LabelSizeDieCutW23H23,
  LabelSizeDieCutW29H42,
  LabelSizeDieCutW29H90,
  LabelSizeDieCutW38H90,
  LabelSizeDieCutW39H48,
  LabelSizeDieCutW52H29,
  LabelSizeDieCutW62H29,
  LabelSizeDieCutW62H100,
  LabelSizeDieCutW60H86,
  LabelSizeDieCutW54H29,
  LabelSizeDieCutW102H51,
  LabelSizeDieCutW102H152,
  LabelSizeDieCutW103H164,
  LabelSizeRollW12,
  LabelSizeRollW29,
  LabelSizeRollW38,
  LabelSizeRollW50,
  LabelSizeRollW54,
  LabelSizeRollW62,
  LabelSizeRollW62RB,
  LabelSizeRollW102,
  LabelSizeRollW103,
  LabelSizeDTRollW90,
  LabelSizeDTRollW102,
  LabelSizeDTRollW102H51,
  LabelSizeDTRollW102H152,
}

export const LabelNames = [
  "Die Cut 17mm x 54mm", // 0
  "Die Cut 17mm x 87mm", // 1
  "Die Cut 23mm x 23mm", // 2
  "Die Cut 29mm x 42mm", // 3
  "Die Cut 29mm x 90mm", // 4
  "Die Cut 38mm x 90mm", // 5
  "Die Cut 39mm x 48mm", // 6
  "Die Cut 52mm x 29mm", // 7
  "Die Cut 62mm x 29mm", // 8
  "Die Cut 62mm x 100mm", // 9
  "Die Cut 60mm x 86mm", // 10
  "Die Cut 54mm x 29mm", // 11
  "Die Cut 102mm x 51mm", // 12
  "Die Cut 102mm x 152mm", // 13
  "Die Cut 103mm x 164mm", // 14
  "12mm", // 15
  "29mm", // 16
  "38mm", // 17
  "50mm", // 18
  "54mm", // 19
  "62mm", // 20
  "62mm RB", // 21
  "102mm", // 22
  "103mm", // 23
  "DT 90mm", // 24
  "DT 102mm", // 25
  "DT 102mm x 51mm", // 26
  "DT 102mm x 152mm", // 27
];

/**
 * Starts the discovery process for brother printers
 *
 * @param params
 * @param params.V6             If we should searching using IP v6.
 * @param params.printerName    If we should name the printer something specific.
 *
 * @return {Promise<void>}
 */
export async function discoverPrinters(params = {}) {
  return ReactNativeBrotherPrinters?.discoverPrinters(params);
}

/**
 * Checks if a reader is discoverable
 *
 * @param ip
 *
 * @return {Promise<void>}
 */
export async function pingPrinter(ip) {
  return ReactNativeBrotherPrinters?.pingPrinter(ip);
}

/**
 * Prints an image
 *
 * @param device                  Device object
 * @param uri                     URI of image wanting to be printed
 * @param params
 * @param params.autoCut            Boolean if the printer should auto cut the receipt/label
 * @param params.labelSize          Label size that we are printing with
 * @param params.isHighQuality
 * @param params.isHalftoneErrorDiffusion
 *
 * @return {Promise<*>}
 */
export async function printImage(device, uri, params = {}) {
  if (!params.labelSize) {
    return new Error("Label size must be given when printing a label");
  }

  return ReactNativeBrotherPrinters?.printImage(device, uri, params);
}

// export async function printPDF(device, uri, params = {}) {
//   return ReactNativeBrotherPrinters?.printPDF(device, uri, params);
// }

export const discoverBluetoothPrinters = async () => {
  try {
    const printers = await ReactNativeBrotherPrinters.discoverBluetoothPrinters();
    console.log('Discovered printers:', printers);
    return printers;
  } catch (error) {
    console.error('Error discovering printers:', error);
    throw error;
  }
};

export const discoverBLEPrinters = async () => {
  try {
    const printers = await ReactNativeBrotherPrinters.discoverBLEPrinters();
    console.log('Discovered printers:', printers);
    return printers;
  } catch (error) {
    console.error('Error discovering printers:', error);
    throw error;
  }
};

export const connectToBluetoothPrinter = async (serialNumber) => {
  try {
    const result = await ReactNativeBrotherPrinters.connectToBluetoothPrinter(serialNumber);
    console.log('Connected to printer:', result);
    return result;
  } catch (error) {
    console.error('Error connecting to printer:', error);
    throw error;
  }
};

export const printViaBluetooth = async (serialNumber, data) => {
  try {
    const result = await ReactNativeBrotherPrinters.printViaBluetooth(serialNumber, data);
    console.log('Print result:', result);
    return result;
  } catch (error) {
    console.error('Error printing:', error);
    throw error;
  }
};

let listeners;
if (ReactNativeBrotherPrinters) {
  listeners = new NativeEventEmitter(ReactNativeBrotherPrinters);
}

export function registerBrotherListener(key, method) {
  return listeners?.addListener(key, method);
}

/**
 * Retrieves the status of a printer
 *
 * @param device                  Device object
 * @param device.type             Type of the device (e.g., "bluetooth" or "wifi")
 * @param device.serialNumber     Serial number of the device (required for Bluetooth)
 * @param device.ipAddress        IP address of the device (required for WiFi)
 *
 * @return {Promise<Object>}      Printer status object
 */
export async function getPrinterStatus(device) {
  if (!device || !device.type) {
    throw new Error("Device type must be specified");
  }

  return ReactNativeBrotherPrinters?.getPrinterStatus(device);
}
