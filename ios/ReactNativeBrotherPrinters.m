// ReactNativeBrotherPrinters.m

#import "ReactNativeBrotherPrinters.h"
#import <React/RCTConvert.h>
#import <BRLMPrinterKit/BRLMPrinterKit.h>

@implementation ReactNativeBrotherPrinters

NSString *const DISCOVER_READERS_ERROR = @"DISCOVER_READERS_ERROR";
NSString *const DISCOVER_READER_ERROR = @"DISCOVER_READER_ERROR";
NSString *const PRINT_ERROR = @"PRINT_ERROR";

RCT_EXPORT_MODULE()

-(void)startObserving {
    hasListeners = YES;
}

-(void)stopObserving {
    hasListeners = NO;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[
        @"onBrotherLog",

        @"onDiscoverPrinters",
    ];
}

RCT_REMAP_METHOD(discoverPrinters, discoverOptions:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Called the function");

        _brotherDeviceList = [[NSMutableArray alloc] initWithCapacity:0];

        _networkManager = [[BRPtouchNetworkManager alloc] init];
        _networkManager.delegate = self;

        NSString *path = [[NSBundle mainBundle] pathForResource:@"PrinterList" ofType:@"plist"];

        if (path) {
            NSDictionary *printerDict = [NSDictionary dictionaryWithContentsOfFile:path];
            NSArray *printerList = [[NSArray alloc] initWithArray:printerDict.allKeys];

            [_networkManager setPrinterNames:printerList];
        } else {
            NSLog(@"Could not find PrinterList.plist");
        }

        //    Start printer search
        int response = [_networkManager startSearch: 5.0];

        if (response == RET_TRUE) {
            resolve(Nil);
        } else {
            reject(DISCOVER_READERS_ERROR, @"A problem occured when trying to execute discoverPrinters", Nil);
        }
    });
}

RCT_REMAP_METHOD(pingPrinter, printerAddress:(NSString *)ip resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    BRLMChannel *channel = [[BRLMChannel alloc] initWithWifiIPAddress:ip];

    BRLMPrinterDriverGenerateResult *driverGenerateResult = [BRLMPrinterDriverGenerator openChannel:channel];
    if (driverGenerateResult.error.code != BRLMOpenChannelErrorCodeNoError ||
        driverGenerateResult.driver == nil) {

        NSLog(@"%@", @(driverGenerateResult.error.code));
        NSString *errorCodeString = [NSString stringWithFormat:@"%@", @(driverGenerateResult.error.code)];
        NSError* error = [NSError errorWithDomain:@"com.react-native-brother-printers.rn" code:driverGenerateResult.error.code userInfo:[NSDictionary dictionaryWithObject:errorCodeString forKey:NSLocalizedDescriptionKey]];

        [driverGenerateResult.driver closeChannel];

        return reject(DISCOVER_READER_ERROR, @"A problem occured when trying to execute pingPrinter", error);
    }

    NSLog(@"We were able to discover a printer");
    [driverGenerateResult.driver closeChannel];
    resolve(Nil);
}

RCT_REMAP_METHOD(printImage, deviceInfo:(NSDictionary *)device printerUri: (NSString *)imageStr printImageOptions:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Called the printImage function");
    BRPtouchDeviceInfo *deviceInfo = [self deserializeDeviceInfo:device];

    BRLMChannel *channel = [[BRLMChannel alloc] initWithWifiIPAddress:deviceInfo.strIPAddress];
    BRLMPrinterDriverGenerateResult *driverGenerateResult = [BRLMPrinterDriverGenerator openChannel:channel];
    if (driverGenerateResult.error.code != BRLMOpenChannelErrorCodeNoError || driverGenerateResult.driver == nil) {
        NSLog(@"Error initializing printer driver: %@", @(driverGenerateResult.error.code));
        reject(@"driver_init_error", @"Failed to initialize printer driver", nil);
        return;
    }
    BRLMPrinterDriver *printerDriver = driverGenerateResult.driver;

    BRLMPrinterModel model = [BRLMPrinterClassifier transferEnumFromString:deviceInfo.strModelName];
    BRLMQLPrintSettings *qlSettings = [[BRLMQLPrintSettings alloc] initDefaultPrintSettingsWithPrinterModel:model];

    qlSettings.autoCut = true;

    if (options[@"autoCut"]) {
        qlSettings.autoCut = [options[@"autoCut"] boolValue];
    }

    if (options[@"labelSize"]) {
        qlSettings.labelSize = [options[@"labelSize"] intValue];
    }

    if (options[@"isHighQuality"]) {
        if ([options[@"isHighQuality"] boolValue]) {
            qlSettings.printQuality = BRLMPrintSettingsPrintQualityBest;
            NSLog(@"High Quality is enabled");
        } else {
            qlSettings.printQuality = BRLMPrintSettingsPrintQualityFast;
            NSLog(@"High Quality is disabled");
        }
    }

    if (options[@"isHalftoneErrorDiffusion"]) {
        if ([options[@"isHalftoneErrorDiffusion"] boolValue]) {
            qlSettings.halftone = BRLMPrintSettingsHalftoneErrorDiffusion;
            NSLog(@"Error Diffusion is enabled");
        } else {
            qlSettings.halftone = BRLMPrintSettingsHalftoneThreshold;
            NSLog(@"Error Diffusion is disabled");
        }
    }

    NSLog(@"Auto Cut: %@, Label Size: %@", options[@"autoCut"], options[@"labelSize"]);

    NSURL *url = [NSURL URLWithString:imageStr];
    BRLMPrintError *printError = [printerDriver printImageWithURL:url settings:qlSettings];

    if (printError.code != BRLMPrintErrorCodeNoError) {
        NSLog(@"Error - Print Image: %@", printError);

        NSString *errorCodeString = [NSString stringWithFormat:@"Error code: %ld", (long)printError.code];
        NSString *errorDescription = [NSString stringWithFormat:@"%@ - %@", errorCodeString, printError.description];

        NSDictionary *userInfo = @{
            NSLocalizedDescriptionKey: errorDescription,
            @"errorCode": @(printError.code),
        };
        
        NSError *error = [NSError errorWithDomain:@"com.react-native-brother-printers.rn" 
                                            code:printError.code 
                                        userInfo:userInfo];

        [printerDriver closeChannel]; // Close the channel

        reject(PRINT_ERROR, @"There was an error trying to print the image", error);
    } else {
        NSLog(@"Success - Print Image");

        [printerDriver closeChannel]; // Close the channel

        resolve(Nil);
    }
}

RCT_EXPORT_METHOD(discoverBluetoothPrinters:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSArray<BRLMChannel *> *channels = [BRLMPrinterSearcher startBluetoothSearch].channels;

  if (channels == nil || channels.count == 0) {
    reject(DISCOVER_READERS_ERROR, @"No Bluetooth printers found", nil);
    return;
  }

  NSMutableArray *printers = [NSMutableArray array];
  for (BRLMChannel *channel in channels) {
    [printers addObject:@{
      @"modelName": channel.extraInfo[BRLMChannelExtraInfoKeyModelName],
      @"localName": channel.channelInfo
    }];
  }

  resolve(printers);
}

RCT_EXPORT_METHOD(discoverBLEPrinters:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  BRLMBLESearchOption *option = [[BRLMBLESearchOption alloc] init];
  option.searchDuration = 15;

  BRLMPrinterSearchResult *result = [BRLMPrinterSearcher startBLESearch:option callback:^(BRLMChannel *channel) {
    NSString *modelName = [channel.extraInfo objectForKey:BRLMChannelExtraInfoKeyModelName];
    NSString *advertiseLocalName = channel.channelInfo;
    NSLog(@"Model: %@, AdvertiseLocalName: %@", modelName, advertiseLocalName);
  }];

//   if (result.error.code != BRLMPrinterSearcherErrorCodeNoError) {
//     reject(DISCOVER_READERS_ERROR, @"Failed to discover BLE printers", nil);
//     return;
//   }

  NSMutableArray *printers = [NSMutableArray array];
  for (BRLMChannel *channel in result.channels) {
    [printers addObject:@{
      @"modelName": channel.extraInfo[BRLMChannelExtraInfoKeyModelName],
      @"advertiseLocalName": channel.channelInfo
    }];
  }

  resolve(printers);
}

-(void)didFinishSearch:(id)sender
{
    NSLog(@"didFinishedSearch");

    //  get BRPtouchNetworkInfo Class list
    [_brotherDeviceList removeAllObjects];
    _brotherDeviceList = (NSMutableArray*)[_networkManager getPrinterNetInfo];

    NSLog(@"_brotherDeviceList [%@]",_brotherDeviceList);

    NSMutableArray *_serializedArray = [[NSMutableArray alloc] initWithCapacity:_brotherDeviceList.count];

    for (BRPtouchDeviceInfo *deviceInfo in _brotherDeviceList) {
        [_serializedArray addObject:[self serializeDeviceInfo:deviceInfo]];

        NSLog(@"Model: %@, IP Address: %@", deviceInfo.strModelName, deviceInfo.strIPAddress);

    }

    [self sendEventWithName:@"onDiscoverPrinters" body:_serializedArray];

    return;
}

- (NSDictionary *) serializeDeviceInfo:(BRPtouchDeviceInfo *)device {
    return @{
        @"ipAddress": device.strIPAddress,
        @"location": device.strLocation,
        @"modelName": device.strModelName,
        @"printerName": device.strPrinterName,
        @"serialNumber": device.strSerialNumber,
        @"nodeName": device.strNodeName,
        @"macAddress": device.strMACAddress,
    };
}

- (BRPtouchDeviceInfo *) deserializeDeviceInfo:(NSDictionary *)device {
    BRPtouchDeviceInfo *deviceInfo = [[BRPtouchDeviceInfo alloc] init];

//    return @{
//        @"ipAddress": device.strIPAddress,
//        @"location": device.strLocation,
//        @"modelName": device.strModelName,
//        @"printerName": device.strPrinterName,
//        @"serialNumber": device.strSerialNumber,
//        @"nodeName": device.strNodeName,
//        @"macAddress": device.strMACAddress,
//    };
//
//
    deviceInfo.strIPAddress = [RCTConvert NSString:device[@"ipAddress"]];
    deviceInfo.strLocation = [RCTConvert NSString:device[@"location"]];
    deviceInfo.strModelName = [RCTConvert NSString:device[@"modelName"]];
    deviceInfo.strPrinterName = [RCTConvert NSString:device[@"printerName"]];
    deviceInfo.strSerialNumber = [RCTConvert NSString:device[@"serialNumber"]];
    deviceInfo.strNodeName = [RCTConvert NSString:device[@"nodeName"]];
    deviceInfo.strMACAddress = [RCTConvert NSString:device[@"macAddress"]];

    NSLog(@"We got here");

    return deviceInfo;
}

@end
