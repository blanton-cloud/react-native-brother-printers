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

        // Start printer search
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

RCT_REMAP_METHOD(printImage, deviceInfo:(NSDictionary *)device printerUri:(NSString *)imageStr printImageOptions:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Starting printImage method");
    NSLog(@"Device info: %@", device);
    NSLog(@"Printer URI: %@", imageStr);
    NSLog(@"Print options: %@", options);

    NSLog(@"Called the printImage function with device: %@", device);

    BRLMChannel *channel;
    if ([device[@"type"] isEqualToString:@"bluetooth"] && device[@"serialNumber"] != nil) {
        // Use Bluetooth if type is "bluetooth" and serialNumber is provided
        channel = [[BRLMChannel alloc] initWithBluetoothSerialNumber:device[@"serialNumber"]];
    } else if ([device[@"type"] isEqualToString:@"wifi"] && device[@"ipAddress"] != nil) {
        // Use WiFi if type is "wifi" and ipAddress is provided
        channel = [[BRLMChannel alloc] initWithWifiIPAddress:device[@"ipAddress"]];
    } else {
        reject(@"channel_init_error", @"Invalid type or missing required fields (serialNumber or ipAddress)", nil);
        return;
    }

    if (!channel) {
        NSLog(@"Failed to initialize channel. Device info might be invalid.");
    } else {
        NSLog(@"Channel initialized successfully.");
    }

    BRLMPrinterDriverGenerateResult *driverGenerateResult = [BRLMPrinterDriverGenerator openChannel:channel];
    if (driverGenerateResult.error.code != BRLMOpenChannelErrorCodeNoError || driverGenerateResult.driver == nil) {
        NSLog(@"Error initializing printer driver: %@", @(driverGenerateResult.error.code));
        reject(@"driver_init_error", @"Failed to initialize printer driver", nil);
        return;
    }

    NSLog(@"Printer driver initialized successfully.");

    BRLMPrinterDriver *printerDriver = driverGenerateResult.driver;

    // Retrieve printer status
    NSLog(@"Retrieving printer status...");
    BRLMGetPrinterStatusResult *statusResult = [printerDriver getPrinterStatus];
    if (statusResult.error.code != BRLMGetStatusErrorCodeNoError || statusResult.status == nil) {
        NSLog(@"Failed to retrieve printer status: %@", @(statusResult.error.code));
        [printerDriver closeChannel];
        reject(@"status_error", @"Failed to retrieve printer status", nil);
        return;
    }

    NSLog(@"Printer status retrieved successfully: %@", statusResult.status);

    BRLMPrinterModel model = [BRLMPrinterClassifier transferEnumFromString:device[@"modelName"]];
    BRLMQLPrintSettings *qlSettings = [[BRLMQLPrintSettings alloc] initDefaultPrintSettingsWithPrinterModel:model];

    qlSettings.autoCut = true;

    if (options[@"autoCut"]) {
        qlSettings.autoCut = [options[@"autoCut"] boolValue];
    }

    if (options[@"labelSize"]) {
        qlSettings.labelSize = [options[@"labelSize"] intValue];
    }

    if (options[@"isHighQuality"]) {
        qlSettings.printQuality = [options[@"isHighQuality"] boolValue] ? BRLMPrintSettingsPrintQualityBest : BRLMPrintSettingsPrintQualityFast;
    }

    if (options[@"isHalftoneErrorDiffusion"]) {
        qlSettings.halftone = [options[@"isHalftoneErrorDiffusion"] boolValue] ? BRLMPrintSettingsHalftoneErrorDiffusion : BRLMPrintSettingsHalftoneThreshold;
    }

    // Automatically determine label size if not provided in options
    if (!options[@"labelSize"] && statusResult.status.mediaInfo) {
        BRLMQLPrintSettingsLabelSize determinedLabelSize = [self determineLabelSizeFromMediaInfo:@{
            @"width_mm": @(statusResult.status.mediaInfo.width_mm),
            @"height_mm": @(statusResult.status.mediaInfo.height_mm)
        }];
        qlSettings.labelSize = determinedLabelSize;
        NSLog(@"Determined label size: %ld", (long)determinedLabelSize);
    }

    NSURL *url = [NSURL URLWithString:imageStr];
    NSLog(@"Starting print operation...");
    BRLMPrintError *printError = [printerDriver printImageWithURL:url settings:qlSettings];

    if (printError.code != BRLMPrintErrorCodeNoError) {
        NSLog(@"Error - Print Image: %@", printError);

        NSString *errorCodeString = [NSString stringWithFormat:@"Error code: %ld", (long)printError.code];
        NSString *errorDescription = [NSString stringWithFormat:@"%@ - %@", errorCodeString, printError.description];

        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorDescription, @"errorCode": @(printError.code)};
        NSError *error = [NSError errorWithDomain:@"com.react-native-brother-printers.rn" code:printError.code userInfo:userInfo];

        [printerDriver closeChannel];
        reject(PRINT_ERROR, @"There was an error trying to print the image", error);
    } else {
        NSLog(@"Print operation completed successfully.");
        NSLog(@"Success - Print Image");
        [printerDriver closeChannel];
        resolve(Nil);
    }
}

RCT_REMAP_METHOD(printViaBluetooth, serialNumber:(NSString *)serialNumber printerUri:(NSString *)imageStr printImageOptions:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Called the printViaBluetooth function");

    BRLMChannel *channel = [[BRLMChannel alloc] initWithBluetoothSerialNumber:serialNumber];
    BRLMPrinterDriverGenerateResult *driverGenerateResult = [BRLMPrinterDriverGenerator openChannel:channel];

    if (driverGenerateResult.error.code != BRLMOpenChannelErrorCodeNoError || driverGenerateResult.driver == nil) {
        NSLog(@"Error initializing printer driver: %@", @(driverGenerateResult.error.code));
        reject(@"driver_init_error", @"Failed to initialize printer driver", nil);
        return;
    }

    BRLMPrinterDriver *printerDriver = driverGenerateResult.driver;

    BRLMQLPrintSettings *qlSettings = [[BRLMQLPrintSettings alloc] initDefaultPrintSettingsWithPrinterModel:BRLMPrinterModelQL_820NWB];

    qlSettings.autoCut = true;

    if (options[@"autoCut"]) {
        qlSettings.autoCut = [options[@"autoCut"] boolValue];
    }

    if (options[@"labelSize"]) {
        qlSettings.labelSize = [options[@"labelSize"] intValue];
    }

    if (options[@"isHighQuality"]) {
        qlSettings.printQuality = [options[@"isHighQuality"] boolValue] ? BRLMPrintSettingsPrintQualityBest : BRLMPrintSettingsPrintQualityFast;
    }

    if (options[@"isHalftoneErrorDiffusion"]) {
        qlSettings.halftone = [options[@"isHalftoneErrorDiffusion"] boolValue] ? BRLMPrintSettingsHalftoneErrorDiffusion : BRLMPrintSettingsHalftoneThreshold;
    }

    NSURL *url = [NSURL URLWithString:imageStr];
    BRLMPrintError *printError = [printerDriver printImageWithURL:url settings:qlSettings];

    if (printError.code != BRLMPrintErrorCodeNoError) {
        NSLog(@"Error - Print Image: %@", printError);

        NSString *errorCodeString = [NSString stringWithFormat:@"Error code: %ld", (long)printError.code];
        NSString *errorDescription = [NSString stringWithFormat:@"%@ - %@", errorCodeString, printError.description];

        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorDescription, @"errorCode": @(printError.code)};
        NSError *error = [NSError errorWithDomain:@"com.react-native-brother-printers.rn" code:printError.code userInfo:userInfo];

        [printerDriver closeChannel];
        reject(PRINT_ERROR, @"There was an error trying to print the image", error);
    } else {
        NSLog(@"Success - Print Image");
        [printerDriver closeChannel];
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
    NSString *serialNumber = channel.extraInfo[BRLMChannelExtraInfoKeySerialNumber];
    NSString *modelName = channel.extraInfo[BRLMChannelExtraInfoKeyModelName];

    [printers addObject:@{
      @"serialNumber": serialNumber,
      @"modelName": modelName,
      @"printerName": modelName,
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

  NSMutableArray *printers = [NSMutableArray array];
  for (BRLMChannel *channel in result.channels) {
    [printers addObject:@{
      @"modelName": channel.extraInfo[BRLMChannelExtraInfoKeyModelName],
      @"printerName": channel.extraInfo[BRLMChannelExtraInfoKeyModelName],
      @"advertiseLocalName": channel.channelInfo
    }];
  }

  resolve(printers);
}

RCT_REMAP_METHOD(getPrinterStatus, deviceInfo:(NSDictionary *)device resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"Called the getPrinterStatus function with device: %@", device);

    BRLMChannel *channel;
    if ([device[@"type"] isEqualToString:@"bluetooth"] && device[@"serialNumber"] != nil) {
        channel = [[BRLMChannel alloc] initWithBluetoothSerialNumber:device[@"serialNumber"]];
    } else if ([device[@"type"] isEqualToString:@"wifi"] && device[@"ipAddress"] != nil) {
        channel = [[BRLMChannel alloc] initWithWifiIPAddress:device[@"ipAddress"]];
    } else {
        reject(@"channel_init_error", @"Invalid type or missing required fields (serialNumber or ipAddress)", nil);
        return;
    }

    NSLog(@"Attempting to open channel...");
    BRLMPrinterDriverGenerateResult *driverGenerateResult = [BRLMPrinterDriverGenerator openChannel:channel];
    NSLog(@"Channel open attempt completed.");

    if (driverGenerateResult.error.code != BRLMOpenChannelErrorCodeNoError || driverGenerateResult.driver == nil) {
        NSLog(@"Error initializing printer driver: %@", @(driverGenerateResult.error.code));
        reject(@"driver_init_error", @"Failed to initialize printer driver", nil);
        return;
    }

    BRLMPrinterDriver *printerDriver = driverGenerateResult.driver;
    BRLMGetPrinterStatusResult *statusResult = [printerDriver getPrinterStatus];

    if (statusResult.error.code != BRLMGetStatusErrorCodeNoError || statusResult.status == nil) {
        NSLog(@"Failed to retrieve printer status: %@", @(statusResult.error.code));
        reject(@"status_error", @"Failed to retrieve printer status", nil);
        return;
    }

    BRLMPrinterStatus *printerStatus = statusResult.status;
    NSLog(@"Printer status loaded: %@", printerStatus);

    NSDictionary *rawDataDict = @{ 
        @"byHead": @(printerStatus.rawData.byHead),
        @"bySize": @(printerStatus.rawData.bySize),
        @"byBrotherCode": @(printerStatus.rawData.byBrotherCode),
        @"bySeriesCode": @(printerStatus.rawData.bySeriesCode),
        @"byModelCode": @(printerStatus.rawData.byModelCode),
        @"byNationCode": @(printerStatus.rawData.byNationCode),
        @"byFiller": @(printerStatus.rawData.byFiller),
        @"byFiller2": @(printerStatus.rawData.byFiller2),
        @"byErrorInf": @(printerStatus.rawData.byErrorInf),
        @"byErrorInf2": @(printerStatus.rawData.byErrorInf2),
        @"byMediaWidth": @(printerStatus.rawData.byMediaWidth),
        @"byMediaType": @(printerStatus.rawData.byMediaType),
        @"byColorNum": @(printerStatus.rawData.byColorNum),
        @"byFont": @(printerStatus.rawData.byFont),
        @"byMode": @(printerStatus.rawData.byMode),
        @"byDensity": @(printerStatus.rawData.byDensity),
        @"byMediaLength": @(printerStatus.rawData.byMediaLength),
        @"byStatusType": @(printerStatus.rawData.byStatusType),
        @"byPhaseType": @(printerStatus.rawData.byPhaseType),
        @"byPhaseNoHi": @(printerStatus.rawData.byPhaseNoHi),
        @"byPhaseNoLow": @(printerStatus.rawData.byPhaseNoLow),
        @"byNoticeNo": @(printerStatus.rawData.byNoticeNo),
        @"byExtByteNum": @(printerStatus.rawData.byExtByteNum),
        @"byLabelColor": @(printerStatus.rawData.byLabelColor),
        @"byFontColor": @(printerStatus.rawData.byFontColor)
    };

    NSDictionary *batteryStatusDict = printerStatus.batteryStatus ? @{ 
        @"batteryMounted": @(printerStatus.batteryStatus.batteryMounted),
        @"charging": @(printerStatus.batteryStatus.charging),
        @"chargeLevel": @{ 
            @"max": @(printerStatus.batteryStatus.chargeLevel.max),
            @"current": @(printerStatus.batteryStatus.chargeLevel.current)
        }
    } : [NSNull null];

    NSDictionary *mediaInfoDict = printerStatus.mediaInfo ? @{ 
        @"mediaType": @(printerStatus.mediaInfo.mediaType),
        @"backgroundColor": @(printerStatus.mediaInfo.backgroundColor),
        @"inkColor": @(printerStatus.mediaInfo.inkColor),
        @"width_mm": @(printerStatus.mediaInfo.width_mm),
        @"height_mm": @(printerStatus.mediaInfo.height_mm),
        @"isHeightInfinite": @(printerStatus.mediaInfo.isHeightInfinite)
    } : [NSNull null];

    NSDictionary *statusDict = @{ 
        @"hasError": @(printerStatus.errorCode != BRLMPrinterStatusErrorCodeNoError),
        @"errorCode": @(printerStatus.errorCode),
        @"rawData": rawDataDict,
        @"model": @(printerStatus.model),
        @"batteryStatus": batteryStatusDict,
        @"mediaInfo": mediaInfoDict
    };
    resolve(statusDict);

    [printerDriver closeChannel];
}

-(void)didFinishSearch:(id)sender
{
    NSLog(@"didFinishedSearch");

    // Get BRPtouchNetworkInfo Class list
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

- (BRLMQLPrintSettingsLabelSize)determineLabelSizeFromMediaInfo:(NSDictionary *)mediaInfo {
    NSNumber *width = mediaInfo[@"width_mm"];
    NSNumber *height = mediaInfo[@"height_mm"];

    if (!width || !height) {
        return BRLMQLPrintSettingsLabelSizeRollW62; // Default label size if dimensions are unavailable
    }

    if ([width intValue] == 17 && [height intValue] == 54) {
        return BRLMQLPrintSettingsLabelSizeDieCutW17H54;
    } else if ([width intValue] == 17 && [height intValue] == 87) {
        return BRLMQLPrintSettingsLabelSizeDieCutW17H87;
    } else if ([width intValue] == 23 && [height intValue] == 23) {
        return BRLMQLPrintSettingsLabelSizeDieCutW23H23;
    } else if ([width intValue] == 29 && [height intValue] == 42) {
        return BRLMQLPrintSettingsLabelSizeDieCutW29H42;
    } else if ([width intValue] == 29 && [height intValue] == 90) {
        return BRLMQLPrintSettingsLabelSizeDieCutW29H90;
    } else if ([width intValue] == 38 && [height intValue] == 90) {
        return BRLMQLPrintSettingsLabelSizeDieCutW38H90;
    } else if ([width intValue] == 39 && [height intValue] == 48) {
        return BRLMQLPrintSettingsLabelSizeDieCutW39H48;
    } else if ([width intValue] == 52 && [height intValue] == 29) {
        return BRLMQLPrintSettingsLabelSizeDieCutW52H29;
    } else if ([width intValue] == 62 && [height intValue] == 29) {
        return BRLMQLPrintSettingsLabelSizeDieCutW62H29;
    } else if ([width intValue] == 62 && [height intValue] == 60) {
        return BRLMQLPrintSettingsLabelSizeDieCutW62H60;
    } else if ([width intValue] == 62 && [height intValue] == 75) {
        return BRLMQLPrintSettingsLabelSizeDieCutW62H75;
    } else if ([width intValue] == 62 && [height intValue] == 100) {
        return BRLMQLPrintSettingsLabelSizeDieCutW62H100;
    } else if ([width intValue] == 60 && [height intValue] == 86) {
        return BRLMQLPrintSettingsLabelSizeDieCutW60H86;
    } else if ([width intValue] == 54 && [height intValue] == 29) {
        return BRLMQLPrintSettingsLabelSizeDieCutW54H29;
    } else if ([width intValue] == 102 && [height intValue] == 51) {
        return BRLMQLPrintSettingsLabelSizeDieCutW102H51;
    } else if ([width intValue] == 102 && [height intValue] == 152) {
        return BRLMQLPrintSettingsLabelSizeDieCutW102H152;
    } else if ([width intValue] == 103 && [height intValue] == 164) {
        return BRLMQLPrintSettingsLabelSizeDieCutW103H164;
    } else if ([width intValue] == 12) {
        return BRLMQLPrintSettingsLabelSizeRollW12;
    } else if ([width intValue] == 29) {
        return BRLMQLPrintSettingsLabelSizeRollW29;
    } else if ([width intValue] == 38) {
        return BRLMQLPrintSettingsLabelSizeRollW38;
    } else if ([width intValue] == 50) {
        return BRLMQLPrintSettingsLabelSizeRollW50;
    } else if ([width intValue] == 54) {
        return BRLMQLPrintSettingsLabelSizeRollW54;
    } else if ([width intValue] == 62) {
        return BRLMQLPrintSettingsLabelSizeRollW62;
    } else if ([width intValue] == 102) {
        return BRLMQLPrintSettingsLabelSizeRollW102;
    } else if ([width intValue] == 103) {
        return BRLMQLPrintSettingsLabelSizeRollW103;
    } else {
        return BRLMQLPrintSettingsLabelSizeRollW62; // Default label size
    }
}

@end
