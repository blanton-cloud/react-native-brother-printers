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

export const LabelSize: {
  LabelSizeDieCutW17H54: number;
  LabelSizeDieCutW17H87: number;
  LabelSizeDieCutW23H23: number;
  LabelSizeDieCutW29H42: number;
  LabelSizeDieCutW29H90: number;
  LabelSizeDieCutW38H90: number;
  LabelSizeDieCutW39H48: number;
  LabelSizeDieCutW52H29: number;
  LabelSizeDieCutW62H29: number;
  LabelSizeDieCutW62H100: number;
  LabelSizeDieCutW60H86: number;
  LabelSizeDieCutW54H29: number;
  LabelSizeDieCutW102H51: number;
  LabelSizeDieCutW102H152: number;
  LabelSizeDieCutW103H164: number;
  LabelSizeRollW12: number;
  LabelSizeRollW29: number;
  LabelSizeRollW38: number;
  LabelSizeRollW50: number;
  LabelSizeRollW54: number;
  LabelSizeRollW62: number;
  LabelSizeRollW62RB: number;
  LabelSizeRollW102: number;
  LabelSizeRollW103: number;
  LabelSizeDTRollW90: number;
  LabelSizeDTRollW102: number;
  LabelSizeDTRollW102H51: number;
  LabelSizeDTRollW102H152: number;
};

export const LabelNames: string[];

export function discoverPrinters(
  params?: { V6?: boolean; printerName?: string }
): Promise<void>;

export function pingPrinter(ip: string): Promise<void>;

export interface Device {
  ipAddress: string;
  modelName: string;
  location?: string;
  printerName?: string;
  serialNumber?: string;
  nodeName?: string;
  macAddress?: string;
}

export function printImage(
  device: Device,
  uri: string,
  params: { autoCut?: boolean; labelSize: number, isHighQuality?: boolean, isHalftoneErrorDiffusion?: boolean }
): Promise<any>;

export function registerBrotherListener(key: any, method: any): any;
